# spatial_boutique_native —— HarmonyOS NDK napi 模块（D1 骨架）
# 真机集成计划 Task D1：仅注册空模块，编译产出 libspatial_native.so。
# D2/D3/D4 起把 capture_kit_native.cpp / thermal_observer.cpp / recon_engine_native.cpp
# 追加到 add_library 列表，并在 target_link_libraries 加入对应 SDK 库。

cmake_minimum_required(VERSION 3.5.0)
project(spatial_boutique_native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(spatial_native SHARED
    napi_init.cpp
)

find_library(napi-lib napi)

# AR Engine / Spatial Recon 的 .so 名以 SDK 实际头文件链接要求为准。
# D2 起追加（示意，按 SDK 真名调整）：
#   target_link_libraries(spatial_native ${napi-lib} hms_ar_engine hms_spatial_recon)
target_link_libraries(spatial_native
    ${napi-lib}
)
