# 🦯 WhiteCane

> 시각장애인을 위한 캠퍼스 보행 안내 앱

이화여자대학교 캠퍼스에서 목적지를 검색하고, 실외 경로 안내 → 실내 경로 안내까지 통합 제공합니다.

---

## 📱 주요 기능

| 기능 | 설명 |
|------|------|
| 🔍 장소 검색 | 건물 이름으로 캠퍼스 내 장소 검색 |
| 📍 현재 위치 추적 | GPS 기반 실시간 위치 추적 및 지도 팔로우 |
| 🚶 실외 경로 안내 | 도보(OSRM) / 자동차(Kakao Mobility) 경로 선택 |
| 🧭 실시간 내비게이션 | 진행 방향 카메라 회전 + 남은 거리/시간 HUD |
| 🏢 실내 전환 안내 | 실외 목적지 도착 시 실내 경로 안내로 자동 전환 |
| 🗺 실내 경로 안내 | 건물 내부 경로 안내 (알고리즘 연동 예정) |

---

## 🛠 기술 스택

| 영역 | 사용 기술 |
|------|----------|
| 모바일 앱 | Flutter (Android / iOS) |
| 지도 | Naver Maps SDK |
| 장소 검색 | Naver Local Search API |
| 도보 경로 | OSRM (router.project-osrm.org) |
| 자동차 경로 | Kakao Mobility Directions API |
| 데이터베이스 | Firebase Firestore |
| 백엔드 | Rust + Actix-web |
| 상태 관리 | GetX |

---

## 🚀 시작하기

### 1단계 — 저장소 클론

```bash
git clone https://github.com/paintedblue/WhiteCane_ewha.git
cd WhiteCane_ewha
```

### 2단계 — 환경변수 파일 생성

```bash
cp frontend/whitecane/.env.example frontend/whitecane/.env
```

`.env` 파일을 열고 아래 항목을 채워주세요:

```env
SERVER_URL=http://10.0.2.2:8000/

# 네이버 지도 SDK (Mobile SDK 전용)
NAVER_MAP_CLIENT_ID=발급받은_ID
NAVER_CLIENT_SECRET=발급받은_Secret

# 네이버 Directions (현재 미사용 — Kakao로 대체됨)
NAVER_DIRECTIONS_CLIENT_ID=발급받은_ID
NAVER_DIRECTIONS_CLIENT_SECRET=발급받은_Secret

# 네이버 장소 검색
NAVER_SEARCH_CLIENT_ID=발급받은_ID
NAVER_SEARCH_CLIENT_SECRET=발급받은_Secret

# 카카오 REST API (경로 안내용)
KAKAO_REST_API_KEY=발급받은_Key
```

