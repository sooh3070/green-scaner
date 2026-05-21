from fastapi import APIRouter

router = APIRouter()


@router.post("/")
async def chat_analyze():
    # TODO: 텍스트 설명 수신 후 RAG + Gemini 판별
    return {"message": "chat endpoint - WIP"}
