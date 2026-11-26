# HairFlow install verifier - checks files only, never launches ZBrush.
param(
    [string]$ZBrush2022 = "D:\media work\ZBrush 2022.0.5",
    [string]$ZBrush2025 = "D:\media work\Zbrush2025.0.1",
    [string]$DataDir   = "C:\HairFlow"
)

$ErrorActionPreference = "Stop"
$fail = 0
$pass = 0

$script:ExpectedTxt = -1
$script:ExpectedZsc = -1
$script:ExpectedZsc22 = -1
$buildPath = Join-Path $DataDir "build.txt"
if (Test-Path $buildPath) {
    foreach ($line in Get-Content $buildPath) {
        $kv = $line -split "=", 2
        if ($kv.Count -eq 2) {
            if ($kv[0] -eq "txt") { $script:ExpectedTxt = [int]$kv[1] }
            if ($kv[0] -eq "zsc") { $script:ExpectedZsc = [int]$kv[1] }
            if ($kv[0] -eq "zsc2022") { $script:ExpectedZsc22 = [int]$kv[1] }
        }
    }
}

function Check {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        Write-Host "  PASS  $Message"
        $script:pass++
    } else {
        Write-Host "  FAIL  $Message"
        $script:fail++
    }
}

function Check-Plugin {
    param([string]$Root, [string]$Label, [int]$Expected)

    Write-Host ""
    Write-Host "[$Label] $Root"
    $plugs = Join-Path $Root "ZStartup\ZPlugs64"
    $txt = Join-Path $plugs "HairFlow.txt"
    Check (Test-Path $plugs) "ZPlugs64 exists"
    Check (Test-Path $txt) "HairFlow.txt exists"
    if (Test-Path $txt) {
        $size = (Get-Item $txt).Length
        Check ($size -gt 5000) "HairFlow.txt looks complete ($size bytes)"
        Check ($size -eq $script:ExpectedTxt) "HairFlow.txt matches build manifest ($size = $script:ExpectedTxt)"
    }
    $zsc = Join-Path $plugs "HairFlow.zsc"
    Check (Test-Path $zsc) "HairFlow.zsc exists (auto-load)"
    if (Test-Path $zsc) {
        $zsize = (Get-Item $zsc).Length
        Check ($zsize -gt 5000) "HairFlow.zsc looks complete ($zsize bytes)"
        Check ($zsize -eq $Expected) "HairFlow.zsc is this version's own build ($zsize = $Expected)"
    }
    if ($Label -like "*2022*") {
        Check (Test-Path (Join-Path $plugs "INSTALL_2022.txt")) "INSTALL_2022.txt exists"
    }
}

Write-Host "HairFlow install verifier"
Check-Plugin -Root $ZBrush2025 -Label "ZBrush 2025" -Expected $script:ExpectedZsc
Check-Plugin -Root $ZBrush2022 -Label "ZBrush 2022" -Expected $script:ExpectedZsc22

Write-Host ""
Write-Host "[Data] $DataDir"
Check (Test-Path $DataDir) "data folder exists"
Check (Test-Path (Join-Path $DataDir "version.txt")) "version.txt exists"
Check (Test-Path (Join-Path $DataDir "build.txt")) "build.txt exists"
Check ($script:ExpectedTxt -gt 0) "build manifest has txt size"
Check ($script:ExpectedZsc -gt 0) "build manifest has zsc size"
Check ($script:ExpectedZsc22 -gt 0) "build manifest has 2022 zsc size"
foreach ($doc in @("README_zh.md", "FAQ.md", "QUICK_REFERENCE.md", "ACCEPTANCE.md", "CHANGELOG.md", "workflow.svg", "seam-comparison.svg")) {
    Check (Test-Path (Join-Path $DataDir "docs\$doc")) "docs/$doc exists"
}

Write-Host ""
Write-Host "RESULT: PASS ($pass checks)" -ForegroundColor Green
if ($fail -gt 0) {
    Write-Host "RESULT: FAIL ($fail failed, $pass passed)" -ForegroundColor Red
    exit 1
}
exit 0
