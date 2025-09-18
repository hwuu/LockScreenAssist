// 名言页面业务逻辑服务
import { Quote } from '../common/QuoteData';
import { QuoteSelectionService } from './QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper } from './WallpaperService';
import { TextLayoutService } from './TextLayoutService';
import { TextUtils } from '../common/TextUtils';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { QuoteDataSource } from '../common/QuoteDataSource';
import { QuoteListInitResult } from '../common/ServiceTypes';

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

  // 计算基于字体大小的动态容器宽度
  calculateDynamicContainerWidth(fontSize: number): number {
    const parentPadding = 48; // 左右各24px
    const safetyMargin = fontSize * 5; // 字体大小 * 5
    const rawContainerWidth = this.screenWidth - parentPadding - safetyMargin;
    return Math.max(rawContainerWidth, 200); // 最小宽度200px
  }

  // 处理单个quote的通用方法（添加到数据源、生成壁纸、优化字体）
  async processQuote(quote: Quote, quoteDataSource: QuoteDataSource, wallpaperList: (GeneratedWallpaper | null)[], optimizedFontSizes: number[]): Promise<void> {
    // 添加到数据源和已使用列表
    quoteDataSource.pushItem(quote);
    this.usedQuoteTexts.add(quote.text);

    // 生成壁纸
    const wallpaper = await WallpaperService.generateWallpaper(quote);
    wallpaperList.push(wallpaper);

    // 预处理字体大小
    const quoteFontSize = wallpaper?.style.fontSize || 24;
    const quoteContainerWidth = this.calculateDynamicContainerWidth(quoteFontSize);
    const quoteLayout = this.formatQuoteText(quote.text, quoteFontSize, quoteContainerWidth);
    optimizedFontSizes.push(quoteLayout.fontSize);
  }

  // 智能格式化名言文本，避免孤行和标点符号行首
  formatQuoteText(text: string, fontSize?: number, containerWidth?: number): TextLayoutResult {
    // 如果没有提供参数或服务未初始化，使用简单处理
    if (!fontSize || !containerWidth || !this.textLayoutService) {
      // 降级到原有的简单换行逻辑
      const simpleFormatted = TextUtils.applySimpleTextFormatting(text);

      return {
        text: simpleFormatted,
        fontSize: fontSize || 24,
        lines: simpleFormatted.split('\n')
      };
    }

    // 使用TextLayoutService的智能优化算法
    try {
      console.log(`Starting text layout optimization for: "${text.substring(0, 20)}..."`);
      const result = this.textLayoutService.optimizeLayout(text, containerWidth, fontSize);
      console.log(`Optimization completed. Font size: ${result.fontSize}, Lines: ${result.lines.length}`);
      return result;
    } catch (error) {
      console.error('Advanced text optimization failed, fallback to simple formatting:', error);

      // 出错时降级到简单处理
      const simpleFormatted = TextUtils.applySimpleTextFormatting(text);

      return {
        text: simpleFormatted,
        fontSize: fontSize,
        lines: simpleFormatted.split('\n')
      };
    }
  }

  // 初始化名言列表，参考helper6_page_turn.txt第57-65行
  async initializeQuoteList(
    currentQuote: Quote | null,
    currentWallpaper: GeneratedWallpaper | null,
    quoteDataSource: QuoteDataSource,
    wallpaperList: (GeneratedWallpaper | null)[],
    optimizedFontSizes: number[]
  ): Promise<QuoteListInitResult> {
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
      if (!currentQuote) {
        const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1, this.usedQuoteTexts);
        if (recommendedQuotes && recommendedQuotes.length > 0) {
          currentQuote = recommendedQuotes[0];
          this.usedQuoteTexts.add(currentQuote.text); // 添加到已使用列表
        } else {
          // 如果推荐系统也失败，使用默认名言
          const defaultQuote: Quote = {
            text: "一切群众的实际生活问题，都是我们应当注意的问题",
            author: "毛泽东",
            category: "群众",
            source: "《关心群众生活，注意工作方法》"
          };
          currentQuote = defaultQuote;
        }
      }

      // 先加载当前名言
      quoteDataSource.pushItem(currentQuote);

      // 如果没有当前壁纸，生成一个
      if (!currentWallpaper) {
        currentWallpaper = await WallpaperService.generateWallpaper(currentQuote);
      }
      wallpaperList.push(currentWallpaper);

      // 预处理当前名言的字体大小
      const initialFontSize = currentWallpaper?.style.fontSize || 24;
      console.log(`使用初始字体大小: ${initialFontSize}px`);

      // 重新计算基于字体大小的安全边距和容器宽度
      const dynamicContainerWidth = this.calculateDynamicContainerWidth(initialFontSize);

      console.log(`动态安全边距: ${initialFontSize * 5}px (基于字体${initialFontSize}px)`);
      console.log(`动态容器宽度: ${dynamicContainerWidth}px`);

      const textLayout = this.formatQuoteText(currentQuote.text, initialFontSize, dynamicContainerWidth);
      optimizedFontSizes.push(textLayout.fontSize);

      console.log(`=== 当前quote处理完成 ===`);
      console.log(`优化后字体大小: ${textLayout.fontSize}px`);
      console.log(`优化后文本:\n${textLayout.text}`);

      // 预加载更多推荐名言
      console.log(`=== 开始加载推荐名言 ===`);
      const moreQuotes = await QuoteSelectionService.getRecommendedQuotes(10, this.usedQuoteTexts);
      if (moreQuotes && moreQuotes.length > 0) {
        for (const quote of moreQuotes) {
          await this.processQuote(quote, quoteDataSource, wallpaperList, optimizedFontSizes);
        }
        console.log(`加载了${moreQuotes.length}条推荐名言`);
      }

      const result: QuoteListInitResult = { quote: currentQuote, wallpaper: currentWallpaper };
      return result;
    } catch (error) {
      console.error('Failed to initialize quote list:', error);
      const result: QuoteListInitResult = { quote: currentQuote, wallpaper: currentWallpaper };
      return result;
    }
  }

  // 按需加载更多内容
  async loadMoreIfNeeded(
    currentIndex: number,
    quoteDataSource: QuoteDataSource,
    wallpaperList: (GeneratedWallpaper | null)[],
    optimizedFontSizes: number[]
  ): Promise<void> {
    const totalCount = quoteDataSource.totalCount();

    // 限制最多加载100条内容
    if (totalCount >= 100) {
      console.log('已达到最大加载数量限制(100条)');
      return;
    }

    // 当滚动到倒数第3项时，预加载更多内容
    if (currentIndex >= totalCount - 3) {
      try {
        // 计算还能加载多少条，避免超过100条限制
        const remainingCount = 100 - totalCount;
        const loadCount = Math.min(10, remainingCount); // 预加载5条或剩余数量
        const parentPadding = 48; // 左右各24px padding

        for (let i = 0; i < loadCount; i++) {
          const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1, this.usedQuoteTexts);
          if (recommendedQuotes && recommendedQuotes.length > 0) {
            const quote = recommendedQuotes[0];
            await this.processQuote(quote, quoteDataSource, wallpaperList, optimizedFontSizes);
          }
        }

        console.log(`加载了${loadCount}条内容，当前总数：${quoteDataSource.totalCount()}`);
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