# 鸿蒙空间化商品 3D 展示 · P1 真机集成计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 P1 地基计划里的 Mock 实现替换为**真 NDK 实现**——真 AR Engine 取帧 + 真 Spatial Recon 3DGS 重建 + 3DGS 渲染 + 沉浸光感真实动效 + 手势 + 扫描引导，并在真机上跑通端到端闭环。

**前置**：P1 地基计划（`plan-p1-foundation-2026-06-23.md`）已完成——工程存在、接口已定义、Mock 链路在模拟器跑通、依赖注入点就位。本计划从地基的 Mock 切到真 NDK。

**Architecture:** 新增 `cpp/` NDK 模块（CMake + napi）。`NapiCaptureKit` / `NapiReconEngine` 实现 ArkTS 侧的 `CaptureKit` / `ReconEngine` 接口，经 napi 调 NDK。3DGS 渲染经 `XComponent` 取 native surface，调 Spatial Recon loader。沉浸光感动效按已确认的 HDS 属性施加。

**Tech Stack:** C/C++ NDK、AR Engine（`ar/ar_engine_core.h`）、Spatial Recon Kit（`spatial_recon_interface.h`）、napi、XComponent、HDS 沉浸光感材质。

---

## 置信度与验证约定（先读）

1. **本计划全部任务需 AGC 云调试真机（API 26 / 7.0.0.23）验证**——AR Engine 与 Spatial Recon 在模拟器上不可用。无真机则只能编译通过、不能功能验证。
2. **NDK 函数名**（`HMS_AREngine_*`、`HMS_SpatialRecon_*`）来自官方文档原文；但**完整签名（参数类型、结构体字段、头文件路径）必须在实现时对照 SDK 实际头文件核验**：`ar/ar_engine_core.h`、`spatial_recon_interface.h`。本计划代码示意结构，不保证逐字段精确。
3. **沉浸光感 API 已确认**（见 `docs/notes-immersive-light-sense.md`）：`@kit.UIDesignKit` 的 `systemMaterialEffect`（`materialType`/`materialLevel`），施加于 `HdsNavigation` 标题栏与 `HdsTabs` 底部页签；`IMMERSIVE` 材质自带光随指动/光线勾勒/非线性形变。
4. **单 session 守卫与温升暂停是硬约束**（官方文档明示违反是未定义行为）。

---

## 文件结构（在 SpatialBoutique 工程内新增）

```
SpatialBoutique/
├── cpp/
│   ├── CMakeLists.txt
│   ├── napi_init.cpp                # napi 模块注册 + 类型/回调转换
│   ├── capture_kit_native.cpp       # CaptureKit 真实现：AR Engine + 推帧
│   ├── recon_engine_native.cpp      # ReconEngine 真实现：Spatial Recon 生命周期
│   └── thermal_observer.cpp         # 订阅 COMMON_EVENT_THERMAL_LEVEL_CHANGED
├── entry/src/main/ets/recon/
│   ├── NapiCaptureKit.ets           # 调 napi，实现 CaptureKit 接口（替换 MockCaptureKit）
│   └── NapiReconEngine.ets          # 实现 ReconEngine 接口（替换 MockReconEngine）
├── entry/src/main/ets/components/
│   ├── Showcase3DView.ets           # XComponent 容器，承载 3DGS native 渲染
│   ├── ScanGuideOverlay.ets         # 360° 引导环 + 角度补漏 + 低光提示
│   └── ShowcaseChrome.ets           # （地基已有；Task D7 升级光感动效）
└── entry/src/ohosTest/ets/device/   # 设备端测试（仅真机）
    ├── CaptureDevice.test.ets
    ├── ReconDevice.test.ets
    └── FullLoopDevice.test.ets
```

**依赖顺序**：NDK 骨架(D1) → Capture(D2) → 温升(D3) → Recon(D4) → napi ArkTS 包装(D5) → 渲染(D6) → 光感(D7) → 手势(D8) → 引导(D9) → 真机 prove-it(D10)。

---

## Task D1: NDK 工程结构 + napi 骨架（✅ 已完成 2026-06-26）

**Files:**
- Create: `SpatialBoutique/cpp/CMakeLists.txt`
- Create: `SpatialBoutique/cpp/napi_init.cpp`
- Modify: `SpatialBoutique/entry/build-profile.json5`（加 externalNativeOptions / abi）
- Modify: `SpatialBoutique/entry/src/main/module.json5`（如需声明 AR/Spatial Recon 权限与元服务能力）

