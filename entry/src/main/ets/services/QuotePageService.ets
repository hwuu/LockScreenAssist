// 名言页面业务逻辑服务
import { Quote } from '../common/QuoteData';
import { QuoteSelectionService } from './QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper } from './WallpaperService';
import { TextLayoutService } from './TextLayoutService';
import { TextUtils } from '../common/TextUtils';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { QuoteListInitResult, QuoteListInitParams, LoadMoreParams, ProcessQuoteParams } from '../common/ServiceTypes';

export class QuotePageService {
  private textLayoutService: TextLayoutService | null = null;
  private usedQuoteTexts: Set<string> = new Set();
  private screenWidth: number = 0;
  private screenHeight: number = 0;

  constructor(screenWidth: number, screenHeight: number) {
    this.screenWidth = screenWidth;
    this.screenHeight = screenHeight;
    this.textLayoutService = new TextLayoutService(screenWidth, screenHeight);
  }

  calculateDynamicContainerWidth(fontSize: number): number {
    const parentPadding = 48;
    const safetyMargin = fontSize * 5;
    const rawContainerWidth = this.screenWidth - parentPadding - safetyMargin;
    return Math.max(rawContainerWidth, 200);
  }

  async processQuote(quote: Quote, params: ProcessQuoteParams): Promise<void> {
    params.quoteDataSource.pushItem(quote);
    this.usedQuoteTexts.add(quote.text);

    const wallpaper = await WallpaperService.generateWallpaper(quote);
    params.wallpaperList.push(wallpaper);
    const quoteFontSize = wallpaper?.style.fontSize || 24;
    const quoteContainerWidth = this.calculateDynamicContainerWidth(quoteFontSize);
    const quoteLayout = this.formatQuoteText(quote.text, quoteFontSize, quoteContainerWidth);
    params.optimizedFontSizes.push(quoteLayout.fontSize);
  }

  formatQuoteText(text: string, fontSize?: number, containerWidth?: number): TextLayoutResult {
    if (!fontSize || !containerWidth || !this.textLayoutService) {
      const simpleFormatted = TextUtils.applySimpleTextFormatting(text);

      return {
        text: simpleFormatted,
        fontSize: fontSize || 24,
        lines: simpleFormatted.split('\n')
      };
    }

    try {
      console.log(`Starting text layout optimization for: "${text.substring(0, 20)}..."`);
      const result = this.textLayoutService.optimizeLayout(text, containerWidth, fontSize);
      console.log(`Optimization completed. Font size: ${result.fontSize}, Lines: ${result.lines.length}`);
      return result;
    } catch (error) {
      console.error('Advanced text optimization failed, fallback to simple formatting:', error);
      const simpleFormatted = TextUtils.applySimpleTextFormatting(text);

      return {
        text: simpleFormatted,
        fontSize: fontSize,
        lines: simpleFormatted.split('\n')
      };
    }
  }

