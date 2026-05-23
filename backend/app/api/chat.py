from fastapi import APIRouter, HTTPException

from app.schemas import ChatRequest, ScanResult
from app.services import gemini

router = APIRouter()


@router.post(
    "/",
    response_model=ScanResult,
    responses={
        400: {"description": "잘못된 요청"},
        500: {"description": "Gemini API 호출 실패"},
    },
)
async def chat_analyze(body: ChatRequest):
    try:
        return await gemini.analyze_text(body.message)
    except gemini.GeminiConfigurationError:
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY가 설정되어 있지 않습니다.",
        )
    except gemini.GeminiResponseError:
        raise HTTPException(status_code=500, detail="텍스트를 분석할 수 없습니다.")
