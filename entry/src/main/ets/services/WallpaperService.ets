// 壁纸生成和管理服务
import { Quote } from '../common/QuoteData';

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

export class WallpaperService {
  private static readonly WALLPAPER_STORAGE_KEY = "current_wallpaper";

  // 生成壁纸样式
  static generateWallpaperStyle(quote: Quote): WallpaperStyle {
    const textLength = quote.text.length;

    // 深色系、低对比度、高级感背景色
    const darkBackgrounds = [
      // 深灰蓝系
      '#2c3e50', // 经典深灰蓝
      '#34495e', // 深石板灰
      '#1a252f', // 深夜蓝
      '#273c75', // 深宝蓝
      '#40407a', // 深紫蓝
      '#2d3436', // 深炭灰
      '#636e72', // 中性灰

      // 深绿系
      '#00b894', // 深翠绿
      '#00a085', // 深翡翠
      '#2d3748', // 深灰绿
      '#22543d', // 深森绿
      '#2f855a', // 低调绿
      '#319795', // 深青绿

      // 深紫系
      '#6c5ce7', // 优雅紫
      '#5f3dc4', // 深紫罗兰
      '#553c9a', // 深葡萄紫
      '#44337a', // 深丁香紫
      '#322659', // 深紫灰

      // 深棕系
      '#8b5a2b', // 深焦糖色
      '#744c3e', // 深咖啡色
      '#5d4e37', // 深古铜色
      '#654321', // 深栗色
      '#8b4513', // 深马鞍色

      // 深红系
      '#c0392b', // 深红
      '#a93226', // 深紫红
      '#922b21', // 深酒红
      '#7b241c', // 深栗红
      '#641e16', // 深棕红

      // 特殊深色
      '#2c2c54', // 深鬼紫
      '#474787', // 灰紫蓝
      '#40739e', // 深钢蓝
      '#487eb0', // 低调蓝
      '#8c7851', // 深古金
      '#596275', // 深灰青
      '#1e3799', // 深皇家蓝
      '#3c6382', // 深海蓝
      '#40514e'  // 深石青
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

    // 计算亮度 (使用 WCAG 2.0 公式)
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;

    // 根据背景亮度选择文字颜色，提高对比度
    if (brightness > 155) {
      // 亮背景使用深色文字
      return '#1a202c';
    } else if (brightness > 100) {
      // 中等亮度背景使用高对比度深色文字
      return '#ffffff';
    } else if (brightness > 60) {
      // 偏暗背景使用纯白文字
      return '#ffffff';
    } else {
      // 深色背景使用高亮度白色文字
      return '#f8f9fa';
    }
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
      // 使用wallpaper模块设置锁屏壁纸
      // 注意：实际API可能需要根据HarmonyOS版本调整
      console.log('Setting lock screen wallpaper:', imagePath);

      // 模拟设置成功，实际项目中需要调用真实的系统API
      // const wallpaper = require('@ohos.wallpaper');
      // await wallpaper.setWallpaper(imagePath, wallpaper.WallpaperType.WALLPAPER_LOCKSCREEN);

      console.log('Lock screen wallpaper set successfully (simulated):', imagePath);
      return true;
    } catch (error) {
      console.error('Failed to set lock screen wallpaper:', error);
      return false;
    }
  }

  // 保存到系统图库
  static async saveToGallery(imagePath: string): Promise<boolean> {
    try {
      console.log('Attempting to save image to gallery:', imagePath);

      // 模拟保存到图库的操作
      // 在实际项目中，这里应该使用PhotoAccessHelper API
      // const photoAccessHelper = require('@ohos.file.photoAccessHelper');
      // const helper = photoAccessHelper.getPhotoAccessHelper(context);
      // await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');

      console.log('Image saved to gallery successfully (simulated):', imagePath);
      return true;
    } catch (error) {
      console.error('Failed to save image to gallery:', error);
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