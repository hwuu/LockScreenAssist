import { ScheduleConfig, CardConfig, SelectionAlgorithm } from '../common/ScheduleConfig';
import { QuoteData, QuoteSource } from '../common/QuoteData';
import { router, promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';

// 设置项类型枚举
enum SettingType {
  TOGGLE,
  RADIO,
  NAVIGATION
}

// 选项接口
interface OptionItem {
  label: string;
  value: string;
}

// 设置项接口
interface SettingItem {
  id: string;
  title: string;
  description?: string;
  type: SettingType;
  value?: boolean | string;
  options?: OptionItem[];
  onClick?: () => void;
  onChangeBoolean?: (value: boolean) => void;
  onChangeString?: (value: string) => void;
}

// 设置组接口
interface SettingGroup {
  title: string;
  items: SettingItem[];
}

// ActionSheet选项接口
interface SheetOption {
  title: string;
  action: () => void;
}

@Entry
@Component
struct Settings {
  @State config: CardConfig = {
    selectionAlgorithm: SelectionAlgorithm.SMART,
    autoOptimizeFont: true,
    autoOptimizeBackground: true,
    enableSeasonalAdjustment: false,
    enableWeatherAdjustment: false
  };

  @State currentQuoteSource: QuoteSource = QuoteSource.MAOZEDONG;
  @State settingGroups: SettingGroup[] = [];
  @State showDialog: boolean = false;
  @State currentDialogItem: SettingItem | null = null;
  @State hasChanges: boolean = false;

  // 保存原始配置用于比较
  private originalConfig: CardConfig = {
    selectionAlgorithm: SelectionAlgorithm.SMART,
    autoOptimizeFont: true,
    autoOptimizeBackground: true,
    enableSeasonalAdjustment: true,
    enableWeatherAdjustment: false
  };
  private originalQuoteSource: QuoteSource = QuoteSource.MAOZEDONG;

  async aboutToAppear() {
    await this.loadConfig();
    await this.loadQuoteSource();
    this.initSettingGroups();
  }

  async loadConfig() {
    try {
      const savedConfig = await ScheduleConfig.getConfig();
      if (savedConfig) {
        this.config = savedConfig;
        // 保存原始配置
        this.originalConfig = {
          selectionAlgorithm: savedConfig.selectionAlgorithm,
          autoOptimizeFont: savedConfig.autoOptimizeFont,
          autoOptimizeBackground: savedConfig.autoOptimizeBackground,
          enableSeasonalAdjustment: savedConfig.enableSeasonalAdjustment,
          enableWeatherAdjustment: savedConfig.enableWeatherAdjustment
        };
      }
    } catch (error) {
      console.error('Failed to load config:', error);
    }
  }

  async loadQuoteSource() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await QuoteData.loadQuoteSource(context);
      this.currentQuoteSource = QuoteData.getQuoteSource();
      // 保存原始值
      this.originalQuoteSource = this.currentQuoteSource;
      console.log('设置页面加载的名言来源:', this.currentQuoteSource);
    } catch (error) {
      console.error('Failed to load quote source:', error);
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

  async saveQuoteSource(source: QuoteSource) {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await QuoteData.saveQuoteSource(source, context);
      this.currentQuoteSource = source;
      console.log('Quote source saved successfully:', source);
    } catch (error) {
      console.error('Failed to save quote source:', error);
    }
  }

  checkForChanges() {
    // 检查配置是否有变化
    const configChanged =
      this.config.selectionAlgorithm !== this.originalConfig.selectionAlgorithm ||
      this.config.autoOptimizeFont !== this.originalConfig.autoOptimizeFont ||
      this.config.autoOptimizeBackground !== this.originalConfig.autoOptimizeBackground ||
      this.config.enableSeasonalAdjustment !== this.originalConfig.enableSeasonalAdjustment ||
      this.config.enableWeatherAdjustment !== this.originalConfig.enableWeatherAdjustment;

    // 检查名言源是否有变化
    const quoteSourceChanged = this.currentQuoteSource !== this.originalQuoteSource;

    this.hasChanges = configChanged || quoteSourceChanged;
  }

  async applyChanges() {
    try {
      // 检查名言来源是否变化
      const quoteSourceChanged = this.currentQuoteSource !== this.originalQuoteSource;

      await this.saveConfig();
      await this.saveQuoteSource(this.currentQuoteSource);

      // 更新原始值
      this.originalConfig = {
        selectionAlgorithm: this.config.selectionAlgorithm,
        autoOptimizeFont: this.config.autoOptimizeFont,
        autoOptimizeBackground: this.config.autoOptimizeBackground,
        enableSeasonalAdjustment: this.config.enableSeasonalAdjustment,
        enableWeatherAdjustment: this.config.enableWeatherAdjustment
      };
      this.originalQuoteSource = this.currentQuoteSource;

      // 重置变更状态
      this.hasChanges = false;

      promptAction.showToast({
        message: '设置已保存',
        duration: 2000
      });

      // 如果名言来源变化了，存储标记
      if (quoteSourceChanged) {
        // 使用AppStorage存储标记，主界面会在onPageShow时检查
        AppStorage.setOrCreate('quoteSourceChanged', true);
        console.log('设置页面：名言来源已变化，设置标记为true');
      }

      // 应用成功后直接返回主界面
      setTimeout(() => {
        router.back();
      }, 500); // 短暂延迟让用户看到提示信息
    } catch (error) {
      console.error('Failed to apply changes:', error);
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      });
    }
  }

  initSettingGroups() {
    this.settingGroups = [
      {
        title: '名言设置',
        items: [
          {
            id: 'quote_source',
            title: '名言来源',
            description: '选择名言的内容来源',
            type: SettingType.RADIO,
            value: this.currentQuoteSource,
            options: [
              { label: '毛选摘抄', value: QuoteSource.MAOZEDONG } as OptionItem,
              { label: '诗经精选', value: QuoteSource.SHIJING } as OptionItem,
              { label: '唐诗三百首', value: QuoteSource.TANGSHI } as OptionItem
            ],
            onChangeString: (value: string) => {
              this.currentQuoteSource = value as QuoteSource;
              this.updateSettingValue('quote_source', value);
              this.checkForChanges();
            }
          }
        ]
      }
    ];
  }

  updateSettingValue(id: string, value: boolean | string) {
    this.settingGroups = this.settingGroups.map(group => {
      const newGroup: SettingGroup = {
        title: group.title,
        items: group.items.map(item => {
          if (item.id === id) {
            const newItem: SettingItem = {
              id: item.id,
              title: item.title,
              description: item.description,
              type: item.type,
              value: value,
              options: item.options,
              onClick: item.onClick,
              onChangeBoolean: item.onChangeBoolean,
              onChangeString: item.onChangeString
            };
            return newItem;
          }
          return item;
        })
      };
      return newGroup;
    });
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        Row() {
          Button() {
            Text('‹')
              .fontSize(24)
              .fontColor('#333333')
          }
          .width(40)
          .height(40)
          .backgroundColor('#F5F5F5')
          .borderRadius(20)
          .onClick(() => {
            if (this.hasChanges) {
              // 如果有未保存的更改，提示用户
              AlertDialog.show({
                title: '放弃修改',
                message: '是否放弃修改配置？',
                autoCancel: true,
                alignment: DialogAlignment.Center,
                primaryButton: {
                  value: '否',
                  action: () => {
                    // 点击否，留在设置页面
                  }
                },
                secondaryButton: {
                  value: '是',
                  action: () => {
                    router.back();
                  }
                }
              });
            } else {
              router.back();
            }
          })

          Blank()

          Text('设置')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)

          Blank()

          Button('应用')
            .fontSize(14)
            .fontColor(this.hasChanges ? '#FFFFFF' : '#999999')
            .backgroundColor(this.hasChanges ? '#4A90E2' : '#E5E5E5')
            .enabled(this.hasChanges)
            .height(36)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              if (this.hasChanges) {
                AlertDialog.show({
                  title: '应用',
                  message: '是否确认应用配置？',
                  autoCancel: true,
                  alignment: DialogAlignment.Center,
                  primaryButton: {
                    value: '否',
                    action: () => {
                      // 点击否，什么都不做
                    }
                  },
                  secondaryButton: {
                    value: '是',
                    action: () => {
                      this.applyChanges();
                    }
                  }
                });
              }
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 12, right: 12 })

      // 设置列表
      List({ space: 0 }) {
        ForEach(this.settingGroups, (group: SettingGroup, groupIndex: number) => {
          ListItemGroup({ header: this.groupHeader(group.title) }) {
            ForEach(group.items, (item: SettingItem, itemIndex: number) => {
              ListItem() {
                if (item.type === SettingType.TOGGLE) {
                  this.buildToggleItem(item);
                } else if (item.type === SettingType.RADIO) {
                  this.buildRadioItem(item);
                } else if (item.type === SettingType.NAVIGATION) {
                  this.buildNavigationItem(item);
                }
              }
              .height(item.description ? 72 : 56)
              .backgroundColor('#FFFFFF')
              .padding({ left: 12, right: 12 })
            })
          }
          .divider({
            strokeWidth: 0.5,
            color: '#E5E5E5',
            startMargin: 12,
            endMargin: 12
          })
        })

        // 底部空间
        ListItem() {
          Column().height(20)
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F8F8F8')
      .divider({
        strokeWidth: 0.5,
        color: '#E5E5E5',
        startMargin: 12,
        endMargin: 12
      })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F8F8F8')

      // 自定义选择对话框
      if (this.showDialog && this.currentDialogItem) {
        Column() {
          Column() {
            Text(this.currentDialogItem.title)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ bottom: 16 })

            Column() {
              if (this.currentDialogItem.options) {
                ForEach(this.currentDialogItem.options, (option: OptionItem) => {
                  Row() {
                    Text(option.label)
                      .fontSize(16)
                      .fontColor(this.currentDialogItem?.value === option.value ? '#4A90E2' : '#333333')
                      .layoutWeight(1)

                    if (this.currentDialogItem?.value === option.value) {
                      Text('✓')
                        .fontSize(16)
                        .fontColor('#4A90E2')
                    }
                  }
                  .width('100%')
                  .height(48)
                  .padding({ left: 16, right: 16 })
                  .borderRadius(8)
                  .backgroundColor(this.currentDialogItem?.value === option.value ? '#F0F7FF' : '#FFFFFF')
                  .onClick(() => {
                    if (this.currentDialogItem?.onChangeString) {
                      this.currentDialogItem.onChangeString(option.value);
                      this.showDialog = false;
                      this.currentDialogItem = null;
                    }
                  })
                })
              }
            }
            .margin({ bottom: 16 })

            Button('取消')
              .width('100%')
              .height(44)
              .backgroundColor('#F5F5F5')
              .fontColor('#666666')
              .onClick(() => {
                this.showDialog = false;
                this.currentDialogItem = null;
              })
          }
          .width('90%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showDialog = false;
          this.currentDialogItem = null;
        })
      }
    }
  }

  @Builder
  groupHeader(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor('#666666')
      .padding({ left: 12, top: 8, bottom: 8 })
      .width('100%')
      .backgroundColor('#F8F8F8')
  }

  @Builder
  buildToggleItem(item: SettingItem) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (item.description) {
          Text(item.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: item.value as boolean })
        .selectedColor('#4A90E2')
        .onChange((isOn: boolean) => {
          if (item.onChangeBoolean) {
            item.onChangeBoolean(isOn);
          }
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildRadioItem(item: SettingItem) {
    Column() {
      Row() {
        Column() {
          Text(item.title)
            .fontSize(16)
            .fontColor('#333333')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (item.description) {
            Text(item.description)
              .fontSize(14)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(item.options?.find(opt => opt.value === item.value)?.label || '')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 4 })

        Text('›')
          .fontSize(16)
          .fontColor('#999999')
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.showRadioDialog(item);
      })
    }
  }

  @Builder
  buildNavigationItem(item: SettingItem) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (item.description) {
          Text(item.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      if (item.onClick) {
        item.onClick();
      }
    })
  }

  showRadioDialog(item: SettingItem) {
    if (!item.options || !item.onChangeString) return;

    this.currentDialogItem = item;
    this.showDialog = true;
  }
}