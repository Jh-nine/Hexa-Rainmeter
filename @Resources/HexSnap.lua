-- HexSnap.lua
-- 허니콤 그리드 스냅 스크립트
-- 드래그 후 가장 가까운 허니콤 격자점에 자동 정렬
-- 해상도 대응: 기준 해상도 대비 현재 해상도 비율로 간격 자동 조정
-- 충돌 방지: 큰 모듈(비주얼라이저) 영역을 작은 모듈이 피해서 스냅

local prevX, prevY = 0, 0
local moved = false
local stableCount = 0
local snappedX, snappedY = -9999, -9999
local STABLE_THRESHOLD = 2  -- Update 주기 x 2 안정 후 스냅

-- 해상도 기반 스냅 간격 (Initialize에서 자동 계산)
local spacingX = 88
local halfX = 44
local spacingY = 76
local snapScale = 1.0
local resPath = ''
local moduleSize = 100

function Initialize()
    prevX = SKIN:GetX()
    prevY = SKIN:GetY()
    resPath = SKIN:GetVariable('@')
    moduleSize = tonumber(SKIN:GetVariable('HexModuleSize', '100'))
    CalcScale()
    -- 큰 모듈(비주얼라이저)이면 초기 위치를 파일에 기록
    if moduleSize > 100 then
        WriteLargeSkinPos(SKIN:GetX(), SKIN:GetY(), moduleSize)
    end
end

function CalcScale()
    -- 현재 화면 해상도
    local screenW = tonumber(SKIN:GetVariable('SCREENAREAWIDTH', '1920'))
    local screenH = tonumber(SKIN:GetVariable('SCREENAREAHEIGHT', '1080'))
    -- 기준 해상도 (Variables.inc에서 설정)
    local refW = tonumber(SKIN:GetVariable('ReferenceWidth', '1920'))
    local refH = tonumber(SKIN:GetVariable('ReferenceHeight', '1080'))

    -- 스케일 팩터: 가로/세로 중 작은 비율 사용 (허니콤 형태 유지, 와이드 모니터 대응)
    local scaleW = screenW / refW
    local scaleH = screenH / refH
    snapScale = math.min(scaleW, scaleH)

    -- 기본 오프셋에 스케일 적용 (모든 모듈 동일 그리드)
    local baseX = tonumber(SKIN:GetVariable('HexOffsetX', '88'))
    local baseDX = tonumber(SKIN:GetVariable('HexOffsetDX', '44'))
    local baseDY = tonumber(SKIN:GetVariable('HexOffsetDY', '76'))

    spacingX = baseX * snapScale
    halfX = baseDX * snapScale
    spacingY = baseDY * snapScale
end

-- ====== 충돌 방지 (큰 모듈 ↔ 작은 모듈) ======

-- 큰 모듈 위치 기록
function WriteLargeSkinPos(x, y, size)
    local f = io.open(resPath .. 'LargeSkinPos.dat', 'w')
    if f then
        f:write(math.floor(x + 0.5) .. ',' .. math.floor(y + 0.5) .. ',' .. math.floor(size))
        f:close()
    end
end

-- 큰 모듈 위치 읽기
function ReadLargeSkinPos()
    local ok, f = pcall(io.open, resPath .. 'LargeSkinPos.dat', 'r')
    if not ok or not f then return nil end
    local data = f:read('*all')
    f:close()
    if not data or data == '' then return nil end
    local bx, by, bs = data:match('(-?%d+),(-?%d+),(%d+)')
    if bx then return tonumber(bx), tonumber(by), tonumber(bs) end
    return nil
end

-- AABB 사각형 충돌 검사
function CheckOverlap(cx, cy, mySize, vx, vy, vSize)
    return cx + mySize > vx and cx < vx + vSize and
           cy + mySize > vy and cy < vy + vSize
end

-- ====== 스냅 로직 ======

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

    -- 작은 모듈이면 큰 모듈 위치 읽기
    local vizX, vizY, vizSize = nil, nil, nil
    if moduleSize <= 100 then
        vizX, vizY, vizSize = ReadLargeSkinPos()
    end

    -- 충돌 방지 시 검색 범위 확대 (겹치는 영역 너머의 격자점까지)
    local searchRange = (vizX and 3) or 1

    local bestX, bestY = x, y
    local bestDist = math.huge

    for rowOff = -searchRange, searchRange do
        local row = math.floor((y - oy) / spacingY + 0.5) + rowOff
        local rowOffset = (row % 2 ~= 0) and halfX or 0
        local col = math.floor((x - ox - rowOffset) / spacingX + 0.5)

        for colOff = -searchRange, searchRange do
            local cx = ox + rowOffset + (col + colOff) * spacingX
            local cy = oy + row * spacingY
            cx = math.floor(cx + 0.5)
            cy = math.floor(cy + 0.5)

            -- 큰 모듈 영역과 겹치면 스킵
            local skip = false
            if vizX and CheckOverlap(cx, cy, moduleSize, vizX, vizY, vizSize) then
                skip = true
            end

            if not skip then
                local dist = (cx - x) * (cx - x) + (cy - y) * (cy - y)
                if dist < bestDist then
                    bestDist = dist
                    bestX = cx
                    bestY = cy
                end
            end
        end
    end

    -- 큰 모듈이면 위치 파일 갱신
    if moduleSize > 100 then
        WriteLargeSkinPos(bestX, bestY, moduleSize)
    end

    snappedX = bestX
    snappedY = bestY

    if x ~= bestX or y ~= bestY then
        SKIN:Bang('!Move', bestX, bestY)
    end
end
