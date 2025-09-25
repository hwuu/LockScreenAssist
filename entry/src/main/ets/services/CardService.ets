// 卡片服务（统一管理卡片生成、样式、导出和页面管理功能）
import { Quote } from '../common/QuoteData';
import { CardViewerDataSource } from '../common/CardViewerDataSource';
import { QuoteSelectionService } from './QuoteSelectionService';
import { TextLayoutService } from './TextLayoutService';
import { TextUtils } from '../common/TextUtils';
import { TextLayoutResult } from '../common/TextLayoutTypes';
import { QuoteListInitResult, QuoteListInitParams, ProcessQuoteParams } from '../common/ServiceTypes';
import componentSnapshot from '@ohos.arkui.componentSnapshot';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wallpaper } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

// 卡片样式定义
export interface CardStyle {
  backgroundColor: string;
  gradientColors?: string[];
  textColor: string;
  fontSize: number;
  fontFamily: string;
  textAlign: string;
  backgroundOpacity: number;
}

// 卡片数据
export interface Card {
  quote: Quote;
  style: CardStyle;
  imagePath?: string;
  createdAt: Date;
}

// 卡片导出参数
export interface CardExportParams {
  setAsLockScreen: boolean;
  saveToGallery: boolean;
  context: common.UIAbilityContext;
}

// 卡片操作结果
export interface CardOperationResult {
  success: boolean;
  message: string;
  lockScreenSuccess?: boolean;
  gallerySuccess?: boolean;
}

// 文字颜色配置
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

// HSL颜色空间接口
interface HSLColor {
  h: number;  // 色调 (0-1)
  s: number;  // 饱和度 (0-1)
  l: number;  // 明度 (0-1)
}

