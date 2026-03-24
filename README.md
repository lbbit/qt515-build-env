# Qt 5.15 AArch64 Build Environment Container

用于构建 **Qt 5.15.2 QMake 项目** 的 **aarch64 交叉编译 Docker 环境**。

当前仓库只聚焦一个目标：

- **aarch64 (ARM64 Linux)**

这样做是为了优先把最关键、最急需的 ARM64 构建链路打通，而不是同时维护 x86_64 / armv7 多套复杂环境。

## 特性

- 基于 Docker 统一构建环境
- Qt 5.15.2
- 面向 **aarch64 QMake 工程**
- 自动构建并发布到 GHCR

## 容器内容

最终发布到 GHCR 的镜像中会准备：

- host Qt 工具：`/opt/Qt5.15/5.15.2/gcc_64/bin`
- aarch64 Qt target SDK：`/opt/Qt5.15/5.15.2/aarch64`
- 交叉编译器：`aarch64-linux-gnu-g++`
- cross mkspec：`linux-aarch64-gnu-g++`
- 常见工具：`zip` / `patchelf`

这个镜像的正确使用方式是：

- 用 **host qmake** 生成 Makefile
- 用 **aarch64 mkspec** 和交叉编译器完成 ARM64 构建
- 使用 `/opt/Qt5.15/5.15.2/aarch64` 下的头文件和库作为 target SDK

## 当前模块范围

当前优先保证以下能力可用于 aarch64 QMake 工程：

- Qt Core
- Qt Gui
- Qt Widgets
- Qt Network
- Qt Test
- Qt Concurrent
- Qt SerialPort
- Qt SerialBus
- Qt Svg
- Qt Translations
- Qt MQTT

### 关于 MQTT

MQTT 在 Qt 5.15 体系里通常来自 **`qtmqtt` 模块**，它不是 `qtbase` 自带的一部分。

当前仓库已采用增量方式接入：

- 基础 Qt 5.15.2 aarch64 交叉环境来自 `qt-everywhere-src-5.15.2`
- `qtmqtt` 通过 GitHub 下载 `qt/qtmqtt` 对应 `v5.15.2` 源码后单独编译安装

这样可以在不放大基础环境排障范围的前提下，为业务项目补齐 `QtMqtt`。


```text
ghcr.io/lbbit/qt515-build-env:latest
```

## 如何使用（QMake 工程）

### 1. 拉取镜像

```bash
docker pull ghcr.io/lbbit/qt515-build-env:latest
```

### 2. 构建 aarch64 版本

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/lbbit/qt515-build-env:latest \
  bash -lc '
    /opt/Qt5.15/5.15.2/gcc_64/bin/qmake -spec linux-aarch64-gnu-g++ \
      QMAKE_CC=aarch64-linux-gnu-gcc \
      QMAKE_CXX=aarch64-linux-gnu-g++ \
      QMAKE_LINK=aarch64-linux-gnu-g++ \
      QMAKE_STRIP=aarch64-linux-gnu-strip \
      QMAKE_CFLAGS+="--sysroot=/" \
      QMAKE_CXXFLAGS+="--sysroot=/" \
      QMAKE_LFLAGS+="--sysroot=/" \
      your-project.pro &&
    make -j$(nproc)
  '
```

### 3. 推荐 build 目录方式

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/lbbit/qt515-build-env:latest \
  bash -lc '
    mkdir -p build-aarch64 && cd build-aarch64 &&
    /opt/Qt5.15/5.15.2/gcc_64/bin/qmake -spec linux-aarch64-gnu-g++ \
      QMAKE_CC=aarch64-linux-gnu-gcc \
      QMAKE_CXX=aarch64-linux-gnu-g++ \
      QMAKE_LINK=aarch64-linux-gnu-g++ \
      QMAKE_STRIP=aarch64-linux-gnu-strip \
      QMAKE_CFLAGS+="--sysroot=/" \
      QMAKE_CXXFLAGS+="--sysroot=/" \
      QMAKE_LFLAGS+="--sysroot=/" \
      ../your-project.pro &&
    make -j$(nproc)
  '
```

### 4. 验证容器是否完整

```bash
test -x /opt/Qt5.15/5.15.2/gcc_64/bin/qmake
test -d /opt/Qt5.15/5.15.2/aarch64/include
test -d /opt/Qt5.15/5.15.2/aarch64/lib
test -d /opt/Qt5.15/5.15.2/gcc_64/mkspecs/linux-aarch64-gnu-g++ || test -d /usr/lib/qt5/mkspecs/linux-aarch64-gnu-g++
```

## 关于 QMake 工程的注意点

- 这个容器的推荐入口是 **host qmake**，不是 `aarch64/bin/qmake`
- 交叉构建时显式指定 `-spec linux-aarch64-gnu-g++`
- 不要混用系统默认 `qmake` 和未声明的 target mkspec
- target 侧的 Qt 资产主要位于 `/opt/Qt5.15/5.15.2/aarch64`

## GHCR 自动构建

仓库内置 GitHub Actions：

- push 到 `main` 自动构建镜像
- tag 可生成版本化镜像 tag
- 自动推送到 GHCR

## 当前范围

当前仓库 **只保证 aarch64**。

后续如果需要，再单独补：

- x86_64 完整 host Qt
- armv7 Qt toolchain

但这些不影响当前先解决 ARM64 项目的交叉编译问题。
