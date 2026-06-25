/**
 * SmokeFlow —— 端到端 mock 闭环 prove-it。对应地基计划 Task 14。
 * 链路：MockCaptureKit.start -> MockReconEngine.start(写 fixture PLY)
 *      -> LocalModelStore.save -> list 命中 -> load 字段一致 -> delete。
 * 全绿即整条 P1 地基链路在本地模拟器上跑通（mock 实现）。
 * 运行：DevEco 右键本文件 → Run（或跑 entry_test 整模块）。
 */
import { describe, it, expect } from '@ohos/hypium';
import { MockCaptureKit } from '../../../main/ets/recon/MockCaptureKit';
import { MockReconEngine } from '../../../main/ets/recon/MockReconEngine';
import { LocalModelStore } from '../../../main/ets/store/LocalModelStore';
import { MaterialPresetId } from '../../../main/ets/model/MaterialPreset';
import { obtainAbilityContext } from './testContext';

export default function smokeFlowTest() {
  describe('SmokeFlow (mock 端到端)', () => {
    it('capture -> recon -> store -> list -> load 全链路', 0, async () => {
      const context = await obtainAbilityContext();
      const capture = new MockCaptureKit();
      const engine = new MockReconEngine(context, { stepMs: 4, steps: 5 });
      const store = new LocalModelStore(context, 'flow_models.db');

      const id = `smoke_${Date.now()}`;
      await capture.start();
      const result = await engine.start();
      await store.save({
        id,
        name: '冒烟戒指',
        category: 'jewelry',
        createdAt: Date.now(),
        thumbnailPath: result.plyPath,
        plyPath: result.plyPath,
        materialPreset: MaterialPresetId.Gem,
      });
      capture.stop();

      const listed = await store.list();
      expect(listed.some(m => m.id === id)).assertTrue();

      const loaded = await store.load(id);
      expect(loaded?.plyPath).assertEqual(result.plyPath);
      expect(loaded?.materialPreset).assertEqual(MaterialPresetId.Gem);

      await store.delete(id);
    });
  });
}
