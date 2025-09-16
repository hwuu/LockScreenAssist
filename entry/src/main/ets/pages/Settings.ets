import { ScheduleConfig, WallpaperConfig, SelectionAlgorithm } from '../common/ScheduleConfig';
import { router } from '@kit.ArkUI';

// 定义选项接口
interface OptionItem {
  label: string;
  value: SelectionAlgorithm;
}

@Entry
@Component
struct Settings {
  @State config: WallpaperConfig = {
    selectionAlgorithm: SelectionAlgorithm.SMART,
    autoOptimizeFont: true,
    autoOptimizeBackground: true,
    enableSeasonalAdjustment: true,
    enableWeatherAdjustment: false
  };

  async aboutToAppear() {
    await this.loadConfig();
  }

  async loadConfig() {
    try {
      const savedConfig = await ScheduleConfig.getConfig();
      if (savedConfig) {
        this.config = savedConfig;
      }
    } catch (error) {
      console.error('Failed to load config:', error);
    }
  }

  async saveConfig() {
    try {
      await ScheduleConfig.saveConfig(this.config);
      console.log('Config saved successfully');
    } catch (error) {
      console.error('Failed to save config:', error);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('←')
            .fontSize(20)
            .fontColor('#666')
        }
        .width(40)
        .height(40)
        .backgroundColor('#f5f5f5')
        .borderRadius(20)
        .onClick(() => {
          router.back();
        })

        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .margin({ left: 16 })

        Blank()
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#ffffff')

      // 设置内容
      Scroll() {
        Column() {
          // 名言选择算法
          this.buildSettingSection(
            '名言选择',
            '选择名言的算法和偏好设置',
            () => {
              this.buildRadioGroup(
                '选择算法',
                [
                  { label: '智能推荐', value: SelectionAlgorithm.SMART } as OptionItem,
                  { label: '随机选择', value: SelectionAlgorithm.RANDOM } as OptionItem,
                  { label: '顺序选择', value: SelectionAlgorithm.SEQUENTIAL } as OptionItem
                ] as OptionItem[],
                this.config.selectionAlgorithm,
                (value: SelectionAlgorithm) => {
                  this.config.selectionAlgorithm = value;
                  this.saveConfig();
                }
              )
            }
          )

          // 显示优化
          this.buildSettingSection(
            '显示优化',
            '自动优化字体和背景颜色',
            () => {
              this.buildToggleItem(
                '自动字体优化',
                '根据文本长度自动调整字体大小',
                this.config.autoOptimizeFont,
                (value: boolean) => {
                  this.config.autoOptimizeFont = value;
                  this.saveConfig();
                }
              )

              this.buildToggleItem(
                '自动背景优化',
                '根据内容智能选择背景颜色',
                this.config.autoOptimizeBackground,
                (value: boolean) => {
                  this.config.autoOptimizeBackground = value;
                  this.saveConfig();
                }
              )
            }
          )

          // 环境适应
          this.buildSettingSection(
            '环境适应',
            '根据季节和天气调整显示效果',
            () => {
              this.buildToggleItem(
                '季节调整',
                '根据当前季节调整配色方案',
                this.config.enableSeasonalAdjustment,
                (value: boolean) => {
                  this.config.enableSeasonalAdjustment = value;
                  this.saveConfig();
                }
              )

              this.buildToggleItem(
                '天气调整',
                '根据天气情况调整显示效果',
                this.config.enableWeatherAdjustment,
                (value: boolean) => {
                  this.config.enableWeatherAdjustment = value;
                  this.saveConfig();
                }
              )
            }
          )
        }
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .backgroundColor('#f8f9fa')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8f9fa')
  }

  @Builder
  buildSettingSection(title: string, description: string, content: () => void) {
    Column() {
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .alignSelf(ItemAlign.Start)

        Text(description)
          .fontSize(14)
          .fontColor('#7f8c8d')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 4, bottom: 16 })

        //content()
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#ffffff')
      .borderRadius(12)
      .margin({ bottom: 16 })
    }
  }

  @Builder
  buildToggleItem(title: string, description: string, value: boolean, onChange: (value: boolean) => void) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor('#2c3e50')
          .alignSelf(ItemAlign.Start)

        Text(description)
          .fontSize(12)
          .fontColor('#7f8c8d')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange(onChange)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  buildRadioGroup(title: string, options: OptionItem[], currentValue: SelectionAlgorithm, onChange: (value: SelectionAlgorithm) => void) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor('#2c3e50')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      ForEach(options, (option: OptionItem) => {
        Row() {
          Radio({ value: option.value.toString(), group: 'algorithm' })
            .checked(currentValue === option.value)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                onChange(option.value);
              }
            })

          Text(option.label)
            .fontSize(14)
            .fontColor('#2c3e50')
            .margin({ left: 8 })
        }
        .width('100%')
        .margin({ bottom: 8 })
        .onClick(() => {
          onChange(option.value);
        })
      })
    }
    .alignItems(HorizontalAlign.Start)
  }
}