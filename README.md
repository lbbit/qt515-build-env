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
- aarch64 Qt 工具链：`/opt/Qt5.15/5.15.2/aarch64`
- 交叉编译器：`aarch64-linux-gnu-g++`
- 常见工具：`zip` / `patchelf`

## 当前模块范围

当前优先保证以下能力可用于 aarch64 QMake 工程：

- Qt Core
- Qt Gui
- Qt Widgets
- Qt Network
- Qt Test
- Qt SerialPort
- Qt Translations

### 关于 MQTT

MQTT 在 Qt 5.15 体系里通常来自 **`qtmqtt` 模块**，它不是 `qtbase` 自带的一部分。

因此当前仓库先优先打通：

- Qt 5.15 aarch64 基础交叉编译环境
- `qtserialport`
- `qttranslations`

等基础环境稳定后，再继续把 `qtmqtt` 加进容器。


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
  bash -lc '/opt/Qt5.15/5.15.2/aarch64/bin/qmake your-project.pro && make -j$(nproc)'
```

### 3. 推荐 build 目录方式

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/lbbit/qt515-build-env:latest \
  bash -lc '
    mkdir -p build-aarch64 && cd build-aarch64 &&
    /opt/Qt5.15/5.15.2/aarch64/bin/qmake ../your-project.pro &&
    make -j$(nproc)
  '
```

## 关于 QMake 工程的注意点

- 直接调用目标架构 Qt 安装目录下的 `qmake`
- 不要混用系统 `qmake` 和 aarch64 mkspec
- 最稳的方式就是：

```bash
/opt/Qt5.15/5.15.2/aarch64/bin/qmake your-project.pro
```

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
