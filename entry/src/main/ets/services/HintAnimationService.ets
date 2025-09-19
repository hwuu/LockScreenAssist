// 呼吸动画时间配置接口
export interface BreathingConfig {
  initialPause?: number;     // 初始静止时间（毫秒）
  inhaleTime?: number;       // 吸气时间（毫秒）
  topPause?: number;         // 顶部停顿时间（毫秒）
  exhaleTime?: number;       // 呼气时间（毫秒）
  bottomPause?: number;      // 底部停顿时间（毫秒）
  recoveryTime?: number;     // 恢复时间（毫秒）
}

// 提示文字动画服务
export class HintAnimationService {
  private hintTimer: number = -1; // 提示文字定时器
  private debounceTimer: number = -1; // 防抖定时器
  private breathingTimer: number = -1; // 呼吸动画定时器
  private isBreathing: boolean = false; // 是否正在呼吸动画

  // 呼吸动画时间配置
  private breathingConfig: Required<BreathingConfig> = {
    initialPause: 1000,   // 初始静止1秒
    inhaleTime: 2500,     // 吸气2.5秒
    topPause: 500,        // 顶部停顿0.5秒
    exhaleTime: 3000,     // 呼气3秒
    bottomPause: 500,     // 底部停顿0.5秒
    recoveryTime: 1000    // 恢复1秒
  };

  // 回调函数类型定义
  private changeOpacity?: (opacity: number, duration: number) => void;

  constructor(
    changeOpacity?: (opacity: number, duration: number) => void,
    breathingConfig?: BreathingConfig
  ) {
    this.changeOpacity = changeOpacity;
    if (breathingConfig) {
      // 手动合并配置，避免使用展开运算符
      if (breathingConfig.initialPause !== undefined) {
        this.breathingConfig.initialPause = breathingConfig.initialPause;
      }
      if (breathingConfig.inhaleTime !== undefined) {
        this.breathingConfig.inhaleTime = breathingConfig.inhaleTime;
      }
      if (breathingConfig.topPause !== undefined) {
        this.breathingConfig.topPause = breathingConfig.topPause;
      }
      if (breathingConfig.exhaleTime !== undefined) {
        this.breathingConfig.exhaleTime = breathingConfig.exhaleTime;
      }
      if (breathingConfig.bottomPause !== undefined) {
        this.breathingConfig.bottomPause = breathingConfig.bottomPause;
      }
      if (breathingConfig.recoveryTime !== undefined) {
        this.breathingConfig.recoveryTime = breathingConfig.recoveryTime;
      }
    }
  }

  // 启动提示文字定时器
  startHintTimer(): void {
    this.clearHintTimer();
    this.hintTimer = setTimeout(() => {
      this.showHint();
    }, 5000);
  }

  // 清除提示文字定时器
  clearHintTimer(): void {
    if (this.hintTimer !== -1) {
      clearTimeout(this.hintTimer);
      this.hintTimer = -1;
    }
  }

  // 清除呼吸定时器
  clearBreathingTimer(): void {
    if (this.breathingTimer !== -1) {
      clearTimeout(this.breathingTimer);
      this.breathingTimer = -1;
    }
  }

  // 显示提示文字（触发动画的业务逻辑，实际动画由UI层处理）
  showHint(): void {
    /*
    // 通知UI层开始渐入动画，从0渐入到0.8
    if (this.changeOpacity) {
      this.changeOpacity(0.8, 2000);
    }

    // 渐入动画完成后开始呼吸效果
    setTimeout(() => {
      this.startBreathing();
    }, 2000);
    */
    this.startBreathing();
  }

  // 开始呼吸效果
  startBreathing(): void {
    // 移除透明度检查，因为呼吸循环会改变透明度
    this.isBreathing = true;
    this.breathingCycle();
  }

