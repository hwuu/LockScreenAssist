// 名言滑动组件
import { Quote } from '../common/QuoteData';
import { GeneratedWallpaper } from '../services/WallpaperService';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { UI_CONSTANTS } from '../common/UIConstants';

@Component
export struct QuoteSwiperComponent {
  @Link currentPageIndex: number;
  @Consume quoteDataSource: QuoteDataSource;
  @Prop wallpaperList: (GeneratedWallpaper | null)[];
  @Prop optimizedFontSizes: number[];
  @Prop contentOpacity: number;
  formatQuoteText: (text: string, fontSize?: number, containerWidth?: number) => TextLayoutResult = () => ({ text: '', fontSize: 24, lines: [] });
  onScrollIndex: (index: number) => void = () => {};
  updateBackgroundForCurrentPage: (index: number) => void = () => {};
  resetHintTimer: () => void = () => {};

  aboutToAppear() {
    console.log('CLAUDE_DEBUG: QuoteSwiperComponent.aboutToAppear: quoteDataSource totalCount:', this.quoteDataSource.totalCount());
    console.log('CLAUDE_DEBUG: QuoteSwiperComponent.aboutToAppear: currentPageIndex:', this.currentPageIndex);
  }

  private logQuoteInfo(quote: Quote, index: number) {
    console.log(`CLAUDE_DEBUG: QuoteSwiperComponent LazyForEach index ${index}:`, quote?.text || 'null');
    const formattedText = this.formatQuoteText(quote.text);
    const fontSize = this.optimizedFontSizes[index] || (this.wallpaperList[index]?.style.fontSize) || UI_CONSTANTS.DEFAULT_FONT_SIZE;
    const fontColor = (this.wallpaperList[index]?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR;
    console.log(`CLAUDE_DEBUG: QuoteSwiperComponent Text ${index}: text="${formattedText.text}", fontSize=${fontSize}, color=${fontColor}`);
  }

  build() {
    Swiper() {
      LazyForEach(this.quoteDataSource, (quote: Quote, index: number) => {
        Column() {
          Text(this.formatQuoteText(quote.text).text)
            .fontSize(this.optimizedFontSizes[index] || (this.wallpaperList[index]?.style.fontSize) || UI_CONSTANTS.DEFAULT_FONT_SIZE)
            .fontColor((this.wallpaperList[index]?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ bottom: UI_CONSTANTS.TEXT_BOTTOM_MARGIN })
            .maxLines(UI_CONSTANTS.TEXT_LAYOUT.MAX_LINES)
            .textOverflow({ overflow: TextOverflow.None })

          Text(`—— ${quote.author || ''}${(quote.author && quote.source) ? ' · ' : ''}${quote.source || ''}`)
            .fontSize(UI_CONSTANTS.AUTHOR_FONT_SIZE)
            .fontColor((this.wallpaperList[index]?.style.textColor) || UI_CONSTANTS.TEXT_GRAY_COLOR)
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
    .onChange((index: number) => {
      console.log('CLAUDE_DEBUG: QuoteSwiperComponent.onChange: index:', index, 'totalCount:', this.quoteDataSource.totalCount());
      if (index >= 0 && index < this.quoteDataSource.totalCount()) {
        console.log('CLAUDE_DEBUG: QuoteSwiperComponent.onChange: 调用onScrollIndex');
        const currentQuote = this.quoteDataSource.getData(index);
        console.log('CLAUDE_DEBUG: QuoteSwiperComponent.onChange: 当前名言:', currentQuote?.text || 'null');
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
        console.log('CLAUDE_DEBUG: 防止向前滑动超出边界');
        return;
      }
      if (targetIndex >= this.quoteDataSource.totalCount()) {
        console.log('CLAUDE_DEBUG: 防止向后滑动超出边界');
        return;
      }
    })
    .opacity(this.contentOpacity)
  }
}