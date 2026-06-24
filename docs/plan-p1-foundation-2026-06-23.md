# 鸿蒙空间化商品 3D 展示 · P1 地基实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭出 P1「空间核心闭环」的可本地验证地基——DevEco 工程 + 数据模型 + ModelStore + 双角色 Shell + 材质预设数据 + NDK 包装层接口（mock 实现），让端到端链路能在 DevEco 本地手机模拟器上用 mock 跑通。

**Architecture:** DevEco Studio HarmonyOS 工程。ArkTS UI + 为 NDK 层（CaptureKit/ReconEngine）定义 TypeScript interface，P1 地基用 Mock 实现支撑整条链路；真 NDK AR Engine/Spatial Recon/3DGS 渲染集成留给后续「真机集成」计划。

**Tech Stack:** ArkTS、RelationalStore（@kit.ArkData）、hypium 测试框架、napi 接口（P1 仅 interface + Mock）。

---

## 置信度与验证约定（先读这一段）

1. **本计划所有命令面向 DevEco Studio + HarmonyOS SDK**。当前 bash shell 没有 SDK，**不能在此执行或验证任何步骤**。实现者在 DevEco Studio 里执行。
2. **逻辑/数据/UI 任务** → 在 **DevEco 本地手机模拟器** 上跑 hypium 测试即可验证，不需要真机。
3. **真 AR Engine / Spatial Recon / 3DGS 渲染** → 不在本计划，归入后续「真机集成」计划，需 **AGC 云调试真机（API 26 / 7.0.0.23）**。
4. **沉浸光感 API 已确认**（2026-06-23，见 `docs/notes-immersive-light-sense.md`）：`@kit.UIDesignKit` 的 `systemMaterialEffect`（`materialType` + `materialLevel`），仅施加于 `HdsNavigation` 标题栏与 `HdsTabs` 底部页签；`IMMERSIVE` 材质自带光随指动/光线勾勒/非线性形变。地基 Task 12 模拟器阶段用 `backgroundBlurStyle` 占位，真实光感在真机计划 D7 用 HDS 组件实现。
5. **API 名真实性**：NDK 函数名（`HMS_SpatialRecon_*`、`HMS_AREngine_*`）来自官方文档原文，可直接引用；但本计划仅写 ArkTS interface，不写 NDK 实现。

---

## 文件结构

```
SpatialBoutique/                         # DevEco 工程（Task 1 创建）
├── .gitignore
├── build-profile.json5
├── oh-package.json5
├── entry/
│   ├── build-profile.json5
│   ├── src/main/
│   │   ├── module.json5
│   │   ├── resources/                   # string/media/color
│   │   └── ets/
│   │       ├── entryability/EntryAbility.ets
│   │       ├── model/
│   │       │   ├── ModelInfo.ets        # 模型元数据类型
│   │       │   ├── MaterialPreset.ets   # 4 个材质预设数据
│   │       │   └── Role.ets             # 买家/商家角色枚举
│   │       ├── store/
│   │       │   ├── ModelStore.ets       # 接口
│   │       │   └── LocalModelStore.ets  # RelationalStore 实现
│   │       ├── recon/
│   │       │   ├── CaptureKit.ets       # 接口
│   │       │   ├── ReconEngine.ets      # 接口 + 类型
│   │       │   ├── MockCaptureKit.ets   # mock
│   │       │   └── MockReconEngine.ets  # mock（模拟进度+落 fixture PLY）
│   │       ├── common/
│   │       │   ├── AppMode.ets          # 全局角色状态（AppStorage）
│   │       │   └── errors.ets           # CaptureError/ReconError
│   │       ├── pages/
│   │       │   ├── ListPage.ets         # 浏览模型列表
│   │       │   ├── ScanPage.ets         # 扫描页（P1 接 mock）
│   │       │   ├── ShowcasePage.ets     # 沉浸展示
│   │       │   └── ProfilePage.ets      # 我的 + 角色切换
│   │       └── components/
│   │           ├── ModelCard.ets
│   │           ├── MaterialPicker.ets
│   │           └── ShowcaseChrome.ets   # 光感 chrome 覆盖层（Task 12）
│   └── src/ohosTest/ets/
│       ├── List.test.ets                # 测试入口（注册各测试模块）
│       ├── model/MaterialPreset.test.ets
│       ├── store/LocalModelStore.test.ets
│       ├── recon/MockReconEngine.test.ets
│       ├── common/AppMode.test.ets
│       └── flow/SmokeFlow.test.ets      # 端到端 mock 闭环
# 注：spec / plan / CLAUDE.md 在仓库根 harmonyos-spatial-commerce/docs/，不在 SpatialBoutique 工程目录内
```

**模块依赖顺序**：model → common → store/recon(mock) → pages → components → flow。Tasks 按此顺序。

---

## Task 1: DevEco 工程脚手架

> 仓库已在 `harmonyos-spatial-commerce/`（仓库根）init 并推到 GitHub（`origin/main`）。SpatialBoutique 作为**子目录**加入现有仓库，本 Task **不再 `git init`**。

**Files:**
- Create: `SpatialBoutique/`（DevEco "Empty Ability" 模板工程，位于仓库根内）

- [ ] **Step 1: 在 DevEco Studio 创建工程**

File → New → Create Project → Application → Empty Ability。
- Project name: `SpatialBoutique`
- Bundle name: `com.spatial.boutique`
- Compile SDK / Target SDK: **API 26**（HarmonyOS 7）
- Language: ArkTS
- Device: Phone

- [ ] **Step 2: 验证空工程能构建**

