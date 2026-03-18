; =============================================
; Hexa - 怨듯넻 ?↔컖??Shape ?ㅽ???
; Shape 誘명꽣?먯꽌 @Include濡??ъ슜
; =============================================

; ?뺤쑁媛곹삎 醫뚰몴 怨꾩궛 (毓곗”??瑗???먯씠 ???꾨옒):
; 以묒떖 (cx, cy), 諛섏?由?r 湲곗?
; 瑗?쭞?? (cx, cy-r), (cx+r*0.866, cy-r*0.5), (cx+r*0.866, cy+r*0.5),
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
