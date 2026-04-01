# WhiteCane_ewha

시각장애인을 위한 보행 보조 앱으로, 이화여자대학교 캠퍼스를 중심으로 목적지 검색 및 경로 안내 기능을 제공합니다.

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 모바일 앱 | Flutter (Android) |
| 지도 표시 | flutter_naver_map (Naver Maps SDK) |
| 위치 추적 | geolocator |
| 장소 검색 | Kakao Local Search REST API |
| 백엔드 | Rust + Actix-web |
| 상태 관리 | GetX |
| DI | get_it |
| HTTP 클라이언트 (앱) | Dio |
| HTTP 클라이언트 (서버) | reqwest |

---

## 프로젝트 구조

```
WhiteCane_ewha/
├── backend/
│   └── rust_server/            # Actix-web REST API 서버
│       ├── src/
│       │   ├── main.rs
│       │   ├── handlers/
│       │   │   ├── place.rs    # 장소 검색 핸들러 (Kakao API 연동)
│       │   │   └── navigation.rs
│       │   └── routes/
│       │       └── mod.rs
│       ├── Cargo.toml
│       └── .env                # 환경변수 (gitignore)
│
└── frontend/
    └── whitecane/              # Flutter 앱
        ├── lib/
        │   ├── main.dart
        │   ├── di/
        │   │   └── service_locator.dart   # get_it DI 설정
        │   ├── navigation/
        │   │   └── main_navigation_page.dart
        │   ├── domain/
        │   │   ├── model/
        │   │   │   └── place.dart         # Place 도메인 모델
        │   │   ├── repository/
        │   │   │   └── place_repository.dart
        │   │   └── usecase/
        │   │       └── search_places_usecase.dart
        │   ├── data/
        │   │   └── remote/
        │   │       ├── api/
        │   │       │   ├── building_api.dart    # 장소 검색 API 호출
        │   │       │   └── navigation_api.dart
        │   │       └── dto/
        │   │           ├── building_dto.dart    # 백엔드 응답 DTO
        │   │           └── navigation_dto.dart
        │   └── presentation/
        │       ├── common/
        │       │   ├── map_component.dart  # 네이버 지도 위젯
        │       │   └── place_item.dart     # 검색 결과 리스트 아이템
        │       └── map/
        │           └── map_page.dart
        ├── assets/
        │   ├── icons/
        │   └── images/
        └── .env                # 환경변수 (gitignore)
```

---

## 아키텍처

Flutter 앱은 Clean Architecture 패턴을 따릅니다.

```
UI (Presentation)
    ↓ 호출
UseCase (Domain)
    ↓ 호출
Repository (Domain Interface / Data Impl)
    ↓ 호출
API (Data / Remote)
    ↓ HTTP
Rust Backend (/api/building)
    ↓ HTTP
Kakao Local Search API
```

---

## 현재 위치 실시간 추적

`geolocator` 패키지를 사용해 GPS 위치를 실시간으로 수신하고 지도 카메라가 사용자를 따라갑니다.

### 동작 방식

- 앱 실행 시 위치 권한 요청
- 권한 허용 후 현재 위치로 카메라 즉시 이동
- 이후 5m 이상 이동할 때마다 카메라 자동 업데이트 (팔로우 ON)
- 지도를 드래그하면 팔로우 OFF → 사용자가 원하는 곳을 자유롭게 탐색 가능
- `MapComponentState.resumeFollowing()` 호출 시 팔로우 재활성화

### 필요 권한 (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

---

## API

### 장소 검색

```
GET /api/building?name={검색어}
```

**Response:**
```json
[
  {
    "name": "이화여자대학교",
    "address": "서울 서대문구 이화여대길 52",
    "latitude": 37.5620,
    "longitude": 126.9469,
    "category": "대학교",
    "phone_number": "02-3277-2114"
  }
]
```

---

## 환경 설정

### 백엔드 (`backend/rust_server/.env`)

```env
PORT=8000
ROUTING_SERVER_URL=http://localhost:8002

# Naver Maps (지도 표시용) - console.ncloud.com
NAVER_MAP_CLIENT_ID=발급받은_클라이언트_ID
NAVER_CLIENT_SECRET=발급받은_클라이언트_SECRET

# Kakao (장소 검색용) - developers.kakao.com
KAKAO_REST_API_KEY=발급받은_REST_API_키
```

### 프론트엔드 (`frontend/whitecane/.env`)

```env
NAVER_MAP_CLIENT_ID=발급받은_클라이언트_ID
NAVER_CLIENT_SECRET=발급받은_클라이언트_SECRET
SERVER_URL=http://10.0.2.2:8000/
```

> **참고:** Android 에뮬레이터에서 호스트 Mac의 localhost는 `10.0.2.2`로 접근합니다.

---

## 실행 방법

### 백엔드 서버

```bash
cd backend/rust_server
cargo run
# 서버가 http://localhost:8000 에서 실행됨
```

### Flutter 앱 (Android 에뮬레이터)

```bash
cd frontend/whitecane
flutter pub get
flutter run
```

---

## API 키 발급

| 서비스 | 용도 | 발급처 |
|--------|------|--------|
| Naver Maps | 지도 표시 | [console.ncloud.com](https://console.ncloud.com) → Services → Maps |
| Kakao Local Search | 장소 검색 | [developers.kakao.com](https://developers.kakao.com) → 내 애플리케이션 → REST API 키 |

> Kakao 앱 설정에서 **제품 설정 → 카카오맵** 활성화 필요
