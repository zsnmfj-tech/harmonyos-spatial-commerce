# NDK API 速查（AR Engine + Spatial Recon）· 2026-06-25

> 实测自本机 SDK：`D:\Program Files\Huawei\DevEco Studio\sdk\default\hms\native\`。
> 用于 D2（真 CaptureKit）/ D4（真 ReconEngine）实现，修正真机集成计划里的示意偏差。

---

## 链接库真名（CMake `find_library` 第二参数）

| Kit | .so 真名 | find_library 写法 | 头文件 |
|---|---|---|---|
| napi | `libace_napi.z.so` | `find_library(napi-lib ace_napi.z)` | `napi/native_api.h` |
| AR Engine | `libarengine_ndk.z.so` | `find_library(ar-lib arengine_ndk.z)` | `ar/ar_engine_core.h` |
| Spatial Recon | `libspatial_recon_ndk.z.so` | `find_library(recon-lib spatial_recon_ndk.z)` | `spatial/spatial_recon_interface.h` |

⚠️ 计划原文写的 `hms_ar_engine` / `hms_spatial_recon` 是错的，按本文档为准。

---

## AR Engine 关键 API（D2 用到）

头文件：`hms/native/sysroot/usr/include/ar/ar_engine_core.h`（4523 行）
返回类型：**`AREngine_ARStatus`**（不是 `HMS_AREngine_*`）
句柄类型：`AREngine_ARSession*` / `AREngine_ARConfig*` / `AREngine_ARFrame*`（opaque 指针）

### 会话生命周期

```c
// 创建会话——签名比计划多两个前置参数
AREngine_ARStatus HMS_AREngine_ARSession_Create(
    void *env,                          // JNI 环境（OHOS 上可传 nullptr）
    void *applicationContext,           // 应用 Context（OHOS 上可传 nullptr）
    AREngine_ARSession **outSession);

AREngine_ARStatus HMS_AREngine_ARSession_Configure(
    AREngine_ARSession *session, const AREngine_ARConfig *config);

AREngine_ARStatus HMS_AREngine_ARSession_Update(
    AREngine_ARSession *session, AREngine_ARFrame *outFrame);  // outFrame 是出参，不是入参

AREngine_ARStatus HMS_AREngine_ARSession_Pause(AREngine_ARSession *session);
AREngine_ARStatus HMS_AREngine_ARSession_Resume(AREngine_ARSession *session);
AREngine_ARStatus HMS_AREngine_ARSession_Stop(AREngine_ARSession *session);
```

### 配置（D2 硬约束：1080×1440 + Update + Focus）

```c
AREngine_ARStatus HMS_AREngine_ARConfig_Create(
    const AREngine_ARSession *session, AREngine_ARConfig **outConfig);

AREngine_ARStatus HMS_AREngine_ARConfig_SetPreviewSize(
    const AREngine_ARSession *session, AREngine_ARConfig *config,
    int32_t width, int32_t height);   // 1080, 1440

AREngine_ARStatus HMS_AREngine_ARConfig_SetUpdateMode(
    const AREngine_ARSession *session, AREngine_ARConfig *config,
    AREngine_ARUpdateMode mode);       // ARENGINE_UPDATE_MODE_LATEST

AREngine_ARStatus HMS_AREngine_ARConfig_SetFocusMode(
    const AREngine_ARSession *session, AREngine_ARConfig *config,
    AREngine_ARFocusMode mode);        // ARENGINE_FOCUS_MODE_AUTO
```

### 帧

```c
AREngine_ARStatus HMS_AREngine_ARFrame_Create(
    const AREngine_ARSession *session, AREngine_ARFrame **outFrame);
```

> D2 流程：Create session → Create config → Set 三参数 → Configure → Create frame → 循环 Update(session, frame)。

---

## Spatial Recon 关键 API（D4 用到）

头文件：`hms/native/sysroot/usr/include/spatial/spatial_recon_interface.h`（527 行）
返回类型：**`HMS_SpatialReconStatus`**
句柄类型：`HMS_SpatialRecon_Session`

### ⭐ 能力探测（A0 云调试验证用！）

```c
HMS_SpatialReconStatus HMS_SpatialRecon_IsSupport(HMS_SpatialReconModelType type);
```

**A0 验证捷径**：D2 之前可以先在云调试上写一行代码调 `IsSupport`，立即知道云调试是否支持重建能力，不用跑完整 AR 链路。

### 生命周期（与计划对照）

```c
HMS_SpatialReconStatus HMS_SpatialRecon_CreateSession(
    HMS_SpatialReconModelType type,
    const char* workPath,               // 工作目录（落临时文件）
    HMS_SpatialRecon_Session *outSession);