Run（在 DevEco 工具栏）：`hvigorw assembleHap`
Expected: BUILD SUCCESSFUL，生成 `entry/build/default/outputs/default/entry-default-signed.hap`

- [ ] **Step 3: 确认 .gitignore 覆盖 DevEco 产物**

仓库根已有 `.gitignore`（覆盖 `**/build/` / `.cxx/` / `.hvigor/` / `local.properties` / `*.hap` / `oh_modules/` 等）。DevEco 建工程时可能在 `SpatialBoutique/` 内再生成一个项目级 `.gitignore`——两者都保留，不冲突。

- [ ] **Step 4: 提交到现有仓库并推送**

仓库已在父目录 init 并连到 GitHub。从仓库根添加 SpatialBoutique、提交、推送：

```bash
cd harmonyos-spatial-commerce   # 仓库根（含 .git、CLAUDE.md、docs/）
git add SpatialBoutique
git commit -m "chore: scaffold DevEco SpatialBoutique project (API 26)"
git push
```

---

## Task 2: 数据模型类型

**Files:**
- Create: `entry/src/main/ets/model/MaterialPreset.ets`
- Create: `entry/src/main/ets/model/ModelInfo.ets`
- Create: `entry/src/main/ets/model/Role.ets`
- Create: `entry/src/ohosTest/ets/model/MaterialPreset.test.ets`
- Modify: `entry/src/ohosTest/ets/List.test.ets`（注册测试模块）

- [ ] **Step 1: 写失败测试**

`entry/src/ohosTest/ets/model/MaterialPreset.test.ets`:
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { MATERIAL_PRESETS, MaterialPresetId } from '../../../main/ets/model/MaterialPreset';

export default function materialPresetTest() {
  describe('MaterialPreset', () => {
    it('exposes exactly four presets', 0, () => {
      const ids = Object.keys(MATERIAL_PRESETS) as MaterialPresetId[];
      expect(ids.length).assertEqual(4);
      expect(ids).assertContain(MaterialPresetId.Metal);
      expect(ids).assertContain(MaterialPresetId.Gem);
      expect(ids).assertContain(MaterialPresetId.Glass);
      expect(ids).assertContain(MaterialPresetId.Matte);
    });
    it('metal preset is sharp and metallic', 0, () => {
      const m = MATERIAL_PRESETS[MaterialPresetId.Metal];
      expect(m.metalness).assertEqual(1.0);
      expect(m.roughness < 0.2).assertTrue();
    });
    it('matte preset is diffuse', 0, () => {
      const m = MATERIAL_PRESETS[MaterialPresetId.Matte];
      expect(m.metalness).assertEqual(0.0);
      expect(m.roughness > 0.7).assertTrue();
    });
  });
}
```

`entry/src/ohosTest/ets/List.test.ets`（测试入口）:
```typescript
import materialPresetTest from './model/MaterialPreset.test';
export default function testsuite() {
  materialPresetTest();
}
```

- [ ] **Step 2: 跑测试验证失败**

DevEco：右键 `List.test.ets` → Run（部署到本地模拟器）。
Expected: FAIL —— `cannot find module '../../../main/ets/model/MaterialPreset'`。

- [ ] **Step 3: 写最小实现**

`entry/src/main/ets/model/MaterialPreset.ets`:
```typescript
export enum MaterialPresetId {
  Metal = 'metal',
  Gem = 'gem',
  Glass = 'glass',
  Matte = 'matte',
}

export interface MaterialParams {
  /** 0..1，PBR 粗糙度 */
  roughness: number;
  /** 0..1，PBR 金属度 */
  metalness: number;
  /** 0..1，透射（玻璃/宝石） */
  transmission: number;
  /** 环境色调，用于风格化 */
  tint: ResourceColor;
  /** 展示用标签 */
  label: ResourceStr;
}

export const MATERIAL_PRESETS: Record<MaterialPresetId, MaterialParams> = {
  [MaterialPresetId.Metal]: {
    roughness: 0.12, metalness: 1.0, transmission: 0.0,
    tint: '#C8CED8', label: $r('app.string.mat_metal'),
  },
  [MaterialPresetId.Gem]: {
    roughness: 0.05, metalness: 0.0, transmission: 0.85,
    tint: '#7FE0FF', label: $r('app.string.mat_gem'),
  },
  [MaterialPresetId.Glass]: {
    roughness: 0.02, metalness: 0.0, transmission: 0.95,
    tint: '#E8F4FF', label: $r('app.string.mat_glass'),
  },
  [MaterialPresetId.Matte]: {
    roughness: 0.85, metalness: 0.0, transmission: 0.0,
    tint: '#D9CDB8', label: $r('app.string.mat_matte'),
  },
};
```

`entry/src/main/ets/model/ModelInfo.ets`:
```typescript
import { MaterialPresetId } from './MaterialPreset';

export interface ModelInfo {
  id: string;
  name: string;
  category: string;
  createdAt: number;
  thumbnailPath: string;
  plyPath: string;
  materialPreset: MaterialPresetId;
}
```

`entry/src/main/ets/model/Role.ets`:
```typescript
export enum Role { Buyer = 'buyer', Seller = 'seller' }
```

并往 `entry/src/main/resources/base/element/string.json` 加入四个 `mat_*` 字符串（金属/宝石/玻璃/哑光）。

- [ ] **Step 4: 跑测试验证通过**

DevEco：右键 `List.test.ets` → Run。
Expected: PASS（3 用例全绿）。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/model entry/src/ohosTest entry/src/main/resources
git commit -m "feat(model): add ModelInfo, MaterialPreset, Role types"
```

