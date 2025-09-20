/**
 * 自动播放服务
 * 管理播放状态机和动画时序
 */

export enum PlayState {
  IDLE = 'idle',                          // 完整显示状态
  TEXT_FADE_OUT = 'text_fade_out',        // 文字淡出
  TEXT_OUT_HOLD = 'text_out_hold',        // 文字消失后保持
  BG_FADE_OUT = 'bg_fade_out',            // 背景淡出（100% -> 50%）
  BG_FADE_IN = 'bg_fade_in',              // 背景淡入（50% -> 100%）
  TEXT_IN_HOLD = 'text_in_hold',          // 文字出现前保持
  TEXT_FADE_IN = 'text_fade_in',          // 文字淡入
  STOPPING = 'stopping'                    // 正在停止（等待回到IDLE）
}

export interface AnimationParams {
  currentBackgroundOpacity: number;
  nextBackgroundOpacity: number;
  textOpacity: number;
}

export interface AutoPlayCallbacks {
  onStateChange?: (state: PlayState, speedUpFactor?: number) => void;
  onAnimationUpdate?: (params: AnimationParams) => void;
  onNextPage?: () => void;
  onStopComplete?: () => void;
  getCurrentTextLength?: () => number;  // 获取当前文字长度的回调
  onIdleProgress?: (percentage: number, duration: number) => void;  // IDLE进度回调
}

export class AutoPlayService {
  private stateTimer: number | null = null;
  private currentState: PlayState = PlayState.IDLE;
  private isRunning: boolean = false;
  private isStopping: boolean = false;
  private speedUpFactor: number = 1;  // 速度倍数，默认1倍速
  private isFirstIdle: boolean = true;  // 是否是首次进入IDLE（用于播放时）
  private idleProgressTimer: number | null = null;  // IDLE进度定时器
  private idleStartTime: number = 0;  // IDLE开始时间
  private currentIdleDuration: number = 0;  // 当前IDLE总时长
  private displayDuration: number;
  private textFadeDuration: number;
  private bgFadeDuration: number;
  private holdDuration: number;
  private callbacks: AutoPlayCallbacks;

  constructor(
    displayDuration: number = 3000,
    textFadeDuration: number = 500,
    bgFadeDuration: number = 500,
    holdDuration: number = 200,
    callbacks: AutoPlayCallbacks = {}
  ) {
    this.displayDuration = displayDuration;
    this.textFadeDuration = textFadeDuration;
    this.bgFadeDuration = bgFadeDuration;
    this.holdDuration = holdDuration;
    this.callbacks = callbacks;
  }

  /**
   * 开始自动播放
   */
  start() {
    console.log('AutoPlayService: 开始自动播放');
    this.isRunning = true;
    this.isStopping = false;
    this.isFirstIdle = true;  // 标记这是播放开始的IDLE
    this.transitionToState(PlayState.IDLE);
  }

  /**
   * 请求停止播放
   * @returns 当前状态，用于决定如何停止
   */
  requestStop(): PlayState {
    console.log('AutoPlayService: 请求停止，当前状态:', this.currentState);
    this.isStopping = true;
    this.isRunning = false;

    // 不清除定时器，让动画继续执行到IDLE状态
    // 如果当前不是IDLE状态，设置加速因子
    if (this.currentState !== PlayState.IDLE) {
      this.speedUpFactor = 10;  // 10倍速
      console.log('AutoPlayService: 设置10倍速运行到IDLE');
    }

    return this.currentState;
  }

  /**
   * 立即停止
   */
  stop() {
    console.log('AutoPlayService: 立即停止');
    this.isRunning = false;
    this.isStopping = false;

    if (this.stateTimer) {
      clearTimeout(this.stateTimer);
      this.stateTimer = null;
    }

    this.stopIdleProgress();  // 停止进度追踪

    this.currentState = PlayState.IDLE;
  }

