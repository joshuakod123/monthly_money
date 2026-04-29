# 🌿 배당나무 v2 — 실시간 API 연동 마이그레이션

v1의 하드코딩 데이터(15개 종목)를 **3개의 공식 API 조합**으로 교체했습니다.

## 📦 이번에 교체되는 파일들

| 파일 | 변경 |
|---|---|
| `lib/services/api/api_config.dart` | 🆕 신규 — API 키와 엔드포인트 |
| `lib/services/api/opendart_client.dart` | 🆕 신규 — 배당 historical |
| `lib/services/api/kis_client.dart` | 🆕 신규 — 실시간 시세 |
| `lib/services/api/krx_client.dart` | 🆕 신규 — 종목 마스터 |
| `lib/services/stock_data_service.dart` | ♻️ 전면 교체 |
| `lib/providers/app_providers.dart` | ♻️ async 대응 |
| `lib/screens/home_screen.dart` | ♻️ AsyncValue + shimmer |
| `lib/main.dart` | ♻️ 서비스 초기화 추가 |
| `pubspec.yaml` | ♻️ 의존성 추가 |

**그대로 유지되는 파일** (수정 불필요):
- `lib/models/stock_model.dart`
- `lib/services/forecast_engine.dart` ⭐ 예측 공식 그대로 유지
- `lib/screens/goal_setup_screen.dart`
- `lib/screens/portfolio_screen.dart` (필요시 async 처리만 추가)
- `lib/screens/stock_detail_screen.dart`
- `lib/widgets/common_widgets.dart`
- `lib/theme/app_theme.dart`
- `lib/screens/main_scaffold.dart`

---

## 🌐 API 조합 아키텍처

```
┌──────────────────────┐  ┌──────────────────┐  ┌──────────────┐
│  OpenDART (금감원)    │  │   KIS Open API   │  │     KRX      │
│  배당 historical 5년치 │  │ 실시간 현재가/PER │  │  종목 마스터  │
│  ROE/EPS/배당성향     │  │  PBR/시가총액     │  │   섹터분류    │
└──────────┬───────────┘  └────────┬─────────┘  └──────┬───────┘
           │                       │                    │
           └───────────┬───────────┴────────────────────┘
                       ▼
              StockDataService v2
              (Hive 디스크 캐시 + 병렬 호출)
                       ▼
                  StockModel
                       ▼
              ForecastEngine (공식 그대로)
```

### 왜 이 조합인가?

- **OpenDART**: 금감원 공식, 무료, 사업보고서 기반이라 가장 정확한 historical
- **KIS**: 실시간 시세 + PER/PBR 등 시장 데이터 (개별 증권사 중 가장 모던한 REST API)
- **KRX**: 전체 상장사 마스터 (KOSPI 200 이외 종목까지 확장 시 사용)

### 토스증권/카카오페이증권은?

조사 결과, **공개 OpenAPI를 제공하지 않습니다.** 두 곳 모두 자체 앱 전용이고 외부 개발자용 API 포털이 없어요. (토스페이먼츠/토스플레이스 API는 결제·POS 도메인이라 주식과 무관)

증권 API를 추가로 조합하고 싶다면 **LS증권**(구 이베스트) 또는 **NH투자증권**의 OpenAPI를 추가하는 걸 추천합니다. 둘 다 KIS와 비슷한 REST 방식이에요.

---

## 🔑 API 키 발급 가이드

### 1. OpenDART (필수, 5분 소요)
1. https://opendart.fss.or.kr 접속
2. 회원가입 → 인증키 신청/관리 → 인증키 신청
3. 약관 동의 → **즉시 발급** (40자 영문/숫자)
4. `lib/services/api/api_config.dart` 의 `openDartApiKey` 에 입력

**한도**: 일일 10,000회 (개인 기준)

