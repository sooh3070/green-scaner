# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

AI 카메라로 분리배출 여부를 1초 만에 판별하는 해커톤 프로젝트.
사용자가 쓰레기를 카메라로 찍으면 Gemini 3.5 Flash가 verdict + condition + action + reason 구조의 JSON을 반환한다.

## 아키텍처

```
app/          Flutter 앱 (Android + Tablet)
backend/      FastAPI 서버 → Gemini 3.5 Flash + RAG
firmware/     ESP32 BLE 펌웨어 (키오스크 자동 트리거용)
docs/         API 명세서, 개발 가이드, Git 규칙, 환경 설정
```

Flutter 앱은 두 가지 경로로 백엔드와 통신한다:
- `POST /scan/` — 이미지(multipart) 전송
- `POST /chat/` — 텍스트 설명 전송

키오스크 모드에서는 ESP32가 HC-SR04로 거리를 측정해 BLE로 Flutter 앱에 트리거를 보내고, 앱이 자동으로 카메라를 촬영해 `/scan/`을 호출한다.

## AI 판정 스키마

모든 판별 API의 응답은 아래 구조로 고정된다.

```json
{
  "verdict": "플라스틱",
  "condition": "세척 필요",
  "action": "물로 3회 헹군 뒤 라벨 제거 후 배출하세요.",
  "reason": "PP 재질 용기이나 기름 오염이 확인됩니다."
}
```

verdict: `일반쓰레기 | 플라스틱 | 종이류 | 유리 | 캔 | 비닐 | 스티로폼 | 음식물 | 특수폐기물`  
condition: `세척 필요 | 라벨·테이프 제거 필요 | 부품 분리 필요 | null`

## Flutter 앱 명령어

```bash
cd app

# 반드시 fvm flutter 사용 (flutter 직접 사용 금지)
fvm flutter pub get
fvm flutter run
fvm flutter build apk --release
fvm flutter analyze
fvm flutter test
```

상태관리는 **Riverpod** (`flutter_riverpod`), HTTP는 **Dio**, BLE는 **flutter_blue_plus** 사용.  
기능별 폴더 구조: `lib/features/scan/`, `lib/features/chat/`, `lib/features/kiosk/`, `lib/core/`

## 백엔드 명령어

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload   # 로컬 실행
```

로컬 API 문서: http://localhost:8000/docs  
환경변수: `backend/.env` (GEMINI_API_KEY)

## 백엔드 구현 현황

- `app/main.py` — 라우터 등록, CORS, health check 완료
- `app/api/scan.py` / `app/api/chat.py` — 스텁 상태, Gemini 연동 필요
- `app/services/gemini.py` — 미구현 (`analyze_image`, `analyze_text` 작성 필요)
- `app/services/rag.py` — 미구현 (chromadb 또는 langchain 사용 예정)
- `knowledge_base/` — 환경부 분리배출 기준 데이터 미작성

## Git 규칙

각자 이름으로 고정 브랜치 하나 사용. `main` 직접 push 금지.  
작업 완료 후 PR → main 머지 → main을 내 브랜치로 다시 머지해 싱크.  
커밋: `feat:` / `fix:` / `chore:` / `docs:` 접두사 사용.
