FROM rust:1 AS htmlq-builder
RUN cargo install --locked htmlq --root /opt/htmlq

FROM mcr.microsoft.com/devcontainers/base:trixie
ARG TARGETARCH
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Opt out of tracking
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
    CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1 \
    CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1

RUN printf '%s\n' \
      "DISABLE_TELEMETRY=1" \
      "DO_NOT_TRACK=1" \
      "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1" \
      "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1" \
      "CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL=1" \
      >> /etc/environment

# tmux and ripgrep (Codex uses rg) from Debian; pandoc from its official .deb
# (Debian's pandoc lags far behind upstream releases).
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends tmux ripgrep \
 && loc="$(curl -fsSI https://github.com/jgm/pandoc/releases/latest | awk 'tolower($1) == "location:" && !found { found = 1; sub(/\r$/, "", $2); print $2 }')" \
 && ver="${loc##*/}" \
 && [ -n "${ver}" ] && [ "${ver}" != "releases" ] \
 && curl -fsSLo /tmp/pandoc.deb "https://github.com/jgm/pandoc/releases/download/${ver}/pandoc-${ver}-1-${TARGETARCH}.deb" \
 && apt-get install -y --no-install-recommends /tmp/pandoc.deb \
 && rm -f /tmp/pandoc.deb \
 && rm -rf /var/lib/apt/lists/*

# Node.js LTS — official tarball from nodejs.org, checksum-verified
RUN case "${TARGETARCH}" in \
      amd64) arch="x64" ;; \
      arm64) arch="arm64" ;; \
      *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && version="$(curl -fsSL https://nodejs.org/dist/index.json | jq -re '[.[] | select(.lts != false)][0].version')" \
 && [[ "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] \
 && tarball="node-${version}-linux-${arch}.tar.gz" \
 && cd /tmp \
 && curl -fsSLo "${tarball}" "https://nodejs.org/dist/${version}/${tarball}" \
 && curl -fsSL "https://nodejs.org/dist/${version}/SHASUMS256.txt" | grep -F "  ${tarball}" | sha256sum -c - \
 && tar -xzf "${tarball}" -C /usr/local --strip-components=1 --no-same-owner \
 && rm -f "${tarball}" \
 && ln -sf node /usr/local/bin/nodejs \
 && node --version && npm --version

# Claude Code — Anthropic's native installer. It executes the downloaded
# binary, which is unreliable under QEMU, so CI builds each platform natively.
RUN curl -fsSL https://claude.ai/install.sh | bash -s latest \
 && ln -sf /root/.local/bin/claude /usr/local/bin/claude \
 && rm -rf /root/.claude/downloads

# Codex — official prebuilt static binary (musl)
RUN case "${TARGETARCH}" in \
      amd64) triple="x86_64-unknown-linux-musl" ;; \
      arm64) triple="aarch64-unknown-linux-musl" ;; \
      *) echo "unsupported arch: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
 && curl -fsSLo /tmp/codex.tar.gz "https://github.com/openai/codex/releases/latest/download/codex-${triple}.tar.gz" \
 && tar -xzf /tmp/codex.tar.gz -C /tmp "codex-${triple}" \
 && install -m 755 "/tmp/codex-${triple}" /usr/local/bin/codex \
 && rm -f /tmp/codex.tar.gz "/tmp/codex-${triple}"

COPY --from=htmlq-builder /opt/htmlq/bin/htmlq /usr/local/bin/htmlq

# Mouse scrolling in tmux, for both users the container may run as
RUN printf 'set -g mouse on\n' >> /root/.tmux.conf \
 && printf 'set -g mouse on\n' >> /home/vscode/.tmux.conf \
 && chown vscode:vscode /home/vscode/.tmux.conf
