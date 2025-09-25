import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BackgroundLifecycleService } from '../services/BackgroundLifecycleService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private backgroundLifecycleService: BackgroundLifecycleService | null = null;
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    // 设置全局context供其他模块使用
    globalThis.abilityContext = this.context;

    // 初始化后台生命周期管理服务
    this.initBackgroundLifecycleService();

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    // 销毁后台生命周期管理服务
    this.backgroundLifecycleService?.destroy();
    this.backgroundLifecycleService = null;

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');

    // 通知后台生命周期管理服务
    this.backgroundLifecycleService?.onForeground();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');

    // 通知后台生命周期管理服务
    this.backgroundLifecycleService?.onBackground();
  }

  /**
   * 初始化后台生命周期管理服务
   */
  private initBackgroundLifecycleService(): void {
    this.backgroundLifecycleService = new BackgroundLifecycleService({
      onPauseAutoPlay: (): void => {
        // 通过全局事件或全局对象通知Index页面暂停播放
        globalThis.backgroundEventHandler?.pauseAutoPlay?.();
      },
      onStopBreathing: (): void => {
        // 通过全局事件或全局对象通知Index页面停止呼吸灯
        globalThis.backgroundEventHandler?.stopBreathing?.();
      },
      onResumeBreathing: (): void => {
        // 通过全局事件或全局对象通知Index页面恢复呼吸灯
        globalThis.backgroundEventHandler?.resumeBreathing?.();
      },
      isAutoPlaying: (): boolean => {
        // 通过全局事件或全局对象获取播放状态
        return globalThis.backgroundEventHandler?.isAutoPlaying?.() || false;
      }
    });
  }
}