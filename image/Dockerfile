# Job-Image: Jeder Factory-Job läuft in einem eigenen Container aus diesem Image.
# Enthält Claude Code, GitHub CLI, git, Node, Python (uv), einen Chromium für Screenshots/E2E-Tests
# und die Werkzeuge für die Plattform-Checks.
FROM mcr.microsoft.com/playwright:v1.65.0-noble

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends git jq curl ca-certificates gnupg \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli.gpg \
 && chmod go+r /etc/apt/keyrings/githubcli.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update -qq && apt-get install -y -qq gh \
 && rm -rf /var/lib/apt/lists/*

# Playwright als globales Paket (Browser sind im Basis-Image schon vorhanden)
RUN npm install -g playwright@1.65.0 && npm cache clean --force
ENV NODE_PATH=/usr/lib/node_modules

# Werkzeuge für die Plattform-Checks (conventions/README.md): Workflows, Dockerfiles, Compose-Dateien
# und deploy/k3s/values.yaml statisch prüfen. Docker-CLI mit Compose-Plugin nur für "docker compose config",
# im Job gibt es keinen Daemon und keinen Docker-Socket. Versionen fest, Updates bewusst per PR.
ARG ACTIONLINT_VERSION=1.7.7
ARG HADOLINT_VERSION=2.12.0
ARG YQ_VERSION=4.45.1
ARG DOCKER_CLI_VERSION=28.1.1
ARG COMPOSE_VERSION=2.35.1
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN case "$(dpkg --print-architecture)" in \
      amd64) GOARCH=amd64; UNAME_M=x86_64; HADOLINT_ARCH=x86_64 ;; \
      arm64) GOARCH=arm64; UNAME_M=aarch64; HADOLINT_ARCH=arm64 ;; \
      *) echo "Architektur nicht unterstützt" >&2; exit 1 ;; \
    esac \
 && curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${GOARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin actionlint \
 && curl -fsSL -o /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-${HADOLINT_ARCH}" \
 && chmod 0755 /usr/local/bin/hadolint \
 && curl -fsSL -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${GOARCH}" \
 && chmod 0755 /usr/local/bin/yq \
 && curl -fsSL "https://download.docker.com/linux/static/stable/${UNAME_M}/docker-${DOCKER_CLI_VERSION}.tgz" \
    | tar -xz -C /usr/local/bin --strip-components=1 docker/docker \
 && mkdir -p /usr/local/lib/docker/cli-plugins \
 && curl -fsSL -o /usr/local/lib/docker/cli-plugins/docker-compose "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${UNAME_M}" \
 && chmod 0755 /usr/local/lib/docker/cli-plugins/docker-compose \
 && actionlint --version && hadolint --version && yq --version \
 && docker --version && docker compose version
SHELL ["/bin/sh", "-c"]

# Factory-Werkzeuge, Playbook, Workflow und Betriebskonventionen
COPY image/bin/ /usr/local/bin/
COPY image/entrypoint.sh /factory/entrypoint.sh
COPY image/preview.sh /factory/preview.sh
COPY image/improve.sh /factory/improve.sh
COPY playbooks/factory.md /factory/playbook.md
COPY playbooks/improve.md /factory/improve.md
COPY workflows/ /factory/workflows/
COPY conventions/ /factory/conventions/
RUN chmod +x /usr/local/bin/factory-* /factory/entrypoint.sh /factory/preview.sh /factory/improve.sh

# Claude Code als normaler Nutzer installieren (offizieller Installer)
USER pwuser
ENV HOME=/home/pwuser
RUN curl -fsSL https://claude.ai/install.sh | bash
# Python-Projekte: uv (verwaltet Python-Versionen und Pakete selbst)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH=/home/pwuser/.local/bin:$PATH
# Schema-Validierung von .factory/delivery.json (Plattform-Check "delivery-config")
ARG CHECK_JSONSCHEMA_VERSION=0.33.0
RUN uv tool install "check-jsonschema==${CHECK_JSONSCHEMA_VERSION}" && check-jsonschema --version

WORKDIR /work
ENTRYPOINT ["/factory/entrypoint.sh"]
