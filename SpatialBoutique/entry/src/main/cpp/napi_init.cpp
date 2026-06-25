/**
 * spatial_native napi 模块注册入口（D1 骨架）。
 *
 * 后续 Task 在 Init 里挂载方法（用 napi_create_function + napi_set_named_property）：
 *   D2: captureStart / capturePushFrame / captureStop / setRunningMode
 *   D3: subscribeThermal
 *   D4: reconCreate / reconStart / reconPause / reconResume / reconProgress / reconSave
 *
 * 模块名 "spatial_native" 与 CMakeLists 的 target 一致；
 * ArkTS 侧 `import spatialNative from 'libspatial_native.so'`。
 */
#include "napi/native_api.h"

static napi_value Init(napi_env env, napi_value exports) {
    // D2/D3/D4 在此注册方法
    return exports;
}

static napi_module g_spatialNativeModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "spatial_native",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterSpatialNativeModule(void) {
    napi_module_register(&g_spatialNativeModule);
}
