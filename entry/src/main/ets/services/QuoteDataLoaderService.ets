// 名言数据加载服务
import { Quote, QuoteSource } from '../common/QuoteData';
import { DataStats } from '../common/ServiceTypes';
import resourceManager from '@ohos.resourceManager';
import common from '@ohos.app.ability.common';
import { util } from '@kit.ArkTS';

export class QuoteDataLoaderService {
  private static shijingQuotes: Quote[] = [];
  private static maozedongQuotes: Quote[] = [];
  private static isDataLoaded: boolean = false;

  /**
   * 从rawfile加载名言数据
   */
  static async loadQuoteData(context?: common.UIAbilityContext): Promise<void> {
    if (QuoteDataLoaderService.isDataLoaded) {
      console.log('名言数据已加载，跳过重复加载');
      return;
    }

    console.log('开始加载名言数据...');

    try {
      // 获取资源管理器 - Stage模式下必须使用context
      const resMgr: resourceManager.ResourceManager | undefined = context ? context.resourceManager : globalThis.abilityContext?.resourceManager;
      if (!resMgr) {
        throw new Error('无法获取资源管理器，需要传入context参数');
      }

      // 加载诗经名言
      try {
        const shijingData: Uint8Array = await resMgr.getRawFileContent('shijing_quotes.json');
        const textDecoder = new util.TextDecoder('utf-8');
        const shijingText = textDecoder.decodeWithStream(shijingData, { stream: false });
        QuoteDataLoaderService.shijingQuotes = JSON.parse(shijingText) as Quote[];
        console.log(`加载诗经名言成功: ${QuoteDataLoaderService.shijingQuotes.length}条`);
      } catch (error) {
        console.error('加载诗经名言失败:', error);
        // 使用回退数据
        QuoteDataLoaderService.shijingQuotes = QuoteDataLoaderService.getFallbackShijingQuotes();
      }

      // 加载毛泽东名言
      try {
        const maozedongData: Uint8Array = await resMgr.getRawFileContent('maozedong_quotes.json');
        const textDecoder2 = new util.TextDecoder('utf-8');
        const maozedongText = textDecoder2.decodeWithStream(maozedongData, { stream: false });
        QuoteDataLoaderService.maozedongQuotes = JSON.parse(maozedongText) as Quote[];
        console.log(`加载毛泽东名言成功: ${QuoteDataLoaderService.maozedongQuotes.length}条`);
      } catch (error) {
        console.error('加载毛泽东名言失败:', error);
        // 使用回退数据
        QuoteDataLoaderService.maozedongQuotes = QuoteDataLoaderService.getFallbackMaozedongQuotes();
      }

      QuoteDataLoaderService.isDataLoaded = true;
      console.log('名言数据加载完成');
      console.log(`总共加载: 诗经${QuoteDataLoaderService.shijingQuotes.length}条, 毛泽东${QuoteDataLoaderService.maozedongQuotes.length}条`);

    } catch (error) {
      console.error('获取资源管理器失败:', error);
      // 使用回退数据
      QuoteDataLoaderService.shijingQuotes = QuoteDataLoaderService.getFallbackShijingQuotes();
      QuoteDataLoaderService.maozedongQuotes = QuoteDataLoaderService.getFallbackMaozedongQuotes();
      QuoteDataLoaderService.isDataLoaded = true;
    }
  }

  /**
   * 获取指定来源的名言数据
   */
  static getQuotesBySource(source: QuoteSource): Quote[] {
    if (!QuoteDataLoaderService.isDataLoaded) {
      console.warn('名言数据尚未加载，使用回退数据');
      // 返回回退数据而不是空数组
      switch (source) {
        case QuoteSource.SHIJING:
          return QuoteDataLoaderService.getFallbackShijingQuotes();
        case QuoteSource.MAOZEDONG:
          return QuoteDataLoaderService.getFallbackMaozedongQuotes();
        default:
          return QuoteDataLoaderService.getFallbackMaozedongQuotes();
      }
    }

    switch (source) {
      case QuoteSource.SHIJING:
        return QuoteDataLoaderService.shijingQuotes;
      case QuoteSource.MAOZEDONG:
        return QuoteDataLoaderService.maozedongQuotes;
      default:
        return QuoteDataLoaderService.maozedongQuotes;
    }
  }

  /**
   * 获取所有名言数据
   */
  static getAllQuotes(): Quote[] {
    return [
      ...QuoteDataLoaderService.shijingQuotes,
      ...QuoteDataLoaderService.maozedongQuotes
    ];
  }

  /**
   * 检查数据是否已加载
   */
  static isDataLoadedFlag(): boolean {
    return QuoteDataLoaderService.isDataLoaded;
  }

  /**
   * 获取数据统计信息
   */
  static getDataStats(): DataStats {
    return {
      shijingCount: QuoteDataLoaderService.shijingQuotes.length,
      maozedongCount: QuoteDataLoaderService.maozedongQuotes.length,
      totalCount: QuoteDataLoaderService.getAllQuotes().length
    };
  }

  /**
   * 回退的诗经名言数据（最少量的核心数据）
   */
  private static getFallbackShijingQuotes(): Quote[] {
    return [
      { text: "关关雎鸠，在河之洲。窈窕淑女，君子好逑。", category: "爱情", source: "《诗经·周南·关雎》" },
      { text: "蒹葭苍苍，白露为霜。所谓伊人，在水一方。", category: "思念", season: "秋", weather: "cold", source: "《诗经·秦风·蒹葭》" },
      { text: "死生契阔，与子成说。执子之手，与子偕老。", category: "爱情", source: "《诗经·邶风·击鼓》" },
      { text: "他山之石，可以攻玉。", category: "学习", source: "《诗经·小雅·鹤鸣》" },
      { text: "高山仰止，景行行止。", category: "敬仰", source: "《诗经·小雅·车舝》" }
    ];
  }

  /**
   * 回退的毛泽东名言数据（最少量的核心数据）
   */
  private static getFallbackMaozedongQuotes(): Quote[] {
    return [
      { text: "一切群众的实际生活问题，都是我们应当注意的问题。", author: "毛泽东", category: "群众", source: "《关心群众生活，注意工作方法》" },
      { text: "为人民服务。", author: "毛泽东", category: "服务", source: "《为人民服务》" },
      { text: "没有调查，就没有发言权。", author: "毛泽东", category: "调查", source: "《反对本本主义》" },
      { text: "实践是检验真理的唯一标准。", author: "毛泽东", category: "真理", source: "《实践论》" },
      { text: "好好学习，天天向上。", author: "毛泽东", category: "学习", source: "《对儿童的题词》" }
    ];
  }
}