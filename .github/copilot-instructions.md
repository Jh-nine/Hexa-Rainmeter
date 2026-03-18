# HEXA Rainmeter Skin — AI 코딩 지침

## 프로젝트 개요
육각형(Hexagon) 기반 Rainmeter 데스크탑 스킨. 하드웨어 모니터, 앱 독, 오디오 비주얼라이저, 설정 패널로 구성.

## 핵심 원칙: 하드코딩 금지, 범용 호환

### 1. 하드웨어 정보 — 반드시 동적 Measure 사용

| 항목 | 사용해야 할 방식 | 금지 (하드코딩) |
|------|------------------|-----------------|
| CPU 사용률 | `Measure=CPU` (내장) | 특정 CPU 모델명 |
| CPU 온도 | `Plugin=UsageMonitor` Category=Thermal Zone Information | 특정 센서 경로 |
| GPU 사용률 | `Plugin=UsageMonitor` Alias=GPU | 특정 GPU 모델명 |
| GPU 온도 | `Plugin=UsageMonitor` Category/Counter 방식 | `nvidia-smi`, `aticonfig` 등 벤더 전용 CLI |
| 메모리 | `Measure=PhysicalMemory` (내장) | 특정 RAM 용량/속도 |
| 디스크 | `Measure=FreeDiskSpace` + **변수로 드라이브 지정** | `Drive=C:` 직접 하드코딩 |
| 배터리 | `Plugin=PowerPlugin` | — |
| 네트워크 | `Measure=NetTotal` / `Plugin=UsageMonitor` Alias=Network | 특정 어댑터명 |
| 오디오 | `Plugin=AudioLevel` Port=Output | 특정 오디오 장치 ID |
| 미디어 | `Plugin=WebNowPlaying` | 특정 플레이어 경로 |

**GPU 온도 호환 방식 (nvidia-smi 금지):**
```ini
; UsageMonitor로 범용 GPU 온도 (NVIDIA/AMD/Intel 모두 호환)
[MeasureGPUTemp]
Measure=Plugin
Plugin=UsageMonitor
Category=GPU Engine
Counter=Utilization Percentage
Index=0
; 온도가 필요하면 HWiNFO 플러그인 또는 UsageMonitor 카테고리 활용
```

**디스크 드라이브 — 변수로 관리:**
```ini
; Variables.inc에 정의
DiskDrive=C:

; 사용 시
[MeasureDiskUsed]
Measure=FreeDiskSpace
Drive=#DiskDrive#
```

### 2. 소프트웨어 경로 — 절대경로 금지

| 사용해야 할 방식 | 금지 |
|------------------|------|
| `#@#` (스킨 @Resources 경로) | `C:\Users\xxx\...` |
| `#CURRENTPATH#` (현재 .ini 경로) | 절대 경로 |
| `#SKINSPATH#` (스킨 루트 경로) | 사용자명 포함 경로 |
| `#SETTINGSPATH#` (Rainmeter 설정 경로) | 드라이브 하드코딩 |
| Rainmeter 내장 변수 (`#WORKAREAX#`, `#SCREENAREAWIDTH#` 등) | 해상도 하드코딩 |

**앱 실행 — 시스템 PATH나 프로토콜 활용:**
```ini
; URL 기반 실행 (브라우저 종속 제거)
Parameter=/c start "" "#AppUrl_1#"

; 실행파일은 PATH에 있는 명칭 또는 변수로
AppExe_1=chrome
; 또는 기본 브라우저 활용: start "" "https://..."
```

### 3. 파일 인코딩

- **모든 .ini, .inc 파일: UTF-8 WITHOUT BOM** (BOM이 있으면 @Include 변수 해석 실패)
- Lua 스크립트(.lua): UTF-8 (BOM 선택사항)
- 새 파일 생성 시 반드시 **UTF-8 BOM 없이** 저장
- ⚠️ UTF-8 BOM(EF BB BF)이 .ini 파일에 있으면 @Include로 포함된 파일의 변수가 해석되지 않음

### 4. 성능 최적화 규칙

```
Update=         메인 루프 간격 (ms). 기본 1000, 애니메이션은 50~200
UpdateDivider=  측정 빈도 감소 배율. 하드웨어 Measure는 25+ 권장
DynamicVariables=1  필요한 미터/메져에만 사용 (전역 남발 금지)
```

