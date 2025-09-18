// 应用初始化服务
import { Quote } from '../common/QuoteData';
import { QuoteSelectionService } from './QuoteSelectionService';
import { WallpaperService, GeneratedWallpaper } from './WallpaperService';
import { ScheduleConfig, WallpaperConfig } from '../common/ScheduleConfig';
import { ScreenInfo, CurrentWallpaperResult, AppInitResult } from '../common/ServiceTypes';
import display from '@ohos.display';

export class AppInitializationService {
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private screenRatio: number = 16/9;

  // 获取屏幕比例和尺寸
  async getScreenRatio(): Promise<ScreenInfo> {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      // 计算竖屏比例（高度/宽度）
      this.screenRatio = defaultDisplay.height / defaultDisplay.width;
      this.screenWidth = defaultDisplay.width;
      this.screenHeight = defaultDisplay.height;
      console.log(`Screen ratio: ${this.screenRatio} (${defaultDisplay.width}x${defaultDisplay.height})`);

      const result: ScreenInfo = {
        width: this.screenWidth,
        height: this.screenHeight,
        ratio: this.screenRatio
      };
      return result;
    } catch (error) {
      console.error('Failed to get screen ratio:', error);
      this.screenRatio = 16/9; // 保持默认比例
      this.screenWidth = 360;
      this.screenHeight = 640;

      const result: ScreenInfo = {
        width: this.screenWidth,
        height: this.screenHeight,
        ratio: this.screenRatio
      };
      return result;
    }
  }

  // 加载应用配置
  async loadConfig(): Promise<WallpaperConfig | null> {
    try {
      const config = await ScheduleConfig.getConfig();
      return config;
    } catch (error) {
      console.error('Failed to load config:', error);
      return null;
    }
  }

  // 加载当前壁纸
  async loadCurrentWallpaper(config?: WallpaperConfig | null): Promise<CurrentWallpaperResult> {
    const currentWallpaper = await WallpaperService.getCurrentWallpaper();
    let currentQuote: Quote | null = null;

    if (!currentWallpaper && config) {
      try {
        const selectedQuote = await QuoteSelectionService.selectQuote(config.selectionAlgorithm);
        currentQuote = selectedQuote;
        const wallpaper = await WallpaperService.generateWallpaper(selectedQuote);
        const result: CurrentWallpaperResult = { quote: currentQuote, wallpaper: wallpaper };
        return result;
      } catch (error) {
        console.error('Failed to load initial wallpaper:', error);
      }
    }

    const result: CurrentWallpaperResult = { quote: currentQuote, wallpaper: currentWallpaper };
    return result;
  }

  // 加载名言数据源
  async loadQuoteSource(): Promise<void> {
    try {
      const QuoteDataModule = await import('../common/QuoteData');
      await QuoteDataModule.QuoteData.loadQuoteSource();
    } catch (error) {
      console.error('Failed to load quote source in Index:', error);
    }
  }

  // 完整的应用初始化流程
  async initializeApp(): Promise<AppInitResult> {
    // 确保屏幕尺寸首先被正确获取
    const screenInfo = await this.getScreenRatio();

    // 验证屏幕尺寸获取是否成功
    console.log(`aboutToAppear - 屏幕尺寸确认: ${screenInfo.width}x${screenInfo.height}`);

    // 如果屏幕尺寸获取失败，使用默认值
    if (screenInfo.width === 0 || screenInfo.height === 0) {
      console.warn('屏幕尺寸获取失败，使用默认值');
      screenInfo.width = 360;
      screenInfo.height = 640;
    }

    // 加载配置
    const config = await this.loadConfig();

    // 加载名言数据源
    await this.loadQuoteSource();

    // 加载当前壁纸和名言
    const wallpaperResult = await this.loadCurrentWallpaper(config);
    const currentQuote = wallpaperResult.quote;
    const currentWallpaper = wallpaperResult.wallpaper;

    const result: AppInitResult = {
      screenInfo,
      config,
      currentQuote,
      currentWallpaper
    };
    return result;
  }
}