/**
 * D2 A0 验证切片：在 D1 空骨架上注册一个方法 reconIsSupport。
 * 云调试上点按钮调用，立即知道当前设备/环境是否支持 Spatial Recon 3D 重建。
 *
 * 返回值：true = 支持，可投入 D2-D4 实现；false = 不支持，回方案重估。
 * 这是整个 P1 真机集成阶段的 go/no-go 节点。
 */
#include "napi/native_api.h"
#include "spatial/spatial_recon_interface.h"

static napi_value ReconIsSupport(napi_env env, napi_callback_info /*info*/) {
    // 调用真实 SDK 函数（签名见 docs/notes-ndk-api-2026-06-25.md）。
    // SPATIAL_RECON_MODEL_3D 枚举值以 SDK 头文件实际定义为准；
    // 这里取 3D 类型，对应小件精品的重建场景。
    HMS_SpatialReconStatus st = HMS_SpatialRecon_IsSupport(HMS_SPATIAL_RECON_MODEL_3D);
    bool ok = (st == HMS_SPATIAL_RECON_SUCCESS);

    napi_value result;
    napi_get_boolean(env, ok, &result);
    return result;
}

static napi_value Init(napi_env env, napi_value exports) {
    napi_value fn;
    napi_create_function(env, "reconIsSupport", NAPI_AUTO_LENGTH, ReconIsSupport, nullptr, &fn);
    napi_set_named_property(env, exports, "reconIsSupport", fn);
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
