/**
 * ScanPage —— 接 MockCaptureKit + MockReconEngine + LocalModelStore。对应地基计划 Task 13。
 * 商家模式：输入名称 → 选材质 → 开始扫描 → 进度走完 → 存模型 → 通知列表刷新。
 */
import { MockCaptureKit } from '../recon/MockCaptureKit';
import { MockReconEngine } from '../recon/MockReconEngine';
import { LocalModelStore } from '../store/LocalModelStore';
import { ModelInfo } from '../model/ModelInfo';
import { MaterialPresetId } from '../model/MaterialPreset';
import { AppContext } from '../common/AppContext';
import { MaterialPicker } from '../components/MaterialPicker';

@Component
export struct ScanPage {
  @State progress: number = 0;
  @State busy: boolean = false;
  @State name: string = '';
  @State material: MaterialPresetId = MaterialPresetId.Metal;
  private capture: MockCaptureKit = new MockCaptureKit();
  private store: LocalModelStore | null = null;

  aboutToAppear(): void {
    const ctx = AppContext.get();
    if (ctx !== null) {
      this.store = new LocalModelStore(ctx);
    }
  }

  private async runScan(): Promise<void> {
    if (this.store === null) {
      return;
    }
    const store = this.store;
    const ctx = AppContext.get();
    if (ctx === null) {
      return;
    }
    this.busy = true;
    this.progress = 0;
    await this.capture.start();
    const engine = new MockReconEngine(ctx, { stepMs: 30, steps: 10 });
    const result = await engine.start((p: number) => {
      this.progress = p;
    });
    const model: ModelInfo = {
      id: `m_${Date.now()}`,
      name: this.name.length > 0 ? this.name : '未命名',
      category: 'jewelry',
      createdAt: Date.now(),
      thumbnailPath: result.plyPath, // mock：缩略图暂指 PLY 占位
      plyPath: result.plyPath,
      materialPreset: this.material,
    };
    await store.save(model);
    this.capture.stop();
    this.busy = false;
    // 通知列表刷新
    AppStorage.setOrCreate('listVersion', (AppStorage.get<number>('listVersion') ?? 0) + 1);
  }

  build() {
    Column({ space: 16 }) {
      Text('扫描上架（mock）')
        .fontSize(22)
        .fontColor('#FFFFFF')
        .margin({ top: 24 });
      TextInput({ placeholder: '商品名称' })
        .width('80%')
        .onChange((v: string) => {
          this.name = v;
        });
      MaterialPicker({
        selected: this.material,
        onSelect: (id: MaterialPresetId) => {
          this.material = id;
        },
      });
      Progress({ value: this.progress * 100, total: 100 })
        .width('80%')
        .color('#6B5BFF');
      Button(this.busy ? '重建中…' : '开始扫描')
        .enabled(!this.busy)
        .onClick(() => this.runScan());
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#13151F')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}