- [ ] **Step 1: 配置 CMake 与 NDK 编译选项**

`cpp/CMakeLists.txt`（库名已实测自本机 SDK，详见 `docs/notes-ndk-api-2026-06-25.md`）：
```cmake
cmake_minimum_required(VERSION 3.5.0)
project(spatial_boutique_native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(spatial_native SHARED
    napi_init.cpp
    # D2/D3/D4 起追加：capture_kit_native.cpp / thermal_observer.cpp / recon_engine_native.cpp
)

find_library(napi-lib ace_napi.z)        # HarmonyOS 7 API 26 真名 libace_napi.z.so
# D2 起追加：
# find_library(ar-lib arengine_ndk.z)    # libarengine_ndk.z.so
# D4 起追加：
# find_library(recon-lib spatial_recon_ndk.z)  # libspatial_recon_ndk.z.so

target_link_libraries(spatial_native ${napi-lib})
```

`entry/build-profile.json5` 加 `externalNativeOptions: { path: './cpp/CMakeLists.txt', arguments, abiFilters: ['arm64-v8a'] }`，并配 `nativeLib`。

- [ ] **Step 2: napi 模块注册骨架**

`cpp/napi_init.cpp`（注册一个空模块，后续 Task 往里加方法）：
```cpp
#include "napi/native_api.h"

napi_value Init(napi_env env, napi_value exports) {
    // D2/D4/D5 在此注册：captureStart, captureStop, reconStart, reconPause, ...
    return exports;
}

extern "C" __attribute__((constructor)) void RegisterModule(void) {
    static napi_module module = {
        .nm_version = 1, .nm_flags = 0, .nm_filename = nullptr,
        .nm_register_func = Init, .nm_modname = "spatial_native",
        .nm_priv = nullptr, .nm_register_func = nullptr, .reserved = {0},
    };
    napi_module_register(&module);
}
```

- [ ] **Step 3: 真机编译验证**

在 DevEco 连真机或云调试真机，`hvigorw assembleHap`。
Expected: BUILD SUCCESSFUL，HAP 内含 `libs/arm64-v8a/libspatial_native.so`。

- [ ] **Step 4: 提交推送**

```bash
git add SpatialBoutique/cpp SpatialBoutique/entry/build-profile.json5 SpatialBoutique/entry/src/main/module.json5
git commit -m "feat(ndk): scaffold cpp module + napi registration"
git push
```

---

## Task D2: CaptureKit 真实现（AR Engine 取帧 + 推帧）

**Files:**
- Create: `SpatialBoutique/cpp/capture_kit_native.cpp`
- Modify: `SpatialBoutique/cpp/napi_init.cpp`（注册 `captureStart` / `captureStop`）

- [ ] **Step 1: 实现 AR Engine 会话与推帧**

`capture_kit_native.cpp`（签名已对照本机 SDK 实测，见 `docs/notes-ndk-api-2026-06-25.md`）：
```cpp
#include "ar/ar_engine_core.h"
#include "spatial/spatial_recon_interface.h"   // 注意 spatial/ 子目录
#include "napi/native_api.h"

static AREngine_ARSession* g_arSession = nullptr;
static AREngine_ARFrame*   g_arFrame   = nullptr;
static HMS_SpatialRecon_Session g_reconSession = nullptr; // 由 D4 注入

napi_value CaptureStart(napi_env env, napi_callback_info info) {
    // 1) 创建 + 配置 AR 会话。返回类型是 AREngine_ARStatus（不是 HMS_AREngine_*）
    AREngine_ARStatus st;
    st = HMS_AREngine_ARSession_Create(/*env*/ nullptr, /*applicationContext*/ nullptr, &g_arSession);
    if (st != ARENGINE_OK) return /* napi 抛 CaptureError */;
    AREngine_ARConfig* cfg = nullptr;
    HMS_AREngine_ARConfig_Create(g_arSession, &cfg);
    // 硬约束：预览 1080×1440
    HMS_AREngine_ARConfig_SetPreviewSize(g_arSession, cfg, 1080, 1440);
    HMS_AREngine_ARConfig_SetUpdateMode(g_arSession, cfg, ARENGINE_UPDATE_MODE_LATEST);
    HMS_AREngine_ARConfig_SetFocusMode(g_arSession, cfg, ARENGINE_FOCUS_MODE_AUTO);
    HMS_AREngine_ARSession_Configure(g_arSession, cfg);
    HMS_AREngine_ARFrame_Create(g_arSession, &g_arFrame);
    return nullptr;
}

// 每帧由渲染循环/定时器调用（D5 在 ArkTS 侧驱动）
napi_value CapturePushFrame(napi_env env, napi_callback_info info) {
    // Update 是更新 AR 结果（frame 是出参），不是推帧
    HMS_AREngine_ARSession_Update(g_arSession, g_arFrame);
    // 真正推帧给 Spatial Recon：
    HMS_SpatialRecon_PushARFrame(g_reconSession, g_arSession, g_arFrame);
    return nullptr;
}

napi_value CaptureStop(napi_env env, napi_callback_info info) {
    if (g_arSession) HMS_AREngine_ARSession_Stop(g_arSession);   // 真名 Stop 不是 Destroy
    g_arFrame = nullptr; g_arSession = nullptr;
    return nullptr;
}
```

