// 名言选择服务
import { Quote, QuoteData } from '../common/QuoteData';
import { SelectionAlgorithm } from '../common/ScheduleConfig';

export interface WeatherInfo {
  condition: string; // sunny, cloudy, rainy, snowy, etc.
  temperature: number;
}

export interface TimeContext {
  hour: number;
  month: number;
  season: string;
  isWeekend: boolean;
}

export interface ScoredQuote {
  quote: Quote;
  score: number;
}

export class QuoteSelectionService {
  
  // 获取当前季节
  static getCurrentSeason(): string {
    const month = new Date().getMonth() + 1;
    if (month >= 3 && month <= 5) return '春';
    if (month >= 6 && month <= 8) return '夏';
    if (month >= 9 && month <= 11) return '秋';
    return '冬';
  }

  // 获取时间上下文
  static getTimeContext(): TimeContext {
    const now = new Date();
    const hour = now.getHours();
    const month = now.getMonth() + 1;
    const day = now.getDay();
    
    return {
      hour,
      month,
      season: QuoteSelectionService.getCurrentSeason(),
      isWeekend: day === 0 || day === 6
    };
  }

  // 模拟获取天气信息（实际应用中应该调用天气API）
  static async getWeatherInfo(): Promise<WeatherInfo> {
    // 这里应该调用真实的天气API
    // 为了演示，返回随机天气
    const conditions = ['sunny', 'cloudy', 'rainy', 'snowy', 'hot', 'cold'];
    const condition = conditions[Math.floor(Math.random() * conditions.length)];
    const temperature = Math.floor(Math.random() * 40) - 10; // -10°C 到 30°C
    
    return {
      condition,
      temperature
    };
  }

  // 根据算法选择名言
  static async selectQuote(algorithm: SelectionAlgorithm): Promise<Quote> {
    console.log('QuoteSelectionService.selectQuote 开始, algorithm:', algorithm);
    let result: Quote;
    switch (algorithm) {
      case SelectionAlgorithm.RANDOM:
        result = QuoteSelectionService.selectRandomQuote();
        break;

      case SelectionAlgorithm.SEQUENTIAL:
        result = QuoteSelectionService.selectSequentialQuote();
        break;

      case SelectionAlgorithm.SMART:
        result = await QuoteSelectionService.selectSmartQuote();
        break;

      default:
        result = QuoteSelectionService.selectRandomQuote();
        break;
    }
    console.log('QuoteSelectionService.selectQuote 完成, quote:', result?.text || 'null');
    return result;
  }

  // 随机选择
  private static selectRandomQuote(): Quote {
    console.log('QuoteSelectionService.selectRandomQuote 开始');
    const quote = QuoteData.getRandomQuote();
    console.log('QuoteSelectionService.selectRandomQuote 完成, quote:', quote?.text || 'null');
    return quote;
  }

  // 顺序选择
  private static selectSequentialQuote(): Quote {
    // 实现顺序选择逻辑
    const allQuotes = QuoteData.getAllQuotes();
    const currentIndex = QuoteSelectionService.getSequentialIndex();
    const nextIndex = (currentIndex + 1) % allQuotes.length;
    QuoteSelectionService.setSequentialIndex(nextIndex);
    return allQuotes[currentIndex];
  }

  // 获取顺序索引
  private static getSequentialIndex(): number {
    // 在实际实现中应该从存储中读取
    return Math.floor(Date.now() / 1000) % QuoteData.getAllQuotes().length;
  }

  // 设置顺序索引
  private static setSequentialIndex(index: number): void {
    // 在实际实现中应该保存到存储中
    console.log(`Sequential index set to: ${index}`);
  }

  // 根据季节选择
  private static selectSeasonalQuote(): Quote {
    const season = QuoteSelectionService.getCurrentSeason();
    const seasonalQuotes = QuoteData.getQuotesBySeason(season);
    
    if (seasonalQuotes.length === 0) {
      return QuoteData.getRandomQuote();
    }
    
    return seasonalQuotes[Math.floor(Math.random() * seasonalQuotes.length)];
  }

  // 根据天气选择
  private static async selectWeatherBasedQuote(): Promise<Quote> {
    try {
      const weather = await QuoteSelectionService.getWeatherInfo();
      const weatherQuotes = QuoteData.getQuotesByWeather(weather.condition);
      
      if (weatherQuotes.length === 0) {
        return QuoteData.getRandomQuote();
      }
      
      return weatherQuotes[Math.floor(Math.random() * weatherQuotes.length)];
    } catch (error) {
      console.error('Failed to get weather info:', error);
      return QuoteData.getRandomQuote();
    }
  }

