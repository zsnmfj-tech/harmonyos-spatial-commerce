/**
 * MockReconEngine —— ReconEngine 的地基 Mock。对应地基计划 Task 7。
 * 按固定步数推进进度，结束写一个 fixture PLY 到 sandbox；带单 session 守卫。
 * 真机版由 NDK 封 Spatial Recon 实现（真机集成计划）。
 *
 * ArkTS 适配：字段显式声明（无构造器参数属性）；可选回调显式判空。
 */
import { fileIo } from '@kit.CoreFileKit';
import common from '@ohos.app.ability.common';
import { ReconEngine, ReconResult, ReconProgressListener } from './ReconEngine';
import { ReconError } from '../common/errors';

export interface MockReconOptions {
  stepMs?: number;
  steps?: number;
}

const FIXTURE_PLY =
  'ply\nformat ascii 1.0\nelement vertex 1\nproperty float x\nproperty float y\nproperty float z\nend_header\n0 0 0\n';

export class MockReconEngine implements ReconEngine {
  private running: boolean = false;
  private p: number = 0;
  private timer: number = -1;
  private context: common.UIAbilityContext;
  private opts: MockReconOptions;

  constructor(context: common.UIAbilityContext, opts: MockReconOptions = {}) {
    this.context = context;
    this.opts = opts;
  }

  async start(onProgress?: ReconProgressListener, _writeMp4?: boolean): Promise<ReconResult> {
    if (this.running) {
      throw new ReconError('已有重建在进行（单 session 守卫）', 'start');
    }
    this.running = true;
    this.p = 0;
    const steps = this.opts.steps ?? 10;
    const stepMs = this.opts.stepMs ?? 30;
    return new Promise<ReconResult>((resolve, reject) => {
      let i = 0;
      this.timer = setInterval(() => {
        i += 1;
        this.p = Math.min(1, i / steps);
        if (onProgress !== undefined && onProgress !== null) {
          onProgress(this.p);
        }
        if (i >= steps) {
          clearInterval(this.timer);
          this.writeFixture()
            .then((plyPath: string) => {
              this.running = false;
              resolve({ plyPath });
            })
            .catch((e: Error) => {
              this.running = false;
              reject(new ReconError('写入 fixture PLY 失败', 'save', e));
            });
        }
      }, stepMs);
    });
  }

  pause(): void {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  resume(): void {
    // 地基 mock：暂停后不自动续，由 start 驱动；真机版在真机集成实现
  }

  progress(): number {
    return this.p;
  }

  private async writeFixture(): Promise<string> {
    const dir = this.context.filesDir;
    const path = `${dir}/mock_${Date.now()}.ply`;
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.writeSync(file.fd, FIXTURE_PLY);
    fileIo.closeSync(file);
    return path;
  }
}
