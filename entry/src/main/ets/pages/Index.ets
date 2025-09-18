import { QuoteData, Quote } from '../common/QuoteData';
import { QuoteSelectionService } from '../services/QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper, WallpaperStyle, WallpaperOperationResult } from '../services/WallpaperService';
import router from '@ohos.router';
import { ScheduleConfig, WallpaperConfig } from '../common/ScheduleConfig';
import { TextUtils } from '../common/TextUtils';
import display from '@ohos.display';
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import measure from '@ohos.measure';
// SaveButton is not available in HarmonyOS API, using regular Button instead


// 文本换行结果接口
interface TextLayoutResult {
  text: string;
  fontSize: number;
  lines: string[];
}

// 换行点信息接口
interface BreakPoint {
  line: string;
  nextIndex: number;
}

// 行信息接口
interface LineInfo {
  text: string;
  width: number;
  height: number;
  characterCount: number;
  hasLeadingPunctuation: boolean;
  isOrphan: boolean;
  isAutoWrapped: boolean;
}

// 文本布局度量接口
interface TextLayoutMetrics {
  lines: LineInfo[];
  totalWidth: number;
  totalHeight: number;
  fontSize: number;
  autoWrapCount: number;
  orphanCount: number;
  punctuationViolations: number;
  originalLineCount: number;
}

// 权重配置接口
interface WeightsConfig {
  r1: number;  // 自动换行比例
  r2: number;  // 孤行比例
  r3: number;  // 行宽不均匀度
  r4: number;  // 长宽比偏差
  r5: number;  // 空间利用率
  r6: number;  // 标点位置合规性
  r7: number;  // 视觉密度均匀性
  r9: number;  // 视觉焦点分散度
}

// 字体范围接口
interface FontRange {
  min: number;
  max: number;
}

// 理想行数范围接口
interface IdealLineRange {
  min: number;
  max: number;
}

// 优化配置接口
interface OptimizationConfig {
  weights: WeightsConfig;
  fontRange: FontRange;
  idealLineRange: IdealLineRange;
  maxIterations: number;
}

// 文本布局优化器类
class TextLayoutOptimizer {
  private config: OptimizationConfig;
  private screenWidth: number;
  private screenHeight: number;

  constructor(screenWidth: number, screenHeight: number) {
    this.screenWidth = screenWidth;
    this.screenHeight = screenHeight;

    const weights: WeightsConfig = {
      r1: 0.15,  // 自动换行比例
      r2: 0.35,  // 孤行比例
      r3: 0.05,  // 行宽不均匀度
      r4: 0.05,  // 长宽比偏差
      r5: 0.15,  // 空间利用率
      r6: 0.1,   // 标点位置合规性
      r7: 0.125, // 视觉密度均匀性
      r9: 0.025  // 视觉焦点分散度
    };

    const fontRange: FontRange = { min: 14, max: 40 };
    const idealLineRange: IdealLineRange = { min: 5, max: 12 };

    this.config = {
      weights: weights,
      fontRange: fontRange,
      idealLineRange: idealLineRange,
      maxIterations: 50
    };
  }

  // 主要优化方法
  optimizeLayout(text: string, containerWidth: number, baseFontSize: number): TextLayoutResult {
    let bestScore = Infinity;
    let bestResult: TextLayoutResult | null = null;

    // 两阶段搜索：粗搜索 + 细搜索
    const coarseRange = this.getCoarseSearchRange(baseFontSize);
    let coarseBest = this.searchOptimalFontSize(text, containerWidth, coarseRange.min, coarseRange.max, 2);

    // 在最佳区间进行细搜索
    const fineRange: FontRange = {
      min: Math.max(this.config.fontRange.min, coarseBest.fontSize - 4),
      max: Math.min(this.config.fontRange.max, coarseBest.fontSize + 4)
    };
    let fineBest = this.searchOptimalFontSize(text, containerWidth, fineRange.min, fineRange.max, 0.5);

    return fineBest;
  }

