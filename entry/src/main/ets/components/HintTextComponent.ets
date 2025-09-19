// 底部提示文字组件
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct HintTextComponent {
  @Prop hintOpacity: number = 0;

  build() {
    Column() {
      Text('上下滑动切换 · 长按保存')
        .fontSize(UI_CONSTANTS.HINT_FONT_SIZE)
        .fontColor(UI_CONSTANTS.WHITE_COLOR)
        .textAlign(TextAlign.Center)
        .padding({
          top: 12,
          bottom: 12,
          left: UI_CONSTANTS.CONTAINER_PADDING,
          right: UI_CONSTANTS.CONTAINER_PADDING
        })
        .borderRadius(UI_CONSTANTS.DIALOG_BORDER_RADIUS)
    }
    .width('100%')
    .padding({
      left: UI_CONSTANTS.CONTAINER_PADDING,
      right: UI_CONSTANTS.CONTAINER_PADDING,
      bottom: 30,
      top: UI_CONSTANTS.CONTAINER_PADDING
    })
    .backgroundColor('rgba(0, 0, 0, 0)')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
    .opacity(this.hintOpacity)
  }
}