  /**
   * 状态转换
   */
  private transitionToState(state: PlayState) {
    if (!this.isRunning && !this.isStopping) {
      return;
    }

    console.log('AutoPlayService: 转换到状态:', state, '速度因子:', this.speedUpFactor);
    this.currentState = state;
    this.callbacks.onStateChange?.(state, this.speedUpFactor);

    switch (state) {
      case PlayState.IDLE:
        this.handleIdleState();
        break;
      case PlayState.TEXT_FADE_OUT:
        this.handleTextFadeOutState();
        break;
      case PlayState.TEXT_OUT_HOLD:
        this.handleTextOutHoldState();
        break;
      case PlayState.BG_FADE_OUT:
        this.handleBgFadeOutState();
        break;
      case PlayState.BG_FADE_IN:
        this.handleBgFadeInState();
        break;
      case PlayState.TEXT_IN_HOLD:
        this.handleTextInHoldState();
        break;
      case PlayState.TEXT_FADE_IN:
        this.handleTextFadeInState();
        break;
    }
  }

  /**
   * 处理完整显示状态
   */
  private handleIdleState() {
    // 如果正在停止，完成停止流程
    if (this.isStopping) {
      console.log('AutoPlayService: 到达IDLE状态，完成停止');
      this.isStopping = false;
      this.speedUpFactor = 1;  // 重置速度因子
      this.isFirstIdle = false;  // 重置首次标志
      this.callbacks.onStopComplete?.();
      return;
    }

    // 完整显示状态：背景100%，文字100%
    this.callbacks.onAnimationUpdate?.({
      currentBackgroundOpacity: 1,
      nextBackgroundOpacity: 0,
      textOpacity: 1
    });

    // 计算等待时间
    let waitDuration: number;

    if (this.isFirstIdle) {
      // 首次进入IDLE（点击播放时），等待时间强制为1秒
      waitDuration = 1000;
      this.isFirstIdle = false;  // 只在第一次使用
      console.log(`AutoPlayService: 首次IDLE，等待 ${waitDuration}ms 后开始淡出`);
    } else {
      // 根据文字长度动态调整显示时间
      // 10字以下：5秒
      // 10字以上：每增加1字增加0.2秒
      // 最多30秒
      const textLength = this.callbacks.getCurrentTextLength?.() || 0;

      let dynamicDuration: number;
      if (textLength <= 10) {
        dynamicDuration = 5000;  // 5秒
      } else {
        // 5秒 + (字数-10) * 0.2秒
        dynamicDuration = 5000 + (textLength - 10) * 200;
        // 最多30秒
        dynamicDuration = Math.min(dynamicDuration, 30000);
      }

      // 应用速度因子
      waitDuration = dynamicDuration / this.speedUpFactor;
      this.currentIdleDuration = waitDuration;  // 保存当前IDLE时长
      console.log(`AutoPlayService: 文字长度 ${textLength}，动态时间 ${dynamicDuration}ms，实际等待 ${waitDuration}ms (${this.speedUpFactor}倍速)`);
    }

    // 启动IDLE进度追踪（即使是首次也要追踪）
    this.startIdleProgress(waitDuration);

    // 等待后进入文字淡出
    if (this.isRunning) {
      this.stateTimer = setTimeout(() => {
        this.stopIdleProgress();
        if (this.isRunning && !this.isStopping) {
          this.transitionToState(PlayState.TEXT_FADE_OUT);
        }
      }, waitDuration);
    }
  }

  /**
   * 开始IDLE进度追踪
   */
  private startIdleProgress(duration: number) {
    this.idleStartTime = Date.now();
    this.currentIdleDuration = duration;

    // 清除旧的进度定时器
    if (this.idleProgressTimer) {
      clearInterval(this.idleProgressTimer);
    }

    // 立即发送0%进度
    this.callbacks.onIdleProgress?.(0, duration);

    // 每100ms更新一次进度
    this.idleProgressTimer = setInterval(() => {
      const elapsed = Date.now() - this.idleStartTime;
      const percentage = Math.min(elapsed / duration * 100, 100);
      this.callbacks.onIdleProgress?.(percentage, duration);

      // 如果达到100%，停止更新
      if (percentage >= 100) {
        this.stopIdleProgress();
      }
    }, 100);
  }

