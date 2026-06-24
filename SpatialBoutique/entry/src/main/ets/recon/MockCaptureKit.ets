/**
 * MockCaptureKit —— CaptureKit 的地基 Mock。对应地基计划 Task 7。
 * P1 地基不取真帧；真机版由 NDK 封 AR Engine 实现。
 */
import { CaptureKit } from './CaptureKit';

export class MockCaptureKit implements CaptureKit {
  async start(): Promise<void> {
    // P1 地基：不取真帧
  }
  stop(): void {
    // no-op
  }
}
