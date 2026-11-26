# HairFlow Changelog

## 1.6.0 — 2026-11-26（当前）

用屏幕控制（真实鼠标操作）在 **ZBrush 2025.0.1 和 2022.0.5** 里把整条工作流实际做了一遍，发现并修正了 1.5.0 文档流程里的错误。

### 屏幕实测发现

- **拖动曲线会雕刻**：Curve Mode 下拖曲线（中段或端点）时，每个鼠标移动事件都会沿曲线压一次笔划，留下多排点状痕迹（`tests/results/screen_drag_without_lock_rows.jpg`）。1.5.0 文档的“先拖曲线调形，最后点一次提交”会叠出多条沟；
- **端点拖动 = 移动整条曲线**，不能接长；
- **提交 = 在曲线上点一下**：一次点击压一次、沿曲线连续、两端自然收尖。完全静止的合成点击不提交，按下后哪怕移动 1 像素即提交（真人点击天然满足）；
- **Smooth Curve 不雕刻**，只修曲线；
- **Curve Step 0.25 下 DamStandard 的沟呈珠串**，0.1 连续顺滑（`screen_step010_vs_025.jpg`）；
- 笔触 > 曲线函数 > **快照** 在 DamStandard 下为禁用状态；“曲线函数”子面板在界面里存在（只是脚本按这个名字查不到），删除/平滑按钮就在其中，插件所用路径正确；
- **2022 能正常运行**：此前的 “Unable To Open File” 只在 2025 同时运行时出现；关掉 2025 后 2022 正常启动。

### 新增

- **Shape Lock / Shape Unlock**：调形前记住并关闭 `Draw:Zadd` / `Draw:Zsub`，拖曲线只改形状不雕刻；Unlock 原样恢复（2022 下 DamStandard 默认 Zsub 也正确恢复）；重复 Lock 不覆盖记住的值；Z 强度、Size、Alpha 始终不动。
- Restore Stroke、Reset Stroke Defaults 会自动解除 Shape Lock；Preflight 在锁定时提醒；Diagnostics 记录 Zadd/Zsub/锁状态。
- 2022 专用编译产物 `plugin/HairFlow_2022.zsc`（49204 字节，2022 自己编译）；安装脚本给两个版本各装各的，`build.txt` 记录 `zsc2022=`，校验脚本核对两版（28 项）。

### 修改

- **Long Strand Curve** 同时把 Curve Step 设为 0.1；Preflight 建议改为 Step Fine；
- Curve Edit Tips、Workflow 提示改为实测正确的流程；
- 静态检查：22 按钮；白名单加入 `Draw:Zadd` / `Draw:Zsub`，并限定它们只能被写成 0 或存回的值；检查三处解锁调用。

### 实测

- 2025.0.1 与 2022.0.5：UI/路径探针 22 按钮 + 12 条路径一致；19 步命令体回读两版逐行相同；屏幕端到端：滑杆拖动同步、四预设同步、Long Strand 点亮曲线模式/捕捉、Shape Lock 调形无痕、提交得到单条连续沟、Delete / Restore 正常。

## 1.5.0 — 2026-11-26

接手审查 + 运行期实测修正。**1.2–1.4 的核心按钮在 2025.0.1 上并没有做它声称的事**，原因是路径只用 `IExists` 验证过，而 `IExists` 对路径很宽松。本版用 `IGetID` / `IGetTitle` 逐条解析，并改正：

### 修正（行为错误）

- **Long Strand Curve / Curve Off / Freehand / Reset / Remember / Restore / Preflight**：`Stroke:Curve`（子面板）→ `Stroke:Curve:Curve Mode`（真正的开关）。实测旧写法写入后 Curve Mode 仍为 0；新写法回读为 1；
- **删除 Add Curve Point**：`Stroke:Curve Functions:Add` 实际解析为 `Stroke:Inventory:Add`（笔划库）。ZBrush 没有原生“给曲线加点”按钮；换成只显示提示的 **Curve Edit Tips**，文档流程改为“整条拖出 → 分段调形 → 一次提交”；
- **Smooth / Delete Curve**：改用确切路径 `Stroke:Curve:Smooth` / `Stroke:Curve:Delete`（旧路径碰巧解析到同一控件）；
- **Curve Step 语义**：原生默认 0.25、越小越密。旧预设 1/2/5/10 全部比默认稀 4–40 倍。改为 **Step Fine 0.1 / Standard 0.25 / Medium 0.5 / Fast 1**；滑杆改为 0–2、精度 0.05、初值 0.25；
- **预设同步滑杆**：脚本 `ISet` 滑杆不会触发其回调，所以预设与 Restore 通过 `hfSetCurveStep` 同时写原生值和滑杆，二者不再脱节；
- **Lazy 数值越界**：原生 Lazy Smooth 上限 16，旧值 20 被截断。Freehand Assist 改为 Radius 10 / Step 0.25 / Smooth 4；
- **Reset Stroke Defaults**：改为 2025.0.1 启动实测值（Curve 关、Step 0.25、Snap 关、Lazy 1 / 0.25 / 0），不再强制打开 Lazy Mouse（它跟随笔刷）；
- **Remember / Restore**：补记 Curve Mode 与 Snap 的正确路径；所有 ISet 加 `IExists` 保护；
- **变量名**：数值变量去掉下划线（2025 解析器已知问题）；
- **Diagnostics**：每组值一行、CRLF 分隔、`MemResize` 去掉 512 字节填充 NUL；增加 Curve Mode / Snap / Lazy 细项。

