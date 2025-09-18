// 文本处理工具类，包含标点符号处理、文本格式化和测量功能
import measure from '@ohos.measure';

export class TextUtils {
  // 不能在行首出现的标点符号
  static readonly AT_START = /[，。！？；：、）】」』》"'…]/;

  // 不能在行末出现的标点符号
  static readonly AT_END = /[（【「』《"']/;

  // 检查字符是否为行首禁用标点
  static isStartPunctuation(char: string): boolean {
    return TextUtils.AT_START.test(char);
  }

  // 检查字符是否为行末禁用标点
  static isEndPunctuation(char: string): boolean {
    return TextUtils.AT_END.test(char);
  }

  // 应用简单的文本格式化（标点符号换行）
  static applySimpleTextFormatting(text: string): string {
    return text
      .replace(/([，,])\s*/g, '$1\n')
      .replace(/([。！？；：])\s*/g, '$1\n \n')
      .replace(/([.!?;:])\s*/g, '$1\n \n')
      .replace(/\n{3,}/g, '\n \n')
      .replace(/\s*\n\s*/g, '\n')
      .trim();
  }

  // 通用的文本宽度测量方法
  static measureTextWidthCore(text: string, fontSize: number, fontFamily: string = 'HarmonyOS Sans'): number {
    try {
      const textMetrics = measure.measureTextSize({
        textContent: text,
        fontSize: fontSize,
        fontFamily: fontFamily
      });

      const width = textMetrics.width;

      if (typeof width === 'number') {
        return width;
      } else if (typeof width === 'string') {
        const numericValue = parseFloat(width);
        return isNaN(numericValue) ? text.length * fontSize * 0.9 : numericValue;
      } else {
        return text.length * fontSize * 0.9;
      }
    } catch (error) {
      console.error('Failed to measure text width:', error);
      return text.length * fontSize * 0.9;
    }
  }
}