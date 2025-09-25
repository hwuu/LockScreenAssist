// 卡片查看器组件
import { Card } from '../services/CardService';
import { CardViewerDataSource } from '../common/CardViewerDataSource';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct CardViewerComponent {
  @Link currentCardIndex: number;
  @Consume cardViewerDataSource: CardViewerDataSource;
  @Link optimizedFontSizes: number[];
  @Prop contentOpacity: number;
  @Prop swipeEnabled: boolean = true;  // 是否启用滑动
  formatQuoteText: (text: string, fontSize?: number, containerWidth?: number) => TextLayoutResult = () => ({ text: '', fontSize: 24, lines: [] });
  onScrollIndex: (index: number) => void = () => {};
  updateBackgroundForCurrentCard: (index: number) => void = () => {};
  resetHintTimer: () => void = () => {};


  build() {
    Swiper() {
      LazyForEach(this.cardViewerDataSource, (card: Card, index: number) => {
        Column() {
          Text(this.formatQuoteText(card.quote.text).text)
            .fontSize(this.optimizedFontSizes[index] || card.style.fontSize || UI_CONSTANTS.DEFAULT_FONT_SIZE)
            .fontColor(card.style.textColor || UI_CONSTANTS.TEXT_GRAY_COLOR)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: UI_CONSTANTS.TEXT_BOTTOM_MARGIN })
            .maxLines(UI_CONSTANTS.TEXT_LAYOUT.MAX_LINES)
            .textOverflow({ overflow: TextOverflow.None })

          Text(`—— ${card.quote.author || ''}${(card.quote.author && card.quote.source) ? ' · ' : ''}${card.quote.source || ''}`)
            .fontSize(UI_CONSTANTS.AUTHOR_FONT_SIZE)
            .fontColor(card.style.textColor || UI_CONSTANTS.TEXT_GRAY_COLOR)
            .opacity(UI_CONSTANTS.AUTHOR_TEXT_OPACITY)
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(UI_CONSTANTS.CONTAINER_PADDING)
        .width('100%')
        .height('100%')
      }, (card: Card, index: number) => `${card.quote.text}-${index}`)
    }
    .index(this.currentCardIndex)
    .width('100%')
    .height('100%')
    .indicator(false)
    .vertical(true)
    .loop(false)
    .cachedCount(UI_CONSTANTS.SWIPER_CACHED_COUNT)
    .enabled(this.swipeEnabled)
    .onChange((index: number) => {
      if (index >= 0 && index < this.cardViewerDataSource.totalCount()) {
        this.onScrollIndex(index);
        this.updateBackgroundForCurrentCard(index);
        this.resetHintTimer();
      }
    })
    .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
      this.resetHintTimer();
    })
    .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
      if (targetIndex < 0) {
        return;
      }
      if (targetIndex >= this.cardViewerDataSource.totalCount()) {
        return;
      }
    })
    .opacity(this.contentOpacity)
  }
}