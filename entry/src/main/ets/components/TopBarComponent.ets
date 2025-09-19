// 顶部标题栏组件
import router from '@ohos.router';
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct TopBarComponent {
  build() {
    Row() {
      Blank()

      Button() {
        Text('...')
          .fontSize(UI_CONSTANTS.SUBTITLE_FONT_SIZE)
          .fontColor(UI_CONSTANTS.WHITE_COLOR)
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