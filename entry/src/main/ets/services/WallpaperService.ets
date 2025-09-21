// 壁纸生成和管理服务
import { Quote } from '../common/QuoteData';
import { wallpaper, BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { PreGeneratedWallpaperService } from './PreGeneratedWallpaperService';

export interface WallpaperStyle {
  backgroundColor: string;
  gradientColors?: string[];
  textColor: string;
  fontSize: number;
  fontFamily: string;
  textAlign: string;
  backgroundOpacity: number;
}

export interface GeneratedWallpaper {
  quote: Quote;
  style: WallpaperStyle;
  imagePath?: string;
  createdAt: Date;
}

export interface WallpaperOperationResult {
  lockScreenSuccess: boolean;
  gallerySuccess: boolean;
}

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

// 颜色信息类型
class ColorInfo {
  color: string = '';
  name: string = '';
  luminance: number = 0;

  constructor(color: string, name: string, luminance: number) {
    this.color = color;
    this.name = name;
    this.luminance = luminance;
  }
}

export class WallpaperService {
  private static readonly WALLPAPER_STORAGE_KEY = "current_wallpaper";
  private static lastColorIndex: number = -1;  // 记录上次选择的颜色索引
  private static recentColorIndices: number[] = [];  // 记录最近10次使用的颜色索引
  private static readonly MAX_HISTORY_SIZE = 10;  // 历史记录最大长度
  private static candidateColorSequence: string[] = [];  // 按亮度排序的颜色序列
  private static initialized: boolean = false;  // 是否已初始化

  // 计算单个颜色值的 WCAG 2.1 相对亮度
  private static getRGBLuminance(value: number): number {
    const normalized = value / 255;
    return normalized <= 0.03928
      ? normalized / 12.92
      : Math.pow((normalized + 0.055) / 1.055, 2.4);
  }

  // 计算十六进制颜色的亮度
  private static calculateLuminance(hexColor: string): number {
    // 移除 # 符号
    const hex = hexColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    // 使用 WCAG 2.1 公式计算亮度
    return 0.2126 * WallpaperService.getRGBLuminance(r) +
           0.7152 * WallpaperService.getRGBLuminance(g) +
           0.0722 * WallpaperService.getRGBLuminance(b);
  }

  // 原始颜色分组（保持不变）
  // 蓝色系
  private static readonly BLUES: string[] = [
      '#2563eb',    // 天蓝 L:0.162
      '#0284c7',    // 天空蓝 L:0.143
      '#1d4ed8',    // 蓝宝石 L:0.114
      '#0369a1',    // 湖蓝 L:0.097
      '#1e40af',    // 钴蓝 L:0.084
      '#075985',    // 海洋蓝 L:0.067
      '#1e3a8a',    // 皇家蓝 L:0.061
      '#0c4a6e',    // 深天蓝 L:0.047
      '#0f3460',    // 深钴蓝 L:0.036
      '#1e293b',    // 深蓝灰 L:0.027
      '#1a202c',    // 午夜蓝 L:0.020
      '#16213e',    // 暗海军蓝 L:0.020
      '#1a1a2e',    // 深紫蓝 L:0.016
      '#171923',    // 深靛蓝 L:0.013
      '#0f172a',    // 墨蓝 L:0.012
      '#020617'     // 深夜蓝 L:0.004
  ];

  // 紫色系
  private static readonly PURPLES: string[] = [
      '#7c3aed',    // 明紫 L:0.166
      '#6d28d9',    // 亮紫 L:0.133
      '#6b21a8',    // 葡萄紫 L:0.098
      '#5b21b6',    // 紫罗兰 L:0.095
      '#553c9a',    // 薰衣草紫 L:0.091
      '#6366f1',    // 柔紫蓝 L:0.178
      '#581c87',    // 深紫 L:0.063
      '#4c1d95',    // 深靛紫 L:0.065
      '#701a75',    // 深品红 L:0.058
      '#4a044e',    // 深葡萄紫 L:0.032
      '#3b0764',    // 深紫罗兰 L:0.033
      '#2e1065',    // 深夜紫 L:0.030
      '#240046',    // 暗紫 L:0.019
      '#10002b'     // 极深紫 L:0.008
  ];

  // 绿色系
  private static readonly GREENS: string[] = [
      '#22c55e',    // 明绿 L:0.371
      '#16a34a',    // 草绿 L:0.239
      '#0d9488',    // 青绿 L:0.196
      '#059669',    // 祖母绿 L:0.193
      '#15803d',    // 翠绿 L:0.154
      '#047857',    // 深青绿 L:0.125
      '#0f766e',    // 深青 L:0.120
      '#166534',    // 深祖母绿 L:0.095
      '#065f46',    // 森林绿 L:0.082
      '#14532d',    // 深森林绿 L:0.058
      '#134e4a',    // 暗绿松石 L:0.053
      '#064e3b',    // 深松绿 L:0.052
      '#022c22',    // 暗森林 L:0.020
      '#052e16',    // 极深绿 L:0.021
      '#0f2922'     // 墨绿 L:0.018
  ];

  // 棕色系
  private static readonly BROWNS: string[] = [
      '#d97706',    // 琥珀 L:0.225
      '#ca8a04',    // 金棕 L:0.263
      '#a97817',    // 芥末黄 L:0.205
      '#a16207',    // 黄棕 L:0.161
      '#b45309',    // 橙棕 L:0.140
      '#854d0e',    // 深金棕 L:0.104
      '#92400e',    // 红棕 L:0.097
      '#713f12',    // 深焦糖 L:0.078
      '#78350f',    // 深棕 L:0.068
      '#7c2d12',    // 深棕红 L:0.056
      '#5c2e0a',    // 巧克力棕 L:0.043
      '#3c2a1e',    // 咖啡色 L:0.028
      '#422006',    // 深巧克力 L:0.022
      '#451a03',    // 暗棕 L:0.021
      '#3e1a07',    // 黑棕 L:0.018
      '#431407'     // 深褐 L:0.015
  ];

  // 红色系
  private static readonly REDS: string[] = [
      '#ef4444',    // 亮红 L:0.183
      '#dc2626',    // 正红 L:0.119
      '#b91c1c',    // 猩红 L:0.080
      '#a21caf',    // 品红 L:0.097
      '#be123c',    // 玫瑰红 L:0.082
      '#991b1b',    // 酒红 L:0.058
      '#9f1239',    // 深玫红 L:0.057
      '#7f1d1d',    // 深红 L:0.044
      '#881337',    // 暗玫瑰 L:0.045
      '#831843',    // 深梅红 L:0.045
      '#500724',    // 暗酒红 L:0.014
      '#450a0a',    // 深褐红 L:0.011
      '#3f0708',    // 黑红 L:0.008
      '#2d0607'     // 暗血红 L:0.005
  ];

  // 橙色系
  private static readonly ORANGES: string[] = [
      '#fb923c',    // 亮橙 L:0.347
      '#f97316',    // 橙 L:0.260
      '#ea580c',    // 深橙 L:0.189
      '#dc2626',    // 橙红 L:0.119
      '#c2410c',    // 暗橙 L:0.103
      '#9a3412',    // 褐橙 L:0.065
      '#7c2d12',    // 深褐橙 L:0.056
      '#6b2912',    // 暗褐橙 L:0.043
      '#582010'     // 黑橙 L:0.030
  ];

  // 粉色系
  private static readonly PINKS: string[] = [
      '#f472b6',    // 亮粉 L:0.303
      '#ec4899',    // 粉红 L:0.208
      '#db2777',    // 深粉 L:0.138
      '#be185d',    // 暗粉 L:0.089
      '#9d174d',    // 深玫粉 L:0.059
      '#831843',    // 深品粉 L:0.045
      '#701a75',    // 梅红 L:0.058
      '#500724'     // 暗梅红 L:0.014
  ];

  // 青色系
  private static readonly CYANS: string[] = [
      '#22d3ee',    // 亮青 L:0.479
      '#06b6d4',    // 青 L:0.340
      '#0891b2',    // 深青 L:0.213
      '#0e7490',    // 暗青 L:0.125
      '#155e75',    // 深暗青 L:0.086
      '#164e63',    // 墨青 L:0.061
      '#083344'     // 深墨青 L:0.032
  ];

  // 灰色系
  private static readonly GRAYS: string[] = [
      '#6b7280',    // 银灰 L:0.250
      '#4b5563',    // 浅灰蓝 L:0.141
      '#57534e',    // 中性灰 L:0.134
      '#4a5568',    // 板岩灰 L:0.141
      '#44403c',    // 暖灰 L:0.089
      '#3f3f46',    // 中锌灰 L:0.086
      '#374151',    // 中灰蓝 L:0.086
      '#3d4852',    // 暗青灰 L:0.103
      '#36393f',    // 深钢灰 L:0.069
      '#313540',    // 深炭灰 L:0.058
      '#2d3748',    // 暗石板 L:0.059
      '#2c2f33',    // 暗灰 L:0.045
      '#2b2d3a',    // 暗铁灰 L:0.041
      '#1f2937',    // 暗蓝灰 L:0.037
      '#292524',    // 深石灰 L:0.033
      '#27272a',    // 暗锌灰 L:0.034
      '#23272a',    // 炭黑 L:0.033
      '#1e2124',    // 石墨灰 L:0.025
      '#1c1917',    // 暗石色 L:0.016
      '#111827',    // 深灰蓝 L:0.017
      '#18181b'     // 深炭 L:0.015
  ];

  // 初始化：生成按亮度排序的颜色序列
  private static initializeCandidateSequence(): void {
    if (WallpaperService.initialized) {
      return;
    }

    // 收集所有颜色并计算亮度
    const allColors: ColorInfo[] = [];

    // 处理所有色系
    const processColorGroup = (colors: string[]) => {
      colors.forEach((colorStr: string) => {
        // 只提取十六进制颜色值（#开头的6位十六进制）
        const hexMatch = colorStr.match(/^#[0-9a-fA-F]{6}/);
        if (hexMatch) {
          const hex = hexMatch[0];
          // 使用统一的亮度计算方法
          const luminance = WallpaperService.calculateLuminance(hex);
          allColors.push(new ColorInfo(hex, '', luminance));
        }
      });
    };

    // 处理每个色系
    processColorGroup(WallpaperService.BLUES);
    processColorGroup(WallpaperService.PURPLES);
    processColorGroup(WallpaperService.GREENS);
    processColorGroup(WallpaperService.BROWNS);
    processColorGroup(WallpaperService.REDS);
    processColorGroup(WallpaperService.ORANGES);
    processColorGroup(WallpaperService.PINKS);
    processColorGroup(WallpaperService.CYANS);
    processColorGroup(WallpaperService.GRAYS);

    // 按亮度从高到低排序
    allColors.sort((a: ColorInfo, b: ColorInfo) => b.luminance - a.luminance);

    // 过滤掉过亮的颜色（亮度 > 0.20）
    const filteredColors = allColors.filter((c: ColorInfo) => c.luminance <= 0.20);

    // 生成最终的颜色序列
    WallpaperService.candidateColorSequence = filteredColors.map((c: ColorInfo) => c.color);
    WallpaperService.initialized = true;

    console.log(`初始化颜色序列完成，共 ${WallpaperService.candidateColorSequence.length} 个颜色`);
  }

  // 根据邻近算法选择背景颜色
  private static selectBackgroundColor(): string {
    // 确保已初始化
    WallpaperService.initializeCandidateSequence();

    const colors = WallpaperService.candidateColorSequence;
    const totalColors = colors.length;

    // 初次选择：完全随机
    if (WallpaperService.lastColorIndex === -1) {
      WallpaperService.lastColorIndex = Math.floor(Math.random() * totalColors);
      // 记录到历史
      WallpaperService.addToHistory(WallpaperService.lastColorIndex);
      return colors[WallpaperService.lastColorIndex];
    }

    // 后续选择：在当前位置的前10个和后10个之间选择
    const range = 10;  // 邻近范围
    const minIndex = Math.max(0, WallpaperService.lastColorIndex - range);
    const maxIndex = Math.min(totalColors - 1, WallpaperService.lastColorIndex + range);

    // 构建可选索引列表（排除最近10次使用过的颜色）
    const availableIndices: number[] = [];
    for (let i = minIndex; i <= maxIndex; i++) {
      // 检查该索引是否在最近10次历史中
      if (!WallpaperService.recentColorIndices.includes(i)) {
        availableIndices.push(i);
      }
    }

    // 如果有可用的索引，从中随机选择
    if (availableIndices.length > 0) {
      const randomIndex = Math.floor(Math.random() * availableIndices.length);
      WallpaperService.lastColorIndex = availableIndices[randomIndex];
    } else {
      // 如果没有可用的索引（极端情况：范围内所有颜色都在最近10次内使用过）
      // 从范围内除当前颜色外随机选择
      let newIndex = WallpaperService.lastColorIndex;
      const rangeSize = maxIndex - minIndex + 1;
      if (rangeSize > 1) {
        while (newIndex === WallpaperService.lastColorIndex) {
          const randomOffset = Math.floor(Math.random() * rangeSize);
          newIndex = minIndex + randomOffset;
        }
        WallpaperService.lastColorIndex = newIndex;
      }
    }

    // 记录到历史
    WallpaperService.addToHistory(WallpaperService.lastColorIndex);
    return colors[WallpaperService.lastColorIndex];
  }

  // 将索引添加到历史记录
  private static addToHistory(index: number): void {
    // 添加新索引到开头
    WallpaperService.recentColorIndices.unshift(index);

    // 保持历史记录不超过10个
    if (WallpaperService.recentColorIndices.length > WallpaperService.MAX_HISTORY_SIZE) {
      WallpaperService.recentColorIndices.pop();
    }

    //console.log(`颜色历史记录: [${WallpaperService.recentColorIndices.join(', ')}]`);
  }

  // 生成壁纸样式（使用预生成数据）
  static generateWallpaperStyle(quote: Quote): WallpaperStyle {
    // 优先使用预生成的数据
    if (PreGeneratedWallpaperService.isReady()) {
      const preGenerated = PreGeneratedWallpaperService.getNextWallpaper();
      if (preGenerated) {
        // 返回预生成的样式，但保留传入的quote（如果需要的话）
        return preGenerated.style;
      }
    }

    // 降级到原有的动态生成逻辑
    console.log('使用动态生成壁纸样式（预生成数据不可用）');
    const textLength = quote.text.length;
    const randomBackground = WallpaperService.selectBackgroundColor();
    const textColor = WallpaperService.calculateOptimalTextColor(randomBackground);

    let style: WallpaperStyle = {
      backgroundColor: randomBackground,
      textColor: textColor,
      fontSize: WallpaperService.calculateOptimalFontSize(textLength),
      fontFamily: 'HarmonyOS Sans',
      textAlign: 'center',
      backgroundOpacity: 1.0
    };

    return style;
  }

  // 根据背景颜色计算最佳文字颜色
  private static calculateOptimalTextColor(backgroundColor: string): string {
    // 使用统一的亮度计算方法
    const luminance = WallpaperService.calculateLuminance(backgroundColor);

    // 获取RGB值以计算色调
    const hex = backgroundColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    // 高级感文字颜色选择
    const textColors: TextColors = {
      // 高对比度白色系
      white: '#ffffff',           // 纯白
      softWhite: '#f8fafc',      // 柔和白
      warmWhite: '#fefefe',      // 暖白
      coolWhite: '#f1f5f9',      // 冷白

      // 优雅浅色系
      lightGray: '#e2e8f0',      // 浅灰
      silver: '#cbd5e1',         // 银色
      platinum: '#d1d5db',       // 铂金色

      // 深色文字（极少使用）
      charcoal: '#1f2937',       // 炭灰
      midnight: '#111827'        // 午夜蓝
    };

    // 根据背景亮度和色调智能选择文字颜色
    if (luminance > 0.5) {
      // 亮背景：使用深色文字
      return textColors.charcoal;
    } else if (luminance > 0.18) {
      // 中等亮度背景：使用高对比度白色
      return textColors.white;
    } else if (luminance > 0.05) {
      // 深色背景：使用柔和白色，更舒适
      return textColors.softWhite;
    } else {
      // 极深背景：使用暖白色，增加层次感
      // 根据背景颜色倾向选择不同的白色调
      const hue = WallpaperService.calculateHue(r, g, b);

      if (hue >= 200 && hue <= 260) {
        // 蓝色系背景使用暖白平衡
        return textColors.warmWhite;
      } else if (hue >= 260 && hue <= 320) {
        // 紫色系背景使用冷白
        return textColors.coolWhite;
      } else if (hue >= 80 && hue <= 160) {
        // 绿色系背景使用柔和白
        return textColors.softWhite;
      } else {
        // 其他颜色使用纯白
        return textColors.white;
      }
    }
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

  // 计算最佳字体大小（调小）
  private static calculateOptimalFontSize(textLength: number): number {
    if (textLength <= 15) return 36;
    if (textLength <= 25) return 32;
    if (textLength <= 35) return 28;
    if (textLength <= 50) return 24;
    if (textLength <= 70) return 20;
    return 18;
  }

  // 根据季节调整样式
  private static adjustStyleBySeason(style: WallpaperStyle, season: string): WallpaperStyle {
    switch (season) {
      case '春':
        style.gradientColors = ['#a8e6cf', '#dcedc8'];
        style.textColor = '#2e7d32';
        break;
      case '夏':
        style.gradientColors = ['#ffd54f', '#ff8a65'];
        style.textColor = '#d84315';
        break;
      case '秋':
        style.gradientColors = ['#ffb74d', '#ff8a65'];
        style.textColor = '#5d4037';
        break;
      case '冬':
        style.gradientColors = ['#90caf9', '#e1f5fe'];
        style.textColor = '#0277bd';
        break;
    }
    return style;
  }

  // 根据天气调整样式
  private static adjustStyleByWeather(style: WallpaperStyle, weather: string): WallpaperStyle {
    switch (weather) {
      case 'sunny':
        style.gradientColors = ['#ffd54f', '#ffecb3'];
        style.textColor = '#f57f17';
        break;
      case 'cloudy':
        style.gradientColors = ['#90a4ae', '#cfd8dc'];
        style.textColor = '#37474f';
        break;
      case 'rainy':
        style.gradientColors = ['#64b5f6', '#90caf9'];
        style.textColor = '#0d47a1';
        break;
      case 'snowy':
        style.gradientColors = ['#e8eaf6', '#f3e5f5'];
        style.textColor = '#4527a0';
        break;
      case 'hot':
        style.gradientColors = ['#ff5722', '#ff9800'];
        style.textColor = '#ffffff';
        break;
      case 'cold':
        style.gradientColors = ['#3f51b5', '#7986cb'];
        style.textColor = '#ffffff';
        break;
    }
    return style;
  }

  // 生成壁纸（使用预生成数据）
  static async generateWallpaper(quote?: Quote): Promise<GeneratedWallpaper> {
    let finalQuote: Quote = quote || { text: '', author: '', category: '' };
    let style: WallpaperStyle;

    // 优先使用预生成的数据
    if (PreGeneratedWallpaperService.isReady()) {
      const preGenerated = PreGeneratedWallpaperService.getNextWallpaper();
      if (preGenerated) {
        finalQuote = preGenerated.quote;
        style = preGenerated.style;
      } else {
        // 降级逻辑
        style = WallpaperService.generateWallpaperStyle(finalQuote);
      }
    } else {
      // 降级到原有逻辑
      if (!quote) {
        console.error('预生成数据未就绪且未提供quote');
        finalQuote = { text: '生活就像海洋，只有意志坚强的人，才能到达彼岸。', author: '马克思', category: '励志' };
      }
      style = WallpaperService.generateWallpaperStyle(finalQuote);
    }

    const wallpaper: GeneratedWallpaper = {
      quote: finalQuote,
      style,
      createdAt: new Date()
    };

    // 这里应该生成实际的图片文件
    // 在HarmonyOS中可以使用Canvas API或者图片处理库
    wallpaper.imagePath = await WallpaperService.generateImageFile(wallpaper);

    return wallpaper;
  }

  // 生成图片文件（模拟实现）
  private static async generateImageFile(wallpaper: GeneratedWallpaper): Promise<string> {
    // 在实际实现中，这里应该：
    // 1. 创建Canvas
    // 2. 绘制渐变背景
    // 3. 绘制文字
    // 4. 保存为图片文件
    // 5. 返回文件路径

    const timestamp = Date.now();
    const fileName = `quote_wallpaper_${timestamp}.png`;
    const filePath = `wallpapers/${fileName}`;

    // 模拟生成过程
    console.log(`Generating wallpaper: ${fileName}`);
    console.log(`Quote: ${wallpaper.quote.text}`);
    console.log(`Style: ${JSON.stringify(wallpaper.style)}`);

    return filePath;
  }


  // 保存当前壁纸信息 (公开方法供外部调用)
  static async saveCurrentWallpaper(wallpaper: GeneratedWallpaper): Promise<void> {
    // 在实际应用中应该使用Preferences API存储
    console.log('Current wallpaper saved:', wallpaper);
  }

  // 获取当前壁纸
  static async getCurrentWallpaper(): Promise<GeneratedWallpaper | null> {
    try {
      // 从存储中读取当前壁纸信息
      // 这里返回模拟数据
      return null;
    } catch (error) {
      console.error('Failed to get current wallpaper:', error);
      return null;
    }
  }

  // 预览壁纸效果
  static createWallpaperPreview(wallpaper: GeneratedWallpaper): string {
    // 返回CSS样式字符串，用于UI预览
    const style = wallpaper.style;

    if (style.gradientColors && style.gradientColors.length >= 2) {
      return `linear-gradient(135deg, ${style.gradientColors[0]} 0%, ${style.gradientColors[1]} 100%)`;
    } else {
      return style.backgroundColor;
    }
  }

  // 清理旧的壁纸文件
  static async cleanupOldWallpapers(keepCount: number = 10): Promise<void> {
    try {
      // 清理超过指定数量的旧壁纸文件
      console.log(`Cleaning up old wallpapers, keeping ${keepCount} recent files`);
    } catch (error) {
      console.error('Failed to cleanup old wallpapers:', error);
    }
  }

  // 设置锁屏壁纸
  static async setLockScreenWallpaper(imagePath: string): Promise<boolean> {
    try {
      console.log('Setting lock screen wallpaper:', imagePath);

      // 获取上下文 - 明确类型为UIAbilityContext
      const context: common.UIAbilityContext = globalThis.abilityContext;
      if (!context) {
        throw new Error('Unable to get application context');
      }

      // 检查SET_WALLPAPER权限
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = await atManager.checkAccessToken(context.applicationInfo.accessTokenId, 'ohos.permission.SET_WALLPAPER');

      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.warn('SET_WALLPAPER permission not granted, status:', grantStatus);
        // 不抛出错误，因为权限可能在module.json5中已声明
      } else {
        console.log('SET_WALLPAPER permission granted');
      }

      // 验证文件是否存在
      try {
        const stat: fs.Stat = await fs.stat(imagePath);
        console.info("get file info succeed, the size of file is " + stat.size);
      } catch (statError) {
        console.error("get file info failed with error message: " + (statError as BusinessError).message + ", error code: " + (statError as BusinessError).code);
        throw new Error('Wallpaper file not accessible');
      }

      // 使用正确的wallpaper API调用方式
      // 参考 _helper4_set_wallpaper.txt，使用WallpaperType.WALLPAPER_LOCKSCREEN
      console.log('Calling wallpaper.setWallpaper with type WALLPAPER_LOCKSCREEN');

      // 使用Promise版本的API调用
      await wallpaper.setWallpaper(imagePath, wallpaper.WallpaperType.WALLPAPER_LOCKSCREEN);

      console.log('Lock screen wallpaper set successfully:', imagePath);
      return true;
    } catch (error) {
      console.error('Failed to set lock screen wallpaper:', error);
      console.error('Error details:', JSON.stringify(error));
      return false;
    }
  }

  // 保存到系统图库
  static async saveToGallery(imagePath: string): Promise<boolean> {
    try {
      console.log('Attempting to save image to gallery:', imagePath);

      // 获取上下文 - 明确类型为UIAbilityContext
      const context: common.UIAbilityContext = globalThis.abilityContext;
      if (!context) {
        throw new Error('Unable to get application context');
      }

      // 参考 _helper.txt 第88行：const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const helper = photoAccessHelper.getPhotoAccessHelper(context);

      // 参考 _helper.txt 第89行：const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      const uri: string = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      // 读取源文件内容
      const sourceFile = await fs.open(imagePath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(imagePath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(sourceFile.fd, buffer);
      await fs.close(sourceFile);

      // 参考 _helper.txt 第90-92行：const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, buffer);
      await fs.close(file.fd);

      console.log('Image saved to gallery successfully:', uri);
      return true;
    } catch (error) {
      console.error('Failed to save image to gallery:', error);
      console.error('Error details:', JSON.stringify(error));
      return false;
    }
  }

  // 应用壁纸操作（设置锁屏壁纸和/或保存到图库）
  static async applyWallpaperOperations(imagePath: string, setLockScreen: boolean, saveToGallery: boolean): Promise<WallpaperOperationResult> {
    const results: WallpaperOperationResult = {
      lockScreenSuccess: false,
      gallerySuccess: false
    };

    if (setLockScreen) {
      results.lockScreenSuccess = await WallpaperService.setLockScreenWallpaper(imagePath);
    }

    if (saveToGallery) {
      results.gallerySuccess = await WallpaperService.saveToGallery(imagePath);
    }

    return results;
  }
}