# 🌿 배당나무 (Baedang-Namu)

한국 주식 배당금 자동 계산 & AI 예측 포트폴리오 앱

## ✨ 주요 기능

### 1. 목표 기반 포트폴리오 추천
- 사용자가 "월 200만원 받기" 같은 목표를 설정하면, 자동으로 필요 투자금 계산
- 투자 성향(안정형/균형형/성장형/고배당형) 기반 종목 추천
- 섹터별 필터링 (금융/통신/에너지/리츠/소비재 등)

### 2. 자체 배당 예측 엔진 (Forecast Engine)
**E[D] = D₀ × (1 + g_blend) × C_stability × R_payout**

| 변수 | 의미 | 계산 |
|------|------|------|
| `D₀` | 최근 배당금 | 가장 최근 연도 실제 배당 |
| `g_blend` | 가중 성장률 | 최근 데이터 가중평균(70%) + CAGR(30%) |
| `C_stability` | 안정성 보정 | 변동계수(CV) 기반, 0.85~1.0 |
| `R_payout` | 배당성향 회귀 | ROE 기반 ±10% / PBR<1 보정 |

**특징:**
- 최근 3년 추세 가중치 부여 (모멘텀 반영)
- 변동성이 클수록 보수적 추정 (코로나 같은 outlier 자동 완화)
- 95% 신뢰구간 제공 (시간 경과에 따라 폭 확장)
- 추세 분류: 상승 / 안정 / 하락

### 3. 종목별 상세 분석
- 5년 배당 히스토리 + 향후 3년 예측 차트
- 단독 종목으로 목표 달성 가능성 % 계산
- 예측 공식 분해 (각 변수 값을 시각화)

### 4. 포트폴리오 추적
- 보유 종목 자산/배당 현황
- 섹터 분포 파이차트
- 미래 예측 (현재 → 3년 후)

---

## 🚀 시작하기 (맥북)

### 1. Flutter 설치
```bash
brew install --cask flutter
flutter doctor
```

### 2. 프로젝트 생성 & 코드 복사
```bash
flutter create dividend_app
cd dividend_app

# 이 zip의 lib/ 폴더와 pubspec.yaml을 복사
```

### 3. 의존성 설치
```bash
flutter pub get
```

### 4. 실행
```bash
# iOS 시뮬레이터
flutter run

# 안드로이드 에뮬레이터
flutter emulators --launch <emulator_id>
flutter run

# 웹
flutter run -d chrome
```

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── theme/
│   └── app_theme.dart                 # 컬러/타이포 시스템
├── models/
│   └── stock_model.dart               # 데이터 모델 (StockModel, UserGoal 등)
├── services/
│   ├── stock_data_service.dart        # 한국 배당주 데이터 (15개 종목)
│   └── forecast_engine.dart           # ⭐ 자체 예측 엔진
├── providers/
│   └── app_providers.dart             # Riverpod 상태관리
├── widgets/
│   └── common_widgets.dart            # 재사용 위젯
└── screens/
    ├── main_scaffold.dart             # 하단 네비
    ├── home_screen.dart               # 홈 (목표/추천/예측)
    ├── stock_detail_screen.dart       # 종목 상세 + 예측 차트
    ├── goal_setup_screen.dart         # 목표 설정
    └── portfolio_screen.dart          # 내 포트폴리오
```

---

## 📊 데이터 소스

현재 코드에는 **15개 주요 한국 배당주**의 실제 배당 데이터(2020~2024)가 하드코딩 되어 있습니다:
- **금융**: KB금융, 신한지주, 하나금융지주, 우리금융지주
- **통신**: KT, SK텔레콤, LG유플러스
- **에너지**: 한국전력, 한국가스공사
- **리츠**: 맥쿼리인프라, SK리츠, KODEX 리츠
- **소비재**: 하이트진로, 오리온

### 실시간 데이터 연동 (다음 단계)
프로덕션 환경에서는 다음 API 중 선택:
1. **한국투자증권 OpenAPI** (가장 신뢰도 높음, 실시간) - https://apiportal.koreainvestment.com
2. **키움증권 OpenAPI** (Windows 전용 단점)
3. **DART API** (배당공시 무료) - https://opendart.fss.or.kr
4. **네이버/다음 금융 크롤링** (비공식, 주의 필요)

`lib/services/stock_data_service.dart`의 `allStocks` 리스트를 API 호출 결과로 대체하면 됩니다.

---

## 🎨 디자인 시스템

- **컬러**: 딥 포레스트 그린(#1A3A2A) + 민트 액센트(#3DD68C)
    - 20-40대가 선호하는 차분하고 모던한 톤
- **폰트**: Noto Sans KR (구글폰트, 자동 다운로드)
- **모서리**: 16-20px 라운드 (부드럽고 현대적)
- **애니메이션**: flutter_animate 패키지 (페이드+슬라이드)

---

## 🔮 향후 확장 아이디어

1. **백테스팅**: 5년 전 추천 받았다면 지금 어땠을지 시뮬레이션
2. **세금 계산**: 배당소득세 15.4% 자동 차감
3. **알림**: 배당락일/지급일 푸시 알림
4. **AI 챗봇**: Claude API 연동해서 "내 포트폴리오 어떻게 개선할까?" 질문 가능
5. **DRIP 시뮬레이션**: 배당 재투자 시 복리 효과 시각화

---

## ⚠️ 면책 조항

이 앱은 **참고용 정보**이며 투자 권유가 아닙니다. 모든 투자 결정은 본인 책임입니다.
배당금은 기업 실적에 따라 변동되며 예측치는 과거 데이터 기반 추정이므로 실제와 다를 수 있습니다.
