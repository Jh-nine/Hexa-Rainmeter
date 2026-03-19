-- FanParse.lua
-- RunCommand 출력 파싱 → 팬 미터 동적 표시

local maxSlots = 4
local fanCount = 0
local fans = {}

function Initialize()
    fanCount = 0
    fans = {}
end

function Update()
end

-- RunCommand FinishAction에서 호출
function ParseAndUpdate()
    local measure = SKIN:GetMeasure('MeasureFanQuery')
    local raw = measure:GetStringValue()
    parseFanData(raw)
    updateMeters()
end

function parseFanData(data)
    fans = {}
    fanCount = 0
    if not data or data == '' then return end
    for line in data:gmatch('[^\r\n]+') do
        local name, rpm = line:match('^(.-)=(%d+)$')
        if name and rpm then
            fanCount = fanCount + 1
            if fanCount <= maxSlots then
                fans[fanCount] = { name = name, rpm = tonumber(rpm) }
            end
        end
    end
end

function shortenName(name)
    -- "CPU Fan" → "CPU FAN", "GPU Fan" → "GPU FAN", "Fan #1" → "FAN 1"
    local short = name:upper()
    short = short:gsub('#', '')
    short = short:gsub('%s+', ' ')
    short = short:match('^%s*(.-)%s*$') or ''
    if short == '' then short = 'FAN' end
    if #short > 8 then short = short:sub(1, 8) end
    return short
end

function updateMeters()
    local maxRPM = tonumber(SKIN:GetVariable('FanMaxRPM', '3000'))

    for i = 1, maxSlots do
        local group = 'Fan' .. i
        if i <= fanCount and fans[i] then
            SKIN:Bang('!ShowMeterGroup', group)

            local shortName = shortenName(fans[i].name)
            SKIN:Bang('!SetOption', 'TitleFan' .. i, 'Text', shortName)
            SKIN:Bang('!SetOption', 'ValueFan' .. i, 'Text', tostring(fans[i].rpm))

            -- 프로그레스 바
            local pct = math.min(100, fans[i].rpm / maxRPM * 100)
            local dashLen = string.format('%.1f', math.max(0.1, pct * 1.35))
            local color = SKIN:GetVariable('ColorText', '240,240,240,255')
            SKIN:Bang('!SetOption', 'ProgressFan' .. i, 'Shape2',
                'Path ProgressPath | StrokeWidth 2 | Stroke Color ' .. color ..
                ' | Fill Color 0,0,0,0 | StrokeDashes ' .. dashLen ..
                ',500 | StrokeDashCap Flat')

            -- ToolTip
            SKIN:Bang('!SetOption', 'HitFan' .. i, 'ToolTipText',
                fans[i].name .. ': ' .. tostring(fans[i].rpm) .. ' RPM')
        else
            SKIN:Bang('!HideMeterGroup', group)
        end
    end

    -- 팬 없음 표시
    if fanCount == 0 then
        SKIN:Bang('!ShowMeterGroup', 'NoFan')
    else
        SKIN:Bang('!HideMeterGroup', 'NoFan')
    end

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')
end
