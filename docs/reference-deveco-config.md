# DevEco 工程配置参考（Task 1 脚手架后合并用）

> 用法：按地基 Task 1 用 DevEco「Empty Ability」向导建工程后，把本文档的片段**合并**进向导生成的 json5。
> 不要把本文档当完整工程——向导会生成全套 boilerplate，本文只补向导不自动生成的部分（权限 / NDK / 依赖 / 光感声明）。
> 带 ⚠️ 的字段需对照实际 SDK 核验（字段名/路径以 DevEco 实际导出为准）。

## 1. `AppScope/app.json5`（应用级，向导填，核对）

```json5
{
  "app": {
    "bundleName": "com.spatial.boutique",
    "vendor": "zsnmfj-tech",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name",
    "minAPIVersion": 26,      // 沉浸光感扩展在 7；Spatial Recon 起 6.1.0(23)，统一锁 26
    "targetAPIVersion": 26
  }
}
```

## 2. `build-profile.json5`（工程根，向导填，核对）

```json5
{
  "app": {
    "signingConfigs": [],      // 本地构建可空；正式签名在 DevEco 里配
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "compatibleSdkVersion": "5.0.0(26)",   // ⚠️ 以 DevEco 实际 API 26 版本号为准
        "targetSdkVersion": "5.0.0(26)",
        "runtimeOS": "HarmonyOS"
      }
    ]
  }
}
```

## 3. `entry/build-profile.json5`（模块级，**加 NDK/CMake**）

地基阶段不需要 NDK；真机集成计划 D1 加 CMake 时用这段 `externalNativeOptions`：

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "./cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "",
      "abiFilters": ["arm64-v8a"]
    }
  },
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    },
    {
      "name": "ohosTest"     // hypium 测试目标
    }
  ]
}
```

## 4. `entry/src/main/module.json5`（**加相机权限 + AR/Spatial Recon 元数据**）

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "deviceTypes": ["phone"],          // P1 手机优先；P2 加 tablet
    "abilities": [ /* EntryAbility，向导生成 */ ],
    "requestPermissions": [
      {
        "name": "ohos.permission.CAMERA",
        "reason": "$string:reason_camera",
        "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" }
      }
      // ⚠️ AR Engine / Spatial Recon 若需额外元数据或权限（如 hiAI 模型、空间能力声明），
      //    对照官方「Spatial Recon Kit 简介」「AR Engine 接入」文档补 metadata / requestPermissions。
    ]
    // "metadata": [...]   // ⚠️ 如官方要求声明 AR/Spatial Recon 能力，在此补
  }
}
```

> 关键：相机权限是硬要求（AR Engine 取帧必须）。运行时还需在 ArkTS 用 `@ohos.abilityAccessCtrl` 动态申请 `ohos.permission.CAMERA`（参考地基计划捕获流程）。

## 5. `oh-package.json5`（**加 hypium 测试依赖**）

工程根 `oh-package.json5`（向导生成，一般无需改）。`entry/oh-package.json5` 加测试依赖：

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "dependencies": {},
  "devDependencies": {
    "@ohos/hypium": "1.0.21"   // ⚠️ 版本以 DevEco 实际可用为准
  }
}
```

> 沉浸光感用的 `@kit.UIDesignKit` 与 Spatial Recon 的 NDK 是**系统 Kit / 原生库**，不需要在 oh-package 声明依赖；ArkTS 侧直接 `import { hdsMaterial, HdsTabs } from '@kit.UIDesignKit'`，NDK 侧在 CMake 里链接 `hms_ar_engine` / `hms_spatial_recon`（见真机计划 D1）。

## 6. 向导已处理 vs 需手动加（清单）

| 项 | 向导自动 | 需手动（本文档片段） |
|---|---|---|
| bundleName / version / icon / label | ✅ | 核对 API 26 |
| signingConfigs / products | ✅ | 核对 compatibleSdkVersion |
| EntryAbility / pages 路由 | ✅ | — |
| `module.json5` requestPermissions CAMERA | ❌ | **本文 §4** |
| AR/Spatial Recon metadata（若有） | ❌ | **本文 §4 ⚠️ 核验** |
| NDK/CMake externalNativeOptions | ❌（地基不需要） | 真机 D1 加，**本文 §3** |
| hypium devDependency | ❌ | **本文 §5** |

## 7. 验证

合并后在 DevEco：
1. `hvigorw assembleHap` 成功（地基阶段，无 NDK）。
2. 模拟器跑起来能请求相机权限（地基阶段相机为空，真 AR 在真机）。
3. 进入真机计划 D1 后，加 §3 的 CMake 配置 + cpp/ 目录，编译出 `libspatial_native.so`。
