# Hexa - Fan Speed Query
# ASUS ATK WMI → LHM DLL 순서로 시도
# 관리자 권한 필요 | 출력: "팬이름=RPM" (줄 단위)

# --- 1단계: ASUS ATK WMI (DLL 불필요) ---
try {
    $atk = Get-WmiObject -Namespace root\WMI -Class AsusAtkWmi_WMNB -ErrorAction Stop
    # ASUS DSTS Device IDs: CPU Fan=0x00110013, GPU Fan=0x00110014
    $fans = @(
        @{ Id = 0x00110013; Name = 'CPU Fan' }
        @{ Id = 0x00110014; Name = 'GPU Fan' }
    )
    $found = $false
    foreach ($fan in $fans) {
        $result = $atk.DSTS($fan.Id)
        $raw = $result.device_status
        if ($raw -ne $null -and $raw -ne 0xFFFFFFFE -and ($raw -band 0x10000)) {
            $rpm = ($raw -band 0xFFFF) * 100
            if ($rpm -gt 0) {
                '{0}={1}' -f $fan.Name, $rpm
                $found = $true
            }
        }
    }
    if ($found) { exit 0 }
} catch {}

# --- 2단계: LHM DLL 폴백 (비ASUS 시스템용) ---
$libDir = Join-Path $PSScriptRoot "Lib"
$lhmDll = Join-Path $libDir "LibreHardwareMonitorLib.dll"
if (-not (Test-Path $lhmDll)) { exit }

# C# 리졸버 (PowerShell ScriptBlock 대신 → StackOverflow 방지)
Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Reflection;
public static class AsmResolver {
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
"@
[AsmResolver]::Register($libDir)
[System.Reflection.Assembly]::LoadFrom($lhmDll) | Out-Null

try {
    $c = New-Object LibreHardwareMonitor.Hardware.Computer
    $c.IsCpuEnabled = $true
    $c.IsGpuEnabled = $true
    $c.IsMotherboardEnabled = $true
    $c.IsControllerEnabled = $true
    $c.Open()

    foreach ($hw in $c.Hardware) {
        $hw.Update()
        foreach ($sub in $hw.SubHardware) { $sub.Update() }
        foreach ($s in $hw.Sensors) {
            if ($s.SensorType.ToString() -eq 'Fan' -and $s.Value -gt 0) {
                '{0}={1}' -f $s.Name, [int]$s.Value
            }
        }
        foreach ($sub in $hw.SubHardware) {
            foreach ($s in $sub.Sensors) {
                if ($s.SensorType.ToString() -eq 'Fan' -and $s.Value -gt 0) {
                    '{0}={1}' -f $s.Name, [int]$s.Value
                }
            }
        }
    }
    $c.Close()
} catch {}
