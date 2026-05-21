from fastapi import APIRouter

router = APIRouter()


@router.post("/")
async def scan_image():
    # TODO: 이미지 수신 후 Gemini Vision 판별
    return {"message": "scan endpoint - WIP"}
