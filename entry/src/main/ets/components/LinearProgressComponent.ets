// 线性进度条组件
@Component
export struct LinearProgressComponent {
  @Prop progressWidth: number = 0;      // 进度百分比 (0-100)
  @Prop progressOpacity: number = 0;    // 进度条透明度（控制整体透明度）
  @Prop isEnabled: boolean = true;      // 是否启用

  build() {
    if (this.isEnabled) {
      Column() {
        Stack({ alignContent: Alignment.Start }) {
          // 背景轨道
          Row()
            .width('100%')
            .height(2)
            .backgroundColor('#FFFFFF')
            .opacity(0.1 * (this.progressOpacity / 0.3))  // 背景透明度跟随主透明度变化

          // 进度条
          Row()
            .width(`${this.progressWidth}%`)
            .height(2)
            .backgroundColor('#FFFFFF')
            .opacity(this.progressOpacity)
            .animation({
              duration: 100,
              curve: Curve.Linear
            })
        }
        .width('50%')  // 屏幕宽度的1/2
        .height(2)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)  // 水平居中
      .position({ x: 0, y: '100%' })
      .translate({ y: -50 })  // 向上偏移到适当位置
    }
  }
}