  /**
   * 停止IDLE进度追踪
   */
  private stopIdleProgress() {
    if (this.idleProgressTimer) {
      clearInterval(this.idleProgressTimer);
      this.idleProgressTimer = null;
    }
  }

  /**
   * 处理文字淡出状态
   */
  private handleTextFadeOutState() {
    // 文字淡出动画会在Index.ets中通过animateTo实现
    const duration = this.textFadeDuration / this.speedUpFactor;
    this.stateTimer = setTimeout(() => {
      // 如果正在停止，仍然需要继续状态转换
      if (this.isRunning || this.isStopping) {
        this.transitionToState(PlayState.TEXT_OUT_HOLD);
      }
    }, duration);
  }

  /**
   * 处理文字消失后保持状态
   */
  private handleTextOutHoldState() {
    // 保持一小段时间
    const duration = this.holdDuration / this.speedUpFactor;
    this.stateTimer = setTimeout(() => {
      // 如果正在停止，仍然需要继续状态转换
      if (this.isRunning || this.isStopping) {
        this.transitionToState(PlayState.BG_FADE_OUT);
      }
    }, duration);
  }

  /**
   * 处理背景淡出状态
   */
  private handleBgFadeOutState() {
    // 背景淡出动画会在Index.ets中通过animateTo实现
    const duration = this.bgFadeDuration / this.speedUpFactor;
    this.stateTimer = setTimeout(() => {
      // 如果正在停止，仍然需要完成页面切换和状态转换
      if (this.isRunning || this.isStopping) {
        // 通知切换到下一页
        this.callbacks.onNextPage?.();
        this.transitionToState(PlayState.BG_FADE_IN);
      }
    }, duration);
  }

  /**
   * 处理背景淡入状态
   */
  private handleBgFadeInState() {
    // 背景淡入动画会在Index.ets中通过animateTo实现
    const duration = this.bgFadeDuration / this.speedUpFactor;
    this.stateTimer = setTimeout(() => {
      // 如果正在停止，仍然需要继续状态转换
      if (this.isRunning || this.isStopping) {
        this.transitionToState(PlayState.TEXT_IN_HOLD);
      }
    }, duration);
  }

  /**
   * 处理文字出现前保持状态
   */
  private handleTextInHoldState() {
    // 保持一小段时间
    const duration = this.holdDuration / this.speedUpFactor;
    this.stateTimer = setTimeout(() => {
      // 如果正在停止，仍然需要继续状态转换
      if (this.isRunning || this.isStopping) {
        this.transitionToState(PlayState.TEXT_FADE_IN);
      }
    }, duration);
  }

  /**
   * 处理文字淡入状态
   */
  private handleTextFadeInState() {
    // 文字淡入动画会在Index.ets中通过animateTo实现
    const duration = this.textFadeDuration / this.speedUpFactor;
    this.stateTimer = setTimeout(() => {
      // 无论是否正在停止，都需要转换到IDLE状态
      this.transitionToState(PlayState.IDLE);
    }, duration);
  }

  /**
   * 更新时间配置
   */
  updateDurations(displayDuration?: number, textFadeDuration?: number, bgFadeDuration?: number, holdDuration?: number) {
    if (displayDuration !== undefined) {
      this.displayDuration = displayDuration;
    }
    if (textFadeDuration !== undefined) {
      this.textFadeDuration = textFadeDuration;
    }
    if (bgFadeDuration !== undefined) {
      this.bgFadeDuration = bgFadeDuration;
    }
    if (holdDuration !== undefined) {
      this.holdDuration = holdDuration;
    }
  }

  /**
   * 获取当前状态
   */
  getCurrentState(): PlayState {
    return this.currentState;
  }

  /**
   * 是否正在播放
   */
  isPlaying(): boolean {
    return this.isRunning;
  }
}