-- HexSnap.lua
-- 허니콤 그리드 스냅 스크립트
-- 드래그 후 가장 가까운 허니콤 격자점에 자동 정렬

local prevX, prevY = 0, 0
local moved = false
local stableCount = 0
local snappedX, snappedY = -9999, -9999
local STABLE_THRESHOLD = 2  -- Update 주기 x 2 안정 후 스냅

function Initialize()
    prevX = SKIN:GetX()
    prevY = SKIN:GetY()
end

function Update()
    local x = SKIN:GetX()
    local y = SKIN:GetY()

    -- 방금 스냅한 위치면 무시 (재귀 방지)
    if x == snappedX and y == snappedY then
        prevX = x
        prevY = y
        return
    end

    if x ~= prevX or y ~= prevY then
        -- 위치가 변했다 = 드래그 중
        moved = true
        stableCount = 0
        prevX = x
        prevY = y
    elseif moved then
        -- 위치가 안정됨 = 드래그 끝
        stableCount = stableCount + 1
        if stableCount >= STABLE_THRESHOLD then
            moved = false
            stableCount = 0
            Snap()
        end
    end
end

function Snap()
    local x = SKIN:GetX()
    local y = SKIN:GetY()

    local ox = tonumber(SKIN:GetVariable('SnapOriginX', '0'))
    local oy = tonumber(SKIN:GetVariable('SnapOriginY', '0'))
    local spacingX = tonumber(SKIN:GetVariable('HexOffsetX', '88'))
    local halfX = tonumber(SKIN:GetVariable('HexOffsetDX', '44'))
    local spacingY = tonumber(SKIN:GetVariable('HexOffsetDY', '76'))

    -- 가장 가까운 격자점 찾기 (짝수행 + 홀수행 모두 비교)
    local bestX, bestY = x, y
    local bestDist = math.huge

    for rowOff = -1, 1 do
        local row = math.floor((y - oy) / spacingY + 0.5) + rowOff
        local rowOffset = (row % 2 ~= 0) and halfX or 0
        local col = math.floor((x - ox - rowOffset) / spacingX + 0.5)

        for colOff = -1, 1 do
            local cx = ox + rowOffset + (col + colOff) * spacingX
            local cy = oy + row * spacingY
            local dist = (cx - x) * (cx - x) + (cy - y) * (cy - y)
            if dist < bestDist then
                bestDist = dist
                bestX = cx
                bestY = cy
            end
        end
    end

    snappedX = bestX
    snappedY = bestY

    if x ~= bestX or y ~= bestY then
        SKIN:Bang('!Move', bestX, bestY)
    end
end
