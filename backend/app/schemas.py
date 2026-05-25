from typing import Literal

from pydantic import BaseModel, Field, field_validator


VERDICT_VALUES = (
    "알수없음",
    "일반쓰레기",
    "플라스틱",
    "종이류",
    "유리",
    "캔",
    "비닐",
    "스티로폼",
    "음식물",
    "특수폐기물",
)

CONDITION_VALUES = (
    "세척 필요",
    "라벨·테이프 제거 필요",
    "부품 분리 필요",
)

Verdict = Literal[
    "알수없음",
    "일반쓰레기",
    "플라스틱",
    "종이류",
    "유리",
    "캔",
    "비닐",
    "스티로폼",
    "음식물",
    "특수폐기물",
]

Condition = Literal[
    "세척 필요",
    "라벨·테이프 제거 필요",
    "부품 분리 필요",
]


class ScanResult(BaseModel):
    verdict: Verdict
    condition: Condition | None
    pollution: int = Field(ge=0, le=100)
    action: str = Field(min_length=1)
    reason: str = Field(min_length=1)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, strict=True)

    @field_validator("message")
    @classmethod
    def strip_message(cls, value: str) -> str:
        message = value.strip()
        if not message:
            raise ValueError("message must not be blank.")
        return message
