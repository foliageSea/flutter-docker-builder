# Flutter Docker Android Builder

可复用的 Flutter Android Docker 构建模板，用于在容器中构建 Flutter Android 项目。

## 包含内容

- `docker/Dockerfile`：安装 Java 17、Android SDK、Flutter、Node、pnpm。
- `docker/gradle/init.gradle`：Gradle 初始化占位文件，可按项目需要扩展。
- `scripts/docker-build-image.sh`：构建构建器镜像。
- `scripts/docker-run-android.sh`：挂载目标项目和缓存，启动容器构建。
- `scripts/container-build-android.sh`：容器内写入 `local.properties` 并执行构建命令。
- `scripts/docker-build-android.sh`：一键构建镜像并执行 Android 构建。

## 快速使用

普通 Flutter 项目：

```bash
PROJECT_DIR=/path/to/flutter/app \
BUILD_COMMAND="flutter build apk --release" \
bash scripts/docker-build-android.sh
```

Melos/Monorepo 项目：

```bash
PROJECT_DIR=/path/to/monorepo \
ANDROID_PROJECT_DIR=apps/app/android \
PRE_BUILD_COMMAND="dart pub get && dart run melos bs" \
BUILD_COMMAND="dart run melos run build:android" \
bash scripts/docker-build-android.sh
```

只构建镜像：

```bash
bash scripts/docker-build-image.sh
```

只运行构建：

```bash
PROJECT_DIR=/path/to/flutter/app bash scripts/docker-run-android.sh
```

## 配置项

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `IMAGE_NAME` | `flutter-android-builder:flutter-${FLUTTER_VERSION}` | Docker 镜像名 |
| `FLUTTER_VERSION` | `3.35.6` | Flutter stable 版本 |
| `NODE_VERSION` | `22.11.0` | Node 版本 |
| `PNPM_VERSION` | `9.15.2` | pnpm 版本 |
| `ANDROID_PLATFORM` | `android-35` | 主 Android platform |
| `ANDROID_BUILD_TOOLS` | `35.0.0` | Android build-tools 版本 |
| `ANDROID_NDK` | `27.0.12077973` | Android NDK 版本 |
| `ANDROID_EXTRA_PACKAGES` | `platforms;android-31,platforms;android-34,platforms;android-36,cmake;3.22.1` | 逗号分隔的额外 SDK 包 |
| `PROJECT_DIR` | 当前目录 | 要构建的 Flutter 项目或仓库根目录 |
| `ANDROID_PROJECT_DIR` | `android` | 相对 `PROJECT_DIR` 的 Android 工程目录 |
| `BUILD_WORKDIR` | `/workspace` | 容器内工作目录，一般不用改 |
| `PRE_BUILD_COMMAND` | 空 | 构建前命令 |
| `BUILD_COMMAND` | `flutter build apk --release` | 主构建命令 |
| `POST_BUILD_COMMAND` | 空 | 构建后命令 |
| `CACHE_ROOT` | `${PROJECT_DIR}/.docker-cache` | pub、Gradle、pnpm 缓存目录 |
| `DOCKER_BUILD_NO_CACHE` | `0` | 设为 `1` 时强制无缓存构建镜像 |

## 私有 Git 依赖

如果 `pubspec.yaml` 中存在需要认证的 Git 依赖，可以传入：

```bash
GIT_HOST=gitee.com \
GIT_USERNAME=your-username \
GIT_TOKEN=your-token \
PROJECT_DIR=/path/to/project \
bash scripts/docker-build-android.sh
```

脚本会在容器内临时写入 `/root/.netrc`，构建结束后删除。不要把真实 token 写入仓库。

## 国内镜像

默认使用：

- `PUB_HOSTED_URL=https://pub.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- `NPM_CONFIG_REGISTRY=https://registry.npmmirror.com`

需要使用官方源时可覆盖这些环境变量。

## Android local.properties

容器内会临时写入：

```properties
sdk.dir=/opt/android-sdk
flutter.sdk=/root/fvm/versions/<FLUTTER_VERSION>
```

如果目标项目已有 `local.properties`，脚本会先备份，构建结束后恢复。

## Windows 说明

脚本面向 Bash。Windows 可使用 Git Bash、WSL 或其他 Bash 环境执行。`docker-run-android.sh` 已设置 `MSYS_NO_PATHCONV=1`，避免 Git Bash 自动转换 Docker 挂载路径。

签名文件、`key.properties`、业务项目 Gradle 配置仍由目标项目自己维护，本模板不复制这些敏感或业务相关文件。
