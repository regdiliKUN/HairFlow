# HairFlow 验证记录

日期：2026-11-26  
环境：Windows / ZBrush 2025.0.1 / ZBrush 2022.0.5  
插件版本：1.6.0

> 验证分三层：① 路径身份（`IGetTitle`）+ 写入回读；② 从源码原样抽取的按钮命令体逐步回读；③ **用屏幕控制在两个 ZBrush 里实际操作**（1.6.0 新增）。第三层推翻了 1.5.0 文档里“拖曲线调形、最后点一次提交”的流程，见第 2.5 节。

---

## 1. 验证矩阵（1.6.0）

| 项目 | 2025.0.1 | 2022.0.5 | 证据 |
|---|---|---|---|
| 从 ZPlugs64 自动加载本版本编译的 `.zsc` | PASS（16376 B） | PASS（49204 B） | `ui_probe_160.txt` / `ui_probe_160_2022.txt` |
| 面板 + 滑杆 + 22 按钮存在 | PASS | PASS | 同上 |
| 12 条原生路径身份 | PASS | PASS（与 2025 一致） | 同上 |
| 19 步按钮命令体执行 + 回读 | PASS | PASS（逐行相同） | `runtime_bodies_160.txt` / `runtime_bodies_160_2022.txt` |
| Shape Lock 重复按不丢原值、Unlock/Restore 精确恢复、Z 强度不变 | PASS | PASS | 同上 |
| Diagnostics 写文件 | PASS | PASS | `diag_160.txt` |
| 屏幕：拖滑杆 → 原生 Curve Step 同步 | PASS（0.61538） | PASS（0.61538） | 第 2.5 节 |
| 屏幕：四个 Step 预设同步原生值和滑杆 | PASS | 命令体已验 | 第 2.5 节 |
| 屏幕：Long Strand Curve 点亮曲线模式 + 捕捉 | PASS | PASS | 第 2.5 节 |
| 屏幕：Shape Lock 下多步拖动调形无痕 | PASS | PASS（Zsub 笔刷） | 第 2.5 节 |
| 屏幕：Unlock 后点一下曲线 → 单条连续沟 | PASS | PASS | `screen_160_final_groove.jpg` / `screen_160_final_groove_2022.jpg` |
| 屏幕：Delete Curve / Restore Stroke | PASS | PASS | 第 2.5 节 |
| 静态检查 / 安装校验 | PASS / 28 项 PASS | 同左 | `check_hairflow.py` / `Verify-HairFlow.ps1` |

---

## 2. 2025.0.1 实测

### 2.1 测试方法（不点屏幕、不弹额外窗口）

