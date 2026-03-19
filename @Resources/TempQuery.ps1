# Hexa - Temperature Query
# ACPI Thermal Zone → LHM DLL 순서로 시도
# 관리자 권한 필요 (LHM 폴백 시) | 출력: "CPU=xx" "GPU=xx" (섭씨, 줄 단위)
# 캐시: 4초 이내 재호출 시 캐시 파일에서 읽음

param([string]$Type)

$cacheFile = Join-Path $PSScriptRoot "Lib\TempCache.txt"
$cacheMaxAge = 4

# --- 캐시 확인 ---
if ($Type -and (Test-Path $cacheFile)) {
    $age = ((Get-Date) - (Get-Item $cacheFile).LastWriteTime).TotalSeconds
    if ($age -lt $cacheMaxAge) {
        $cached = Get-Content $cacheFile -Raw -ErrorAction SilentlyContinue
        if ($cached -match "$Type=(-?\d+)") {
            $Matches[1]
            exit 0
        }
    }
}

$lines = @()

# --- 1단계: ACPI Thermal Zone (노트북 등 ACPI 지원 시스템) ---
try {
    $samples = (Get-Counter "\Thermal Zone Information(*)\Temperature" -ErrorAction Stop).CounterSamples
    if ($samples.Count -gt 0) {
        $cpuK = $samples[0].CookedValue
        if ($cpuK -gt 200) {
            $lines += 'CPU={0}' -f [math]::Round($cpuK - 273.15, 0)
        }
    }
    if ($samples.Count -gt 1) {
        $gpuK = $samples[1].CookedValue
        if ($gpuK -gt 200) {
            $lines += 'GPU={0}' -f [math]::Round($gpuK - 273.15, 0)
        }
    }
    if ($lines.Count -ge 2) {
        $lines -join "`n" | Set-Content $cacheFile -NoNewline -ErrorAction SilentlyContinue
        if ($Type) {
            $all = $lines -join "`n"
            if ($all -match "$Type=(-?\d+)") { $Matches[1] }
        } else { $lines -join "`n" }
        exit 0
    }
} catch {}

# --- 2단계: LHM DLL 폴백 (비ACPI 시스템 / 데스크탑) ---
$libDir = Join-Path $PSScriptRoot "Lib"
$lhmDll = Join-Path $libDir "LibreHardwareMonitorLib.dll"
if (-not (Test-Path $lhmDll)) {
    Write-Output "0"
    exit
}

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Reflection;
public static class TempAsmResolver {
    static string _dir;
    public static void Register(string dir) {
        _dir = dir;
        AppDomain.CurrentDomain.AssemblyResolve += OnResolve;
    }
    static Assembly OnResolve(object s, ResolveEventArgs e) {
        string name = new AssemblyName(e.Name).Name;
        string path = Path.Combine(_dir, name + ".dll");
        return File.Exists(path) ? Assembly.LoadFrom(path) : null;
    }
}
"@ -ErrorAction SilentlyContinue
[TempAsmResolver]::Register($libDir)
[System.Reflection.Assembly]::LoadFrom($lhmDll) | Out-Null

try {
    $c = New-Object LibreHardwareMonitor.Hardware.Computer
    $c.IsCpuEnabled = $true
    $c.IsGpuEnabled = $true
    $c.Open()

    $cpuTemp = $null
    $gpuTemp = $null

    foreach ($hw in $c.Hardware) {
        $hw.Update()
        foreach ($sub in $hw.SubHardware) { $sub.Update() }

        $hwType = $hw.HardwareType.ToString()

        foreach ($s in $hw.Sensors) {
            if ($s.SensorType.ToString() -eq 'Temperature' -and $s.Value -ne $null) {
                # CPU Package / CPU Core 온도
                if ($hwType -eq 'Cpu' -and $null -eq $cpuTemp -and $s.Name -match 'Package|Core') {
                    $cpuTemp = [math]::Round($s.Value, 0)
                }
                # GPU Core 온도
                if ($hwType -match 'Gpu' -and $null -eq $gpuTemp -and $s.Name -match 'Core|Hot Spot') {
                    $gpuTemp = [math]::Round($s.Value, 0)
                }
            }
        }
        foreach ($sub in $hw.SubHardware) {
            foreach ($s in $sub.Sensors) {
                if ($s.SensorType.ToString() -eq 'Temperature' -and $s.Value -ne $null) {
                    if ($hwType -eq 'Cpu' -and $null -eq $cpuTemp -and $s.Name -match 'Package|Core') {
                        $cpuTemp = [math]::Round($s.Value, 0)
                    }
                    if ($hwType -match 'Gpu' -and $null -eq $gpuTemp -and $s.Name -match 'Core|Hot Spot') {
                        $gpuTemp = [math]::Round($s.Value, 0)
                    }
                }
            }
        }
    }
    $c.Close()

    if ($cpuTemp -ne $null -and $cpuTemp -gt 0) { $lines += 'CPU={0}' -f $cpuTemp }
    if ($gpuTemp -ne $null -and $gpuTemp -gt 0) { $lines += 'GPU={0}' -f $gpuTemp }
} catch {}

# --- 출력 및 캐시 저장 ---
if ($lines.Count -gt 0) {
    $all = $lines -join "`n"
    $all | Set-Content $cacheFile -NoNewline -ErrorAction SilentlyContinue
    if ($Type) {
        if ($all -match "$Type=(-?\d+)") { $Matches[1] } else { "0" }
    } else { $all }
} else {
    "--"
}
