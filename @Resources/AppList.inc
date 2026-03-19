; =============================================
; Hexa - App Dock Configuration
; AppCount, AppName, AppLaunch, AppIcon 설정
; =============================================
; 형식:
;   AppName_N   = 표시 이름 (ToolTip)
;   AppLaunch_N = 실행 액션 (Rainmeter bang 형식)
;   AppIcon_N   = 아이콘 경로
;
; 최대 슬롯: DockColumns x DockRows (Variables.inc)
; AppCount를 실제 앱 수에 맞춰 설정

[Variables]
AppCount=3

; --- App 1 ---
AppName_1=Google
AppLaunch_1=["https://www.google.com"]
AppIcon_1=#@#Icons\google.png

; --- App 2 ---
AppName_2=YouTube
AppLaunch_2=["chrome" --profile-directory=Default --app-id=agimnkijcaahngcdmfeangaknmldooml]
AppIcon_2=#@#Icons\youtube.png

; --- App 3 ---
AppName_3=YouTube Music
AppLaunch_3=["chrome" --profile-directory=Default --app-id=cinhimbnkkaeohfgghhklpknlkffjgod]
AppIcon_3=#@#Icons\YT-music.png

; --- App 4~6 (빈 슬롯, 필요시 채우세요) ---
AppName_4=
AppLaunch_4=
AppIcon_4=

AppName_5=
AppLaunch_5=
AppIcon_5=

AppName_6=
AppLaunch_6=
AppIcon_6=