/**
 * 全局 ability context holder。
 * 用途：ohosTest 里 RelationalStore 等需要 ability 级 Context 的 API，
 * 不能用 delegator.getAppContext()（应用级 Context 会被判 Illegal context）。
 * EntryAbility.onCreate 写入，测试读取。
 */
import common from '@ohos.app.ability.common';

export class AppContext {
  private static ctx: common.UIAbilityContext | null = null;

  static set(context: common.UIAbilityContext): void {
    AppContext.ctx = context;
  }

  static get(): common.UIAbilityContext | null {
    return AppContext.ctx;
  }
}
