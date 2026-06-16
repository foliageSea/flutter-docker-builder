#!/usr/bin/env bash
set -euo pipefail

BUILDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.6}"
IMAGE_NAME="${IMAGE_NAME:-flutter-android-builder:flutter-${FLUTTER_VERSION}}"
CACHE_ROOT="${CACHE_ROOT:-${PROJECT_DIR}/.docker-cache}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required but was not found in PATH." >&2
  exit 1
fi

if [[ ! -d "${PROJECT_DIR}" ]]; then
  echo "PROJECT_DIR does not exist: ${PROJECT_DIR}" >&2
  exit 1
fi

mkdir -p \
  "${CACHE_ROOT}/pub" \
  "${CACHE_ROOT}/gradle/caches" \
  "${CACHE_ROOT}/gradle/wrapper" \
  "${CACHE_ROOT}/pnpm-store"

DOCKER_ENV_ARGS=(
  -e "ANDROID_PROJECT_DIR=${ANDROID_PROJECT_DIR:-android}"
  -e "BUILD_WORKDIR=${BUILD_WORKDIR:-/workspace}"
  -e "BUILD_COMMAND=${BUILD_COMMAND:-flutter build apk --release}"
  -e "PRE_BUILD_COMMAND=${PRE_BUILD_COMMAND:-}"
  -e "POST_BUILD_COMMAND=${POST_BUILD_COMMAND:-}"
  -e "PUB_HOSTED_URL=${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
  -e "FLUTTER_STORAGE_BASE_URL=${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
  -e "NPM_CONFIG_REGISTRY=${NPM_CONFIG_REGISTRY:-https://registry.npmmirror.com}"
  -e "CI=${CI:-true}"
)

if [[ -n "${GIT_HOST:-}" ]]; then
  DOCKER_ENV_ARGS+=(-e "GIT_HOST=${GIT_HOST}")
fi
if [[ -n "${GIT_USERNAME:-}" ]]; then
  DOCKER_ENV_ARGS+=(-e "GIT_USERNAME=${GIT_USERNAME}")
fi
if [[ -n "${GIT_TOKEN:-}" ]]; then
  DOCKER_ENV_ARGS+=(-e "GIT_TOKEN=${GIT_TOKEN}")
fi

echo "Running Android build in Docker..."
MSYS_NO_PATHCONV=1 docker run --rm \
  "${DOCKER_ENV_ARGS[@]}" \
  -v "${PROJECT_DIR}:/workspace" \
  -v "${BUILDER_ROOT}:/builder:ro" \
  -v "${CACHE_ROOT}/pub:/root/.pub-cache" \
  -v "${CACHE_ROOT}/gradle/caches:/root/.gradle/caches" \
  -v "${CACHE_ROOT}/gradle/wrapper:/root/.gradle/wrapper" \
  -v "${CACHE_ROOT}/pnpm-store:/root/.pnpm-store" \
  -w /workspace \
  "${IMAGE_NAME}" \
  bash /builder/scripts/container-build-android.sh

echo "Build finished. Check the target project's build output directory."