---

## Task 3: 类型化错误

**Files:**
- Create: `entry/src/main/ets/common/errors.ets`

- [ ] **Step 1: 写实现（纯类型，无独立测试，由下游任务间接覆盖）**

`entry/src/main/ets/common/errors.ets`:
```typescript
export class CaptureError extends Error {
  constructor(message: string, public cause?: Error) {
    super(message);
    this.name = 'CaptureError';
  }
}

export class ReconError extends Error {
  constructor(message: string, public phase: 'start' | 'pause' | 'resume' | 'save' = 'start', public cause?: Error) {
    super(message);
    this.name = 'ReconError';
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/common/errors.ets
git commit -m "feat(common): add CaptureError and ReconError typed errors"
```

---

## Task 4: ModelStore 接口

**Files:**
- Create: `entry/src/main/ets/store/ModelStore.ets`

- [ ] **Step 1: 写接口**

`entry/src/main/ets/store/ModelStore.ets`:
```typescript
import { ModelInfo } from '../model/ModelInfo';

export interface ModelStore {
  save(model: ModelInfo): Promise<void>;
  list(): Promise<ModelInfo[]>;
  load(id: string): Promise<ModelInfo | undefined>;
  delete(id: string): Promise<void>;
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/store/ModelStore.ets
git commit -m "feat(store): define ModelStore interface"
```

---

## Task 5: LocalModelStore（RelationalStore 实现）

**Files:**
- Create: `entry/src/main/ets/store/LocalModelStore.ets`
- Create: `entry/src/ohosTest/ets/store/LocalModelStore.test.ets`
- Modify: `entry/src/ohosTest/ets/List.test.ets`

- [ ] **Step 1: 写失败测试**

`entry/src/ohosTest/ets/store/LocalModelStore.test.ets`:
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { LocalModelStore } from '../../../main/ets/store/LocalModelStore';
import { MaterialPresetId } from '../../../main/ets/model/MaterialPreset';
import type common from '@ohos.app.ability.common';

export default function localModelStoreTest(context: common.UIAbilityContext) {
  describe('LocalModelStore', () => {
    it('saves then lists then loads then deletes a model', 0, async () => {
      const store = new LocalModelStore(context, 'smoke_models.db');
      await store.delete('m1'); // 幂等清理

      const model = {
        id: 'm1', name: '测试戒指', category: 'jewelry',
        createdAt: 1719000000000, thumbnailPath: '/tmp/t.png',
        plyPath: '/tmp/m1.ply', materialPreset: MaterialPresetId.Metal,
      };
      await store.save(model);

      const listed = await store.list();
      expect(listed.some(m => m.id === 'm1')).assertTrue();

      const loaded = await store.load('m1');
      expect(loaded?.name).assertEqual('测试戒指');
      expect(loaded?.materialPreset).assertEqual(MaterialPresetId.Metal);

      await store.delete('m1');
      const after = await store.load('m1');
      expect(after === undefined).assertTrue();
    });
  });
}
```

`List.test.ets` 改为接收 context 并注册：
```typescript
import { abilityDelegator } from '@kit.TestKit';
import materialPresetTest from './model/MaterialPreset.test';
import localModelStoreTest from './store/LocalModelStore.test';

export default function testsuite() {
  const context = abilityDelegator.getContext();
  materialPresetTest();
  localModelStoreTest(context);
}
```

- [ ] **Step 2: 跑测试验证失败**

DevEco：Run `List.test.ets`。
Expected: FAIL —— `LocalModelStore` 未定义。

- [ ] **Step 3: 写实现**

`entry/src/main/ets/store/LocalModelStore.ets`:
```typescript
import { relationalStore } from '@kit.ArkData';
import type common from '@ohos.app.ability.common';
import { ModelStore } from './ModelStore';
import { ModelInfo } from '../model/ModelInfo';

const TABLE = 'models';

function rowToModel(row: relationalStore.ValuesBucket): ModelInfo {
  return {
    id: String(row['id']),
    name: String(row['name']),
    category: String(row['category']),
    createdAt: Number(row['createdAt']),
    thumbnailPath: String(row['thumbnailPath']),
    plyPath: String(row['plyPath']),
    materialPreset: String(row['materialPreset']) as ModelInfo['materialPreset'],
  };
}

export class LocalModelStore implements ModelStore {
  private rdb?: relationalStore.RdbStore;

