# pending-src/D2 · A0 验证切片（最小可编译）

> **目的**：在 D1 骨架上做最小增量，让你**点一个按钮**就知道云调试真机是否支持 Spatial Recon 重建。
> **不是 D2 完整实现**。完整 D2（真 AR Engine CaptureKit）等 A0 通过后再写。
> **前置**：D1 完成（✅ 2026-06-26）。

---

## 文件清单

| 本目录内 | 贴到工程路径 | 说明 |
|---|---|---|
| `cpp/CMakeLists.txt` | `entry/src/main/cpp/CMakeLists.txt` | **整份替换** D1 版：加 spatial_recon_ndk.z 链接 |
| `cpp/napi_init.cpp` | `entry/src/main/cpp/napi_init.cpp` | **整份替换** D1 版：注册 reconIsSupport 方法 |
| `entry/src/main/ets/recon/NapiReconProbe.ets` | 同左 | napi 调用封装（新建） |
| `entry/src/main/ets/pages/ReconSupportProbePage.ets` | 同左 | 探测页 UI（新建） |

---

## 贴入步骤

### Step 1：替换两个 cpp 文件

把 D1 完成态的 `CMakeLists.txt` 和 `napi_init.cpp` 用本目录的版本整份覆盖（D2 A0 是 D1 的超集 + 一个新方法）。

### Step 2：新建 ArkTS 包装与探测页

按表格路径新建两个 .ets 文件。

### Step 3：把探测页接到能打开的入口

最简单：临时改 `entry/src/main/ets/pages/Index.ets`，把根容器内容临时换成：

```typescript
import { ReconSupportProbePage } from './ReconSupportProbePage';

@Entry
@Component
struct Index {
  build() {
    Column() {
      ReconSupportProbePage();
    }
    .width('100%').height('100%');
  }
}
```

> 验证完恢复原 Index.ets 内容（即 TabBar）。

### Step 4：Sync + 构建 Release HAP

```
DevEco: File → Sync and Refresh Project
DevEco: Build → Clean Project
DevEco: Build Variants 面板 → entry 切到 release
DevEco: Build → Build Hap(s)/APP(s) → Build Hap(s)
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`（HarmonyOS 不在文件名区分 debug/release；以 Build 视图日志 `buildMode=release` 为准）。

### Step 5：上传云调试 + 验证

1. 上传新构建的 HAP 到云调试真机 → 安装 → 启动 App
2. 应见到 A0 探测页 → 点"开始探测"
3. 看结果：

| 结果 | 含义 | 下一步 |
|---|---|---|
| ✅ 支持 | 云调试虚拟化了相机/IMU 或透传到位，Spatial Recon 可用 | 写完整 D2（真 AR Engine CaptureKit） |
| ❌ 不支持 | 云调试明确不支持，远程环境透传不到 AR 链路 | 项目级风险，重估方案（借真机 / 攒新机 / 改方向） |
| ⚠️ 调用异常 | 编译/链接问题，常见：枚举名不符、权限缺失、.so 没打包进去 | 把异常 message 贴给我 debug |

---

## 常见踩坑

- **`HMS_SPATIAL_RECON_MODEL_3D` 枚举名编译失败** → 不同 SDK 版本枚举常量名可能略不同，到 `spatial/spatial_recon_interface.h` 找 `enum HMS_SpatialReconModelType` 里的实际成员名替换。
- **`libspatial_native.so` 装到真机后加载失败（dlopen failed）** → CMakeLists 没链 `${recon-lib}`，或 ABI 不匹配（必须 arm64-v8a）。
- **`HMS_SpatialRecon_IsSupport` 链接报 undefined reference** → 同上，CMakeLists 的 link_libraries 漏了。
- **按钮点了无反应/直接闪退** → 看 hdc log（云调试有日志面板），抓 native crash 栈。

---

## 验证完的处理

- 通过：把 Index.ets 恢复成 TabBar，A0 切片可保留（作为后续 D2 开发期的 sanity check）或移除。
- 不通过：保留探测页，把项目转向「等待真机」状态，A0 切片作为后续真机到位时的第一次验证工具。

---

## 与后续 D2 完整版的关系

A0 切片只覆盖"能力探测"这一个小函数。完整 D2（按 `plan-p1-device-integration-2026-06-23.md` Task D2）会：
- 新增 `capture_kit_native.cpp`（AR Engine 会话 + 取帧 + 推帧）
- `napi_init.cpp` 增加 captureStart / capturePushFrame / captureStop / setRunningMode 注册
- `CMakeLists.txt` 加 `find_library(ar-lib arengine_ndk.z)` 与对应链接
- 权限申请：`ohos.permission.CAMERA` 等

A0 通过后，**完整 D2 代码我会在新一轮会话里预写到 `pending-src/D2-full/`**（避免与 A0 切片混淆）。
