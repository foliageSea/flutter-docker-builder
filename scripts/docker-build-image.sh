#!/usr/bin/env bash
set -euo pipefail

BUILDER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.6}"
NODE_VERSION="${NODE_VERSION:-22.11.0}"
PNPM_VERSION="${PNPM_VERSION:-9.15.2}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-35}"
ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-35.0.0}"
ANDROID_NDK="${ANDROID_NDK:-27.0.12077973}"
ANDROID_EXTRA_PACKAGES="${ANDROID_EXTRA_PACKAGES:-platforms;android-31,platforms;android-34,platforms;android-36,cmake;3.22.1}"
IMAGE_NAME="${IMAGE_NAME:-flutter-android-builder:flutter-${FLUTTER_VERSION}}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required but was not found in PATH." >&2
  exit 1
fi

DOCKER_BUILD_ARGS=()
if [[ "${DOCKER_BUILD_NO_CACHE:-0}" == "1" ]]; then
  DOCKER_BUILD_ARGS+=(--no-cache)
fi

if [[ "${DOCKER_BUILD_NO_CACHE:-0}" != "1" ]] && docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
  echo "Docker image exists, skipping build: ${IMAGE_NAME}"
else
  echo "Building Docker image: ${IMAGE_NAME}"
  docker build \
    "${DOCKER_BUILD_ARGS[@]}" \
    --build-arg "FLUTTER_VERSION=${FLUTTER_VERSION}" \
    --build-arg "NODE_VERSION=${NODE_VERSION}" \
    --build-arg "PNPM_VERSION=${PNPM_VERSION}" \
    --build-arg "ANDROID_PLATFORM=${ANDROID_PLATFORM}" \
    --build-arg "ANDROID_BUILD_TOOLS=${ANDROID_BUILD_TOOLS}" \
    --build-arg "ANDROID_NDK=${ANDROID_NDK}" \
    --build-arg "ANDROID_EXTRA_PACKAGES=${ANDROID_EXTRA_PACKAGES}" \
    -f "${BUILDER_ROOT}/docker/Dockerfile" \
    -t "${IMAGE_NAME}" \
    "${BUILDER_ROOT}"
fi