在 `napi_init.cpp` 的 `Init` 里注册三方法：`napi_create_function(env, "captureStart", ...)` 等。

- [ ] **Step 2: RunningMode 前后台切换**

应用进前台调 `HMS_SpatialRecon_SetRunningMode(SPATIAL_RECON_RUNNING_FOREGROUND_MODE)`，切后台调 `BACKGROUND`。在 `EntryAbility` 的 `onForeground` / `onBackground` 钩子里触发（经 napi 暴露 `setRunningMode(foreground: boolean)`）。

- [ ] **Step 3: 真机验证**

云调试真机部署，进扫描页，观察相机预览（1080×1440）正常出帧、无 `SPATIAL_RECON_STATUS_FAILED`。
Expected: 预览流畅，log 无推帧失败。

- [ ] **Step 4: 提交推送**

```bash
git add SpatialBoutique/cpp
git commit -m "feat(capture): real AR Engine capture + PushARFrame at 1080x1440"
git push
```

---

## Task D3: 温升观察者

**Files:**
- Create: `SpatialBoutique/cpp/thermal_observer.cpp`
- Modify: `SpatialBoutique/cpp/napi_init.cpp`（注册 `subscribeThermal` / 回调桥到 ArkTS）

- [ ] **Step 1: 订阅温升公共事件**

`thermal_observer.cpp`（示意，API 以 `@ohos.commonEventManager` / NDK 等价为准）：
```cpp
// 订阅 COMMON_EVENT_THERMAL_LEVEL_CHANGED
// 回调里读当前 level，超过阈值 → 调 HMS_SpatialRecon_PauseSession
// 回落 → HMS_SpatialRecon_ResumeSession
// 阈值建议：THERMAL_LEVEL_OVER_HEATED 起暂停
```

通过 napi 把"过热暂停 / 降温继续"事件抛回 ArkTS，由 `NapiReconEngine` 维护状态、UI 显示"降温中"。

- [ ] **Step 2: 真机验证**

真机扫描中人为加热（跑高负载）或等自然温升，观察自动暂停 + "降温中" UI + 回落后自动续。
Expected: 过热自动暂停、降温自动续、无崩溃。

- [ ] **Step 3: 提交推送**

```bash
git add SpatialBoutique/cpp
git commit -m "feat(thermal): subscribe thermal event, auto pause/resume recon"
git push
```

---

## Task D4: ReconEngine 真实现（Spatial Recon 生命周期）

**Files:**
- Create: `SpatialBoutique/cpp/recon_engine_native.cpp`
- Modify: `SpatialBoutique/cpp/napi_init.cpp`

- [ ] **Step 1: 实现完整生命周期（签名以 `spatial_recon_interface.h` 为准）**