  // 搜索最佳字体大小
  private searchOptimalFontSize(text: string, containerWidth: number, minSize: number, maxSize: number, step: number): TextLayoutResult {
    let bestScore = Infinity;
    let bestResult: TextLayoutResult | null = null;

    console.log(`=== 开始搜索最佳字体大小 ===`);
    console.log(`文本: "${text}"`);
    console.log(`容器宽度: ${containerWidth}px`);
    console.log(`字体范围: ${minSize}px - ${maxSize}px, 步长: ${step}px`);

    for (let fontSize = minSize; fontSize <= maxSize; fontSize += step) {
      const metrics = this.measureText(text, fontSize, containerWidth);
      const score = this.calculateScore(metrics);

      const r1 = this.calculateR1(metrics);
      const r2 = this.calculateR2(metrics);
      const r3 = this.calculateR3(metrics);
      const r4 = this.calculateR4(metrics);
      const r5 = this.calculateR5(metrics);
      const r6 = this.calculateR6(metrics);
      const r7 = this.calculateR7(metrics);
      const r9 = this.calculateR9(metrics);

      console.log(`--- 字体大小 ${fontSize}px ---`);
      console.log(`总行数: ${metrics.lines.length}`);
      console.log(`孤行数: ${metrics.orphanCount}`);
      console.log(`自动换行数: ${metrics.autoWrapCount}`);
      console.log(`标点违规数: ${metrics.punctuationViolations}`);
      console.log(`文本区域: ${metrics.totalWidth.toFixed(0)}x${metrics.totalHeight.toFixed(0)}px`);
      console.log(`各指标评分:`);
      console.log(`  r1(自动换行): ${r1.toFixed(4)} * ${this.config.weights.r1} = ${(r1 * this.config.weights.r1).toFixed(4)}`);
      console.log(`  r2(孤行): ${r2.toFixed(4)} * ${this.config.weights.r2} = ${(r2 * this.config.weights.r2).toFixed(4)}`);
      console.log(`  r3(行宽不均): ${r3.toFixed(4)} * ${this.config.weights.r3} = ${(r3 * this.config.weights.r3).toFixed(4)}`);
      console.log(`  r4(长宽比): ${r4.toFixed(4)} * ${this.config.weights.r4} = ${(r4 * this.config.weights.r4).toFixed(4)}`);
      console.log(`  r5(空间利用): ${r5.toFixed(4)} * ${this.config.weights.r5} = ${(r5 * this.config.weights.r5).toFixed(4)}`);
      console.log(`  r6(标点位置): ${r6.toFixed(4)} * ${this.config.weights.r6} = ${(r6 * this.config.weights.r6).toFixed(4)}`);
      console.log(`  r7(密度均匀): ${r7.toFixed(4)} * ${this.config.weights.r7} = ${(r7 * this.config.weights.r7).toFixed(4)}`);
      console.log(`  r9(焦点分散): ${r9.toFixed(4)} * ${this.config.weights.r9} = ${(r9 * this.config.weights.r9).toFixed(4)}`);
      console.log(`综合评分: ${score.toFixed(4)}`);

      // 输出每行的详细信息
      metrics.lines.forEach((line: LineInfo, index: number) => {
        console.log(`行${index + 1}: "${line.text}" (宽度:${line.width.toFixed(1)}px, 字符数:${line.characterCount}, 孤行:${line.isOrphan}, 自动换行:${line.isAutoWrapped})`);
      });

      if (score < bestScore) {
        bestScore = score;
        bestResult = {
          text: metrics.lines.map(line => line.text).join('\n'),
          fontSize: fontSize,
          lines: metrics.lines.map(line => line.text)
        };

        console.log(`✓ 新的最佳结果! 字体大小: ${fontSize}px, 评分: ${score.toFixed(4)}`);
      }
    }

    console.log(`=== 搜索完成 ===`);
    if (bestResult) {
      // 为了进一步确保能消除孤行，将 fontSize 减小一点。
      if (bestResult.fontSize > minSize) {
        bestResult.fontSize -= 1;
      }
      console.log(`最终结果 - 字体大小: ${bestResult.fontSize}px, 行数: ${bestResult.lines.length}`);
      console.log(`最终文本:\n${bestResult.text}`);
    }

    return bestResult || {
      text: text,
      fontSize: minSize,
      lines: [text]
    };
  }

  // 获取粗搜索范围
  private getCoarseSearchRange(baseFontSize: number): FontRange {
    const range = 8; // 基准字体大小上下8px
    const result: FontRange = {
      min: Math.max(this.config.fontRange.min, baseFontSize - range),
      max: Math.min(this.config.fontRange.max, baseFontSize + range)
    };
    return result;
  }

  // 计算综合评分
  private calculateScore(metrics: TextLayoutMetrics): number {
    const r1 = this.calculateR1(metrics);
    const r2 = this.calculateR2(metrics);
    const r3 = this.calculateR3(metrics);
    const r4 = this.calculateR4(metrics);
    const r5 = this.calculateR5(metrics);
    const r6 = this.calculateR6(metrics);
    const r7 = this.calculateR7(metrics);
    const r9 = this.calculateR9(metrics);

    return this.config.weights.r1 * r1 +
           this.config.weights.r2 * r2 +
           this.config.weights.r3 * r3 +
           this.config.weights.r4 * r4 +
           this.config.weights.r5 * r5 +
           this.config.weights.r6 * r6 +
           this.config.weights.r7 * r7 +
           this.config.weights.r9 * r9;
  }

  // 核心文本测量方法
  private measureText(text: string, fontSize: number, containerWidth: number): TextLayoutMetrics {
    console.log(`>>> measureText开始: 字体${fontSize}px, 容器宽度${containerWidth}px`);
    console.log(`原始文本: "${text}"`);

    // 1. 首先应用强制标点换行逻辑，获取原始行数
    const punctuationFormatted = TextUtils.applySimpleTextFormatting(text);

    console.log(`标点换行后: "${punctuationFormatted}"`);

    const originalLines: string[] = punctuationFormatted.split('\n').filter((line: string) => line.trim().length > 0);
    const originalLineCount: number = originalLines.length;

    console.log(`原始行数: ${originalLineCount}`);
    originalLines.forEach((line: string, index: number) => {
      console.log(`原始行${index + 1}: "${line}"`);
    });

    // 2. 对每一行进行智能换行处理
    let allLines: LineInfo[] = [];
    let autoWrapCount = 0;
    let maxWidth = 0;
    let totalHeight = 0;

    for (let i = 0; i < originalLines.length; i++) {
      const originalLine: string = originalLines[i];
      if (originalLine.trim().length === 0) continue;

      // 测量这一行在容器宽度下的换行情况
      const wrappedLines = this.wrapSingleLine(originalLine, fontSize, containerWidth);

      for (let j = 0; j < wrappedLines.length; j++) {
        const lineText: string = wrappedLines[j];
        const lineWidth: number = TextUtils.measureTextWidthCore(lineText, fontSize);
        const lineHeight: number = fontSize * 1.2; // 行高系数

        const lineInfo: LineInfo = {
          text: lineText,
          width: lineWidth,
          height: lineHeight,
          characterCount: lineText.length,
          hasLeadingPunctuation: this.hasLeadingPunctuation(lineText),
          isOrphan: this.isOrphanLine(lineText),
          isAutoWrapped: j > 0 // 除了第一行，其他都是自动换行产生的
        };

        allLines.push(lineInfo);
        maxWidth = Math.max(maxWidth, lineWidth);
        totalHeight += lineHeight;

        // 统计自动换行数量
        if (j > 0) {
          autoWrapCount++;
        }
      }
    }

    // 3. 统计各种指标
    const orphanCount = allLines.filter(line => line.isOrphan).length;
    const punctuationViolations = allLines.filter(line => line.hasLeadingPunctuation).length;

    return {
      lines: allLines,
      totalWidth: maxWidth,
      totalHeight: totalHeight,
      fontSize: fontSize,
      autoWrapCount: autoWrapCount,
      orphanCount: orphanCount,
      punctuationViolations: punctuationViolations,
      originalLineCount: originalLineCount
    };
  }

