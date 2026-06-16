# AGENTS.md

## Repo Purpose

- This repo is a reusable Docker/Bash template for building Android artifacts from external Flutter projects; it is not itself a Flutter app.
- Main entrypoints are `scripts/docker-build-android.sh` for image+build, `scripts/docker-build-image.sh` for only the image, and `scripts/docker-run-android.sh` for running an existing image against `PROJECT_DIR`.

## Commands

- Build the builder image: `bash scripts/docker-build-image.sh`.
- Run a target project build with the existing image: `PROJECT_DIR=/path/to/flutter/app bash scripts/docker-run-android.sh`.
- Full flow: `PROJECT_DIR=/path/to/flutter/app BUILD_COMMAND="flutter build apk --release" bash scripts/docker-build-android.sh`.
- There is no repo-local test/lint/format task configured; verify shell changes by running the relevant script path, usually with a disposable Flutter project supplied through `PROJECT_DIR`.

## Script And Environment Gotchas

- Scripts require Bash and Docker; on Windows use Git Bash/WSL, not PowerShell for direct script execution.
- `docker-build-android.sh` always runs `docker-build-image.sh` before `docker-run-android.sh`; `docker-build-image.sh` skips rebuilding if `IMAGE_NAME` already exists unless `DOCKER_BUILD_NO_CACHE=1`.
- `PROJECT_DIR` defaults to the current directory, which is usually wrong in this repo because the scripts expect an external Flutter project mounted at `/workspace`.
- `ANDROID_PROJECT_DIR` is relative to `PROJECT_DIR` and defaults to `android`; set it for monorepos such as `apps/app/android`.
- `PRE_BUILD_COMMAND`, `BUILD_COMMAND`, and `POST_BUILD_COMMAND` run inside the container via `bash -lc` from `/workspace`.
- `container-build-android.sh` temporarily rewrites `<PROJECT_DIR>/<ANDROID_PROJECT_DIR>/local.properties` with container SDK paths and restores or removes it on exit.
- `docker-run-android.sh` sets `MSYS_NO_PATHCONV=1` for Git Bash Docker volume mounts; preserve this when touching Windows compatibility.

## Toolchain Defaults

- Keep version defaults aligned across `docker/Dockerfile`, `scripts/*.sh`, and `examples/*.example`: Flutter `3.35.6`, Node `22.11.0`, pnpm `9.15.2`, Android platform `android-35`, build-tools `35.0.0`, NDK `27.0.12077973`.
- Default mirrors are China-friendly: `PUB_HOSTED_URL=https://pub.flutter-io.cn`, `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`, and `NPM_CONFIG_REGISTRY=https://registry.npmmirror.com`.
- `docker/gradle/init.gradle` is intentionally empty; only add Gradle mirror logic if it will not conflict with target projects' `repositoriesMode` settings.

## Secrets And Generated Files

- Do not commit `.env`, `.docker-cache/`, signing files, `key.properties`, or real `GIT_TOKEN` values; these are intentionally ignored.
- Private Git credentials must be passed as `GIT_HOST`, `GIT_USERNAME`, and `GIT_TOKEN` together; the container writes a temporary `/root/.netrc` and deletes it during cleanup.

## 提交规范

- 参考格式 feat(app): 初始化
