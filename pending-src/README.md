# pending-src · 地基 Task 2–3 源码暂存

> 这里是**还没接入工程**的 ArkTS 源码，镜像了 DevEco 工程的相对路径。
> Task 1 用 DevEco 向导建好 `SpatialBoutique/` 后，把下面的文件**贴到工程对应路径**即可，避免与向导生成的 boilerplate 冲突。

## 覆盖范围（地基 Task 2 + Task 3）

| 文件（本目录内） | 贴到工程路径 | 内容 |
|---|---|---|
| `entry/src/main/ets/model/MaterialPreset.ets` | 同左 | 材质预设四类 + 参数 |
| `entry/src/main/ets/model/ModelInfo.ets` | 同左 | 模型元数据 interface |
| `entry/src/main/ets/model/Role.ets` | 同左 | 买家/商家角色枚举 |
| `entry/src/main/ets/common/errors.ets` | 同左 | CaptureError / ReconError |
| `entry/src/ohosTest/ets/model/MaterialPreset.test.ets` | 同左 | MaterialPreset 单测 |
| `entry/src/ohosTest/ets/List.test.ets` | 同左 | 测试入口（**替换**向导生成的同名文件） |

## 贴入步骤

1. 按 `docs/plan-p1-foundation-2026-06-23.md` Task 1，DevEco「New → Empty Ability」建 `SpatialBoutique/`（API 26）。
2. 把本目录下 `entry/...` 的文件复制到 `SpatialBoutique/entry/...` 的**相同相对路径**（目录不存在就新建）。
3. `List.test.ets`：向导已生成同名文件——**用本目录的版本替换它**（或把 `materialPresetTest()` 注册行合并进去）。
4. 往 `SpatialBoutique/entry/src/main/resources/base/element/string.json` 的 `string` 数组里**追加**这四条（向导生成的 `app_name` 等保留）：

```json5
{ "name": "mat_metal",  "value": "金属" },
{ "name": "mat_gem",    "value": "宝石" },
{ "name": "mat_glass",  "value": "玻璃" },
{ "name": "mat_matte",  "value": "哑光" }
```

5. 跑测试：DevEco 右键 `List.test.ets` → Run（部署到本地模拟器），4 个用例应全绿。

## 注意

- **测试 import 路径** `../../../main/ets/model/MaterialPreset` 假设标准 ohosTest 布局（`src/ohosTest/ets` ↔ `src/main/ets`）。若你的 DevEco 版本生成不同布局，按实际层级调 `../` 数量。
- `Record<MaterialPresetId, MaterialParams>` + 计算枚举键在严格 ArkTS 下偶有报错；若编译器抱怨，改成显式对象字面量（键写字符串）即可，语义不变。
- `ResourceColor` / `ResourceStr` / `$r(...)` 是 ArkTS 全局，无需 import。
- 这批代码**只**实现 Task 2–3；Task 4（ModelStore 接口）起的代码会陆续加进本目录或直接进工程。
