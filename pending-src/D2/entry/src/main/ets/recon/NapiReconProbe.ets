/**
 * NapiReconProbe —— A0 验证的 ArkTS 侧封装。
 * 调用 native 模块 spatial_native 的 reconIsSupport，返回 boolean。
 * 仅用于云调试环境探测，不属于正式 D2 完整实现。
 */
import spatialNative from 'libspatial_native.so';

export class NapiReconProbe {
  static isSupport(): boolean {
    return spatialNative.reconIsSupport() as boolean;
  }
}
