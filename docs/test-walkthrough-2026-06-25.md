# P1 地基完整测试清单（2026-06-25）

> 涵盖已完成 T1–T14 的全部验证步骤与预期结果。按章节顺序执行即可。
> 环境：DevEco Studio（API 26 / HarmonyOS 7 SDK）+ 本地手机模拟器。

---

## 0. 前置准备（必做一次）

1. 打开 DevEco Studio，Open `harmonyos-spatial-commerce/SpatialBoutique/`。
2. **File → Sync and Refresh Project**（同步依赖、生成 Run 配置）。
3. 启动 **本地手机模拟器**（Tools → Device Manager）。
4. 确认 Run → Edit Configurations 里有 `entry` 与 `entry_test`（OHOS Test）两条配置。

> ⚠️ 如果右键测试文件没有 Run，先做 **File → Invalidate Caches / Restart**，再 Sync。
> 测试入口由本次新补的 `entry/src/ohosTest/ets/testability/TestAbility.ets` + `ohosTest/module.json5` 提供。

---

## Part A · 自动化测试（hypium，一次跑完覆盖 T2/T3/T5/T7/T8/T14）

**入口**：`entry/src/ohosTest/ets/test/List.test.ets`
**运行方式**：右键 `List.test.ets` → Run；或右键 `entry_test` 模块 → Run；或选 `entry_test` Run Configuration。

### 期待结果

测试报告应出现 **6 个测试套件、用例全绿（PASS）**：

| # | 套件名 (`describe`) | 文件 | 覆盖 Task | 验证点 |
|---|---|---|---|---|
| 1 | `ActsAbilityTest` | `test/Ability.test.ets` | 脚手架自带 | `assertContain('abc','b')` 通过 |
| 2 | `MaterialPreset` | `test/MaterialPreset.test.ets` | T2/T3 | 4 个预设 id（metal/gem/glass/matte）齐全；Metal 的 `metalness===1.0`、Gem/Matte 的 `metalness===0.0` |
| 3 | `LocalModelStore` | `test/LocalModelStore.test.ets` | T4/T5 | save → list 命中 m1 → load 字段一致 → delete 后 load 返回 undefined |
| 4 | `MockReconEngine` | `test/MockReconEngine.test.ets` | T6/T7 | 进度单调不减、末值 === 1；fixture PLY 文件可读；并发 `start()` 抛 `ReconError`（name 正确） |
| 5 | `AppMode` | `test/AppMode.test.ets` | T8 | `getRole()` 默认 Buyer；`setRole(Seller)` 后再读为 Seller；`AppStorage` 中的 `appRole` 同步更新 |
| 6 | `SmokeFlow (mock 端到端)` | `test/SmokeFlow.test.ets` | **T14（本次）** | capture.start → engine.start 返回 plyPath → store.save 后 list 含该 id → load 的 plyPath 与 materialPreset 与写入一致 → delete 成功 |

### 失败排查清单

- **`obtainAbilityContext: EntryAbility 未在 5s 内注入 context`** → EntryAbility 没起来，检查 `entry/src/main/module.json5` 的 bundleName 是否 `com.example.spatialboutique`，与 `testContext.ets` 一致。
- **`Illegal context`（RelationalStore）** → context 仍是应用级而非 ability 级，检查 `EntryAbility.onCreate` 是否调用 `AppContext.set(this.context)`。
- **`ReconError` 在 SmokeFlow 抛出** → 单 session 守卫误触发，hypium 串行执行不应出现，若出现说明上一用例未清干净。
- **Resource 引用错（`$string:EntryAbility_desc` 等）** → test 模块资源作用域问题，把 TestAbility 配置里 description/icon 改字面量。

---

## Part B · 构建验证（T1）

**目的**：确认工程脚手架可正常出 hap。

1. DevEco 右键 `entry` 模块 → Build → Build Hap(s)/APP(s) → Build Hap(s)。
2. 或终端：
   ```bash
   cd SpatialBoutique
   ./hvigorw assembleHap
   ```
3. **预期**：`BUILD SUCCESSFUL`，产物在
   `entry/build/default/outputs/default/entry-default-signed.hap`。

---

## Part C · 手测 UI（T9 / T10 / T13）

> 部署 App 到模拟器：右键 `entry` 模块 → Run 'entry'。启动后进入「我的」页做角色切换。

### C-1 · 角色切换与 Tab 显隐（T9）

入口：App 启动 → 默认买家模式。

| 步骤 | 预期 |
|---|---|
| 1. 启动 App，看底部 Tab | **3 个 Tab**：浏览 / 展示 / 我的（无"扫描"） |
| 2. 点「我的」Tab | 进入「我的」页，显示标题"我的" + 两个按钮（买家/商家）+ 文案"当前：买家" |
| 3. 点「商家模式」按钮 | 商家按钮变 Capsule 高亮；文案变"当前：商家" |
| 4. 看底部 Tab | **变 4 个**：浏览 / 扫描 / 展示 / 我的（"扫描"出现） |
| 5. 点「买家模式」切回 | Tab 应回到 **3 个**（"扫描"消失），文案"当前：买家" |

