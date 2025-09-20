// 顶部标题栏组件
import router from '@ohos.router';
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct TopBarComponent {
  @Prop isAutoPlaying: boolean = false;
  @Prop showLoadingIcon: boolean = false;
  @Prop idleProgressPercentage: number = 0;  // IDLE进度百分比
  @Prop progressOpacity: number = 1;  // 进度圈圈透明度
  onPlayClick: () => void = () => {};
  onPauseClick: () => void = () => {};

  /**
   * 生成按钮内部的圆弧路径
   * @param size 容器大小（宽高）
   * @param radius 圆弧半径
   */
  private getArcPathForButton(size: number, radius: number): string {
    // HACK: 由于 Shape 默认 viewPort 的奇怪行为，需要调整坐标
    // 正常情况下应该是 centerX = size / 2, centerY = size / 2
    // 但实际上需要偏移和缩放才能正确显示
    const delta = 10
    size *= 3
    radius *= 3

    const centerX = size / 2 + delta;
    const centerY = size / 2 + delta;

    // 计算结束角度（0% = 12点钟，100% = 完整一圈）
    const percentage = Math.min(Math.max(this.idleProgressPercentage, 0), 100);
    const endAngle = (percentage / 100) * 360 - 90;  // -90度是12点钟方向

    // 起始点（12点钟位置）
    const startX = centerX;
    const startY = centerY - radius;

    // 如果进度很小，只画一个点
    if (percentage < 1) {
      return `M ${startX} ${startY}`;
    }

    // 计算结束点
    const endAngleRad = endAngle * Math.PI / 180;
    const endX = centerX + radius * Math.cos(endAngleRad);
    const endY = centerY + radius * Math.sin(endAngleRad);

    // 判断是否需要画大弧（超过180度）
    const largeArc = percentage > 50 ? 1 : 0;

    // SVG路径：M起点 A圆弧
    return `M ${startX} ${startY} A ${radius} ${radius} 0 ${largeArc} 1 ${endX} ${endY}`;
  }

  build() {
    Row() {
      // 设置按钮（左侧）
      Button() {
        Text('⋯')
          .fontSize(16)
          .fontColor(UI_CONSTANTS.WHITE_COLOR)
          .fontFamily('Times New Roman')
      }
      .width(UI_CONSTANTS.BUTTON_SIZE)
      .height(UI_CONSTANTS.BUTTON_SIZE)
      .backgroundColor('rgba(255, 255, 255, 0)')
      .borderRadius(UI_CONSTANTS.BUTTON_RADIUS)
      .backdropBlur(10)
      .onClick(() => {
        router.pushUrl({
          url: 'pages/Settings'
        });
      })

      Blank()

      // 播放控制按钮（右侧）
      Button() {
        if (this.showLoadingIcon) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(UI_CONSTANTS.WHITE_COLOR)
        } else if (this.isAutoPlaying) {
          // 暂停图标 - 使用Stack叠加进度圆圈和两个矩形
          Stack() {
            // 进度圆圈（仅在IDLE状态且有进度时显示）
            if (this.idleProgressPercentage > 0) {
              Shape() {
                Path()
                  .commands(this.getArcPathForButton(
                    UI_CONSTANTS.BUTTON_SIZE,  // 容器大小
                    UI_CONSTANTS.BUTTON_SIZE * 0.5 * 0.8  // 圆弧半径
                  ))
                  .strokeWidth(2)
                  .stroke('rgba(255, 255, 255, 0.8)')
                  .fillOpacity(0)
                  .strokeLineCap(LineCapStyle.Round)
                  .width(UI_CONSTANTS.BUTTON_SIZE)
                  .height(UI_CONSTANTS.BUTTON_SIZE)
              }
              .width(UI_CONSTANTS.BUTTON_SIZE)
              .height(UI_CONSTANTS.BUTTON_SIZE)
              .opacity(this.progressOpacity)  // 使用透明度属性实现淡入淡出
            }

            // 两个竖线（暂停图标）- 居中显示
            Row() {
              Rect()
                .width(4)
                .height(12)
                .fill(UI_CONSTANTS.WHITE_COLOR)
                .margin({ right: 3 })
              Rect()
                .width(4)
                .height(12)
                .fill(UI_CONSTANTS.WHITE_COLOR)
            }
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.Center)
          }
          .width(UI_CONSTANTS.BUTTON_SIZE)
          .height(UI_CONSTANTS.BUTTON_SIZE)
          .alignContent(Alignment.Center)
        } else {
          // 播放图标 - 使用 Polygon 绘制三角形
          Polygon()
            .points([[1, 0], [1, 12], [11, 6]])  // 三角形的三个顶点
            .fill(UI_CONSTANTS.WHITE_COLOR)
            .width(12)
            .height(12)
        }
      }
      .width(UI_CONSTANTS.BUTTON_SIZE)
      .height(UI_CONSTANTS.BUTTON_SIZE)
      .backgroundColor('rgba(255, 255, 255, 0)')
      .borderRadius(UI_CONSTANTS.BUTTON_RADIUS)
      .backdropBlur(10)
      .enabled(!this.showLoadingIcon)
      .onClick(() => {
        if (!this.showLoadingIcon) {
          if (this.isAutoPlaying) {
            this.onPauseClick();
          } else {
            this.onPlayClick();
          }
        }
      })
    }
    .width('100%')
    .height(UI_CONSTANTS.TOP_BAR_HEIGHT)
    .padding({
      left: UI_CONSTANTS.CONTAINER_PADDING,
      right: UI_CONSTANTS.CONTAINER_PADDING,
      top: 10,
      bottom: 10
    })
    .backgroundColor('rgba(0, 0, 0, 0)')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
    .position({ x: 0, y: 0 })
  }
}