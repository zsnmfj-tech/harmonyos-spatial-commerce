/**
 * CaptureKit 接口。对应地基计划 Task 6。
 * P1 地基用 Mock 实现；真机计划里由 NDK 封 AR Engine 实现此接口。
 */
export interface CaptureKit {
  start(): Promise<void>;
  stop(): void;
}
