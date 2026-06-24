/**
 * 测试专用：获取 entry 的 ability 级 Context。
 * delegator.getAppContext() 是应用级 Context，被 RelationalStore / fileIo 的某些路径判 Illegal；
 * 改为 startAbility 拉起 EntryAbility（onCreate 把 context 写入 AppContext），再轮询取出。
 */
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';
import common from '@ohos.app.ability.common';
import { AppContext } from '../../../main/ets/common/AppContext';

function sleep(ms: number): Promise<void> {
  return new Promise<void>(resolve => setTimeout(resolve, ms));
}

export async function obtainAbilityContext(): Promise<common.UIAbilityContext> {
  const cached = AppContext.get();
  if (cached !== null) return cached;

  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const want: Want = {
    bundleName: 'com.example.spatialboutique',
    abilityName: 'EntryAbility',
  };
  await delegator.startAbility(want);

  for (let i = 0; i < 50; i++) {
    const ctx = AppContext.get();
    if (ctx !== null) return ctx;
    await sleep(100);
  }
  throw new Error('obtainAbilityContext: EntryAbility 未在 5s 内注入 context');
}
