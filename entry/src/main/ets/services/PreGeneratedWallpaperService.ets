// 预生成壁纸数据服务
import { Quote } from '../common/QuoteData';
import { WallpaperStyle } from './WallpaperService';

export interface PreGeneratedWallpaper {
  id: number;
  quote: Quote;
  style: WallpaperStyle;
}

export class PreGeneratedWallpaperService {
  private static preGeneratedWallpapers: PreGeneratedWallpaper[] = [];
  private static currentIndex: number = 0;
  private static isInitialized: boolean = false;

  // 预生成的壁纸数量
  private static readonly WALLPAPER_COUNT = 100;

  // 颜色序列（从WallpaperService复制过来的颜色定义）
  private static candidateColorSequence: string[] = [];

  // 蓝色系
  private static readonly BLUES: string[] = [
    '#2563eb', '#0284c7', '#1d4ed8', '#0369a1', '#1e40af', '#075985',
    '#1e3a8a', '#0c4a6e', '#0f3460', '#1e293b', '#1a202c', '#16213e',
    '#1a1a2e', '#171923', '#0f172a', '#020617'
  ];

  // 紫色系
  private static readonly PURPLES: string[] = [
    '#7c3aed', '#6d28d9', '#6b21a8', '#5b21b6', '#553c9a', '#6366f1',
    '#581c87', '#4c1d95', '#701a75', '#4a044e', '#3b0764', '#2e1065',
    '#240046', '#10002b'
  ];

  // 绿色系
  private static readonly GREENS: string[] = [
    '#22c55e', '#16a34a', '#0d9488', '#059669', '#15803d', '#047857',
    '#0f766e', '#166534', '#065f46', '#14532d', '#134e4a', '#064e3b',
    '#022c22', '#052e16', '#0f2922'
  ];

  // 棕色系
  private static readonly BROWNS: string[] = [
    '#d97706', '#ca8a04', '#a97817', '#a16207', '#b45309', '#854d0e',
    '#92400e', '#713f12', '#78350f', '#7c2d12', '#5c2e0a', '#3c2a1e',
    '#422006', '#451a03', '#3e1a07', '#431407'
  ];

  // 红色系
  private static readonly REDS: string[] = [
    '#ef4444', '#dc2626', '#b91c1c', '#a21caf', '#be123c', '#991b1b',
    '#9f1239', '#7f1d1d', '#881337', '#831843', '#500724', '#450a0a',
    '#3f0708', '#2d0607'
  ];

  // 橙色系
  private static readonly ORANGES: string[] = [
    '#fb923c', '#f97316', '#ea580c', '#dc2626', '#c2410c', '#9a3412',
    '#7c2d12', '#6b2912', '#582010'
  ];

  // 粉色系
  private static readonly PINKS: string[] = [
    '#f472b6', '#ec4899', '#db2777', '#be185d', '#9d174d', '#831843',
    '#701a75', '#500724'
  ];

  // 青色系
  private static readonly CYANS: string[] = [
    '#22d3ee', '#06b6d4', '#0891b2', '#0e7490', '#155e75', '#164e63',
    '#083344'
  ];

  // 灰色系
  private static readonly GRAYS: string[] = [
    '#6b7280', '#4b5563', '#57534e', '#4a5568', '#44403c', '#3f3f46',
    '#374151', '#3d4852', '#36393f', '#313540', '#2d3748', '#2c2f33',
    '#2b2d3a', '#1f2937', '#292524', '#27272a', '#23272a', '#1e2124',
    '#1c1917', '#111827', '#18181b'
  ];

  // 计算单个颜色值的 WCAG 2.1 相对亮度
  private static getRGBLuminance(value: number): number {
    const normalized = value / 255;
    return normalized <= 0.03928
      ? normalized / 12.92
      : Math.pow((normalized + 0.055) / 1.055, 2.4);
  }

  // 计算十六进制颜色的亮度
  private static calculateLuminance(hexColor: string): number {
    const hex = hexColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    // 使用 WCAG 2.1 公式计算亮度
    return 0.2126 * PreGeneratedWallpaperService.getRGBLuminance(r) +
           0.7152 * PreGeneratedWallpaperService.getRGBLuminance(g) +
           0.0722 * PreGeneratedWallpaperService.getRGBLuminance(b);
  }

  // 计算颜色的色调
  private static calculateHue(r: number, g: number, b: number): number {
    const max = Math.max(r, g, b) / 255;
    const min = Math.min(r, g, b) / 255;
    const delta = max - min;

    if (delta === 0) return 0;

    let hue = 0;
    if (max === r / 255) {
      hue = ((g / 255 - b / 255) / delta) % 6;
    } else if (max === g / 255) {
      hue = (b / 255 - r / 255) / delta + 2;
    } else {
      hue = (r / 255 - g / 255) / delta + 4;
    }

    return hue * 60;
  }

