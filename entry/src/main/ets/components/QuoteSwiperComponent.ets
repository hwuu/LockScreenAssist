// 名言滑动组件
import { Quote } from '../common/QuoteData';
import { Card } from '../services/CardService';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct QuoteSwiperComponent {
  @Link currentPageIndex: number;
  @Consume quoteDataSource: QuoteDataSource;
  @Link cardList: (Card | null)[];
  @Link optimizedFontSizes: number[];
  @Prop contentOpacity: number;
  @Prop swipeEnabled: boolean = true;  // 是否启用滑动
  formatQuoteText: (text: string, fontSize?: number, containerWidth?: number) => TextLayoutResult = () => ({ text: '', fontSize: 24, lines: [] });
  onScrollIndex: (index: number) => void = () => {};
  updateBackgroundForCurrentPage: (index: number) => void = () => {};
  resetHintTimer: () => void = () => {};


  build() {
    Swiper() {
      LazyForEach(this.quoteDataSource, (quote: Quote, index: number) => {
        Column() {
          Text(this.formatQuoteText(quote.text).text)
            .fontSize(this.optimizedFontSizes[index] || (this.cardList[index]?.style.fontSize) || UI_CONSTANTS.DEFAULT_FONT_SIZE)
            .fontColor((this.cardList[index]?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: UI_CONSTANTS.TEXT_BOTTOM_MARGIN })
            .maxLines(UI_CONSTANTS.TEXT_LAYOUT.MAX_LINES)
            .textOverflow({ overflow: TextOverflow.None })

          Text(`—— ${quote.author || ''}${(quote.author && quote.source) ? ' · ' : ''}${quote.source || ''}`)
            .fontSize(UI_CONSTANTS.AUTHOR_FONT_SIZE)
            .fontColor((this.cardList[index]?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
            .opacity(UI_CONSTANTS.AUTHOR_TEXT_OPACITY)
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(UI_CONSTANTS.CONTAINER_PADDING)
        .width('100%')
        .height('100%')
      }, (quote: Quote, index: number) => `${quote.text}-${index}`)
    }
    .index(this.currentPageIndex)
    .width('100%')
    .height('100%')
    .indicator(false)
    .vertical(true)
    .loop(false)
    .cachedCount(UI_CONSTANTS.SWIPER_CACHED_COUNT)
    .enabled(this.swipeEnabled)
    .onChange((index: number) => {
      if (index >= 0 && index < this.quoteDataSource.totalCount()) {
        this.onScrollIndex(index);
        this.updateBackgroundForCurrentPage(index);
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
      if (targetIndex >= this.quoteDataSource.totalCount()) {
        return;
      }
    })
    .opacity(this.contentOpacity)
  }
}