`recon_engine_native.cpp`（签名已对照本机 SDK 实测）：
```cpp
#include "spatial/spatial_recon_interface.h"   // 注意 spatial/ 子目录

static HMS_SpatialRecon_Session g_session = nullptr;
static bool g_running = false;

// ⭐ A0 验证专用：D2 之前就能用。云调试上点按钮调这个，立即知道重建能力是否支持。
napi_value ReconIsSupport(napi_env env, napi_callback_info info) {
    HMS_SpatialReconStatus st = HMS_SpatialRecon_IsSupport(SPATIAL_RECON_MODEL_3D /* 以 SDK 枚举真名 */);
    bool ok = (st == HMS_SPATIAL_RECON_SUCCESS);
    return /* napi_boolean(ok) */;
}

napi_value ReconCreate(napi_env env, napi_callback_info info) {
    // 真签名：CreateSession(type, workPath, &session) —— 比 plan 原稿多 workPath
    HMS_SpatialReconStatus st = HMS_SpatialRecon_CreateSession(
        SPATIAL_RECON_MODEL_3D, "/data/storage/el2/base/haps/recon", &g_session);
    return nullptr;
}

napi_value ReconStart(napi_env env, napi_callback_info info) {
    if (g_running) { /* 抛 ReconError：单 session 守卫 */ return nullptr; }
    g_running = true;
    HMS_SpatialRecon_ModelWriteInfo info = {};
    info.modelFormat = SPATIAL_RECON_OUTPUT_FORMAT_PLY; // 主产物 PLY
    HMS_SpatialRecon_StartSession(g_session, &info);
    HMS_SpatialRecon_SetRunningMode(g_session, SPATIAL_RECON_RUNNING_FOREGROUND_MODE);
    return nullptr;
}

napi_value ReconPause(napi_env env, napi_callback_info info)  { HMS_SpatialRecon_PauseSession(g_session);  return nullptr; }
napi_value ReconResume(napi_env env, napi_callback_info info) { HMS_SpatialRecon_ResumeSession(g_session); return nullptr; }

napi_value ReconProgress(napi_env env, napi_callback_info info) {
    float p = 0.0f;
    HMS_SpatialRecon_GetProgress(g_session, &p, nullptr);
    return /* napi_double(p) */;
}

napi_value ReconSave(napi_env env, napi_callback_info info) {
    HMS_SpatialRecon_ModelWriteInfo info = {};
    info.modelFormat = SPATIAL_RECON_OUTPUT_FORMAT_PLY;
    HMS_SpatialRecon_SaveResultToFile(g_session, &info, nullptr);
    return /* napi_string(plyPath) */;
}
```

- [ ] **Step 2: 真机验证（小件精品环绕扫描）**

真机扫描一件小物体（如戒指），完整环绕，观察进度 0→1，结束生成 PLY 文件落盘。
Expected: 进度单调推进、PLY 生成、`SaveResultToFile` 成功、路径可读。

- [ ] **Step 3: 提交推送**

```bash
git add SpatialBoutique/cpp
git commit -m "feat(recon): real Spatial Recon lifecycle (start/pause/resume/progress/save)"
git push
```

---

## Task D5: napi ArkTS 包装 + Mock 切换

**Files:**
- Create: `SpatialBoutique/entry/src/main/ets/recon/NapiCaptureKit.ets`
- Create: `SpatialBoutique/entry/src/main/ets/recon/NapiReconEngine.ets`
- Modify: 扫描页与 showcase 的依赖注入点（把 `new MockReconEngine(...)` 换成可注入的工厂）

- [ ] **Step 1: NapiReconEngine 实现 ReconEngine 接口**

`NapiReconEngine.ets`（示意）：
```typescript
import spatialNative from 'libspatial_native.so'; // 由 napi_init 注册的模块名
import { ReconEngine, ReconResult, ReconProgressListener } from './ReconEngine';
import { ReconError } from '../common/errors';

export class NapiReconEngine implements ReconEngine {
  private p = 0;
  async start(onProgress?: ReconProgressListener, writeMp4?: boolean): Promise<ReconResult> {
    spatialNative.reconCreate();
    spatialNative.reconStart();
    // 轮询进度（ArkTS 侧 setInterval 调 reconProgress）→ onProgress
    // 监听完成回调 → resolve { plyPath }
    // 单 session 守卫：start 抛错则 reject(new ReconError(...))
    return { plyPath: '' }; // 占位，实际由完成回调填
  }
  pause(): void  { spatialNative.reconPause(); }
  resume(): void { spatialNative.reconResume(); }
  progress(): number { return this.p; }
}
```

`NapiCaptureKit.ets` 同理调 `captureStart` / `captureStop`，并在渲染循环里 `capturePushFrame`。

- [ ] **Step 2: 引入依赖注入点**

在 `recon/` 加 `ReconFactory.ets`：根据构建配置（如 BuildProfile.DEBUG）返回 Mock 或 Napi 实现。扫描页改为从 factory 取实例，而非直接 `new MockReconEngine`。

- [ ] **Step 3: 真机验证切换**

Debug 构建仍走 Mock（模拟器可用）；Release/真机构建走 Napi。真机上确认 `NapiReconEngine.start` 能驱动 D4 的生命周期。

- [ ] **Step 4: 提交推送**

