# MultiTUI Base — OpenCode + DooD essentials only
# No language runtimes. Stack-specific images extend this.
FROM alpine:3.23

ARG HOST_UID=1000
ARG HOST_GID=1000

ENV DOCKER_VERSION=29.2.1
ENV DOCKER_COMPOSE_VERSION=2.35.1

RUN apk add --no-cache \
    nodejs \
    npm \
    git \
    curl \
    ca-certificates \
    bash \
    sudo \
    shadow \
    openssh-client \
    ripgrep \
    jq && \
    curl -fsSL "https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_VERSION}.tgz" | \
    tar xz -C /usr/local/bin --strip-components=1 docker/docker && \
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    ARCH=$(uname -m) && \
    curl -fsSL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${ARCH}" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose && \
    rm -rf /tmp/* /var/cache/apk/*

RUN addgroup -g 998 docker 2>/dev/null || true && \
    addgroup -g $HOST_GID dev && \
    adduser -D -u $HOST_UID -G dev -s /bin/bash dev && \
    addgroup dev docker && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER dev
WORKDIR /home/dev

RUN mkdir -p /home/dev/.config

RUN npm config set prefix /home/dev/.npm-global

ENV PATH="/home/dev/.opencode/bin:/home/dev/.npm-global/bin:/usr/local/bin:/root/.local/bin:${PATH}"
RUN echo 'export PATH="/home/dev/.opencode/bin:/home/dev/.npm-global/bin:/usr/local/bin:${HOME}/.local/bin:${PATH}"' >> /home/dev/.bashrc

ARG OPENCODE_VERSION

RUN if [ -n "$OPENCODE_VERSION" ]; then \
      curl -fsSL https://opencode.ai/install | bash -s -- --version "${OPENCODE_VERSION#v}"; \
    else \
      curl -fsSL https://opencode.ai/install | bash; \
    fi && \
    npm install -g \
      @modelcontextprotocol/server-memory \
      @modelcontextprotocol/server-sequential-thinking

RUN hash -r

# OpenCode configuration
ENV OPENCODE_CONFIG_DIR=/workspace/.opencode \
    OPENCODE_DATA_DIR=/workspace/.opencode-data \
    OPENCODE_CACHE_DIR=/workspace/.opencode-cache \
    OPENCODE_STATE_DIR=/workspace/.opencode-state \
    OPENCODE_LOG_DIR=/workspace/.opencode-log \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Create writable OpenCode runtime directories
RUN mkdir -p /workspace/.opencode-data /workspace/.opencode-cache /workspace/.opencode-state /workspace/.opencode-log && \
    chown -R dev:dev /workspace/.opencode* && \
    chmod 700 /workspace/.opencode-data /workspace/.opencode-state && \
    chmod 755 /workspace/.opencode-cache /workspace/.opencode-log

USER root
RUN rm -rf /tmp/* /var/cache/apk/* /home/dev/.cache /root/.local /root/.config /root/.npm
USER dev

WORKDIR /workspace

HEALTHCHECK --interval=30s --timeout=5s --retries=2 \
  CMD node -e "process.exit(0)" || exit 1

LABEL org.opencontainers.image.title="multitui" \
      org.opencontainers.image.description="OpenCode DooD environment" \
      org.opencontainers.image.version="0.2.0"

CMD ["bash"]
