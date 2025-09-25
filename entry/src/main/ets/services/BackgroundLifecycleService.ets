// 后台生命周期管理服务
export interface BackgroundLifecycleCallbacks {
  onPauseAutoPlay?: () => void;           // 暂停播放回调
  onStopBreathing?: () => void;           // 停止呼吸灯回调
  onResumeBreathing?: () => void;         // 恢复呼吸灯回调
  isAutoPlaying?: () => boolean;           // 检查是否正在播放
}

export class BackgroundLifecycleService {
  private backgroundTimer: number | null = null;
  private isInBackground: boolean = false;
  private wasPlayingBeforeBackground: boolean = false;
  private callbacks: BackgroundLifecycleCallbacks;

  // 后台等待时间（10秒）
  private static readonly BACKGROUND_WAIT_TIME = 10000;

  constructor(callbacks: BackgroundLifecycleCallbacks = {}) {
    this.callbacks = callbacks;
  }

  /**
   * 应用进入后台
   */
  onBackground(): void {
    console.log('BackgroundLifecycleService: 应用进入后台');
    this.isInBackground = true;

    // 清除之前的定时器（如果有）
    this.clearBackgroundTimer();

    // 记录当前播放状态
    this.wasPlayingBeforeBackground = this.callbacks.isAutoPlaying?.() || false;
    console.log('BackgroundLifecycleService: 进入后台时播放状态:', this.wasPlayingBeforeBackground);

    // 立即停止呼吸灯
    console.log('BackgroundLifecycleService: 立即停止呼吸灯');
    this.callbacks.onStopBreathing?.();

    // 设置10秒定时器，如果还在后台则暂停播放
    this.backgroundTimer = setTimeout(() => {
      if (this.isInBackground) {
        console.log('BackgroundLifecycleService: 已在后台10秒');

        // 如果正在播放，暂停播放
        if (this.callbacks.isAutoPlaying?.()) {
          console.log('BackgroundLifecycleService: 暂停自动播放');
          this.callbacks.onPauseAutoPlay?.();
        }
      }
    }, BackgroundLifecycleService.BACKGROUND_WAIT_TIME);
  }

  /**
   * 应用返回前台
   */
  onForeground(): void {
    console.log('BackgroundLifecycleService: 应用返回前台');
    this.isInBackground = false;

    // 清除后台定时器
    this.clearBackgroundTimer();

    // 检查当前是否在播放
    const isCurrentlyPlaying = this.callbacks.isAutoPlaying?.() || false;
    console.log('BackgroundLifecycleService: 返回前台时播放状态:', isCurrentlyPlaying);

    // 如果当前不在播放状态，恢复呼吸灯
    if (!isCurrentlyPlaying) {
      console.log('BackgroundLifecycleService: 恢复呼吸灯');
      this.callbacks.onResumeBreathing?.();
    } else {
      console.log('BackgroundLifecycleService: 正在播放中，不恢复呼吸灯');
    }
  }

  /**
   * 清除后台定时器
   */
  private clearBackgroundTimer(): void {
    if (this.backgroundTimer !== null) {
      clearTimeout(this.backgroundTimer);
      this.backgroundTimer = null;
    }
  }

  /**
   * 销毁服务
   */
  destroy(): void {
    this.clearBackgroundTimer();
    this.isInBackground = false;
    this.wasPlayingBeforeBackground = false;
  }

  /**
   * 获取后台状态
   */
  isAppInBackground(): boolean {
    return this.isInBackground;
  }
}