> 原理：`TabBar.role` 与 `ProfilePage.role` 都是 `@StorageLink('appRole')`，`setRole()` 写 AppStorage 即联动。

### C-2 · 列表空态（T10）

| 步骤 | 预期 |
|---|---|
| 1. 切到「浏览」Tab（首次启动） | 标题"我的 3D 好物" + 居中文案 **"还没有模型"** + 小字 **"切到商家模式扫描一件"** |

> 说明：若之前跑过 C-3 已留下数据，先卸载重装 App 或在 SmokeFlow 跑过后清空 `flow_models.db`。

### C-3 · 端到端 mock 闭环（T13）

> 这是 P1 地基最关键的链路：扫描 → 重建 → 落盘 → 列表刷新 → 卡片点击跳展示。

| 步骤 | 预期 |
|---|---|
| 1. 切到「商家模式」 | 底部出现「扫描」Tab |
| 2. 点「扫描」Tab | 进入扫描页：标题"扫描上架（mock）" + 商品名称输入框 + 材质选择器（4 个预设） + 进度条 + 按钮"开始扫描" |
| 3. 在名称框输入"测试戒指" | 文本被记录 |
| 4. 点任意材质（如「宝石」） | 该材质高亮选中 |
| 5. 点「开始扫描」按钮 | 按钮变 **"重建中…"** 且禁用；进度条从 0% 走到 100%（约 300ms，10 步 × 30ms） |
| 6. 进度走完后 | 按钮恢复"开始扫描"；mock PLY 已落盘到应用 sandbox |
| 7. 切到「浏览」Tab | **列表自动刷新**，出现一张卡片，名称为"测试戒指"（即刚扫的） |
| 8. 点该卡片 | 底部 Tab 自动切到「展示」；展示页显示大标题"测试戒指"，并叠加 `ShowcaseChrome`（毛玻璃占位 chrome，含返回/收藏按钮） |
| 9. （可选）多次扫描 | 列表卡片数随之增加 |
| 10. 卸载重装 App | 列表清空，回到 C-2 空态 |

> 验证点：
> - **Tab 程序化切换**：点卡片用 `pendingTab='showcase'` 触发 `TabsController.changeIndex`（绕开 Scan 显隐导致的索引漂移）—— 这是 T9 设计的核心。
> - **列表刷新机制**：扫描完成写 `listVersion++`，ListPage 的 `@Watch('onVersionChanged')` 触发 `refresh()`。
> - **光感占位**：`ShowcaseChrome` 此版本是 `backgroundBlurStyle` 毛玻璃，**真沉浸光感动效留真机 D7**。

---

## Part D · 全绿后的收尾

```bash
cd "D:/yfj/02-work/AI/Codex/harmonyos-spatial-commerce"

# 1. 测试模块脚手架修复（本次补的）
git add SpatialBoutique/entry/src/ohosTest/ets/testability/TestAbility.ets \
        SpatialBoutique/entry/src/ohosTest/module.json5 \
        SpatialBoutique/entry/src/ohosTest/oh-package.json5

# 2. SmokeFlow 测试 + List.test 启用
git add SpatialBoutique/entry/src/ohosTest/ets/test/SmokeFlow.test.ets \
        SpatialBoutique/entry/src/ohosTest/ets/test/List.test.ets

# 3. 本清单
git add docs/test-walkthrough-2026-06-25.md

git commit -m "test(e2e): fix ohosTest scaffolding (TestAbility+module.json5) and add SmokeFlow prove-it"
git push
```

随后在 `TODO.md` 把 **T14** 勾上 —— 地基 14 Task 全部完成，可进入 **真机集成 D1**（NDK/napi 骨架）。

---

## 测试矩阵速查

| Task | 类型 | 验证方式 | 通过标准 |
|---|---|---|---|
| T1 | 构建 | `hvigorw assembleHap` | BUILD SUCCESSFUL |
| T2/T3 | 自动 | hypium | MaterialPreset 套件绿 |
| T4/T5 | 自动 | hypium | LocalModelStore 套件绿 |
| T6/T7 | 自动 | hypium | MockReconEngine 套件绿 |
| T8 | 自动 | hypium | AppMode 套件绿 |
| T9 | 手测 | UI | Tab 随角色显隐 |
| T10 | 手测 | UI | 列表空态文案 |
| T11 | 包含在 T13 | 手测 | 扫描页材质选择器可选 |
| T12 | 包含在 T13 | 手测 | 展示页叠加毛玻璃 chrome |
| T13 | 手测 | UI | 端到端闭环跑通 |
| T14 | 自动 | hypium | SmokeFlow 套件绿 |
