/**
 * 类型化错误。对应地基计划 Task 3。
 * NDK 层（相机/重建）的错误经 napi 封成这些类型回 ArkTS，绝不裸崩。
 * 内部模块互信，只在系统边界（相机/AR/重建/存储/加载）校验。
 *
 * ArkTS：字段显式声明，构造体内赋值（无构造器参数属性）。
 */

/** 相机/取帧相关错误 */
export class CaptureError extends Error {
  cause?: Error;

  constructor(message: string, cause?: Error) {
    super(message);
    this.name = 'CaptureError';
    this.cause = cause;
  }
}

/** 重建相关错误。phase 标注失败发生在哪个阶段，便于 UI 给针对性提示。 */
export class ReconError extends Error {
  phase: 'start' | 'pause' | 'resume' | 'save';
  cause?: Error;

  constructor(
    message: string,
    phase: 'start' | 'pause' | 'resume' | 'save' = 'start',
    cause?: Error,
  ) {
    super(message);
    this.name = 'ReconError';
    this.phase = phase;
    this.cause = cause;
  }
}
