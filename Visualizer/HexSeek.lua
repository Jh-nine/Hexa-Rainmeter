-- HexSeek.lua
-- 육각형 프로그래스바 클릭/드래그로 미디어 탐색

-- 내부 육각형 꼭짓점 (ProgressPath)
local verts = {
    {100, 8},
    {179.7, 54},
    {179.7, 146},
    {100, 192},
    {20.3, 146},
    {20.3, 54}
}

local numVerts = #verts
local isDragging = false

-- 각 변의 길이와 누적 거리 미리 계산
local edgeLen = {}
local cumLen = {0}
local totalPerim = 0

function Initialize()
    for i = 1, numVerts do
        local j = (i % numVerts) + 1
        local dx = verts[j][1] - verts[i][1]
        local dy = verts[j][2] - verts[i][2]
        edgeLen[i] = math.sqrt(dx * dx + dy * dy)
        totalPerim = totalPerim + edgeLen[i]
        cumLen[i + 1] = totalPerim
    end
end

-- 마우스 좌표 → 육각형 둘레 퍼센트 변환
local function MouseToPercent(mx, my)
    local bestDist = math.huge
    local bestEdge = 1
    local bestT = 0

    for i = 1, numVerts do
        local j = (i % numVerts) + 1
        local ax, ay = verts[i][1], verts[i][2]
        local bx, by = verts[j][1], verts[j][2]

        local dx = bx - ax
        local dy = by - ay
        local len2 = dx * dx + dy * dy

        -- 점을 변 위에 투영
        local t = ((mx - ax) * dx + (my - ay) * dy) / len2
        t = math.max(0, math.min(1, t))

        local px = ax + t * dx
        local py = ay + t * dy
        local dist = math.sqrt((mx - px) ^ 2 + (my - py) ^ 2)

        if dist < bestDist then
            bestDist = dist
            bestEdge = i
            bestT = t
        end
    end

    local seekDist = cumLen[bestEdge] + bestT * edgeLen[bestEdge]
    return (seekDist / totalPerim) * 100
end

-- 클릭으로 탐색
function Seek(mx, my)
    local percent = MouseToPercent(tonumber(mx), tonumber(my))
    SKIN:Bang('!CommandMeasure MeasurePlayer "SetPosition ' .. string.format("%.1f", percent) .. '"')
end

-- 드래그 시작
function DragStart(mx, my)
    isDragging = true
    Seek(mx, my)
end

-- 드래그 중 (Update에서 호출)
function DragMove(mx, my)
    if isDragging then
        Seek(mx, my)
    end
end

-- 드래그 종료
function DragEnd()
    isDragging = false
end
