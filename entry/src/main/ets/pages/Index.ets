import { QuoteData, Quote } from '../common/QuoteData';
import { QuoteSelectionService } from '../services/QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper, WallpaperStyle } from '../services/WallpaperService';
import router from '@ohos.router';
import { ScheduleConfig, WallpaperConfig } from '../common/ScheduleConfig';
import display from '@ohos.display';
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { BusinessError } from '@ohos.base';
import { Context } from '@ohos.abilityAccessCtrl';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
// SaveButton is not available in HarmonyOS API, using regular Button instead

@Entry
@Component
struct Index {
  @State currentQuote: Quote = QuoteData.getRandomQuote();
  @State currentWallpaper: GeneratedWallpaper | null = null;
  @State isLoading: boolean = false;
  @State previewBackground: string = '';
  @State previewMode: 'current' | 'recommended' = 'current';
  @State recommendedQuote: Quote | null = null;
  @State recommendedWallpaper: GeneratedWallpaper | null = null;
  @State usedRecommendations: Set<string> = new Set();

  @State config: WallpaperConfig | null = null;
  @State showSaveDialog: boolean = false;
  @State screenRatio: number = 16/9; // 默认比例
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;

  async aboutToAppear() {
    await this.getScreenRatio();
    await this.loadConfig();
    await this.loadCurrentWallpaper();
    await this.updatePreview();
  }

