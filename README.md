# Green Scanner (그린스캐너)

> **버릴까 말까 고민되는 애매한 일상 쓰레기, AI 카메라로 1초 만에 판별합니다.**

분리배출 의지는 있지만 복잡하고 모호한 기준 때문에 쓰레기통 앞에서 좌절하는 사람들을 위한<br>
AI 비전 기반 친환경 행동 유도 플랫폼입니다.

---

## 문서

| 문서 | 내용 |
|------|------|
| [docs/setup.md](docs/setup.md) | 개발 환경 설정 (FVM, Python, Arduino IDE) |
| [docs/git.md](docs/git.md) | Git 브랜치 전략 및 커밋 규칙 |
| [docs/api.md](docs/api.md) | API 명세서 (엔드포인트, 요청/응답 스키마) |
| [docs/backend.md](docs/backend.md) | 백엔드 개발 가이드 및 TODO |

---

## 문제 정의

| 영역 | 문제 |
|------|------|
| **정보** | "고추기름 묻은 배달 용기", "복합 재질 칫솔", "감열지 영수증" 같은 애매한 쓰레기에 대한 명확한 기준이 없음 |
| **자원순환** | 잘못된 분리배출로 오염된 자원이 선별장에서 탈락 → 결국 소각·매립 |
| **사회적 비용** | 사후 분류에 투입되는 막대한 인력·기계·예산 낭비 |

---

## 핵심 기능

### 1. 홈 대시보드

앱 첫 화면에서 주요 기능과 최근 스캔 기록을 바로 확인합니다.

- 카메라 스캔, 채팅 판별, 키오스크 모드 진입 카드 제공
- 하단 내비게이션으로 홈/통계 탭 이동
- 중앙 플로팅 카메라 버튼으로 즉시 촬영 시작
- 최근 스캔 기록을 로컬에 최대 20개 저장하고 홈에서는 최근 5개 표시
- 프로필 버튼을 통해 Google 계정 및 통계 화면으로 이동

### 2. 카메라 스캔 모드

후면 카메라로 물체를 촬영하면 AI가 즉시 분리배출 여부를 판별합니다.

- Flutter `camera` 기반 촬영 화면
- 촬영 이미지를 `POST /scan/` multipart 요청으로 백엔드에 전송
- 분석 중 프레임 애니메이션 표시
- 결과를 `verdict`, `condition`, `pollution`, `action`, `reason` 구조로 표시
- 배출 가능, 조건부 배출, 배출 불가능 상태를 색상과 카드 UI로 구분
- 로그인 상태에서는 Firestore에 개인 스캔 기록 및 전체 통계 저장

### 3. 채팅 판별 모드

직접 물품 상태를 텍스트로 설명하면 AI가 분리배출 방법을 안내합니다.

- 예: "마라탕 먹고 남은 플라스틱 용기인데 기름이 많이 묻었어"
- `POST /chat/` 요청으로 텍스트 분석
- RAG 기반 환경부 분리배출 기준을 Gemini 프롬프트에 참고 문맥으로 주입
- 채팅 말풍선 안에서 분석 결과 카드 표시

### 4. 키오스크 자동 감지 모드

ESP32 + HC-SR04 초음파 센서와 BLE로 연동하여, 쓰레기통 앞에 사람이 접근하면 자동으로 촬영 및 판별합니다.

- BLE 기기명: `GreenScanner`
- 감지 거리: 30cm 이내
- 펌웨어가 `TRIGGER` 알림을 보내면 앱이 자동 촬영 후 `/scan/` 호출
- 키오스크 화면은 전면 카메라를 우선 사용
- 결과 화면 유지 시간은 10~60초 범위에서 조정 가능

### 5. 계정 및 통계

Firebase Auth와 Cloud Firestore를 사용해 개인/전체 분리배출 기여도를 저장하고 보여줍니다.

- Google 로그인 및 로그아웃
- 개인 통계: 총 판별 수, 재활용 성공 수, 나무 살리기 환산
- 전체 통계: 전체 판별 수, 재활용 처리 수, TOP 5 쓰레기 종류
- Firestore `scans` 컬렉션에 개인 스캔 기록 저장
- Firestore `stats/global` 문서에 전체 통계 atomic 업데이트

