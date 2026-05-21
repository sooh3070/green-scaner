# Git 규칙

## 브랜치 구조

각자 **자신의 이름으로 브랜치 하나**를 만들고, 그 브랜치에서만 작업합니다.
`main` 브랜치에 직접 push하지 않습니다.

```
main
 ├── sooh        # 팀원 A
 ├── hyunwoo     # 팀원 B
 └── jiyeon      # 팀원 C
```

---

## 기본 작업 흐름

### 1. 내 브랜치에서 작업 후 main에 올리기

```bash
# 작업 후 커밋
git add .
git commit -m "feat: 카메라 스캔 UI 추가"

# 내 브랜치 push
git push origin 내이름

# GitHub에서 내이름 → main PR 생성 후 머지
```

### 2. 다른 팀원 작업 내려받기 (main 싱크 맞추기)

```bash
# main 최신화
git checkout main
git pull origin main

# 내 브랜치로 돌아와서 main 머지
git checkout 내이름
git merge main
```

---

## 커밋 메시지 규칙

```
feat: 카메라 스캔 UI 추가
fix: BLE 연결 끊김 버그 수정
chore: 패키지 추가
docs: 문서 업데이트
```

---

## 주의 사항

- `main` 직접 push 금지
- `.env` 파일 절대 커밋 금지