HMS_SpatialReconStatus HMS_SpatialRecon_PushARFrame(
    HMS_SpatialRecon_Session *session,
    const AREngine_ARSession *arSession,
    const AREngine_ARFrame *arFrame);   // D2/D4 桥接点

HMS_SpatialReconStatus HMS_SpatialRecon_StartSession(
    HMS_SpatialRecon_Session *session, /* params */);

HMS_SpatialReconStatus HMS_SpatialRecon_SetRunningMode(
    HMS_SpatialRecon_Session *session,
    HMS_SpatialReconRunningMode mode);  // FOREGROUND / BACKGROUND

HMS_SpatialReconStatus HMS_SpatialRecon_PauseSession(HMS_SpatialRecon_Session *session);
HMS_SpatialReconStatus HMS_SpatialRecon_ResumeSession(HMS_SpatialRecon_Session *session);

HMS_SpatialReconStatus HMS_SpatialRecon_GetProgress(
    HMS_SpatialRecon_Session *session, float *outProgress, /* ... */);

HMS_SpatialReconStatus HMS_SpatialRecon_GetRefinedFrame(
    HMS_SpatialRecon_Session *session, /* 出参：精修帧 */);

HMS_SpatialReconStatus HMS_SpatialRecon_SaveResultToFile(
    HMS_SpatialRecon_Session *session,
    const HMS_SpatialRecon_ModelWriteInfo *info,
    const char *outPath);

HMS_SpatialReconStatus HMS_SpatialRecon_DestroySession(HMS_SpatialRecon_Session *session);
```

---

## D2/D4 实现时的偏差修正清单

| 计划原文（示意） | 实测真名 |
|---|---|
| `find_library(... hms_ar_engine)` | `find_library(... arengine_ndk.z)` |
| `find_library(... hms_spatial_recon)` | `find_library(... spatial_recon_ndk.z)` |
| `HMS_AREngine_ARSession_Create(nullptr, nullptr, &session)` | `HMS_AREngine_ARSession_Create(env, applicationContext, &session)` |
| 返回 `HMS_AREngine_*` | 实际是 `AREngine_ARStatus` |
| `HMS_AREngine_ARSession_Update(session, frame)` 推帧 | 实际是更新 AR 结果，frame 是出参；推帧用 `HMS_SpatialRecon_PushARFrame` |
| 单独 `HMS_SpatialRecon_Create(&session)` | 实际是 `CreateSession(type, workPath, &session)` |
| （未提） | 多了 `IsSupport` 与 `GetRefinedFrame`，分别用于能力探测和精修帧获取 |

---

## A0 验证捷径（云调试 AR 可用性）

不必跑完整 AR Hello-AR sample。**最小验证 = 在 D2 之前先写个 napi 函数调 `HMS_SpatialRecon_IsSupport`**：

1. 在 `napi_init.cpp` 注册一个 `reconIsSupport` napi 函数。
2. 它内部调 `HMS_SpatialRecon_IsSupport(SPATIAL_RECON_MODEL_3D)` 返回 bool。
3. ArkTS 侧在测试页加一个按钮，点它调 `reconIsSupport()`。
4. 在云调试真机上跑：
   - 返回 **true** → 重建能力可用，可投入 D2-D4。
   - 返回 **false** 或会话创建失败 → 云调试明确不支持，回到方案重估。

这比跑华为 AR Engine sample 快得多（sample 还得自己编 HAP），且答案更精确（直接问的是 Spatial Recon，正是 D4 依赖的能力）。

---

## 引用

- 头文件原文（本机）：`sdk/default/hms/native/sysroot/usr/include/ar/ar_engine_core.h`
- 头文件原文（本机）：`sdk/default/hms/native/sysroot/usr/include/spatial/spatial_recon_interface.h`
- AR Engine 示例代码：https://developer.huawei.com/consumer/cn/doc/graphics-Examples/sample-code-0000001050148898
- HarmonyOS Codelabs（GitHub）：https://github.com/huaweicodelabs/harmonyos-codelabs
