import { Quote, QuoteData } from '../common/QuoteData';
import { CardService, Card } from '../services/CardService';
import { WallpaperConfig } from '../common/ScheduleConfig';
import router from '@ohos.router';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { AppInitializationService } from '../services/AppInitializationService';
import { QuotePageService } from '../services/QuotePageService';
import { CardUIService } from '../services/CardUIService';
import { HintAnimationService } from '../services/HintAnimationService';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { UI_CONSTANTS } from '../common/UIConstants';
import { TopBarComponent } from '../components/TopBarComponent';
import { HintTextComponent } from '../components/HintTextComponent';
import { LoadingOverlayComponent } from '../components/LoadingOverlayComponent';
import { LinearProgressComponent } from '../components/LinearProgressComponent';
import { QuoteSwiperComponent } from '../components/QuoteSwiperComponent';
import { AutoPlayService, PlayState } from '../services/AutoPlayService';
import common from '@ohos.app.ability.common';
@Entry
@Component
struct Index {
  @State currentQuote: Quote | null = null;
  @State currentCard: Card | null = null;
  @State isLoading: boolean = false;
  @StorageLink('quoteSourceChanged') @Watch('onQuoteSourceChanged') quoteSourceChanged: boolean = false;
  @State previewMode: 'current' | 'recommended' = 'current';
  @State recommendedQuote: Quote | null = null;
  @State recommendedCard: Card | null = null;
  @State usedRecommendations: Set<string> = new Set();

  // 自动播放相关状态
  @State playState: PlayState = PlayState.IDLE;
  @State isAutoPlaying: boolean = false;
  @State isStopping: boolean = false;
  @State showLoadingIcon: boolean = false;
  @State currentBackgroundOpacity: number = 1;
  @State nextBackgroundOpacity: number = 0;
  @State currentBackground: string = '';
  @State nextBackground: string = '';
  @State textOpacity: number = 1;
  @State currentSpeedUpFactor: number = 1;  // 当前速度倍数
  @State idleProgressPercentage: number = 0;  // IDLE进度百分比
  @State idleDuration: number = 0;  // IDLE总时长
  @State progressOpacity: number = 1;  // 进度圆圈透明度

  // 线性进度条状态
  @State linearProgressWidth: number = 0;      // 线性进度条宽度 (0-100)
  @State linearProgressOpacity: number = 0;    // 线性进度条透明度
  @State showLinearProgress: boolean = true;   // 是否启用线性进度条

  // 时间配置
  @State displayDuration: number = 8000;   // 完整显示时间（现在仅作为参考，实际根据文字长度动态计算）
  @State textFadeDuration: number = 1000;   // 文字淡入淡出时间
  @State bgFadeDuration: number = 500;     // 背景淡入淡出时间
  @State holdDuration: number = 250;       // 保持时间

  @State config: WallpaperConfig | null = null;
  @State showSaveDialog: boolean = false;
  @State screenRatio: number = UI_CONSTANTS.DEFAULT_SCREEN_RATIO;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State previewBackground: string = '#000000';  // 初始为纯黑色
  @State setLockScreen: boolean = false;
  @State saveToGallery: boolean = true;
  @State isApplying: boolean = false;
  @State hintOpacity: number = 0;
  @State contentOpacity: number = 0;  // 初始为0，避免闪烁
  @State isTransitioning: boolean = false;
  @State isInitialLoad: boolean = true;  // 标记是否是初次加载

  @State currentPageIndex: number = 0;
  @Provide quoteDataSource: QuoteDataSource = new QuoteDataSource();
  @State cardList: (Card | null)[] = [];
  @State optimizedFontSizes: number[] = [];

  private appInitService: AppInitializationService | null = null;
  private quotePageService: QuotePageService | null = null;
  private hintAnimationService: HintAnimationService | null = null;
  private autoPlayService: AutoPlayService | null = null;

  aboutToDisappear() {
    // 清理定时器和服务
    this.autoPlayService?.stop();
    this.hintAnimationService?.stopHintTimer();

    // 清理全局事件处理器
    this.unregisterBackgroundEventHandler();

    console.log('Index aboutToDisappear: 已清理所有定时器');
  }