  async initializeQuoteList(params: QuoteListInitParams): Promise<QuoteListInitResult> {
    try {
      console.log(`=== 初始化名言列表 ===`);
      console.log(`屏幕宽度: ${this.screenWidth}px, 屏幕高度: ${this.screenHeight}px`);

      // 计算Text组件的实际可用宽度
      // Text组件父容器有 .padding(24)，即左右各24px
      // Text组件自身没有额外的padding/margin（除了bottom margin）
      // 安全边距现在根据字体大小动态计算：字体大小 * 4
      const parentPadding = 48; // 左右各24px

      console.log(`屏幕宽度: ${this.screenWidth}px`);
      console.log(`父容器padding: ${parentPadding}px`);

      // 如果没有当前名言，使用推荐系统获取第一个
      if (!params.currentQuote) {
        const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1, this.usedQuoteTexts);
        if (recommendedQuotes && recommendedQuotes.length > 0) {
          params.currentQuote = recommendedQuotes[0];
          this.usedQuoteTexts.add(params.currentQuote.text); // 添加到已使用列表
        } else {
          // 如果推荐系统也失败，使用默认名言
          const defaultQuote: Quote = {
            text: "一切群众的实际生活问题，都是我们应当注意的问题",
            author: "毛泽东",
            category: "群众",
            source: "《关心群众生活，注意工作方法》"
          };
          params.currentQuote = defaultQuote;
        }
      }

      // 先加载当前名言
      params.quoteDataSource.pushItem(params.currentQuote);

      // 如果没有当前壁纸，生成一个
      if (!params.currentWallpaper) {
        params.currentWallpaper = await WallpaperService.generateWallpaper(params.currentQuote);
      }
      params.wallpaperList.push(params.currentWallpaper);

      // 预处理当前名言的字体大小
      const initialFontSize = params.currentWallpaper?.style.fontSize || 24;
      console.log(`使用初始字体大小: ${initialFontSize}px`);

      // 重新计算基于字体大小的安全边距和容器宽度
      const dynamicContainerWidth = this.calculateDynamicContainerWidth(initialFontSize);

      console.log(`动态安全边距: ${initialFontSize * 5}px (基于字体${initialFontSize}px)`);
      console.log(`动态容器宽度: ${dynamicContainerWidth}px`);

      const textLayout = this.formatQuoteText(params.currentQuote.text, initialFontSize, dynamicContainerWidth);
      params.optimizedFontSizes.push(textLayout.fontSize);

      console.log(`=== 当前quote处理完成 ===`);
      console.log(`优化后字体大小: ${textLayout.fontSize}px`);
      console.log(`优化后文本:\n${textLayout.text}`);

      // 预加载更多推荐名言
      console.log(`=== 开始加载推荐名言 ===`);
      const moreQuotes = await QuoteSelectionService.getRecommendedQuotes(10, this.usedQuoteTexts);
      if (moreQuotes && moreQuotes.length > 0) {
        for (const quote of moreQuotes) {
          const processParams: ProcessQuoteParams = {
            quoteDataSource: params.quoteDataSource,
            wallpaperList: params.wallpaperList,
            optimizedFontSizes: params.optimizedFontSizes
          };
          await this.processQuote(quote, processParams);
        }
        console.log(`加载了${moreQuotes.length}条推荐名言`);
      }

      const result: QuoteListInitResult = { quote: params.currentQuote, wallpaper: params.currentWallpaper };
      return result;
    } catch (error) {
      console.error('Failed to initialize quote list:', error);
      const result: QuoteListInitResult = { quote: params.currentQuote, wallpaper: params.currentWallpaper };
      return result;
    }
  }

  // 按需加载更多内容
  async loadMoreIfNeeded(params: LoadMoreParams): Promise<void> {
    const totalCount = params.quoteDataSource.totalCount();

    // 限制最多加载100条内容
    if (totalCount >= 100) {
      console.log('已达到最大加载数量限制(100条)');
      return;
    }

    // 当滚动到倒数第3项时，预加载更多内容
    if (params.currentIndex >= totalCount - 3) {
      try {
        // 计算还能加载多少条，避免超过100条限制
        const remainingCount = 100 - totalCount;
        const loadCount = Math.min(10, remainingCount); // 预加载10条或剩余数量

        for (let i = 0; i < loadCount; i++) {
          const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1, this.usedQuoteTexts);
          if (recommendedQuotes && recommendedQuotes.length > 0) {
            const quote = recommendedQuotes[0];
            const processParams2: ProcessQuoteParams = {
              quoteDataSource: params.quoteDataSource,
              wallpaperList: params.wallpaperList,
              optimizedFontSizes: params.optimizedFontSizes
            };
            await this.processQuote(quote, processParams2);
          }
        }

        console.log(`加载了${loadCount}条内容，当前总数：${params.quoteDataSource.totalCount()}`);
      } catch (error) {
        console.error('Failed to load more quotes:', error);
      }
    }
  }

  // 获取已使用的名言文本集合
  getUsedQuoteTexts(): Set<string> {
    return this.usedQuoteTexts;
  }

  // 添加已使用的名言文本
  addUsedQuoteText(text: string): void {
    this.usedQuoteTexts.add(text);
  }
}