#!/usr/bin/env bash
set -euo pipefail

BUILD_WORKDIR="${BUILD_WORKDIR:-/workspace}"
ANDROID_PROJECT_DIR="${ANDROID_PROJECT_DIR:-android}"
BUILD_COMMAND="${BUILD_COMMAND:-flutter build apk --release}"
PRE_BUILD_COMMAND="${PRE_BUILD_COMMAND:-}"
POST_BUILD_COMMAND="${POST_BUILD_COMMAND:-}"
FLUTTER_SDK="${FLUTTER_ROOT:-/root/fvm/versions/3.35.6}"
LOCAL_PROPERTIES="${BUILD_WORKDIR}/${ANDROID_PROJECT_DIR}/local.properties"
LOCAL_PROPERTIES_BACKUP=""
LOCAL_PROPERTIES_EXISTED=0

cleanup() {
  rm -f /root/.netrc

  if [[ "${LOCAL_PROPERTIES_EXISTED}" == "1" && -n "${LOCAL_PROPERTIES_BACKUP}" && -f "${LOCAL_PROPERTIES_BACKUP}" ]]; then
    cp "${LOCAL_PROPERTIES_BACKUP}" "${LOCAL_PROPERTIES}"
    rm -f "${LOCAL_PROPERTIES_BACKUP}"
  elif [[ "${LOCAL_PROPERTIES_EXISTED}" == "0" ]]; then
    rm -f "${LOCAL_PROPERTIES}"
  fi
}
trap cleanup EXIT

if [[ ! -d "${BUILD_WORKDIR}" ]]; then
  echo "BUILD_WORKDIR does not exist: ${BUILD_WORKDIR}" >&2
  exit 1
fi

if [[ ! -d "${BUILD_WORKDIR}/${ANDROID_PROJECT_DIR}" ]]; then
  echo "Android project directory does not exist: ${BUILD_WORKDIR}/${ANDROID_PROJECT_DIR}" >&2
  exit 1
fi

cd "${BUILD_WORKDIR}"
git config --global --add safe.directory "${BUILD_WORKDIR}" || true

if [[ -n "${GIT_USERNAME:-}" || -n "${GIT_TOKEN:-}" ]]; then
  if [[ -z "${GIT_HOST:-}" || -z "${GIT_USERNAME:-}" || -z "${GIT_TOKEN:-}" ]]; then
    echo "GIT_HOST, GIT_USERNAME and GIT_TOKEN must be set together." >&2
    exit 1
  fi

  cat > /root/.netrc <<EOF
machine ${GIT_HOST}
login ${GIT_USERNAME}
password ${GIT_TOKEN}
EOF
  chmod 600 /root/.netrc
fi

npm config set registry "${NPM_CONFIG_REGISTRY:-https://registry.npmmirror.com}"
pnpm config set registry "${NPM_CONFIG_REGISTRY:-https://registry.npmmirror.com}"
pnpm config set store-dir /root/.pnpm-store

export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"
export GRADLE_USER_HOME="/root/.gradle"
export PATH="${FLUTTER_SDK}/bin:${FLUTTER_SDK}/bin/cache/dart-sdk/bin:/root/.pub-cache/bin:${PATH}"

mkdir -p "${GRADLE_USER_HOME}"
cp /builder/docker/gradle/init.gradle "${GRADLE_USER_HOME}/init.gradle"

if [[ -f "${LOCAL_PROPERTIES}" ]]; then
  LOCAL_PROPERTIES_EXISTED=1
  LOCAL_PROPERTIES_BACKUP="$(mktemp)"
  cp "${LOCAL_PROPERTIES}" "${LOCAL_PROPERTIES_BACKUP}"
fi

cat > "${LOCAL_PROPERTIES}" <<EOF
sdk.dir=${ANDROID_HOME}
flutter.sdk=${FLUTTER_SDK}
EOF

echo "Using Flutter: $(flutter --version | head -n 1)"
echo "Using Node: $(node --version)"
echo "Using pnpm: $(pnpm --version)"

flutter doctor -v

if [[ -n "${PRE_BUILD_COMMAND}" ]]; then
  bash -lc "${PRE_BUILD_COMMAND}"
fi

bash -lc "${BUILD_COMMAND}"

if [[ -n "${POST_BUILD_COMMAND}" ]]; then
  bash -lc "${POST_BUILD_COMMAND}"
fi
