import { QuoteData, Quote } from '../common/QuoteData';
import { QuoteSelectionService } from '../services/QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper, WallpaperStyle, WallpaperOperationResult } from '../services/WallpaperService';
import router from '@ohos.router';
import { ScheduleConfig, WallpaperConfig } from '../common/ScheduleConfig';
import display from '@ohos.display';
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
// SaveButton is not available in HarmonyOS API, using regular Button instead

// 数据源类实现，参考helper6_page_turn.txt第68-74行
class QuoteDataSource implements IDataSource {
  private quotes: Quote[] = [];
  private listeners: DataChangeListener[] = [];

  public totalCount(): number {
    return this.quotes.length;
  }

  public getData(index: number): Quote {
    return this.quotes[index];
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  public pushItem(quote: Quote): void {
    this.quotes.push(quote);
    this.notifyDataAdd(this.quotes.length - 1);
  }

  public addItem(quote: Quote): void {
    this.quotes.unshift(quote);
    this.notifyDataAdd(0);
  }

  private notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    });
  }
}

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
  @State setLockScreen: boolean = false; // 官方已不支持该功能
  @State saveToGallery: boolean = true; // 默认选中保存到图库
  @State isApplying: boolean = false; // 应用壁纸的状态
  @State hintOpacity: number = 0; // 提示文字透明度
  @State contentOpacity: number = 1; // 内容区域透明度
  @State isTransitioning: boolean = false; // 是否在过渡动画中
  private hintTimer: number = -1; // 提示文字定时器
  private debounceTimer: number = -1; // 防抖定时器
  private blinkTimer: number = -1; // 闪烁动画定时器
  @State isBlinking: boolean = false; // 是否正在闪烁

  // 上下翻页相关状态
  @State currentPageIndex: number = 0;
  @State quoteDataSource: QuoteDataSource = new QuoteDataSource();
  @State wallpaperList: (GeneratedWallpaper | null)[] = [];

  async aboutToAppear() {
    await this.getScreenRatio();
    await this.loadConfig();
    await this.loadQuoteSource();
    await this.initializeQuoteList();
    await this.updatePreview();
    await this.updateBackgroundForCurrentPage(this.currentPageIndex); // 初始化背景
    this.startHintTimer();
  }

  // 初始化名言列表，参考helper6_page_turn.txt第57-65行
  async initializeQuoteList() {
    try {
      // 先加载当前名言
      this.quoteDataSource.pushItem(this.currentQuote);
      this.wallpaperList.push(await WallpaperService.getCurrentWallpaper());

      // 加载推荐名言
      if (this.config) {
        for (let i = 0; i < 10; i++) { // 预加载10条名言
          try {
            const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1);
            if (recommendedQuotes && recommendedQuotes.length > 0) {
              const quote = recommendedQuotes[0];
              this.quoteDataSource.pushItem(quote);
              const wallpaper = await WallpaperService.generateWallpaper(quote);
              this.wallpaperList.push(wallpaper);
            }
          } catch (error) {
            console.error('Failed to load recommended quote:', error);
            // 加载默认名言作为备选
            const fallbackQuote = QuoteData.getRandomQuote();
            this.quoteDataSource.pushItem(fallbackQuote);
            this.wallpaperList.push(null);
          }
        }
      }
    } catch (error) {
      console.error('Failed to initialize quote list:', error);
    }
  }

  async loadQuoteSource() {
    try {
      const QuoteDataModule = await import('../common/QuoteData');
      await QuoteDataModule.QuoteData.loadQuoteSource();
    } catch (error) {
      console.error('Failed to load quote source in Index:', error);
    }
  }

  // 启动提示文字定时器
  startHintTimer() {
    this.clearHintTimer();
    this.hintTimer = setTimeout(() => {
      this.showHint();
    }, 4000);
  }

  // 清除提示文字定时器
  clearHintTimer() {
    if (this.hintTimer !== -1) {
      clearTimeout(this.hintTimer);
      this.hintTimer = -1;
    }
  }

  // 清除闪烁定时器
  clearBlinkTimer() {
    if (this.blinkTimer !== -1) {
      clearTimeout(this.blinkTimer);
      this.blinkTimer = -1;
    }
  }

  // 显示提示文字
  showHint() {
    animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      onFinish: () => {
        // 渐入动画完成后开始闪烁效果
        this.startBlinkEffect();
      }
    }, () => {
      this.hintOpacity = 0.8;
    });
  }

  // 开始闪烁效果
  startBlinkEffect() {
    // 移除透明度检查，因为呼吸循环会改变透明度
    this.isBlinking = true;
    this.blinkCycle();
  }

  // 呼吸循环（模仿人类平静呼吸）
  blinkCycle() {
    if (!this.isBlinking) {
      // 如果不在闪烁状态，停止呼吸
      return;
    }

    // 第一阶段：静止等待2秒（呼吸间隙）
    this.blinkTimer = setTimeout(() => {
      if (!this.isBlinking) return;

      // 第二阶段：缓慢"呼气"3秒
      animateTo({
        duration: 3000,
        curve: Curve.EaseInOut, // 平缓的缓动曲线，模仿自然呼吸
        onFinish: () => {
          // 呼气动画完成后，开始底部停顿
          if (!this.isBlinking) return;

          // 第三阶段：底部停顿5秒
          setTimeout(() => {
            if (!this.isBlinking) return;

            // 第四阶段：缓慢"吸气"2.5秒，从0.1恢复到0.8
            animateTo({
              duration: 2500,
              curve: Curve.EaseInOut,
              onFinish: () => {
                // 完成一轮呼吸后继续下一轮
                if (this.isBlinking) {
                  this.blinkCycle();
                }
              }
            }, () => {
              this.hintOpacity = 0.8;
            });
          }, 500); // 底部停顿0.5秒
        }
      }, () => {
        this.hintOpacity = 0.1;
      });
    }, 2000); // 初始静止2秒
  }

  // 停止闪烁效果
  stopBlinkEffect() {
    this.isBlinking = false;
    this.clearBlinkTimer();
  }

  // 隐藏提示文字
  hideHint() {
    // 停止闪烁效果
    this.stopBlinkEffect();

    // 只有在当前显示状态下才执行隐藏动画
    if (this.hintOpacity > 0) {
      // 添加短暂延迟，确保呼吸动画完全停止
      setTimeout(() => {
        animateTo({
          duration: 1000,
          curve: Curve.EaseInOut
        }, () => {
          this.hintOpacity = 0;
        });
      }, 50); // 50ms延迟确保状态同步
    }
  }

  // 重置提示文字定时器（带防抖）
  resetHintTimer() {
    // 停止闪烁效果
    this.stopBlinkEffect();

    // 清除防抖定时器
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }

    // 设置防抖，200ms内的连续操作只执行最后一次
    this.debounceTimer = setTimeout(() => {
      // 立即清除定时器，避免重复触发
      this.clearHintTimer();
      // 只有在显示状态下才执行隐藏动画
      this.hideHint();
      // 重新启动定时器
      this.startHintTimer();
      this.debounceTimer = -1;
    }, 200);
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

  // 获取当前页面的名言和壁纸
  getCurrentQuote(): Quote {
    if (this.quoteDataSource.totalCount() > this.currentPageIndex) {
      return this.quoteDataSource.getData(this.currentPageIndex);
    }
    return this.currentQuote;
  }

  getCurrentWallpaper(): GeneratedWallpaper | null {
    if (this.wallpaperList.length > this.currentPageIndex) {
      return this.wallpaperList[this.currentPageIndex];
    }
    return this.currentWallpaper;
  }


  async updatePreview() {
    try {
      // 设置过渡状态，禁用手势响应
      this.isTransitioning = true;

      let newBackground = '#2c3e50';
      const currentWallpaper = this.getCurrentWallpaper();

      if (currentWallpaper) {
        const previewResult = WallpaperService.createWallpaperPreview(currentWallpaper);
        if (previewResult) {
          newBackground = previewResult;
        } else {
          newBackground = currentWallpaper.style.backgroundColor || '#2c3e50';
        }
      }

      // 内容淡出 -> 更新背景和内容 -> 内容淡入
      // 第一阶段：内容淡出
      animateTo({
        duration: 250,
        curve: Curve.EaseInOut
      }, () => {
        this.contentOpacity = 0;
      });

      // 第二阶段：更新背景，然后内容淡入
      setTimeout(() => {
        animateTo({
          duration: 250,
          curve: Curve.EaseInOut
        }, () => {
          this.previewBackground = newBackground;
          this.contentOpacity = 1;
        });

        // 动画完成后恢复手势响应
        setTimeout(() => {
          this.isTransitioning = false;
        }, 250);
      }, 250);

      setTimeout(() => {
        console.log('Preview updated:', this.previewBackground);
      }, 0);
    } catch (error) {
      console.error('Failed to update preview:', error);
      animateTo({
        duration: 500,
        curve: Curve.EaseInOut
      }, () => {
        this.previewBackground = '#2c3e50';
        this.contentOpacity = 1;
      });

      // 错误情况下也要恢复手势响应
      setTimeout(() => {
        this.isTransitioning = false;
      }, 500);
    }
  }

  // 页面滚动时的回调，参考helper6_page_turn.txt第101-103行
  onScrollIndex(firstIndex: number) {
    this.currentPageIndex = firstIndex;
    console.log('Current page index:', this.currentPageIndex);
    // 异步加载更多内容
    this.loadMoreIfNeeded(firstIndex);
  }

  // 按需加载更多内容
  async loadMoreIfNeeded(currentIndex: number) {
    const totalCount = this.quoteDataSource.totalCount();

    // 限制最多加载100条内容
    if (totalCount >= 100) {
      console.log('已达到最大加载数量限制(100条)');
      return;
    }

    // 当滚动到倒数第3项时，预加载更多内容
    if (currentIndex >= totalCount - 3) {
      try {
        // 计算还能加载多少条，避免超过100条限制
        const remainingCount = 100 - totalCount;
        const loadCount = Math.min(5, remainingCount); // 预加载5条或剩余数量

        for (let i = 0; i < loadCount; i++) {
          const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1);
          if (recommendedQuotes && recommendedQuotes.length > 0) {
            const quote = recommendedQuotes[0];
            this.quoteDataSource.pushItem(quote);
            const wallpaper = await WallpaperService.generateWallpaper(quote);
            this.wallpaperList.push(wallpaper);
          }
        }

        console.log(`加载了${loadCount}条内容，当前总数：${this.quoteDataSource.totalCount()}`);
      } catch (error) {
        console.error('Failed to load more quotes:', error);
      }
    }
  }

  // 更新当前页面的背景颜色
  async updateBackgroundForCurrentPage(index: number) {
    try {
      let newBackground = '#2c3e50';

      if (this.wallpaperList.length > index && this.wallpaperList[index] !== null) {
        const wallpaper = this.wallpaperList[index];
        if (wallpaper) {
          const previewResult = WallpaperService.createWallpaperPreview(wallpaper);
          if (previewResult) {
            newBackground = previewResult;
          } else {
            newBackground = wallpaper.style.backgroundColor || '#2c3e50';
          }
        }
      }

      // 使用动画更新背景
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.previewBackground = newBackground;
      });

      console.log('Background updated for page:', index, newBackground);
    } catch (error) {
      console.error('Failed to update background for current page:', error);
    }
  }


  async applyWallpaperOptions() {
    if (!this.setLockScreen && !this.saveToGallery) {
      this.showSaveDialog = false;
      return;
    }

    this.isApplying = true;

    try {
      console.log('开始应用壁纸操作...');

      // 使用componentSnapshot API截图纯净壁纸区域
      componentSnapshot.get("pureWallpaperArea", async (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          console.error("截图失败: " + JSON.stringify(error));
          this.isApplying = false;
          this.showSaveDialog = false;
          return;
        }

        try {
          // 将PixelMap保存为JPEG格式
          const packOpts: image.PackingOption = {
            format: "image/jpeg",
            quality: 98
          };

          const imagePacker: image.ImagePacker = image.createImagePacker();
          const arrayBuffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

          // 创建临时文件
          const context = getContext(this) as common.UIAbilityContext;
          const filesDir: string = context.filesDir;
          const tempImagePath = `${filesDir}/temp_wallpaper_${Date.now()}.jpg`;

          // 保存临时文件
          const file = await fs.open(tempImagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
          await fs.write(file.fd, arrayBuffer);
          await fs.close(file.fd);

          // 执行选定的操作
          const results = await WallpaperService.applyWallpaperOperations(
            tempImagePath,
            this.setLockScreen,
            this.saveToGallery
          );

          // 显示结果
          let message = '';
          if (this.setLockScreen && results.lockScreenSuccess) {
            message += '锁屏壁纸设置成功！';
          } else if (this.setLockScreen && !results.lockScreenSuccess) {
            message += '锁屏壁纸设置失败！';
          }

          if (this.saveToGallery && results.gallerySuccess) {
            if (message) message += '\n';
            message += '图片已保存到图库！';
          } else if (this.saveToGallery && !results.gallerySuccess) {
            if (message) message += '\n';
            message += '图片保存到图库失败！';
          }

          console.log('壁纸操作完成:', message);

          // 清理临时文件
          try {
            await fs.unlink(tempImagePath);
          } catch (unlinkError) {
            console.error('清理临时文件失败:', unlinkError);
          }

          // 释放资源
          imagePacker.release();
          pixelMap.release();

        } catch (packError) {
          console.error('图片处理失败:', packError);
          pixelMap.release();
        } finally {
          this.isApplying = false;
          this.showSaveDialog = false;
        }
      });

    } catch (error) {
      console.error('应用壁纸失败:', error);
      this.isApplying = false;
      this.showSaveDialog = false;
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
    const context = getContext(this) as common.UIAbilityContext;
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

      // 上下翻页的名言文本层，使用Swiper实现分页效果，参考helper6_page_turn.txt第38-54行
      Swiper() {
        LazyForEach(this.quoteDataSource, (quote: Quote, index: number) => {
          Column() {
            Text(this.formatQuoteText(quote.text))
              .fontSize((this.wallpaperList[index]?.style.fontSize) || 24)
              .fontColor((this.wallpaperList[index]?.style.textColor) || '#d3d3d3')
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ bottom: 40 })
              .maxLines(20)
              .textOverflow({ overflow: TextOverflow.None })

            Text(`—— ${quote.author || ''}${(quote.author && quote.source) ? ' · ' : ''}${quote.source || ''}`)
              .fontSize(12)
              .fontColor((this.wallpaperList[index]?.style.textColor) || '#d3d3d3')
              .opacity(0.8)
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding(24)
          .width('100%')
          .height('100%')
        }, (quote: Quote, index: number) => `${quote.text}-${index}`)
      }
      .index(this.currentPageIndex)
      .width('100%')
      .height('100%')
      .indicator(false) // 隐藏指示器
      .vertical(true) // 设置为垂直方向滑动
      .loop(false) // 禁用循环滚动，防止在边界时继续滑动
      .cachedCount(3) // 参考helper6_page_turn.txt第53行，设置缓存数量
      .onChange((index: number) => {
        // 确保索引在有效范围内
        if (index >= 0 && index < this.quoteDataSource.totalCount()) {
          this.onScrollIndex(index);
          this.updateBackgroundForCurrentPage(index);
          this.resetHintTimer(); // 滑动切换时重置提示文字定时器
        }
      })
      .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
        this.resetHintTimer(); // 滑动手势开始时立即重置提示文字定时器
      })
      .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
        // 防止向前滑动超出边界
        if (targetIndex < 0) {
          console.log('防止向前滑动超出边界');
          return;
        }
        // 防止向后滑动超出边界
        if (targetIndex >= this.quoteDataSource.totalCount()) {
          console.log('防止向后滑动超出边界');
          return;
        }
      })

      // 顶部标题栏 - 半透明层
      Row() {
        Blank()

        Button() {
          Text('...')
            .fontSize(18)
            .fontColor('#ffffff')
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255, 255, 255, 0)')
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

      // 底部提示文字 - 半透明层
      Column() {
        Text('上下滑动切换 · 长按保存')
          .fontSize(14)
          .fontColor('#ffffff')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12, left: 24, right: 24 })
          .borderRadius(12)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 30, top: 20 })
      .backgroundColor('rgba(0, 0, 0, 0)')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
      .opacity(this.hintOpacity)

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
      // 长按手势：保存壁纸
      LongPressGesture({ fingers: 1, repeat: false, duration: 800 })
        .onAction(() => {
          this.resetHintTimer(); // 长按时重置提示文字定时器
          this.showSaveDialog = true;
        })
    )
    .bindContentCover(this.showSaveDialog, this.buildSaveDialog(), ModalTransition.NONE)
  }


  @Builder
  buildSaveDialog() {
    Column() {
      Column() {
        Text('应用壁纸')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .margin({ bottom: 16 })

        Text('请选择要执行的操作：')
          .fontSize(16)
          .fontColor('#7f8c8d')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        // 选项区域
        Column() {
          Column() {
            Row() {
              Checkbox({ name: 'setLockScreen', group: 'wallpaperOptions' })
                .select(this.setLockScreen)
                .selectedColor('#5b9bd5')
                .onChange((value: boolean) => {
                  this.setLockScreen = value;
                })
                .margin({ right: 12 })
                .enabled(false)

              Text('设置为系统锁屏壁纸')
                .fontSize(16)
                .fontColor('#bdc3c7')
                .flexGrow(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 8, bottom: 4 })

            Text('官方已不支持该功能，需保存图片后手动设置')
              .fontSize(12)
              .fontColor('#95a5a6')
              .width('100%')
              .margin({ left: 32, bottom: 4 })
          }

          Row() {
            Checkbox({ name: 'saveToGallery', group: 'wallpaperOptions' })
              .select(this.saveToGallery)
              .selectedColor('#5b9bd5')
              .onChange((value: boolean) => {
                this.saveToGallery = value;
              })
              .margin({ right: 12 })

            Text('保存到系统图库')
              .fontSize(16)
              .fontColor('#2c3e50')
              .flexGrow(1)
              .onClick(() => {
                this.saveToGallery = !this.saveToGallery;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 8, bottom: 8 })
        }
        .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .backgroundColor('#ffffff')
            .fontColor('#7f8c8d')
            .borderRadius(6)
            .border({ width: 1, color: '#bdc3c7' })
            .enabled(!this.isApplying)
            .onClick(() => {
              this.showSaveDialog = false;
            })

          Button() {
            if (this.isApplying) {
              Row() {
                LoadingProgress()
                  .width(16)
                  .height(16)
                  .color('#ffffff')
                  .margin({ right: 8 })
                Text('应用中...')
                  .fontSize(14)
                  .fontColor('#ffffff')
              }
            } else {
              Text('确定')
                .fontSize(16)
                .fontColor('#ffffff')
            }
          }
          .width('45%')
          .height(40)
          .backgroundColor('#5b9bd5')
          .borderRadius(6)
          .margin({ left: '10%' })
          .enabled(!this.isApplying && (this.setLockScreen || this.saveToGallery))
          .onClick(async () => {
            await this.applyWallpaperOptions();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('85%')
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
      if (!this.isApplying) {
        this.showSaveDialog = false;
      }
    })
  }

  @Builder
  buildPureWallpaper() {
    // 纯净的壁纸组件，只包含背景色和文字，用于截图保存
    // 注意：截图组件不使用动画，始终显示完整内容
    Column() {
      if (this.quoteDataSource.totalCount() > this.currentPageIndex) {
        // 显示当前页面的内容
        Text(this.formatQuoteText(this.getCurrentQuote().text))
          .fontSize((this.getCurrentWallpaper()?.style.fontSize) || 24)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || '#d3d3d3')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 40 })
          .maxLines(20)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.getCurrentQuote().author || ''}${(this.getCurrentQuote().author && this.getCurrentQuote().source) ? ' · ' : ''}${this.getCurrentQuote().source || ''}`)
          .fontSize(12)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || '#d3d3d3')
          .opacity(0.8)
          .textAlign(TextAlign.Center)
          .width('100%')
      } else if (this.currentQuote) {
        // 备用：显示默认内容
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