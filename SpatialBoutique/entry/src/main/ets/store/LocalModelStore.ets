/**
 * LocalModelStore —— ModelStore 的本地 RelationalStore 实现。对应地基计划 Task 5。
 *
 * ArkTS 严格模式相对 plan 原文（TS 风格）的修正：
 *  - 不用构造器参数属性（arkts-no-ctor-prop-decls）：字段显式声明 + 构造体内赋值。
 *  - 不用索引访问 ValuesBucket（arkts-no-aliases-by-index）：改用 ResultSet 的
 *    getColumnIndex + getString/getLong 按列读，绕开 row['x'] 与 ModelInfo['x']。
 *  - 不用对象展开（arkts-no-spread）：ValuesBucket 显式逐字段构造。
 *  - list() 用 querySql（原 SQL 字符串重载已移除，db.query 只接 RdbPredicates）。
 */
import { relationalStore } from '@kit.ArkData';
import common from '@ohos.app.ability.common';
import { ModelStore } from './ModelStore';
import { ModelInfo } from '../model/ModelInfo';
import { MaterialPresetId } from '../model/MaterialPreset';

const TABLE = 'models';

function rowToModel(rs: relationalStore.ResultSet): ModelInfo {
  return {
    id: rs.getString(rs.getColumnIndex('id')),
    name: rs.getString(rs.getColumnIndex('name')),
    category: rs.getString(rs.getColumnIndex('category')),
    createdAt: rs.getLong(rs.getColumnIndex('createdAt')),
    thumbnailPath: rs.getString(rs.getColumnIndex('thumbnailPath')),
    plyPath: rs.getString(rs.getColumnIndex('plyPath')),
    materialPreset: rs.getString(rs.getColumnIndex('materialPreset')) as MaterialPresetId,
  };
}

export class LocalModelStore implements ModelStore {
  private rdb?: relationalStore.RdbStore;
  private context: common.Context;
  private dbName: string;

  constructor(context: common.Context, dbName: string = 'models.db') {
    this.context = context;
    this.dbName = dbName;
  }

  private async db(): Promise<relationalStore.RdbStore> {
    if (this.rdb) return this.rdb;
    this.rdb = await relationalStore.getRdbStore(this.context, {
      name: this.dbName,
      securityLevel: relationalStore.SecurityLevel.S1,
    });
    await this.rdb.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      createdAt INTEGER NOT NULL,
      thumbnailPath TEXT NOT NULL,
      plyPath TEXT NOT NULL,
      materialPreset TEXT NOT NULL
    )`);
    return this.rdb;
  }

  async save(model: ModelInfo): Promise<void> {
    const db = await this.db();
    const bucket: relationalStore.ValuesBucket = {
      id: model.id,
      name: model.name,
      category: model.category,
      createdAt: model.createdAt,
      thumbnailPath: model.thumbnailPath,
      plyPath: model.plyPath,
      materialPreset: model.materialPreset,
    };
    await db.insert(TABLE, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async list(): Promise<ModelInfo[]> {
    const db = await this.db();
    const rs = await db.querySql(`SELECT * FROM ${TABLE} ORDER BY createdAt DESC`, []);
    const out: ModelInfo[] = [];
    while (rs.goToNextRow()) out.push(rowToModel(rs));
    rs.close();
    return out;
  }

  async load(id: string): Promise<ModelInfo | undefined> {
    const db = await this.db();
    const pred = new relationalStore.RdbPredicates(TABLE);
    pred.equalTo('id', id);
    const rs = await db.query(pred, []);
    const out = rs.goToNextRow() ? rowToModel(rs) : undefined;
    rs.close();
    return out;
  }

  async delete(id: string): Promise<void> {
    const db = await this.db();
    const pred = new relationalStore.RdbPredicates(TABLE);
    pred.equalTo('id', id);
    await db.delete(pred);
  }
}