### 新增

- Preflight：Curve Step > 1 时提醒点状风险；
- `tests/build_runtime_test.py`：从源码**原样**抽取按钮命令体生成运行期测试（因为脚本 IPress 自定义按钮会接管执行、调用方随即中断）；
- `tests/probe_ui.txt`：除按钮存在外，增加 9 条原生路径的 `IGetTitle` 身份校验；
- `check_hairflow.py`：原生路径白名单、禁止 `Stroke:Curve` / `Curve Functions`、ISet 数值范围、Step 预设上限、变量名下划线、运行期测试是否与源码同步。对 1.4.0 源码运行可抓出全部 7 类问题。

### 实测

- 2025.0.1：编译产物 14800 字节，自动加载；20 按钮 + 滑杆存在；15 个按钮命令体逐个执行回读全部符合；Restore 回到初始状态逐项一致。
- 2022.0.5：未运行（本机既有启动错误），静态兼容。

## 1.4.0 — 2026-11-26

在 1.3.0 基础上完成第二轮 20 轮质量迭代（第 24–43 轮）。

### 新增控制

- **Curve Step 滑杆**：0–10 连续调节，保留 1/2/5/10 预设；
- **Curve Off**：只关 Curve，不改 Lazy；
- **Reset Stroke Defaults**：Curve OFF / Lazy ON / Step 5 的常用默认，并明确“不是个人预设”；
- **Open Manual**：打开 `C:/HairFlow/docs/README_zh.md`。

### 正确性 / 边界

- Preflight 增加 Curve 状态分支：Curve 未开时明确提示；
- Diagnostics 增加 `curveStep=`（有 `IExists` 保护）；
- 安装脚本复制文档到 `C:/HairFlow/docs`，写 `version.txt` / `build.txt`；
- 新增 `Verify-HairFlow.ps1`：用构建清单尺寸识别“源码新、`.zsc` 旧”；
- 备份目录彻底移出 `ZPlugs64`。

### 验证 / 文档

- `tests/probe_ui.txt` 扩展到 20 按钮 + 滑杆，运行结果全部 =1；
- `check_hairflow.py` 扩展到 20 按钮、文档存在性、相对链接；
- 新增 `QUICK_REFERENCE.md`、`seam-comparison.svg`、`tests/README.md`；
- README 增加笔刷准备表、曲线手势速查、异常快速定位表；
- 验收清单增加滑杆 / Curve Off / Open Manual / 对称 / 图层 / 重开。

## 1.3.0 — 2026-11-26

第一轮 23 轮质量迭代（第 1–23 轮）。

### 正确性

- Restore Stroke 增加 `HF_HAS_SNAP` 快照保护，未 Remember 时不再写入默认值；
- Long Strand / Freehand 的核心 `Stroke:Curve` 写入增加 `IExists` 保护；
- Add / Smooth / Delete 在路径缺失时给出回退提示，不再静默失败；
- Diagnostics 检查 `MemSaveToFile` 返回值，区分成功/失败。

### 边界与异常

- 新增 `Preflight Check`：检查 SubTool、Edit、Curve、Draw Size；
- 新增 `Open Data Folder`；
- 2022 安装说明补充一次性 Load 编译与启动报错排查；
- 安装备份移到 ZBrush 根目录，避免 `ZPlugs64` 内的旧 `.zsc` 被重复加载。

### 性能

- 新增 `Curve Step 1`；
- 文档增加按发束长度选择 Step 的规则，避免长曲线全程最小 Step。

### 可用性 / 一致性

- 按钮按真实工作流重排：Preflight → 模式 → 曲线功能 → Step → Snap → Freehand → 记忆 → 诊断；
- README 增加 30 秒快速开始、目录、术语表、性能分层；
- 新增 FAQ、ACCEPTANCE、CHANGELOG、ITERATIONS；
- 新增 `tests/check_hairflow.py` 静态检查（ASCII、按钮、版本、笔刷写入、ISet 保护）；
- 全文档版本号统一为 1.3.0，诊断与安装说明同步。

## 1.2.0 — 2026-11-26

- 改为原生 Curve 工作流：多段控制点、一次提交、无接缝；
- 提供 Long Strand Curve / Add / Smooth / Delete / Curve Step / Snap / Freehand / Remember / Restore / Diagnostics；
- 不修改 Draw Size、Z Intensity、Focal Shift、Alpha；
- 2025.0.1 自动加载验证；2022.0.5 源码部署与静态兼容检查。

## 1.1.0 — 2026-11-26（内部研究版）

- 尝试 `CanvasStroke + ZObjStrokeV02` 的程序化一笔引擎；
- 在 2025 顶层脚本中验证连续形变可行；
- 因按钮/嵌套例程上下文不稳定、屏幕坐标依赖视角，未进入最终 UI。

## 1.0.0 — 2026-11-26（初版）

- 完成长发沟壑需求分析与 ZBrush ZScript 可行性调查；
- 建立插件 UI、安装脚本与验证框架。
