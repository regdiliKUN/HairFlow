# HairFlow 一页速查（1.6.0）

## 五步

1. **Remember Stroke** → **Long Strand Curve**（Curve Mode 开、Snap 开、Lazy 关、Step 0.1）
2. 从发根**一次拖到发梢**：只生成曲线，不雕刻
3. 要改形：**Shape Lock** → 拖曲线弯曲（可旋转视角）→ **Smooth Curve** → **Shape Unlock**
4. 曲线变红高亮时**点一下**提交 → **Delete Curve**
5. **Restore Stroke**

> 没锁就拖曲线 = 每次鼠标移动都压一次，留下多排痕迹。

## 控件分组

| 组 | 按钮 |
|---|---|
| 模式 | Long Strand Curve / Curve Off / Freehand Assist |
| 调形 | Shape Lock / Shape Unlock / Curve Edit Tips |
| 曲线 | Smooth Curve / Delete Curve |
| 密度 | Curve Step 滑杆（0–2）+ Step Fine 0.1 / Standard 0.25 / Medium 0.5 / Fast 1 |
| 贴合 | Curve Snap On / Off |
| 记忆 | Remember Stroke / Restore Stroke / Reset Stroke Defaults |
| 工具 | Preflight Check / Open Manual / Open Data Folder / Diagnostics / Workflow |

## 四条规则

1. **同一条发束只用一条曲线**：拆成两条就会重新出现接缝；拖端点是移动整条曲线，不能接长。
2. **调形必锁**：Shape Lock 只关 Zadd/Zsub，Z 强度、Size、Alpha 不动；Unlock 原样恢复。
3. **发沟用 Step Fine**：0.25 下 DamStandard 呈珠串；超过 1 点状明显。
4. **只点一次**：每点一次曲线就压一次。

## 出问题

| 症状 | 先做什么 |
|---|---|
| 面板没有 | 重跑安装脚本（2022/2025 各装自己编译的 `.zsc`） |
| 2022 一启动就报 Unable To Open File | 先关掉 2025 |
| 画不出曲线 | 换 3D 雕刻笔刷、进 Edit、在模型表面拖；看 笔触 > 曲线 > 曲线模式 是否亮 |
| 模型上多了几排点 | Ctrl+Z；先 Shape Lock 再拖 |
| 点曲线没压出东西 | Shape Unlock；曲线变红再点，按下轻轻一动 |
| 笔刷什么都画不出 | 忘了 Shape Unlock → Unlock 或 Restore |
| 沟里一颗颗点 | Step Fine |
| 有折角 | Smooth Curve 1–3 次 |

## 路径

- 插件：`ZStartup\ZPlugs64\HairFlow.zsc`
- 文档：`C:\HairFlow\docs\README_zh.md`
- 诊断：`C:\HairFlow\HairFlow_diag.txt`

更多：`README_zh.md` / `FAQ.md` / `ACCEPTANCE.md`
