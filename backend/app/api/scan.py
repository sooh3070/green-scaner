import os
from typing import Annotated

from fastapi import APIRouter, File, HTTPException, UploadFile

from app.schemas import ScanResult
from app.services import gemini

router = APIRouter()

DEFAULT_MAX_IMAGE_BYTES = 10 * 1024 * 1024
SUPPORTED_IMAGE_MIME_TYPES = {
    "image/jpeg",
    "image/png",
}


@router.post("/", response_model=ScanResult)
async def scan_image(
    image: Annotated[UploadFile | None, File()] = None,
):
    if image is None:
        raise HTTPException(status_code=400, detail="이미지 파일을 업로드해주세요.")

    max_image_bytes = _max_image_bytes()
    upload_size = getattr(image, "size", None)
    if upload_size is not None and upload_size > max_image_bytes:
        raise HTTPException(
            status_code=400,
            detail=_image_size_error_message(max_image_bytes),
        )

    image_bytes = await image.read()
    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="빈 이미지 파일은 분석할 수 없습니다.",
        )

    if len(image_bytes) > max_image_bytes:
        raise HTTPException(
            status_code=400,
            detail=_image_size_error_message(max_image_bytes),
        )

    mime_type = _resolve_mime_type(image_bytes)
    if mime_type is None:
        raise HTTPException(
            status_code=400,
            detail="jpg, png 이미지 파일만 업로드할 수 있습니다.",
        )

    try:
        return await gemini.analyze_image(
            image_bytes=image_bytes,
            mime_type=mime_type,
        )
    except gemini.GeminiConfigurationError:
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY 또는 GEMINI_MODEL이 설정되어 있지 않습니다.",
        )
    except gemini.GeminiResponseError:
        raise HTTPException(status_code=500, detail="이미지를 분석할 수 없습니다.")


def _max_image_bytes() -> int:
    raw_value = os.getenv("MAX_SCAN_IMAGE_BYTES")
    if raw_value is None:
        return DEFAULT_MAX_IMAGE_BYTES

    try:
        return max(int(raw_value), 1)
    except ValueError:
        return DEFAULT_MAX_IMAGE_BYTES


def _image_size_error_message(max_image_bytes: int) -> str:
    max_image_megabytes = max(1, max_image_bytes // 1024 // 1024)
    return f"이미지 파일 크기는 {max_image_megabytes}MB 이하여야 합니다."


def _resolve_mime_type(image_bytes: bytes) -> str | None:
    detected_type = _detect_image_mime_type(image_bytes)
    if detected_type in SUPPORTED_IMAGE_MIME_TYPES:
        return detected_type

    return None


def _detect_image_mime_type(image_bytes: bytes) -> str | None:
    if image_bytes.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"

    if image_bytes.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png"

    return None