  // 智能选择（综合考虑多个因素）
  private static async selectSmartQuote(): Promise<Quote> {
    try {
      const timeContext = QuoteSelectionService.getTimeContext();
      const weather = await QuoteSelectionService.getWeatherInfo();
      
      // 智能评分系统
      const allQuotes = QuoteData.getAllQuotes();
      const scoredQuotes: ScoredQuote[] = allQuotes.map(quote => {
        const scoredQuote: ScoredQuote = {
          quote: quote,
          score: QuoteSelectionService.calculateQuoteScore(quote, timeContext, weather)
        };
        return scoredQuote;
      });

      // 按分数排序
      scoredQuotes.sort((a, b) => b.score - a.score);
      
      // 从前30%的高分名言中随机选择
      const topQuotes = scoredQuotes.slice(0, Math.max(1, Math.floor(scoredQuotes.length * 0.3)));
      const selectedQuote = topQuotes[Math.floor(Math.random() * topQuotes.length)];
      
      return selectedQuote.quote;
    } catch (error) {
      console.error('Smart selection failed:', error);
      return QuoteData.getRandomQuote();
    }
  }

  // 计算名言适合度评分
  private static calculateQuoteScore(quote: Quote, timeContext: TimeContext, weather: WeatherInfo): number {
    let score = 50; // 基础分数

    // 季节匹配加分
    if (quote.season === timeContext.season) {
      score += 30;
    }

    // 天气匹配加分
    if (quote.weather === weather.condition) {
      score += 25;
    }

    // 时间段适配
    if (timeContext.hour >= 6 && timeContext.hour < 12) {
      // 上午：偏好励志类
      if (quote.category === '励志') score += 15;
    } else if (timeContext.hour >= 12 && timeContext.hour < 18) {
      // 下午：偏好智慧类
      if (quote.category === '智慧') score += 15;
    } else if (timeContext.hour >= 18 && timeContext.hour < 22) {
      // 晚上：偏好哲理类
      if (quote.category === '哲理') score += 15;
    } else {
      // 深夜/凌晨：偏好诗词类
      if (quote.category === '诗词') score += 15;
    }

    // 周末加分策略
    if (timeContext.isWeekend) {
      if (quote.category === '诗词' || quote.category === '哲理') {
        score += 10;
      }
    }

    // 温度相关调整
    if (weather.temperature > 25 && quote.weather === 'hot') {
      score += 10;
    } else if (weather.temperature < 5 && quote.weather === 'cold') {
      score += 10;
    }

    return score;
  }

  // 获取推荐的名言列表
  static async getRecommendedQuotes(count: number = 5, excludeQuoteTexts?: Set<string>): Promise<Quote[]> {
    const timeContext = QuoteSelectionService.getTimeContext();
    const weather = await QuoteSelectionService.getWeatherInfo();

    const allQuotes = QuoteData.getAllQuotes();

    // 先过滤掉已使用的quotes
    const availableQuotes = excludeQuoteTexts && excludeQuoteTexts.size > 0
      ? allQuotes.filter(quote => !excludeQuoteTexts.has(quote.text))
      : allQuotes;

    // 如果过滤后的quotes不足，记录警告
    if (availableQuotes.length < count) {
      console.warn(`可用quotes不足，需要${count}个，只有${availableQuotes.length}个`);
    }

    const scoredQuotes: ScoredQuote[] = availableQuotes.map(quote => {
      const scoredQuote: ScoredQuote = {
        quote: quote,
        score: QuoteSelectionService.calculateQuoteScore(quote, timeContext, weather) + Math.random() * 10 // 添加随机性
      };
      return scoredQuote;
    });

    scoredQuotes.sort((a, b) => b.score - a.score);

    // 从前50%的高分名言中选择，增加多样性
    const topPercentage = Math.max(count * 2, Math.floor(scoredQuotes.length * 0.5));
    const topQuotes = scoredQuotes.slice(0, topPercentage);

    // 随机打乱顺序
    for (let i = topQuotes.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = topQuotes[i];
      topQuotes[i] = topQuotes[j];
      topQuotes[j] = temp;
    }

    return topQuotes.slice(0, Math.min(count, availableQuotes.length)).map(item => item.quote);
  }
}