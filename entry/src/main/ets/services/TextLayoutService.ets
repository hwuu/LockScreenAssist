// 文本布局服务
import { TextUtils } from '../common/TextUtils';
import {
  TextLayoutResult,
  BreakPoint,
  LineInfo,
  TextLayoutMetrics,
  WeightsConfig,
  FontRange,
  IdealLineRange,
  OptimizationConfig
} from '../common/TextLayoutTypes';
import { UI_CONSTANTS, TEXT_LAYOUT_WEIGHTS, FONT_RANGE, IDEAL_LINE_RANGE, TEXT_OPTIMIZATION_CONFIG } from '../common/UIConstants';

// 文本布局服务类
export class TextLayoutService {
  private config: OptimizationConfig;
  private screenWidth: number;
  private screenHeight: number;

  constructor(screenWidth: number, screenHeight: number) {
    this.screenWidth = screenWidth;
    this.screenHeight = screenHeight;

    const weights: WeightsConfig = {
      r1: TEXT_LAYOUT_WEIGHTS.AUTO_WRAP_RATIO,
      r2: TEXT_LAYOUT_WEIGHTS.ORPHAN_LINE_RATIO,
      r3: TEXT_LAYOUT_WEIGHTS.LINE_WIDTH_VARIANCE,
      r4: TEXT_LAYOUT_WEIGHTS.ASPECT_RATIO_DEVIATION,
      r5: TEXT_LAYOUT_WEIGHTS.SPACE_UTILIZATION,
      r6: TEXT_LAYOUT_WEIGHTS.PUNCTUATION_COMPLIANCE,
      r7: TEXT_LAYOUT_WEIGHTS.VISUAL_DENSITY_UNIFORMITY,
      r9: TEXT_LAYOUT_WEIGHTS.VISUAL_FOCUS_DISPERSION
    };

    const fontRange: FontRange = { min: FONT_RANGE.MIN, max: FONT_RANGE.MAX };
    const idealLineRange: IdealLineRange = { min: IDEAL_LINE_RANGE.MIN, max: IDEAL_LINE_RANGE.MAX };

    this.config = {
      weights: weights,
      fontRange: fontRange,
      idealLineRange: idealLineRange,
      maxIterations: TEXT_OPTIMIZATION_CONFIG.MAX_ITERATIONS
    };
  }

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

      const r1 = this.calculateAutoWrapRatio(metrics);
      const r2 = this.calculateOrphanLineRatio(metrics);
      const r3 = this.calculateLineWidthVariance(metrics);
      const r4 = this.calculateAspectRatioDeviation(metrics);
      const r5 = this.calculateSpaceUtilization(metrics);
      const r6 = this.calculatePunctuationViolationRatio(metrics);
      const r7 = this.calculateVisualDensityUniformity(metrics);
      const r9 = this.calculateVisualFocusDispersion(metrics);

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
    const r1 = this.calculateAutoWrapRatio(metrics);
    const r2 = this.calculateOrphanLineRatio(metrics);
    const r3 = this.calculateLineWidthVariance(metrics);
    const r4 = this.calculateAspectRatioDeviation(metrics);
    const r5 = this.calculateSpaceUtilization(metrics);
    const r6 = this.calculatePunctuationViolationRatio(metrics);
    const r7 = this.calculateVisualDensityUniformity(metrics);
    const r9 = this.calculateVisualFocusDispersion(metrics);

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
  private calculateAutoWrapRatio(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length === 0) return 0;
    return (metrics.autoWrapCount + metrics.originalLineCount) / metrics.lines.length;
  }

  // r2: 孤行比例 = 孤行数量 / 渲染后总行数
  private calculateOrphanLineRatio(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length === 0) return 0;
    return metrics.orphanCount / metrics.lines.length;
  }

  // r6: 标点符号位置合规性 = 行首标点数量 / 总行数
  private calculatePunctuationViolationRatio(metrics: TextLayoutMetrics): number {
    if (metrics.lines.length === 0) return 0;
    return metrics.punctuationViolations / metrics.lines.length;
  }

  // r7: 视觉密度均匀性 = 各行字符密度方差 / 平均字符密度
  private calculateVisualDensityUniformity(metrics: TextLayoutMetrics): number {
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
  private calculateLineWidthVariance(metrics: TextLayoutMetrics): number {
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
  private calculateAspectRatioDeviation(metrics: TextLayoutMetrics): number {
    if (metrics.totalWidth === 0 || metrics.totalHeight === 0 || this.screenWidth === 0 || this.screenHeight === 0) return 0;

    // 计算文本区域长宽比（高/宽）
    const textAspectRatio = metrics.totalHeight / metrics.totalWidth;

    // 计算屏幕长宽比（高/宽）
    const screenAspectRatio = this.screenHeight / this.screenWidth;

    if (screenAspectRatio === 0) return 0;
    return Math.abs(textAspectRatio - screenAspectRatio) / screenAspectRatio;
  }

  // r5: 空间利用率 = (屏幕面积 - 渲染后文本区域面积) / 屏幕面积
  private calculateSpaceUtilization(metrics: TextLayoutMetrics): number {
    if (this.screenWidth === 0 || this.screenHeight === 0) return 0;

    const screenArea = this.screenWidth * this.screenHeight;
    const textArea = metrics.totalWidth * metrics.totalHeight;

    return (screenArea - textArea) / screenArea;
  }

  // r9: 视觉焦点分散度 = |理想行数 - 实际行数| / 理想行数
  private calculateVisualFocusDispersion(metrics: TextLayoutMetrics): number {
    const actualLines = metrics.lines.length;
    const idealLines = (this.config.idealLineRange.min + this.config.idealLineRange.max) / 2;

    if (idealLines === 0) return 0;
    return Math.abs(idealLines - actualLines) / idealLines;
  }
}