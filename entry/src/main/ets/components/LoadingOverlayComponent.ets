// 加载遮罩组件
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct LoadingOverlayComponent {
  @Prop isLoading: boolean = false;

  build() {
    if (this.isLoading) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(`rgba(0, 0, 0, ${UI_CONSTANTS.LOADING_OVERLAY_OPACITY})`)
          .backdropBlur(10)

        Column() {
          LoadingProgress()
            .width(UI_CONSTANTS.LOADING_PROGRESS_SIZE)
            .height(UI_CONSTANTS.LOADING_PROGRESS_SIZE)
            .margin({ bottom: UI_CONSTANTS.DIALOG_MARGIN })

          Text('正在生成壁纸...')
            .fontSize(UI_CONSTANTS.SUBTITLE_FONT_SIZE)
            .fontColor(UI_CONSTANTS.WHITE_COLOR)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width(UI_CONSTANTS.LOADING_CONTAINER_SIZE)
        .height(UI_CONSTANTS.LOADING_CONTAINER_SIZE)
        .backgroundColor(`rgba(44, 62, 80, ${UI_CONSTANTS.DIALOG_BACKGROUND_OPACITY})`)
        .borderRadius(UI_CONSTANTS.DIALOG_MARGIN)
        .backdropBlur(20)
      }
      .width('100%')
      .height('100%')
    }
  }
}