  async getScreenRatio() {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      // 计算竖屏比例（高度/宽度）
      this.screenRatio = defaultDisplay.height / defaultDisplay.width;
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
      console.log(`Screen ratio: ${this.screenRatio} (${defaultDisplay.width}x${defaultDisplay.height})`);
    } catch (error) {
      console.error('Failed to get screen ratio:', error);
      this.screenRatio = 16/9; // 保持默认比例
      this.screenWidth = 360;
      this.screenHeight = 640;
    }
  }

  async loadConfig() {
    try {
      this.config = await ScheduleConfig.getConfig();
    } catch (error) {
      console.error('Failed to load config:', error);
    }
  }

  async loadCurrentWallpaper() {
    this.currentWallpaper = await WallpaperService.getCurrentWallpaper();
    if (!this.currentWallpaper && this.config) {
      try {
        const selectedQuote = await QuoteSelectionService.selectQuote(this.config.selectionAlgorithm);
        this.currentQuote = selectedQuote;
        this.currentWallpaper = await WallpaperService.generateWallpaper(selectedQuote);
      } catch (error) {
        console.error('Failed to load initial wallpaper:', error);
      }
    }
  }


  async updatePreview() {
    try {
      if (this.previewMode === 'recommended' && this.recommendedWallpaper) {
        const previewResult = WallpaperService.createWallpaperPreview(this.recommendedWallpaper);
        if (previewResult) {
          this.previewBackground = previewResult;
        } else {
          this.previewBackground = this.recommendedWallpaper.style.backgroundColor || '#2c3e50';
        }
      } else if (this.currentWallpaper) {
        const previewResult = WallpaperService.createWallpaperPreview(this.currentWallpaper);
        if (previewResult) {
          this.previewBackground = previewResult;
        } else {
          this.previewBackground = this.currentWallpaper.style.backgroundColor || '#2c3e50';
        }
      } else {
        this.previewBackground = '#2c3e50';
      }

      setTimeout(() => {
        console.log('Preview updated:', this.previewBackground);
      }, 0);
    } catch (error) {
      console.error('Failed to update preview:', error);
      this.previewBackground = '#2c3e50';
    }
  }

  async viewCurrent() {
    this.previewMode = 'current';
    await this.updatePreview();
  }

  async recommendNext() {
    try {
      this.isLoading = true;
      this.recommendedQuote = null;
      this.recommendedWallpaper = null;
      this.previewMode = 'current';
      await this.updatePreview();

      console.log('Starting recommendation process...');

      const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(20);
      console.log('Got recommended quotes:', recommendedQuotes.length);

      if (!recommendedQuotes || recommendedQuotes.length === 0) {
        throw new Error('No recommended quotes available');
      }

      const unusedQuotes = recommendedQuotes.filter(quote => {
        const quoteKey = `${quote.text}-${quote.author}`;
        return !this.usedRecommendations.has(quoteKey);
      });

      let selectedQuote: Quote;

      if (unusedQuotes.length > 0) {
        const randomIndex = Math.floor(Math.random() * unusedQuotes.length);
        selectedQuote = unusedQuotes[randomIndex];
      } else {
        this.usedRecommendations.clear();
        const randomIndex = Math.floor(Math.random() * recommendedQuotes.length);
        selectedQuote = recommendedQuotes[randomIndex];
      }

      if (!selectedQuote) {
        throw new Error('Failed to select a quote');
      }

      console.log('Selected quote:', selectedQuote.text);

      const quoteKey = `${selectedQuote.text}-${selectedQuote.author}`;
      this.usedRecommendations.add(quoteKey);
      this.recommendedQuote = selectedQuote;

      let generatedWallpaper: GeneratedWallpaper;
      try {
        generatedWallpaper = await WallpaperService.generateWallpaper(this.recommendedQuote);
        console.log('Generated wallpaper:', generatedWallpaper);
      } catch (wallpaperError) {
        console.error('Failed to generate wallpaper, creating fallback:', wallpaperError);
        const fallbackStyle: WallpaperStyle = {
          backgroundColor: '#2c3e50',
          textColor: '#d3d3d3',
          fontSize: 32,
          fontFamily: 'HarmonyOS Sans',
          textAlign: 'center',
          backgroundOpacity: 1.0
        };
        generatedWallpaper = {
          quote: this.recommendedQuote,
          style: fallbackStyle,
          createdAt: new Date()
        };
      }

      this.recommendedWallpaper = generatedWallpaper;

      if (!this.recommendedQuote || !this.recommendedWallpaper) {
        throw new Error('Recommendation data is incomplete');
      }

      this.previewMode = 'recommended';
      console.log('Switching to recommended mode');
      await this.updatePreview();
      console.log('Recommendation completed successfully');

    } catch (error) {
      console.error('Failed to load recommendation:', error);
      if (!this.currentQuote) {
        this.currentQuote = QuoteData.getRandomQuote();
      }
      this.previewMode = 'current';
      await this.updatePreview();
    } finally {
      this.isLoading = false;
    }
  }


  async savePreviewImage() {
    try {
      console.log('开始保存壁纸图片...');

      // 使用componentSnapshot API截图纯净壁纸区域 - 参考_helper.txt第106行
      componentSnapshot.get("pureWallpaperArea", async (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          console.error("截图失败: " + JSON.stringify(error));
          return;
        }

        try {
          // 将PixelMap保存为JPEG格式 - 参考_helper.txt第111行
          const packOpts: image.PackingOption = {
            format: "image/jpeg",
            quality: 98
          };

          const imagePacker: image.ImagePacker = image.createImagePacker();
          const arrayBuffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

          // 保存到相册 - 参考_helper.txt第86-94行
          await this.saveImageToPhoto(arrayBuffer);

          // 释放资源
          imagePacker.release();
          pixelMap.release();

          console.log('壁纸图片保存成功');

        } catch (packError) {
          console.error('图片打包失败:', packError);
          pixelMap.release();
        }
      });

    } catch (error) {
      console.error('保存图片失败:', error);
    }
  }

  /**
   * 保存ArrayBuffer到图库 - 参考_helper.txt第86-94行的实现
   * @param buffer：图片ArrayBuffer
   */
  formatQuoteText(text: string): string {
    // 按照中英文标点符号分行
    let formattedText = text
      // 逗号后单换行
      .replace(/([，,])\s*/g, '$1\n')
      // 其他中文标点符号后双换行（空一行）
      .replace(/([。！？；：])\s*/g, '$1\n\n')
      // 其他英文标点符号后双换行（空一行）
      .replace(/([.!?;:])\s*/g, '$1\n\n')
      // 清理多余的换行和空格
      .replace(/\n{3,}/g, '\n\n') // 最多保留双换行
      .replace(/\s*\n\s*/g, '\n')
      .trim();

    return formattedText;
  }

  async saveImageToPhoto(buffer: ArrayBuffer): Promise<void> {
    // 按照 _helper.txt 第86-94行的方法实现
    const context = getContext(this) as Context;
    const helper = photoAccessHelper.getPhotoAccessHelper(context);
    const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
    const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    await fs.write(file.fd, buffer);
    await fs.close(file.fd);
    console.log("图片保存成功到相册:", uri);
  }

  build() {
    // 全屏预览区域
    Stack() {
      // 背景预览区域（填满整个屏幕）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.previewBackground || '#667eea')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 名言文本层
      Column() {
        if (this.isLoading) {
          // 加载状态
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#d3d3d3')
              .margin({ bottom: 12 })

            Text('正在生成推荐...')
              .fontSize(16)
              .fontColor('#d3d3d3')
              .textAlign(TextAlign.Center)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else if (this.previewMode === 'recommended' && this.recommendedQuote) {
          // 推荐模式显示推荐内容
          Text(this.formatQuoteText(this.recommendedQuote.text))
            .fontSize((this.recommendedWallpaper?.style.fontSize) || 24)
            .fontColor((this.recommendedWallpaper?.style.textColor) || '#d3d3d3')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 40 })
            .maxLines(20)
            .textOverflow({ overflow: TextOverflow.None })

          Text(`—— ${this.recommendedQuote.author || ''}${(this.recommendedQuote.author && this.recommendedQuote.source) ? ' · ' : ''}${this.recommendedQuote.source || ''}`)
            .fontSize(12)
            .fontColor((this.recommendedWallpaper?.style.textColor) || '#d3d3d3')
            .opacity(0.8)
            .textAlign(TextAlign.Center)
            .width('100%')
        } else if (this.currentQuote) {
          // 当前模式或推荐内容不存在时显示当前内容
          Text(this.formatQuoteText(this.currentQuote.text))
            .fontSize((this.currentWallpaper?.style.fontSize) || 24)
            .fontColor((this.currentWallpaper?.style.textColor) || '#d3d3d3')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: 40 })
            .maxLines(20)
            .textOverflow({ overflow: TextOverflow.None })

          Text(`—— ${this.currentQuote.author || ''}${(this.currentQuote.author && this.currentQuote.source) ? ' · ' : ''}${this.currentQuote.source || ''}`)
            .fontSize(12)
            .fontColor((this.currentWallpaper?.style.textColor) || '#d3d3d3')
            .opacity(0.8)
            .textAlign(TextAlign.Center)
            .width('100%')
        } else {
          // 最后的保护：显示占位文本
          Text('正在加载壁纸...')
            .fontSize(16)
            .fontColor('#d3d3d3')
            .textAlign(TextAlign.Center)
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(24)
      .width('100%')
      .height('100%')

      // 顶部标题栏 - 半透明层
      Row() {
        Text('锁屏助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffffff')

        Blank()

        Button() {
          Text('⚙')
            .fontSize(18)
            .fontColor('#ffffff')
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .borderRadius(20)
        .backdropBlur(10)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/Settings'
          });
        })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor('rgba(0, 0, 0, 0)')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .position({ x: 0, y: 0 })

      // 底部操作按钮 - 半透明层
      Column() {
        Row() {
          Button() {
            if (this.isLoading) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color('#ffffff')
            } else {
              Text('试试手气')
                .fontSize(16)
                .fontColor('#ffffff')
            }
          }
          .width('100%')
          .height(40)
          .backgroundColor('rgba(255, 255, 255, 0.2)')
          .borderRadius(20)
          .backdropBlur(10)
          .enabled(!this.isLoading)
          .onClick(async () => {
            await this.recommendNext();
          })
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 30, top: 20 })
      .backgroundColor('rgba(0, 0, 0, 0)')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })

      // 全屏加载遮罩
      if (this.isLoading) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .backdropBlur(10)

          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .margin({ bottom: 16 })

            Text('正在生成壁纸...')
              .fontSize(18)
              .fontColor('#ffffff')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width(140)
          .height(140)
          .backgroundColor('rgba(44, 62, 80, 0.8)')
          .borderRadius(16)
          .backdropBlur(20)
        }
        .width('100%')
        .height('100%')
      }
      // 隐藏的纯净壁纸组件用于截图
      this.buildPureWallpaper()
    }
    .width('100%')
    .height('100%')
    .id('previewArea')
    .gesture(
      LongPressGesture({ fingers: 1, repeat: false, duration: 800 })
        .onAction(() => {
          // 长按保存当前预览的壁纸图片
          this.showSaveDialog = true;
        })
    )
    .bindContentCover(this.showSaveDialog, this.buildSaveDialog(), ModalTransition.NONE)
  }


  @Builder
  buildSaveDialog() {
    Column() {
      Column() {
        Text('保存图片')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .margin({ bottom: 16 })

        Text('是否要保存此壁纸到"锁屏助手"相册？')
          .fontSize(16)
          .fontColor('#7f8c8d')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .backgroundColor('#ffffff')
            .fontColor('#7f8c8d')
            .borderRadius(6)
            .border({ width: 1, color: '#bdc3c7' })
            .onClick(() => {
              this.showSaveDialog = false;
            })

          Button('保存')
            .width('45%')
            .height(40)
            .backgroundColor('#5b9bd5')
            .fontColor('#ffffff')
            .borderRadius(6)
            .margin({ left: '10%' })
            .onClick(async () => {
              this.showSaveDialog = false;
              try {
                await this.savePreviewImage();
              } catch (error) {
                console.error("保存图片时发生错误: " + JSON.stringify(error));
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('80%')
      .padding(24)
      .backgroundColor('#ffffff')
      .borderRadius(12)
      .shadow({
        radius: 16,
        color: '#00000020',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000050')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showSaveDialog = false;
    })
  }

  @Builder
  buildPureWallpaper() {
    // 纯净的壁纸组件，只包含背景色和文字，用于截图保存
    Column() {
      if (this.previewMode === 'recommended' && this.recommendedQuote) {
        // 推荐模式显示推荐内容
        Text(this.formatQuoteText(this.recommendedQuote.text))
          .fontSize((this.recommendedWallpaper?.style.fontSize) || 24)
          .fontColor((this.recommendedWallpaper?.style.textColor) || '#d3d3d3')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 40 })
          .maxLines(20)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.recommendedQuote.author || ''}${(this.recommendedQuote.author && this.recommendedQuote.source) ? ' · ' : ''}${this.recommendedQuote.source || ''}`)
          .fontSize(12)
          .fontColor((this.recommendedWallpaper?.style.textColor) || '#d3d3d3')
          .opacity(0.8)
          .textAlign(TextAlign.Center)
          .width('100%')
      } else if (this.currentQuote) {
        // 当前模式或推荐内容不存在时显示当前内容
        Text(this.formatQuoteText(this.currentQuote.text))
          .fontSize((this.currentWallpaper?.style.fontSize) || 24)
          .fontColor((this.currentWallpaper?.style.textColor) || '#d3d3d3')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 40 })
          .maxLines(20)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.currentQuote.author || ''}${(this.currentQuote.author && this.currentQuote.source) ? ' · ' : ''}${this.currentQuote.source || ''}`)
          .fontSize(12)
          .fontColor((this.currentWallpaper?.style.textColor) || '#d3d3d3')
          .opacity(0.8)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(24)
    .width('100%')
    .height('100%')
    .backgroundColor(this.previewBackground || '#667eea')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .id('pureWallpaperArea')
    .position({ x: -2000, y: 0 }) // 移到屏幕外，不可见但可以截图
  }
}