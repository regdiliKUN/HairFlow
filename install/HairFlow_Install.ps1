# HairFlow installer for ZBrush 2022.0.5 / 2025.0.1
# Copies the plugin sources, creates the data directory, and backs up old copies.
# It never deletes user projects or other plugins.

param(
    [string]$ZBrush2022 = "D:\media work\ZBrush 2022.0.5",
    [string]$ZBrush2025 = "D:\media work\Zbrush2025.0.1",
    [string]$Source      = (Join-Path $PSScriptRoot "..\plugin")
)

$ErrorActionPreference = "Stop"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$Version = "1.6.0"
$dataDir = "C:\HairFlow"
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

$DocsSource = Join-Path $PSScriptRoot "..\docs"
$docsDir = Join-Path $dataDir "docs"
New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
foreach ($doc in @("README_zh.md", "FAQ.md", "QUICK_REFERENCE.md", "ACCEPTANCE.md", "CHANGELOG.md", "workflow.svg", "seam-comparison.svg")) {
    $srcDoc = Join-Path $DocsSource $doc
    if (Test-Path $srcDoc) {
        Copy-Item $srcDoc (Join-Path $docsDir $doc) -Force
    }
}
Set-Content -Path (Join-Path $dataDir "version.txt") -Value "HairFlow $Version" -Encoding ASCII

$srcTxt = Join-Path $Source "HairFlow.txt"
$srcZsc = Join-Path $Source "HairFlow.zsc"
$manifest = @("version=$Version")
if (Test-Path $srcTxt) { $manifest += "txt=$((Get-Item $srcTxt).Length)" }
if (Test-Path $srcZsc) { $manifest += "zsc=$((Get-Item $srcZsc).Length)" }
$srcZsc22 = Join-Path $Source "HairFlow_2022.zsc"
if (Test-Path $srcZsc22) { $manifest += "zsc2022=$((Get-Item $srcZsc22).Length)" }
Set-Content -Path (Join-Path $dataDir "build.txt") -Value ($manifest -join "`r`n") -Encoding ASCII
Write-Host "Docs copied to $docsDir"

function Install-Plugin {
    param(
        [string]$Root,
        [string]$Label,
        [string]$ZscName = "HairFlow.zsc"
    )

    if (-not (Test-Path $Root)) {
        Write-Host "[$Label] skipped: ZBrush folder not found: $Root"
        return
    }

    $plugs = Join-Path $Root "ZStartup\ZPlugs64"
    if (-not (Test-Path $plugs)) {
        Write-Host "[$Label] skipped: $plugs not found"
        return
    }

    $srcTxt = Join-Path $Source "HairFlow.txt"
    if (-not (Test-Path $srcTxt)) {
        throw "HairFlow.txt not found in source folder: $Source"
    }

    $oldFiles = @()
    foreach ($name in @("HairFlow.txt", "HairFlow.zsc")) {
        $old = Join-Path $plugs $name
        if (Test-Path $old) { $oldFiles += $old }
    }
    if ($oldFiles.Count -gt 0) {
        $backup = Join-Path $Root ("_hairflow_backup_" + $stamp)
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        foreach ($old in $oldFiles) {
            Copy-Item $old (Join-Path $backup (Split-Path $old -Leaf)) -Force
        }
        Write-Host "[$Label] backup: $backup"
    } else {
        Write-Host "[$Label] no previous HairFlow files; nothing to back up"
    }

    Copy-Item $srcTxt (Join-Path $plugs "HairFlow.txt") -Force
    $copied = Get-Item (Join-Path $plugs "HairFlow.txt")
    Write-Host "[$Label] copied HairFlow.txt ($($copied.Length) bytes)"

    # Each ZBrush version gets the .zsc compiled by that version (2022 and 2025
    # bytecode differ: 49204 vs 16376 bytes for the same 1.6.0 source).
    $zsc = Join-Path $Source $ZscName
    if (Test-Path $zsc) {
        Copy-Item $zsc (Join-Path $plugs "HairFlow.zsc") -Force
        Write-Host "[$Label] copied $ZscName as HairFlow.zsc (auto-load)"
    } else {
        Write-Host "[$Label] $ZscName missing; load HairFlow.txt once in ZScript > Load"
    }
    if ($Label -like "*2022*") {
        $note = @(
            "HairFlow $Version for ZBrush 2022.0.5",
            "",
            "Folder: $plugs",
            "",
            "HairFlow.zsc here was compiled BY ZBrush 2022.0.5 itself (it is not",
            "the 2025 build) and loads automatically.",
            "",
            "Only if you edit HairFlow.txt, recompile:",
            "1. Start ZBrush 2022.",
            "2. Open ZScript > Load.",
            "3. Choose this folder's HairFlow.txt.",
            "4. ZBrush writes HairFlow.zsc next to it.",
            "5. Restart ZBrush; the panel appears under ZPlugin > HairFlow.",
            "",
            "Verify:",
            "6. HairFlow.zsc exists next to HairFlow.txt.",
            "7. ZPlugin > HairFlow shows the Preflight / Long Strand buttons.",
            "   Optional: copy tests\probe_ui.txt into ZStartup\Macros\<folder>, restart,",
            "   and check every Stroke path resolves as listed in docs\VERIFICATION.md.",
            "8. If the panel is missing, close ZBrush, confirm only one HairFlow.zsc",
            "   is present, then start ZBrush again.",
            "",
            "If ZBrush 2022 shows 'Unable To Open File' and exits, close ZBrush 2025",
            "first: on this machine 2022 only failed while 2025 was also running."
        ) -join "`r`n"
        Set-Content -Path (Join-Path $plugs "INSTALL_2022.txt") -Value $note -Encoding ASCII
        Write-Host "[$Label] source installed; see INSTALL_2022.txt"
    }

    $finalTxt = Get-Item (Join-Path $plugs "HairFlow.txt")
    Write-Host "[$Label] ready: HairFlow.txt ($($finalTxt.Length) bytes)"
}

Write-Host "HairFlow $Version installer"
Write-Host "  source: $Source"
Write-Host "  data:   $dataDir"

Install-Plugin -Root $ZBrush2025 -Label "ZBrush 2025" -ZscName "HairFlow.zsc"
Install-Plugin -Root $ZBrush2022 -Label "ZBrush 2022" -ZscName "HairFlow_2022.zsc"

Write-Host ""
Write-Host "Done. Launch ZBrush and open ZPlugin > HairFlow."
Write-Host "Docs: docs\README_zh.md"