```bash
git add SpatialBoutique/entry/src/main/ets/recon
git commit -m "feat(recon): napi-backed NapiCaptureKit/NapiReconEngine + DI switch"
git push
```

---

## Task D6: 3DGS 渲染（XComponent + Spatial Recon loader）

**Files:**
- Create: `SpatialBoutique/entry/src/main/ets/components/Showcase3DView.ets`
- Modify: `SpatialBoutique/entry/src/main/ets/pages/ShowcasePage.ets`（用 Showcase3DView 替换占位）

- [ ] **Step 1: XComponent 承载 native 渲染表面**

`Showcase3DView.ets`（示意）：
```typescript
@Component
export struct Showcase3DView {
  plyPath: string = '';
  materialPreset: MaterialPresetId = MaterialPresetId.Metal;

  build() {
    XComponent({ id: 'showcase3d', type: 'surface', libraryname: 'spatial_native' })
      .onLoad(() => {
        // 调 napi: 用 Spatial Recon 「加载3DGS模型」loader 加载 plyPath
        // 应用材质预设参数（D7 细化真实光照）
      })
      .width('100%').height('100%')
  }
}
```

native 侧（`recon_engine_native.cpp` 或新文件）：在 XComponent 的 surface 上用 Spatial Recon loader 加载 PLY 并渲染。loader API 见官方「加载 3DGS 模型」文档。

- [ ] **Step 2: 真机验证渲染**

真机上扫描一件物体 → 进展示页 → 确认 PLY 以 3D 形式渲染出来（非空、有点云/网格外观）。
Expected: 模型可见、可交互（D8 加手势）。

- [ ] **Step 3: 提交推送**

```bash
git add SpatialBoutique/entry/src/main/ets/components/Showcase3DView.ets SpatialBoutique/entry/src/main/ets/pages/ShowcasePage.ets SpatialBoutique/cpp
git commit -m "feat(showcase): render 3DGS model via XComponent + Spatial Recon loader"
git push
```

---

## Task D7: 沉浸光感真实动效

> API 已确认（`docs/notes-immersive-light-sense.md`）：用 `HdsNavigation`/`HdsTabs` + `systemMaterialEffect: { materialType: IMMERSIVE, materialLevel: EXQUISITE }`，并以 `hdsMaterial.getSystemMaterialTypes()` 查询做降级（不支持 IMMERSIVE → BACKGROUND_BLUR + SMOOTH）。

**Files:**
- Modify: `SpatialBoutique/entry/src/main/ets/components/ShowcaseChrome.ets`（升级光感）
- Modify: `SpatialBoutique/entry/src/main/ets/components/Showcase3DView.ets`（光随指动跟随触点）

- [ ] **Step 1: 按确认后的 HDS 属性施加三个动效**

- **光随指动**：在 3D 视口的玻璃覆盖层，触摸/拖拽事件把触点坐标传给材质光源参数，使高光跟随手指。深色背景下尤其明显。
- **光线勾勒**：TitleBar 与主操作按钮（收藏/详情）按 HDS `TitleBarStyle` 或光描边属性，动态描边。
- **非线性形变**：底部悬浮商品卡用 HDS 弹性动效，弹出/收起有"弹性"。

把地基 Task 12 的保底 `backgroundBlurStyle` 替换为确认后的真实沉浸光感属性。

- [ ] **Step 2: 真机肉眼验证（四材质预设）**

切换金属/宝石/玻璃/哑光四个预设，确认各材质在真机上的视觉差异（金属锐高光、玻璃通透、哑光柔和等）。记录与预期的偏差，记入风险。
Expected: 四预设肉眼可辨；光随指动随拖拽流畅跟随。

- [ ] **Step 3: 提交推送**

```bash
git add SpatialBoutique/entry/src/main/ets/components docs/
git commit -m "feat(showcase): real immersive light-sense (light-follow/outline/nonlinear-deform)"
git push
```

---

## Task D8: 手势交互

**Files:**
- Modify: `SpatialBoutique/entry/src/main/ets/components/Showcase3DView.ets`

- [ ] **Step 1: 实现四种手势 + 触点驱动光源**

- 单指拖拽 → 旋转模型（把 delta 传给 native 旋转矩阵）
- 双指捏合 → 缩放（ pinch scale ）
- 双指拖拽 → 平移
- 双击 → resetView
- 任意触摸点坐标 → 驱动 D7 光随指动光源位置

ArkTS 侧用 `TouchType` / 多指识别；参数经 napi 传给 native 渲染层。

