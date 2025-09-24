// 名言数据管理
import { QuoteDataLoaderService } from '../services/QuoteDataLoaderService';
import { DataStats, QuoteDataStatsResult } from './ServiceTypes';
import common from '@ohos.app.ability.common';
import { preferences as dataPreferences } from '@kit.ArkData';

export interface Quote {
  text: string;
  author?: string;
  category: string;
  source?: string;
  bg_color?: string;        // 建议的背景颜色
  bg_color_reason?: string; // 选择该颜色的理由
}

export enum QuoteSource {
  SHIJING = 'shijing',
  MAOZEDONG = 'maozedong',
  TANGSHI = 'tangshi'
}

export class QuoteData {

  private static currentSource: QuoteSource = QuoteSource.MAOZEDONG;
  private static readonly QUOTE_SOURCE_KEY = 'quote_source';

  static async loadQuoteSource(context?: common.UIAbilityContext): Promise<void> {
    try {
      // 首先加载数据
      await QuoteDataLoaderService.loadQuoteData(context);

      // 加载用户偏好设置
      if (context) {
        try {
          const preferencesInstance = await dataPreferences.getPreferences(context, 'app_preferences');
          const saved = await preferencesInstance.get(QuoteData.QUOTE_SOURCE_KEY, QuoteSource.MAOZEDONG) as string;
          if (saved && Object.values(QuoteSource).includes(saved as QuoteSource)) {
            QuoteData.currentSource = saved as QuoteSource;
          }
        } catch (prefError) {
          console.error('读取Preferences失败:', prefError);
        }
      } else {
      }
    } catch (error) {
      console.error('Failed to load quote source:', error);
    }
  }

  static async saveQuoteSource(source: QuoteSource, context?: common.UIAbilityContext): Promise<void> {
    try {
      QuoteData.currentSource = source;

      // 使用Preferences API保存
      if (context) {
        const preferencesInstance = await dataPreferences.getPreferences(context, 'app_preferences');
        await preferencesInstance.put(QuoteData.QUOTE_SOURCE_KEY, source);
        await preferencesInstance.flush();
      } else {
      }
    } catch (error) {
      console.error('Failed to save quote source:', error);
    }
  }

  static setQuoteSource(source: QuoteSource): void {
    QuoteData.currentSource = source;
  }

  static getQuoteSource(): QuoteSource {
    return QuoteData.currentSource;
  }

  static getAllQuotes(): Quote[] {
    return QuoteDataLoaderService.getQuotesBySource(QuoteData.currentSource);
  }

  static getRandomQuote(): Quote {
    const quotes = QuoteData.getAllQuotes();
    if (quotes.length === 0) {
      // 如果没有数据，返回默认名言
      const defaultQuote: Quote = {
        text: "一切群众的实际生活问题，都是我们应当注意的问题",
        author: "毛泽东",
        category: "群众",
        source: "《关心群众生活，注意工作方法》"
      };
      return defaultQuote;
    }
    return quotes[Math.floor(Math.random() * quotes.length)];
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