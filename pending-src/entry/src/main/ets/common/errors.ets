/**
 * 类型化错误。对应地基计划 Task 3。
 * NDK 层（相机/重建）的错误经 napi 封成这些类型回 ArkTS，绝不裸崩。
 * 内部模块互信，只在系统边界（相机/AR/重建/存储/加载）校验。
 */

/** 相机/取帧相关错误 */
export class CaptureError extends Error {
  constructor(message: string, public cause?: Error) {
    super(message);
    this.name = 'CaptureError';
  }
}

/** 重建相关错误。phase 标注失败发生在哪个阶段，便于 UI 给针对性提示。 */
export class ReconError extends Error {
  constructor(
    message: string,
    public phase: 'start' | 'pause' | 'resume' | 'save' = 'start',
    public cause?: Error,
  ) {
    super(message);
    this.name = 'ReconError';
  }
}