// RGB颜色空间接口
interface RGBColor {
  r: number;  // 红色分量 (0-255)
  g: number;  // 绿色分量 (0-255)
  b: number;  // 蓝色分量 (0-255)
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

export class CardService {
  private static readonly CARD_STORAGE_KEY = "current_card";
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
    return 0.2126 * CardService.getRGBLuminance(r) +
           0.7152 * CardService.getRGBLuminance(g) +
           0.0722 * CardService.getRGBLuminance(b);
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
    if (CardService.initialized) {
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
          const luminance = CardService.calculateLuminance(hex);
          allColors.push(new ColorInfo(hex, '', luminance));
        }
      });
    };

    // 处理每个色系
    processColorGroup(CardService.BLUES);
    processColorGroup(CardService.PURPLES);
    processColorGroup(CardService.GREENS);
    processColorGroup(CardService.BROWNS);
    processColorGroup(CardService.REDS);
    processColorGroup(CardService.ORANGES);
    processColorGroup(CardService.PINKS);
    processColorGroup(CardService.CYANS);
    processColorGroup(CardService.GRAYS);

    // 按亮度从高到低排序
    allColors.sort((a: ColorInfo, b: ColorInfo) => b.luminance - a.luminance);

    // 过滤掉过亮的颜色（亮度 > 0.20）
    const filteredColors = allColors.filter((c: ColorInfo) => c.luminance <= 0.20);

    // 生成最终的颜色序列
    CardService.candidateColorSequence = filteredColors.map((c: ColorInfo) => c.color);
    CardService.initialized = true;

    console.log(`初始化颜色序列完成，共 ${CardService.candidateColorSequence.length} 个颜色`);
  }

  // 根据邻近算法选择背景颜色
  private static selectBackgroundColor(): string {
    // 确保已初始化
    CardService.initializeCandidateSequence();

    const colors = CardService.candidateColorSequence;
    const totalColors = colors.length;

    // 初次选择：完全随机
    if (CardService.lastColorIndex === -1) {
      CardService.lastColorIndex = Math.floor(Math.random() * totalColors);
      // 记录到历史
      CardService.addToHistory(CardService.lastColorIndex);
      return colors[CardService.lastColorIndex];
    }

    // 后续选择：在当前位置的前10个和后10个之间选择
    const range = 10;  // 邻近范围
    const minIndex = Math.max(0, CardService.lastColorIndex - range);
    const maxIndex = Math.min(totalColors - 1, CardService.lastColorIndex + range);

    // 构建可选索引列表（排除最近10次使用过的颜色）
    const availableIndices: number[] = [];
    for (let i = minIndex; i <= maxIndex; i++) {
      // 检查该索引是否在最近10次历史中
      if (!CardService.recentColorIndices.includes(i)) {
        availableIndices.push(i);
      }
    }

    // 如果有可用的索引，从中随机选择
    if (availableIndices.length > 0) {
      const randomIndex = Math.floor(Math.random() * availableIndices.length);
      CardService.lastColorIndex = availableIndices[randomIndex];
    } else {
      // 如果没有可用的索引（极端情况：范围内所有颜色都在最近10次内使用过）
      // 从范围内除当前颜色外随机选择
      let newIndex = CardService.lastColorIndex;
      const rangeSize = maxIndex - minIndex + 1;
      if (rangeSize > 1) {
        while (newIndex === CardService.lastColorIndex) {
          const randomOffset = Math.floor(Math.random() * rangeSize);
          newIndex = minIndex + randomOffset;
        }
        CardService.lastColorIndex = newIndex;
      }
    }

    // 记录到历史
    CardService.addToHistory(CardService.lastColorIndex);
    return colors[CardService.lastColorIndex];
  }

  // 将索引添加到历史记录
  private static addToHistory(index: number): void {
    // 添加新索引到开头
    CardService.recentColorIndices.unshift(index);

    // 保持历史记录不超过10个
    if (CardService.recentColorIndices.length > CardService.MAX_HISTORY_SIZE) {
      CardService.recentColorIndices.pop();
    }

    //console.log(`颜色历史记录: [${CardService.recentColorIndices.join(', ')}]`);
  }

  // 生成卡片样式
  static generateCardStyle(quote: Quote): CardStyle {
    // 总是动态生成，不使用缓存
    const textLength = quote.text.length;

    // 如果quote有建议的背景色，优先使用；否则随机选择
    let backgroundColor: string;
    if (quote.bg_color) {
      const originalColor = quote.bg_color;
      backgroundColor = CardService.adjustBrightnessIfNeeded(originalColor);

      if (backgroundColor !== originalColor) {
        console.debug(`自动调暗背景色: ${originalColor} -> ${backgroundColor}, 理由: ${quote.bg_color_reason || '无'}`);
      } else {
        console.debug(`使用建议背景色: ${backgroundColor}, 理由: ${quote.bg_color_reason || '无'}`);
      }
    } else {
      backgroundColor = CardService.selectBackgroundColor();
      console.debug(`使用随机背景色: ${backgroundColor}`);
    }

    const textColor = CardService.calculateOptimalTextColor(backgroundColor);
    const fontSize = CardService.calculateOptimalFontSize(textLength);

    console.debug(`生成卡片样式 - 文本长度: ${textLength}, 字体大小: ${fontSize}`);

    let style: CardStyle = {
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
      fontFamily: 'HarmonyOS Sans',
      textAlign: 'center',
      backgroundOpacity: 1.0
    };

    return style;
  }

  // 根据背景颜色计算最佳文字颜色
  private static calculateOptimalTextColor(backgroundColor: string): string {
    // 使用统一的亮度计算方法
    const luminance = CardService.calculateLuminance(backgroundColor);

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
      const hue = CardService.calculateHue(r, g, b);

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

  /**
   * RGB转HSL
   */
  private static rgbToHsl(r: number, g: number, b: number): HSLColor {
    r /= 255;
    g /= 255;
    b /= 255;

    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    let h = 0, s = 0, l = (max + min) / 2;

    if (max === min) {
      h = s = 0; // 灰色
    } else {
      const d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

      switch (max) {
        case r: h = (g - b) / d + (g < b ? 6 : 0); break;
        case g: h = (b - r) / d + 2; break;
        case b: h = (r - g) / d + 4; break;
      }
      h /= 6;
    }

    return {h, s, l};
  }

  /**
   * HSL转RGB
   */
  private static hslToRgb(h: number, s: number, l: number): RGBColor {
    let r: number, g: number, b: number;

    if (s === 0) {
      r = g = b = l; // 灰色
    } else {
      const hue2rgb = (p: number, q: number, t: number) => {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1/6) return p + (q - p) * 6 * t;
        if (t < 1/2) return q;
        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
        return p;
      };

      const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      const p = 2 * l - q;
      r = hue2rgb(p, q, h + 1/3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1/3);
    }

    return {
      r: Math.round(r * 255),
      g: Math.round(g * 255),
      b: Math.round(b * 255)
    };
  }

  /**
   * 调整颜色亮度至目标范围
   * 如果HSL明度超过0.15，则线性映射到[0.15, 0.2]范围内
   */
  private static adjustBrightnessIfNeeded(hexColor: string): string {
    // 提取RGB分量
    const hex = hexColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);

    // 转换为HSL
    const hsl = CardService.rgbToHsl(r, g, b);
    const originalL = hsl.l;

    // 如果明度超过0.15，则调整
    if (originalL > 0.15) {
      // 线性映射参数
      const minThresholdL = 0.15;  // 输入的最小阈值
      const maxThresholdL = 1.0;   // 输入的最大阈值
      const minTargetL = 0.15;     // 输出的最小值
      const maxTargetL = 0.2;      // 输出的最大值

      // 线性映射公式
      const targetL = minTargetL + (originalL - minThresholdL) / (maxThresholdL - minThresholdL) * (maxTargetL - minTargetL);
      hsl.l = targetL;

      // 转回RGB
      const newRgb = CardService.hslToRgb(hsl.h, hsl.s, hsl.l);

      // 转回hex
      const newHex = `#${newRgb.r.toString(16).padStart(2, '0')}${newRgb.g.toString(16).padStart(2, '0')}${newRgb.b.toString(16).padStart(2, '0')}`;

      return newHex;
    }

    return hexColor; // 不需要调整
  }

  // 生成卡片
  static async generateCard(quote?: Quote): Promise<Card> {
    // 如果没有提供quote，返回错误
    if (!quote) {
      console.error('generateCard: 未提供quote');
      quote = { text: '生活就像海洋，只有意志坚强的人，才能到达彼岸。', author: '马克思', category: '励志' };
    }

    // 总是重新生成样式，不使用缓存
    const style = CardService.generateCardStyle(quote);

    const card: Card = {
      quote: quote,
      style,
      createdAt: new Date()
    };

    // 这里应该生成实际的图片文件
    // 在HarmonyOS中可以使用Canvas API或者图片处理库
    card.imagePath = await CardService.generateImageFile(card);

    return card;
  }

  // 生成图片文件（占位实现）
  private static async generateImageFile(card: Card): Promise<string> {
    // 目前仅返回模拟路径，实际图片生成功能未实现
    const timestamp = Date.now();
    return `cards/quote_card_${timestamp}.png`;
  }

  // 获取当前卡片
  static async getCurrentCard(): Promise<Card | null> {
    // 目前未实现持久化存储
    return null;
  }

  // ============== 从 CardUIService 合并的导出功能 ==============

  /**
   * 获取卡片的背景颜色
   */
  static getCardBackgroundColor(card: Card | null): string {
    if (card?.style?.backgroundColor) {
      return card.style.backgroundColor;
    }
    return '#2c3e50'; // 默认背景色
  }

  /**
   * 导出卡片（设置锁屏和/或保存到相册）
   */
  static async exportCard(params: CardExportParams): Promise<CardOperationResult> {
    if (!params.setAsLockScreen && !params.saveToGallery) {
      return {
        success: false,
        message: '未选择任何操作'
      };
    }

    try {
      console.log('开始导出卡片操作...');

      // 如果需要保存到相册，先请求权限
      if (params.saveToGallery) {
        const permissionResult = await CardService.requestGalleryPermissions(params.context);
        if (!permissionResult.success) {
          return permissionResult;
        }
      }

      // 截图并处理
      return await CardService.captureAndExportCard(params);

    } catch (error) {
      console.error('导出卡片失败:', error);
      return {
        success: false,
        message: '导出卡片失败'
      };
    }
  }

  /**
   * 请求相册权限
   */
  private static async requestGalleryPermissions(context: common.UIAbilityContext): Promise<CardOperationResult> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = [
      'ohos.permission.WRITE_IMAGEVIDEO',
      'ohos.permission.READ_IMAGEVIDEO'
    ];

    try {
      const data = await atManager.requestPermissionsFromUser(context, permissions);
      const grantStatus: Array<number> = data.authResults;
      let allGranted: boolean = true;

      for (let i = 0; i < grantStatus.length; i++) {
        if (grantStatus[i] !== 0) {
          allGranted = false;
          console.error(`权限 ${permissions[i]} 被拒绝`);
        }
      }

      if (!allGranted) {
        return {
          success: false,
          message: '需要存储权限才能保存图片，请到设置中开启'
        };
      }

      return { success: true, message: '' };

    } catch (err) {
      const error = err as BusinessError;
      console.error(`请求权限失败: ${error.message}`);
      return {
        success: false,
        message: '请求权限失败'
      };
    }
  }

  /**
   * 截图并导出卡片
   */
  private static async captureAndExportCard(params: CardExportParams): Promise<CardOperationResult> {
    return new Promise((resolve) => {
      componentSnapshot.get("exportableCardArea", async (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          console.error("截图失败: " + JSON.stringify(error));
          resolve({
            success: false,
            message: '截图失败'
          });
          return;
        }

        try {
          const tempImagePath = await CardService.savePixelMapToTempFile(pixelMap, params.context);
          const result = await CardService.performExportOperations(tempImagePath, params);

          // 清理临时文件
          try {
            await fs.unlink(tempImagePath);
          } catch (unlinkError) {
            console.error('清理临时文件失败:', unlinkError);
          }

          pixelMap.release();
          resolve(result);

        } catch (packError) {
          console.error('图片处理失败:', packError);
          pixelMap.release();
          resolve({
            success: false,
            message: '图片处理失败'
          });
        }
      });
    });
  }

  /**
   * 将PixelMap保存为临时文件
   */
  private static async savePixelMapToTempFile(
    pixelMap: image.PixelMap,
    context: common.UIAbilityContext
  ): Promise<string> {
    const packOpts: image.PackingOption = {
      format: "image/jpeg",
      quality: 98
    };

    const imagePacker: image.ImagePacker = image.createImagePacker();
    const arrayBuffer: ArrayBuffer = await imagePacker.packing(pixelMap, packOpts);

    const filesDir: string = context.filesDir;
    const tempImagePath = `${filesDir}/temp_card_${Date.now()}.jpg`;

    const file = await fs.open(tempImagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    await fs.write(file.fd, arrayBuffer);
    await fs.close(file.fd);

    imagePacker.release();
    return tempImagePath;
  }

  /**
   * 执行导出操作
   */
  private static async performExportOperations(
    imagePath: string,
    params: CardExportParams
  ): Promise<CardOperationResult> {
    let lockScreenSuccess = false;
    let gallerySuccess = false;
    let messages: string[] = [];

    if (params.setAsLockScreen) {
      lockScreenSuccess = await CardService.setAsLockScreenWallpaper(imagePath, params.context);
      messages.push(lockScreenSuccess ? '锁屏壁纸设置成功！' : '锁屏壁纸设置失败！');
    }

    if (params.saveToGallery) {
      gallerySuccess = await CardService.saveImageToGallery(imagePath, params.context);
      messages.push(gallerySuccess ? '图片已保存到图库！' : '图片保存到图库失败！');
    }

    const success = (!params.setAsLockScreen || lockScreenSuccess) &&
                   (!params.saveToGallery || gallerySuccess);

    return {
      success,
      message: messages.join('\n'),
      lockScreenSuccess,
      gallerySuccess
    };
  }

  /**
   * 设置为锁屏壁纸
   */
  private static async setAsLockScreenWallpaper(
    imagePath: string,
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const grantStatus = await atManager.checkAccessToken(
        context.applicationInfo.accessTokenId,
        'ohos.permission.SET_WALLPAPER'
      );

      if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.warn('SET_WALLPAPER permission not granted');
      }

      const stat = await fileIo.stat(imagePath);
      console.info("File size: " + stat.size);

      await wallpaper.setWallpaper(imagePath, wallpaper.WallpaperType.WALLPAPER_LOCKSCREEN);
      console.log('Lock screen wallpaper set successfully');
      return true;
    } catch (error) {
      console.error('Failed to set lock screen wallpaper:', error);
      return false;
    }
  }

  /**
   * 保存图片到相册
   */
  private static async saveImageToGallery(
    imagePath: string,
    context: common.UIAbilityContext
  ): Promise<boolean> {
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri: string = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      const sourceFile = await fileIo.open(imagePath, fileIo.OpenMode.READ_ONLY);
      const stat = await fileIo.stat(imagePath);
      const buffer = new ArrayBuffer(stat.size);
      await fileIo.read(sourceFile.fd, buffer);
      await fileIo.close(sourceFile);

      const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.write(file.fd, buffer);
      await fileIo.close(file.fd);

      console.log('Image saved to gallery successfully');
      return true;
    } catch (error) {
      console.error('Failed to save image to gallery:', error);
      return false;
    }
  }

  // ============== 从 CardPageService 合并的列表管理功能 ==============

  private static textLayoutService: TextLayoutService | null = null;
  private static usedQuoteTexts: Set<string> = new Set();
  private static screenWidth: number = 0;
  private static screenHeight: number = 0;

  /**
   * 初始化页面服务
   */
  static initPageService(screenWidth: number, screenHeight: number): void {
    CardService.screenWidth = screenWidth;
    CardService.screenHeight = screenHeight;
    CardService.textLayoutService = new TextLayoutService(screenWidth, screenHeight);
  }

  /**
   * 计算动态容器宽度
   */
  static calculateDynamicContainerWidth(fontSize: number): number {
    const parentPadding = 48;
    const safetyMargin = fontSize * 5;
    const rawContainerWidth = CardService.screenWidth - parentPadding - safetyMargin;
    return Math.max(rawContainerWidth, 200);
  }

  /**
   * 处理单个名言
   */
  static async processQuote(quote: Quote, params: ProcessQuoteParams): Promise<void> {
    // 直接使用传入的quote，不使用预生成数据
    const card = await CardService.generateCard(quote);

    params.cardViewerDataSource.pushItem(card);
    CardService.usedQuoteTexts.add(quote.text);
    const quoteFontSize = card?.style.fontSize || 24;
    const quoteContainerWidth = CardService.calculateDynamicContainerWidth(quoteFontSize);
    const quoteLayout = CardService.formatQuoteText(quote.text, quoteFontSize, quoteContainerWidth);
    params.optimizedFontSizes.push(quoteLayout.fontSize);
  }

  /**
   * 格式化名言文本
   */
  static formatQuoteText(text: string, fontSize?: number, containerWidth?: number): TextLayoutResult {
    if (!fontSize || !containerWidth || !CardService.textLayoutService) {
      const simpleFormatted = TextUtils.applySimpleTextFormatting(text);

      return {
        text: simpleFormatted,
        fontSize: fontSize || 24,
        lines: simpleFormatted.split('\n')
      };
    }

    try {
      const result = CardService.textLayoutService.optimizeLayout(text, containerWidth, fontSize);
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

  /**
   * 初始化名言列表
   */
  static async initializeQuoteList(params: QuoteListInitParams): Promise<QuoteListInitResult> {
    try {
      console.log(`=== 初始化名言列表 ===`);
      console.log(`屏幕宽度: ${CardService.screenWidth}px, 屏幕高度: ${CardService.screenHeight}px`);

      const parentPadding = 48; // 左右各24px

      console.log(`屏幕宽度: ${CardService.screenWidth}px`);
      console.log(`父容器padding: ${parentPadding}px`);

      // 如果没有当前卡片，使用推荐系统获取第一个
      if (!params.currentCard) {
        const recommendedQuotes = await QuoteSelectionService.getRecommendedQuotes(1, CardService.usedQuoteTexts);
        if (recommendedQuotes && recommendedQuotes.length > 0) {
          const quote = recommendedQuotes[0];
          CardService.usedQuoteTexts.add(quote.text);
          params.currentCard = await CardService.generateCard(quote);
        } else {
          // 如果推荐系统也失败，使用默认名言
          const defaultQuote: Quote = {
            text: "一切群众的实际生活问题，都是我们应当注意的问题",
            author: "毛泽东",
            category: "群众",
            source: "《关心群众生活，注意工作方法》"
          };
          params.currentCard = await CardService.generateCard(defaultQuote);
        }
      }

      // 加载当前卡片
      params.cardViewerDataSource.pushItem(params.currentCard);

      // 预处理当前名言的字体大小
      const initialFontSize = params.currentCard?.style.fontSize || 24;
      console.log(`使用初始字体大小: ${initialFontSize}px`);

      // 重新计算基于字体大小的安全边距和容器宽度
      const dynamicContainerWidth = CardService.calculateDynamicContainerWidth(initialFontSize);

      console.log(`动态安全边距: ${initialFontSize * 5}px (基于字体${initialFontSize}px)`);
      console.log(`动态容器宽度: ${dynamicContainerWidth}px`);

      const textLayout = CardService.formatQuoteText(params.currentCard.quote.text, initialFontSize, dynamicContainerWidth);
      params.optimizedFontSizes.push(textLayout.fontSize);

      console.log(`=== 当前quote处理完成 ===`);
      console.log(`优化后字体大小: ${textLayout.fontSize}px`);
      console.log(`优化后文本:\n${textLayout.text}`);

      // 一次性加载所有名言（99条，加上当前的1条共100条）
      console.log(`=== 开始加载所有名言 ===`);
      let loadedCount = 0;
      const targetCount = 99; // 加上当前的1条，总共100条

      // 从推荐系统加载99条名言
      console.log(`当前已使用名言数量: ${CardService.usedQuoteTexts.size}`);
      const moreQuotes = await QuoteSelectionService.getRecommendedQuotes(targetCount, CardService.usedQuoteTexts);
      console.log(`获取到 ${moreQuotes?.length || 0} 条新名言`);
      if (moreQuotes && moreQuotes.length > 0) {
        for (const quote of moreQuotes) {
          const processParams: ProcessQuoteParams = {
            cardViewerDataSource: params.cardViewerDataSource,
            optimizedFontSizes: params.optimizedFontSizes
          };
          await CardService.processQuote(quote, processParams);
          loadedCount++;
        }
      }
      console.log(`加载了${loadedCount}条名言，加上当前名言共${loadedCount + 1}条`);

      const result: QuoteListInitResult = { card: params.currentCard };
      return result;
    } catch (error) {
      console.error('Failed to initialize quote list:', error);
      const result: QuoteListInitResult = { card: params.currentCard };
      return result;
    }
  }


  /**
   * 获取已使用的名言文本集合
   */
  static getUsedQuoteTexts(): Set<string> {
    return CardService.usedQuoteTexts;
  }

  /**
   * 添加已使用的名言文本
   */
  static addUsedQuoteText(text: string): void {
    CardService.usedQuoteTexts.add(text);
  }

  /**
   * 清空已使用的名言文本集合
   */
  static clearUsedQuoteTexts(): void {
    CardService.usedQuoteTexts.clear();
    console.log('已清空已使用名言文本缓存');
  }
}