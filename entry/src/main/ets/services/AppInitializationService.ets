// 应用初始化服务
import { Quote } from '../common/QuoteData';
import { QuoteSelectionService } from './QuoteSelectionService';
import { CardService, Card } from './CardService';
import { ScheduleConfig, WallpaperConfig } from '../common/ScheduleConfig';
import { ScreenInfo, CurrentCardResult, AppInitResult } from '../common/ServiceTypes';
import display from '@ohos.display';
import common from '@ohos.app.ability.common';

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

  // 加载当前卡片
  async loadCurrentCard(config?: WallpaperConfig | null): Promise<CurrentCardResult> {
    const currentCard = await CardService.getCurrentCard();
    let currentQuote: Quote | null = null;

    if (!currentCard && config) {
      try {
        const selectedQuote = await QuoteSelectionService.selectQuote(config.selectionAlgorithm);
        currentQuote = selectedQuote;
        const card = await CardService.generateCard(selectedQuote);
        const result: CurrentCardResult = { quote: currentQuote, card: card };
        return result;
      } catch (error) {
        console.error('Failed to load initial card:', error);
      }
    }

    const result: CurrentCardResult = { quote: currentQuote, card: currentCard };
    return result;
  }

  // 加载名言数据源并初始化预生成数据
  async loadQuoteSource(context?: common.UIAbilityContext): Promise<void> {
    try {
      const QuoteDataModule = await import('../common/QuoteData');
      await QuoteDataModule.QuoteData.loadQuoteSource(context);

    } catch (error) {
      console.error('Failed to load quote source:', error);
    }
  }

  // 完整的应用初始化流程
  async initializeApp(context?: common.UIAbilityContext): Promise<AppInitResult> {
    // 确保屏幕尺寸首先被正确获取
    const screenInfo = await this.getScreenRatio();

    // 如果屏幕尺寸获取失败，使用默认值
    if (screenInfo.width === 0 || screenInfo.height === 0) {
      screenInfo.width = 360;
      screenInfo.height = 640;
    }

    // 加载配置
    const config = await this.loadConfig();

    // 加载名言数据源
    await this.loadQuoteSource(context);

    // 加载当前卡片和名言
    const cardResult = await this.loadCurrentCard(config);
    const currentQuote = cardResult.quote;
    const currentCard = cardResult.card;

    const result: AppInitResult = {
      screenInfo,
      config,
      currentQuote,
      currentCard
    };
    return result;
  }
}