  // 对单行文本进行智能换行
  private wrapSingleLine(text: string, fontSize: number, maxWidth: number): string[] {
    if (!text || text.trim().length === 0) return [];

    console.log(`>>> wrapSingleLine开始: "${text}", 字体${fontSize}px, 最大宽度${maxWidth}px`);

    const lines: string[] = [];
    let currentLine = '';
    let i = 0;

    // 标点符号规则
    const punctuationAtStart = new RegExp('^' + TextUtils.AT_START.source);
    const punctuationAtEnd = new RegExp(TextUtils.AT_END.source + '$');

    while (i < text.length) {
      const char = text[i];
      const testLine = currentLine + char;
      const lineWidth = TextUtils.measureTextWidthCore(testLine, fontSize);

      console.log(`字符'${char}': 测试行"${testLine}" 宽度${lineWidth.toFixed(1)}px, 最大宽度${maxWidth}px`);

      if (lineWidth > maxWidth && currentLine.length > 0) {
        console.log(`需要换行! 当前行"${currentLine}" 宽度超限`);
        // 需要换行，检查换行规则
        const breakResult = this.findOptimalBreakPointNew(
          text, currentLine, i, fontSize, maxWidth
        );

        lines.push(breakResult.line);
        console.log(`添加行: "${breakResult.line}"`);
        currentLine = '';
        i = breakResult.nextIndex;
        continue;
      }

      currentLine += char;
      i++;
    }

    if (currentLine.length > 0) {
      lines.push(currentLine);
      console.log(`添加最后一行: "${currentLine}"`);
    }

    console.log(`<<< wrapSingleLine完成: 总共${lines.length}行`);
    return lines.length > 0 ? lines : [text];
  }

  // 新的寻找最佳换行点方法
  private findOptimalBreakPointNew(
    fullText: string,
    currentLine: string,
    currentIndex: number,
    fontSize: number,
    maxWidth: number
  ): BreakPoint {
    const nextChar = fullText[currentIndex] || '';
    const punctuationAtStart = TextUtils.AT_START;
    const punctuationAtEnd = TextUtils.AT_END;

    if (punctuationAtStart.test(nextChar)) {
      const testLine = currentLine + nextChar;
      const totalWidth = TextUtils.measureTextWidthCore(testLine, fontSize);

      if (totalWidth <= maxWidth) {
        return {
          line: testLine,
          nextIndex: currentIndex + 1
        };
      } else {
        return this.findPreviousBreakPointNew(currentLine, currentIndex, fontSize, maxWidth);
      }
    }

    const lastChar = currentLine[currentLine.length - 1] || '';
    if (punctuationAtEnd.test(lastChar)) {
      return this.findPreviousBreakPointNew(currentLine, currentIndex, fontSize, maxWidth);
    }

    return {
      line: currentLine,
      nextIndex: currentIndex
    };
  }

  // 新的向前回退寻找断点方法
  private findPreviousBreakPointNew(
    currentLine: string,
    currentIndex: number,
    fontSize: number,
    maxWidth: number
  ): BreakPoint {
    for (let i = currentLine.length - 1; i > 0; i--) {
      const truncatedLine = currentLine.substring(0, i);
      const char = currentLine[i];

      const punctuationAtEnd = TextUtils.AT_END;
      const punctuationAtStart = TextUtils.AT_START;

      if (!punctuationAtEnd.test(truncatedLine[truncatedLine.length - 1] || '') &&
          !punctuationAtStart.test(char)) {

        const truncatedWidth = TextUtils.measureTextWidthCore(truncatedLine, fontSize);

        if (truncatedWidth <= maxWidth) {
          return {
            line: truncatedLine,
            nextIndex: currentIndex - (currentLine.length - i)
          };
        }
      }
    }

    return {
      line: currentLine,
      nextIndex: currentIndex
    };
  }

  // 检查是否有行首标点
  private hasLeadingPunctuation(line: string): boolean {
    return TextUtils.isStartPunctuation(line.charAt(0));
  }

  // 检查是否为孤行
  private isOrphanLine(line: string): boolean {
    const effectiveLength = line.replace(/[，。！？；：、（）【】「」『』《》\"'\"'…]/g, '').length;
    const isOrphan = effectiveLength > 0 && effectiveLength < 3;
    if (isOrphan) {
      console.log(`检测到孤行: "${line}" (有效字符数: ${effectiveLength})`);
    }
    return isOrphan;
  }

  // r1: 自动换行比例 = (自动换行数 + 原始换行数) / 渲染后总行数
  private calculateR1(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length === 0) return 0;
    return (metrics.autoWrapCount + metrics.originalLineCount) / metrics.lines.length;
  }

  // r2: 孤行比例 = 孤行数量 / 渲染后总行数
  private calculateR2(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length === 0) return 0;
    return metrics.orphanCount / metrics.lines.length;
  }

