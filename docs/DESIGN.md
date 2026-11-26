# HairFlow 设计说明

版本 1.6.0 · 2026-11-26

## 1. 目标与成功标准

**目标**：雕刻日式手办长发时，一条沟壑可以从发根到发梢分多段完成，但最终结果必须像一笔画成：无接缝、无台阶、无起收笔变浅，沟深与细节与单笔一致。

**成功标准**：

1. 发束长度超过一次手部行程时，仍能完成整条沟壑；
2. 段与段之间没有可见接缝/双线/蜂腰；
3. 沟壑中段深度一致，发梢可自然收尖；
4. 不改变用户惯用笔刷的大小、强度、Alpha、Focal Shift；
5. 2022.0.5 与 2025.0.1 都能安装；
6. 失败时可回退，不破坏模型/拓扑。

## 2. 方案比较

### 方案 A：自由手绘 + 接缝补笔（否决）

做法：画一段，抬手，接第二段，重叠 10–15%，再用 Smooth 压接缝。

问题：

- 每段都有独立的起笔/收笔 taper，接缝处天然变浅；
- 手压、笔刷大小、方向很难完全一致；
- 补 Smooth 会把沟底细节和锐边一起磨掉；
- 段数越多，误差累积越明显。

它只能“降低接缝可见度”，不能消除接缝。

### 方案 B：程序化合并笔划（研究后未采用）

ZBrush ZScript 提供：

- `StrokeGetLast` / `StrokeLoad` / `CanvasStroke`；
- `ZObjStrokeV02` 文本笔划格式；
- `MouseHPos` / `MouseVPos` / `MouseLButton`。

我们实际验证了：在**顶层脚本**中生成一条 100+ 点的 V02 笔划，用 `CanvasStroke` 可在 2025.0.1 中对球体产生一条连续形变，证明“整条路径一次成笔”在引擎层可行。

但把它做成插件按钮时遇到三个硬约束：

1. **上下文限制**：`CanvasStroke` 在按钮/嵌套例程中稳定性差；在本机 2025.0.1 的脚本化测试里，按压自定义插件按钮（即使动作只是 `ISet` 或 `Note`）会让 ZBrush 直接退出。真实鼠标点击可能正常，但无法在无人值守环境可靠验证，也不能把用户体验押在不确定行为上。
2. **屏幕空间**：`CanvasStroke` 的 H/V 是画布坐标。用户搭到一半旋转视角/缩放，已记录点就失效；长发雕刻恰恰经常需要转视角。
3. **ZScript 工程限制**：`StrMerge` 结果上限 255 字符，长笔划必须逐段写内存；`MemWrite/MemRead` 参数顺序、内存块生命周期、嵌套例程都有坑。实现复杂度高，失败模式多。

因此没有把“程序化一笔”放进最终 UI，只在验证中保留为可行性证据。

### 方案 C：原生 Curve 编辑（采用）

ZBrush 原生 Curve 模式本身就是“先搭路径，再一次成笔”：

- 任意 3D 笔刷都可开启 Curve；
- 曲线可分段拖动弯曲、旋转视角继续调、Smooth、删除（原生没有“加点”按钮）；
- 每次编辑都会把**整条曲线**重新作为一条连续笔划计算；
- 提交时只有一条笔划，没有第二段起笔。

它天然满足“多段搭建、一次成笔”，而且完全保留笔刷参数与手感。插件要做的不是重写引擎，而是把这条工作流变得一键可达、可恢复、可诊断。

## 3. 最终架构

```
ZBrush
  └─ ZPlugin:HairFlow (ZScript, ASCII)
       ├─ Long Strand Curve   → Stroke:Curve:Curve Mode=1, Lazy=0, Snap=1
       ├─ Smooth/Delete       → Stroke:Curve:Smooth / Stroke:Curve:Delete
       ├─ Step 0.1/0.25/0.5/1 → Stroke:Curve:Curve Step（同步滑杆）
       ├─ Snap On/Off         → Stroke:Curve:Snap
       ├─ Freehand Assist     → Lazy Mouse 预设
       ├─ Remember/Restore    → 仅记忆 Stroke 状态
       ├─ Diagnostics         → C:/HairFlow/HairFlow_diag.txt
       └─ Workflow            → 状态栏四步提示
```

