# 백엔드 개발 가이드

## 구조

```
backend/
├── app/
│   ├── main.py              # FastAPI 앱, 라우터 등록
│   ├── api/
│   │   ├── scan.py          # POST /scan/ 엔드포인트
│   │   └── chat.py          # POST /chat/ 엔드포인트
│   └── services/
│       ├── gemini.py        # Gemini 3.5 Flash 호출
│       └── rag.py           # RAG 검색 (분리배출 기준 KB)
├── knowledge_base/          # RAG에 사용할 분리배출 기준 텍스트
├── Dockerfile
├── requirements.txt
└── .env                     # GEMINI_API_KEY (git 제외)
```

---

## 개발 순서

### 1단계: Gemini 연동 (`services/gemini.py`)

- `google-generativeai` SDK 사용
- 모델: `gemini-3.5-flash`
- 이미지(bytes) 또는 텍스트를 받아 ScanResult JSON 반환
- 응답을 반드시 JSON으로 강제 (Structured Output 또는 프롬프트 지시)

```python
# 구현할 함수
async def analyze_image(image_bytes: bytes) -> dict: ...
async def analyze_text(message: str) -> dict: ...
```

**Gemini에게 전달할 프롬프트 방향**

```
당신은 한국 분리배출 전문가입니다.
아래 물체를 분석하여 반드시 다음 JSON 형식으로만 응답하세요:
{
  "verdict": "<일반쓰레기|플라스틱|종이류|유리|캔|비닐|스티로폼|음식물|특수폐기물>",
  "condition": "<세척 필요|라벨·테이프 제거 필요|부품 분리 필요|null>",
  "action": "<사용자 행동 지침>",
  "reason": "<판정 근거>"
}
```

---

### 2단계: RAG 구성 (`services/rag.py`, `knowledge_base/`)

- `knowledge_base/` 폴더에 분리배출 기준 텍스트 파일 작성
  - 환경부 분리배출 기준
  - 재질별 세부 처리 방법
  - 애매한 품목 판정 기준 (감열지, 복합재질 등)
- 텍스트를 청크로 분리 후 벡터 임베딩 → 유사도 검색
- 검색 결과를 Gemini 프롬프트에 context로 주입

**사용 가능한 라이브러리**
- `chromadb` (로컬 벡터 DB, 가장 간단)
- `langchain` (RAG 파이프라인 구성)

---

### 3단계: 엔드포인트 구현

#### `api/scan.py`

```python
@router.post("/", response_model=ScanResult)
async def scan_image(image: UploadFile = File(...)):
    image_bytes = await image.read()
    result = await gemini.analyze_image(image_bytes)
    return result
```

#### `api/chat.py`

```python
@router.post("/", response_model=ScanResult)
async def chat_analyze(body: ChatRequest):
    result = await gemini.analyze_text(body.message)
    return result
```

---

### 4단계: 배포 (GCP Cloud Run)

```bash
# Docker 빌드 & 푸시
docker build -t gcr.io/PROJECT_ID/green-scanner-api .
docker push gcr.io/PROJECT_ID/green-scanner-api

# Cloud Run 배포
gcloud run deploy green-scanner-api \
  --image gcr.io/PROJECT_ID/green-scanner-api \
  --platform managed \
  --region asia-northeast3 \
  --set-env-vars GEMINI_API_KEY=your_key
```

---

## 로컬 실행

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

서버 확인: http://localhost:8000
API 문서 (자동 생성): http://localhost:8000/docs

---

## TODO

- [ ] `services/gemini.py` — 이미지 분석 구현
- [ ] `services/gemini.py` — 텍스트 분석 구현
- [ ] `knowledge_base/` — 분리배출 기준 데이터 작성
- [ ] `services/rag.py` — RAG 파이프라인 구성
- [ ] `api/scan.py` — 실제 Gemini 호출로 교체
- [ ] `api/chat.py` — 실제 Gemini + RAG 호출로 교체
- [ ] Pydantic 모델 (`ScanResult`, `ChatRequest`) 정의
- [ ] GCP Cloud Run 배포
