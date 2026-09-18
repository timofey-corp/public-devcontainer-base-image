# README.md
> WARNING: This is an experimental repo. Which may break at any time.

This is a base image made for devcontainer, preconfigured with tools like
node, claude code, codex, htmlq, pandoc, with support for arm64 & amd64 
architectures.

To learn about devcontainer, see https://devcontainers.github.io/

## Installed tools
Built on `mcr.microsoft.com/devcontainers/base:trixie` (Debian 13), plus:

- Node.js (latest LTS, with npm)
- pnpm
- Claude Code
- Codex
- htmlq
- pandoc
- tmux
- ripgrep

Each tool is the latest release at build time. The image rebuilds nightly
whenever one of them, or the base image, has a new version.
