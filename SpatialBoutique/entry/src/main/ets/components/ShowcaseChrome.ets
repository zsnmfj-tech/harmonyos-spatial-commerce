/**
 * ShowcaseChrome —— 展示页 chrome 覆盖层（顶栏 + 收藏按钮）。对应地基计划 Task 12。
 *
 * 模拟器阶段：顶栏用 backgroundBlurStyle 作毛玻璃近似占位。
 * 真实沉浸光感（光随指动/光线勾勒/非线性形变）在真机计划 D7 用
 * HdsNavigation/HdsTabs + systemMaterialEffect:IMMERSIVE 实现
 * （见 docs/notes-immersive-light-sense.md）。
 */
@Component
export struct ShowcaseChrome {
  title: string = '';
  onBack: () => void = () => {};
  onCollect: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .onClick(() => this.onBack());
        Text(this.title)
          .fontSize(18)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
        Text('♡')
          .fontSize(22)
          .fontColor('#FFFFFF')
          .onClick(() => this.onCollect());
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
      .border({ width: 0.5, color: 'rgba(255,255,255,0.25)' });
    }
    .width('100%')
    .height('100%');
  }
}
