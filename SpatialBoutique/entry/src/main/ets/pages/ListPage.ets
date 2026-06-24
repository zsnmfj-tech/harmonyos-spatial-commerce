/**
 * ListPage —— 从 LocalModelStore 加载并展示模型。对应地基计划 Task 10 + 13。
 * 监听 listVersion（@Watch），扫描页存新模型后自动刷新；
 * 卡片点击写 selectedModelId，展示页响应加载。
 */
import { ModelInfo } from '../model/ModelInfo';
import { LocalModelStore } from '../store/LocalModelStore';
import { ModelCard } from '../components/ModelCard';
import { AppContext } from '../common/AppContext';

@Component
export struct ListPage {
  @State items: ModelInfo[] = [];
  @StorageLink('listVersion') @Watch('onVersionChanged') listVersion: number = 0;
  private store: LocalModelStore | null = null;

  aboutToAppear(): void {
    const ctx = AppContext.get();
    if (ctx !== null) {
      this.store = new LocalModelStore(ctx);
    }
    this.refresh();
  }

  onVersionChanged(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    if (this.store !== null) {
      this.items = await this.store.list();
    }
  }

  build() {
    Column({ space: 8 }) {
      Text('我的 3D 好物')
        .fontSize(24)
        .fontColor('#FFFFFF')
        .padding(16);

      if (this.items.length === 0) {
        Column() {
          Text('还没有模型').fontColor('#9AA0B4');
          Text('切到商家模式扫描一件')
            .fontSize(12)
            .fontColor('#6B7186')
            .margin({ top: 4 });
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .layoutWeight(1);
      } else {
        List({ space: 0 }) {
          ForEach(this.items, (m: ModelInfo) => {
            ListItem() {
              ModelCard({
                item: m,
                onTap: (item: ModelInfo) => {
                  AppStorage.setOrCreate('selectedModelId', item.id);
                  AppStorage.setOrCreate('pendingTab', 'showcase');
                },
              });
            }
          }, (m: ModelInfo) => m.id);
        }
        .layoutWeight(1)
        .width('100%');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#13151F');
  }
}
