/**
 * 测试入口（聚合）。
 * 单文件 Run 会被 DevEco 加 `-s class` 过滤器只跑被点中的套件；
 * 要跑全部套件，用 entry_test 模块的 Run 配置（不带 class 过滤）。
 */
import abilityTest from './Ability.test';
import materialPresetTest from './MaterialPreset.test';
import localModelStoreTest from './LocalModelStore.test';
import mockReconEngineTest from './MockReconEngine.test';
import appModeTest from './AppMode.test';
// import smokeFlowTest from './SmokeFlow.test';    // Task 14

export default function testsuite() {
  abilityTest();
  materialPresetTest();
  localModelStoreTest();
  mockReconEngineTest();
  appModeTest();
  // smokeFlowTest();        // Task 14
}
