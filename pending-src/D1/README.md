# pending-src/D1 · NDK 骨架暂存（Task D1）

> 真机集成计划 `docs/plan-p1-device-integration-2026-06-23.md` Task D1。
> **前置**：地基 T1–T14 全绿（含本次 ohosTest 脚手架修复 + SmokeFlow）。
> **执行环境**：DevEco Studio + AGC 云调试真机（API 26 / 7.0.0.23）。模拟器**不能**验证 NDK 功能，只能确认编译通过。

---

## 与原计划的偏差（已修正）

| # | 计划原文 | 本版修正 | 原因 |
|---|---|---|---|
| 1 | `cmake_minimum_required(are.DEFAULT_PROJECT)` | `cmake_minimum_required(VERSION 3.5.0)` | 原文语法非法（应给版本号） |
| 2 | `napi_module` 重复声明 `nm_register_func` 字段 | 仅声明一次 | 重复字段会编译失败 |
| 3 | CMakeLists 一次列 4 个 .cpp（含 D2/D3/D4 才有的） | D1 只列 `napi_init.cpp` | 其余文件 D1 时还不存在，链接会报 `Cannot find source file` |
| 4 | `cpp/` 放在 `SpatialBoutique/cpp/`（工程根） | 改放 `SpatialBoutique/entry/src/main/cpp/` | DevEco 默认 NDK 源码搜索位置；`externalNativeOptions.path` 相对 entry 模块定位更可靠 |
| 5 | `find_library(napi-lib napi)` | `find_library(napi-lib ace_napi.z)` | HarmonyOS 7 / API 26 SDK 里 napi 运行时库真名是 `libace_napi.z.so`，不是 `libnapi.so`；不改会报 `napi-lib set to NOTFOUND` |

---

## 文件清单

| 本目录内 | 贴到工程路径 |
|---|---|
| `cpp/CMakeLists.txt` | `SpatialBoutique/entry/src/main/cpp/CMakeLists.txt` |
| `cpp/napi_init.cpp` | `SpatialBoutique/entry/src/main/cpp/napi_init.cpp` |

---

## 贴入步骤

### Step 1：创建 cpp 目录与文件

1. DevEco 工程视图，右键 `entry/src/main` → New → Directory → 命名 `cpp`。
2. 把本目录 `cpp/CMakeLists.txt` 与 `cpp/napi_init.cpp` 复制到 `entry/src/main/cpp/`。

### Step 2：修改 `entry/build-profile.json5`

在 `buildOption` 里追加 `externalNativeOptions`。**完整改后形态**（保留原有 `resOptions`）：

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "",
      "abiFilters": ["arm64-v8a"]
    },
    "resOptions": {
      "copyCodeResource": {
        "enable": false
      }
    }
  },
  "buildOptionSet": [
    {
      "name": "release",
      "arkOptions": {
        "obfuscation": {
          "ruleOptions": {
            "enable": false,
            "files": ["./obfuscation-rules.txt"]
          }
        }
      }
    }
  ],
  "targets": [
    { "name": "default" },
    { "name": "ohosTest" }
  ]
}
```

> 路径 `"./src/main/cpp/CMakeLists.txt"` 相对 `entry/` 模块根。

### Step 3：`entry/src/main/module.json5` —— AR/Spatial Recon 权限（按 SDK 文档核对后再加）

⚠️ **不臆造权限名**。计划只标注"如需声明 AR/Spatial Recon 权限与元服务能力"。

实施时按以下顺序确认：

1. 查 AR Engine 文档 `ar/ar_engine_core.h` 引用要求 → 通常需 `ohos.permission.CAMERA`。
2. 查 Spatial Recon Kit 文档 → 是否有专属权限。
3. 在 `module.json5` 的 `module` 顶层加 `requestPermissions`：

```json5
"requestPermissions": [
  {
    "name": "ohos.permission.CAMERA",
    "reason": "$string:reason_camera",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
  // Spatial Recon 专属权限按文档补
]
```

并在 `entry/src/main/resources/base/element/string.json` 追加：
```json5
{ "name": "reason_camera", "value": "用于扫描商品生成 3D 模型" }
```

### Step 4：Sync 与编译验证

1. **File → Sync and Refresh Project**（让 DevEco 识别 NDK 模块）。
2. 终端：
   ```bash
   cd SpatialBoutique
   ./hvigorw assembleHap
   ```
3. **预期**：`BUILD SUCCESSFUL`，HAP 内含 `libs/arm64-v8a/libspatial_native.so`。
   - 检查路径：`entry/build/default/outputs/default/entry-default-signed.hap`（解压后看 `libs/arm64-v8a/`）。

### Step 5：提交推送

```bash
cd "D:/yfj/02-work/AI/Codex/harmonyos-spatial-commerce"
git add SpatialBoutique/entry/src/main/cpp \
        SpatialBoutique/entry/build-profile.json5 \
        SpatialBoutique/entry/src/main/module.json5 \
        SpatialBoutique/entry/src/main/resources/base/element/string.json
git commit -m "feat(ndk): scaffold cpp module + napi registration (D1)"
git push
```

---

## 常见踩坑

- **`Cannot find napi/native_api.h`** → NDK 路径未配置。DevEco：File → Project Structure → SDK 位置确认；`local.properties` 里 `sdk.externalNativeModules` 配置。
- **`napi_module_register` 链接失败** → CMakeLists 未链接 `${napi-lib}`（本版已链）。
- **HAP 内无 .so** → `abiFilters` 与目标设备 ABI 不匹配；真机/云调试一律 `arm64-v8a`。
- **Sync 后 cpp 目录不被识别** → `externalNativeOptions.path` 写成绝对路径或相对路径层级错。务必相对 `entry/`。

---

## 后续衔接

- D2 在 `napi_init.cpp` 的 `Init` 里注册 `captureStart/PushFrame/Stop/setRunningMode`，新建 `capture_kit_native.cpp` 并加入 CMakeLists。
- D3 新建 `thermal_observer.cpp`。
- D4 新建 `recon_engine_native.cpp`。
- 每加一个 .cpp，CMakeLists 的 `add_library(... )` 列表要同步追加，`target_link_libraries` 加入对应 SDK 库。
