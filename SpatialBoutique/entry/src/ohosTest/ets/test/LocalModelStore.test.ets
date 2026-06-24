/**
 * LocalModelStore 单测。对应地基计划 Task 5。
 * 用 hypium + 真 RelationalStore（本地模拟器），走 save→list→load→delete 闭环。
 * 运行：DevEco 右键本文件 → Run（部署到本地模拟器）。
 */
import { describe, it, expect } from '@ohos/hypium';
import { LocalModelStore } from '../../../main/ets/store/LocalModelStore';
import { MaterialPresetId } from '../../../main/ets/model/MaterialPreset';
import { ModelInfo } from '../../../main/ets/model/ModelInfo';
import { obtainAbilityContext } from './testContext';

export default function localModelStoreTest() {
  describe('LocalModelStore', () => {
    it('saves then lists then loads then deletes a model', 0, async () => {
      const context = await obtainAbilityContext();
      const store = new LocalModelStore(context, 'smoke_models.db');
      await store.delete('m1'); // 幂等清理

      const model: ModelInfo = {
        id: 'm1',
        name: '测试戒指',
        category: 'jewelry',
        createdAt: 1719000000000,
        thumbnailPath: '/tmp/t.png',
        plyPath: '/tmp/m1.ply',
        materialPreset: MaterialPresetId.Metal,
      };
      await store.save(model);

      const listed = await store.list();
      expect(listed.some(m => m.id === 'm1')).assertTrue();

      const loaded = await store.load('m1');
      expect(loaded?.name).assertEqual('测试戒指');
      expect(loaded?.materialPreset).assertEqual(MaterialPresetId.Metal);

      await store.delete('m1');
      const after = await store.load('m1');
      expect(after === undefined).assertTrue();
    });
  });
}
