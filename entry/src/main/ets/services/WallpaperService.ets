// 壁纸生成和管理服务
import { Quote } from '../common/QuoteData';
import { wallpaper, BusinessError } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

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

export class WallpaperService {
  private static readonly WALLPAPER_STORAGE_KEY = "current_wallpaper";

  // 生成壁纸样式
  static generateWallpaperStyle(quote: Quote): WallpaperStyle {
    const textLength = quote.text.length;

    // 深色系、高级感背景色调色板
    const darkBackgrounds = [
      // 经典深色系 - 优雅沉稳
      '#1a1a2e', // 深夜蓝
      '#16213e', // 深海军蓝
      '#0f3460', // 深钴蓝
      '#1e2124', // 深炭黑
      '#2c2f33', // 深石墨灰
      '#23272a', // 深板岩灰
      '#36393f', // 深灰蓝

      // 高级灰系 - 现代简约
      '#4a5568', // 时尚灰
      '#2d3748', // 深青灰
      '#1a202c', // 深墨灰
      '#171923', // 深夜墨
      '#2b2d3a', // 深紫灰
      '#313540', // 深钢灰
      '#3d4852', // 深暖灰

      // 深蓝系 - 商务高端
      '#1e3a8a', // 深宝石蓝
      '#1e40af', // 深皇家蓝
      '#1d4ed8', // 深钴蓝
      '#2563eb', // 深蓝
      '#1e293b', // 深青钢蓝
      '#0f172a', // 深午夜蓝
      '#020617', // 极深蓝

      // 深紫系 - 神秘优雅
      '#581c87', // 深紫罗兰
      '#6b21a8', // 深紫
      '#7c2d12', // 深紫红
      '#4c1d95', // 深靛紫
      '#5b21b6', // 深葡萄紫
      '#6d28d9', // 深紫蓝
      '#553c9a', // 深薰衣草紫

      // 深绿系 - 自然沉静
      '#14532d', // 深森林绿
      '#166534', // 深翡翠绿
      '#15803d', // 深绿
      '#16a34a', // 深草绿
      '#0d9488', // 深青绿
      '#0f766e', // 深海绿
      '#134e4a', // 深墨绿

      // 深棕系 - 温暖厚重
      '#78350f', // 深琥珀棕
      '#92400e', // 深橙棕
      '#a16207', // 深金棕
      '#a97817', // 深黄棕
      '#713f12', // 深木棕
      '#451a03', // 深咖啡棕
      '#3c2a1e', // 深巧克力棕

      // 深红系 - 典雅庄重
      '#7f1d1d', // 深酒红
      '#991b1b', // 深红
      '#b91c1c', // 深朱红
      '#dc2626', // 深鲜红
      '#9f1239', // 深玫瑰红
      '#881337', // 深粉红
      '#701a75', // 深紫红

      // 特殊深色系 - 独特气质
      '#1c1917', // 深石灰
      '#292524', // 深暖石
      '#44403c', // 深沙石
      '#57534e', // 深米灰
      '#0c4a6e', // 深天蓝
      '#075985', // 深海蓝
      '#0369a1', // 深湖蓝
      '#0284c7', // 深天空蓝

      // 现代深色系 - 科技感
      '#111827', // 深科技灰
      '#1f2937', // 深炭蓝
      '#374151', // 深冷灰
      '#4b5563', // 深中性灰
      '#6b7280', // 深银灰
      '#18181b', // 极深黑
      '#27272a', // 深锌灰
      '#3f3f46'  // 深铁灰
    ];

    // 随机选择深色背景
    const randomBackground = darkBackgrounds[Math.floor(Math.random() * darkBackgrounds.length)];

    // 根据背景颜色自动调整文字颜色以确保可读性
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
    // 将十六进制颜色转换为RGB值
    const hex = backgroundColor.replace('#', '');
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);

    // 计算亮度 (使用 WCAG 2.1 相对亮度公式)
    const getRGBLuminance = (value: number) => {
      const normalized = value / 255;
      return normalized <= 0.03928
        ? normalized / 12.92
        : Math.pow((normalized + 0.055) / 1.055, 2.4);
    };

    const luminance = 0.2126 * getRGBLuminance(r) +
                     0.7152 * getRGBLuminance(g) +
                     0.0722 * getRGBLuminance(b);

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

  // 生成壁纸
  static async generateWallpaper(quote: Quote): Promise<GeneratedWallpaper> {
    const style = WallpaperService.generateWallpaperStyle(quote);

    const wallpaper: GeneratedWallpaper = {
      quote,
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