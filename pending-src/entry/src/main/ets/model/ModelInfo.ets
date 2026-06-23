/**
 * 模型元数据类型。对应地基计划 Task 2。
 * 一个 ModelInfo = 一次重建产物 + 商家填的商品信息。
 */
import { MaterialPresetId } from './MaterialPreset';

export interface ModelInfo {
  /** 主键（如 `m_<timestamp>`） */
  id: string;
  /** 商品名 */
  name: string;
  /** 品类（如 jewelry / figure / collectible） */
  category: string;
  /** 创建时间（毫秒） */
  createdAt: number;
  /** 缩略图路径（app sandbox 内） */
  thumbnailPath: string;
  /** 重建产物 PLY 路径（展示原料） */
  plyPath: string;
  /** 材质预设 */
  materialPreset: MaterialPresetId;
}
