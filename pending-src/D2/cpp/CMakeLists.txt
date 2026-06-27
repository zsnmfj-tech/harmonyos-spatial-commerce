# D2 A0 验证切片：在 D1 骨架上最小增量 —— 加 spatial_recon_ndk.z 链接 + reconIsSupport。
# 这个 CMakeLists 是 D1 完成态的"下一版"，整份替换 entry/src/main/cpp/CMakeLists.txt。
# 不加 capture_kit_native.cpp / recon_engine_native.cpp —— 那是 D2 完整版 / D4 的事。

cmake_minimum_required(VERSION 3.5.0)
project(spatial_boutique_native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(spatial_native SHARED
    napi_init.cpp
)

find_library(napi-lib ace_napi.z)
find_library(recon-lib spatial_recon_ndk.z)   # A0 验证只需 Spatial Recon

target_link_libraries(spatial_native
    ${napi-lib}
    ${recon-lib}
)