特点：

- **纯 ZScript**，无 DLL、无 Python、无外部进程；
- 不导出/导入网格，不碰拓扑、UV、SubTool；
- 不修改 Draw Size / Z Intensity / Focal Shift / Alpha / Imbed；
- 所有可选路径先 `IExists` 再 `ISet`，旧版本缺项不会报错；
- 插件源码保持 ASCII，避免 ZScript 编译器吞掉中文。

### 3.0a 1.6 修正：拖曲线会雕刻（屏幕实测）

1.5 的流程是“拖曲线分段调形 → 最后点一次提交”。在 2022/2025 里用真实鼠标操作发现：Curve Mode 下拖曲线时，ZBrush 会在每个鼠标移动事件沿当前曲线压一次笔划，调形本身就在雕刻，多步拖动留下多排点状痕迹。

可选方案：

| 方案 | 问题 |
|---|---|
| 不许调形，只能重画 | 长发束很难一笔拖准，失去“分段”的意义 |
| 调形时把 Z 强度设 0 | 改了深度参数，恢复出错就毁手感；违背“不碰深度”原则 |
| **调形时关 Zadd/Zsub，调完原样恢复（采用）** | 只是“雕刻方向开关”，不涉及强度数值；可精确记住并恢复；重复 Lock 不覆盖原值；Restore/Reset 兜底解锁 |

提交方式也实测确认：在曲线上点一下 = 沿曲线压一次（完全静止的合成点击不触发，带 1 像素移动即触发）。Long Strand Curve 默认 Step 0.1，因为 0.25 下 DamStandard 细沟呈珠串。

### 3.0 1.5 修正：路径身份必须实测

1.2–1.4 依据 `IExists=1` 认定路径正确，这是错的：ZBrush 的路径查找对中间段很宽松。2025.0.1 用 `IGetID` / `IGetTitle` 实测：

| 1.4 写法 | 实际解析到 | 后果 |
|---|---|---|
| `Stroke:Curve` | Curve **子面板**（id 11277） | 写 1 只展开面板，Curve Mode 仍为 0 |
| `Stroke:Curve Functions:Add` | `Stroke:Inventory:Add`（id 4804） | 按到笔划库，不是加点 |
| `Stroke:Curve Functions:Smooth/Delete` | Curve 子面板的 Smooth/Delete | 碰巧正确 |
| `Stroke:Curve Step` | `Stroke:CurveStep`（id 1241） | 正确，但 1/2/5/10 的语义反了（默认 0.25） |

1.5 的规则：插件只使用在白名单里、且由 `IGetTitle` 确认过身份的路径；`tests/check_hairflow.py` 拒绝白名单外的任何 Stroke 路径。

### 3.1 1.4 增量

1.4 没有改变“原生 Curve 一条曲线一次成笔”的主结构，只补控制面与可发现性：

- **Curve Step 滑杆**：0–10 连续调节，预设 1/2/5/10 保留，兼顾精细与快速；
- **Curve Off**：只关 Curve，不动 Lazy，给“回到普通笔划”一个干净出口；
- **Preflight Curve 分支**：预检不仅看“能不能画”，还看“是不是 Curve 在画”；
- **Open Manual + 安装复制文档**：把 README/FAQ/ACCEPTANCE/CHANGELOG 复制到 `C:/HairFlow/docs`，面板可直接打开；
- **测试与文档套件**：全按钮探针、静态检查、链接检查、验收清单、逐轮迭代记录。

这些增量的共同原则：**只增加“可见、可退、可验证”的控制，不增加会改变笔刷深度的隐式行为。**

## 4. 交互状态机

```
[任意雕刻状态]
   │ Remember Stroke
   ▼
[已记忆 Stroke 状态]
   │ Long Strand Curve
   ▼
[Curve 编辑中]
   ├─ 从发根拖到发梢        （整条路径）
   ├─ Shape Lock            （Zadd/Zsub 关）
   ├─ 分段拖动 × N          （只改形状）
   ├─ Smooth Curve          （修顺）
   ├─ Shape Unlock          （Zadd/Zsub 原样恢复）
   ├─ 点击曲线              （提交一条连续笔划）
   └─ Delete Curve          （清理）
   │ Restore Stroke
   ▼
[回到原状态]
```