  // r6: 标点符号位置合规性 = 行首标点数量 / 总行数
  private calculateR6(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length === 0) return 0;
    return metrics.punctuationViolations / metrics.lines.length;
  }

  // r7: 视觉密度均匀性 = 各行字符密度方差 / 平均字符密度
  private calculateR7(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length <= 1) return 0;

    // 计算每行的字符密度（字符数/行宽度）
    const densities: number[] = [];
    for (const line of metrics.lines) {
      if (line.width > 0) {
        densities.push(line.characterCount / line.width);
      }
    }

    if (densities.length <= 1) return 0;

    // 计算平均密度
    const meanDensity = densities.reduce((sum, d) => sum + d, 0) / densities.length;
    if (meanDensity === 0) return 0;

    // 计算方差
    const variance = densities.reduce((sum, d) => sum + Math.pow(d - meanDensity, 2), 0) / densities.length;

    return variance / meanDensity;
  }

  // r3: 行宽不均匀度 = 1 - (最短行宽度 / 最宽行宽度)
  private calculateR3(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length <= 1) return 0;

    let minWidth = Infinity;
    let maxWidth = 0;

    for (const line of metrics.lines) {
      if (line.width > 0) {
        minWidth = Math.min(minWidth, line.width);
        maxWidth = Math.max(maxWidth, line.width);
      }
    }

    if (maxWidth === 0 || minWidth === Infinity) return 0;
    return 1 - (minWidth / maxWidth);
  }

  // r4: 长宽比偏差 = abs(渲染后文本区域长宽比 - 屏幕长宽比) / 屏幕长宽比
  private calculateR4(metrics: TextLayoutMetrics): number {
    if (metrics.totalWidth === 0 || metrics.totalHeight === 0 || this.screenWidth === 0 || this.screenHeight === 0) return 0;

    // 计算文本区域长宽比（高/宽）
    const textAspectRatio = metrics.totalHeight / metrics.totalWidth;

    // 计算屏幕长宽比（高/宽）
    const screenAspectRatio = this.screenHeight / this.screenWidth;

    if (screenAspectRatio === 0) return 0;
    return Math.abs(textAspectRatio - screenAspectRatio) / screenAspectRatio;
  }

  // r5: 空间利用率 = (屏幕面积 - 渲染后文本区域面积) / 屏幕面积
  private calculateR5(metrics: TextLayoutMetrics): number {
    if (this.screenWidth === 0 || this.screenHeight === 0) return 0;

    const screenArea = this.screenWidth * this.screenHeight;
    const textArea = metrics.totalWidth * metrics.totalHeight;

    return (screenArea - textArea) / screenArea;
  }

  // r9: 视觉焦点分散度 = |理想行数 - 实际行数| / 理想行数
  private calculateR9(metrics: TextLayoutMetrics): number {
    const actualLines = metrics.lines.length;
    const idealLines = (this.config.idealLineRange.min + this.config.idealLineRange.max) / 2;

    if (idealLines === 0) return 0;
    return Math.abs(idealLines - actualLines) / idealLines;
  }

}

// 数据源类实现，参考helper6_page_turn.txt第68-74行
class QuoteDataSource implements IDataSource {
  private quotes: Quote[] = [];
  private listeners: DataChangeListener[] = [];

  public totalCount(): number {
    return this.quotes.length;
  }

  public getData(index: number): Quote {
    return this.quotes[index];
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  public pushItem(quote: Quote): void {
    this.quotes.push(quote);
    this.notifyDataAdd(this.quotes.length - 1);
  }

  public addItem(quote: Quote): void {
    this.quotes.unshift(quote);
    this.notifyDataAdd(0);
  }

  private notifyDataAdd(index: number): void {
    this.listeners.forEach((listener: DataChangeListener) => {
      listener.onDataAdd(index);
    });
  }
}

@Entry
@Component
struct Index {
  @State currentQuote: Quote | null = null;
  @State currentWallpaper: GeneratedWallpaper | null = null;
  @State isLoading: boolean = false;
  @State previewBackground: string = '';
  @State previewMode: 'current' | 'recommended' = 'current';
  @State recommendedQuote: Quote | null = null;
  @State recommendedWallpaper: GeneratedWallpaper | null = null;
  @State usedRecommendations: Set<string> = new Set();

  @State config: WallpaperConfig | null = null;
  @State showSaveDialog: boolean = false;
  @State screenRatio: number = 16/9; // 默认比例
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State setLockScreen: boolean = false; // 官方已不支持该功能
  @State saveToGallery: boolean = true; // 默认选中保存到图库
  @State isApplying: boolean = false; // 应用壁纸的状态
  @State hintOpacity: number = 0; // 提示文字透明度
  @State contentOpacity: number = 1; // 内容区域透明度
  @State isTransitioning: boolean = false; // 是否在过渡动画中
  private hintTimer: number = -1; // 提示文字定时器
  private debounceTimer: number = -1; // 防抖定时器
  private blinkTimer: number = -1; // 闪烁动画定时器
  @State isBlinking: boolean = false; // 是否正在闪烁

  // 上下翻页相关状态
  @State currentPageIndex: number = 0;
  @State quoteDataSource: QuoteDataSource = new QuoteDataSource();
  @State wallpaperList: (GeneratedWallpaper | null)[] = [];
  @State optimizedFontSizes: number[] = []; // 存储每页优化后的字体大小
  private textLayoutOptimizer: TextLayoutOptimizer | null = null; // 文本布局优化器
  private usedQuoteTexts: Set<string> = new Set(); // 已使用的quote文本集合，用于去重

  // 计算基于字体大小的动态容器宽度
  private calculateDynamicContainerWidth(fontSize: number): number {
    const parentPadding = 48; // 左右各24px
    const safetyMargin = fontSize * 5; // 字体大小 * 5
    const rawContainerWidth = this.screenWidth - parentPadding - safetyMargin;
    return Math.max(rawContainerWidth, 200); // 最小宽度200px
  }

  // 处理单个quote的通用方法（添加到数据源、生成壁纸、优化字体）
  private async processQuote(quote: Quote): Promise<void> {
    // 添加到数据源和已使用列表
    this.quoteDataSource.pushItem(quote);
    this.usedQuoteTexts.add(quote.text);

    // 生成壁纸
    const wallpaper = await WallpaperService.generateWallpaper(quote);
    this.wallpaperList.push(wallpaper);

    // 预处理字体大小
    const quoteFontSize = wallpaper?.style.fontSize || 24;
    const quoteContainerWidth = this.calculateDynamicContainerWidth(quoteFontSize);
    const quoteLayout = this.formatQuoteText(quote.text, quoteFontSize, quoteContainerWidth);
    this.optimizedFontSizes.push(quoteLayout.fontSize);
  }








