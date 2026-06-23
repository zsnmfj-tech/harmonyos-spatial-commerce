/**
 * 测试入口。对应地基计划 Task 2。
 * 后续 Task 的测试模块（LocalModelStore / MockReconEngine / AppMode / SmokeFlow）
 * 都在这里注册（取消注释对应行）。
 *
 * 注意：DevEco 向导会生成一个同名 List.test.ets——用本文件替换它（或把注册行合并进去）。
 */
import { abilityDelegator } from '@kit.TestKit';
import materialPresetTest from './model/MaterialPreset.test';
// import localModelStoreTest from './store/LocalModelStore.test';       // Task 5
// import mockReconEngineTest from './recon/MockReconEngine.test';       // Task 7
// import appModeTest from './common/AppMode.test';                     // Task 8
// import smokeFlowTest from './flow/SmokeFlow.test';                   // Task 14

export default function testsuite() {
  // const context = abilityDelegator.getContext();   // 后续需要 context 的测试打开
  materialPresetTest();
  // localModelStoreTest(context);
  // mockReconEngineTest(context);
  // appModeTest();
  // smokeFlowTest(context);
}
