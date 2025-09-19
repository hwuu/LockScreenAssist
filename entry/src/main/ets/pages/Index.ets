import { Quote } from '../common/QuoteData';
import { GeneratedWallpaper } from '../services/WallpaperService';
import { WallpaperConfig } from '../common/ScheduleConfig';
import router from '@ohos.router';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { AppInitializationService } from '../services/AppInitializationService';
import { QuotePageService } from '../services/QuotePageService';
import { WallpaperUIService } from '../services/WallpaperUIService';
import { HintAnimationService } from '../services/HintAnimationService';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { UI_CONSTANTS } from '../common/UIConstants';
import { TopBarComponent } from '../components/TopBarComponent';
import { HintTextComponent } from '../components/HintTextComponent';
import { LoadingOverlayComponent } from '../components/LoadingOverlayComponent';
import { QuoteSwiperComponent } from '../components/QuoteSwiperComponent';
import common from '@ohos.app.ability.common';
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
  @State screenRatio: number = UI_CONSTANTS.DEFAULT_SCREEN_RATIO;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State setLockScreen: boolean = false;
  @State saveToGallery: boolean = true;
  @State isApplying: boolean = false;
  @State hintOpacity: number = 0;
  @State contentOpacity: number = 1;
  @State isTransitioning: boolean = false;

  @State currentPageIndex: number = 0;
  @Provide quoteDataSource: QuoteDataSource = new QuoteDataSource();
  @State wallpaperList: (GeneratedWallpaper | null)[] = [];
  @State optimizedFontSizes: number[] = [];

  private appInitService: AppInitializationService | null = null;
  private quotePageService: QuotePageService | null = null;
  private wallpaperUIService: WallpaperUIService | null = null;
  private hintAnimationService: HintAnimationService | null = null;

  async aboutToAppear() {
    console.log('CLAUDE_DEBUG: Index.aboutToAppear 开始');
    this.appInitService = new AppInitializationService();
    this.wallpaperUIService = new WallpaperUIService();

    this.hintAnimationService = new HintAnimationService((opacity: number, duration: number) => {
      animateTo({
        duration: duration,
        curve: Curve.EaseInOut
      }, () => {
        this.hintOpacity = opacity;
      });
    });
    const context = getContext(this) as common.UIAbilityContext;
    console.log('CLAUDE_DEBUG: Index 获取到context, 开始初始化应用');
    const initResult = await this.appInitService.initializeApp(context);
    console.log('CLAUDE_DEBUG: Index 应用初始化完成, initResult:', {
      hasQuote: !!initResult.currentQuote,
      hasWallpaper: !!initResult.currentWallpaper,
      screenInfo: initResult.screenInfo
    });

    this.screenWidth = initResult.screenInfo.width;
    this.screenHeight = initResult.screenInfo.height;
    this.screenRatio = initResult.screenInfo.ratio;
    this.config = initResult.config;
    this.currentQuote = initResult.currentQuote;
    this.currentWallpaper = initResult.currentWallpaper;

    console.log('CLAUDE_DEBUG: Index 当前名言:', this.currentQuote?.text || 'null');

    this.quotePageService = new QuotePageService(this.screenWidth, this.screenHeight);
    console.log('CLAUDE_DEBUG: Index 开始初始化QuoteList, currentQuote:', this.currentQuote?.text || 'null');
    const quoteResult = await this.quotePageService.initializeQuoteList({
      currentQuote: this.currentQuote,
      currentWallpaper: this.currentWallpaper,
      quoteDataSource: this.quoteDataSource,
      wallpaperList: this.wallpaperList,
      optimizedFontSizes: this.optimizedFontSizes
    });

    this.currentQuote = quoteResult.quote;
    this.currentWallpaper = quoteResult.wallpaper;
    console.log('CLAUDE_DEBUG: Index QuoteList初始化完成, 最终名言:', this.currentQuote?.text || 'null');

    await this.updatePreview();
    await this.updateBackgroundForCurrentPage(this.currentPageIndex);
    this.hintAnimationService?.startHintTimer();
  }







  getCurrentQuote(): Quote | null {
    const totalCount = this.quoteDataSource.totalCount();
    console.log(`CLAUDE_DEBUG: Index.getCurrentQuote pageIndex=${this.currentPageIndex}, totalCount=${totalCount}`);
    if (totalCount > this.currentPageIndex) {
      const quote = this.quoteDataSource.getData(this.currentPageIndex);
      console.log('CLAUDE_DEBUG: Index.getCurrentQuote 从DataSource获取:', quote?.text || 'null');
      return quote;
    }
    console.log('CLAUDE_DEBUG: Index.getCurrentQuote 使用currentQuote:', this.currentQuote?.text || 'null');
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
      this.isTransitioning = true;

      const currentWallpaper = this.getCurrentWallpaper();
      const newBackground = await this.wallpaperUIService?.updatePreview(currentWallpaper) || '#2c3e50';

      animateTo({
        duration: UI_CONSTANTS.ANIMATION_DURATION_SHORT,
        curve: Curve.EaseInOut
      }, () => {
        this.contentOpacity = 0;
      });

      setTimeout(() => {
        animateTo({
          duration: UI_CONSTANTS.ANIMATION_DURATION_SHORT,
          curve: Curve.EaseInOut
        }, () => {
          this.previewBackground = newBackground;
          this.contentOpacity = 1;
        });

        setTimeout(() => {
          this.isTransitioning = false;
        }, UI_CONSTANTS.ANIMATION_DURATION_SHORT);
      }, UI_CONSTANTS.ANIMATION_DURATION_SHORT);

      setTimeout(() => {
        console.log('Preview updated:', this.previewBackground);
      }, 0);
    } catch (error) {
      console.error('Failed to update preview:', error);
      animateTo({
        duration: UI_CONSTANTS.ANIMATION_DURATION_FADE,
        curve: Curve.EaseInOut
      }, () => {
        this.previewBackground = UI_CONSTANTS.DEFAULT_BACKGROUND_COLOR;
        this.contentOpacity = 1;
      });

      setTimeout(() => {
        this.isTransitioning = false;
      }, UI_CONSTANTS.ANIMATION_DURATION_FADE);
    }
  }

  onScrollIndex(firstIndex: number) {
    console.log('CLAUDE_DEBUG: Index.onScrollIndex 从', this.currentPageIndex, '到', firstIndex);
    this.currentPageIndex = firstIndex;
    console.log('CLAUDE_DEBUG: Index.onScrollIndex 更新后 currentPageIndex:', this.currentPageIndex);
    this.loadMoreIfNeeded(firstIndex);
  }

  async loadMoreIfNeeded(currentIndex: number) {
    if (this.quotePageService) {
      await this.quotePageService.loadMoreIfNeeded({
        currentIndex: currentIndex,
        quoteDataSource: this.quoteDataSource,
        wallpaperList: this.wallpaperList,
        optimizedFontSizes: this.optimizedFontSizes
      });
    }
  }

  async updateBackgroundForCurrentPage(index: number) {
    try {
      console.log('CLAUDE_DEBUG: Index.updateBackgroundForCurrentPage index:', index, 'wallpaperList.length:', this.wallpaperList.length);
      const newBackground = await this.wallpaperUIService?.updateBackgroundForCurrentPage(index, this.wallpaperList) || UI_CONSTANTS.DEFAULT_BACKGROUND_COLOR;

      console.log('CLAUDE_DEBUG: Index.updateBackgroundForCurrentPage 新背景色:', newBackground);
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.previewBackground = newBackground;
        console.log('CLAUDE_DEBUG: Index.updateBackgroundForCurrentPage 背景色已更新到:', this.previewBackground);
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
      const result = await this.wallpaperUIService?.applyWallpaperOptions({
        setLockScreen: this.setLockScreen,
        saveToGallery: this.saveToGallery,
        context: context
      });

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

    return {
      text: text,
      fontSize: fontSize || 24,
      lines: [text]
    };
  }


  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.previewBackground || UI_CONSTANTS.FALLBACK_BACKGROUND_COLOR)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      QuoteSwiperComponent({
        currentPageIndex: $currentPageIndex,
        wallpaperList: this.wallpaperList,
        optimizedFontSizes: this.optimizedFontSizes,
        contentOpacity: this.contentOpacity,
        formatQuoteText: this.formatQuoteText.bind(this),
        onScrollIndex: this.onScrollIndex.bind(this),
        updateBackgroundForCurrentPage: this.updateBackgroundForCurrentPage.bind(this),
        resetHintTimer: () => this.hintAnimationService?.resetHintTimer()
      })

      TopBarComponent()
      HintTextComponent({ hintOpacity: this.hintOpacity })
      LoadingOverlayComponent({ isLoading: this.isLoading })
      this.buildPureWallpaper()
    }
    .width('100%')
    .height('100%')
    .id('previewArea')
    .gesture(
      LongPressGesture({
        fingers: 1,
        repeat: false,
        duration: UI_CONSTANTS.LONG_PRESS_DURATION
      })
        .onAction(() => {
          this.hintAnimationService?.resetHintTimer();
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
    Column() {
      if (this.getCurrentQuote()) {
        Text(this.formatQuoteText(this.getCurrentQuote()?.text || '').text)
          .fontSize(this.optimizedFontSizes[this.currentPageIndex] || (this.getCurrentWallpaper()?.style.fontSize) || UI_CONSTANTS.DEFAULT_FONT_SIZE)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: UI_CONSTANTS.TEXT_BOTTOM_MARGIN })
          .maxLines(UI_CONSTANTS.TEXT_LAYOUT.MAX_LINES)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.getCurrentQuote()?.author || ''}${(this.getCurrentQuote()?.author && this.getCurrentQuote()?.source) ? ' · ' : ''}${this.getCurrentQuote()?.source || ''}`)
          .fontSize(UI_CONSTANTS.AUTHOR_FONT_SIZE)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
          .opacity(UI_CONSTANTS.AUTHOR_TEXT_OPACITY)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(UI_CONSTANTS.CONTAINER_PADDING)
    .width('100%')
    .height('100%')
    .backgroundColor(this.previewBackground || UI_CONSTANTS.FALLBACK_BACKGROUND_COLOR)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .id('pureWallpaperArea')
    .position({ x: UI_CONSTANTS.PURE_WALLPAPER_OFFSET_X, y: 0 })
  }
}