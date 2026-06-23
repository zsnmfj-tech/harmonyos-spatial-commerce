# TODO · 商品 3D 展示 HarmonyOS App

> 进度权威清单，双方勾选。最后更新：2026-06-23。
> 续做先读 `CLAUDE.md`，设计与代码细节见 `docs/`。

## 现状一句话

HarmonyOS 7（API 26）空间化能力的商品 3D 展示 App。**设计 + 两份实现计划完成，尚未开始编码。** 下一步：在 DevEco Studio 跑 P1 地基 Task 1。

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

- [ ] #3 GitHub Actions 构建检查 workflow（push 后 `hvigorw assembleHap`）
- [ ] #4 预写 DevEco 静态配置（build-profile.json5 / oh-package.json5 / module.json5 / AppScope）
- [x] #5 重抓沉浸光感文档，确认 D7 的 HDS 属性名，写入笔记 → `docs/notes-immersive-light-sense.md`

---

## P1 地基实现（需 DevEco Studio + 本地模拟器）

> 按 `docs/plan-p1-foundation-2026-06-23.md` 执行，每 Task 含 TDD 步骤。

- [ ] T1 建 DevEco 工程 SpatialBoutique（API 26，加入本仓库子目录）
- [ ] T2 数据模型类型（ModelInfo / MaterialPreset / Role）
- [ ] T3 类型化错误（CaptureError / ReconError）
- [ ] T4 ModelStore 接口
- [ ] T5 LocalModelStore（RelationalStore）
- [ ] T6 CaptureKit + ReconEngine 接口
- [ ] T7 MockCaptureKit + MockReconEngine
- [ ] T8 AppMode 全局角色状态
- [ ] T9 Shell 导航骨架 + 角色切换
- [ ] T10 ListPage 接 ModelStore
- [ ] T11 MaterialPicker 组件
- [ ] T12 ShowcaseChrome（光感覆盖层）
- [ ] T13 ScanPage + ShowcasePage 接 mock 跑通闭环
- [ ] T14 端到端 mock 闭环测试（prove-it）

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