> API 키 발급 방법은 [아래 섹션](#-api-키-발급-방법)을 참고하세요.

### 3단계 — 패키지 설치 및 실행

```bash
cd frontend/whitecane
flutter pub get
flutter run
```

---

## 🔑 API 키 발급 방법

### Naver Maps SDK
> 사이트: [console.ncloud.com](https://console.ncloud.com)

1. NCP 콘솔 로그인
2. **AI·Application Service → Maps → Application** 이동
3. 애플리케이션 등록, 아래 서비스 활성화:
   - `Dynamic Map` (지도 표시)
4. **인증 정보** 탭에서 `Client ID` 복사 → `AndroidManifest.xml`에 입력

> **주의:** Naver Directions REST API는 별도 IAM 인증이 필요합니다. 현재 경로 안내는 OSRM(도보) / Kakao Mobility(자동차)를 사용합니다.

### Kakao REST API (경로 안내)
> 사이트: [developers.kakao.com](https://developers.kakao.com)

1. 카카오 개발자 콘솔 로그인
2. **내 애플리케이션 → 애플리케이션 추가**
3. **앱 키** 탭에서 `REST API 키` 복사

### Naver 장소 검색 API
> 사이트: [developers.naver.com](https://developers.naver.com) ← NCP와 **다른 사이트**

1. 네이버 개발자 센터 로그인
2. **Application → 애플리케이션 등록**
3. 사용 API에서 **검색** 체크
4. Android 패키지명 입력: `com.example.whitecane`
5. `Client ID` / `Client Secret` 복사

### Firebase
> 사이트: [console.firebase.google.com](https://console.firebase.google.com)

```bash
# Firebase CLI 설치
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# PATH 설정 (최초 1회)
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc

# 로그인 및 프로젝트 연결
firebase login
cd frontend/whitecane
flutterfire configure
```

---

## 📂 프로젝트 구조

```
WhiteCane_ewha/
├── backend/
│   └── rust_server/          # Rust 백엔드 서버
│
└── frontend/
    └── whitecane/            # Flutter 앱
        └── lib/
            ├── main.dart
            ├── di/                        # 의존성 주입
            ├── domain/
            │   ├── model/                 # Place, IndoorRoom 모델
            │   └── usecase/
            ├── data/
            │   ├── local/                 # MockBuildingData (실내 목업)
            │   └── remote/
            │       ├── api/               # NaverDirectionsApi, NavigationApi
            │       └── dto/               # DirectionsDto, NavigationDto
            └── presentation/
                ├── map/                   # 지도 메인 화면
                ├── indoor/                # 실내 경로 화면
                │   ├── indoor_map_page.dart
                │   └── indoor_navigation_sheet.dart
                └── common/
                    └── map_component.dart # 지도 + 내비게이션 핵심 컴포넌트
```

---

## 🗺 화면 흐름

```
앱 실행
  └─ 메인 지도 화면 (현재 위치 자동 추적)
       └─ 검색창 클릭 → 장소 검색
             └─ 결과 클릭 → 지도에 마커 + 장소 상세 바텀시트
                   ├─ 이동 수단 선택 (도보 / 자동차)
                   ├─ 실내 목적지 추가 (선택)
                   └─ [경로 안내하기] 버튼
                         └─ 경로 지도에 표시 + 내비게이션 시작
                               ├─ HUD: "{목적지}까지 N km / 약 N분 남음"
                               ├─ 카메라: 진행 방향 자동 회전 + 45도 틸트
                               ├─ 이동 중: 지나온 경로 제거, 남은 경로만 표시
                               └─ 목적지 25m 이내 도착
                                     ├─ 실내 데이터 있음 → 실내 전환 시트
                                     │     └─ [실내 안내 시작] → 실내 경로 화면
                                     └─ 실내 데이터 없음 → 도착 알림
```

---

## 🧭 내비게이션 상세 동작

### 경로 API

| 이동 수단 | API | 비고 |
|-----------|-----|------|
| 도보 | OSRM (`router.project-osrm.org`) | 무료, OpenStreetMap 기반 |
| 자동차 | Kakao Mobility Directions | REST API 키 필요 |

### 카메라 동작

| 상태 | 줌 | 방향 | 틸트 |
|------|----|------|------|
| 일반 지도 | 자유 | 정북 | 0° |
| 내비게이션 중 | 18 | 진행 방향 | 45° |
| 안내 종료 후 | 16 | 정북 | 0° |

### 실내 전환 조건

현재 실내 데이터가 등록된 건물: **ECC (이화캠퍼스복합단지)**

실외 목적지 도착(25m 이내) 시 → **실내 전환 시트** 자동 표시
- 실내 목적지를 미리 선택한 경우: 해당 목적지로 바로 실내 안내 진행
- 미선택 경우: 실내 목적지 선택 화면으로 이동

---

## 🏢 실내 경로 알고리즘 팀을 위한 가이드

### 현재 상태

앱에서 사용자가 건물을 선택하고 실내 안내를 시작하면:
1. 출발지 X/Y, 도착지 X/Y 좌표를 `IndoorMapPage`로 전달
2. 현재는 직선 점선으로 경로 미리보기만 표시되는 상태

### 연동 방법

**관련 파일:**
- 입력 UI: `presentation/indoor/indoor_navigation_sheet.dart`
- 경로 표시: `presentation/indoor/indoor_map_page.dart`
- 실내 목업 데이터: `data/local/mock_building_data.dart`

**`IndoorMapPage`가 현재 받는 파라미터:**

```dart
IndoorMapPage(
  buildingName: "ECC",
  startX: 0.0,   // 건물 입구 (기본값)
  startY: 0.0,
  endX: 10.0,    // 목적지 X 좌표
  endY: 8.0,     // 목적지 Y 좌표
)
```

**알고리즘 연동 후 추가 권장 파라미터:**

```dart
IndoorMapPage(
  buildingName: "ECC",
  startX: 0.0,
  startY: 0.0,
  endX: 10.0,
  endY: 8.0,
  routePath: [   // 알고리즘이 계산한 경유 좌표 목록
    Point(0.0, 0.0),
    Point(4.0, 0.0),
    Point(4.0, 5.0),
    Point(10.0, 8.0),
  ],
)
```

### 좌표계 정의 (팀 간 합의 필요)

| 항목 | 결정 필요 내용 |
|------|--------------|
| 좌표 단위 | 미터? 픽셀? 격자 번호? |
| 기준점 (원점) | 건물 어느 지점이 (0, 0)인가? |
| Y축 방향 | 위로 갈수록 증가? 감소? |
| 층 정보 | `floor` 파라미터로 전달 예정 |

---

## 🔥 Firebase Firestore 구조

```
buildings/
  └── {문서ID}
        ├── name        : "ECC"
        ├── address     : "서울특별시 서대문구 이화여대길 52"
        ├── latitude    : 37.5620
        ├── longitude   : 126.9469
        ├── category    : "대학 건물"
        └── entrances   : [
              {
                nodeId      : "ecc_entrance_1",
                description : "정문 경사로",
                latitude    : 37.5621,
                longitude   : 126.9470
              }
            ]
```

---

## 📱 에뮬레이터에서 테스트하기

에뮬레이터는 GPS가 없어서 위치를 직접 설정해야 합니다.

1. Android Studio 에뮬레이터 실행
2. 오른쪽 점 세개 메뉴 **(···)** 클릭
3. **Location** 탭 선택
4. 아래 좌표 입력 후 **Set Location** 클릭

```
Latitude  : 37.5622
Longitude : 126.9462
```

> **ECC 도착 시뮬레이션:** 앱 우측 상단 주황색 **ECC** 버튼을 누르면 현재 위치가 ECC로 강제 이동됩니다. (테스트 전용 버튼)

---

## 📋 개발 현황

- [x] 네이버 지도 SDK 연동
- [x] 현재 위치 실시간 추적
- [x] 장소 검색 (Naver Local Search API)
- [x] 실외 도보 경로 안내 (OSRM)
- [x] 실외 자동차 경로 안내 (Kakao Mobility)
- [x] 이동 수단 선택 UI (도보 / 자동차)
- [x] 실시간 내비게이션 HUD (남은 거리 / 시간 / 목적지 표시)
- [x] 진행 방향 카메라 자동 회전 (bearing + tilt)
- [x] 실내 목적지 사전 선택 기능
- [x] 실외 → 실내 자동 전환 UI
- [x] Firebase 연동 (Firestore, Auth, Realtime DB)
- [x] 실내 경로 UI (미리보기)
- [ ] 실내 경로 알고리즘 연동
- [ ] 로그인 / 회원가입
- [ ] 즐겨찾기 저장
- [ ] 음성 안내 (TTS)
- [ ] 경사로 데이터 수집 및 등록

---

## ⚠️ 주의사항

- `.env` 파일은 **절대 커밋하지 마세요.** API 키가 외부에 노출됩니다.
- Firebase Firestore는 현재 **테스트 모드**로 설정되어 있습니다. 배포 전 보안 규칙을 반드시 강화하세요.
- Android 에뮬레이터에서 로컬 백엔드 접속 시 `localhost` 대신 `10.0.2.2`를 사용합니다.
- 학교 WiFi 등 일부 네트워크에서는 OSRM / Kakao API 도메인이 차단될 수 있습니다. 모바일 데이터로 테스트하세요.
