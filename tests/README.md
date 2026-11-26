# HairFlow tests（1.6.0）

> 原则：**存在 ≠ 正确**。`IExists` 对路径很宽松（`Stroke:Curve Functions:Add` 不存在也返回 1，并解析成 `Stroke:Inventory:Add`），所以 1.5.0 起每条原生路径都要确认**身份**，每个按钮都要回读**效果**。

## 1. 静态检查（不启动 ZBrush）

```powershell
python tests/check_hairflow.py
```

检查：ASCII / `IConfig 2021`；20 个按钮齐全且无多余；不写 Draw Size / Z Intensity / Focal；**原生路径必须在已实测白名单内**；禁止 `"Stroke:Curve"`（子面板）与 `Curve Functions`；`ISet` 字面值在控件范围内；Curve Step 预设 ≤ 1；数值变量名无下划线；`runtime_bodies.txt` 与源码同步；文档版本、按钮覆盖、相对链接。

期望最后一行：`RESULT: PASS`。

## 2. 运行期测试（启动 ZBrush 2025）

ZBrush 的两个限制决定了测试方式：

- `ZPlugs64` 里的 `.txt` **不会**被自动编译；`ZStartup\Macros\<文件夹>\` 里的 `.txt` 会在启动时编译**并执行**；
- 脚本 `IPress` 一个 ZScript 按钮会被该按钮接管、调用方中断，所以不能“脚本按按钮”。

### 2.1 按钮命令体测试

```powershell
python tests/build_runtime_test.py
```

生成 `tests/runtime_bodies.txt`：从 `plugin/HairFlow.txt` 原样复制每个按钮的命令体与 `RoutineDef`，按 Remember → 各模式/预设 → Restore 的顺序执行，每步回读。

把 `plugin/HairFlow.txt`（让滑杆存在）和 `tests/runtime_bodies.txt` 放进同一个 `ZStartup\Macros\<临时文件夹>\`（文件名按字母序，HairFlow 要排在前面），启动 ZBrush，结果在 `C:\HairFlow\runtime_bodies.txt`。最后一步 Restore 的状态应与 `start` 逐项一致。测完删除临时文件夹。

### 2.2 UI + 路径身份探针

`tests/probe_ui.txt`（只读）：面板、滑杆、20 个按钮存在性 + 9 条原生路径的 `IGetTitle`。结果 `C:\HairFlow\HairFlow_ui_probe.txt`，对照 `tests/results/ui_probe_150.txt`。在 2022 修好后也用它确认路径。

### 2.3 路径/子面板勘察（开发用）

- `tests/probe_stroke_paths.txt`：逐条输出路径的 id / 标题 / 当前值 / 范围；
- `tests/probe_curve_members.txt`：按 id 枚举 Curve 子面板成员 + Curve Mode / Curve Step 写入回读。

> 按 id 枚举时，遇到无效 id 会弹 “Interface item could not be found” 并中止；已写出的行会保留（每行即时落盘）。

### 2.4 无界面收尾

脚本出错会弹 ZScript Note 对话框，阻塞后续。可用 Win32 枚举 ZBrush 进程窗口读出错误文本，并对“确定”发送 `BM_CLICK`；用 `CloseMainWindow` 正常关闭 ZBrush，避免下次启动出现“异常退出”提示。

## 2.5 屏幕实测（真实鼠标）

1.6.0 用 Computer Use 在 2022 与 2025 中实际操作（建 52 万面球体、DamStandard），记录见 `docs/VERIFICATION.md` 2.5 节，截图在 `results/screen_*.jpg`。
注意：Curve Mode 曲线虚线会遮住下面的沟，检查前先 Delete Curve；完全静止的合成点击不会提交曲线，需要按下后移动 1 像素。

## 3. 结果归档 `tests/results/`

| 文件 | 内容 |
|---|---|
| `ui_probe_160.txt` / `ui_probe_160_2022.txt` | 1.6.0：两版 22 按钮 + 12 条路径身份 |
| `runtime_bodies_160.txt` / `runtime_bodies_160_2022.txt` | 1.6.0：两版 19 步命令体回读（逐行相同） |
| `screen_160_final_groove*.jpg` | 1.6.0：两版端到端提交结果 |
| `screen_drag_without_lock_rows.jpg` | 不锁直接拖曲线留下的多排痕迹 |
| `screen_step025_beads.jpg` / `screen_step010_vs_025.jpg` | Step 0.25 珠串 vs 0.1 连续 |
| `ui_probe_150.txt` | 1.5.0：20 按钮 + 滑杆 + 9 条路径身份 |
| `runtime_bodies_150.txt` | 1.5.0：15 步按钮命令体回读 + 滑杆/旧版对照 |
| `diag_150.txt` | 1.5.0：Diagnostics 输出 |
| `stroke_paths_2025.txt` | 2025.0.1 原生路径 id/标题/范围 + Curve 子面板成员 |
| `ui_probe_all20.txt` 等 | 1.4.0 及以前的存在性探针（仅供对照，见 VERIFICATION 第 5 节） |
| `canvasstroke_sphere.png` | CanvasStroke 引擎可行性证据（非最终 UI） |

## 4. 2022

1.6.0 已在 2022 完成全部运行期与屏幕测试。注意先关掉 2025 再启动 2022（同时运行时 2022 会报 Unable To Open File 退出）。
