#!/usr/bin/env bash
# Smoke test for the prebuilt devcontainer image. Run inside the image:
#
#   docker run --rm -v "$PWD/.github/scripts:/smoke:ro" <image> \
#     bash /smoke/devcontainer-image-smoke.sh
#
# When changing the tool set, update this script AND the Dockerfile at the
# repo root AND devcontainer-image-versions.sh.
set -Eeuxo pipefail

# One tool per check: multi-arg `command -v` succeeds if ANY name resolves,
# which would let a missing tool slip through.
for tool in htmlq pandoc tmux rg claude codex node npm pnpm; do
  command -v "${tool}" > /dev/null || { echo "missing: ${tool}" >&2; exit 1; }
done

htmlq --version
tmux -V
rg --version
pandoc --version
claude --version
codex --version
node --version
npm --version
pnpm --version

echo "smoke test passed"
