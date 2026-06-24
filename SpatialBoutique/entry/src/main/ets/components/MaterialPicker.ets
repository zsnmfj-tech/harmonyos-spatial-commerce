/**
 * MaterialPicker —— 四类材质 4 选 1。对应地基计划 Task 11。
 * 商家扫描后选材质，选中态金色高亮。
 * 用显式 id 数组（不用 Object.keys，后者对 Record 枚举在 ArkTS 下不可靠）。
 */
import { MATERIAL_PRESETS, MaterialPresetId } from '../model/MaterialPreset';

const PRESET_IDS: MaterialPresetId[] = [
  MaterialPresetId.Metal,
  MaterialPresetId.Gem,
  MaterialPresetId.Glass,
  MaterialPresetId.Matte,
];

@Component
export struct MaterialPicker {
  @Prop selected: MaterialPresetId = MaterialPresetId.Metal;
  onSelect: (id: MaterialPresetId) => void = () => {};

  build() {
    Row({ space: 8 }) {
      ForEach(PRESET_IDS, (id: MaterialPresetId) => {
        Text(MATERIAL_PRESETS[id].label)
          .fontSize(13)
          .fontColor(this.selected === id ? '#0B0D14' : '#FFFFFF')
          .backgroundColor(this.selected === id ? '#FFD166' : '#2A2D3A')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .onClick(() => this.onSelect(id));
      }, (id: MaterialPresetId) => id);
    }
    .width('100%')
    .justifyContent(FlexAlign.Center);
  }
}