- **启动期探针**：把只读 `.txt` 放进 `ZStartup\Macros\<临时文件夹>\`，ZBrush 启动时编译并执行，结果写到 `C:\HairFlow\*.txt`；测完删除该文件夹。
- **按钮命令体测试**：脚本 `IPress` 一个 ZScript 按钮时，被按按钮接管执行、调用方随即中断，所以不能用“脚本按按钮”测插件。`tests/build_runtime_test.py` 从 `HairFlow.txt` **原样**复制每个按钮的命令体和 `RoutineDef`，按顺序执行并在每步后回读原生 Stroke 状态。
- **关闭 ZBrush**：`CloseMainWindow` 正常退出；遇到 ZScript Note 等标准对话框时，用 Win32 `BM_CLICK` 点“确定”，不用强杀。

### 2.2 原生路径身份（摘录）

| 插件使用的路径 | `IGetTitle` | 范围 | 启动值 |
|---|---|---|---|
| `Stroke:Curve:Curve Mode` | Stroke:Curve Mode（id 1239） | 0–1 | 0 |
| `Stroke:Curve:Curve Step` | Stroke:CurveStep（id 1241） | 0–10 | 0.25 |
| `Stroke:Curve:Snap` | Stroke:Snap（id 1249） | 0–1 | 0 |
| `Stroke:Curve:Delete` | Stroke:Delete（id 1250） | 按钮 | — |
| `Stroke:Curve:Smooth` | Stroke:Smooth（id 1252） | 按钮 | — |
| `Stroke:Lazy Mouse` | Stroke:LazyMouse（id 1098） | 0–1 | 1 |
| `Stroke:Lazy Radius` | Stroke:LazyRadius（id 1099） | 1–200 | 1 |
| `Stroke:Lazy Step` | Stroke:LazyStep（id 1101） | 0–10 | 0.25 |
| `Stroke:Lazy Smooth` | Stroke:LazySmooth（id 1102） | 0–16 | 0 |

Curve 子面板 id 1239–1258 全部成员（含 AsLine、Curve Falloff、Curve Snap Distance、Curve Smoothness、Snapshot、Frame Mesh、CurveEdit Radius 等）见 `tests/results/stroke_paths_2025.txt`。

### 2.3 按钮命令体回读（`runtime_bodies_150.txt` 摘录）

```
start                 mode=0 step=0.25 slider=0.25 snap=0  lazy=1 rad=1 lstep=0.25 lsm=0
Long Strand Curve     mode=1 step=0.25 slider=0.25 snap=1  lazy=0
Step Fine             step=0.1  slider=0.1
Step Fast             step=1    slider=1
Curve Snap Off / On   snap=0 / snap=1
Step Medium           step=0.5  slider=0.5
Freehand Assist       mode=0  lazy=1 rad=10 lstep=0.25 lsm=4
Reset Stroke Defaults mode=0 step=0.25 slider=0.25 snap=0  rad=1 lstep=0.25 lsm=0
Curve Off             mode=0（Lazy 不变）
Restore Stroke        mode=0 step=0.25 slider=0.25 snap=0  lazy=1 rad=1 lstep=0.25 lsm=0  ← 与 start 一致
```

附加观察：

- 脚本 `ISet "ZPlugin:HairFlow:Curve Step", 0.6` 只改滑杆、不触发回调（原生 Step 仍 0.25）。因此预设按钮和 Restore 显式同时写两处；**真人拖动滑杆**会触发回调，但只能手工验收（ACCEPTANCE B9）。
- 1.4.0 对照：`ISet "Stroke:Curve", 1` 后 Curve Mode 仍为 0、子面板被展开；`Stroke:Curve Functions:Add` 解析为 `Stroke:Inventory:Add`。

### 2.4 一笔连续笔划可行性（引擎级，不在最终 UI）

1.2 时期用 `ZObjStrokeV02` 笔划文件 + `[CanvasStroke, [StrokeLoad, ...]]` 在高密度球体上验证过“整条路径一次成笔”的几何效果（`canvasstroke_sphere.png`）。未放入 UI：依赖屏幕坐标、转视角失效，详见 DESIGN.md 第 2 节。

---

## 2.5 屏幕实测（真实鼠标操作，1.6.0）

环境：52 万面 PolyMesh 球体（Sphere3D → PolyMesh3D → 细分 3 次），DamStandard，Draw Size 64。每个实验在球面不同区域进行，做完用 Delete Curve 去掉曲线再放大检查（曲线虚线会遮住下面的沟）。

| 实验 | 操作 | 结果 |
|---|---|---|
| A | 拖出曲线 → 静止单击曲线 | 不雕刻 |
| B | 拖出曲线 → 抓中段多步拖动 | 曲线被移动/弯曲，**同时留下多排点状痕迹**（每个移动事件压一次） |
| C | 拖出曲线 → 曲线函数 > 快照 | 按钮为禁用状态，无效果 |
| D | 拖出曲线 → 按下 + 1 像素移动 + 松开 | **沿曲线一条连续、两端收尖的沟** |
| E | 拖出曲线 → Smooth Curve ×2 | 只修曲线，不雕刻 |
| F | 抓中段单步拖动 | 曲线整体移动，并在新位置压一次 |
| 端点 | 从末端拖动 | 整条曲线被拖走（不是延长），同时压笔划；一次 Ctrl+Z 撤销 |
| G | 关 Zadd → 多步拖动弯曲 → 开 Zadd → 点一下提交 | 只有一条沿**弯曲后**路径的沟，无叠加痕迹 → 形成 Shape Lock 方案 |
| Step | 同样流程 0.25 vs 0.1 | 0.25 珠串，0.1 连续 → Long Strand Curve 默认 0.1 |

1.6.0 端到端（两版各一次）：Remember → Long Strand Curve（状态栏提示、Step 0.1）→ 拖出长曲线 → Shape Lock（Zadd/Zsub 全灭）→ 多步拖动弯曲 → Smooth Curve → Shape Unlock（2025 恢复 Zadd，2022 恢复 Zsub）→ 点一下曲线 → Delete Curve → 一条沿弧线、两端收尖的连续沟 → Restore（曲线模式关、Step 0.25、Lazy 开，与 Remember 时一致）。

其他：滑杆拖动后 HairFlow 显示 0.61538，笔触 > 曲线 > 曲线步进同为 0.61538；笔触 > 曲线函数子面板内为 删除 / 快照 / 平滑 / 曲线平滑度 / 匹配网格，没有“添加”。

## 3. 2022.0.5

- 此前的 “Unable To Open File” 后退出：本次复现为**与 2025 同时运行时**启动 2022 会退出（一次 1 秒内退出码 -1）；关闭 2025 后 2022 正常启动。之前“2022 安装损坏”的判断不成立；
- 用 Macros 方法让 2022 自己编译插件（49204 字节，与 2025 的 16376 字节不同，不能互换）并跑命令体测试：19 步输出与 2025 逐行相同；
- 安装到 2022 ZPlugs64 后重启：自动加载，UI/路径探针与 2025 一致；
- 屏幕端到端流程通过（见 2.5）。

---

## 4. 手工验收

[ACCEPTANCE.md](ACCEPTANCE.md) 的 B、C 节核心项已在两个版本中用屏幕操作完成。没有覆盖的：真实发型模型 + 数位板压感、Symmetry、Layer 录制、超高面数性能。

---

## 5. 1.4.0 及以前的验证漏了什么

| 1.4.0 记录 | 实际含义 | 漏掉的问题 |
|---|---|---|
| `pal=1 long=1 add=1 …` 全部 =1 | 只证明按钮/路径“能找到点什么” | Add 指向笔划库 |
| `curve=1 lazy=0 snap=1`（写入后回读） | 回读的是 `Stroke:Curve`（子面板展开状态） | Curve Mode 从未打开 |
| `setStep=5` 回读 5 | 写入有效 | 没对照默认值 0.25，语义反了 |
| 自定义按钮 IPress 导致 ZBrush “退出” | 实为调用方脚本被接管中断 | 因此按钮行为从未被运行期验证 |

---

## 6. 结论

- 2025.0.1 与 2022.0.5：插件加载、路径身份、按钮行为、真实鼠标端到端流程全部通过；
- 1.6.0 的关键变化来自屏幕实测：Curve Mode 下拖曲线会雕刻，所以加入 Shape Lock；DamStandard 细沟用 Step 0.1；
- 设计不变：一条曲线、一次提交，不修改笔刷深度/细节参数（Shape Lock 只临时关 Zadd/Zsub 并原样恢复）。
