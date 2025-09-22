import { ScheduleConfig, WallpaperConfig, SelectionAlgorithm } from '../common/ScheduleConfig';
import { QuoteData, QuoteSource } from '../common/QuoteData';
import { router, promptAction } from '@kit.ArkUI';

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
  @State config: WallpaperConfig = {
    selectionAlgorithm: SelectionAlgorithm.SMART,
    autoOptimizeFont: true,
    autoOptimizeBackground: true,
    enableSeasonalAdjustment: true,
    enableWeatherAdjustment: false
  };

  @State currentQuoteSource: QuoteSource = QuoteSource.MAOZEDONG;
  @State settingGroups: SettingGroup[] = [];
  @State showDialog: boolean = false;
  @State currentDialogItem: SettingItem | null = null;

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
      }
    } catch (error) {
      console.error('Failed to load config:', error);
    }
  }

  async loadQuoteSource() {
    try {
      await QuoteData.loadQuoteSource();
      this.currentQuoteSource = QuoteData.getQuoteSource();
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
      await QuoteData.saveQuoteSource(source);
      this.currentQuoteSource = source;
      console.log('Quote source saved successfully:', source);
    } catch (error) {
      console.error('Failed to save quote source:', error);
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
              { label: '诗经精选', value: QuoteSource.SHIJING } as OptionItem,
              { label: '毛选摘抄', value: QuoteSource.MAOZEDONG } as OptionItem
            ],
            onChangeString: (value: string) => {
              this.saveQuoteSource(value as QuoteSource);
              this.updateSettingValue('quote_source', value);
            }
          },
          {
            id: 'selection_algorithm',
            title: '选择算法',
            description: '名言展示的算法策略',
            type: SettingType.RADIO,
            value: this.config.selectionAlgorithm,
            options: [
              { label: '智能推荐', value: SelectionAlgorithm.SMART } as OptionItem,
              { label: '随机选择', value: SelectionAlgorithm.RANDOM } as OptionItem,
              { label: '顺序选择', value: SelectionAlgorithm.SEQUENTIAL } as OptionItem
            ],
            onChangeString: (value: string) => {
              this.config.selectionAlgorithm = value as SelectionAlgorithm;
              this.saveConfig();
              this.updateSettingValue('selection_algorithm', value);
            }
          }
        ]
      },
      {
        title: '显示优化',
        items: [
          {
            id: 'auto_font',
            title: '自动字体优化',
            description: '根据文本长度自动调整字体大小',
            type: SettingType.TOGGLE,
            value: this.config.autoOptimizeFont,
            onChangeBoolean: (value: boolean) => {
              this.config.autoOptimizeFont = value;
              this.saveConfig();
              this.updateSettingValue('auto_font', value);
            }
          },
          {
            id: 'auto_background',
            title: '自动背景优化',
            description: '根据内容智能选择背景颜色',
            type: SettingType.TOGGLE,
            value: this.config.autoOptimizeBackground,
            onChangeBoolean: (value: boolean) => {
              this.config.autoOptimizeBackground = value;
              this.saveConfig();
              this.updateSettingValue('auto_background', value);
            }
          }
        ]
      },
      {
        title: '环境适应',
        items: [
          {
            id: 'seasonal',
            title: '季节调整',
            description: '根据当前季节调整配色方案',
            type: SettingType.TOGGLE,
            value: this.config.enableSeasonalAdjustment,
            onChangeBoolean: (value: boolean) => {
              this.config.enableSeasonalAdjustment = value;
              this.saveConfig();
              this.updateSettingValue('seasonal', value);
            }
          },
          {
            id: 'weather',
            title: '天气调整',
            description: '根据天气情况调整显示效果',
            type: SettingType.TOGGLE,
            value: this.config.enableWeatherAdjustment,
            onChangeBoolean: (value: boolean) => {
              this.config.enableWeatherAdjustment = value;
              this.saveConfig();
              this.updateSettingValue('weather', value);
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
          router.back();
        })

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .margin({ left: 16 })
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