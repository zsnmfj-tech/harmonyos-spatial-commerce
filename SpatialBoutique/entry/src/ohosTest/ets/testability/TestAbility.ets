/**
 * TestAbility —— OHOS 测试运行器入口。DevEco 「OHOS Test」运行配置拉起此 Ability，
 * onCreate 调用 testsuite() 把所有套件交给 hypium 的 OpenHarmonyTestRunner 执行。
 * 缺这个文件 + module.json5 里的声明，DevEco 右键测试文件不会出现 Run 选项。
 */
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import testsuite from '../test/List.test';

const DOMAIN = 0x0000;

export default class TestAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'TestAbility onCreate');
    testsuite();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'TestAbility onDestroy');
  }

  onWindowStageCreate(_windowStage: window.WindowStage): void {
    // 测试 Ability 无需加载页面，hypium runner 在 onCreate 后自行驱动用例。
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'TestAbility onWindowStageCreate');
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'TestAbility onWindowStageDestroy');
  }
}
