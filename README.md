# claude-dev-box

Ubuntu 24.04 기반 Claude Code 개발 환경 Docker 이미지.  
SSH로 접속해 Claude Code, Node.js, pnpm, tmux, zsh 등이 사전 설치된 개발 서버를 바로 사용할 수 있습니다.

## 포함 도구

| 도구 | 버전 |
|------|------|
| Ubuntu | 24.04 |
| Node.js | 20 (nvm) |
| pnpm | latest |
| Claude Code | latest |
| tmux | latest |
| zsh + Oh My Zsh | latest |
| Powerlevel10k | latest |

---

## 빠른 시작

### 1. .env 파일 생성

```env
USERNAME=devuser
USER_PASSWORD=mypassword
SSH_PORT=2222
GIT_USER_NAME=홍길동
GIT_USER_EMAIL=hello@example.com
```

### 2. docker-compose.yml 생성

```yaml
services:
  dev:
    image: ghcr.io/dusvlf111/claude-dev-box:main
    env_file:
      - .env
    ports:
      - "2222:2222"
    volumes:
      - ./workspace:/home/devuser/workspace
      - ./claude-auth:/home/devuser/.claude
    restart: unless-stopped
```
```yaml
services:
  dev:
    image: ghcr.io/dusvlf111/claude-dev-box:main
    container_name: claude-dev-box
    restart: unless-stopped
    
    # 1. 포트 설정 (호스트 2222 -> 컨테이너 2222)
    ports:
      - "2222:2222"
    
    # 2. 환경 변수 직접 설정
    environment:
      - SSH_PORT=2222
      - USERNAME=devuser
      - USER_PASSWORD=your_secure_password_here  # SSH 접속 비번
      - GIT_USER_NAME=ImSeongBin                 # Git 이름 자동 설정
      - GIT_USER_EMAIL=your-email@example.com    # Git 이메일 자동 설정
      - GITHUB_TOKEN=ghp_ABC123yourActualTokenHere
      - CLAUDE_API_KEY=${CLAUDE_API_KEY}         # 외부 환경변수에서 가져오기
    
    # 3. .env 파일 병용 (민감한 정보는 여기에)
    env_file:
      - .env
      
    # 4. 볼륨 설정
    volumes:
      - ./workspace:/home/devuser/workspace
      - ./claude-auth:/home/devuser/.claude      # Claude 인증 정보 유지
      - /var/run/docker.sock:/var/run/docker.sock # (선택) 컨테이너 안에서 도커 사용 시
      
    # 리소스 제한 (선택 사항)
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 4G
```
```
# vscode 설정
Host main-dev-server
    HostName [테일스케일IP]
    Port 2222
    User devuser
    # ⭐ 키가 바뀌어도 경고를 띄우지 않고, 새로운 키를 자동으로 저장함
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```
### 3. 실행

```bash
docker-compose up -d
```

### 4. SSH 접속

```bash
ssh devuser@localhost -p 2222
```

### 5. Claude Code 로그인 (최초 1회)

```bash
claude login
```

> 로그인 토큰은 `./claude-auth`에 저장되어 컨테이너 재시작 후에도 유지됩니다.

---

## 환경변수 설명

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `USERNAME` | `devuser` | SSH 접속 유저명 |
| `USER_PASSWORD` | `devpass123` | SSH 접속 비밀번호 |
| `SSH_PORT` | `22` | SSH 포트 |
| `GIT_USER_NAME` | - | git config user.name |
| `GIT_USER_EMAIL` | - | git config user.email |

---

## 볼륨 설명

| 호스트 경로 | 컨테이너 경로 | 설명 |
|------------|--------------|------|
| `./workspace` | `/home/devuser/workspace` | 작업 파일 영구 보존 |
| `./claude-auth` | `/home/devuser/.claude` | Claude Code 로그인 토큰 유지 |

---