---

## API 응답 구조

카메라 스캔과 채팅 판별은 동일한 결과 구조를 사용합니다.

```json
{
  "verdict": "플라스틱",
  "condition": "세척 필요",
  "pollution": 45,
  "action": "물로 3회 헹군 뒤 라벨을 제거하고 플라스틱 수거함에 배출하세요.",
  "reason": "PP 재질 용기로 보이며 표면에 기름 오염이 확인됩니다."
}
```

| 필드 | 설명 |
|------|------|
| `verdict` | `알수없음`, `일반쓰레기`, `플라스틱`, `종이류`, `유리`, `캔`, `비닐`, `스티로폼`, `음식물`, `특수폐기물` 중 하나 |
| `condition` | `세척 필요`, `라벨·테이프 제거 필요`, `부품 분리 필요`, `null` 중 하나 |
| `pollution` | 0~100 사이의 오염도 추정값 |
| `action` | 사용자가 따라야 할 배출 행동 지침 |
| `reason` | AI 판정 근거 |

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 앱 | Flutter 3.44.0 (FVM), Riverpod, Dio, camera, flutter_blue_plus, permission_handler |
| 인증/데이터 | Firebase Auth, Cloud Firestore, Google Sign-In, SharedPreferences |
| 백엔드 | FastAPI, Pydantic, google-generativeai, python-dotenv, Uvicorn |
| 배포 | Docker, GCP Cloud Run |
| AI | Gemini 3.5 Flash (`gemini-3.5-flash`) |
| RAG | `backend/knowledge_base` 기반 키워드 검색 RAG |
| IoT | ESP32 (BLE) + HC-SR04 초음파 센서 |

---

## 시스템 아키텍처

```text
[사용자]
   │
   ├─ 카메라 촬영 / 채팅 입력
   │
[Flutter App (Android / Tablet)]
   │            │                 │
   │ BLE        │ HTTP            │ Firebase
   │            │                 │
[ESP32]   [FastAPI Server]   [Auth / Firestore]
 HC-SR04        │                 │
 자동 트리거     │                 ├─ 개인 스캔 기록
                │                 └─ 전체 통계
                │
          [Gemini 3.5 Flash]
                │
          [RAG Knowledge Base]
```

---

## 프로젝트 구조

```text
green-scaner/
├── app/                         # Flutter 앱
│   ├── assets/
│   │   ├── icon.png
│   │   └── indicator/           # 스캔 분석 로딩 프레임
│   ├── lib/
│   │   ├── core/
│   │   │   ├── api/             # Dio API 클라이언트
│   │   │   ├── models/          # ScanResult, ChatMessage, ScanHistoryEntry
│   │   │   ├── services/        # Auth, Firestore, 로컬 스캔 기록
│   │   │   ├── theme/
│   │   │   └── widgets/
│   │   ├── features/
│   │   │   ├── home/            # 홈 대시보드, 최근 기록
│   │   │   ├── scan/            # 카메라 스캔, 분석 결과
│   │   │   ├── chat/            # 채팅 판별
│   │   │   ├── kiosk/           # BLE 키오스크 모드
│   │   │   ├── stats/           # 개인/전체 통계
│   │   │   └── account/         # Google 계정 화면
│   │   ├── firebase_options.dart
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/                     # FastAPI 서버
│   ├── app/
│   │   ├── api/
│   │   │   ├── scan.py          # POST /scan/
│   │   │   └── chat.py          # POST /chat/
│   │   ├── services/
│   │   │   ├── gemini.py        # Gemini 호출 및 응답 정규화
│   │   │   └── rag.py           # KB 키워드 검색
│   │   ├── schemas.py           # ScanResult, ChatRequest
│   │   └── main.py              # 라우터, CORS, API Key 미들웨어
│   ├── knowledge_base/
│   │   └── recycling_rules.md
│   ├── Dockerfile
│   └── requirements.txt
│
├── firmware/
│   └── sensor_ble/
│       └── module.txt           # ESP32 BLE + HC-SR04 Arduino 코드
│
├── docs/                        # 개발 문서 및 인디케이터 원본 이미지
├── firebase.json
└── firestore.rules
```

