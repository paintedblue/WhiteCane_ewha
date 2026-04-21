# WhiteCane

시각장애인을 위한 보행 보조 앱입니다. 이화여자대학교 캠퍼스를 중심으로 장소 검색, 실외 보행자 경로 안내, 실내 경로 안내 기능을 제공합니다.

---

## 목차

1. [기술 스택](#기술-스택)
2. [프로젝트 구조](#프로젝트-구조)
3. [아키텍처](#아키텍처)
4. [구현된 기능](#구현된-기능)
5. [환경 설정](#환경-설정)
6. [API 키 발급 방법](#api-키-발급-방법)
7. [실행 방법](#실행-방법)
8. [Firebase 설정](#firebase-설정)
9. [향후 구현 예정](#향후-구현-예정)

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 모바일 앱 | Flutter (Android / iOS) |
| 지도 표시 | flutter_naver_map (Naver Maps SDK) |
| 장소 검색 | Naver Local Search API (developers.naver.com) |
| 실외 경로 안내 | Naver Directions 15 Walking API (NCP) |
| 위치 추적 | geolocator |
| 백엔드 | Rust + Actix-web |
| 데이터베이스 | Firebase Firestore |
| 인증 | Firebase Auth (예정) |
| 상태 관리 | GetX |
| DI | get_it |
| HTTP 클라이언트 | Dio |

---

## 프로젝트 구조

```
WhiteCane_ewha/
├── backend/
│   └── rust_server/                    # Rust Actix-web 백엔드 서버
│       ├── src/
│       │   ├── main.rs
│       │   ├── handlers/
│       │   └── routes/
│       ├── Cargo.toml
│       └── .env                        # 환경변수 (gitignore)
│
└── frontend/
    └── whitecane/                      # Flutter 앱
        ├── lib/
        │   ├── main.dart               # 앱 진입점 (Firebase, NaverMap 초기화)
        │   ├── firebase_options.dart   # FlutterFire 자동 생성 설정
        │   ├── di/
        │   │   └── service_locator.dart        # get_it DI 설정
        │   ├── navigation/
        │   │   └── main_navigation_page.dart   # 하단 탭 네비게이션
        │   ├── domain/
        │   │   ├── model/
        │   │   │   ├── place.dart              # Place 도메인 모델 (진입로 포함)
        │   │   │   └── entrance.dart           # Entrance 모델 (경사로/진입로)
        │   │   ├── repository/
        │   │   │   └── place_repository.dart   # 장소 검색 Repository
        │   │   └── usecase/
        │   │       └── search_places_usecase.dart
        │   ├── data/
        │   │   ├── firestore/
        │   │   │   └── building_firestore_source.dart  # Firestore 건물 데이터
        │   │   └── remote/
        │   │       ├── api/
        │   │       │   ├── naver_local_search_api.dart  # 네이버 장소 검색
        │   │       │   ├── naver_directions_api.dart    # 보행자 경로 API
        │   │       │   └── navigation_api.dart          # 백엔드 경로 API
        │   │       └── dto/
        │   │           ├── navigation_dto.dart
        │   │           └── directions_dto.dart
        │   └── presentation/
        │       ├── theme/
        │       │   └── color.dart
        │       ├── common/
        │       │   ├── map_component.dart       # 네이버 지도 위젯 (핵심)
        │       │   ├── route_finder_modal.dart  # 실외 경로 안내 모달
        │       │   ├── custom_search_bar.dart
        │       │   └── place_item.dart          # 검색 결과 리스트 아이템
        │       ├── map/
        │       │   ├── map_page.dart            # 메인 지도 페이지
        │       │   ├── search_page.dart         # 장소 검색 페이지
        │       │   └── search_viewmodel.dart
        │       └── indoor/
        │           ├── indoor_navigation_sheet.dart  # 실내 경로 입력 시트
        │           └── indoor_map_page.dart          # 실내 지도 페이지
        ├── assets/
        │   ├── icons/
        │   └── images/
        ├── android/
        │   └── app/
        │       └── google-services.json    # Firebase Android 설정
        ├── ios/
        │   └── Runner/
        │       └── GoogleService-Info.plist  # Firebase iOS 설정
        ├── pubspec.yaml
        └── .env                            # 환경변수 (gitignore)
```

---

## 아키텍처

Flutter 앱은 Clean Architecture 패턴을 따릅니다.

```
Presentation (UI / ViewModel)
        ↓
    UseCase (Domain)
        ↓
    Repository (Interface)
        ↓
  Data Source (API / Firestore)
        ↓
외부 서비스 (Naver API / Firebase)
```

### 장소 검색 흐름

```
SearchPage → SearchViewModel → SearchPlacesUseCase
    → PlaceRepositoryImpl → NaverLocalSearchApi
    → GET https://openapi.naver.com/v1/search/local.json
```

### 실외 경로 안내 흐름

```
_PlaceDetailSheet → RouteFinderModal
    → NaverDirectionsApi
    → GET https://naveropenapi.apigw.ntruss.com/map-direction-15/walking
    → MapComponent.drawRoute() (폴리라인 렌더링)
```

---

## 구현된 기능

### 1. 장소 검색
- 네이버 Local Search API를 통해 장소 이름으로 검색
- 검색 결과에서 장소 선택 시 지도에 마커 표시 및 카메라 이동
- 장소 상세 정보 바텀시트 표시 (이름, 카테고리, 주소, 전화번호)

### 2. 현재 위치 실시간 추적
- 앱 실행 시 GPS 위치 권한 요청
- 현재 위치로 지도 카메라 즉시 이동
- 5m 이상 이동 시 카메라 자동 업데이트 (팔로우 모드)
- 지도 드래그 시 팔로우 모드 OFF, 자유 탐색 가능

### 3. 실외 보행자 경로 안내
- Naver Directions 15 Walking API 사용 (자동차 경로가 아닌 **보행자 경로**)
- 현재 위치 → 목적지까지의 경로를 파란 폴리라인으로 지도에 표시
- 거리 및 예상 소요 시간 표시
- 건물에 진입로(경사로) 데이터가 있는 경우 진입로 선택 후 경로 안내

### 4. 실내 경로 안내 (UI 구현, 알고리즘 연동 예정)
- 건물 선택 시 "실내 경로" 버튼으로 진입
- 출발지 좌표 / 도착지 좌표 입력 UI 구현
- 실내 경로 알고리즘은 별도 팀에서 추후 연동 예정

### 5. Firebase 연동
- Firebase Core, Auth, Firestore, Realtime Database 패키지 설치 완료
- 건물 데이터를 Firestore `buildings` 컬렉션에서 관리 가능 (진입로 데이터 포함)

---

## 환경 설정

### 프론트엔드 (`frontend/whitecane/.env`)

`.env.example`을 복사해서 `.env` 파일을 생성하고 아래 값을 채우세요.

```env
# 백엔드 서버 URL
SERVER_URL=http://10.0.2.2:8000/

# 네이버 지도 SDK (NCP - console.ncloud.com)
NAVER_MAP_CLIENT_ID=발급받은_클라이언트_ID

# 네이버 Directions 15 Walking API (NCP - console.ncloud.com)
NAVER_DIRECTIONS_CLIENT_ID=발급받은_Directions_클라이언트_ID
NAVER_DIRECTIONS_CLIENT_SECRET=발급받은_Directions_클라이언트_SECRET

# 네이버 장소 검색 API (developers.naver.com)
NAVER_SEARCH_CLIENT_ID=발급받은_검색_클라이언트_ID
NAVER_SEARCH_CLIENT_SECRET=발급받은_검색_클라이언트_SECRET
```

> **주의:** Android 에뮬레이터에서 로컬 백엔드 서버 접속 시 `localhost` 대신 `10.0.2.2`를 사용합니다.

### 백엔드 (`backend/rust_server/.env`)

```env
PORT=8000
SERVER_URL=http://localhost:8000/
```

---

## API 키 발급 방법

### 1. 네이버 지도 SDK + Directions API (NCP)

> **발급처:** [console.ncloud.com](https://console.ncloud.com)

1. NCP 콘솔 로그인
2. **Services → AI·NAVER API → Maps → Application** 이동
3. 애플리케이션 등록 (앱 패키지명: `com.example.whitecane`)
4. 서비스 목록에서 아래 항목 활성화:
   - **Dynamic Map** (지도 표시용)
   - **Directions 15** (보행자 경로용)
5. 앱 상세 페이지 → **인증 정보** 탭에서 `Client ID` / `Client Secret` 확인

### 2. 네이버 장소 검색 API

> **발급처:** [developers.naver.com](https://developers.naver.com) (NCP와 **다른 사이트**)

1. 네이버 개발자 센터 로그인
2. **Application → 애플리케이션 등록**
3. 사용 API 목록에서 **검색** 체크
4. Android 앱 패키지명 입력: `com.example.whitecane`
5. `Client ID` / `Client Secret` 확인

### 3. Firebase

> **발급처:** [console.firebase.google.com](https://console.firebase.google.com)

1. Firebase 프로젝트 생성
2. Android / iOS 앱 등록
3. `flutterfire configure` 실행 (자동으로 `firebase_options.dart` 생성)

```bash
# Firebase CLI 및 FlutterFire CLI 설치
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# 로그인 및 설정
firebase login
cd frontend/whitecane
flutterfire configure
```

---

## 실행 방법

### 사전 준비

- Flutter SDK 설치 (>=3.3.0)
- Android Studio + Android Emulator 설정
- 환경변수 파일 (`.env`) 준비

### Flutter 앱 실행

```bash
cd frontend/whitecane
flutter pub get
flutter run
```

### 에뮬레이터 현재 위치 설정

실제 기기가 없을 경우 Android Studio 에뮬레이터에서 가상 위치를 설정합니다:

1. 에뮬레이터 오른쪽 점 세개(···) 클릭
2. **Location** 탭 선택
3. 아래 좌표 입력 후 **Set Location** 클릭

```
Latitude:  37.5620
Longitude: 126.9469
```

### 백엔드 서버 실행 (선택)

```bash
cd backend/rust_server
cargo run
```

> 현재 장소 검색은 네이버 API를 직접 호출하므로 백엔드 없이도 앱이 동작합니다.

---

## Firebase 설정

### Firestore 건물 데이터 구조

진입로(경사로) 데이터를 Firestore에 저장하는 경우 아래 구조를 따릅니다.

**컬렉션:** `buildings`

```json
{
  "name": "ECC",
  "address": "서울특별시 서대문구 이화여대길 52",
  "latitude": 37.5620,
  "longitude": 126.9469,
  "category": "대학 건물",
  "phoneNumber": "02-3277-2114",
  "entrances": [
    {
      "nodeId": "ecc_entrance_1",
      "description": "정문 경사로",
      "latitude": 37.5621,
      "longitude": 126.9470
    }
  ]
}
```

### Firestore 보안 규칙

개발 단계에서는 테스트 모드(전체 허용)로 설정하고, 배포 전 반드시 규칙을 강화하세요.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // 개발용, 배포 전 변경 필요
    }
  }
}
```

---

## 향후 구현 예정

| 기능 | 설명 | 우선순위 |
|------|------|---------|
| 실내 경로 알고리즘 연동 | 별도 팀의 알고리즘을 출발지/도착지 좌표 기반으로 연동 | 높음 |
| 로그인 / 회원가입 | Firebase Auth (이메일 또는 Google 로그인) | 중간 |
| 즐겨찾기 | 자주 가는 장소 저장 (Firestore) | 중간 |
| 경사로 데이터 관리 | 캠퍼스 내 경사로/진입로 위치 데이터 수집 및 Firestore 저장 | 중간 |
| 음성 안내 | TTS 기반 경로 안내 음성 출력 | 높음 |
| 설정 페이지 | 음성 안내 on/off 등 접근성 설정 | 낮음 |
