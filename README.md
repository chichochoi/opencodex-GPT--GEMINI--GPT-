# OpenCodex GPT -> Gemini -> GPT Harness

Codex의 기본 GPT 모델이 문제를 분석하고, 구현 단위를 지정된 워커 모델에 위임한 뒤, 결과를 다시 GPT가 검토하도록 설정하는 설치형 하네스입니다.

## 보장하는 동작

- 기본 오케스트레이터: `gpt-5.6-terra`
- 기본 추론 강도: `high`
- 구현 워커 roster: `google-antigravity/gemini-3.8-flash`, `korea-llm/gemini-3.8-flash`, `korea-llm/gpt-5.6-luna`, `gpt-5.6-luna`
- Gemini 작업: `google-antigravity/gemini-3.8-flash`와 Google Antigravity OAuth를 우선 사용
- Gemini API 키 기반 `google`/`google-vertex` provider는 사용하지 않음
- 일반적인 subagent fallback 목록은 비워 조용한 provider 전환을 막음
- Antigravity Gemini가 토큰을 소진한 경우에만 injection policy가 `korea-llm/gpt-5.6-luna` 위임을 허용
- GPT가 워커 결과를 검토하고, 실패 시 더 작은 작업으로 재위임
- Codex 실행 시 로컬 OpenCodex 프록시와 모델 카탈로그를 사용

> 사용자는 각자 Codex/ChatGPT 로그인과 Google Antigravity OAuth 승인을 완료해야 합니다. 인증 정보, API 키, OAuth 토큰, 사용자별 경로는 저장소에 포함되지 않습니다. 모델 접근 권한과 quota는 각 provider 계정 정책에 따릅니다.

## 요구 사항

- Node.js 20 이상과 npm
- Codex CLI 또는 Codex Desktop
- OpenAI 계정 로그인
- Google Antigravity OAuth 계정
- `korea-llm` 모델을 사용하려면 별도 provider 인증 및 모델 권한

## Windows 설치

PowerShell에서 저장소를 복제한 뒤 실행합니다.

```powershell
git clone https://github.com/chichochoi/opencodex-GPT--GEMINI--GPT-.git
cd opencodex-GPT--GEMINI--GPT-
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

브라우저가 열리면 Google Antigravity OAuth를 승인합니다. 설치가 끝나면 Codex Desktop을 완전히 종료한 뒤 다시 실행합니다.

## macOS / Linux 설치

```bash
git clone https://github.com/chichochoi/opencodex-GPT--GEMINI--GPT-.git
cd opencodex-GPT--GEMINI--GPT-
chmod +x scripts/install.sh scripts/verify.sh
./scripts/install.sh
```

macOS는 LaunchAgent, Linux는 systemd user service를 설치합니다. GUI 로그인 없이 부팅 직후부터 실행해야 하는 Linux 서버는 별도의 system service가 필요합니다.

## 검증

Windows:

```powershell
.\scripts\verify.ps1
.\scripts\test-loop.ps1
```

macOS / Linux:

```bash
./scripts/verify.sh
```

검증은 proxy 상태, 워커 roster, fallback 비활성화, OAuth 계정, `multi_agent_v2`, 기본 모델과 추론 강도, 전역 정책, 자동 시작 등록을 확인합니다.

## 기존 설치에 적용

기존 OpenCodex를 유지하려면 Windows에서 다음 옵션을 사용할 수 있습니다.

```powershell
.\scripts\install.ps1 -SkipOpenCodexInstall
```

설치기는 `~/.codex/config.toml`과 `~/.codex/AGENTS.md`를 수정하기 전에 타임스탬프가 붙은 백업을 만듭니다. `AGENTS.md`의 다른 사용자 지침은 보존하고 하네스 표시 블록만 갱신합니다.

## 작동 구조

상세 흐름은 [docs/architecture.md](docs/architecture.md), 장애 대응은 [docs/troubleshooting.md](docs/troubleshooting.md)를 참고하십시오.

## 주의

OpenCodex는 독립 프로젝트이며 이 저장소는 OpenCodex 설정 하네스입니다. 설치 전 스크립트를 검토하고, OAuth 토큰이나 `~/.opencodex`, `~/.codex` 디렉터리를 Git에 커밋하지 마십시오.
