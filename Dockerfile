FROM ubuntu:24.04

# 1. 필수 패키지 설치
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openssh-server curl git build-essential \
    zsh locales vim iproute2 procps \
    sudo tmux \
    && mkdir /var/run/sshd

# 2. 로케일 설정
RUN locale-gen ko_KR.UTF-8
ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8

# 3. 유저 생성 + sudo 권한 부여
ARG USERNAME=devuser
RUN useradd -m -s /usr/bin/zsh ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# 4. nvm 및 Node.js 설치
ENV NVM_DIR=/home/${USERNAME}/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install 20 \
    && nvm use 20 \
    && nvm alias default 20 \
    && npm install -g pnpm

# 5. Oh My Zsh 및 플러그인 설치
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# 6. Zsh / Bash 설정
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc \
    && sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc \
    && echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc \
    && echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc

# 7. tmux 기본 설정
RUN echo 'set -g default-shell /usr/bin/zsh' > ~/.tmux.conf \
    && echo 'set -g history-limit 10000' >> ~/.tmux.conf \
    && echo 'set -g mouse on' >> ~/.tmux.conf

# 8. Claude Code 설치
RUN curl -fsSL https://claude.ai/install.sh | bash

# 9. SSH 설정 및 엔트리포인트
USER root

ENV SSH_PORT=22

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config \
    && echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config

RUN printf '#!/bin/bash\n\
set -e\n\
TARGET_USER="${USERNAME:-devuser}"\n\
SSH_PORT="${SSH_PORT:-22}"\n\
echo "${TARGET_USER}:${USER_PASSWORD:-devpass123}" | chpasswd\n\
sed -i "s/^#\\?Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config\n\
if [ -n "$GIT_USER_NAME" ]; then\n\
    su - ${TARGET_USER} -c "git config --global user.name '\''$GIT_USER_NAME'\''"\n\
fi\n\
if [ -n "$GIT_USER_EMAIL" ]; then\n\
    su - ${TARGET_USER} -c "git config --global user.email '\''$GIT_USER_EMAIL'\''"\n\
fi\n\
echo "🐧 Ubuntu 24.04 개발 서버 준비 완료 (Port: ${SSH_PORT})"\n\
echo "👤 접속 유저: ${TARGET_USER}"\n\
exec /usr/sbin/sshd -D\n' > /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE ${SSH_PORT}
ENTRYPOINT ["/entrypoint.sh"]
