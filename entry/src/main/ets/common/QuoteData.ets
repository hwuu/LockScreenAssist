// 名言数据管理
import { QuoteDataLoaderService } from '../services/QuoteDataLoaderService';
import { DataStats, QuoteDataStatsResult } from './ServiceTypes';
import common from '@ohos.app.ability.common';

export interface Quote {
  text: string;
  author?: string;
  category: string;
  season?: string;
  weather?: string;
  source?: string;
}

export enum QuoteSource {
  SHIJING = 'shijing',
  MAOZEDONG = 'maozedong'
}

export class QuoteData {

  private static currentSource: QuoteSource = QuoteSource.MAOZEDONG;
  private static readonly QUOTE_SOURCE_KEY = 'quote_source';

  static async loadQuoteSource(context?: common.UIAbilityContext): Promise<void> {
    try {
      console.log('CLAUDE_DEBUG: QuoteData.loadQuoteSource 开始执行');
      // 首先加载数据
      await QuoteDataLoaderService.loadQuoteData(context);
      console.log('CLAUDE_DEBUG: QuoteDataLoaderService.loadQuoteData 完成');

      // 加载用户偏好设置
      const saved: string | null = globalThis.localStorage?.getItem?.(QuoteData.QUOTE_SOURCE_KEY) || null;
      if (saved && Object.values(QuoteSource).includes(saved as QuoteSource)) {
        QuoteData.currentSource = saved as QuoteSource;
        console.log(`CLAUDE_DEBUG: 使用保存的名言来源: ${QuoteData.currentSource}`);
      } else {
        console.log(`CLAUDE_DEBUG: 使用默认名言来源: ${QuoteData.currentSource}`);
      }
      console.log('CLAUDE_DEBUG: QuoteData.loadQuoteSource 完成');
    } catch (error) {
      console.error('CLAUDE_DEBUG: Failed to load quote source:', error);
    }
  }

  static async saveQuoteSource(source: QuoteSource): Promise<void> {
    try {
      QuoteData.currentSource = source;
      // 在实际实现中应该使用Preferences API
      // 这里先用localStorage模拟
      globalThis.localStorage?.setItem?.(QuoteData.QUOTE_SOURCE_KEY, source);
    } catch (error) {
      console.error('CLAUDE_DEBUG: Failed to save quote source:', error);
    }
  }

  static setQuoteSource(source: QuoteSource): void {
    QuoteData.currentSource = source;
  }

  static getQuoteSource(): QuoteSource {
    return QuoteData.currentSource;
  }

  static getAllQuotes(): Quote[] {
    console.log('CLAUDE_DEBUG: QuoteData.getAllQuotes 开始, currentSource:', QuoteData.currentSource);
    const quotes = QuoteDataLoaderService.getQuotesBySource(QuoteData.currentSource);
    console.log('CLAUDE_DEBUG: QuoteData.getAllQuotes 完成, quotes数量:', quotes.length);
    return quotes;
  }

  static getRandomQuote(): Quote {
    console.log('CLAUDE_DEBUG: QuoteData.getRandomQuote 开始');
    const quotes = QuoteData.getAllQuotes();
    console.log('CLAUDE_DEBUG: QuoteData.getRandomQuote: 获取到quotes数量:', quotes.length);
    if (quotes.length === 0) {
      // 如果没有数据，返回默认名言
      console.log('CLAUDE_DEBUG: QuoteData.getRandomQuote: 没有数据，返回默认名言');
      const defaultQuote: Quote = {
        text: "一切群众的实际生活问题，都是我们应当注意的问题",
        author: "毛泽东",
        category: "群众",
        source: "《关心群众生活，注意工作方法》"
      };
      return defaultQuote;
    }
    const selectedQuote = quotes[Math.floor(Math.random() * quotes.length)];
    console.log('CLAUDE_DEBUG: QuoteData.getRandomQuote 完成, quote:', selectedQuote?.text || 'null');
    return selectedQuote;
  }

  static getQuotesByCategory(category: string): Quote[] {
    return QuoteData.getAllQuotes().filter(quote => quote.category === category);
  }

  static getQuotesBySeason(season: string): Quote[] {
    return QuoteData.getAllQuotes().filter(quote => !quote.season || quote.season === season);
  }

  static getQuotesByWeather(weather: string): Quote[] {
    return QuoteData.getAllQuotes().filter(quote => !quote.weather || quote.weather === weather);
  }

  /**
   * 获取数据统计信息
   */
  static getDataStats(): QuoteDataStatsResult {
    const stats: DataStats = QuoteDataLoaderService.getDataStats();
    const currentSourceCount = QuoteData.currentSource === QuoteSource.SHIJING ?
      stats.shijingCount : stats.maozedongCount;

    const result: QuoteDataStatsResult = {
      currentSourceCount,
      totalCount: stats.totalCount
    };
    return result;
  }

  /**
   * 检查数据是否已加载
   */
  static isDataLoaded(): boolean {
    return QuoteDataLoaderService.isDataLoadedFlag();
  }
}