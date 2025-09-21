// 全局类型定义
import common from '@ohos.app.ability.common';

// 后台事件处理器接口
interface BackgroundEventHandler {
  pauseAutoPlay?: () => void;
  stopBreathing?: () => void;
  resumeBreathing?: () => void;
  isAutoPlaying?: () => boolean;
}

declare global {
  var abilityContext: common.UIAbilityContext | undefined;
  var localStorage: Storage | undefined;
  var backgroundEventHandler: BackgroundEventHandler | null | undefined;
}

export {};