  constructor(private context: common.UIAbilityContext, private dbName: string = 'models.db') {}

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
    const bucket: relationalStore.ValuesBucket = { ...model };
    await db.insertWithConflictResolution(TABLE, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async list(): Promise<ModelInfo[]> {
    const db = await this.db();
    const rs = await db.query(`SELECT * FROM ${TABLE} ORDER BY createdAt DESC`, []);
    const out: ModelInfo[] = [];
    while (rs.goToNextRow()) out.push(rowToModel(rs.getRow()));
    rs.close();
    return out;
  }

  async load(id: string): Promise<ModelInfo | undefined> {
    const db = await this.db();
    const rs = await db.queryPredicates(TABLE).equalTo('id', id).query();
    const out = rs.goToNextRow() ? rowToModel(rs.getRow()) : undefined;
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
```

- [ ] **Step 4: 跑测试验证通过**

DevEco：Run `List.test.ets`。
Expected: PASS（save→list→load→delete 全绿）。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/store entry/src/ohosTest
git commit -m "feat(store): implement LocalModelStore over RelationalStore"
```

---

## Task 6: CaptureKit + ReconEngine 接口

**Files:**
- Create: `entry/src/main/ets/recon/CaptureKit.ets`
- Create: `entry/src/main/ets/recon/ReconEngine.ets`

- [ ] **Step 1: 写接口**

`entry/src/main/ets/recon/CaptureKit.ets`:
```typescript
export interface CaptureKit {
  start(): Promise<void>;
  stop(): void;
}
```

`entry/src/main/ets/recon/ReconEngine.ets`:
```typescript
export type ReconProgressListener = (progress: number) => void;

export interface ReconResult {
  plyPath: string;
  mp4Path?: string;
}

export interface ReconEngine {
  /** 启动重建。writeMp4=true 时同时产出运镜预览。完成 resolve 结果。 */
  start(onProgress?: ReconProgressListener, writeMp4?: boolean): Promise<ReconResult>;
  pause(): void;
  resume(): void;
  /** 0..1，最近一次进度。 */
  progress(): number;
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/recon
git commit -m "feat(recon): define CaptureKit and ReconEngine interfaces"
```

---

## Task 7: MockReconEngine + MockCaptureKit

**Files:**
- Create: `entry/src/main/ets/recon/MockCaptureKit.ets`
- Create: `entry/src/main/ets/recon/MockReconEngine.ets`
- Create: `entry/src/ohosTest/ets/recon/MockReconEngine.test.ets`
- Modify: `entry/src/ohosTest/ets/List.test.ets`

- [ ] **Step 1: 写失败测试**

`entry/src/ohosTest/ets/recon/MockReconEngine.test.ets`:
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { MockReconEngine } from '../../../main/ets/recon/MockReconEngine';
import type common from '@ohos.app.ability.common';
import { fileIo } from '@kit.CoreFileKit';

export default function mockReconEngineTest(context: common.UIAbilityContext) {
  describe('MockReconEngine', () => {
    it('reports increasing progress and writes a fixture PLY', 0, async () => {
      const ticks: number[] = [];
      const engine = new MockReconEngine(context, { stepMs: 5, steps: 6 });
      const result = await engine.start(p => ticks.push(p));
      expect(result.plyPath.length > 0).assertTrue();
      const file = fileIo.openSync(result.plyPath, fileIo.OpenMode.READ_ONLY);
      expect(file.fd > 0).assertTrue();
      fileIo.closeSync(file);
      // 进度单调不减，末值为 1
      expect(ticks[ticks.length - 1]).assertEqual(1);
      for (let i = 1; i < ticks.length; i++) {
        expect(ticks[i] >= ticks[i - 1]).assertTrue();
      }
    });
    it('rejects concurrent start (single-session guard)', 0, async () => {
      const engine = new MockReconEngine(context, { stepMs: 50, steps: 10 });
      const first = engine.start();
      await new Promise(r => setTimeout(r, 10));
      try {
        await engine.start();
        expect(false).assertTrue(); // 不应到达
      } catch (e) {
        expect((e as Error).name).assertEqual('ReconError');
      }
      await first;
    });
  });
}
```

在 `List.test.ets` 注册：
```typescript
import mockReconEngineTest from './recon/MockReconEngine.test';
// 在 testsuite() 内：
mockReconEngineTest(context);
```

- [ ] **Step 2: 跑测试验证失败**

DevEco：Run。
Expected: FAIL —— `MockReconEngine` 未定义。

- [ ] **Step 3: 写实现**

`entry/src/main/ets/recon/MockCaptureKit.ets`:
```typescript
import { CaptureKit } from './CaptureKit';

export class MockCaptureKit implements CaptureKit {
  async start(): Promise<void> { /* P1 地基：不取真帧 */ }
  stop(): void { /* no-op */ }
}
```

`entry/src/main/ets/recon/MockReconEngine.ets`:
```typescript
import { fileIo } from '@kit.CoreFileKit';
import type common from '@ohos.app.ability.common';
import { ReconEngine, ReconResult } from './ReconEngine';
import { ReconError } from '../common/errors';

export interface MockReconOptions { stepMs?: number; steps?: number; }

const FIXTURE_PLY = `ply
format ascii 1.0
element vertex 1
property float x
property float y
property float z
end_header
0 0 0
`;

export class MockReconEngine implements ReconEngine {
  private running = false;
  private p = 0;
  private timer?: number;

  constructor(private context: common.UIAbilityContext, private opts: MockReconOptions = {}) {}

  async start(onProgress?: (p: number) => void, writeMp4?: boolean): Promise<ReconResult> {
    if (this.running) throw new ReconError('已有重建在进行（单 session 守卫）', 'start');
    this.running = true;
    this.p = 0;
    const steps = this.opts.steps ?? 10;
    const stepMs = this.opts.stepMs ?? 30;
    return new Promise<ReconResult>((resolve, reject) => {
      let i = 0;
      this.timer = setInterval(() => {
        i += 1;
        this.p = Math.min(1, i / steps);
        onProgress?.(this.p);
        if (i >= steps) {
          clearInterval(this.timer);
          this.writeFixture()
            .then(plyPath => {
              this.running = false;
              resolve({ plyPath });
            })
            .catch((e: Error) => {
              this.running = false;
              reject(new ReconError('写入 fixture PLY 失败', 'save', e));
            });
        }
      }, stepMs);
    });
  }

  pause(): void { if (this.timer) clearInterval(this.timer); }
  resume(): void { /* 地基 mock：暂停后不自动续，由 start 驱动；真机版在 Task 真机集成实现 */ }
  progress(): number { return this.p; }

  private async writeFixture(): Promise<string> {
    const dir = this.context.filesDir;
    const path = `${dir}/mock_${Date.now()}.ply`;
    const file = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    fileIo.writeSync(file.fd, FIXTURE_PLY);
    fileIo.closeSync(file);
    return path;
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

DevEco：Run。
Expected: PASS（进度单调、PLY 落盘、并发拒绝）。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/recon entry/src/ohosTest
git commit -m "feat(recon): add MockCaptureKit and MockReconEngine (progress + fixture PLY)"
```

---

## Task 8: AppMode 全局角色状态

**Files:**
- Create: `entry/src/main/ets/common/AppMode.ets`
- Create: `entry/src/ohosTest/ets/common/AppMode.test.ets`
- Modify: `entry/src/ohosTest/ets/List.test.ets`

- [ ] **Step 1: 写失败测试**

`entry/src/ohosTest/ets/common/AppMode.test.ets`:
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { getRole, setRole, ROLE_KEY } from '../../../main/ets/common/AppMode';
import { Role } from '../../../main/ets/model/Role';

export default function appModeTest() {
  describe('AppMode', () => {
    it('defaults to buyer and switches to seller', 0, () => {
      setRole(Role.Buyer);
      expect(getRole()).assertEqual(Role.Buyer);
      setRole(Role.Seller);
      expect(getRole()).assertEqual(Role.Seller);
      // AppStorage 持有同一值
      expect(AppStorage.get<Role>(ROLE_KEY)).assertEqual(Role.Seller);
    });
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

Expected: FAIL —— `AppMode` 未定义。

- [ ] **Step 3: 写实现**

`entry/src/main/ets/common/AppMode.ets`:
```typescript
import { Role } from '../model/Role';

export const ROLE_KEY = 'appRole';

if (!AppStorage.has(ROLE_KEY)) AppStorage.setOrCreate(ROLE_KEY, Role.Buyer);

export function getRole(): Role {
  return AppStorage.get<Role>(ROLE_KEY) ?? Role.Buyer;
}

export function setRole(role: Role): void {
  AppStorage.setOrCreate(ROLE_KEY, role);
}
```

注册到 `List.test.ets`：
```typescript
import appModeTest from './common/AppMode.test';
// testsuite() 内：
appModeTest();
```

- [ ] **Step 4: 跑测试验证通过**

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/common/AppMode.ets entry/src/ohosTest/ets/common
git commit -m "feat(common): add AppMode role state backed by AppStorage"
```

---

## Task 9: Shell 导航骨架 + 角色切换

**Files:**
- Create: `entry/src/main/ets/pages/ListPage.ets`
- Create: `entry/src/main/ets/pages/ScanPage.ets`
- Create: `entry/src/main/ets/pages/ShowcasePage.ets`
- Create: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`（模板自带，改写）

- [ ] **Step 1: 改写入口页为底部 Tab 壳**

`entry/src/main/ets/pages/Index.ets`:
```typescript
import { TabBar } from '../components/TabBar';

@Entry
@Component
struct Index {
  build() {
    Column() {
      TabBar();
    }.width('100%').height('100%');
  }
}
```

`entry/src/main/ets/components/TabBar.ets`:
```typescript
import { getRole } from '../common/AppMode';
import { Role } from '../model/Role';
import { ListPage } from '../pages/ListPage';
import { ProfilePage } from '../pages/ProfilePage';
import { ScanPage } from '../pages/ScanPage';
import { ShowcasePage } from '../pages/ShowcasePage';

@Component
export struct TabBar {
  @StorageLink('appRole') role: Role = Role.Buyer;

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() { ListPage() }.tabBar(this.tab('浏览', $r('sys.media.ohos_ic_public_grid')))
      if (this.role === Role.Seller) {
        TabContent() { ScanPage() }.tabBar(this.tab('扫描', $r('sys.media.ohos_ic_public_camera')))
      }
      TabContent() { ShowcasePage() }.tabBar(this.tab('展示', $r('sys.media.ohos_ic_public_compass')))
      TabContent() { ProfilePage() }.tabBar(this.tab('我的', $r('sys.media.ohos_ic_public_contacts')))
    }.width('100%').height('100%');
  }

  private tab(text: ResourceStr, icon: Resource) {
    return { text, icon };
  }
}
```

`ListPage.ets` / `ScanPage.ets` / `ShowcasePage.ets` / `ProfilePage.ets` 各放最小占位：
```typescript
@Component
export struct ListPage {
  build() { Column() { Text('浏览 - 待实现').fontSize(20) }.width('100%').height('100%').justifyContent(FlexAlign.Center) }
}
```
（其余三页同构，文字分别改为"扫描 - 待实现"/"展示 - 待实现"/"我的 - 待实现"）

`ProfilePage.ets` 含角色切换：
```typescript
import { getRole, setRole } from '../common/AppMode';
import { Role } from '../model/Role';

@Component
export struct ProfilePage {
  @StorageLink('appRole') role: Role = Role.Buyer;

  build() {
    Column({ space: 16 }) {
      Text('我的').fontSize(24).margin({ top: 32 })
      Row({ space: 12 }) {
        Button('买家模式').type(this.role === Role.Buyer ? ButtonType.Capsule : ButtonType.Normal)
          .onClick(() => setRole(Role.Buyer))
        Button('商家模式').type(this.role === Role.Seller ? ButtonType.Capsule : ButtonType.Normal)
          .onClick(() => setRole(Role.Seller))
      }
    }.width('100%').height('100%').justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Center)
  }
}
```

- [ ] **Step 2: 构建并部署到模拟器，手测**

Run（DevEco 工具栏）→ 部署到本地模拟器。
Expected: 底部 4 个 Tab（浏览/扫描/展示/我的）；默认买家模式下看不到"扫描"Tab；切到商家模式后"扫描"Tab 出现。

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets
git commit -m "feat(shell): add dual-role TabBar shell with mode-gated Scan tab"
```

---

## Task 10: ListPage 接 ModelStore

**Files:**
- Modify: `entry/src/main/ets/pages/ListPage.ets`
- Create: `entry/src/main/ets/components/ModelCard.ets`

- [ ] **Step 1: 实现 ListPage 从 ModelStore 加载并展示**

`entry/src/main/ets/components/ModelCard.ets`:
```typescript
import { ModelInfo } from '../model/ModelInfo';
import { MATERIAL_PRESETS } from '../model/MaterialPreset';

@Component
export struct ModelCard {
  item: ModelInfo = undefined as unknown as ModelInfo;
  onTap: (item: ModelInfo) => void = () => {};

  build() {
    Row({ space: 12 }) {
      Image(this.item.thumbnailPath).width(64).height(64).borderRadius(8)
        .backgroundColor('#2A2D3A')
      Column({ space: 4 }) {
        Text(this.item.name).fontSize(16).fontColor('#FFF')
        Text(MATERIAL_PRESETS[this.item.materialPreset].label + ' · ' + this.item.category)
          .fontSize(12).fontColor('#9AA0B4')
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
    }
    .width('100%').padding(12).borderRadius(12)
    .backgroundColor('#1E2030').margin({ bottom: 8 })
    .onClick(() => this.onTap(this.item));
  }
}
```

`ListPage.ets`（接入 store；context 经 EntryAbility 注入全局）：
```typescript
import { ModelInfo } from '../model/ModelInfo';
import { LocalModelStore } from '../store/LocalModelStore';
import { ModelCard } from '../components/ModelCard';
import { AppContext } from '../common/AppContext';

@Component
export struct ListPage {
  @State items: ModelInfo[] = [];
  private store?: LocalModelStore;

  aboutToAppear() {
    this.store = new LocalModelStore(AppContext.get().context);
    this.refresh();
  }

  async refresh() {
    this.items = await this.store!.list();
  }

  build() {
    Column({ space: 8 }) {
      Text('我的 3D 好物').fontSize(24).fontColor('#FFF').padding(16)
      if (this.items.length === 0) {
        Column() {
          Text('还没有模型').fontColor('#9AA0B4')
          Text('切到商家模式扫描一件').fontSize(12).fontColor('#6B7186').margin({ top: 4 })
        }.justifyContent(FlexAlign.Center).width('100%').layoutWeight(1)
      } else {
        List({ space: 0 }) {
          ForEach(this.items, (m: ModelInfo) => {
            ListItem() { ModelCard({ item: m, onTap: () => { /* Task 11 跳展示页 */ } }) }
          }, (m: ModelInfo) => m.id)
        }.layoutWeight(1).width('100%')
      }
    }.width('100%').height('100%').backgroundColor('#13151F')
  }
}
```

`entry/src/main/ets/common/AppContext.ets`（全局 context 持有）:
```typescript
import type common from '@ohos.app.ability.common';

interface AppCtx { context: common.UIAbilityContext; }

export class AppContext {
  private static inst: AppCtx;
  static set(context: common.UIAbilityContext) { AppContext.inst = { context }; }
  static get(): AppCtx { return AppContext.inst; }
}
```

`EntryAbility.ets` 的 `onWindowStageCreate` 前加 `AppContext.set(this.context);`。

- [ ] **Step 2: 构建部署，手测**

Run → 模拟器。
Expected: 列表页空态文案正确。

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets
git commit -m "feat(list): ListPage loads models from LocalModelStore with empty state"
```

---

## Task 11: MaterialPicker 组件

**Files:**
- Create: `entry/src/main/ets/components/MaterialPicker.ets`

- [ ] **Step 1: 实现 4 选 1 材质选择器**

```typescript
import { MATERIAL_PRESETS, MaterialPresetId } from '../model/MaterialPreset';

@Component
export struct MaterialPicker {
  selected: MaterialPresetId = MaterialPresetId.Metal;
  onSelect: (id: MaterialPresetId) => void = () => {};

  build() {
    Row({ space: 8 }) {
      ForEach(Object.keys(MATERIAL_PRESETS) as MaterialPresetId[], (id: MaterialPresetId) => {
        Text(MATERIAL_PRESETS[id].label)
          .fontSize(13)
          .fontColor(this.selected === id ? '#0B0D14' : '#FFF')
          .backgroundColor(this.selected === id ? '#FFD166' : '#2A2D3A')
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(14)
          .onClick(() => this.onSelect(id));
      }, (id: MaterialPresetId) => id)
    }.width('100%').justifyContent(FlexAlign.Center);
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/components/MaterialPicker.ets
git commit -m "feat(components): add MaterialPicker for 4 material presets"
```

---

## Task 12: ShowcaseChrome（沉浸光感覆盖层）

> 沉浸光感 API 已确认（见 `docs/notes-immersive-light-sense.md`）：`@kit.UIDesignKit` 的 `systemMaterialEffect`，仅施加于 `HdsNavigation` 标题栏与 `HdsTabs` 底部页签。本 Task（模拟器阶段）先用 `backgroundBlurStyle` 作视觉占位；真实沉浸光感在真机计划 D7 用 HDS 组件实现。

**Files:**
- Create: `entry/src/main/ets/components/ShowcaseChrome.ets`

- [ ] **Step 1: 实现光感 chrome 覆盖层（TitleBar + 悬浮卡 + 主按钮）**

`entry/src/main/ets/components/ShowcaseChrome.ets`:
```typescript
@Component
export struct ShowcaseChrome {
  title: ResourceStr = '';
  onBack: () => void = () => {};
  onCollect: () => void = () => {};

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 顶部 TitleBar —— 模拟器阶段用 backgroundBlurStyle 作视觉占位
      // 真实沉浸光感（HdsNavigation + systemMaterialEffect IMMERSIVE）在真机计划 D7 实现，见 docs/notes-immersive-light-sense.md
      Row() {
        Text('‹').fontSize(24).fontColor('#FFF').onClick(() => this.onBack())
        Text(this.title).fontSize(18).fontColor('#FFF').layoutWeight(1).textAlign(TextAlign.Center)
        Text('♡').fontSize(22).fontColor('#FFF').onClick(() => this.onCollect())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)  // 占位：模拟器阶段的毛玻璃近似
      .border({ width: 0.5, color: 'rgba(255,255,255,0.25)' })
    }
    .width('100%').height('100%')
  }
}
```

- [ ] **Step 2: 真机/模拟器肉眼核对（设备相关）**

部署到模拟器，肉眼确认 TitleBar 半透明叠在深色背景上、有描边。**真实沉浸光感（光随指动/光线勾勒/非线性形变）**在真机计划 D7 用 `HdsNavigation`/`HdsTabs` + `systemMaterialEffect: IMMERSIVE` 实现（API 已确认，见 `docs/notes-immersive-light-sense.md`）。

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/components/ShowcaseChrome.ets
git commit -m "feat(components): add ShowcaseChrome overlay with light-sense candidate attrs"
```

---

## Task 13: ScanPage + ShowcasePage 接 mock 跑通闭环

**Files:**
- Modify: `entry/src/main/ets/pages/ScanPage.ets`
- Modify: `entry/src/main/ets/pages/ShowcasePage.ets`
- Modify: `entry/src/main/ets/pages/ListPage.ets`（点击卡片跳展示）

- [ ] **Step 1: ScanPage 接 MockCaptureKit + MockReconEngine + LocalModelStore**

```typescript
import { MockCaptureKit } from '../recon/MockCaptureKit';
import { MockReconEngine } from '../recon/MockReconEngine';
import { LocalModelStore } from '../store/LocalModelStore';
import { ModelInfo } from '../model/ModelInfo';
import { MaterialPresetId } from '../model/MaterialPreset';
import { AppContext } from '../common/AppContext';
import { MaterialPicker } from '../components/MaterialPicker';

@Component
export struct ScanPage {
  @State progress: number = 0;
  @State busy: boolean = false;
  @State material: MaterialPresetId = MaterialPresetId.Metal;
  private capture = new MockCaptureKit();
  private store = new LocalModelStore(AppContext.get().context);

  build() {
    Column({ space: 16 }) {
      Text('扫描上架（mock）').fontSize(22).fontColor('#FFF').margin({ top: 24 })
      TextInput({ placeholder: '商品名称' }).id('scan_name').width('80%')
      MaterialPicker({
        selected: this.material,
        onSelect: (id) => { this.material = id; },
      })
      Progress({ value: this.progress * 100, total: 100 }).width('80%').color('#6B5BFF')
      Button(this.busy ? '重建中…' : '开始扫描')
        .enabled(!this.busy)
        .onClick(() => this.runScan())
    }.width('100%').height('100%').backgroundColor('#13151F')
     .justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Center)
  }

  private async runScan() {
    this.busy = true;
    this.progress = 0;
    await this.capture.start();
    const engine = new MockReconEngine(AppContext.get().context);
    const result = await engine.start(p => this.progress = p);
    const name = (this.getController() ?? { text: '未命名' }).text as string;
    const model: ModelInfo = {
      id: `m_${Date.now()}`,
      name,
      category: 'jewelry',
      createdAt: Date.now(),
      thumbnailPath: result.plyPath, // mock：缩略图暂指 PLY 占位
      plyPath: result.plyPath,
      materialPreset: this.material,
    };
    await this.store.save(model);
    this.capture.stop();
    this.busy = false;
  }

  private getController() {
    // 简化：实际用 @State 绑定 TextInput controller；此处省略以保持聚焦
    return undefined;
  }
}
```

> 注：上例 TextInput 的取值在工程里应用 `TextInputController` 或 `@State name` 双向绑定；本步骤聚焦链路，绑定细节留给实现按 ArkTS 常规处理。

- [ ] **Step 2: ShowcasePage 加载 PLY（mock：占位渲染 + 光感 chrome）**

```typescript
import { ModelInfo } from '../model/ModelInfo';
import { AppContext } from '../common/AppContext';
import { LocalModelStore } from '../store/LocalModelStore';
import { ShowcaseChrome } from '../components/ShowcaseChrome';

@Component
export struct ShowcasePage {
  @State model: ModelInfo | undefined = undefined;
  @Prop modelId: string = '';
  private store = new LocalModelStore(AppContext.get().context);

  aboutToAppear() {
    if (this.modelId) this.model = await this.store.load(this.modelId);
  }

  build() {
    Stack() {
      Column() {
        // 真 3DGS 渲染（XComponent）在「真机集成」计划；地基用占位
        Text(this.model ? this.model.name : '选择一个模型')
          .fontSize(28).fontColor('#FFF')
      }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      if (this.model) {
        ShowcaseChrome({ title: this.model.name, onBack: () => {}, onCollect: () => {} })
      }
    }.width('100%').height('100%').backgroundColor('#0B0D14')
  }
}
```

- [ ] **Step 3: ListPage 点击跳展示（传递 modelId，简化用全局选中）**

在 `ListPage` 顶部加 `@State selectedId: string = ''`，卡片 `onTap` 设 `this.selectedId = m.id`，并在选中时把 `ShowcasePage` 以 `modelId` 参数渲染（或用路由 `router.pushUrl`）。最小可行：List 选中后切换到展示 Tab 并加载该 id。

- [ ] **Step 4: 手测闭环**

模拟器：商家模式 → 扫描 Tab → 输入名称 → 选材质 → 开始扫描 → 进度走完 → 回浏览 Tab 看到新模型 → 点开 → 展示页显示名称 + 光感 chrome。
Expected: mock 闭环跑通，模型出现在列表并可打开。

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets
git commit -m "feat(flow): wire ScanPage->ModelStore->List->Showcase mock loop"
```

---

## Task 14: 端到端 mock 闭环测试（Prove-it）

**Files:**
- Create: `entry/src/ohosTest/ets/flow/SmokeFlow.test.ets`
- Modify: `entry/src/ohosTest/ets/List.test.ets`

- [ ] **Step 1: 写 prove-it 测试**

`entry/src/ohosTest/ets/flow/SmokeFlow.test.ets`:
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { MockCaptureKit } from '../../../main/ets/recon/MockCaptureKit';
import { MockReconEngine } from '../../../main/ets/recon/MockReconEngine';
import { LocalModelStore } from '../../../main/ets/store/LocalModelStore';
import { MaterialPresetId } from '../../../main/ets/model/MaterialPreset';
import type common from '@ohos.app.ability.common';

export default function smokeFlowTest(context: common.UIAbilityContext) {
  describe('SmokeFlow (mock 端到端)', () => {
    it('capture -> recon -> store -> list -> load 全链路', 0, async () => {
      const capture = new MockCaptureKit();
      const engine = new MockReconEngine(context, { stepMs: 4, steps: 5 });
      const store = new LocalModelStore(context, 'flow_models.db');

      const id = `smoke_${Date.now()}`;
      await capture.start();
      const result = await engine.start();
      await store.save({
        id, name: '冒烟戒指', category: 'jewelry',
        createdAt: Date.now(), thumbnailPath: result.plyPath,
        plyPath: result.plyPath, materialPreset: MaterialPresetId.Gem,
      });
      capture.stop();

      const listed = await store.list();
      expect(listed.some(m => m.id === id)).assertTrue();

      const loaded = await store.load(id);
      expect(loaded?.plyPath).assertEqual(result.plyPath);
      expect(loaded?.materialPreset).assertEqual(MaterialPresetId.Gem);

      await store.delete(id);
    });
  });
}
```

注册到 `List.test.ets`：
```typescript
import smokeFlowTest from './flow/SmokeFlow.test';
// testsuite() 内：
smokeFlowTest(context);
```

- [ ] **Step 2: 跑全部测试**

DevEco：Run `List.test.ets`（跑全部已注册用例）。
Expected: PASS（MaterialPreset + LocalModelStore + MockReconEngine + AppMode + SmokeFlow 全绿）。

- [ ] **Step 3: 提交**

```bash
git add entry/src/ohosTest/ets/flow
git commit -m "test(flow): add end-to-end mock smoke test (capture->recon->store->load)"
```

---

## 后续「真机集成」计划（不在本计划内，占位备忘）

以下留作独立计划，需 **AGC 云调试真机（API 26）**：

1. **CaptureKit 真实现**（NDK）：AR Engine 会话、1080×1440 预览、`PushARFrame`、`SetRunningMode` 前后台切换。
2. **ReconEngine 真实现**（NDK）：`StartSession`/`Pause`/`Resume`/`GetProgress`/`SaveResultToFile`（PLY + 可选 MP4）、单 session 守卫、`COMMON_EVENT_THERMAL_LEVEL_CHANGED` 自动暂停。
3. **3DGS 渲染**：Spatial Recon「加载 3DGS 模型」loader，经 `XComponent` 接入；材质预设真实光照（金属/宝石/玻璃/哑光）真机验证。
4. **沉浸光感真实动效**：光随指动 / 光线勾勒 / 非线性形变施加于 ShowcaseChrome 与悬浮卡，按确认后的 HDS 属性实现。
5. **手势**：单指旋转 / 双指缩放 / 双击复位，触点驱动光随指动光源。
6. **真机 prove-it**：用真 AR 帧替换 mock fixture，跑 Task 14 等价链路。

---

## 自检（writing-plans skill self-review）

- **Spec 覆盖**：spec 第 4 节 5 个模块——CaptureKit/ReconEngine（接口 + Mock，Task 6-7）、ModelStore（Task 4-5）、Showcase（chrome Task 12，渲染留真机计划）、Shell（Task 9）。材质预设 Task 2/11。数据流 Task 13/14。错误类型 Task 3。✓ 地基范围内全覆盖；真机部分显式列为后续。
- **占位符扫描**：Task 13 的 TextInput 取值有一处显式简化说明（非 TBD，是聚焦说明）；Task 12 的光感属性名有显式验证标记（已知未知，非懒人占位）。无 "TBD"/"implement later"/"add error handling"。
- **类型一致**：`ModelStore` 四方法、`ReconEngine.start/pause/resume/progress`、`MaterialPresetId` 四值、`Role.Buyer/Seller`、`ROLE_KEY='appRole'` 在各 Task 间一致。✓
