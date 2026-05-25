import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Any

import google.generativeai as genai
from dotenv import load_dotenv
from google.generativeai.types import GenerationConfig
from pydantic import ValidationError

from app.schemas import CONDITION_VALUES, VERDICT_VALUES, ScanResult
from app.services import rag

logger = logging.getLogger(__name__)

BACKEND_DIR = Path(__file__).resolve().parents[2]
DEFAULT_GEMINI_MODEL = "gemini-3.5-flash"
UNKNOWN_RESULT_INDICATORS = (
    "판단할수없",
    "분류할수없",
    "확인할수없",
    "인식할수없",
    "식별할수없",
    "명확하지않",
    "분리배출대상이아",
    "폐기물이아",
    "쓰레기가아",
    "사람얼굴",
    "신체",
)
SCAN_RESULT_RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "verdict": {
            "type": "string",
            "enum": list(VERDICT_VALUES),
        },
        "condition": {
            "type": "string",
            "enum": list(CONDITION_VALUES),
            "nullable": True,
        },
        "action": {
            "type": "string",
        },
        "reason": {
            "type": "string",
        },
    },
    "required": ["verdict", "condition", "action", "reason"],
}

PROMPT = """
당신은 한국 분리배출 전문가입니다.
이미지 속 물체의 재질, 오염 상태, 라벨/테이프 부착 여부, 복합 재질 여부를 판단하세요.

반드시 JSON 객체 하나만 응답하세요. 마크다운 코드블록이나 설명 문장은 넣지 마세요.
응답 필드는 verdict, condition, action, reason 네 개를 모두 포함해야 합니다.

verdict는 반드시 다음 중 하나여야 합니다:
알수없음, 일반쓰레기, 플라스틱, 종이류, 유리, 캔, 비닐, 스티로폼, 음식물, 특수폐기물

condition은 반드시 다음 중 하나이거나 null이어야 합니다:
세척 필요, 라벨·테이프 제거 필요, 부품 분리 필요, null

이미지에 분리배출할 폐기물이나 물품이 명확히 보이지 않으면 verdict는 반드시 "알수없음"으로 응답하세요.
사람 얼굴, 신체, 배경, 화면, 문서처럼 폐기물로 판단할 수 없는 대상도 "알수없음"입니다.
"알수없음"일 때 condition은 null이고, action은 폐기물만 다시 촬영해 달라는 안내로 작성하세요.

응답 형식:
{
  "verdict": "플라스틱",
  "condition": "세척 필요",
  "action": "물로 3회 헹군 뒤 라벨을 제거하고 플라스틱 수거함에 배출하세요.",
  "reason": "PP 재질 용기로 보이며 표면에 기름 오염이 확인됩니다."
}
""".strip()

TEXT_PROMPT = """
당신은 한국 분리배출 전문가입니다.
사용자가 설명한 물품의 재질, 오염 상태, 라벨/테이프 부착 여부, 복합 재질 여부를 판단하세요.

반드시 JSON 객체 하나만 응답하세요. 마크다운 코드블록이나 설명 문장은 넣지 마세요.
응답 필드는 verdict, condition, action, reason 네 개를 모두 포함해야 합니다.

verdict는 반드시 다음 중 하나여야 합니다:
알수없음, 일반쓰레기, 플라스틱, 종이류, 유리, 캔, 비닐, 스티로폼, 음식물, 특수폐기물

condition은 반드시 다음 중 하나이거나 null이어야 합니다:
세척 필요, 라벨·테이프 제거 필요, 부품 분리 필요, null

사용자 설명이 분리배출할 폐기물이나 물품을 가리키지 않으면 verdict는 반드시 "알수없음"으로 응답하세요.
"알수없음"일 때 condition은 null이고, action은 폐기물을 다시 설명해 달라는 안내로 작성하세요.

판단이 애매하면 재활용 가능성보다 실제 분리배출 기준과 오염 상태를 우선하세요.

응답 형식:
{
  "verdict": "일반쓰레기",
  "condition": null,
  "action": "기름 오염이 심해 재활용이 어렵습니다. 종량제 봉투에 넣어 배출하세요.",
  "reason": "기름이 많이 묻은 플라스틱 용기는 선별 과정에서 재활용 품질을 낮출 수 있습니다."
}
""".strip()


