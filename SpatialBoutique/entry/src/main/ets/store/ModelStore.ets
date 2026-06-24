/**
 * ModelStore 接口。对应地基计划 Task 4。
 * P1 只用本地实现（LocalModelStore，Task 5）；接口先定，便于后续 Task 注入 Mock / 云实现。
 */
import { ModelInfo } from '../model/ModelInfo';

export interface ModelStore {
  save(model: ModelInfo): Promise<void>;
  list(): Promise<ModelInfo[]>;
  load(id: string): Promise<ModelInfo | undefined>;
  delete(id: string): Promise<void>;
}
