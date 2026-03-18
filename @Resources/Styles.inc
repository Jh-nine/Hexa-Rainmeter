; =============================================
; Hexa - 공통 육각형 Shape 스타일
; Shape 미터에서 @Include로 사용
; =============================================

; 정육각형 좌표 계산 (뾰족한 꼭지점이 위/아래):
; 중심 (cx, cy), 반지름 r 기준
; 꼭짓점: (cx, cy-r), (cx+r*0.866, cy-r*0.5), (cx+r*0.866, cy+r*0.5),
;          (cx, cy+r), (cx-r*0.866, cy+r*0.5), (cx-r*0.866, cy-r*0.5)

[StyleHexagonBorder]
Shape=Path HexPath | StrokeWidth 2 | Stroke Color #ColorBorder# | Fill Color 0,0,0,1
HexPath=50,0 | LineTo 93.5,25 | LineTo 93.5,75 | LineTo 50,100 | LineTo 6.5,75 | LineTo 6.5,25 | ClosePath 1

[StyleHexagonFilled]
Shape=Path HexPath | StrokeWidth 2 | Stroke Color #ColorBorder# | Fill Color #ColorSecondary#
HexPath=50,0 | LineTo 93.5,25 | LineTo 93.5,75 | LineTo 50,100 | LineTo 6.5,75 | LineTo 6.5,25 | ClosePath 1

[StyleHexagonText]
FontFace=#FontFace#
FontColor=#ColorText#
FontSize=#FontSize#
AntiAlias=1
StringAlign=Center
