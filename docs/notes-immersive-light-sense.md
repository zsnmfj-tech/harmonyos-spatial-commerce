# 沉浸光感（Immersive Light Sense）· API 确认笔记

> 解决地基 Task 12 与真机 Task D7 的「属性名未知」风险。来源：华为官方 HDS 沉浸光感文档（2026-04-20 更新）+ 掘金实战教程，两源一致。
> 官方文档：https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-hds-component-material

## 核心机制

沉浸光感**不是**给任意组件加的通用属性，而是 **HDS 组件**上的 `systemMaterialEffect`（系统材质效果）参数。来自 `@kit.UIDesignKit`。

## 导入

```typescript
import { HdsNavigation, HdsNavigationTitleMode, HdsTabs, HdsTabsController,
         HdsNavigationMenuContentOptions, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
```

## 两个官方支持的施加点

| 施加点 | 容器 | 参数位置 |
|---|---|---|
| **标题栏** | `HdsNavigation` 的 `.titleBar({ style: { systemMaterialEffect: {...} } })` | `TitleBarStyleOptions.systemMaterialEffect` |
| **底部页签** | `HdsTabs` 的 `.barFloatingStyle({ systemMaterialEffect: {...} })` | `HdsTabsFloatingStyle.systemMaterialEffect` |

> 即：沉浸光感天然落在 **TitleBar + TabBar** 这种全局 chrome 上。3D 视口覆盖层/悬浮卡不是官方施加点——那里用 `backgroundBlurStyle` 作互补效果即可。

## 枚举

```typescript
systemMaterialEffect: {
  materialType: hdsMaterial.MaterialType.ADAPTIVE,   // ADAPTIVE | IMMERSIVE | BACKGROUND_BLUR
  materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE,  // ADAPTIVE | EXQUISITE | GENTLE | SMOOTH
}
```

- `MaterialType.IMMERSIVE` —— 沉浸光感（最强）。交互时自带「光晕/反射」反馈，**「光随指动」就是它的内置行为**，无需单独 API。
- `MaterialType.BACKGROUND_BLUR` —— 背景模糊（降级用）。
- `MaterialLevel.EXQUISITE` 精致（最强光影）/ `GENTLE` 柔和 / `SMOOTH` 平滑（最低开销，降级用）。

## 推荐用法

**省心方案**：`ADAPTIVE` + `ADAPTIVE`，系统按算力自适应。
```typescript
.barFloatingStyle({
  barBottomMargin: 28,
  systemMaterialEffect: {
    materialType: hdsMaterial.MaterialType.ADAPTIVE,
    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE,
  },
})
```

**极致方案 + 降级**（强制 IMMERSIVE，不支持则降级）：
```typescript
@State customLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;

aboutToAppear(): void {
  const types: Array<hdsMaterial.MaterialType> = hdsMaterial.getSystemMaterialTypes();
  if (types.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
    this.customLevel = hdsMaterial.MaterialLevel.SMOOTH; // 降级
  }
}
```

## 版本门控

- 能力起点：**6.1.0(23)**。沉浸光感在 HarmonyOS 7（API 26）扩展了支持的组件范围。
- 旧版本兼容：`deviceInfo.sdkApiVersion >= 23` 判断后再用，否则跳过。

## 对本项目的影响（设计修正）

1. **全局光感（Shell）**：Task 9 的底部 Tab 应使用 **`HdsTabs`**（非普通 `Tabs`）+ `.barFloatingStyle({ systemMaterialEffect })`；详情/列表页顶部用 **`HdsNavigation`** + `.titleBar({ style: { systemMaterialEffect } })`。这是光感最自然的落点。
2. **ShowcaseChrome（Task 12 / D7）**：沉浸展示页用 `HdsNavigation` 标题栏施加 `IMMERSIVE` 光感（「光线勾勒」+ 交互时的「光随指动」内置于该材质）。3D 视口之上的悬浮信息卡用 `backgroundBlurStyle` 作互补，不是光感官方施加点。
3. **「光随指动 / 光线勾勒 / 非线性形变」三者不是三个独立 API**——它们是 `IMMERSIVE` 材质在 HDS 组件上的内置视觉/交互行为。选定 `materialType: IMMERSIVE` 即获得全部。

## 下一步

D7 实现时：直接用 `HdsNavigation`/`HdsTabs` + `systemMaterialEffect: { IMMERSIVE, EXQUISITE }` + `getSystemMaterialTypes()` 降级。无需再「先确认属性名」——本笔记即为确认。
