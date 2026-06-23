/**
 * MaterialPreset 单测。对应地基计划 Task 2。
 * 用 hypium。运行：DevEco 里右键 List.test.ets → Run（部署到本地模拟器）。
 */
import { describe, it, expect } from '@ohos/hypium';
import { MATERIAL_PRESETS, MaterialPresetId } from '../../../main/ets/model/MaterialPreset';

export default function materialPresetTest() {
  describe('MaterialPreset', () => {
    it('exposes exactly four presets', 0, () => {
      const ids = Object.keys(MATERIAL_PRESETS) as MaterialPresetId[];
      expect(ids.length).assertEqual(4);
      expect(ids).assertContain(MaterialPresetId.Metal);
      expect(ids).assertContain(MaterialPresetId.Gem);
      expect(ids).assertContain(MaterialPresetId.Glass);
      expect(ids).assertContain(MaterialPresetId.Matte);
    });

    it('metal preset is sharp and metallic', 0, () => {
      const m = MATERIAL_PRESETS[MaterialPresetId.Metal];
      expect(m.metalness).assertEqual(1.0);
      expect(m.roughness < 0.2).assertTrue();
    });

    it('matte preset is diffuse', 0, () => {
      const m = MATERIAL_PRESETS[MaterialPresetId.Matte];
      expect(m.metalness).assertEqual(0.0);
      expect(m.roughness > 0.7).assertTrue();
    });

    it('gem and glass are transmissive', 0, () => {
      expect(MATERIAL_PRESETS[MaterialPresetId.Gem].transmission).assertEqual(0.85);
      expect(MATERIAL_PRESETS[MaterialPresetId.Glass].transmission).assertEqual(0.95);
    });
  });
}