| 카테고리 | Update | UpdateDivider | 실질 갱신 |
|----------|--------|---------------|-----------|
| 비주얼라이저 | 50 | 1 | 50ms (20fps) |
| 하드웨어 모니터 | 200 | 25 | 5초 |
| 디스크/배터리 | 200 | 25+ | 5초+ |
| 독/설정 | 1000 | — | 1초 |

**스무딩 공식 (EMA):**
```ini
Formula=CalcPrev + (MeasureNew - CalcPrev) * 0.4
; 0.4 = 반응 계수. 클수록 빠른 반응, 작을수록 부드러움
```

### 5. 육각형 지오메트리 규약

프로젝트 전반에 두 가지 크기의 육각형 사용:

**100x100 모듈 (HW/독):**
```
외곽: 50,0 | 93.5,25 | 93.5,75 | 50,100 | 6.5,75 | 6.5,25
내곽: 50,5 | 89.0,27.5 | 89.0,72.5 | 50,95 | 11.0,72.5 | 11.0,27.5
```

**200x200 비주얼라이저:**
```
외곽: 100,0 | 187,50 | 187,150 | 100,200 | 13,150 | 13,50
내곽: 100,8 | 179.7,54 | 179.7,146 | 100,192 | 20.3,146 | 20.3,54
```

허니콤 배치 오프셋: `HexOffsetX=88`, `HexOffsetDX=44`, `HexOffsetDY=76`

### 6. 컬러 시스템

임계값 기반 3단계 색상 변환을 모든 HW 모듈에 일관 적용:
```
정상 (< WarningThreshold):  #ColorText#
경고 (>= WarningThreshold): #ColorWarning#
위험 (>= DangerThreshold):  #ColorDanger#
```
임계값은 `Variables.inc`에서 관리. 모듈 내 직접 숫자 사용 금지.

### 7. 프로그레스 바 (커터칼 세그먼트)

공통 패턴:
```ini
; 배경 트랙 (어두운 점선)
Shape=Path ProgressPath | StrokeWidth 2 | Stroke Color 60,60,60,80 | StrokeDashes 2,1.2 | StrokeDashCap Flat
; 활성 트랙 (동적 대시 길이)
Shape2=Path ProgressPath | StrokeWidth 2 | Stroke Color #ProgressColor# | StrokeDashes [CalcProgress:],500 | StrokeDashCap Flat
```
- 진행률 → StrokeDashes 첫 번째 값으로 변환: `Formula=max(0.1, Value * 1.35)`
- 100x100 기준 계수 1.35, 200x200 기준 계수 1.104

### 8. 변수/설정 관리 구조

```
@Resources/Variables.inc  — 전역 변수 (색상, 크기, 임계값, 폰트 등)
@Resources/Styles.inc     — 공통 Shape/String 스타일
@Resources/AppList.inc    — 독 앱 목록 (사용자 편집용)
각 모듈 [Variables]       — 모듈 로컬 오버라이드만
```

- 새 설정값은 항상 `Variables.inc`에 추가
- Settings.ini의 `InputText` → `!WriteKeyValue` → `Variables.inc` → `!RefreshApp` 체인 유지
- 모듈 간 공유 값은 반드시 전역 변수 사용

### 9. 코드 작성 스타일

- 주석은 한국어, 섹션 구분자 사용: `; --- 제목 ---` 또는 `; ====`
- Meter/Measure 이름: PascalCase (`MeasureCPU`, `CalcGPUSmooth`, `HexBorder`)
- 그룹명: PascalCase (`MediaAll`)
- 변수명: PascalCase (`ColorBorder`, `WarningThreshold`)
- 모든 Shape 미터에 `DynamicVariables=1` (동적 연산 필수)
- 불필요한 `SolidColor`, `Fill Color` 투명 배경: `0,0,0,0` (히트 영역이면 `0,0,0,1`)

### 10. 현재 알려진 호환성 문제 (수정 필요)

1. **HW_GPU**: `nvidia-smi` 사용 → NVIDIA 전용. UsageMonitor 또는 HWiNFO로 교체 필요
2. **HW_DISK**: `Drive=C:` 하드코딩 → `#DiskDrive#` 변수로 교체 필요
3. **Dock**: `chrome` 하드코딩 → 기본 브라우저 또는 변수화 필요
4. **폰트**: `Smooch Sans SemiBold` → 미설치 시 대비 폴백 또는 @Resources/Fonts에 동봉 필요
