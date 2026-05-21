# 개발 환경 설정

## 필수 설치

| 도구 | 버전 | 설치 링크 |
|------|------|-----------|
| Flutter (FVM) | 3.44.0 | https://fvm.app |
| Python | 3.12+ | https://python.org |
| Docker Desktop | 최신 | https://docker.com |
| Android Studio | 최신 | https://developer.android.com/studio |
| Arduino IDE | 2.x | https://arduino.cc |

---

## Flutter (FVM)

이 프로젝트는 **FVM(Flutter Version Manager)** 을 사용합니다.
`flutter` 명령어 대신 반드시 `fvm flutter`를 사용하세요.

### FVM 설치

```bash
dart pub global activate fvm
```

### Flutter 버전 설정

```bash
cd app
fvm use 3.44.0
fvm flutter pub get
```

### VS Code 설정

`.vscode/settings.json`에 아래 내용이 자동 생성됩니다.
별도 설정 없이 VS Code에서 바로 사용 가능합니다.

```json
{
  "dart.flutterSdkPath": ".fvm/versions/3.44.0"
}
```

---

## 백엔드 (Python)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 환경변수 설정

```bash
cp .env.example .env
# .env 파일에 GEMINI_API_KEY 입력
```

> **주의 — 퍼블릭 레포입니다.**  
> `.env` 파일은 `.gitignore`에 포함되어 있으므로 절대 커밋하지 마세요.  
> API 키, 개인정보가 담긴 파일을 실수로 push했다면 즉시 키를 재발급하세요.

---

## ESP32 (Arduino IDE)

1. Arduino IDE에서 보드 매니저 → `esp32` 검색 후 설치
2. `firmware/sensor_ble/sensor_ble.ino` 열기
3. 보드: `ESP32 Dev Module` 선택 후 업로드
