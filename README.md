# 여행 올인원 매니저

시간대별 여행 일정표 생성 / 영수증 인식·가계부·환율변환 / 지역 기반 관광지·맛집 추천 3가지 기능을 제공하는 안드로이드 앱입니다.

**API 키 발급이나 결제수단 등록 없이, 완전 무료 스택으로 동작합니다.**

## 구조

```
자동화/
├── backend/   Node.js(Express) 백엔드 - OpenStreetMap / 로컬 OCR / 무료 환율 API 프록시
└── app/       Flutter 안드로이드 앱
```

## 사용하는 무료 데이터 소스 (키/가입/결제 불필요)

| 기능 | 데이터 소스 | 비고 |
|---|---|---|
| 일정표 생성 / 관광지·맛집 추천 | OpenStreetMap (Nominatim 지오코딩 + Overpass API) | 키 불필요. 평점/리뷰수 데이터는 없어 거리·카테고리 다양성 기준으로 선정 |
| 영수증 인식 | Tesseract.js (로컬 OCR, 오프라인) | 키 불필요. 유료 비전 API보다 인식률이 낮을 수 있어, 앱에서 인식 결과를 직접 수정할 수 있습니다 |
| 환율 조회 | frankfurter.app | 키 불필요. 통화쌍이 지원되지 않으면 앱에서 직접 입력하는 화면이 나타납니다 (임의 추정 금지) |

> OpenStreetMap의 Overpass 공용 서버는 짧은 시간에 요청이 몰리면 일시적으로 느려질 수 있습니다. 백엔드에 재시도/미러 전환 로직이 포함되어 있지만, 그래도 실패하면 "확인 불가"로 응답합니다.

## 1. 백엔드 실행

```bash
cd backend
npm install
npm run dev             # http://localhost:3000 에서 실행 (.env는 PORT만 있으면 충분)
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

## 2. Flutter 앱 실행

1. [flutter.dev](https://docs.flutter.dev/get-started/install/windows)에서 Windows용 Flutter SDK 설치 후 PATH 등록
2. `flutter doctor` 실행 → Android 툴체인 인식 확인
3. `app` 폴더로 이동 후, 플랫폼(android/ios 등) 폴더가 없다면 생성:
   ```bash
   cd app
   flutter create .
   ```
   (이미 있는 `pubspec.yaml`/`lib/`는 보존되고 android/ios 등 누락된 폴더만 추가되는 것이 일반적이나, 실행 후 `pubspec.yaml`과 `lib/`가 바뀌지 않았는지 확인하세요.)
4. 의존성 설치:
   ```bash
   flutter pub get
   ```
5. `lib/config/api_config.dart`에서 백엔드 주소 확인/수정:
   - 에뮬레이터: `http://10.0.2.2:3000` (기본값, 변경 불필요)
   - 실기기: PC와 같은 Wi-Fi에 연결 후, `ipconfig`로 확인한 PC의 로컬 IP로 변경 (예: `http://192.168.0.10:3000`)
6. 에뮬레이터 또는 USB로 연결한 실기기에서 실행:
   ```bash
   flutter run
   ```
7. 백엔드가 실행 중인 상태에서 앱의 3개 탭(일정표/가계부/추천)을 순서대로 테스트

## 3. 기능 요약

| 기능 | 화면 | 백엔드 엔드포인트 |
|---|---|---|
| 시간대별 일정표 생성 | 일정표 탭 | `POST /api/itinerary` |
| 영수증 인식 → 가계부 | 가계부 탭 | `POST /api/receipt` (OCR) + `GET /api/exchange-rate` (환율) |
| 지역 검색 → 관광지/맛집 추천 | 추천 탭 | `GET /api/places` |

각 기능은 정보 부족 시 임의로 추측하지 않고 부족한 항목을 명시하며, 조회 불가한 데이터는 "확인 불가"로 표시합니다. 무료 오픈데이터 특성상 정확도가 유료 API보다 낮을 수 있는 부분(영수증 인식, 맛집 평점 등)은 화면에 그 사실을 표시하고 사용자가 직접 확인/수정할 수 있게 설계했습니다.
