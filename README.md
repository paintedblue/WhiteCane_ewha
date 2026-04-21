# 🦯 WhiteCane

> 시각장애인을 위한 캠퍼스 보행 안내 앱

이화여자대학교 캠퍼스에서 목적지를 검색하고, 실외 보행자 경로 안내 및 실내 경로 안내를 제공합니다.

---

## 📱 주요 기능

| 기능 | 설명 |
|------|------|
| 🔍 장소 검색 | 건물 이름으로 캠퍼스 내 장소 검색 |
| 📍 현재 위치 추적 | GPS 기반 실시간 위치 추적 및 지도 팔로우 |
| 🚶 실외 경로 안내 | 현재 위치 → 목적지까지 보행자 경로 안내 |
| 🏢 실내 경로 안내 | 건물 내부 경로 안내 (알고리즘 연동 예정) |

---

## 🛠 기술 스택

| 영역 | 사용 기술 |
|------|----------|
| 모바일 앱 | Flutter (Android / iOS) |
| 지도 | Naver Maps SDK |
| 장소 검색 | Naver Local Search API |
| 경로 안내 | Naver Directions 15 (보행자) |
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

# 네이버 지도 SDK
NAVER_MAP_CLIENT_ID=발급받은_ID

# 네이버 Directions (보행자 경로)
NAVER_DIRECTIONS_CLIENT_ID=발급받은_ID
NAVER_DIRECTIONS_CLIENT_SECRET=발급받은_Secret

# 네이버 장소 검색
NAVER_SEARCH_CLIENT_ID=발급받은_ID
NAVER_SEARCH_CLIENT_SECRET=발급받은_Secret
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

### Naver Maps + Directions API
> 사이트: [console.ncloud.com](https://console.ncloud.com)

1. NCP 콘솔 로그인
2. **Services → AI·NAVER API → Maps → Application** 이동
3. 애플리케이션 등록, 아래 서비스 활성화:
   - `Dynamic Map` (지도 표시)
   - `Directions 15` (보행자 경로)
4. 앱 상세 → **인증 정보** 탭에서 `Client ID` / `Client Secret` 복사

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
            ├── main.dart                  # 앱 시작점
            ├── firebase_options.dart      # Firebase 설정 (자동 생성)
            ├── di/                        # 의존성 주입
            ├── domain/
            │   ├── model/                 # Place, Entrance 모델
            │   ├── repository/            # 데이터 인터페이스
            │   └── usecase/               # 비즈니스 로직
            ├── data/
            │   ├── firestore/             # Firestore 데이터 소스
            │   └── remote/api/            # Naver API 호출
            └── presentation/
                ├── map/                   # 지도 화면
                ├── indoor/                # 실내 경로 화면
                └── common/                # 공통 위젯
```

---

## 🗺 화면 구성

```
앱 실행
  └─ 메인 지도 화면
       ├─ 검색창 클릭 → 장소 검색 화면
       │     └─ 결과 클릭 → 지도에 마커 표시
       │                 → 장소 상세 바텀시트
       │                       ├─ 실외 경로 버튼 → 경로 안내 모달
       │                       │                  → 지도에 경로 표시
       │                       └─ 실내 경로 버튼 → 실내 경로 화면
       └─ 현재 위치 자동 추적 (GPS)
```

---

## 🔥 Firebase Firestore 구조

건물 진입로(경사로) 데이터는 Firestore `buildings` 컬렉션에 저장합니다.

```
buildings/
  └── {문서ID}
        ├── name        : "ECC"
        ├── address     : "서울특별시 서대문구 이화여대길 52"
        ├── latitude    : 37.5620
        ├── longitude   : 126.9469
        ├── category    : "대학 건물"
        ├── phoneNumber : "02-3277-2114"
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
Latitude  : 37.5620
Longitude : 126.9469
```

---

## 📋 개발 현황

- [x] 네이버 지도 SDK 연동
- [x] 현재 위치 실시간 추적
- [x] 장소 검색 (Naver Local Search API)
- [x] 실외 보행자 경로 안내 (Naver Directions 15)
- [x] Firebase 연동 (Firestore, Auth, Realtime DB)
- [x] 실내 경로 UI
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
