// 文本布局相关的类型定义

// 文本换行结果接口
export interface TextLayoutResult {
  text: string;
  fontSize: number;
  lines: string[];
}

// 换行点信息接口
export interface BreakPoint {
  line: string;
  nextIndex: number;
}

// 行信息接口
export interface LineInfo {
  text: string;
  width: number;
  height: number;
  characterCount: number;
  hasLeadingPunctuation: boolean;
  isOrphan: boolean;
  isAutoWrapped: boolean;
}

// 文本布局度量接口
export interface TextLayoutMetrics {
  lines: LineInfo[];
  totalWidth: number;
  totalHeight: number;
  fontSize: number;
  autoWrapCount: number;
  orphanCount: number;
  punctuationViolations: number;
  originalLineCount: number;
}

// 权重配置接口
export interface WeightsConfig {
  r1: number;  // 自动换行比例
  r2: number;  // 孤行比例
  r3: number;  // 行宽不均匀度
  r4: number;  // 长宽比偏差
  r5: number;  // 空间利用率
  r6: number;  // 标点位置合规性
  r7: number;  // 视觉密度均匀性
  r9: number;  // 视觉焦点分散度
}

// 字体范围接口
export interface FontRange {
  min: number;
  max: number;
}

// 理想行数范围接口
export interface IdealLineRange {
  min: number;
  max: number;
}

// 优化配置接口
export interface OptimizationConfig {
  weights: WeightsConfig;
  fontRange: FontRange;
  idealLineRange: IdealLineRange;
  maxIterations: number;
}