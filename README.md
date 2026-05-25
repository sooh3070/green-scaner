# Green Scanner (그린스캐너)

> **버릴까 말까 고민되는 애매한 일상 쓰레기, AI 카메라로 1초 만에 판결합니다.**

분리배출 의지는 있지만 복잡하고 모호한 기준 때문에 쓰레기통 앞에서 좌절하는 사람들을 위한  
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

### 1. 카메라 스캔 모드
후면 카메라로 물체를 촬영하면 AI가 즉시 분리배출 여부를 판별합니다.
- 오염도 분석 (기름때, 착색 등)
- 복합 재질 판별
- AI 판정 결과를 구조화된 JSON으로 반환 (verdict + condition)
- 맞춤형 액션 플랜 제공 ("테이프 제거 후 배출", "물로 3회 헹구면 재활용 가능" 등)

### 2. 채팅 판별 모드
직접 물품 상태를 텍스트로 설명하면 AI가 분리배출 방법을 안내합니다.
- 예: "마라탕 먹고 남은 플라스틱 용기인데 기름이 많이 묻었어"
- RAG 기반 환경부 분리배출 기준 적용

### 3. 키오스크 자동 감지 모드
ESP32 + HC-SR04 초음파 센서와 연동하여, 쓰레기통 앞에 사람이 접근하면 자동으로 촬영 및 판별합니다.
- 설정 거리(기본 60cm) 이내 감지 시 자동 트리거
- 태블릿(갤럭시 탭 등) 거치 환경에 최적화

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 앱 | Flutter 3.44.0 (FVM, Android + Tablet) |
| 백엔드 | FastAPI + Docker |
| 배포 | GCP Cloud Run |
| AI | Gemini 3.5 Flash (`gemini-3.5-flash`) |
| RAG | 환경부 분리배출 기준 기반 자체 KB |
| IoT | ESP32 (BLE) + HC-SR04 초음파 센서 |

---

## 시스템 아키텍처

```
[사용자]
   │
   ├─ 카메라/채팅 입력
   │
[Flutter App (Android / Tablet)]
   │                          │
   │ BLE                      │ HTTP
   │                          │
[ESP32 + HC-SR04]      [FastAPI Server]
  (자동 트리거)              │         │
                        [Gemini 3.5 Flash]  [RAG KB]
                         Vision + 추론    (분리배출 기준)
```

---

## 프로젝트 구조

```
green-scanner/
├── app/                    # Flutter 앱
│   ├── lib/
│   │   ├── features/
│   │   │   ├── scan/       # 카메라 스캔 모드
│   │   │   ├── chat/       # 채팅 판별 모드
│   │   │   └── kiosk/      # 키오스크 자동 감지 모드
│   │   ├── core/           # BLE, API 클라이언트
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/                # FastAPI 서버
│   ├── app/
│   │   ├── api/
│   │   │   ├── scan.py
│   │   │   └── chat.py
│   │   ├── services/
│   │   │   ├── gemini.py
│   │   │   └── rag.py
│   │   └── main.py
│   ├── knowledge_base/
│   ├── Dockerfile
│   └── requirements.txt
│
├── firmware/               # ESP32 펌웨어
│   └── sensor_ble/
│       └── sensor_ble.ino
│
└── docs/                   # 문서
    ├── setup.md
    ├── git.md
    ├── api.md
    └── backend.md
```

---

## 보급 및 홍보 전략

### 오프라인 접점: 키오스크 설치

공용 쓰레기장(기숙사 수거장, 캠퍼스 배달존, 건물 로비 등)에 태블릿을 키오스크 모드로 거치합니다.
- ESP32 + HC-SR04 센서가 접근을 감지해 자동으로 카메라 촬영 및 판별 실행
- 추가 조작 없이 쓰레기통 앞에 서기만 해도 즉시 결과 표시

### 개인 스마트폰 전환: QR 코드

키오스크 옆에 QR 코드를 부착해 개인 설치를 유도합니다.

```
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
| 종이류   | 80 g CO₂ | 종이류 평균 중량 150 g × 0.54 kg CO₂/kg |
| 유리     | 30 g CO₂ | 유리병 평균 중량 300 g × 0.10 kg CO₂/kg |
| 캔       | 95 g CO₂ | 알루미늄 캔 평균 중량 15 g × 6.3 kg CO₂/kg |
| 비닐     | 20 g CO₂ | 비닐봉지 평균 중량 40 g × 0.50 kg CO₂/kg |
| 스티로폼 | 40 g CO₂ | EPS 평균 중량 80 g × 0.50 kg CO₂/kg |

**출처**

- EPA WARM (Waste Reduction Model) — 재질별 온실가스 배출 계수: https://www.epa.gov/warm/documentation-chapters-greenhouse-gas-emission-and-energy-factors-used-waste-reduction-model-warm
- 한국환경공단 국가 LCI 데이터베이스: https://www.edp.or.kr
- 온실가스종합정보센터 (환경부): https://www.gir.go.kr

> 절감량은 해당 재질을 재활용했을 때 원자재 생산 대비 회피되는 온실가스량 기준입니다.  
> 항목별 평균 중량은 국내 유통 제품 기준 추정치이며, 실제 제품에 따라 차이가 있을 수 있습니다.

---

## 개발 배경

> 해커톤 프로토타입 프로젝트  
> "버리는 순간에 개입하는 것이 가장 효과적인 친환경 행동 유도다"
