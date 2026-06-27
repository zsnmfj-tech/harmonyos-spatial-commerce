/**
 * ReconSupportProbePage —— A0 验证页。
 * 云调试上打开此页 → 点按钮 → 显示"支持 / 不支持 Spatial Recon 3D 重建"。
 *
 * 接入方式（两种之一）：
 *   1. 临时改 pages/Index.ets，让某个 Tab 临时指向本页
 *   2. 或在 main_pages.json 加路由后从 ProfilePage 加按钮跳转
 * 验证完即可移除，不进 P1 收尾。
 */
import { NapiReconProbe } from '../recon/NapiReconProbe';

@Entry
@Component
struct ReconSupportProbePage {
  @State result: string = '未测试';
  @State busy: boolean = false;

  build() {
    Column({ space: 24 }) {
      Text('A0 · Spatial Recon 可用性探测')
        .fontSize(22)
        .fontColor('#FFFFFF')
        .margin({ top: 48 });

      Text('本页调用 HMS_SpatialRecon_IsSupport(3D)，'
        + '用于确认云调试真机是否支持 Spatial Recon 重建。')
        .fontSize(13)
        .fontColor('#9AA0B4')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 });

      Button(this.busy ? '查询中…' : '开始探测')
        .enabled(!this.busy)
        .width('60%')
        .onClick(() => {
          this.busy = true;
          try {
            const ok = NapiReconProbe.isSupport();
            this.result = ok
              ? '✅ 支持 —— 可投入 D2-D4 实现'
              : '❌ 不支持 —— 需重估方案（云调试可能无法跑 AR/Spatial Recon）';
          } catch (e) {
            this.result = '⚠️ 调用异常：' + (e as Error).message
              + '\n（可能 .so 未链接、头文件枚举名不符，或权限缺失）';
          } finally {
            this.busy = false;
          }
        });

      Text(this.result)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B0D14')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}
