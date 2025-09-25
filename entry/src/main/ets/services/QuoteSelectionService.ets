// 名言选择服务
import { Quote, QuoteData } from '../common/QuoteData';
import { SelectionAlgorithm } from '../common/ScheduleConfig';


export class QuoteSelectionService {

  // 根据算法选择名言
  static async selectQuote(algorithm: SelectionAlgorithm): Promise<Quote> {
    let result: Quote;
    switch (algorithm) {
      case SelectionAlgorithm.RANDOM:
        result = QuoteSelectionService.selectRandomQuote();
        break;

      case SelectionAlgorithm.SEQUENTIAL:
        result = QuoteSelectionService.selectSequentialQuote();
        break;

      case SelectionAlgorithm.SMART:
        // 智能选择暂时使用随机选择
        result = QuoteSelectionService.selectRandomQuote();
        break;

      default:
        result = QuoteSelectionService.selectRandomQuote();
        break;
    }
    return result;
  }

  // 随机选择
  private static selectRandomQuote(): Quote {
    return QuoteData.getRandomQuote();
  }

  // 顺序选择
  private static selectSequentialQuote(): Quote {
    // 实现顺序选择逻辑
    const allQuotes = QuoteData.getAllQuotes();
    const currentIndex = QuoteSelectionService.getSequentialIndex();
    const nextIndex = (currentIndex + 1) % allQuotes.length;
    QuoteSelectionService.setSequentialIndex(nextIndex);
    return allQuotes[currentIndex];
  }

  // 获取顺序索引
  private static getSequentialIndex(): number {
    // 在实际实现中应该从存储中读取
    return Math.floor(Date.now() / 1000) % QuoteData.getAllQuotes().length;
  }

  // 设置顺序索引
  private static setSequentialIndex(index: number): void {
    // 在实际实现中应该保存到存储中
  }


  // 获取推荐的名言列表
  static async getRecommendedQuotes(count: number = 5, excludeQuoteTexts?: Set<string>): Promise<Quote[]> {
    const allQuotes = QuoteData.getAllQuotes();
    console.log(`[QuoteSelectionService] 当前名言源: ${QuoteData.getQuoteSource()}`);
    console.log(`[QuoteSelectionService] 所有名言数量: ${allQuotes.length}`);

    // 先过滤掉已使用的quotes
    const availableQuotes = excludeQuoteTexts && excludeQuoteTexts.size > 0
      ? allQuotes.filter(quote => !excludeQuoteTexts.has(quote.text))
      : allQuotes;

    // 如果过滤后的quotes不足，记录警告
    if (availableQuotes.length < count) {
      console.warn(`可用quotes不足，需要${count}个，只有${availableQuotes.length}个`);
    }

    // 随机打乱顺序
    const shuffled = [...availableQuotes];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    return shuffled.slice(0, Math.min(count, availableQuotes.length));
  }
}