class GeminiError(Exception):
    """Base exception for Gemini integration failures."""


class GeminiConfigurationError(GeminiError):
    """Raised when Gemini credentials are missing or invalid locally."""


class GeminiResponseError(GeminiError):
    """Raised when Gemini returns an unusable response."""


def _load_env() -> None:
    load_dotenv(BACKEND_DIR / ".env")


def _load_api_key() -> str:
    _load_env()
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise GeminiConfigurationError("GEMINI_API_KEY is not configured.")
    return api_key


def _configured_model_name() -> str:
    _load_env()
    model_name = os.getenv("GEMINI_MODEL")
    if model_name and model_name.strip():
        return model_name.strip()
    return DEFAULT_GEMINI_MODEL


def _build_model(model_name: str) -> genai.GenerativeModel:
    genai.configure(api_key=_load_api_key())
    return genai.GenerativeModel(model_name)


def _extract_json(text: str) -> dict[str, Any]:
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        start = text.find("{")
        end = text.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise
        return json.loads(text[start : end + 1])


def _normalize_payload(payload: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(payload)

    if "verdict" in normalized:
        normalized["verdict"] = _normalize_verdict(normalized["verdict"])

    if "condition" in normalized:
        normalized["condition"] = _normalize_condition(normalized["condition"])

    if "action" in normalized and isinstance(normalized["action"], str):
        normalized["action"] = normalized["action"].strip()

    if "reason" in normalized and isinstance(normalized["reason"], str):
        normalized["reason"] = normalized["reason"].strip()

    if _should_mark_unknown(normalized):
        normalized["verdict"] = "알수없음"
        normalized["condition"] = None

    return normalized


def _normalize_verdict(value: Any) -> Any:
    if not isinstance(value, str):
        return value

    normalized = _compact_text(value)
    aliases = {
        "알수없음": "알수없음",
        "알수없다": "알수없음",
        "알수없습니다": "알수없음",
        "판단불가": "알수없음",
        "판단할수없음": "알수없음",
        "판단할수없다": "알수없음",
        "판단할수없습니다": "알수없음",
        "분류불가": "알수없음",
        "확인불가": "알수없음",
        "인식불가": "알수없음",
        "대상아님": "알수없음",
        "해당없음": "알수없음",
        "쓰레기아님": "알수없음",
        "폐기물아님": "알수없음",
        "분리배출대상아님": "알수없음",
        "unknown": "알수없음",
        "일반쓰레기": "일반쓰레기",
        "일반폐기물": "일반쓰레기",
        "종량제": "일반쓰레기",
        "플라스틱": "플라스틱",
        "페트": "플라스틱",
        "페트병": "플라스틱",
        "종이": "종이류",
        "종이류": "종이류",
        "종이팩": "종이류",
        "유리": "유리",
        "유리류": "유리",
        "유리병": "유리",
        "캔": "캔",
        "캔류": "캔",
        "금속캔": "캔",
        "알루미늄캔": "캔",
        "비닐": "비닐",
        "비닐류": "비닐",
        "스티로폼": "스티로폼",
        "스티로폼류": "스티로폼",
        "음식물": "음식물",
        "음식물쓰레기": "음식물",
        "특수폐기물": "특수폐기물",
        "특수쓰레기": "특수폐기물",
    }
    return aliases.get(normalized, value.strip())


def _normalize_condition(value: Any) -> Any:
    if isinstance(value, list):
        value = next((item for item in value if item), None)

    if value is None:
        return None

    if not isinstance(value, str):
        return value

    normalized = _compact_text(value)
    if normalized in {"", "null", "none", "없음", "조건없음", "해당없음", "불필요"}:
        return None

    if "세척" in normalized or "헹굼" in normalized or "오염제거" in normalized:
        return "세척 필요"

    if "라벨" in normalized or "테이프" in normalized or "스티커" in normalized:
        return "라벨·테이프 제거 필요"

    if "분리" in normalized or "분해" in normalized or "부품" in normalized:
        return "부품 분리 필요"

    return value.strip()


def _compact_text(value: str) -> str:
    return (
        value.strip()
        .lower()
        .replace(" ", "")
        .replace("·", "")
        .replace("/", "")
        .replace("-", "")
        .replace("_", "")
    )


def _should_mark_unknown(payload: dict[str, Any]) -> bool:
    if payload.get("verdict") == "알수없음":
        return True

    if payload.get("verdict") != "일반쓰레기":
        return False

    text = " ".join(
        str(payload.get(key, ""))
        for key in ("action", "reason")
        if payload.get(key) is not None
    )
    compacted_text = _compact_text(text)
    return any(indicator in compacted_text for indicator in UNKNOWN_RESULT_INDICATORS)


def _validate_scan_result(payload: dict[str, Any]) -> ScanResult:
    if not isinstance(payload, dict):
        raise GeminiResponseError("Gemini response JSON must be an object.")

    try:
        return ScanResult.model_validate(_normalize_payload(payload))
    except ValidationError as exc:
        raise GeminiResponseError("Gemini response does not match ScanResult schema.") from exc


def _response_text(response: Any) -> str:
    try:
        text = response.text
    except ValueError as exc:
        raise GeminiResponseError("Gemini response did not include text.") from exc

    if not text or not text.strip():
        raise GeminiResponseError("Gemini response was empty.")
    return text.strip()


def _generate_image_analysis(image_bytes: bytes, mime_type: str) -> ScanResult:
    model_name = _configured_model_name()
    try:
        return _generate_image_analysis_with_model(model_name, image_bytes, mime_type)
    except GeminiConfigurationError:
        raise
    except GeminiResponseError as exc:
        logger.warning(
            "Gemini model %s returned an unusable response: %s",
            model_name,
            exc,
        )
        raise
    except Exception as exc:
        logger.warning(
            "Gemini model %s failed during image analysis",
            model_name,
            exc_info=True,
        )
        raise GeminiResponseError("Gemini API call failed.") from exc


def _generate_image_analysis_with_model(
    model_name: str,
    image_bytes: bytes,
    mime_type: str,
) -> ScanResult:
    return _generate_scan_result(
        model_name,
        [
            PROMPT,
            {
                "mime_type": mime_type,
                "data": image_bytes,
            },
        ],
    )


def _generate_text_analysis(message: str) -> ScanResult:
    model_name = _configured_model_name()
    try:
        return _generate_text_analysis_with_model(model_name, message)
    except GeminiConfigurationError:
        raise
    except GeminiResponseError as exc:
        logger.warning(
            "Gemini model %s returned an unusable text response: %s",
            model_name,
            exc,
        )
        raise
    except Exception as exc:
        logger.warning(
            "Gemini model %s failed during text analysis",
            model_name,
            exc_info=True,
        )
        raise GeminiResponseError("Gemini API call failed.") from exc


def _generate_text_analysis_with_model(model_name: str, message: str) -> ScanResult:
    return _generate_scan_result(model_name, _build_text_contents(message))


def _build_text_contents(message: str) -> list[str]:
    context = rag.retrieve_context(message)
    contents = [TEXT_PROMPT]
    if context:
        contents.append(f"참고 분리배출 기준:\n{context}")
    contents.append(f"사용자 설명:\n{message}")
    return contents


def _generate_scan_result(model_name: str, contents: list[Any]) -> ScanResult:
    model = _build_model(model_name)
    response = model.generate_content(
        contents,
        generation_config=GenerationConfig(
            temperature=0.1,
            max_output_tokens=2048,
            response_mime_type="application/json",
            response_schema=SCAN_RESULT_RESPONSE_SCHEMA,
        ),
        request_options={"timeout": 40},
    )

    try:
        payload = _extract_json(_response_text(response))
    except (json.JSONDecodeError, TypeError) as exc:
        raise GeminiResponseError("Gemini response was not valid JSON.") from exc

    return _validate_scan_result(payload)


async def analyze_image(image_bytes: bytes, mime_type: str) -> ScanResult:
    try:
        return await asyncio.to_thread(_generate_image_analysis, image_bytes, mime_type)
    except GeminiError:
        raise
    except Exception as exc:
        logger.exception("Gemini image analysis failed")
        raise GeminiResponseError("Gemini API call failed.") from exc


async def analyze_text(message: str) -> ScanResult:
    try:
        return await asyncio.to_thread(_generate_text_analysis, message)
    except GeminiError:
        raise
    except Exception as exc:
        logger.exception("Gemini text analysis failed")
        raise GeminiResponseError("Gemini API call failed.") from exc
