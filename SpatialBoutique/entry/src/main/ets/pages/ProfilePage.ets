/**
 * ProfilePage —— 我的页，含角色切换。对应地基计划 Task 9。
 * 点买家/商家按钮写 AppStorage，TabBar 的 @StorageLink 自动响应（扫描 Tab 显隐）。
 */
import { getRole, setRole } from '../common/AppMode';
import { Role } from '../model/Role';

@Component
export struct ProfilePage {
  @StorageLink('appRole') role: Role = Role.Buyer;

  build() {
    Column({ space: 16 }) {
      Text('我的').fontSize(24).margin({ top: 32 });

      Row({ space: 12 }) {
        Button('买家模式')
          .type(this.role === Role.Buyer ? ButtonType.Capsule : ButtonType.Normal)
          .onClick(() => setRole(Role.Buyer));
        Button('商家模式')
          .type(this.role === Role.Seller ? ButtonType.Capsule : ButtonType.Normal)
          .onClick(() => setRole(Role.Seller));
      }

      Text('当前：' + (this.role === Role.Buyer ? '买家' : '商家'))
        .fontSize(14)
        .fontColor('#9AA0B4');
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center);
  }
}