  // 根据背景颜色计算最佳文字颜色
  private static calculateOptimalTextColor(backgroundColor: string): string {
    const luminance = PreGeneratedWallpaperService.calculateLuminance(backgroundColor);

    const hex = backgroundColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    // 高级感文字颜色选择
    interface TextColors {
      white: string;
      softWhite: string;
      warmWhite: string;
      coolWhite: string;
      lightGray: string;
      silver: string;
      platinum: string;
      charcoal: string;
      midnight: string;
    }

    const textColors: TextColors = {
      white: '#ffffff',
      softWhite: '#f8fafc',
      warmWhite: '#fefefe',
      coolWhite: '#f1f5f9',
      lightGray: '#e2e8f0',
      silver: '#cbd5e1',
      platinum: '#d1d5db',
      charcoal: '#1f2937',
      midnight: '#111827'
    };

    // 根据背景亮度和色调智能选择文字颜色
    if (luminance > 0.5) {
      return textColors.charcoal;
    } else if (luminance > 0.18) {
      return textColors.white;
    } else if (luminance > 0.05) {
      return textColors.softWhite;
    } else {
      const hue = PreGeneratedWallpaperService.calculateHue(r, g, b);

      if (hue >= 200 && hue <= 260) {
        return textColors.warmWhite;
      } else if (hue >= 260 && hue <= 320) {
        return textColors.coolWhite;
      } else if (hue >= 80 && hue <= 160) {
        return textColors.softWhite;
      } else {
        return textColors.white;
      }
    }
  }

  // 计算最佳字体大小
  private static calculateOptimalFontSize(textLength: number): number {
    if (textLength <= 15) return 36;
    if (textLength <= 25) return 32;
    if (textLength <= 35) return 28;
    if (textLength <= 50) return 24;
    if (textLength <= 70) return 20;
    return 18;
  }

  // 初始化颜色序列
  private static initializeColorSequence(): void {
    interface ColorInfo {
      color: string;
      luminance: number;
    }
    const allColors: ColorInfo[] = [];

    // 收集所有颜色
    const processColorGroup = (colors: string[]) => {
      colors.forEach((color: string) => {
        const luminance = PreGeneratedWallpaperService.calculateLuminance(color);
        const colorInfo: ColorInfo = { color: color, luminance: luminance };
        allColors.push(colorInfo);
      });
    };

    processColorGroup(PreGeneratedWallpaperService.BLUES);
    processColorGroup(PreGeneratedWallpaperService.PURPLES);
    processColorGroup(PreGeneratedWallpaperService.GREENS);
    processColorGroup(PreGeneratedWallpaperService.BROWNS);
    processColorGroup(PreGeneratedWallpaperService.REDS);
    processColorGroup(PreGeneratedWallpaperService.ORANGES);
    processColorGroup(PreGeneratedWallpaperService.PINKS);
    processColorGroup(PreGeneratedWallpaperService.CYANS);
    processColorGroup(PreGeneratedWallpaperService.GRAYS);

    // 按亮度排序并过滤
    allColors.sort((a, b) => b.luminance - a.luminance);
    const filteredColors = allColors.filter(c => c.luminance <= 0.20);
    PreGeneratedWallpaperService.candidateColorSequence = filteredColors.map(c => c.color);

    console.log(`初始化颜色序列完成，共 ${PreGeneratedWallpaperService.candidateColorSequence.length} 个颜色`);
  }

  // 使用邻近算法选择背景颜色序列
  private static generateBackgroundColorSequence(): string[] {
    PreGeneratedWallpaperService.initializeColorSequence();

    const colors = PreGeneratedWallpaperService.candidateColorSequence;
    const totalColors = colors.length;
    const result: string[] = [];
    const recentIndices: number[] = [];
    const maxHistory = 10;

    // 初次选择：完全随机
    let lastIndex = Math.floor(Math.random() * totalColors);
    result.push(colors[lastIndex]);
    recentIndices.push(lastIndex);

    // 生成后续99个颜色
    for (let i = 1; i < PreGeneratedWallpaperService.WALLPAPER_COUNT; i++) {
      const range = 10;
      const minIndex = Math.max(0, lastIndex - range);
      const maxIndex = Math.min(totalColors - 1, lastIndex + range);

      // 构建可选索引列表
      const availableIndices: number[] = [];
      for (let j = minIndex; j <= maxIndex; j++) {
        if (!recentIndices.includes(j)) {
          availableIndices.push(j);
        }
      }

      // 选择新索引
      if (availableIndices.length > 0) {
        const randomIndex = Math.floor(Math.random() * availableIndices.length);
        lastIndex = availableIndices[randomIndex];
      } else {
        // 极端情况：从范围内随机选择
        let newIndex = lastIndex;
        const rangeSize = maxIndex - minIndex + 1;
        if (rangeSize > 1) {
          while (newIndex === lastIndex) {
            const randomOffset = Math.floor(Math.random() * rangeSize);
            newIndex = minIndex + randomOffset;
          }
          lastIndex = newIndex;
        }
      }

      result.push(colors[lastIndex]);
      recentIndices.unshift(lastIndex);
      if (recentIndices.length > maxHistory) {
        recentIndices.pop();
      }
    }

    return result;
  }