---

## 로컬 실행

### Flutter 앱

반드시 FVM 명령어를 사용합니다.

```bash
cd app
fvm flutter pub get
fvm flutter run
```

앱은 `app/assets/.env`에서 API 설정을 읽습니다.

```env
API_BASE_URL=http://10.0.2.2:8000
API_KEY=optional_backend_api_key
```

### 백엔드

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

백엔드는 `backend/.env`에서 Gemini 및 서버 설정을 읽습니다.

```env
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-3.5-flash
MAX_SCAN_IMAGE_BYTES=10485760
API_KEY=optional_backend_api_key
```

- 로컬 API 문서: http://localhost:8000/docs
- `API_KEY`가 설정되어 있으면 앱은 `X-API-Key` 헤더를 함께 보내야 합니다.
- 실제 API 키와 개인정보가 담긴 파일은 커밋하지 않습니다.

### ESP32 펌웨어

현재 ESP32 코드는 `firmware/sensor_ble/module.txt`에 보관되어 있습니다.

1. Arduino IDE에서 ESP32 보드 패키지를 설치합니다.
2. `module.txt`의 코드를 Arduino 스케치로 열어 업로드합니다.
3. 보드는 `GreenScanner` BLE 기기로 광고됩니다.
4. HC-SR04가 30cm 이내 접근을 감지하면 `TRIGGER` 알림을 전송합니다.

---

## 보급 및 홍보 전략

### 오프라인 접점: 키오스크 설치

공용 쓰레기장(기숙사 수거장, 캠퍼스 배달존, 건물 로비 등)에 태블릿을 키오스크 모드로 거치합니다.

- ESP32 + HC-SR04 센서가 접근을 감지해 자동으로 카메라 촬영 및 판별 실행
- 추가 조작 없이 쓰레기통 앞에 서기만 해도 즉시 결과 표시

### 개인 스마트폰 전환: QR 코드

키오스크 옆에 QR 코드를 부착해 개인 설치를 유도합니다.

```text
[키오스크 태블릿 거치]
        |
    옆에 QR 부착
        |
사용자 스마트폰으로 스캔
        |
Google Play 내부 테스트 링크 or PWA 설치
        |
개인 스마트폰에서도 동일 기능 사용
```

### 확장 방향

- **캠퍼스 B2B**: 대학 총무처·시설팀에 키오스크 패키지 제안
- **지역 연계**: 지자체별 분리배출 기준 맞춤 대응
- **리워드 시스템**: 올바른 배출 인증 시 매점·카페 포인트 적립 (추후 도입)

---

## CO₂ 절감량 산출 근거

통계 탭의 CO₂ 절감량은 재질별 LCA(전과정평가) 데이터를 기반으로 산출합니다.

| 재질 | 항목당 절감량 | 산출 근거 |
|------|-------------|----------|
| 플라스틱 | 50 g CO₂ | PET병 평균 중량 25 g × 2.0 kg CO₂/kg |
| 종이류 | 80 g CO₂ | 종이류 평균 중량 150 g × 0.54 kg CO₂/kg |
| 유리 | 30 g CO₂ | 유리병 평균 중량 300 g × 0.10 kg CO₂/kg |
| 캔 | 95 g CO₂ | 알루미늄 캔 평균 중량 15 g × 6.3 kg CO₂/kg |
| 비닐 | 20 g CO₂ | 비닐봉지 평균 중량 40 g × 0.50 kg CO₂/kg |
| 스티로폼 | 40 g CO₂ | EPS 평균 중량 80 g × 0.50 kg CO₂/kg |

---

## 개발 배경

> 해커톤 프로토타입 프로젝트<br>
> "버리는 순간에 개입하는 것이 가장 효과적인 친환경 행동 유도다"
