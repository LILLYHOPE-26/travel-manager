# 여행 올인원 매니저

시간대별 여행 일정표 생성 / 영수증 인식·가계부·환율변환 / 지역 기반 관광지·맛집 추천 3가지 기능을 제공하는 안드로이드 앱입니다.

## 배포 현황

- 백엔드: Render.com 무료 플랜에 배포됨 → `https://travel-manager-backend-xnhg.onrender.com`
- 앱: `app/lib/config/api_config.dart`가 위 주소를 기본값으로 사용하도록 설정되어 있어, **PC를 켜두지 않아도** 휴대폰에서 바로 동작합니다.
- 무료 플랜 특성상 한동안 요청이 없으면 서버가 슬립 상태가 되어, 첫 요청 응답이 최대 50초 정도 걸릴 수 있습니다 (이후 요청은 빠름).

## 구조

```
자동화/
├── backend/   Node.js(Express) 백엔드 - Geoapify(지오코딩+장소검색) / 로컬 OCR / 무료 환율 API 프록시
└── app/       Flutter 안드로이드 앱
```

## 사용하는 데이터 소스

| 기능 | 데이터 소스 | 비고 |
|---|---|---|
| 일정표 생성 / 관광지·맛집 추천 | Geoapify (지오코딩 + Places API) | 무료 가입만 필요(카드 불필요), 하루 3,000회 무료. 평점/리뷰수는 제공되지 않아 거리·카테고리 다양성 기준으로 선정 |
| 영수증 인식 | Tesseract.js (로컬 OCR, 오프라인) | 키 불필요. 유료 비전 API보다 인식률이 낮을 수 있어, 앱에서 인식 결과를 직접 수정할 수 있습니다 |
| 환율 조회 | frankfurter.app | 키 불필요. 통화쌍이 지원되지 않으면 앱에서 직접 입력하는 화면이 나타납니다 (임의 추정 금지) |

> 처음에는 OpenStreetMap(Nominatim/Overpass)만으로 구현했으나, Render 등 공용 클라우드의 공유 IP가 해당 공용 서버에서 자주 차단되어 Geoapify(무료 API 키 방식)로 교체했습니다.

## 1. 백엔드 API 키 설정

1. [geoapify.com](https://geoapify.com) 무료 가입 (카드 등록 불필요) → API 키 발급
2. 로컬 실행 시: `backend/.env.example`을 `backend/.env`로 복사 후 `GEOAPIFY_API_KEY`에 키 입력
3. Render 배포본에도 동일한 키가 필요합니다 — Render 대시보드 → 서비스 선택 → **Environment** 탭 → `GEOAPIFY_API_KEY` 값 입력 후 저장 (자동 재배포됨)

## 2. 백엔드 로컬 실행

```bash
cd backend
npm install
npm run dev             # http://localhost:3000 에서 실행
```

### 테스트 (curl)

```bash
curl http://localhost:3000/health

curl -X POST http://localhost:3000/api/itinerary \
  -H "Content-Type: application/json" \
  -d '{"destination":"일본","city":"오사카","totalDays":2,"startDate":"2026-10-01","endDate":"2026-10-02","styles":["관광","맛집"],"transport":"대중교통"}'

curl -X POST http://localhost:3000/api/receipt -F "image=@receipt.jpg"

curl "http://localhost:3000/api/exchange-rate?date=2024-01-15&currency=USD&amount=42.5"

curl "http://localhost:3000/api/places?region=강남"
```

> Windows에서 한글이 포함된 요청을 curl로 테스트할 때는, 명령줄에 한글을 직접 입력하면 콘솔 인코딩 때문에 깨질 수 있습니다. 한글이 포함된 요청은 UTF-8로 저장한 JSON 파일을 `--data-binary @파일명`으로 전달하는 것이 안전합니다.

## 3. Flutter 앱 빌드/실행

1. [flutter.dev](https://docs.flutter.dev/get-started/install/windows)에서 Windows용 Flutter SDK 설치 후 PATH 등록 (Android SDK/Java가 이미 있다면 `flutter doctor`가 대부분 통과함)
2. `app` 폴더에서 의존성 설치:
   ```bash
   cd app
   flutter pub get
   ```
3. `lib/config/api_config.dart`는 기본적으로 Render 배포 주소를 가리킵니다. 로컬 백엔드로 테스트하려면:
   - 안드로이드 에뮬레이터: `http://10.0.2.2:3000`
   - USB로 연결한 실기기: `adb reverse tcp:3000 tcp:3000` 실행 후 `http://localhost:3000`
   - Wi-Fi로 연결한 실기기(같은 공유기): `http://<PC의 로컬 IP>:3000` (Windows에서 `ipconfig`로 확인)
4. 에뮬레이터 또는 USB로 연결한 실기기에서 실행:
   ```bash
   flutter run
   ```
   또는 디버그 APK만 빌드해서 수동 설치:
   ```bash
   flutter build apk --debug
   adb install -r build\app\outputs\flutter-apk\app-debug.apk
   ```
5. 앱의 3개 탭(일정표/가계부/추천)을 순서대로 테스트

## 4. 기능 요약

| 기능 | 화면 | 백엔드 엔드포인트 |
|---|---|---|
| 시간대별 일정표 생성 | 일정표 탭 | `POST /api/itinerary` |
| 영수증 인식 → 가계부 | 가계부 탭 | `POST /api/receipt` (OCR) + `GET /api/exchange-rate` (환율) |
| 지역 검색 → 관광지/맛집 추천 | 추천 탭 | `GET /api/places` |

각 기능은 정보 부족 시 임의로 추측하지 않고 부족한 항목을 명시하며, 조회 불가한 데이터는 "확인 불가"로 표시합니다. 무료 데이터 특성상 정확도가 유료 API보다 낮을 수 있는 부분(영수증 인식, 맛집 평점 등)은 화면에 그 사실을 표시하고 사용자가 직접 확인/수정할 수 있게 설계했습니다.

## 5. 배포/저장소

- GitHub: https://github.com/LILLYHOPE-26/travel-manager
- Render Blueprint(`render.yaml`)로 배포되어 있어, `main` 브랜치에 push하면 자동으로 재배포됩니다.