### 2. KIS 한국투자증권 (필수)
1. https://apiportal.koreainvestment.com 접속
2. 회원가입 (한국투자증권 계좌 필요 — 비대면 개설 가능)
3. **앱 등록** → AppKey(36자) + AppSecret(180자) 발급
4. `api_config.dart` 의 `kisAppKey`, `kisAppSecret` 에 입력
5. 처음에는 `useMockTrading = true` 로 모의투자로 테스트

**한도**: 초당 20건 (실전), 초당 2건 (모의)

### 3. KRX (선택)
별도 키 불필요. `krx_client.dart`는 OTP 기반으로 동작.
다만 상업적 사용 시 KRX와 별도 라이선스 협의가 필요해요.

---

## ⚙️ 설치 & 실행

```bash
cd dividend_app
# pubspec.yaml 교체 후
flutter pub get

# API 키 입력 (api_config.dart)
# ⚠️ 절대 git commit 하지 마세요!

flutter run -d chrome   # 웹으로 빠르게 테스트
flutter run             # iOS 시뮬레이터
```

`.gitignore` 에 추가 권장:
```
lib/services/api/api_config.dart
.env
```

---

## 🚀 동작 흐름

### 첫 실행
1. `main()` → `StockDataService.initialize()` 호출
2. Hive 캐시 박스 오픈
3. OpenDART에서 `corpCode.xml`(전체 상장사 → 고유번호 매핑) 다운로드 (~1MB, 5초)
4. 홈 화면 진입

### 홈 화면 진입 시 (첫 로드)
- `defaultDividendStocks` 20개 종목을 3개씩 청크로 병렬 호출
- 각 종목당:
  - KIS 현재가 1회 + KIS 종목정보 1회
  - OpenDART 배당 5년치 (병렬, 5회)
  - OpenDART 재무제표 1회
- 총 약 20초~30초 소요 (Shimmer 로딩 표시)

### 두 번째 이후
- 디스크 캐시(Hive) → **즉시 표시**
- 시세만 5분마다 자동 갱신
- Pull-to-refresh로 강제 갱신

---

## 🔒 보안 (프로덕션 배포 전 필수)

현재 `api_config.dart`에 키를 직접 박아두는 건 **개발용**입니다. 실제 출시할 때는:

```dart
// flutter_secure_storage 사용
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
final kisKey = await storage.read(key: 'kis_app_key');
```

또는 더 안전하게는 **백엔드 프록시 서버**를 두고 거기서 키를 보관하는 게 정석이에요. 모바일 앱 패키지는 디컴파일이 가능해서 어떤 방식으로 박아넣어도 추출 가능합니다.

---

## 🐛 트러블슈팅

### "Access Token 발급 실패"
→ `useMockTrading = true` 인데 실전 키를 쓰고 있거나 그 반대. 모의/실전 키는 다릅니다.

### "OpenDART status=020"
→ 일일 호출 한도 초과. 다음날 자동 리셋됩니다.

### "현재가 = 0" 나옴
→ 장 시작 전(09:00 이전) 또는 장 마감 후(15:30 이후) 일부 필드가 비어있을 수 있어요. 전일 종가 사용 권장.

### KRX EUC-KR 깨짐
→ `pubspec.yaml`에 `charset_converter` 추가 필요. iOS 시뮬레이터에서는 정상, 일부 안드로이드 디바이스에서 EUC-KR 미지원 가능.

---

## 📈 다음 확장 제안

1. **백엔드 프록시 도입** — 키 보안 + 캐시 공유
2. **DART 분기보고서로 배당주기 자동 추론** (현재는 일부 hardcode)
3. **실시간 WebSocket 시세** (KIS 지원, 호가/체결 실시간 푸시)
4. **세금 계산** 배당소득세 15.4% 자동 차감
5. **알림** 배당락일/지급일 푸시 (DART 공시 모니터링)

---

## ⚠️ 면책

- 이 앱은 **참고용 정보**이며 투자 권유가 아닙니다.
- API 응답은 각 기관의 정책에 따라 변경될 수 있어요.
- KRX 데이터를 상업적으로 사용하려면 별도 라이선스가 필요합니다.