  async onPageShow() {
    console.log('Index onPageShow - 页面显示');
    console.log('Index onPageShow - quoteSourceChanged值:', this.quoteSourceChanged);

    // 检查是否需要重新加载（名言来源变化）
    if (this.quoteSourceChanged) {
      console.log('Index onPageShow - 检测到名言来源变化，重新加载...');

      // 清除标记
      this.quoteSourceChanged = false;
      AppStorage.setOrCreate('quoteSourceChanged', false);

      // 重新加载名言
      await this.reloadQuotesWithNewSource();
    }
  }

  /**
   * 监听名言源变化
   */
  onQuoteSourceChanged() {
    console.log('Index - 监听到quoteSourceChanged变化:', this.quoteSourceChanged);
    if (this.quoteSourceChanged) {
      console.log('Index - 准备重新加载名言...');
      // 延迟执行，确保页面已经显示
      setTimeout(() => {
        this.quoteSourceChanged = false;
        AppStorage.setOrCreate('quoteSourceChanged', false);
        this.reloadQuotesWithNewSource();
      }, 100);
    }
  }

  /**
   * 重新加载名言（当名言来源变化时）
   */
  async reloadQuotesWithNewSource() {
    console.log('开始重新加载名言...');

    // 停止自动播放
    if (this.isAutoPlaying) {
      this.completeStopping();
    }

    // 显示加载动画
    this.isLoading = true;

    try {
      // 清理现有的名言数据
      // 重要：不要创建新实例，而是清空现有数据源
      // 否则Swiper组件可能仍然绑定到旧实例
      this.quoteDataSource.clear();
      this.cardList = [];
      this.optimizedFontSizes = [];

      // 重要：清理QuotePageService中的已使用名言缓存
      // 否则新源的名言可能因为文本相同而被错误地排除
      if (this.quotePageService) {
        this.quotePageService.clearUsedQuoteTexts();
      }
      console.log('已清理现有名言数据和缓存');

      // 重新初始化应用（与aboutToAppear的逻辑相同）
      const context = getContext(this) as common.UIAbilityContext;
      console.log('重新加载前的名言来源:', QuoteData.getQuoteSource());
      const initResult = await this.appInitService?.initializeApp(context);
      console.log('重新加载后的名言来源:', QuoteData.getQuoteSource());

      if (initResult) {
        // 更新状态
        this.config = initResult.config;
        this.currentQuote = initResult.currentQuote;
        this.currentCard = initResult.currentCard;

        console.log('重新加载后的名言:', this.currentQuote?.text || 'null');

        // 重新初始化名言列表
        const quoteResult = await this.quotePageService?.initializeQuoteList({
          currentQuote: this.currentQuote,
          currentCard: this.currentCard,
          quoteDataSource: this.quoteDataSource,
          cardList: this.cardList,
          optimizedFontSizes: this.optimizedFontSizes
        });

        if (quoteResult) {
          this.currentQuote = quoteResult.quote;
          this.currentCard = quoteResult.card;
        }

        // 重置到第一页
        this.currentPageIndex = 0;

        // 更新预览
        await this.updatePreview();
        await this.updateBackgroundForCurrentPage(this.currentPageIndex);

        console.log('名言重新加载完成');
      }
    } catch (error) {
      console.error('重新加载名言失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async aboutToAppear() {

    // 初始化AppStorage标记
    AppStorage.setOrCreate('quoteSourceChanged', false);

    // 注册全局后台事件处理器
    this.registerBackgroundEventHandler();

    this.appInitService = new AppInitializationService();
    // CardUIService 使用静态方法，不需要实例化

    this.hintAnimationService = new HintAnimationService((opacity: number, duration: number) => {
      animateTo({
        duration: duration,
        curve: Curve.EaseInOut
      }, () => {
        this.hintOpacity = opacity;
      });
    });
    const context = getContext(this) as common.UIAbilityContext;
    const initResult = await this.appInitService.initializeApp(context);

    this.screenWidth = initResult.screenInfo.width;
    this.screenHeight = initResult.screenInfo.height;
    this.screenRatio = initResult.screenInfo.ratio;
    this.config = initResult.config;
    this.currentQuote = initResult.currentQuote;
    this.currentCard = initResult.currentCard;


    this.quotePageService = new QuotePageService(this.screenWidth, this.screenHeight);
    const quoteResult = await this.quotePageService.initializeQuoteList({
      currentQuote: this.currentQuote,
      currentCard: this.currentCard,
      quoteDataSource: this.quoteDataSource,
      cardList: this.cardList,
      optimizedFontSizes: this.optimizedFontSizes
    });

    this.currentQuote = quoteResult.quote;
    this.currentCard = quoteResult.card;

    await this.updatePreview();
    await this.updateBackgroundForCurrentPage(this.currentPageIndex);
    this.hintAnimationService?.startHintTimer();

    // 初始化自动播放服务
    this.initAutoPlayService();

    // 取消自动开始播放
    // setTimeout(() => {
    //   this.startAutoPlay();
    // }, 500);  // 延迟500ms确保界面完全加载
  }

  /**
   * 初始化自动播放服务
   */
  private initAutoPlayService() {
    this.autoPlayService = new AutoPlayService(
      this.displayDuration,
      this.textFadeDuration,
      this.bgFadeDuration,
      this.holdDuration,
      {
        onStateChange: (state: PlayState, speedUpFactor?: number) => {
          this.playState = state;
          this.currentSpeedUpFactor = speedUpFactor || 1;
          console.log('播放状态变化:', state, '速度倍数:', this.currentSpeedUpFactor);

          // 重置进度圆圈
          //if (state !== PlayState.IDLE && state !== PlayState.TEXT_FADE_OUT && state !== PlayState.BG_FADE_OUT) {
          if (state === PlayState.BG_FADE_IN) {
            this.idleProgressPercentage = 0;
          }

          // 独立处理线性进度条显示逻辑
          if (this.showLinearProgress) {
            this.updateLinearProgressForState(state);
          }

          // 状态变化时触发对应动画
          switch (state) {
            case PlayState.TEXT_FADE_OUT:
              this.executeTextFadeOutAnimation();
              // TEXT_FADE_OUT 开始时，进度条同步淡出（与文字淡出时长一致）
              if (this.showLinearProgress && this.linearProgressOpacity > 0) {
                const duration = this.textFadeDuration / this.currentSpeedUpFactor;
                animateTo({
                  duration: duration,  // 与文字淡出时长一致
                  curve: Curve.EaseOut
                }, () => {
                  this.linearProgressOpacity = 0;
                });
              }
              break;
            case PlayState.TEXT_OUT_HOLD:
              // 进度条已在TEXT_FADE_OUT时处理
              break;
            case PlayState.BG_FADE_OUT:
              this.executeBgFadeOutAnimation();
              break;
            case PlayState.BG_FADE_IN:
              this.executeBgFadeInAnimation();
              break;
            case PlayState.TEXT_FADE_IN:
              this.executeTextFadeInAnimation();
              // 文字淡入时准备真正的下一页背景
              this.prepareNextBackground();
              // TEXT_FADE_IN 开始时不再处理进度条，改为在IDLE时根据播放状态处理
              break;
          }
        },
        onAnimationUpdate: (params) => {
          // 状态机通知更新动画参数（用于IDLE状态重置）
          if (this.playState === PlayState.IDLE) {
            this.currentBackgroundOpacity = params.currentBackgroundOpacity;
            this.nextBackgroundOpacity = params.nextBackgroundOpacity;
            this.textOpacity = params.textOpacity;
            this.progressOpacity = 1;  // IDLE状态时进度圈圈可见
          }
        },
        onNextPage: async () => {
          // 切换到下一页
          await this.autoPlayNext();
        },
        onStopComplete: () => {
          // 停止完成，调用完成停止流程
          this.completeStopping();
        },
        getCurrentTextLength: () => {
          // 获取当前显示的名言文字长度
          const currentQuote = this.getCurrentQuote();
          if (currentQuote?.text) {
            // 只计算主文本长度，不包括作者和来源
            return currentQuote.text.length;
          }
          return 0;
        },
        onIdleProgress: (percentage: number, duration: number) => {
          // 更新IDLE进度
          this.idleProgressPercentage = percentage;
          this.idleDuration = duration;

          // 独立更新线性进度条
          if (this.showLinearProgress) {
            this.linearProgressWidth = percentage;
            // 进度条达到100%后保持显示，等待状态变化时再处理淡出
          }
        }
      }
    );
  }







  getCurrentQuote(): Quote | null {
    const totalCount = this.quoteDataSource.totalCount();
    if (totalCount > this.currentPageIndex) {
      return this.quoteDataSource.getData(this.currentPageIndex);
    }
    return this.currentQuote;
  }

  getCurrentCard(): Card | null {
    if (this.cardList.length > this.currentPageIndex) {
      return this.cardList[this.currentPageIndex];
    }
    return this.currentCard;
  }


  async updatePreview() {
    try {
      this.isTransitioning = true;

      const currentCard = this.getCurrentCard();
      console.log(`updatePreview - currentPageIndex: ${this.currentPageIndex}, card:`, currentCard?.quote?.text, currentCard?.style?.fontSize);
      const newBackground = CardUIService.getCardBackgroundColor(currentCard);

      if (this.isInitialLoad) {
        // 初次加载时，直接设置背景并渐入
        this.previewBackground = newBackground;
        animateTo({
          duration: UI_CONSTANTS.ANIMATION_DURATION_FADE,
          curve: Curve.EaseInOut
        }, () => {
          this.contentOpacity = 1;
        });
        this.isInitialLoad = false;
        setTimeout(() => {
          this.isTransitioning = false;
        }, UI_CONSTANTS.ANIMATION_DURATION_FADE);
      } else {
        // 非初次加载，执行淡出淡入动画
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
      }

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

  /**
   * 注册全局后台事件处理器
   */
  private registerBackgroundEventHandler(): void {
    // 创建全局事件处理器对象
    globalThis.backgroundEventHandler = {
      pauseAutoPlay: () => {
        console.log('Index: 收到后台暂停播放请求');
        if (this.isAutoPlaying && this.autoPlayService) {
          this.pauseAutoPlay();
        }
      },
      stopBreathing: () => {
        console.log('Index: 收到后台停止呼吸灯请求');
        this.hintAnimationService?.stopBreathing();
        // 立即设置透明度为0
        animateTo({
          duration: 300,
          curve: Curve.EaseOut
        }, () => {
          this.hintOpacity = 0;
        });
      },
      resumeBreathing: () => {
        console.log('Index: 收到前台恢复呼吸灯请求');
        // 只有在不播放的情况下才恢复呼吸灯
        if (!this.isAutoPlaying) {
          this.hintAnimationService?.startHintTimer();
        }
      },
      isAutoPlaying: () => {
        return this.isAutoPlaying;
      }
    };
  }

  /**
   * 清理全局后台事件处理器
   */
  private unregisterBackgroundEventHandler(): void {
    if (globalThis.backgroundEventHandler) {
      globalThis.backgroundEventHandler = null;
    }
  }

  /**
   * 根据播放状态更新线性进度条
   */
  private updateLinearProgressForState(state: PlayState): void {
    if (state === PlayState.IDLE) {
      if (this.isAutoPlaying) {
        // IDLE状态且正在自动播放
        // 如果进度条未显示，则渐入（与文字淡入时长一致）
        if (this.linearProgressOpacity <= 0) {
          this.linearProgressWidth = 0;
          const duration = this.textFadeDuration / this.currentSpeedUpFactor;
          animateTo({
            duration: duration,  // 与文字淡入时长一致
            curve: Curve.EaseIn
          }, () => {
            this.linearProgressOpacity = 0.3;
          });
        }
        // 进度条已显示，继续更新进度（通过onIdleProgress）
      } else {
        // IDLE状态但不在自动播放，进度条应渐出
        if (this.linearProgressOpacity > 0) {
          const duration = this.textFadeDuration / this.currentSpeedUpFactor;
          animateTo({
            duration: duration,  // 与文字淡出时长一致
            curve: Curve.EaseOut
          }, () => {
            this.linearProgressOpacity = 0;
          });
        }
      }
    } else if (state === PlayState.BG_FADE_IN) {
      // 进入背景淡入时，确保进度条完全透明
      this.linearProgressWidth = 0;
      this.linearProgressOpacity = 0;
    }
    // 移除了其他状态时立即隐藏的逻辑，改为在 TEXT_FADE_OUT 时处理
  }

  /**
   * 开始自动播放
   */
  async startAutoPlay() {
    if (this.quoteDataSource.totalCount() <= 1) {
      console.log('只有一页，无法自动播放');
      return;
    }

    console.log('开始自动播放');
    this.isAutoPlaying = true;
    this.showLoadingIcon = false;

    // 强制隐藏 Hint 提示
    this.hintAnimationService?.hideHint();

    // 初始化背景状态
    this.currentBackground = this.previewBackground;
    this.nextBackgroundOpacity = 0;  // 确保下一页背景初始是透明的
    console.log(`初始化当前背景: ${this.currentBackground}`);

    // 准备下一页背景
    await this.prepareNextBackground();

    // 启动状态机
    this.autoPlayService?.start();
  }

  /**
   * 暂停自动播放
   */
  pauseAutoPlay() {
    console.log('请求暂停自动播放');
    const currentState = this.autoPlayService?.requestStop();

    // 如果已经在IDLE状态，直接停止
    if (currentState === PlayState.IDLE) {
      console.log('已在IDLE状态，直接停止');
      this.completeStopping();
      return;
    }

    // 非IDLE状态，显示loading，等待动画自然完成到下一个IDLE
    console.log(`当前状态 ${currentState}，等待动画完成到IDLE`);
    this.isStopping = true;
    this.showLoadingIcon = true;

    // 动画会继续执行，直到到达IDLE状态
    // 在AutoPlayService的handleIdleState中会检测isStopping并调用onStopComplete
  }

  /**
   * 完成停止流程
   */
  private completeStopping() {
    this.playState = PlayState.IDLE;
    this.showLoadingIcon = false;
    this.isAutoPlaying = false;
    this.isStopping = false;
    this.currentSpeedUpFactor = 1;  // 重置速度因子
    this.idleProgressPercentage = 0;  // 重置进度
    this.autoPlayService?.stop();

    // 重置线性进度条
    if (this.showLinearProgress) {
      this.linearProgressWidth = 0;
      this.linearProgressOpacity = 0;
    }

    // 恢复 Hint 定时器
    this.hintAnimationService?.startHintTimer();

    console.log('自动播放已完全停止，isAutoPlaying:', this.isAutoPlaying, '，速度因子已重置');
  }

  /**
   * 执行文字淡出动画
   */
  private executeTextFadeOutAnimation() {
    if (!this.isAutoPlaying && !this.isStopping) return;

    const duration = this.textFadeDuration / this.currentSpeedUpFactor;
    console.log(`执行文字淡出动画，时长: ${duration}ms (${this.currentSpeedUpFactor}倍速)`);
    animateTo({
      duration: duration,
      curve: Curve.EaseOut
    }, () => {
      this.textOpacity = 0;
    });
  }

  /**
   * 执行背景淡出动画
   */
  private executeBgFadeOutAnimation() {
    if (!this.isAutoPlaying && !this.isStopping) return;

    const duration = this.bgFadeDuration / this.currentSpeedUpFactor;
    console.log(`执行背景淡出动画，时长: ${duration}ms (${this.currentSpeedUpFactor}倍速)`);
    console.log('当前背景:', this.currentBackground, '下一页背景:', this.nextBackground);
    // 淡出动画：下一页背景从 0 渐变到 0.5，进度圈圈同步淡出
    animateTo({
      duration: duration,
      curve: Curve.Linear
    }, () => {
      this.nextBackgroundOpacity = 0.5;  // 下一页背景渐显到50%
      this.progressOpacity = 0;  // 进度圈圈同步淡出
    });
  }

  /**
   * 执行背景淡入动画
   */
  private executeBgFadeInAnimation() {
    if (!this.isAutoPlaying && !this.isStopping) return;

    const duration = this.bgFadeDuration / this.currentSpeedUpFactor;
    console.log(`执行背景淡入动画，时长: ${duration}ms (${this.currentSpeedUpFactor}倍速)`);
    console.log('当前页:', this.currentBackground, '上一页:', this.nextBackground);
    // 淡入动画：上一页背景从 0.5 渐变到 0（逐渐消失），进度圈圈同步淡入
    // 当前页保持100%不变，视觉效果是从混合状态渐变到纯当前页
    animateTo({
      duration: duration,
      curve: Curve.Linear
    }, () => {
      this.nextBackgroundOpacity = 0;  // 上一页背景完全消失
      this.progressOpacity = 1;  // 进度圈圈同步淡入
    });
  }

  /**
   * 执行文字淡入动画
   */
  private executeTextFadeInAnimation() {
    if (!this.isAutoPlaying && !this.isStopping) return;

    const duration = this.textFadeDuration / this.currentSpeedUpFactor;
    console.log(`执行文字淡入动画，时长: ${duration}ms (${this.currentSpeedUpFactor}倍速)`);
    console.log('当前页索引:', this.currentPageIndex);
    animateTo({
      duration: duration,
      curve: Curve.EaseIn
    }, () => {
      this.textOpacity = 1;
    });
  }

  /**
   * 自动切换到下一页
   */
  private async autoPlayNext() {
    const totalCount = this.quoteDataSource.totalCount();
    if (totalCount <= 1) return;

    let nextIndex = this.currentPageIndex + 1;

    // 到达最后一页时循环到第一页
    if (nextIndex >= totalCount) {
      nextIndex = 0;
    }

    console.log(`自动切换: ${this.currentPageIndex} -> ${nextIndex}`);

    // 切换页面
    this.currentPageIndex = nextIndex;

    // 交换背景：下一页变成当前页，当前页变成上一页
    const tempBackground = this.currentBackground;
    this.currentBackground = this.nextBackground;
    this.nextBackground = tempBackground;  // 旧的当前页变成"下一页"（实际是上一页）

    // 此时 nextBackgroundOpacity 应该还是 0.5（从淡出阶段保留）
    console.log(`切换后当前背景: ${this.currentBackground}, 上一页背景: ${this.nextBackground}`);

    // 不需要在这里准备下一页，等到淡入完成后再准备
  }

  /**
   * 准备下一页的背景
   */
  private async prepareNextBackground() {
    const totalCount = this.quoteDataSource.totalCount();
    const nextIndex = (this.currentPageIndex + 1) % totalCount;

    console.log(`准备下一页背景，nextIndex: ${nextIndex}, totalCount: ${totalCount}`);

    const nextCard = this.cardList[nextIndex];
    if (nextCard) {
      // 使用 CardUIService 获取正确格式的背景
      this.nextBackground = CardUIService.getCardBackgroundColor(nextCard);
      console.log(`下一页背景准备完成: ${this.nextBackground}`);
    } else {
      this.nextBackground = UI_CONSTANTS.DEFAULT_BACKGROUND_COLOR;
      console.log(`下一页没有壁纸，使用默认背景: ${this.nextBackground}`);
    }
  }

  onScrollIndex(firstIndex: number) {
    this.currentPageIndex = firstIndex;
    this.loadMoreIfNeeded(firstIndex);
  }

  async loadMoreIfNeeded(currentIndex: number) {
    if (this.quotePageService) {
      await this.quotePageService.loadMoreIfNeeded({
        currentIndex: currentIndex,
        quoteDataSource: this.quoteDataSource,
        cardList: this.cardList,
        optimizedFontSizes: this.optimizedFontSizes
      });
    }
  }

  async updateBackgroundForCurrentPage(index: number) {
    try {
      const newBackground = CardUIService.getBackgroundColorForPage(index, this.cardList);
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


  async applyCardOptions() {
    if (!this.setLockScreen && !this.saveToGallery) {
      this.showSaveDialog = false;
      return;
    }

    this.isApplying = true;

    try {
      const context = getContext(this) as common.UIAbilityContext;
      const result = await CardUIService.exportCard({
        setAsLockScreen: this.setLockScreen,
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
      // 背景层
      this.buildBackgroundLayers()

      // 内容层（使用文字透明度控制）
      Column() {
        QuoteSwiperComponent({
          currentPageIndex: $currentPageIndex,
          cardList: $cardList,
          optimizedFontSizes: $optimizedFontSizes,
          contentOpacity: this.isAutoPlaying ? this.textOpacity : this.contentOpacity,
          formatQuoteText: this.formatQuoteText.bind(this),
          onScrollIndex: this.onScrollIndex.bind(this),
          updateBackgroundForCurrentPage: this.updateBackgroundForCurrentPage.bind(this),
          resetHintTimer: () => this.hintAnimationService?.resetHintTimer(),
          swipeEnabled: !this.isAutoPlaying  // 播放时禁用滑动
        })
      }
      .width('100%')
      .height('100%')

      TopBarComponent({
        isAutoPlaying: this.isAutoPlaying,
        showLoadingIcon: this.showLoadingIcon,
        idleProgressPercentage: this.idleProgressPercentage,
        progressOpacity: this.progressOpacity,
        onPlayClick: async (): Promise<void> => await this.startAutoPlay(),
        onPauseClick: (): void => this.pauseAutoPlay()
      })
      HintTextComponent({ hintOpacity: this.isAutoPlaying ? 0 : this.hintOpacity })

      // 线性进度条（与hint相同位置）
      LinearProgressComponent({
        progressWidth: this.linearProgressWidth,
        progressOpacity: this.linearProgressOpacity,
        isEnabled: this.showLinearProgress
      })

      // 透明覆盖层，专门处理长按手势
      if (!this.isAutoPlaying) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0)')  // 完全透明
          .hitTestBehavior(HitTestMode.Transparent)  // 透传点击事件，但接收长按
          .gesture(
            LongPressGesture({
              fingers: 1,
              repeat: false,
              duration: UI_CONSTANTS.LONG_PRESS_DURATION
            })
              .onAction(() => {
                console.log('长按手势触发（覆盖层），isAutoPlaying:', this.isAutoPlaying);
                this.hintAnimationService?.resetHintTimer();
                this.showSaveDialog = true;
              })
          )
      }

      LoadingOverlayComponent({ isLoading: this.isLoading })
      this.buildPureCard()
    }
    .width('100%')
    .height('100%')
    .id('previewArea')
    .bindContentCover(this.showSaveDialog, this.buildSaveDialog(), ModalTransition.NONE)
  }

  @Builder
  buildBackgroundLayers() {
    Stack() {
      // 底层背景（在切换过程中保持不变）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(
          this.isAutoPlaying
            ? (this.currentBackground || UI_CONSTANTS.FALLBACK_BACKGROUND_COLOR)
            : (this.previewBackground || UI_CONSTANTS.FALLBACK_BACKGROUND_COLOR)
        )
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 顶层背景（用于过渡效果）
      if (this.isAutoPlaying &&
          (this.playState === PlayState.BG_FADE_OUT ||
           this.playState === PlayState.BG_FADE_IN ||
           this.playState === PlayState.TEXT_IN_HOLD)) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.nextBackground || UI_CONSTANTS.FALLBACK_BACKGROUND_COLOR)
          .opacity(this.nextBackgroundOpacity)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
    }
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
              Checkbox({ name: 'setLockScreen', group: 'cardOptions' })
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
            Checkbox({ name: 'saveToGallery', group: 'cardOptions' })
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
            await this.applyCardOptions();
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
  buildPureCard() {
    // 为了支持截图，需要一个在屏幕内但不可见的元素
    // 使用visibility(Visibility.Hidden)会保留渲染但不显示
    Column() {
      if (this.getCurrentQuote()) {
        Text(this.formatQuoteText(this.getCurrentQuote()?.text || '').text)
          .fontSize(this.optimizedFontSizes[this.currentPageIndex] || (this.getCurrentCard()?.style.fontSize) || UI_CONSTANTS.DEFAULT_FONT_SIZE)
          .fontColor((this.getCurrentCard()?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: UI_CONSTANTS.TEXT_BOTTOM_MARGIN })
          .maxLines(UI_CONSTANTS.TEXT_LAYOUT.MAX_LINES)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.getCurrentQuote()?.author || ''}${(this.getCurrentQuote()?.author && this.getCurrentQuote()?.source) ? ' · ' : ''}${this.getCurrentQuote()?.source || ''}`)
          .fontSize(UI_CONSTANTS.AUTHOR_FONT_SIZE)
          .fontColor((this.getCurrentCard()?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
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
    .id('pureCardArea')
    .position({ x: 0, y: 0 })  // 保持在屏幕内以便截图
    .visibility(Visibility.Hidden)  // 使用visibility隐藏但保留渲染
    .hitTestBehavior(HitTestMode.None)  // 不接收触摸事件
  }
}