// UI动画服务
export class UIAnimationService {
  private hintTimer: number = -1; // 提示文字定时器
  private debounceTimer: number = -1; // 防抖定时器
  private blinkTimer: number = -1; // 闪烁动画定时器
  private isBlinking: boolean = false; // 是否正在闪烁

  // 回调函数类型定义
  private onHintOpacityChange?: (opacity: number) => void;

  constructor(onHintOpacityChange?: (opacity: number) => void) {
    this.onHintOpacityChange = onHintOpacityChange;
  }

  // 启动提示文字定时器
  startHintTimer(): void {
    this.clearHintTimer();
    this.hintTimer = setTimeout(() => {
      this.showHint();
    }, 4000);
  }

  // 清除提示文字定时器
  clearHintTimer(): void {
    if (this.hintTimer !== -1) {
      clearTimeout(this.hintTimer);
      this.hintTimer = -1;
    }
  }

  // 清除闪烁定时器
  clearBlinkTimer(): void {
    if (this.blinkTimer !== -1) {
      clearTimeout(this.blinkTimer);
      this.blinkTimer = -1;
    }
  }

  // 显示提示文字（触发动画的业务逻辑，实际动画由UI层处理）
  showHint(): void {
    // 通知UI层开始渐入动画
    if (this.onHintOpacityChange) {
      this.onHintOpacityChange(0.8);
    }

    // 渐入动画完成后开始闪烁效果
    setTimeout(() => {
      this.startBlinkEffect();
    }, 2000);
  }

  // 开始闪烁效果
  startBlinkEffect(): void {
    // 移除透明度检查，因为呼吸循环会改变透明度
    this.isBlinking = true;
    this.blinkCycle();
  }

  // 呼吸循环（模仿人类平静呼吸）
  blinkCycle(): void {
    if (!this.isBlinking) {
      // 如果不在闪烁状态，停止呼吸
      return;
    }

    // 第一阶段：静止等待2秒（呼吸间隙）
    this.blinkTimer = setTimeout(() => {
      if (!this.isBlinking) return;

      // 第二阶段：缓慢"呼气"3秒
      if (this.onHintOpacityChange) {
        this.onHintOpacityChange(0.1);
      }

      // 呼气动画完成后，开始底部停顿
      setTimeout(() => {
        if (!this.isBlinking) return;

        // 第三阶段：底部停顿5秒
        setTimeout(() => {
          if (!this.isBlinking) return;

          // 第四阶段：缓慢"吸气"2.5秒，从0.1恢复到0.8
          if (this.onHintOpacityChange) {
            this.onHintOpacityChange(0.8);
          }

          // 完成一轮呼吸后继续下一轮
          setTimeout(() => {
            if (this.isBlinking) {
              this.blinkCycle();
            }
          }, 2500);
        }, 500); // 底部停顿0.5秒
      }, 3000); // 呼气3秒
    }, 2000); // 初始静止2秒
  }

  // 停止闪烁效果
  stopBlinkEffect(): void {
    this.isBlinking = false;
    this.clearBlinkTimer();
  }

  // 隐藏提示文字
  hideHint(): void {
    // 停止闪烁效果
    this.stopBlinkEffect();

    // 添加短暂延迟，确保呼吸动画完全停止
    setTimeout(() => {
      if (this.onHintOpacityChange) {
        this.onHintOpacityChange(0);
      }
    }, 50); // 50ms延迟确保状态同步
  }

  // 重置提示文字定时器（带防抖）
  resetHintTimer(): void {
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
      // 隐藏提示
      this.hideHint();
      // 重新启动定时器
      this.startHintTimer();
      this.debounceTimer = -1;
    }, 200);
  }

  // 清理所有定时器（组件销毁时调用）
  cleanup(): void {
    this.clearHintTimer();
    this.clearBlinkTimer();
    this.stopBlinkEffect();
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
  }

  // 检查是否在闪烁状态
  isBlinkingActive(): boolean {
    return this.isBlinking;
  }
}