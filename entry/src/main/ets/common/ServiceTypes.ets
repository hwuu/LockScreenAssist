// 服务类型定义
import { Quote } from './QuoteData';
import { GeneratedWallpaper } from '../services/WallpaperService';
import { WallpaperConfig } from './ScheduleConfig';

// 屏幕信息接口
export interface ScreenInfo {
  width: number;
  height: number;
  ratio: number;
}

// 当前壁纸和名言结果接口
export interface CurrentWallpaperResult {
  quote: Quote | null;
  wallpaper: GeneratedWallpaper | null;
}

// 应用初始化结果接口
export interface AppInitResult {
  screenInfo: ScreenInfo;
  config: WallpaperConfig | null;
  currentQuote: Quote | null;
  currentWallpaper: GeneratedWallpaper | null;
}

// 名言列表初始化结果接口
export interface QuoteListInitResult {
  quote: Quote | null;
  wallpaper: GeneratedWallpaper | null;
}

// 操作结果接口
export interface OperationResult {
  success: boolean;
  message: string;
}