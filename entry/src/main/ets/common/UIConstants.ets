// UI常量定义
import { UIConstantsConfig, TextLayoutConfig, TextLayoutWeightsConfig, FontRangeConfig, IdealLineRangeConfig, TextOptimizationConfig } from './ServiceTypes';

export const UI_CONSTANTS: UIConstantsConfig = {
  // 屏幕比例
  DEFAULT_SCREEN_RATIO: 16/9,

  // 动画时长 (毫秒)
  ANIMATION_DURATION_LONG: 2000,
  ANIMATION_DURATION_MEDIUM: 1000,
  ANIMATION_DURATION_SHORT: 250,
  ANIMATION_DURATION_FADE: 500,

  // 手势配置
  LONG_PRESS_DURATION: 800,

  // 缓存配置
  SWIPER_CACHED_COUNT: 3,
  MAX_LOADED_QUOTES: 100,
  PRELOAD_THRESHOLD: 3,
  BATCH_LOAD_COUNT: 10,

  // 布局尺寸
  CONTAINER_PADDING: 24,
  CONTAINER_PADDING_TOTAL: 48, // 左右各24px
  TOP_BAR_HEIGHT: 60,
  BUTTON_SIZE: 40,
  BUTTON_RADIUS: 20,
  DIALOG_BORDER_RADIUS: 12,
  LOADING_PROGRESS_SIZE: 50,
  LOADING_CONTAINER_SIZE: 140,

  // 字体配置
  DEFAULT_FONT_SIZE: 24,
  AUTHOR_FONT_SIZE: 12,
  HINT_FONT_SIZE: 14,
  TITLE_FONT_SIZE: 20,
  SUBTITLE_FONT_SIZE: 16,

  // 间距配置
  TEXT_BOTTOM_MARGIN: 40,
  DIALOG_MARGIN: 16,
  DIALOG_SECTION_MARGIN: 20,
  DIALOG_ITEM_MARGIN: 24,

  // 颜色配置
  DEFAULT_BACKGROUND_COLOR: '#2c3e50',
  FALLBACK_BACKGROUND_COLOR: '#667eea',
  WHITE_COLOR: '#ffffff',
  TEXT_GRAY_COLOR: '#d3d3d3',
  BORDER_GRAY_COLOR: '#bdc3c7',
  DISABLED_GRAY_COLOR: '#95a5a6',
  PRIMARY_BLUE_COLOR: '#5b9bd5',
  DARK_TEXT_COLOR: '#2c3e50',
  MEDIUM_GRAY_COLOR: '#7f8c8d',

  // 透明度配置
  AUTHOR_TEXT_OPACITY: 0.8,
  LOADING_OVERLAY_OPACITY: 0.4,
  DIALOG_BACKGROUND_OPACITY: 0.8,

  // 截图相关
  PURE_WALLPAPER_OFFSET_X: -2000, // 移到屏幕外位置
  IMAGE_QUALITY: 98,

  // 默认屏幕尺寸
  DEFAULT_SCREEN_WIDTH: 360,
  DEFAULT_SCREEN_HEIGHT: 640,

  // 文本布局优化配置
  TEXT_LAYOUT: {
    MIN_CONTAINER_WIDTH: 200,
    SAFETY_MARGIN_MULTIPLIER: 5, // 字体大小 * 5
    MAX_LINES: 20
  } as TextLayoutConfig
};

// 文本布局优化权重配置
export const TEXT_LAYOUT_WEIGHTS: TextLayoutWeightsConfig = {
  AUTO_WRAP_RATIO: 0.15,      // r1: 自动换行比例
  ORPHAN_LINE_RATIO: 0.35,    // r2: 孤行比例
  LINE_WIDTH_VARIANCE: 0.05,  // r3: 行宽不均匀度
  ASPECT_RATIO_DEVIATION: 0.05, // r4: 长宽比偏差
  SPACE_UTILIZATION: 0.15,    // r5: 空间利用率
  PUNCTUATION_COMPLIANCE: 0.1, // r6: 标点位置合规性
  VISUAL_DENSITY_UNIFORMITY: 0.125, // r7: 视觉密度均匀性
  VISUAL_FOCUS_DISPERSION: 0.025    // r9: 视觉焦点分散度
};

// 字体范围配置
export const FONT_RANGE: FontRangeConfig = {
  MIN: 14,
  MAX: 40
};

// 理想行数范围配置
export const IDEAL_LINE_RANGE: IdealLineRangeConfig = {
  MIN: 5,
  MAX: 12
};

// 文本布局优化配置
export const TEXT_OPTIMIZATION_CONFIG: TextOptimizationConfig = {
  MAX_ITERATIONS: 50
};