  async aboutToAppear() {
    // 确保屏幕尺寸首先被正确获取
    await this.getScreenRatio();

    // 验证屏幕尺寸获取是否成功
    console.log(`aboutToAppear - 屏幕尺寸确认: ${this.screenWidth}x${this.screenHeight}`);

    // 如果屏幕尺寸获取失败，使用默认值
    if (this.screenWidth === 0 || this.screenHeight === 0) {
      console.warn('屏幕尺寸获取失败，使用默认值');
      this.screenWidth = 360;
      this.screenHeight = 640;
    }

    // 初始化文本布局优化器
    this.textLayoutOptimizer = new TextLayoutOptimizer(this.screenWidth, this.screenHeight);

    await this.loadConfig();
    await this.loadQuoteSource();
    await this.initializeQuoteList();
    await this.updatePreview();
    await this.updateBackgroundForCurrentPage(this.currentPageIndex); // 初始化背景
    this.startHintTimer();
  }

  // 初始化名言列表，参考helper6_page_turn.txt第57-65行
  async initializeQuoteList() {
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

      // 加载当前壁纸
      await this.loadCurrentWallpaper();

      // 如果没有当前名言，使用推荐系统获取第一个
      if (!this.currentQuote) {
        const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1, this.usedQuoteTexts);
        if (recommendedQuotes && recommendedQuotes.length > 0) {
          this.currentQuote = recommendedQuotes[0];
          this.usedQuoteTexts.add(this.currentQuote.text); // 添加到已使用列表
        } else {
          // 如果推荐系统也失败，使用默认名言
          this.currentQuote = {
            text: "一切群众的实际生活问题，都是我们应当注意的问题",
            author: "毛泽东",
            category: "群众",
            source: "《关心群众生活，注意工作方法》"
          };
        }
      }

      // 先加载当前名言
      this.quoteDataSource.pushItem(this.currentQuote);

      // 如果没有当前壁纸，生成一个
      if (!this.currentWallpaper) {
        this.currentWallpaper = await WallpaperService.generateWallpaper(this.currentQuote);
      }
      this.wallpaperList.push(this.currentWallpaper);

      // 预处理当前名言的字体大小
      const initialFontSize = this.currentWallpaper?.style.fontSize || 24;
      console.log(`使用初始字体大小: ${initialFontSize}px`);

      // 重新计算基于字体大小的安全边距和容器宽度
      const dynamicContainerWidth = this.calculateDynamicContainerWidth(initialFontSize);

      console.log(`动态安全边距: ${initialFontSize * 5}px (基于字体${initialFontSize}px)`);
      console.log(`动态容器宽度: ${dynamicContainerWidth}px`);

      const textLayout = this.formatQuoteText(this.currentQuote.text, initialFontSize, dynamicContainerWidth);
      this.optimizedFontSizes.push(textLayout.fontSize);

      console.log(`=== 当前quote处理完成 ===`);
      console.log(`优化后字体大小: ${textLayout.fontSize}px`);
      console.log(`优化后文本:\n${textLayout.text}`);

