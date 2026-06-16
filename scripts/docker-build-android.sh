#!/usr/bin/env bash
set -euo pipefail

BUILDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash "${BUILDER_ROOT}/scripts/docker-build-image.sh"
bash "${BUILDER_ROOT}/scripts/docker-run-android.sh"
