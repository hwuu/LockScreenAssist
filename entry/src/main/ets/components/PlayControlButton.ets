/**
 * 自动播放控制按钮组件
 */

@Component
export struct PlayControlButton {
  @Prop isAutoPlaying: boolean = false;
  @Prop showLoadingIcon: boolean = false;
  onPlayClick: () => void = () => {};
  onPauseClick: () => void = () => {};

  build() {
    Button() {
      if (this.showLoadingIcon) {
        // 转圈loading图标
        LoadingProgress()
          .width(24)
          .height(24)
          .color('#ffffff')
      } else if (this.isAutoPlaying) {
        // 暂停图标（两条竖线）
        Row() {
          Rect()
            .width(6)
            .height(20)
            .fill('#ffffff')
            .margin({ right: 4 })
          Rect()
            .width(6)
            .height(20)
            .fill('#ffffff')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
      } else {
        // 播放图标（三角形）
        Polygon()
          .points([[0, 0], [0, 20], [17, 10]])
          .fill('#ffffff')
          .width(17)
          .height(20)
      }
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor('rgba(0, 0, 0, 0.3)')
    .backdropBlur(10)
    .enabled(!this.showLoadingIcon)  // loading时禁用点击
    .onClick(() => {
      if (!this.showLoadingIcon) {
        if (this.isAutoPlaying) {
          this.onPauseClick();
        } else {
          this.onPlayClick();
        }
      }
    })
    .position({ x: '82%', y: 100 })
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.3)',
      offsetX: 0,
      offsetY: 2
    })
    .animation({
      duration: 300,
      curve: Curve.EaseOut
    })
  }
}