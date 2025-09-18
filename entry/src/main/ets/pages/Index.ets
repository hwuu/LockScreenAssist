import { Quote } from '../common/QuoteData';
import { GeneratedWallpaper } from '../services/WallpaperService';
import { WallpaperConfig } from '../common/ScheduleConfig';
import router from '@ohos.router';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { AppInitializationService } from '../services/AppInitializationService';
import { QuotePageService } from '../services/QuotePageService';
import { WallpaperUIService } from '../services/WallpaperUIService';
import { UIAnimationService } from '../services/UIAnimationService';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import common from '@ohos.app.ability.common';
// SaveButton is not available in HarmonyOS API, using regular Button instead



@Entry
@Component
struct Index {
  @State currentQuote: Quote | null = null;
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

  // 上下翻页相关状态
  @State currentPageIndex: number = 0;
  @State quoteDataSource: QuoteDataSource = new QuoteDataSource();
  @State wallpaperList: (GeneratedWallpaper | null)[] = [];
  @State optimizedFontSizes: number[] = []; // 存储每页优化后的字体大小

  // 服务依赖注入
  private appInitService: AppInitializationService | null = null;
  private quotePageService: QuotePageService | null = null;
  private wallpaperUIService: WallpaperUIService | null = null;
  private uiAnimationService: UIAnimationService | null = null;










  async aboutToAppear() {
    // 初始化服务
    this.appInitService = new AppInitializationService();
    this.wallpaperUIService = new WallpaperUIService();

    // 初始化UI动画服务，传入回调函数
    this.uiAnimationService = new UIAnimationService((opacity: number) => {
      // 使用动画更新透明度
      animateTo({
        duration: opacity > this.hintOpacity ? 2000 : 1000,
        curve: Curve.EaseInOut
      }, () => {
        this.hintOpacity = opacity;
      });
    });

    // 应用初始化
    const initResult = await this.appInitService.initializeApp();

    this.screenWidth = initResult.screenInfo.width;
    this.screenHeight = initResult.screenInfo.height;
    this.screenRatio = initResult.screenInfo.ratio;
    this.config = initResult.config;
    this.currentQuote = initResult.currentQuote;
    this.currentWallpaper = initResult.currentWallpaper;

    // 初始化名言页面服务
    this.quotePageService = new QuotePageService(this.screenWidth, this.screenHeight);

    // 初始化名言列表
    const quoteResult = await this.quotePageService.initializeQuoteList(
      this.currentQuote,
      this.currentWallpaper,
      this.quoteDataSource,
      this.wallpaperList,
      this.optimizedFontSizes
    );

    this.currentQuote = quoteResult.quote;
    this.currentWallpaper = quoteResult.wallpaper;

    // 更新预览和背景
    await this.updatePreview();
    await this.updateBackgroundForCurrentPage(this.currentPageIndex);

    // 启动提示定时器
    this.uiAnimationService?.startHintTimer();
  }







  // 获取当前页面的名言和壁纸
  getCurrentQuote(): Quote | null {
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

      const currentWallpaper = this.getCurrentWallpaper();
      const newBackground = await this.wallpaperUIService?.updatePreview(currentWallpaper) || '#2c3e50';

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
    if (this.quotePageService) {
      await this.quotePageService.loadMoreIfNeeded(
        currentIndex,
        this.quoteDataSource,
        this.wallpaperList,
        this.optimizedFontSizes
      );
    }
  }

  // 更新当前页面的背景颜色
  async updateBackgroundForCurrentPage(index: number) {
    try {
      const newBackground = await this.wallpaperUIService?.updateBackgroundForCurrentPage(index, this.wallpaperList) || '#2c3e50';

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
      const context = getContext(this) as common.UIAbilityContext;
      const result = await this.wallpaperUIService?.applyWallpaperOptions(
        this.setLockScreen,
        this.saveToGallery,
        context
      );

      if (result) {
        console.log('壁纸操作完成:', result.message);
      }
    } catch (error) {
      console.error('应用壁纸失败:', error);
    } finally {
      this.isApplying = false;
      this.showSaveDialog = false;
    }
  }

  /**
   * 智能格式化名言文本，避免孤行和标点符号行首
   * @param text 原始文本
   * @param fontSize 字体大小
   * @param containerWidth 容器宽度
   * @returns 格式化后的文本布局结果
   */
  formatQuoteText(text: string, fontSize?: number, containerWidth?: number): TextLayoutResult {
    if (this.quotePageService) {
      return this.quotePageService.formatQuoteText(text, fontSize, containerWidth);
    }

    // 降级处理
    return {
      text: text,
      fontSize: fontSize || 24,
      lines: [text]
    };
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
            Text(this.formatQuoteText(quote.text).text)
              .fontSize(this.optimizedFontSizes[index] || (this.wallpaperList[index]?.style.fontSize) || 24)
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
          this.uiAnimationService?.resetHintTimer(); // 滑动切换时重置提示文字定时器
        }
      })
      .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
        this.uiAnimationService?.resetHintTimer(); // 滑动手势开始时立即重置提示文字定时器
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
          this.uiAnimationService?.resetHintTimer(); // 长按时重置提示文字定时器
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
      if (this.getCurrentQuote()) {
        // 显示当前页面的内容
        Text(this.formatQuoteText(this.getCurrentQuote()?.text || '').text)
          .fontSize(this.optimizedFontSizes[this.currentPageIndex] || (this.getCurrentWallpaper()?.style.fontSize) || 24)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || '#d3d3d3')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 40 })
          .maxLines(20)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.getCurrentQuote()?.author || ''}${(this.getCurrentQuote()?.author && this.getCurrentQuote()?.source) ? ' · ' : ''}${this.getCurrentQuote()?.source || ''}`)
          .fontSize(12)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || '#d3d3d3')
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