import { QuoteData, Quote } from '../common/QuoteData';
import { QuoteSelectionService } from '../services/QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper, WallpaperStyle } from '../services/WallpaperService';
import router from '@ohos.router';
import { ScheduleConfig, WallpaperConfig } from '../common/ScheduleConfig';
import display from '@ohos.display';
import componentSnapshot from '@ohos.arkui.componentSnapshot';

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
  @State showConfirmDialog: boolean = false;
  @State showSaveDialog: boolean = false;
  @State screenRatio: number = 16/9; // 默认比例

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
      console.log(`Screen ratio: ${this.screenRatio} (${defaultDisplay.width}x${defaultDisplay.height})`);
    } catch (error) {
      console.error('Failed to get screen ratio:', error);
      this.screenRatio = 16/9; // 保持默认比例
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

  async confirmChange() {
    if (this.previewMode === 'recommended' && this.recommendedQuote && this.recommendedWallpaper) {
      try {
        this.isLoading = true;
        this.currentQuote = this.recommendedQuote;
        this.currentWallpaper = this.recommendedWallpaper;
        await WallpaperService.applyWallpaper(this.currentWallpaper);
        this.previewMode = 'current';
        await this.updatePreview();
      } catch (error) {
        console.error('Failed to apply wallpaper:', error);
      } finally {
        this.isLoading = false;
      }
    }
  }

  async savePreviewImage() {
    try {
      console.log('Screenshot functionality disabled - requires updated API');

      // 注意：实际保存到相册需要额外的权限和API支持
      // 这里只是演示截图功能，实际保存功能需要在真机上实现

    } catch (error) {
      console.error('Failed to capture screenshot:', error);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('锁屏壁纸助手')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')

        Blank()

        Button() {
          Text('⚙')
            .fontSize(20)
            .fontColor('#666')
        }
        .width(40)
        .height(40)
        .backgroundColor('#f5f5f5')
        .borderRadius(20)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/Settings'
          });
        })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20, bottom: 20 })
      .backgroundColor('#ffffff')

      // 主要内容区域
      Column() {
        // 壁纸预览
        Column() {
          // 预览区域（设备屏幕比例）
          Stack() {
            // 背景
            Column()
              .width('100%')
              .aspectRatio(1/this.screenRatio)
              .backgroundColor(this.previewBackground || '#667eea')
              .borderRadius(12)

            // 名言文本
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
                Text(this.recommendedQuote.text)
                  .fontSize((this.recommendedWallpaper?.style.fontSize) || 24)
                  .fontColor((this.recommendedWallpaper?.style.textColor) || '#d3d3d3')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .margin({ bottom: 20 })

                Text(`—— ${this.recommendedQuote.author || ''}${(this.recommendedQuote.author && this.recommendedQuote.source) ? ' · ' : ''}${this.recommendedQuote.source || ''}`)
                  .fontSize(12)
                  .fontColor((this.recommendedWallpaper?.style.textColor) || '#d3d3d3')
                  .opacity(0.8)
                  .textAlign(TextAlign.Center)
                  .width('100%')
              } else if (this.currentQuote) {
                // 当前模式或推荐内容不存在时显示当前内容
                Text(this.currentQuote.text)
                  .fontSize((this.currentWallpaper?.style.fontSize) || 24)
                  .fontColor((this.currentWallpaper?.style.textColor) || '#d3d3d3')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .margin({ bottom: 20 })

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
            .padding(16)
            .width('100%')
            .height('100%')

          }
          .width('100%')
          .borderRadius(12)
          .shadow({
            radius: 8,
            color: '#00000020',
            offsetX: 0,
            offsetY: 4
          })
          .id('previewArea')
          .gesture(
            LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
              .onAction(() => {
                this.showSaveDialog = true;
              })
          )
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#ffffff')
        .borderRadius(12)
        .margin({ bottom: 16 })
      }
      .layoutWeight(1)
      .backgroundColor('#f8f9fa')

      // 底部操作按钮
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
        .width('40%')
        .height(40)
        .backgroundColor('#5b9bd5')
        .borderRadius(20)
        .enabled(!this.isLoading)
        .onClick(async () => {
          await this.recommendNext();
        })

        Button(' ✓')
          .width('20%')
          .height(36)
          .fontSize(18)
          .backgroundColor('#ffffff')
          .fontColor(this.previewMode === 'recommended' && this.recommendedWallpaper !== null ? '#5b9bd5' : '#bdc3c7')
          .borderRadius(18)
          .border({ width: 2, color: this.previewMode === 'recommended' && this.recommendedWallpaper !== null ? '#5b9bd5' : '#bdc3c7' })
          .margin({ left: 10, right: 10 })
          .enabled(this.previewMode === 'recommended' && this.recommendedWallpaper !== null && !this.isLoading)
          .onClick(() => {
            this.showConfirmDialog = true;
          })

        Button('↶')
          .width('20%')
          .height(36)
          .fontSize(18)
          .backgroundColor('#ffffff')
          .fontColor(this.previewMode === 'current' ? '#bdc3c7' : '#5b9bd5')
          .borderRadius(18)
          .border({ width: 2, color: this.previewMode === 'current' ? '#bdc3c7' : '#5b9bd5' })
          .enabled(this.previewMode !== 'current' && !this.isLoading)
          .onClick(async () => {
            await this.viewCurrent();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 0, right: 0, bottom: 10, top: 10 })
      .backgroundColor('#ffffff')

      // 加载提示
      if (this.isLoading) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('#00000040')

          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .margin({ bottom: 12 })

            Text('正在生成壁纸...')
              .fontSize(16)
              .fontColor('#ffffff')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width(120)
          .height(120)
          .backgroundColor('#2c3e50')
          .borderRadius(12)
        }
        .width('100%')
        .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f9fa')
    .bindContentCover(this.showConfirmDialog, this.buildConfirmDialog(), ModalTransition.NONE)
    .bindContentCover(this.showSaveDialog, this.buildSaveDialog(), ModalTransition.NONE)
  }

  @Builder
  buildConfirmDialog() {
    Column() {
      Column() {
        Text('确认设置壁纸')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .margin({ bottom: 16 })

        Text('确定要将此壁纸设置为锁屏壁纸吗？')
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
              this.showConfirmDialog = false;
            })

          Button('确定')
            .width('45%')
            .height(40)
            .backgroundColor('#5b9bd5')
            .fontColor('#ffffff')
            .borderRadius(6)
            .margin({ left: '10%' })
            .onClick(async () => {
              this.showConfirmDialog = false;
              await this.confirmChange();
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
      this.showConfirmDialog = false;
    })
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
              await this.savePreviewImage();
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
}