  // 初始化预生成的壁纸数据
  static async initialize(quotes: Quote[]): Promise<void> {
    if (PreGeneratedWallpaperService.isInitialized) {
      console.log('预生成壁纸数据已初始化，跳过重复初始化');
      return;
    }

    console.log('开始预生成壁纸数据...');

    // 清空现有数据
    PreGeneratedWallpaperService.preGeneratedWallpapers = [];

    // 确保有足够的名言
    if (quotes.length === 0) {
      console.error('没有可用的名言数据');
      return;
    }

    // 生成背景颜色序列
    const backgroundColors = PreGeneratedWallpaperService.generateBackgroundColorSequence();

    // 随机选择100条不重复的名言
    const selectedQuotes: Quote[] = [];
    const quoteCopy = [...quotes];

    // 如果名言少于100条，则循环使用
    if (quoteCopy.length >= PreGeneratedWallpaperService.WALLPAPER_COUNT) {
      // 随机选择100条不重复的名言
      for (let i = 0; i < PreGeneratedWallpaperService.WALLPAPER_COUNT; i++) {
        const randomIndex = Math.floor(Math.random() * quoteCopy.length);
        selectedQuotes.push(quoteCopy[randomIndex]);
        quoteCopy.splice(randomIndex, 1);
      }
    } else {
      // 名言不足100条，循环使用
      let quoteIndex = 0;
      for (let i = 0; i < PreGeneratedWallpaperService.WALLPAPER_COUNT; i++) {
        selectedQuotes.push(quoteCopy[quoteIndex % quoteCopy.length]);
        quoteIndex++;
      }
    }

    // 生成100个预设的壁纸数据
    for (let i = 0; i < PreGeneratedWallpaperService.WALLPAPER_COUNT; i++) {
      const quote = selectedQuotes[i];
      const backgroundColor = backgroundColors[i];
      const textColor = PreGeneratedWallpaperService.calculateOptimalTextColor(backgroundColor);
      const fontSize = PreGeneratedWallpaperService.calculateOptimalFontSize(quote.text.length);

      const wallpaper: PreGeneratedWallpaper = {
        id: i,
        quote: quote,
        style: {
          backgroundColor: backgroundColor,
          textColor: textColor,
          fontSize: fontSize,
          fontFamily: 'HarmonyOS Sans',
          textAlign: 'center',
          backgroundOpacity: 1.0
        }
      };

      PreGeneratedWallpaperService.preGeneratedWallpapers.push(wallpaper);
    }

    PreGeneratedWallpaperService.isInitialized = true;
    console.log(`预生成壁纸数据完成，共生成 ${PreGeneratedWallpaperService.preGeneratedWallpapers.length} 个壁纸配置`);
  }

  // 获取下一个壁纸
  static getNextWallpaper(): PreGeneratedWallpaper | null {
    if (!PreGeneratedWallpaperService.isInitialized ||
        PreGeneratedWallpaperService.preGeneratedWallpapers.length === 0) {
      console.error('预生成壁纸数据未初始化');
      return null;
    }

    const wallpaper = PreGeneratedWallpaperService.preGeneratedWallpapers[PreGeneratedWallpaperService.currentIndex];
    PreGeneratedWallpaperService.currentIndex =
      (PreGeneratedWallpaperService.currentIndex + 1) % PreGeneratedWallpaperService.WALLPAPER_COUNT;

    return wallpaper;
  }

  // 获取指定索引的壁纸
  static getWallpaperByIndex(index: number): PreGeneratedWallpaper | null {
    if (!PreGeneratedWallpaperService.isInitialized ||
        index < 0 ||
        index >= PreGeneratedWallpaperService.preGeneratedWallpapers.length) {
      return null;
    }

    return PreGeneratedWallpaperService.preGeneratedWallpapers[index];
  }

  // 获取当前索引
  static getCurrentIndex(): number {
    return PreGeneratedWallpaperService.currentIndex;
  }

  // 设置当前索引
  static setCurrentIndex(index: number): void {
    if (index >= 0 && index < PreGeneratedWallpaperService.WALLPAPER_COUNT) {
      PreGeneratedWallpaperService.currentIndex = index;
    }
  }

  // 获取所有预生成的壁纸
  static getAllWallpapers(): PreGeneratedWallpaper[] {
    return PreGeneratedWallpaperService.preGeneratedWallpapers;
  }

  // 检查是否已初始化
  static isReady(): boolean {
    return PreGeneratedWallpaperService.isInitialized;
  }

  // 重置服务
  static reset(): void {
    PreGeneratedWallpaperService.preGeneratedWallpapers = [];
    PreGeneratedWallpaperService.currentIndex = 0;
    PreGeneratedWallpaperService.isInitialized = false;
    PreGeneratedWallpaperService.candidateColorSequence = [];
  }
}