  // 呼吸循环（模仿人类平静呼吸）
  breathingCycle(): void {
    if (!this.isBreathing) {
      // 如果不在呼吸状态，停止呼吸
      return;
    }

    // 第一阶段：静止等待（呼吸间隙，当前为0.0）
    this.breathingTimer = setTimeout(() => {
      if (!this.isBreathing) return;

      // 第二阶段：缓慢"吸气"，从0.0到0.8
      if (this.changeOpacity) {
        this.changeOpacity(0.8, this.breathingConfig.inhaleTime);
      }

      // 吸气动画完成后，开始顶部停顿
      setTimeout(() => {
        if (!this.isBreathing) return;

        // 第三阶段：顶部停顿
        setTimeout(() => {
          if (!this.isBreathing) return;

          // 第四阶段：缓慢"呼气"，从0.8降到0.0
          if (this.changeOpacity) {
            this.changeOpacity(0.0, this.breathingConfig.exhaleTime);
          }

          // 呼气完成后，开始底部停顿
          setTimeout(() => {
            if (!this.isBreathing) return;

            // 第五阶段：底部停顿
            setTimeout(() => {
              if (!this.isBreathing) return;

              // 保持0.0，准备下一轮
              if (this.changeOpacity) {
                this.changeOpacity(0.0, this.breathingConfig.recoveryTime);
              }

              // 完成一轮呼吸后继续下一轮
              setTimeout(() => {
                if (this.isBreathing) {
                  this.breathingCycle();
                }
              }, this.breathingConfig.recoveryTime);
            }, this.breathingConfig.bottomPause);
          }, this.breathingConfig.exhaleTime);
        }, this.breathingConfig.topPause);
      }, this.breathingConfig.inhaleTime);
    }, this.breathingConfig.initialPause);
  }

  // 停止呼吸效果
  stopBreathing(): void {
    this.isBreathing = false;
    this.clearBreathingTimer();
  }

  // 隐藏提示文字
  hideHint(): void {
    // 停止呼吸效果
    this.stopBreathing();

    // 添加短暂延迟，确保呼吸动画完全停止
    setTimeout(() => {
      if (this.changeOpacity) {
        this.changeOpacity(0, 300);
      }
    }, 50); // 50ms延迟确保状态同步
  }

  // 重置提示文字定时器（带防抖）
  resetHintTimer(): void {
    // 停止呼吸效果
    this.stopBreathing();

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
    this.clearBreathingTimer();
    this.stopBreathing();
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = -1;
    }
  }

  // 检查是否在呼吸状态
  isBreathingActive(): boolean {
    return this.isBreathing;
  }

  // 更新呼吸配置
  updateBreathingConfig(config: BreathingConfig): void {
    // 手动合并配置，避免使用展开运算符
    if (config.initialPause !== undefined) {
      this.breathingConfig.initialPause = config.initialPause;
    }
    if (config.inhaleTime !== undefined) {
      this.breathingConfig.inhaleTime = config.inhaleTime;
    }
    if (config.topPause !== undefined) {
      this.breathingConfig.topPause = config.topPause;
    }
    if (config.exhaleTime !== undefined) {
      this.breathingConfig.exhaleTime = config.exhaleTime;
    }
    if (config.bottomPause !== undefined) {
      this.breathingConfig.bottomPause = config.bottomPause;
    }
    if (config.recoveryTime !== undefined) {
      this.breathingConfig.recoveryTime = config.recoveryTime;
    }
  }

  // 获取当前呼吸配置
  getBreathingConfig(): Required<BreathingConfig> {
    // 返回配置的副本，避免使用展开运算符
    return {
      initialPause: this.breathingConfig.initialPause,
      inhaleTime: this.breathingConfig.inhaleTime,
      topPause: this.breathingConfig.topPause,
      exhaleTime: this.breathingConfig.exhaleTime,
      bottomPause: this.breathingConfig.bottomPause,
      recoveryTime: this.breathingConfig.recoveryTime
    };
  }
}