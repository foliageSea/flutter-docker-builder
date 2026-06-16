FROM eclipse-temurin:17-jdk-jammy

ARG FLUTTER_VERSION=3.35.6
ARG NODE_VERSION=22.11.0
ARG PNPM_VERSION=9.15.2
ARG ANDROID_PLATFORM=android-35
ARG ANDROID_BUILD_TOOLS=35.0.0
ARG ANDROID_NDK=27.0.12077973
ARG ANDROID_EXTRA_PACKAGES=platforms;android-31,platforms;android-34,platforms;android-36,cmake;3.22.1

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_ROOT=/root/fvm/versions/${FLUTTER_VERSION} \
    PUB_HOSTED_URL=https://pub.flutter-io.cn \
    FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
    NPM_CONFIG_REGISTRY=https://registry.npmmirror.com \
    ANDROID_EXTRA_PACKAGES=${ANDROID_EXTRA_PACKAGES} \
    PNPM_HOME=/root/.local/share/pnpm \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    CI=true

ENV PATH=${FLUTTER_ROOT}/bin:${FLUTTER_ROOT}/bin/cache/dart-sdk/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PNPM_HOME}:/root/.pub-cache/bin:/opt/node/bin:${PATH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        libglu1-mesa \
        openssh-client \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      amd64) node_arch="x64" ;; \
      arm64) node_arch="arm64" ;; \
      *) echo "Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://npmmirror.com/mirrors/node/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" -o /tmp/node.tar.xz; \
    mkdir -p /opt/node; \
    tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1; \
    rm /tmp/node.tar.xz; \
    npm config set registry "${NPM_CONFIG_REGISTRY}"; \
    npm install -g "pnpm@${PNPM_VERSION}" --registry="${NPM_CONFIG_REGISTRY}"; \
    pnpm config set registry "${NPM_CONFIG_REGISTRY}"; \
    pnpm config set store-dir /root/.pnpm-store

RUN set -eux; \
    mkdir -p "${ANDROID_HOME}/cmdline-tools"; \
    curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/android-cmdline-tools.zip; \
    unzip -q /tmp/android-cmdline-tools.zip -d /tmp/android-cmdline-tools; \
    mv /tmp/android-cmdline-tools/cmdline-tools "${ANDROID_HOME}/cmdline-tools/latest"; \
    rm -rf /tmp/android-cmdline-tools /tmp/android-cmdline-tools.zip; \
    set +o pipefail; \
    yes | sdkmanager --licenses >/dev/null; \
    set -o pipefail; \
    sdkmanager \
      "platform-tools" \
      "platforms;${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK}"; \
    IFS=',' read -ra extra_packages <<< "${ANDROID_EXTRA_PACKAGES}"; \
    if [[ "${#extra_packages[@]}" -gt 0 && -n "${extra_packages[0]}" ]]; then \
      sdkmanager "${extra_packages[@]}"; \
    fi

RUN set -eux; \
    mkdir -p /root/fvm/versions; \
    flutter_archive="/tmp/flutter.tar.xz"; \
    flutter_url="${FLUTTER_STORAGE_BASE_URL}/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"; \
    for attempt in 1 2 3 4 5; do \
      curl -fL --show-error \
        --retry 3 \
        --retry-all-errors \
        --retry-delay 5 \
        --connect-timeout 30 \
        --speed-time 60 \
        --speed-limit 10240 \
        -C - \
        -o "${flutter_archive}" \
        "${flutter_url}" && break; \
      if [ "${attempt}" = "5" ]; then exit 1; fi; \
      sleep 10; \
    done; \
    tar -tJf "${flutter_archive}" >/dev/null; \
    tar -xJf "${flutter_archive}" -C /root/fvm/versions; \
    mv /root/fvm/versions/flutter "${FLUTTER_ROOT}"; \
    rm "${flutter_archive}"; \
    git config --global --add safe.directory "${FLUTTER_ROOT}"; \
    flutter config --no-analytics; \
    flutter precache --android; \
    flutter doctor -v

RUN mkdir -p /root/.gradle
COPY docker/gradle/init.gradle /root/.gradle/init.gradle

WORKDIR /workspace

CMD ["bash", "/builder/scripts/container-build-android.sh"]