关键点：**“段”是曲线的控制段，不是独立的笔划**。所以不存在“第 1 段笔划”和“第 2 段笔划”的接缝。

## 5. 参数设计

| 参数 | 取值 | 设计理由 |
|---|---|---|
| Curve Step | 0.1 / 0.25 / 0.5 / 1，滑杆 0–2 | 原生默认 0.25；越小越密；> 1 易出现点状，所以预设与滑杆都不超过它太多 |
| Curve Snap | On/Off | 头发沟壑贴面；轮廓调整可悬浮 |
| Lazy Mouse（备用） | Radius 10 / Step 0.25 / Smooth 4 | 只用于自由手绘时降低抖动；原生 Smooth 上限 16，1.4 的 20 会被截断 |
| Brush 参数 | 不修改 | 保证深度、宽度、细节与用户原笔刷一致 |

没有暴露“沟壑深度”滑块的刻意原因：深度应由笔刷的 Z Intensity/Imbed 决定。插件若再乘一个系数，会破坏用户已经调好的手感，也让接缝深度难以预测。

## 6. 兼容性策略

- `[IConfig, 2021]`：2022/2025 均可接受，沿用本机已验证插件的做法；
- 只使用两版都有的核心命令：`ISubPalette`、`IButton`、`ISet`、`IGet`、`IExists`、`IPress`、`NoteBar`、`MemCreate`、`MemWriteString`、`MemSaveToFile`；
- 可选路径全部 `IExists` 保护，但 `IExists` 只做“缺项不报错”，**不作为路径正确的证据**；正确性靠 `IGetTitle` 实测 + 静态白名单；`n- 数值变量名不含下划线（2025 解析器对带下划线的数值变量不稳定）；
- 不依赖 2025 新增 API；
- 插件 UI 为英文短标签，说明文档中文，规避 ZScript 非 ASCII 问题。

## 7. 异常与回退

| 失败 | 行为 |
|---|---|
| 无模型/非 Edit | Curve 不产生笔划；提示先加载 PolyMesh |
| Snap 路径不存在 | 跳过设置，不报错；用户可手动开 |
| 按钮路径不存在 | `IExists` 为 0，跳过 |
| 诊断写入失败 | 状态栏提示检查 `C:\HairFlow` |
| 用户误改笔刷 | Remember/Restore 只恢复 Stroke，不伪装成“恢复全部笔刷” |
| 曲线丢失 | ZBrush 原生行为；重新搭，插件不做隐藏状态 |

## 8. 为什么不做“自动接缝焊接”

即使程序能拿到上一笔的终点，焊接仍然要回答：

- 两段的深度是否一致？
- 起笔 taper 是否要去掉？
- 接缝法线方向的笔刷朝向是否一致？
- 焊接 Smooth 会不会磨掉沟底细节？

任何一个答案不确定，都会把“接缝”换成“补丁”。原生 Curve 把这些变量收敛成一条路径，是更可控的工程解。

## 9. 后续可扩展

1. **锚点路径器**：在顶层 ZScript 中读取锚点文件，生成 V02 笔划并用 `CanvasStroke` 一次成笔（引擎已验证，需解决按钮上下文/视角约束）；
2. **发束库**：保存常用发流曲线为预设（ZBrush 原生 Curve 预设/笔刷）；
3. **左右对称**：结合 ZBrush 对称，一次搭曲线生成镜像发束；
4. **曲线辅助参数**：`Curve Snap Distance`、`CurveEdit Radius`、`Curve Smoothness` 已在 2025 实测存在，可按需要暴露。

## 10. 结论

HairFlow 的核心不是“更强的笔刷”，而是**把长发沟壑的编辑单位从‘笔划’换成‘曲线’**。  
只要最终只提交一条曲线，接缝就没有机会出现；笔刷的深度和细节也不需要任何补偿。