- [ ] **Step 2: 真机验证手感**

真机上四手势均生效、跟手；光随指动在拖拽时高光跟随。
Expected: 旋转/缩放/平移/复位均可，光源跟随流畅。

- [ ] **Step 3: 提交推送**

```bash
git add SpatialBoutique/entry/src/main/ets/components/Showcase3DView.ets SpatialBoutique/cpp
git commit -m "feat(showcase): gesture interaction (rotate/scale/pan/reset) + touch-driven light"
git push
```

---

## Task D9: 扫描引导 UX

**Files:**
- Create: `SpatialBoutique/entry/src/main/ets/components/ScanGuideOverlay.ets`
- Modify: `SpatialBoutique/entry/src/main/ets/pages/ScanPage.ets`

- [ ] **Step 1: 实现 360° 引导环 + 角度补漏 + 低光检测**

`ScanGuideOverlay.ets`：
- 360° 环形进度（基于已采集角度覆盖，估算自 AR 位姿）
- 多角度补漏提示（俯/仰/侧欠覆盖时高亮缺口）
- 低光检测（帧亮度统计 < 阈值 → "光线不足，请补光"）

- [ ] **Step 2: 真机验证引导有效性**

真机扫描时刻意欠覆盖/低光，确认提示出现；正常覆盖时进度环走满。
Expected: 引导环反映覆盖度、补漏/低光提示准确触发。

- [ ] **Step 3: 提交推送**

```bash
git add SpatialBoutique/entry/src/main/ets/components/ScanGuideOverlay.ets SpatialBoutique/entry/src/main/ets/pages/ScanPage.ets
git commit -m "feat(scan): guided capture overlay (360 ring + angle gaps + low-light)"
git push
```

---

## Task D10: 真机 prove-it（端到端真闭环）

**Files:**
- Create: `SpatialBoutique/entry/src/ohosTest/ets/device/FullLoopDevice.test.ets`

- [ ] **Step 1: 写真机端到端测试**

用真 AR 取帧替换地基 Task 14 的 mock fixture：captureStart → 持续 pushFrame（环绕扫描一件固定物体）→ reconStart 走完 → reconSave 得 PLY → ModelStore.save → ModelStore.list 断言 → Showcase3DView loadModel → 截图断言非空。

```typescript
// hypium，仅真机
it('full real loop: capture->recon->store->render', 0, async () => {
  const capture = new NapiCaptureKit();
  const engine = new NapiReconEngine();
  const store = new LocalModelStore(context);
  await capture.start();
  // 驱动若干帧（真机由相机自动喂帧；测试脚本里环绕物体 N 秒）
  await new Promise(r => setTimeout(r, 8000));
  const result = await engine.start();
  await store.save({ id: 'real_smoke', /* ... */ plyPath: result.plyPath, /* ... */ });
  expect((await store.list()).some(m => m.id === 'real_smoke')).assertTrue();
});
```

- [ ] **Step 2: 真机跑通**

云调试真机执行，全绿。记录耗时与模型质量基线，作为后续优化参照。

- [ ] **Step 3: 提交推送 + 收尾**

```bash
git add SpatialBoutique/entry/src/ohosTest/ets/device
git commit -m "test(device): full real end-to-end loop on device (capture->recon->store->render)"
git push
```

更新 `CLAUDE.md` 状态：P1 真机集成完成，进入 P2。

---

## 自检（writing-plans skill self-review）

- **Spec 覆盖**：spec §4 ①CaptureKit（D2/D3）、②ReconEngine（D4）、④Showcase 渲染（D6）、光感（D7）、手势（D8）、扫描引导（D9）；napi 桥（D1/D5）；真机 prove-it（D10）。spec §5 错误处理（温升 D3、单 session 守卫 D4、RunningMode D2）全覆盖。✓
- **占位符扫描**：代码块为"示意结构"，已显式声明签名以 SDK 头文件为准（D1-D4 开头与"置信度约定"第 2 条）。无 TBD/"implement later"/"add error handling"懒人占位。
- **类型一致**：`CaptureKit.start/stop`、`ReconEngine.start/pause/resume/progress`、`ReconResult.plyPath/mp4Path` 与地基计划接口一致；napi 方法名 `captureStart/PushFrame/Stop`、`reconCreate/Start/Pause/Resume/Progress/Save` 在 D1-D5 间一致。✓
- **设备门控诚实标注**：每个 Task 均有"真机验证"步骤，无任何"本地跑测试通过"的假象。✓
