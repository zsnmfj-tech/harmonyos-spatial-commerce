/**
 * 材质预设（小件精品四类）
 * 对应地基计划 Task 2。商家扫描后选一个，存进 ModelInfo.materialPreset。
 * 真机渲染时由 Showcase 按这些参数 + 3DGS loader 的光照风格呈现。
 */

/** 材质预设枚举（字符串值，便于持久化到 RelationalStore） */
export enum MaterialPresetId {
  Metal = 'metal',
  Gem = 'gem',
  Glass = 'glass',
  Matte = 'matte',
}

/** 单个材质预设的参数（PBR 取向 + 风格化色调 + 展示标签） */
export interface MaterialParams {
  /** 0..1，PBR 粗糙度 */
  roughness: number;
  /** 0..1，PBR 金属度 */
  metalness: number;
  /** 0..1，透射（玻璃/宝石用） */
  transmission: number;
  /** 环境色调，用于风格化 */
  tint: ResourceColor;
  /** 展示用标签（走资源，便于 i18n） */
  label: ResourceStr;
}

/** 四个材质预设。键用枚举保证类型安全。 */
export const MATERIAL_PRESETS: Record<MaterialPresetId, MaterialParams> = {
  [MaterialPresetId.Metal]: {
    roughness: 0.12,
    metalness: 1.0,
    transmission: 0.0,
    tint: '#C8CED8',
    label: $r('app.string.mat_metal'),
  },
  [MaterialPresetId.Gem]: {
    roughness: 0.05,
    metalness: 0.0,
    transmission: 0.85,
    tint: '#7FE0FF',
    label: $r('app.string.mat_gem'),
  },
  [MaterialPresetId.Glass]: {
    roughness: 0.02,
    metalness: 0.0,
    transmission: 0.95,
    tint: '#E8F4FF',
    label: $r('app.string.mat_glass'),
  },
  [MaterialPresetId.Matte]: {
    roughness: 0.85,
    metalness: 0.0,
    transmission: 0.0,
    tint: '#D9CDB8',
    label: $r('app.string.mat_matte'),
  },
};