      // 预加载更多推荐名言
      console.log(`=== 开始加载推荐名言 ===`);
      const moreQuotes = await QuoteSelectionService.getRecommendedQuotes(10, this.usedQuoteTexts);
      if (moreQuotes && moreQuotes.length > 0) {
        for (const quote of moreQuotes) {
          await this.processQuote(quote);
        }
        console.log(`加载了${moreQuotes.length}条推荐名言`);
      }
    } catch (error) {
      console.error('Failed to initialize quote list:', error);
    }
  }

  async loadQuoteSource() {
    try {
      const QuoteDataModule = await import('../common/QuoteData');
      await QuoteDataModule.QuoteData.loadQuoteSource();
    } catch (error) {
      console.error('Failed to load quote source in Index:', error);
    }
  }

  // 启动提示文字定时器
  startHintTimer() {
    this.clearHintTimer();
    this.hintTimer = setTimeout(() => {
      this.showHint();
    }, 4000);
  }

  // 清除提示文字定时器
  clearHintTimer() {
    if (this.hintTimer !== -1) {
      clearTimeout(this.hintTimer);
      this.hintTimer = -1;
    }
  }

  // 清除闪烁定时器
  clearBlinkTimer() {
    if (this.blinkTimer !== -1) {
      clearTimeout(this.blinkTimer);
      this.blinkTimer = -1;
    }
  }

  // 显示提示文字
  showHint() {
    animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      onFinish: () => {
        // 渐入动画完成后开始闪烁效果
        this.startBlinkEffect();
      }
    }, () => {
      this.hintOpacity = 0.8;
    });
  }

  // 开始闪烁效果
  startBlinkEffect() {
    // 移除透明度检查，因为呼吸循环会改变透明度
    this.isBlinking = true;
    this.blinkCycle();
  }

  // 呼吸循环（模仿人类平静呼吸）
  blinkCycle() {
    if (!this.isBlinking) {
      // 如果不在闪烁状态，停止呼吸
      return;
    }

    // 第一阶段：静止等待2秒（呼吸间隙）
    this.blinkTimer = setTimeout(() => {
      if (!this.isBlinking) return;

      // 第二阶段：缓慢"呼气"3秒
      animateTo({
        duration: 3000,
        curve: Curve.EaseInOut, // 平缓的缓动曲线，模仿自然呼吸
        onFinish: () => {
          // 呼气动画完成后，开始底部停顿
          if (!this.isBlinking) return;

          // 第三阶段：底部停顿5秒
          setTimeout(() => {
            if (!this.isBlinking) return;

            // 第四阶段：缓慢"吸气"2.5秒，从0.1恢复到0.8
            animateTo({
              duration: 2500,
              curve: Curve.EaseInOut,
              onFinish: () => {
                // 完成一轮呼吸后继续下一轮
                if (this.isBlinking) {
                  this.blinkCycle();
                }
              }
            }, () => {
              this.hintOpacity = 0.8;
            });
          }, 500); // 底部停顿0.5秒
        }
      }, () => {
        this.hintOpacity = 0.1;
      });
    }, 2000); // 初始静止2秒
  }

  // 停止闪烁效果
  stopBlinkEffect() {
    this.isBlinking = false;
    this.clearBlinkTimer();
  }

  // 隐藏提示文字
  hideHint() {
    // 停止闪烁效果
    this.stopBlinkEffect();

    // 只有在当前显示状态下才执行隐藏动画
    if (this.hintOpacity > 0) {
      // 添加短暂延迟，确保呼吸动画完全停止
      setTimeout(() => {
        animateTo({
          duration: 1000,
          curve: Curve.EaseInOut
        }, () => {
          this.hintOpacity = 0;
        });
      }, 50); // 50ms延迟确保状态同步
    }
  }

  // 重置提示文字定时器（带防抖）
  resetHintTimer() {
    // 停止闪烁效果
    this.stopBlinkEffect();

    // 清除防抖定时器
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer);
    }

    // 设置防抖，200ms内的连续操作只执行最后一次
    this.debounceTimer = setTimeout(() => {
      // 立即清除定时器，避免重复触发
      this.clearHintTimer();
      // 只有在显示状态下才执行隐藏动画
      this.hideHint();
      // 重新启动定时器
      this.startHintTimer();
      this.debounceTimer = -1;
    }, 200);
  }

  async getScreenRatio() {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      // 计算竖屏比例（高度/宽度）
      this.screenRatio = defaultDisplay.height / defaultDisplay.width;
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
      console.log(`Screen ratio: ${this.screenRatio} (${defaultDisplay.width}x${defaultDisplay.height})`);
    } catch (error) {
      console.error('Failed to get screen ratio:', error);
      this.screenRatio = 16/9; // 保持默认比例
      this.screenWidth = 360;
      this.screenHeight = 640;
    }
  }

  async loadConfig() {
    try {
      this.config = await ScheduleConfig.getConfig();
    } catch (error) {
      console.error('Failed to load config:', error);
    }
  }

  async loadCurrentWallpaper() {
    this.currentWallpaper = await WallpaperService.getCurrentWallpaper();
    if (!this.currentWallpaper && this.config) {
      try {
        const selectedQuote = await QuoteSelectionService.selectQuote(this.config.selectionAlgorithm);
        this.currentQuote = selectedQuote;
        this.currentWallpaper = await WallpaperService.generateWallpaper(selectedQuote);
      } catch (error) {
        console.error('Failed to load initial wallpaper:', error);
      }
    }
  }

  // 获取当前页面的名言和壁纸
  getCurrentQuote(): Quote | null {
    if (this.quoteDataSource.totalCount() > this.currentPageIndex) {
      return this.quoteDataSource.getData(this.currentPageIndex);
    }
    return this.currentQuote;
  }

  getCurrentWallpaper(): GeneratedWallpaper | null {
    if (this.wallpaperList.length > this.currentPageIndex) {
      return this.wallpaperList[this.currentPageIndex];
    }
    return this.currentWallpaper;
  }


  async updatePreview() {
    try {
      // 设置过渡状态，禁用手势响应
      this.isTransitioning = true;

      let newBackground = '#2c3e50';
      const currentWallpaper = this.getCurrentWallpaper();

      if (currentWallpaper) {
        const previewResult = WallpaperService.createWallpaperPreview(currentWallpaper);
        if (previewResult) {
          newBackground = previewResult;
        } else {
          newBackground = currentWallpaper.style.backgroundColor || '#2c3e50';
        }
      }

      // 内容淡出 -> 更新背景和内容 -> 内容淡入
      // 第一阶段：内容淡出
      animateTo({
        duration: 250,
        curve: Curve.EaseInOut
      }, () => {
        this.contentOpacity = 0;
      });

      // 第二阶段：更新背景，然后内容淡入
      setTimeout(() => {
        animateTo({
          duration: 250,
          curve: Curve.EaseInOut
        }, () => {
          this.previewBackground = newBackground;
          this.contentOpacity = 1;
        });

        // 动画完成后恢复手势响应
        setTimeout(() => {
          this.isTransitioning = false;
        }, 250);
      }, 250);

      setTimeout(() => {
        console.log('Preview updated:', this.previewBackground);
      }, 0);
    } catch (error) {
      console.error('Failed to update preview:', error);
      animateTo({
        duration: 500,
        curve: Curve.EaseInOut
      }, () => {
        this.previewBackground = '#2c3e50';
        this.contentOpacity = 1;
      });

      // 错误情况下也要恢复手势响应
      setTimeout(() => {
        this.isTransitioning = false;
      }, 500);
    }
  }

  // 页面滚动时的回调，参考helper6_page_turn.txt第101-103行
  onScrollIndex(firstIndex: number) {
    this.currentPageIndex = firstIndex;
    console.log('Current page index:', this.currentPageIndex);
    // 异步加载更多内容
    this.loadMoreIfNeeded(firstIndex);
  }

  // 按需加载更多内容
  async loadMoreIfNeeded(currentIndex: number) {
    const totalCount = this.quoteDataSource.totalCount();

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
            await this.processQuote(quote);
          }
        }

        console.log(`加载了${loadCount}条内容，当前总数：${this.quoteDataSource.totalCount()}`);
      } catch (error) {
        console.error('Failed to load more quotes:', error);
      }
    }
  }

  // 更新当前页面的背景颜色
  async updateBackgroundForCurrentPage(index: number) {
    try {
      let newBackground = '#2c3e50';

      if (this.wallpaperList.length > index && this.wallpaperList[index] !== null) {
        const wallpaper = this.wallpaperList[index];
        if (wallpaper) {
          const previewResult = WallpaperService.createWallpaperPreview(wallpaper);
          if (previewResult) {
            newBackground = previewResult;
          } else {
            newBackground = wallpaper.style.backgroundColor || '#2c3e50';
          }
        }
      }

      // 使用动画更新背景
      animateTo({
        duration: 300,
        curve: Curve.EaseInOut
      }, () => {
        this.previewBackground = newBackground;
      });

      console.log('Background updated for page:', index, newBackground);
    } catch (error) {
      console.error('Failed to update background for current page:', error);
    }
  }


  async applyWallpaperOptions() {
    if (!this.setLockScreen && !this.saveToGallery) {
      this.showSaveDialog = false;
      return;
    }

    this.isApplying = true;

    try {
      console.log('开始应用壁纸操作...');

      // 使用componentSnapshot API截图纯净壁纸区域
      componentSnapshot.get("pureWallpaperArea", async (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          console.error("截图失败: " + JSON.stringify(error));
          this.isApplying = false;
          this.showSaveDialog = false;
          return;
        }

        try {
          // 将PixelMap保存为JPEG格式
          const packOpts: image.PackingOption = {
            format: "image/jpeg",
            quality: 98
          };

          const imagePacker: image.ImagePacker = image.createImagePacker();
          const arrayBuffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

          // 创建临时文件
          const context = getContext(this) as common.UIAbilityContext;
          const filesDir: string = context.filesDir;
          const tempImagePath = `${filesDir}/temp_wallpaper_${Date.now()}.jpg`;

          // 保存临时文件
          const file = await fs.open(tempImagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
          await fs.write(file.fd, arrayBuffer);
          await fs.close(file.fd);

          // 执行选定的操作
          const results = await WallpaperService.applyWallpaperOperations(
            tempImagePath,
            this.setLockScreen,
            this.saveToGallery
          );

          // 显示结果
          let message = '';
          if (this.setLockScreen && results.lockScreenSuccess) {
            message += '锁屏壁纸设置成功！';
          } else if (this.setLockScreen && !results.lockScreenSuccess) {
            message += '锁屏壁纸设置失败！';
          }

          if (this.saveToGallery && results.gallerySuccess) {
            if (message) message += '\n';
            message += '图片已保存到图库！';
          } else if (this.saveToGallery && !results.gallerySuccess) {
            if (message) message += '\n';
            message += '图片保存到图库失败！';
          }

          console.log('壁纸操作完成:', message);

          // 清理临时文件
          try {
            await fs.unlink(tempImagePath);
          } catch (unlinkError) {
            console.error('清理临时文件失败:', unlinkError);
          }

          // 释放资源
          imagePacker.release();
          pixelMap.release();

        } catch (packError) {
          console.error('图片处理失败:', packError);
          pixelMap.release();
        } finally {
          this.isApplying = false;
          this.showSaveDialog = false;
        }
      });

    } catch (error) {
      console.error('应用壁纸失败:', error);
      this.isApplying = false;
      this.showSaveDialog = false;
    }
  }

  /**
   * 智能格式化名言文本，避免孤行和标点符号行首
   * @param text 原始文本
   * @param fontSize 字体大小
   * @param containerWidth 容器宽度
   * @returns 格式化后的文本布局结果
   */
  formatQuoteText(text: string, fontSize?: number, containerWidth?: number): TextLayoutResult {
    // 如果没有提供参数或优化器未初始化，使用简单处理
    if (!fontSize || !containerWidth || !this.textLayoutOptimizer) {
      // 降级到原有的简单换行逻辑
      const simpleFormatted = TextUtils.applySimpleTextFormatting(text);

      return {
        text: simpleFormatted,
        fontSize: fontSize || 24,
        lines: simpleFormatted.split('\n')
      };
    }

    // 使用TextLayoutOptimizer的智能优化算法
    try {
      console.log(`Starting text layout optimization for: "${text.substring(0, 20)}..."`);
      const result = this.textLayoutOptimizer.optimizeLayout(text, containerWidth, fontSize);
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

  async saveImageToPhoto(buffer: ArrayBuffer): Promise<void> {
    // 按照 _helper.txt 第86-94行的方法实现
    const context = getContext(this) as common.UIAbilityContext;
    const helper = photoAccessHelper.getPhotoAccessHelper(context);
    const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
    const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    await fs.write(file.fd, buffer);
    await fs.close(file.fd);
    console.log("图片保存成功到相册:", uri);
  }

  build() {
    // 全屏预览区域
    Stack() {
      // 背景预览区域（填满整个屏幕）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.previewBackground || '#667eea')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      // 上下翻页的名言文本层，使用Swiper实现分页效果，参考helper6_page_turn.txt第38-54行
      Swiper() {
        LazyForEach(this.quoteDataSource, (quote: Quote, index: number) => {
          Column() {
            Text(this.formatQuoteText(quote.text).text)
              .fontSize(this.optimizedFontSizes[index] || (this.wallpaperList[index]?.style.fontSize) || 24)
              .fontColor((this.wallpaperList[index]?.style.textColor) || '#d3d3d3')
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ bottom: 40 })
              .maxLines(20)
              .textOverflow({ overflow: TextOverflow.None })

            Text(`—— ${quote.author || ''}${(quote.author && quote.source) ? ' · ' : ''}${quote.source || ''}`)
              .fontSize(12)
              .fontColor((this.wallpaperList[index]?.style.textColor) || '#d3d3d3')
              .opacity(0.8)
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding(24)
          .width('100%')
          .height('100%')
        }, (quote: Quote, index: number) => `${quote.text}-${index}`)
      }
      .index(this.currentPageIndex)
      .width('100%')
      .height('100%')
      .indicator(false) // 隐藏指示器
      .vertical(true) // 设置为垂直方向滑动
      .loop(false) // 禁用循环滚动，防止在边界时继续滑动
      .cachedCount(3) // 参考helper6_page_turn.txt第53行，设置缓存数量
      .onChange((index: number) => {
        // 确保索引在有效范围内
        if (index >= 0 && index < this.quoteDataSource.totalCount()) {
          this.onScrollIndex(index);
          this.updateBackgroundForCurrentPage(index);
          this.resetHintTimer(); // 滑动切换时重置提示文字定时器
        }
      })
      .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
        this.resetHintTimer(); // 滑动手势开始时立即重置提示文字定时器
      })
      .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
        // 防止向前滑动超出边界
        if (targetIndex < 0) {
          console.log('防止向前滑动超出边界');
          return;
        }
        // 防止向后滑动超出边界
        if (targetIndex >= this.quoteDataSource.totalCount()) {
          console.log('防止向后滑动超出边界');
          return;
        }
      })

      // 顶部标题栏 - 半透明层
      Row() {
        Blank()

        Button() {
          Text('...')
            .fontSize(18)
            .fontColor('#ffffff')
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(255, 255, 255, 0)')
        .borderRadius(20)
        .backdropBlur(10)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/Settings'
          });
        })
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor('rgba(0, 0, 0, 0)')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
      .position({ x: 0, y: 0 })

      // 底部提示文字 - 半透明层
      Column() {
        Text('上下滑动切换 · 长按保存')
          .fontSize(14)
          .fontColor('#ffffff')
          .textAlign(TextAlign.Center)
          .padding({ top: 12, bottom: 12, left: 24, right: 24 })
          .borderRadius(12)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 30, top: 20 })
      .backgroundColor('rgba(0, 0, 0, 0)')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
      .opacity(this.hintOpacity)

      // 全屏加载遮罩
      if (this.isLoading) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .backdropBlur(10)

          Column() {
            LoadingProgress()
              .width(50)
              .height(50)
              .margin({ bottom: 16 })

            Text('正在生成壁纸...')
              .fontSize(18)
              .fontColor('#ffffff')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width(140)
          .height(140)
          .backgroundColor('rgba(44, 62, 80, 0.8)')
          .borderRadius(16)
          .backdropBlur(20)
        }
        .width('100%')
        .height('100%')
      }
      // 隐藏的纯净壁纸组件用于截图
      this.buildPureWallpaper()
    }
    .width('100%')
    .height('100%')
    .id('previewArea')
    .gesture(
      // 长按手势：保存壁纸
      LongPressGesture({ fingers: 1, repeat: false, duration: 800 })
        .onAction(() => {
          this.resetHintTimer(); // 长按时重置提示文字定时器
          this.showSaveDialog = true;
        })
    )
    .bindContentCover(this.showSaveDialog, this.buildSaveDialog(), ModalTransition.NONE)
  }


  @Builder
  buildSaveDialog() {
    Column() {
      Column() {
        Text('应用壁纸')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .margin({ bottom: 16 })

        Text('请选择要执行的操作：')
          .fontSize(16)
          .fontColor('#7f8c8d')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        // 选项区域
        Column() {
          Column() {
            Row() {
              Checkbox({ name: 'setLockScreen', group: 'wallpaperOptions' })
                .select(this.setLockScreen)
                .selectedColor('#5b9bd5')
                .onChange((value: boolean) => {
                  this.setLockScreen = value;
                })
                .margin({ right: 12 })
                .enabled(false)

              Text('设置为系统锁屏壁纸')
                .fontSize(16)
                .fontColor('#bdc3c7')
                .flexGrow(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .padding({ top: 8, bottom: 4 })

            Text('官方已不支持该功能，需保存图片后手动设置')
              .fontSize(12)
              .fontColor('#95a5a6')
              .width('100%')
              .margin({ left: 32, bottom: 4 })
          }

          Row() {
            Checkbox({ name: 'saveToGallery', group: 'wallpaperOptions' })
              .select(this.saveToGallery)
              .selectedColor('#5b9bd5')
              .onChange((value: boolean) => {
                this.saveToGallery = value;
              })
              .margin({ right: 12 })

            Text('保存到系统图库')
              .fontSize(16)
              .fontColor('#2c3e50')
              .flexGrow(1)
              .onClick(() => {
                this.saveToGallery = !this.saveToGallery;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 8, bottom: 8 })
        }
        .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .backgroundColor('#ffffff')
            .fontColor('#7f8c8d')
            .borderRadius(6)
            .border({ width: 1, color: '#bdc3c7' })
            .enabled(!this.isApplying)
            .onClick(() => {
              this.showSaveDialog = false;
            })

          Button() {
            if (this.isApplying) {
              Row() {
                LoadingProgress()
                  .width(16)
                  .height(16)
                  .color('#ffffff')
                  .margin({ right: 8 })
                Text('应用中...')
                  .fontSize(14)
                  .fontColor('#ffffff')
              }
            } else {
              Text('确定')
                .fontSize(16)
                .fontColor('#ffffff')
            }
          }
          .width('45%')
          .height(40)
          .backgroundColor('#5b9bd5')
          .borderRadius(6)
          .margin({ left: '10%' })
          .enabled(!this.isApplying && (this.setLockScreen || this.saveToGallery))
          .onClick(async () => {
            await this.applyWallpaperOptions();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('85%')
      .padding(24)
      .backgroundColor('#ffffff')
      .borderRadius(12)
      .shadow({
        radius: 16,
        color: '#00000020',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000050')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (!this.isApplying) {
        this.showSaveDialog = false;
      }
    })
  }

  @Builder
  buildPureWallpaper() {
    // 纯净的壁纸组件，只包含背景色和文字，用于截图保存
    // 注意：截图组件不使用动画，始终显示完整内容
    Column() {
      if (this.getCurrentQuote()) {
        // 显示当前页面的内容
        Text(this.formatQuoteText(this.getCurrentQuote()?.text || '').text)
          .fontSize(this.optimizedFontSizes[this.currentPageIndex] || (this.getCurrentWallpaper()?.style.fontSize) || 24)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || '#d3d3d3')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 40 })
          .maxLines(20)
          .textOverflow({ overflow: TextOverflow.None })

        Text(`—— ${this.getCurrentQuote()?.author || ''}${(this.getCurrentQuote()?.author && this.getCurrentQuote()?.source) ? ' · ' : ''}${this.getCurrentQuote()?.source || ''}`)
          .fontSize(12)
          .fontColor((this.getCurrentWallpaper()?.style.textColor) || '#d3d3d3')
          .opacity(0.8)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(24)
    .width('100%')
    .height('100%')
    .backgroundColor(this.previewBackground || '#667eea')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .id('pureWallpaperArea')
    .position({ x: -2000, y: 0 }) // 移到屏幕外，不可见但可以截图
  }
}