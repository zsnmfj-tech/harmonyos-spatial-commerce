# TODO · harmonyos-spatial-commerce

> 进度权威清单，双方勾选。最后更新：2026-06-24。
> 续做先读 `CLAUDE.md`，设计与代码细节见 `docs/`。

## 现状一句话

HarmonyOS 7（API 26）空间化能力的商品 3D 展示 App。**P1 地基 14 Task 全绿（含端到端 SmokeFlow）**，ohosTest 脚手架已修复。下一步：真机集成 D1（NDK 骨架，预写在 `pending-src/D1/`）。

---

## 已完成

- [x] 头脑风暴（能力调研 / 视觉伴侣 / 7 轮澄清 / 3 方案比选 / 设计 / spec / plan）
- [x] 设计 spec — `docs/spec-p1-2026-06-23.md`
- [x] P1 地基实现计划（14 Task）— `docs/plan-p1-foundation-2026-06-23.md`
- [x] P1 真机集成计划（D1–D10）— `docs/plan-p1-device-integration-2026-06-23.md`
- [x] 项目上 GitHub（`origin/main`，Private）
- [x] 一键继续入口 `CLAUDE.md` + 跨会话记忆

---

## 现在就能做（不依赖 SDK，Claude 本会话可执行）

- [x] #3 GitHub Actions 构建检查 workflow → `.github/workflows/build.yml`（path 门控；需配 `HARMONYOS_CMDLINE_URL` secret）
- [x] #4 预写 DevEco 静态配置 → `docs/reference-deveco-config.md`（脚手架后合并的权限/NDK/依赖片段）
- [x] #5 重抓沉浸光感文档，确认 D7 的 HDS 属性名，写入笔记 → `docs/notes-immersive-light-sense.md`

---

## P1 地基实现（需 DevEco Studio + 本地模拟器）

> 按 `docs/plan-p1-foundation-2026-06-23.md` 执行，每 Task 含 TDD 步骤。
> Task 2-3 源码已暂存于 `pending-src/`，Task 1 建工程后按其 README 贴入对应路径。

- [x] T1 建 DevEco 工程 SpatialBoutique（API 26，加入本仓库子目录）
- [x] T2 数据模型类型（ModelInfo / MaterialPreset / Role）— 4 用例全绿
- [x] T3 类型化错误（CaptureError / ReconError）
- [x] T4 ModelStore 接口
- [x] T5 LocalModelStore（RelationalStore）— save→list→load→delete 闭环绿
- [x] T6 CaptureKit + ReconEngine 接口
- [x] T7 MockCaptureKit + MockReconEngine — 进度单调+PLY 落盘、并发拒绝 2 用例绿
- [x] T8 AppMode 全局角色状态 — 1 用例绿
- [x] T9 Shell 导航骨架 + 角色切换 — 手测：扫描 Tab 随角色显隐
- [x] T10 ListPage 接 ModelStore — 空态文案正确
- [x] T11 MaterialPicker 组件
- [x] T12 ShowcaseChrome（光感覆盖层）— 毛玻璃占位，真光感留真机 D7
- [x] T13 ScanPage + ShowcasePage 接 mock 跑通闭环 — 手测：扫描→存→列表刷新→点卡跳展示
- [x] T14 端到端 mock 闭环测试（prove-it）— SmokeFlow 6 套件全绿（2026-06-25）

## P1 真机集成（需 AGC 云调试真机 API 26）

> 按 `docs/plan-p1-device-integration-2026-06-23.md` 执行。**依赖地基 T1–T14 完成。**

- [ ] D1 NDK/napi 骨架（CMake + napi 注册）
- [ ] D2 真 CaptureKit（AR Engine 1080×1440 + PushARFrame + RunningMode）
- [ ] D3 温升观察者（订阅 COMMON_EVENT_THERMAL_LEVEL_CHANGED 自动暂停）
- [ ] D4 真 ReconEngine（Spatial Recon 生命周期 + 单 session 守卫 + 存 PLY/MP4）
- [ ] D5 napi ArkTS 包装 + Mock 切换（NapiCaptureKit / NapiReconEngine）
- [ ] D6 3DGS 渲染（XComponent + Spatial Recon loader）
- [ ] D7 沉浸光感真实动效（光随指动 / 光线勾勒 / 非线性形变）
- [ ] D8 手势（旋转 / 缩放 / 平移 / 复位 + 触点驱动光源）
- [ ] D9 扫描引导 UX（360° 环 + 角度补漏 + 低光检测）
- [ ] D10 真机 prove-it（端到端真闭环）

---

## 后续阶段（各自独立 spec → plan → 实现）

- [ ] P2 商品化与目录（上架流程、分类搜索）
- [ ] P3 交易闭环（华为支付、数字盾、订单售后）
- [ ] P4 分发增长（元服务、服务卡片、闪控窗、平行视界 easygo）

---

## 协作分工

| 待办 | 环境 | 主执行 | Claude 角色 |
|---|---|---|---|
| 现在就能做 #3 / #4 / #5 | 本会话 | Claude | 执行 |
| 地基 T1 建工程 | DevEco Studio | 你 | 给步骤、答疑 |
| 地基 T2–T14 编码 | DevEco + 模拟器 | 你 / Claude 远程给码 | 给完整代码、review、debug |
| 真机 D1–D10 | 云调试真机 | 你 | 给 NDK 骨架、debug、解读报错 |
| P2 / P3 / P4 spec | 本会话 | Claude | 设计（启动 brainstorm） |
| 沉浸光感属性名确认 | 文档/浏览器 | 你或 Claude | 重抓后写入笔记 |

## 关键约束

- **顺序**：地基 T1–T14 → 真机 D1–D10 → P2 → P3 → P4。真机计划依赖地基的接口与 Mock 注入点。
- **环境门控**：逻辑/数据/UI 在 DevEco 模拟器验证；真 AR/Spatial Recon/3DGS 渲染/光感**必须真机**，云 VM 不行。
- **沉浸光感属性名**：D7 前必须确认（重抓 `arkts-immersive-light-sense` 或查 HDS 材质文档）。
