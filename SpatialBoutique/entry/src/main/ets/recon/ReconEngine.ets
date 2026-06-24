/**
 * ReconEngine 接口。对应地基计划 Task 6。
 * P1 地基用 Mock 实现；真机计划里由 NDK 封 Spatial Recon 实现此接口。
 */

export type ReconProgressListener = (progress: number) => void;

export interface ReconResult {
  plyPath: string;
  mp4Path?: string;
}

export interface ReconEngine {
  /** 启动重建。writeMp4=true 时同时产出运镜预览。完成 resolve 结果。 */
  start(onProgress?: ReconProgressListener, writeMp4?: boolean): Promise<ReconResult>;
  pause(): void;
  resume(): void;
  /** 0..1，最近一次进度。 */
  progress(): number;
}
