#!/usr/bin/env python3
"""Static checks for HairFlow plugin and docs.

Run from the HairFlow folder:
    python tests/check_hairflow.py

It does not launch ZBrush. It catches the cheap regressions: non-ASCII source,
missing buttons, accidental brush-parameter writes, version drift, and - since
1.5.0 - native paths that were never verified in ZBrush (IExists is lenient:
"Stroke:Curve Functions:Add" answers 1 but resolves to Stroke:Inventory:Add).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "plugin" / "HairFlow.txt"
DOCS = [ROOT / "docs" / "README_zh.md", ROOT / "docs" / "DESIGN.md", ROOT / "docs" / "VERIFICATION.md"]
LINK_DOCS = [
    ROOT / "docs" / "README_zh.md",
    ROOT / "docs" / "FAQ.md",
    ROOT / "docs" / "DESIGN.md",
    ROOT / "docs" / "VERIFICATION.md",
    ROOT / "docs" / "ACCEPTANCE.md",
    ROOT / "docs" / "CHANGELOG.md",
    ROOT / "docs" / "ITERATIONS.md",
]
EXPECTED_DOCS = [
    "README_zh.md", "FAQ.md", "DESIGN.md", "VERIFICATION.md",
    "ACCEPTANCE.md", "CHANGELOG.md", "ITERATIONS.md", "QUICK_REFERENCE.md",
    "workflow.svg", "seam-comparison.svg",
]

REQUIRED_BUTTONS = {
    "Preflight Check",
    "Long Strand Curve",
    "Curve Off",
    "Curve Edit Tips",
    "Smooth Curve",
    "Delete Curve",
    "Step Fine",
    "Step Standard",
    "Step Medium",
    "Step Fast",
    "Curve Snap On",
    "Curve Snap Off",
    "Freehand Assist",
    "Remember Stroke",
    "Restore Stroke",
    "Reset Stroke Defaults",
    "Open Manual",
    "Open Data Folder",
    "Diagnostics",
    "Workflow",
    "Shape Lock",
    "Shape Unlock",
}

# Native paths resolved with IGetID/IGetTitle in ZBrush 2025.0.1
# (tests/results/stroke_paths_2025.txt, tests/results/ui_probe_150.txt).
# path -> (min, max) of the control.
VERIFIED_PATHS = {
    "Stroke:Curve:Curve Mode": (0, 1),
    "Stroke:Curve:Curve Step": (0, 10),
    "Stroke:Curve:Snap": (0, 1),
    "Stroke:Curve:Smooth": (0, 1),
    "Stroke:Curve:Delete": (0, 1),
    "Stroke:Lazy Mouse": (0, 1),
    "Stroke:Lazy Radius": (1, 200),
    "Stroke:Lazy Step": (0, 10),
    "Stroke:Lazy Smooth": (0, 16),
    "Transform:Edit": (0, 1),
    "Draw:Draw Size": (1, 1000),
    "Draw:Zadd": (0, 1),
    "Draw:Zsub": (0, 1),
}
failures: list[str] = []
notes: list[str] = []


def check(condition: bool, message: str) -> None:
    if condition:
        notes.append("PASS  " + message)
    else:
        failures.append("FAIL  " + message)


def main() -> int:
    raw = PLUGIN.read_bytes()
    try:
        text = raw.decode("ascii")
    except UnicodeDecodeError as exc:
        failures.append(f"FAIL  plugin source is not ASCII: {exc}")
        text = raw.decode("utf-8", errors="replace")

    check("[IConfig, 2021]" in text, "IConfig 2021 present")
    check("CanvasStroke" not in text, "no CanvasStroke in shipped UI (by design)")
    check("hfHasSnap" in text, "snapshot guard variable present")
    check("HairFlow 1.6.0 diagnostics" in text, "diagnostics version is 1.6.0")
    check("1.6.0" in text.splitlines()[0], "header version is 1.6.0")

    buttons = set(re.findall(r'\[IButton, "ZPlugin:HairFlow:([^"]+)"', text))
    missing = REQUIRED_BUTTONS - buttons
    extra = buttons - REQUIRED_BUTTONS
    check(not missing, f"all required buttons present (missing: {sorted(missing)})")
    check(not extra, f"no unexpected buttons (extra: {sorted(extra)})")
    check(len(buttons) == len(REQUIRED_BUTTONS), f"button count = {len(REQUIRED_BUTTONS)}")

    code = "\n".join(ln for ln in text.splitlines() if not ln.lstrip().startswith("//"))

    # --- 1.5.0: native path identity -------------------------------------
    used = set(re.findall(r'\[(?:ISet|IGet|IPress|IExists), "((?:Stroke|Transform|Draw):[^"]+)"', code))
    unverified = sorted(used - set(VERIFIED_PATHS))
    check(not unverified, f"every native path is in the verified list (unverified: {unverified})")
    check('"Stroke:Curve"' not in code, 'never touches "Stroke:Curve" (sub-palette, not Curve Mode)')
    check("Curve Functions" not in code, 'never uses "Stroke:Curve Functions:*" (does not exist; Add -> Inventory:Add)')

    out_of_range = []
    for path, value in re.findall(r'\[ISet, "((?:Stroke|Draw):[^"]+)", (-?[0-9.]+)\]', code):
        lo, hi = VERIFIED_PATHS.get(path, (float("-inf"), float("inf")))
        if not lo <= float(value) <= hi:
            out_of_range.append((path, value, (lo, hi)))
    check(not out_of_range, f"literal ISet values inside control range (bad: {out_of_range})")

    steps = [float(v) for v in re.findall(r"\[RoutineCall, hfSetCurveStep, ([0-9.]+)\]", code)]
    check(steps and max(steps) <= 1, f"Curve Step presets stay <= 1 to avoid dotted grooves ({steps})")

    under = re.findall(r"\[VarDef, ([A-Za-z0-9]*_[A-Za-z0-9_]*), -?[0-9]", code)
    check(not under, f"numeric VarDef names have no underscore (2025 parser) (found: {under})")

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import build_runtime_test  # noqa: E402
    prelude, bodies = build_runtime_test.extract(text)
    check(set(bodies) == REQUIRED_BUTTONS, "runtime generator parses all 20 button bodies")
    gen = ROOT / "tests" / "runtime_bodies.txt"
    if gen.exists():
        missing_steps = [s for s in build_runtime_test.STEPS if bodies.get(s, "<missing>") not in gen.read_text(encoding="ascii")]
        check(not missing_steps, f"tests/runtime_bodies.txt is regenerated from current source (stale: {missing_steps})")
    brush_writes = re.findall(r'\[ISet, "(Draw:Draw Size|Draw:  Z Intensity|Draw:Z Intensity|Draw:Focal Shift)"', text)
    check(not brush_writes, f"plugin never writes brush size/depth/focal (found: {brush_writes})")

    # 1.6.0 Shape Lock: Zadd/Zsub may only be set to 0 (lock) or back to the stored value (unlock)
    zwrites = re.findall(r'\[ISet, "Draw:(Zadd|Zsub)", ([^\]]+)\]', code)
    bad_z = [w for w in zwrites if w[1].strip() not in ("0", "hfRZadd", "hfRZsub")]
    check(not bad_z, f"Zadd/Zsub only written by Shape Lock (0) / unlock (stored value) (bad: {bad_z})")
    check(code.count("[RoutineCall, hfUnlock]") >= 3, "Shape Unlock, Restore Stroke and Reset all release Shape Lock")

    # Every optional Stroke ISet should be guarded by IExists either on the same
    # line or by a surrounding IF block. This is a heuristic, not a parser.
    unguarded = []
    for lineno, line in enumerate(text.splitlines(), 1):
        if "[ISet, \"Stroke:" not in line:
            continue
        if "IExists" in line:
            continue
        window = "\n".join(text.splitlines()[max(0, lineno - 6):lineno])
        if "IExists" not in window and "hfHasSnap" not in window:
            unguarded.append((lineno, line.strip()))
    check(not unguarded, f"Stroke ISet lines look guarded (unguarded: {unguarded})")

    for doc in DOCS:
        body = doc.read_text(encoding="utf-8")
        check("1.6.0" in body, f"{doc.name} mentions version 1.6.0")

    readme = (ROOT / "docs" / "README_zh.md").read_text(encoding="utf-8")
    for name in sorted(REQUIRED_BUTTONS - {"Open Data Folder", "Workflow"}):
        check(name in readme, f"README documents button: {name}")

    for doc_name in EXPECTED_DOCS:
        check((ROOT / "docs" / doc_name).exists(), f"docs/{doc_name} exists")

    link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    broken = []
    for doc in LINK_DOCS:
        if not doc.exists():
            continue
        body = doc.read_text(encoding="utf-8")
        for target in link_re.findall(body):
            target = target.strip().split("#", 1)[0]
            if not target or target.startswith(("http://", "https://", "mailto:", "tel:")):
                continue
            if ":" in target:
                continue
            resolved = (doc.parent / target).resolve()
            if not resolved.exists():
                broken.append((doc.name, target))
    check(not broken, f"relative Markdown links resolve (broken: {broken})")

    print("HairFlow static check")
    print(f"  plugin: {PLUGIN}")
    print(f"  bytes:  {len(raw)}")
    print(f"  buttons:{len(buttons)}")
    print()
    for line in notes:
        print(" ", line)
    print()
    if failures:
        for line in failures:
            print(" ", line)
        print(f"\nRESULT: FAIL ({len(failures)} issue(s))")
        return 1
    print("RESULT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
