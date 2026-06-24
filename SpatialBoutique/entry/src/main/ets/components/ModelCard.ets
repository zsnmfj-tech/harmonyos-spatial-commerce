/**
 * ModelCard —— 单个模型列表项。对应地基计划 Task 10。
 */
import { ModelInfo } from '../model/ModelInfo';
import { MATERIAL_PRESETS, MaterialPresetId } from '../model/MaterialPreset';

@Component
export struct ModelCard {
  item: ModelInfo = {
    id: '',
    name: '',
    category: '',
    createdAt: 0,
    thumbnailPath: '',
    plyPath: '',
    materialPreset: MaterialPresetId.Metal,
  };
  onTap: (item: ModelInfo) => void = () => {};

  build() {
    Row({ space: 12 }) {
      Image(this.item.thumbnailPath)
        .width(64)
        .height(64)
        .borderRadius(8)
        .backgroundColor('#2A2D3A');
      Column({ space: 4 }) {
        Text(this.item.name).fontSize(16).fontColor('#FFFFFF');
        Text(MATERIAL_PRESETS[this.item.materialPreset].label + ' · ' + this.item.category)
          .fontSize(12)
          .fontColor('#9AA0B4');
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1);
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#1E2030')
    .margin({ bottom: 8 })
    .onClick(() => this.onTap(this.item));
  }
}
