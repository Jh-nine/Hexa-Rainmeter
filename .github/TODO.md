# HEXA Rainmeter — 진행 예정 작업 및 개선 계획

## 해결 완료

- [x] HW_GPU: `nvidia-smi` → `UsageMonitor` 범용 방식으로 교체
- [x] HW_DISK: `Drive=C:` 하드코딩 → `#DiskDrive#` 변수 사용
- [x] Dock: `chrome` 하드코딩 → AppList.inc 예외 허용 (PWA app-id 방식)
- [x] 폰트: `Smooch Sans` 전체 웨이트 `@Resources/Fonts/`에 동봉
- [x] UTF-8 BOM 제거: 모든 .ini/.inc 파일 BOM-free 확인
- [x] Visualizer: StrokeDashes 둘레 길이 기반 음량 표현
- [x] Visualizer: 21밴드 FFT (3밴드 그룹핑 × 7레이어)
- [x] Visualizer: 레이어별 시작점 교차 배치 (홀수=위, 짝수=아래)
- [x] Dock: DockSpacing 96 (1px 마진)

## 개선 예정

- [ ] Settings.ini: 비주얼라이저 감도/색상 등 실시간 설정 UI 추가
- [ ] 다크/라이트 테마 전환 기능
- [ ] 네트워크 모듈 (HW_NET) 추가
