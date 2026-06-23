# 商品 3D 展示 HarmonyOS App · 项目状态（一键继续入口）

> **下次会话先读本文件。** 最后更新：2026-06-23。

## 一句话现状

HarmonyOS 7（API 26）「空间化」能力的商品 3D 展示 App，**已完成头脑风暴 + 设计 spec + P1 实现计划，尚未开始编码**。下一步：在 DevEco Studio 里执行 P1 计划的 Task 1（建工程）。

---

## 立即下一步（只做这件事）

1. 打开 **DevEco Studio**（API 26 / HarmonyOS 7 SDK）。
2. 按 `docs/plan-p1-foundation-2026-06-23.md` 的 **Task 1** 创建工程：
   - Project name: `SpatialBoutique`，Bundle: `com.spatial.boutique`，Compile/Target SDK = **API 26**，ArkTS，Phone。
   - 建在 `商品3D展示-HMOS/SpatialBoutique/` 下（中文父目录 OK，DevEco 工程名用 ASCII）。
3. 按 Task 1 验证 `hvigorw assembleHap` 构建通过，`git init`，首次提交。
4. 然后顺序执行 Task 2–14。

---

## ⚠️ 环境约束（重要）

- **本 bash shell 没有 HarmonyOS SDK / DevEco / 设备**，不能在这里执行或验证任何工程命令。
- **逻辑/数据/UI 任务** → DevEco 本地手机模拟器 + hypium 测试即可。
- **真 AR Engine / Spatial Recon / 3DGS 渲染** → 需 **AGC 云调试真机（API 26 / 7.0.0.23）**，归入后续「真机集成」计划。
- **沉浸光感确切属性名未确认**：`arkts-immersive-light-sense` 文档抓取失败；Task 12 按 HDS 材质文档核验，候选 `.material()` / `.backgroundBlurStyle()` / HDS `TitleBarStyle`。

---

## 关键决策（已与用户对齐）

| 维度 | 选择 |
|---|---|
| 方向 | 商品 3D 展示 |
| 模型来源 | 商家现场扫描，**重建为核心** |
| 商品品类 | 小件精品（饰品/潮玩/手办/珠宝/玻璃） |
| 交易范围 | 完整电商闭环（完整平台愿景） |
| 架构 | **单 App 双角色**（买家⇄商家模式切换） |
| 分期 | P1 空间核心闭环 → P2 商品化目录 → P3 交易闭环 → P4 元服务分发 |
| 本次范围 | **P1 只做空间核心闭环，不碰交易** |

**差异化论点**：支付/目录/订单任何框架都能做；「端侧 3DGS 重建 + 沉浸光感材质」只有 HarmonyOS 7 有——这是唯一不可替代的卖点。

---

## 架构（5 模块）

| 模块 | 层 | 职责 | P1 状态 |
|---|---|---|---|
| ① CaptureKit | NDK | AR Engine 取帧 1080×1440、推帧、温升 | 接口+Mock ✅ / 真实现：真机计划 |
| ② ReconEngine | NDK | Spatial Recon 生命周期、进度、存 PLY/MP4、单 session 守卫 | 接口+Mock ✅ / 真实现：真机计划 |
| ③ ModelStore | ArkTS | 本地索引(RelationalStore)+落盘；上传 stub | P1 全做 ✅ |
| ④ Showcase | ArkTS+NDK | 3DGS 渲染 + 光感 chrome + 手势 + 材质预设 | chrome ✅ / 渲染：真机计划 |
| ⑤ Shell | ArkTS | 双角色切换、导航、全局光感 | P1 全做 ✅ |

数据流：Camera→AR Engine→Spatial Recon→PLY 落盘→ModelStore→3DGS loader→XComponent→沉浸光感 chrome。ArkTS↔NDK 经 napi。

---

## 文件清单

| 路径 | 内容 |
|---|---|
| `docs/spec-p1-2026-06-23.md` | **设计 spec**（愿景/范围/架构/模块/错误处理/测试/技术栈/风险） |
| `docs/plan-p1-foundation-2026-06-23.md` | **P1 地基实现计划**（14 个 Task，TDD，含命令与代码） |
| `welcome.html` / `platform-map.html` / `p1-architecture.html` | 头脑风暴可视化快照（可在浏览器打开回顾） |
| `waiting-1.html` | 占位（可删） |
| `SpatialBoutique/` | DevEco 工程（**Task 1 创建，尚未存在**） |

---

## 参考资料（华为官方）

- HarmonyOS 7（API 26）新能力一览：https://developer.huawei.com/consumer/cn/information/news/672547571d37483396004638e9486064
- 沉浸光感（ArkTS）：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-immersive-light-sense ⚠️ 之前抓取失败，需重试或查 HDS 材质文档替代
- 重建三维场景 C/C++（Spatial Recon Kit）：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/spatial-recon-c-spatial-recon-pipeline
- HDS 沉浸光感材质（替代/补充）：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-hds-component-material

---

## 下次会话如何「一键继续」

1. 在本目录打开 Claude Code。
2. 说一句：「继续 商品3D展示-HMOS 项目」（或更具体：「继续执行 P1 计划的 Task N」）。
3. Claude 会读到本文件 + 记忆，直接接上。
   - 若要执行代码任务：需切到装了 HarmonyOS SDK 的环境，或由你在 DevEco 里操作、Claude 协助。
   - 若只推进设计/计划：随时可做（细化 Task、写真机集成计划、补配置文件等）。

---

## 未决/风险（详见 spec §8）

1. 3DGS 模型体积/内存 → 低端机 OOM，P1 用"拒绝加载并提示"兜底。
2. 沉浸光感在 XComponent 覆盖层上的真实表现 → 真机验证，不行退化为外围 chrome。
3. 材质预设与 3DGS 的契合（宝石/玻璃透射折射）→ 真机验证，不行降级为环境光照风格。
4. MP4 运镜视频价值 → P1 仅本地保存，没人看就 P2 砍。
5. 扫描引导有效性 → 欠覆盖是重建质量头号杀手，需用户测试校准。
