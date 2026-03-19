-- SettingsHelper.lua
-- Settings 패널 인터랙션 핸들러

local pages = {'PageMonitor', 'PageVisual', 'PageMisc'}
local tabActive = {'TabMonitor', 'TabVisual', 'TabMisc'}
local activeColor
local inactiveColor

function Initialize()
    activeColor = SKIN:GetVariable('ColorSecondary', '100,180,255,255')
    inactiveColor = SKIN:GetVariable('ColorSubText', '180,180,180,255')
    ShowPage(1)
end

function Update()
end

-- 페이지 전환
function ShowPage(idx)
    for i, group in ipairs(pages) do
        if i == idx then
            SKIN:Bang('!ShowMeterGroup', group)
            SKIN:Bang('!SetOption', tabActive[i], 'FontColor', activeColor)
        else
            SKIN:Bang('!HideMeterGroup', group)
            SKIN:Bang('!SetOption', tabActive[i], 'FontColor', inactiveColor)
        end
        SKIN:Bang('!UpdateMeter', tabActive[i])
    end
    SKIN:Bang('!Redraw')
end

-- 슬라이더 클릭 → 값 계산 → 저장 → 새로고침
function SliderClick(mouseX, trackW, minV, maxV, varName)
    local ratio = math.max(0, math.min(1, mouseX / trackW))
    local val = math.floor(minV + ratio * (maxV - minV) + 0.5)
    val = math.max(minV, math.min(maxV, val))
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    SKIN:Bang('!WriteKeyValue', 'Variables', varName, tostring(val), path)
    SKIN:Bang('!RefreshApp')
end

-- 디스크 드라이브 순환
function CycleDrive(direction)
    local drives = {'C:', 'D:', 'E:', 'F:', 'G:'}
    local cur = SKIN:GetVariable('DiskDrive', 'C:')
    local idx = 1
    for i, d in ipairs(drives) do
        if d == cur then idx = i; break end
    end
    idx = idx + direction
    if idx < 1 then idx = #drives
    elseif idx > #drives then idx = 1 end
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    SKIN:Bang('!WriteKeyValue', 'Variables', 'DiskDrive', drives[idx], path)
    SKIN:Bang('!RefreshApp')
end

-- 네트워크 대역폭 프리셋 순환
function CycleBandwidth(direction)
    local presets = {10, 50, 100, 500, 1000}
    local cur = tonumber(SKIN:GetVariable('NetMaxBandwidth', '100'))
    local idx = 3
    local minDiff = math.huge
    for i, v in ipairs(presets) do
        if math.abs(v - cur) < minDiff then
            minDiff = math.abs(v - cur)
            idx = i
        end
    end
    idx = math.max(1, math.min(#presets, idx + direction))
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    SKIN:Bang('!WriteKeyValue', 'Variables', 'NetMaxBandwidth', tostring(presets[idx]), path)
    SKIN:Bang('!RefreshApp')
end

-- 미디어 정보 위치 토글 (왼쪽/오른쪽)
function ToggleMediaSide()
    local cur = SKIN:GetVariable('MediaInfoSide', '1')
    local new = (cur == '1') and '0' or '1'
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    SKIN:Bang('!WriteKeyValue', 'Variables', 'MediaInfoSide', new, path)
    SKIN:Bang('!RefreshApp')
end

-- HSV → RGB 변환
function hsvToRgb(h, s, v)
    local c = v * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 60 then r, g, b = c, x, 0
    elseif h < 120 then r, g, b = x, c, 0
    elseif h < 180 then r, g, b = 0, c, x
    elseif h < 240 then r, g, b = 0, x, c
    elseif h < 300 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    return math.floor((r + m) * 255 + 0.5),
           math.floor((g + m) * 255 + 0.5),
           math.floor((b + m) * 255 + 0.5)
end

-- 색상 적용 공통
function applyColor(target, r, g, b)
    local colorStr = string.format('%d,%d,%d', r, g, b)
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    if target == 'accent' then
        SKIN:Bang('!WriteKeyValue', 'Variables', 'ColorSecondary', colorStr .. ',255', path)
    elseif target == 'sub' then
        SKIN:Bang('!WriteKeyValue', 'Variables', 'ColorAccent', colorStr .. ',255', path)
    elseif target == 'wave' then
        SKIN:Bang('!WriteKeyValue', 'Variables', 'VisualizerColor', colorStr, path)
    end
    SKIN:Bang('!RefreshApp')
end

-- 팔레트 클릭 → 색조(Hue) 기반 색상 선택
function PaletteClick(mouseX, barW, target)
    local hue = math.max(0, math.min(1, mouseX / barW)) * 360
    local r, g, b = hsvToRgb(hue, 1, 1)
    applyColor(target, r, g, b)
end

-- 그레이스케일 팔레트 클릭
function GrayPaletteClick(mouseX, barW, target)
    local v = math.max(0, math.min(1, mouseX / barW))
    local gray = math.floor(v * 255 + 0.5)
    applyColor(target, gray, gray, gray)
end

-- 테두리 굵기 순환 (1, 2, 3)
function CycleBorderWidth(direction)
    local cur = tonumber(SKIN:GetVariable('BorderWidth', '2'))
    cur = cur + direction
    if cur < 1 then cur = 3
    elseif cur > 3 then cur = 1 end
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    SKIN:Bang('!WriteKeyValue', 'Variables', 'BorderWidth', tostring(cur), path)
    SKIN:Bang('!RefreshApp')
end

-- 모든 설정을 기본값으로 초기화
function ResetDefaults()
    local path = SKIN:GetVariable('@') .. 'Variables.inc'
    SKIN:Bang('!WriteKeyValue', 'Variables', 'WarningThreshold', '50', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'DangerThreshold', '80', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'DiskDrive', 'C:', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'NetMaxBandwidth', '100', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'ColorSecondary', '100,180,255,255', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'ColorAccent', '0,200,150,255', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'VisualizerColor', '200,200,200', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'MediaInfoSide', '1', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'BorderWidth', '2', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'SnapOriginX', '0', path)
    SKIN:Bang('!WriteKeyValue', 'Variables', 'SnapOriginY', '0', path)
    SKIN:Bang('!RefreshApp')
end
