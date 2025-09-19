// 服务类型定义
import { Quote } from './QuoteData';
import { GeneratedWallpaper } from '../services/WallpaperService';
import { WallpaperConfig } from './ScheduleConfig';
import { QuoteDataSource } from './QuoteDataSource';
import common from '@ohos.app.ability.common';

// 数据统计信息接口
export interface DataStats {
  shijingCount: number;
  maozedongCount: number;
  totalCount: number;
}

// 文本布局配置接口
export interface TextLayoutConfig {
  MIN_CONTAINER_WIDTH: number;
  SAFETY_MARGIN_MULTIPLIER: number;
  MAX_LINES: number;
}

// 文本布局权重配置接口
export interface TextLayoutWeightsConfig {
  AUTO_WRAP_RATIO: number;
  ORPHAN_LINE_RATIO: number;
  LINE_WIDTH_VARIANCE: number;
  ASPECT_RATIO_DEVIATION: number;
  SPACE_UTILIZATION: number;
  PUNCTUATION_COMPLIANCE: number;
  VISUAL_DENSITY_UNIFORMITY: number;
  VISUAL_FOCUS_DISPERSION: number;
}

// 字体范围配置接口
export interface FontRangeConfig {
  MIN: number;
  MAX: number;
}

// 理想行数范围配置接口
export interface IdealLineRangeConfig {
  MIN: number;
  MAX: number;
}

// 文本优化配置接口
export interface TextOptimizationConfig {
  MAX_ITERATIONS: number;
}

// UI常量配置接口
export interface UIConstantsConfig {
  DEFAULT_SCREEN_RATIO: number;
  ANIMATION_DURATION_LONG: number;
  ANIMATION_DURATION_MEDIUM: number;
  ANIMATION_DURATION_SHORT: number;
  ANIMATION_DURATION_FADE: number;
  LONG_PRESS_DURATION: number;
  SWIPER_CACHED_COUNT: number;
  MAX_LOADED_QUOTES: number;
  PRELOAD_THRESHOLD: number;
  BATCH_LOAD_COUNT: number;
  CONTAINER_PADDING: number;
  CONTAINER_PADDING_TOTAL: number;
  TOP_BAR_HEIGHT: number;
  BUTTON_SIZE: number;
  BUTTON_RADIUS: number;
  DIALOG_BORDER_RADIUS: number;
  LOADING_PROGRESS_SIZE: number;
  LOADING_CONTAINER_SIZE: number;
  DEFAULT_FONT_SIZE: number;
  AUTHOR_FONT_SIZE: number;
  HINT_FONT_SIZE: number;
  TITLE_FONT_SIZE: number;
  SUBTITLE_FONT_SIZE: number;
  TEXT_BOTTOM_MARGIN: number;
  DIALOG_MARGIN: number;
  DIALOG_SECTION_MARGIN: number;
  DIALOG_ITEM_MARGIN: number;
  DEFAULT_BACKGROUND_COLOR: string;
  FALLBACK_BACKGROUND_COLOR: string;
  WHITE_COLOR: string;
  TEXT_GRAY_COLOR: string;
  BORDER_GRAY_COLOR: string;
  DISABLED_GRAY_COLOR: string;
  PRIMARY_BLUE_COLOR: string;
  DARK_TEXT_COLOR: string;
  MEDIUM_GRAY_COLOR: string;
  AUTHOR_TEXT_OPACITY: number;
  LOADING_OVERLAY_OPACITY: number;
  DIALOG_BACKGROUND_OPACITY: number;
  PURE_WALLPAPER_OFFSET_X: number;
  IMAGE_QUALITY: number;
  DEFAULT_SCREEN_WIDTH: number;
  DEFAULT_SCREEN_HEIGHT: number;
  TEXT_LAYOUT: TextLayoutConfig;
}

type UIAbilityContext = common.UIAbilityContext;

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

// 名言列表初始化参数接口
export interface QuoteListInitParams {
  currentQuote: Quote | null;
  currentWallpaper: GeneratedWallpaper | null;
  quoteDataSource: QuoteDataSource;
  wallpaperList: (GeneratedWallpaper | null)[];
  optimizedFontSizes: number[];
}

// 按需加载参数接口
export interface LoadMoreParams {
  currentIndex: number;
  quoteDataSource: QuoteDataSource;
  wallpaperList: (GeneratedWallpaper | null)[];
  optimizedFontSizes: number[];
}

// 壁纸应用参数接口
export interface WallpaperApplyParams {
  setLockScreen: boolean;
  saveToGallery: boolean;
  context: UIAbilityContext;
}

// 处理名言参数接口
export interface ProcessQuoteParams {
  quoteDataSource: QuoteDataSource;
  wallpaperList: (GeneratedWallpaper | null)[];
  optimizedFontSizes: number[];
}

// 名言数据统计结果接口
export interface QuoteDataStatsResult {
  currentSourceCount: number;
  totalCount: number;
}