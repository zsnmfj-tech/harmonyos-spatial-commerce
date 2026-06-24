/**
 * MockReconEngine 单测。对应地基计划 Task 7。
 * 验证：进度单调不减且末值为 1、fixture PLY 落盘可读、并发 start 被单 session 守卫拒绝（抛 ReconError）。
 * 运行：DevEco 右键本文件 → Run（部署到本地模拟器）。
 */
import { describe, it, expect } from '@ohos/hypium';
import { fileIo } from '@kit.CoreFileKit';
import { MockReconEngine } from '../../../main/ets/recon/MockReconEngine';
import { obtainAbilityContext } from './testContext';

export default function mockReconEngineTest() {
  describe('MockReconEngine', () => {
    it('reports increasing progress and writes a fixture PLY', 0, async () => {
      const context = await obtainAbilityContext();
      const ticks: number[] = [];
      const engine = new MockReconEngine(context, { stepMs: 5, steps: 6 });
      const result = await engine.start((p: number) => ticks.push(p));
      expect(result.plyPath.length > 0).assertTrue();
      const file = fileIo.openSync(result.plyPath, fileIo.OpenMode.READ_ONLY);
      expect(file.fd > 0).assertTrue();
      fileIo.closeSync(file);
      expect(ticks[ticks.length - 1]).assertEqual(1);
      for (let i = 1; i < ticks.length; i++) {
        expect(ticks[i] >= ticks[i - 1]).assertTrue();
      }
    });

    it('rejects concurrent start (single-session guard)', 0, async () => {
      const context = await obtainAbilityContext();
      const engine = new MockReconEngine(context, { stepMs: 50, steps: 10 });
      const first = engine.start();
      await new Promise<void>(resolve => setTimeout(resolve, 10));
      try {
        await engine.start();
        expect(false).assertTrue(); // 不应到达
      } catch (e) {
        expect((e as Error).name).assertEqual('ReconError');
      }
      await first;
    });
  });
}
