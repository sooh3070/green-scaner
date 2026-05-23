import json
import sys
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from app.main import app  # noqa: E402
from app.schemas import ScanResult  # noqa: E402
from app.services import gemini  # noqa: E402


VALID_SCAN_RESULT = {
    "verdict": "플라스틱",
    "condition": "세척 필요",
    "action": "물로 헹군 뒤 라벨을 제거하고 플라스틱으로 배출하세요.",
    "reason": "플라스틱 용기로 보이며 내용물 오염이 남아 있습니다.",
}


class ChatApiTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.original_analyze_text = gemini.analyze_text

    def tearDown(self):
        gemini.analyze_text = self.original_analyze_text

    async def test_chat_returns_scan_result_json(self):
        async def fake_analyze_text(message: str) -> ScanResult:
            self.assertEqual(message, "기름 묻은 플라스틱 컵")
            return ScanResult(**VALID_SCAN_RESULT)

        gemini.analyze_text = fake_analyze_text

        status_code, body = await _post_json(
            "/chat/",
            {"message": "기름 묻은 플라스틱 컵"},
        )

        self.assertEqual(status_code, 200)
        self.assertEqual(body, VALID_SCAN_RESULT)

    async def test_chat_rejects_blank_message(self):
        async def fail_if_called(message: str) -> ScanResult:
            self.fail("blank messages should fail before Gemini is called")

        gemini.analyze_text = fail_if_called

        status_code, body = await _post_json("/chat/", {"message": "   \n\t  "})

        self.assertEqual(status_code, 400)
        self.assertEqual(body, {"detail": "잘못된 요청입니다."})

    async def test_chat_returns_500_when_gemini_configuration_fails(self):
        async def fake_analyze_text(message: str) -> ScanResult:
            raise gemini.GeminiConfigurationError("GEMINI_API_KEY is not configured.")

        gemini.analyze_text = fake_analyze_text

        status_code, body = await _post_json("/chat/", {"message": "종이컵"})

        self.assertEqual(status_code, 500)
        self.assertEqual(body, {"detail": "GEMINI_API_KEY가 설정되어 있지 않습니다."})

    async def test_chat_returns_500_when_gemini_response_is_invalid(self):
        async def fake_analyze_text(message: str) -> ScanResult:
            raise gemini.GeminiResponseError("Gemini response was not valid JSON.")

        gemini.analyze_text = fake_analyze_text

        status_code, body = await _post_json("/chat/", {"message": "종이컵"})

        self.assertEqual(status_code, 500)
        self.assertEqual(body, {"detail": "텍스트를 분석할 수 없습니다."})


async def _post_json(path: str, payload: dict) -> tuple[int, dict]:
    request_body = json.dumps(payload).encode("utf-8")
    response_events = []
    request_sent = False

    scope = {
        "type": "http",
        "asgi": {"version": "3.0", "spec_version": "2.3"},
        "http_version": "1.1",
        "method": "POST",
        "scheme": "http",
        "path": path,
        "raw_path": path.encode("ascii"),
        "query_string": b"",
        "headers": [
            (b"host", b"testserver"),
            (b"content-type", b"application/json"),
            (b"content-length", str(len(request_body)).encode("ascii")),
        ],
        "client": ("testclient", 50000),
        "server": ("testserver", 80),
    }

    async def receive():
        nonlocal request_sent
        if request_sent:
            return {"type": "http.disconnect"}
        request_sent = True
        return {"type": "http.request", "body": request_body, "more_body": False}

    async def send(message):
        response_events.append(message)

    await app(scope, receive, send)

    status_code = next(
        event["status"]
        for event in response_events
        if event["type"] == "http.response.start"
    )
    body = b"".join(
        event.get("body", b"")
        for event in response_events
        if event["type"] == "http.response.body"
    )
    return status_code, json.loads(body.decode("utf-8"))


if __name__ == "__main__":
    unittest.main()
