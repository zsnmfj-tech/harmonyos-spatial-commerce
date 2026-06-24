/**
 * ShowcasePage —— 选中模型的展示页。对应地基计划 Task 13。
 * 监听 AppStorage 的 selectedModelId（@Watch），变化时从 LocalModelStore 加载。
 * 真 3DGS 渲染（XComponent）在真机集成计划；地基用占位 + 光感 chrome。
 */
import { ModelInfo } from '../model/ModelInfo';
import { LocalModelStore } from '../store/LocalModelStore';
import { AppContext } from '../common/AppContext';
import { ShowcaseChrome } from '../components/ShowcaseChrome';

@Component
export struct ShowcasePage {
  @State model: ModelInfo | null = null;
  @StorageLink('selectedModelId') @Watch('onSelectionChanged') selectedId: string = '';
  private store: LocalModelStore | null = null;

  aboutToAppear(): void {
    const ctx = AppContext.get();
    if (ctx !== null) {
      this.store = new LocalModelStore(ctx);
    }
    this.loadModel();
  }

  onSelectionChanged(): void {
    this.loadModel();
  }

  private async loadModel(): Promise<void> {
    if (this.store === null) {
      return;
    }
    if (this.selectedId.length === 0) {
      this.model = null;
      return;
    }
    this.model = (await this.store.load(this.selectedId)) ?? null;
  }

  build() {
    Stack() {
      Column() {
        Text(this.model !== null ? this.model.name : '选择一个模型')
          .fontSize(28)
          .fontColor('#FFFFFF');
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center);

      if (this.model !== null) {
        ShowcaseChrome({
          title: this.model.name,
          onBack: () => {},
          onCollect: () => {},
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B0D14');
  }
}
