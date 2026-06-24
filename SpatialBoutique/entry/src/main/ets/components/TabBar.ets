/**
 * TabBar —— 底部 Tab 壳。对应地基计划 Task 9。
 * 浏览/展示/我的 常驻；扫描 Tab 仅商家模式可见（@StorageLink 响应 AppStorage 角色变化）。
 * 程序化切 Tab：ListPage 点卡片写 pendingTab，这里 @Watch 用 TabsController.changeIndex 切，
 * 绕开 Scan Tab 显隐导致的索引漂移（Tabs 的 index 参数程序化切换不可靠，必须用 controller）。
 */
import { Role } from '../model/Role';
import { ListPage } from '../pages/ListPage';
import { ScanPage } from '../pages/ScanPage';
import { ShowcasePage } from '../pages/ShowcasePage';
import { ProfilePage } from '../pages/ProfilePage';

@Component
export struct TabBar {
  @StorageLink('appRole') role: Role = Role.Buyer;
  @StorageLink('pendingTab') @Watch('onPendingTab') pendingTab: string = 'browse';
  private tabsController: TabsController = new TabsController();

  private indexOf(name: string): number {
    if (name === 'browse') {
      return 0;
    }
    if (name === 'scan') {
      return this.role === Role.Seller ? 1 : 0;
    }
    if (name === 'showcase') {
      return this.role === Role.Seller ? 2 : 1;
    }
    if (name === 'profile') {
      return this.role === Role.Seller ? 3 : 2;
    }
    return 0;
  }

  onPendingTab(): void {
    this.tabsController.changeIndex(this.indexOf(this.pendingTab));
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        ListPage();
      }.tabBar('浏览');

      if (this.role === Role.Seller) {
        TabContent() {
          ScanPage();
        }.tabBar('扫描');
      }

      TabContent() {
        ShowcasePage();
      }.tabBar('展示');

      TabContent() {
        ProfilePage();
      }.tabBar('我的');
    }
    .width('100%')
    .height('100%');
  }
}
