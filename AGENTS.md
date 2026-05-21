# AGENTS.md

Codex 작업 지침입니다. 이 저장소에서 코드를 수정하거나 실행할 때 아래 규칙을 우선 적용합니다.

## 프로젝트 개요

Green Scanner는 AI 카메라로 분리배출 여부를 빠르게 판별하는 해커톤 프로젝트입니다.
사용자가 쓰레기를 카메라로 찍거나 텍스트로 설명하면 Gemini 3.5 Flash가 아래 고정 JSON 구조로 결과를 반환합니다.

```json
{
  "verdict": "플라스틱",
  "condition": "세척 필요",
  "action": "물로 3회 헹군 뒤 라벨 제거 후 배출하세요.",
  "reason": "PP 재질 용기이나 기름 오염이 확인됩니다."
}
```

`verdict`: `일반쓰레기 | 플라스틱 | 종이류 | 유리 | 캔 | 비닐 | 스티로폼 | 음식물 | 특수폐기물`

`condition`: `세척 필요 | 라벨·테이프 제거 필요 | 부품 분리 필요 | null`

## 구조

```text
app/          Flutter 앱 (Android + Tablet)
backend/      FastAPI 서버 -> Gemini 3.5 Flash + RAG
firmware/     ESP32 BLE 펌웨어 (키오스크 자동 트리거용)
docs/         API 명세서, 개발 가이드, Git 규칙, 환경 설정
```

Flutter 앱은 백엔드와 두 엔드포인트로 통신합니다.

- `POST /scan/`: 이미지 multipart 전송
- `POST /chat/`: 텍스트 설명 전송

키오스크 모드는 ESP32가 HC-SR04로 거리를 측정해 BLE로 Flutter 앱에 트리거를 보내고, 앱이 자동 촬영 후 `/scan/`을 호출합니다.

## Flutter 규칙

반드시 `fvm flutter`를 사용합니다. plain `flutter` 명령은 사용하지 않습니다.

```bash
cd app
fvm flutter pub get
fvm flutter run
fvm flutter build apk --release
fvm flutter analyze
fvm flutter test
```

기술 선택:

- 상태관리: `flutter_riverpod`
- HTTP: `dio`
- BLE: `flutter_blue_plus`
- 권한: `permission_handler`

기능별 폴더는 아래 구조를 따릅니다.

```text
lib/features/scan/
lib/features/chat/
lib/features/kiosk/
lib/core/
```

## 백엔드 규칙

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

- 로컬 API 문서: `http://localhost:8000/docs`
- 환경변수 파일: `backend/.env`
- 필수 환경변수: `GEMINI_API_KEY`

현재 구현 상태:

- `backend/app/main.py`: 라우터 등록, CORS, health check 완료
- `backend/app/api/scan.py`: 스텁 상태, Gemini 연동 필요
- `backend/app/api/chat.py`: 스텁 상태, Gemini 연동 필요
- `backend/app/services/gemini.py`: `analyze_image`, `analyze_text` 구현 필요
- `backend/app/services/rag.py`: RAG 구현 필요
- `backend/knowledge_base/`: 환경부 분리배출 기준 데이터 작성 필요

## 구현 원칙

- 기존 문서의 API 스키마와 응답 구조를 유지합니다.
- 판별 API 응답은 항상 `verdict`, `condition`, `action`, `reason` 필드를 포함해야 합니다.
- Flutter 앱에서는 기존 패키지와 구조를 우선 사용하고, 새 아키텍처를 임의로 도입하지 않습니다.
- 백엔드에서는 FastAPI 라우터 구조를 유지합니다.
- Gemini 또는 RAG 구현 시 API 키는 코드에 하드코딩하지 않습니다.
- 테스트나 분석을 실행할 때는 프로젝트 문서에 적힌 명령어를 사용합니다.

## Git 규칙

- 각자 이름으로 고정 브랜치 하나를 사용합니다.
- `main`에 직접 push하지 않습니다.
- 작업 완료 후 PR을 만들고, `main` 머지 후 내 브랜치로 다시 머지해 싱크합니다.
- 커밋 메시지는 아래 접두사를 사용합니다.

```text
feat:
fix:
chore:
docs:
```

## Codex 작업 방식

- 사용자 변경사항을 임의로 되돌리지 않습니다.
- 작업 전 `git status --short --branch`로 변경 상태를 확인합니다.
- 파일 검색은 우선 `rg`를 사용합니다.
- 코드 수정은 기존 스타일과 폴더 구조를 따릅니다.
- 불필요한 리팩터링은 하지 않습니다.
- 변경 후 가능한 범위에서 `fvm flutter analyze`, `fvm flutter test`, 백엔드 테스트 또는 서버 실행으로 확인합니다.
