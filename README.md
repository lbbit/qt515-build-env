# Qt 5.15 Build Environment Container

用于构建 **Qt 5.15** 项目的 Docker 编译环境，面向以下目标架构：

- x86_64 (gcc_64)
- aarch64
- armv7

这个仓库的目标是提供一个可复用的 **Qt 编译环境容器**，并通过 GitHub Actions 自动构建并发布到 **GHCR (GitHub Container Registry)**。

## 特性

- 基于 Docker 统一构建环境
- 支持 Qt 5.15.2
- 支持 x86_64 / aarch64 / armv7
- 适合 **QMake 工程**
- 自动构建并发布到 GHCR

## 容器内容

容器里会准备：

- Qt host 工具链：`/opt/Qt5.15/5.15.2/gcc_64`
- Qt aarch64 工具链：`/opt/Qt5.15/5.15.2/aarch64`
- Qt armv7 工具链：`/opt/Qt5.15/5.15.2/armv7`
- 交叉编译器：
  - `aarch64-linux-gnu-g++`
  - `arm-linux-gnueabihf-g++`
- 常见打包工具：`zip` / `patchelf`

## GHCR 镜像名

发布成功后，镜像地址类似：

```text
ghcr.io/lbbit/qt515-build-env:latest
```

也会按 commit/tag 生成对应 tag。

## 如何使用（QMake 工程）

下面以一个 QMake 工程为例。

### 1. 拉取镜像

```bash
docker pull ghcr.io/lbbit/qt515-build-env:latest
```

### 2. 构建 x86_64 版本

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/lbbit/qt515-build-env:latest \
  bash -lc '/opt/Qt5.15/5.15.2/gcc_64/bin/qmake your-project.pro && make -j$(nproc)'
```

### 3. 构建 aarch64 版本（QMake）

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/lbbit/qt515-build-env:latest \
  bash -lc '/opt/Qt5.15/5.15.2/aarch64/bin/qmake your-project.pro && make -j$(nproc)'
```

### 4. 构建 armv7 版本（QMake）

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  ghcr.io/lbbit/qt515-build-env:latest \
  bash -lc '/opt/Qt5.15/5.15.2/armv7/bin/qmake your-project.pro && make -j$(nproc)'
```

## 推荐目录习惯（QMake）

建议在容器中使用独立 build 目录，例如：

### x86_64

```bash
docker run --rm -it -v "$PWD":/workspace -w /workspace ghcr.io/lbbit/qt515-build-env:latest bash -lc '
  mkdir -p build-gcc_64 && cd build-gcc_64 &&
  /opt/Qt5.15/5.15.2/gcc_64/bin/qmake ../your-project.pro &&
  make -j$(nproc)
'
```

### aarch64

```bash
docker run --rm -it -v "$PWD":/workspace -w /workspace ghcr.io/lbbit/qt515-build-env:latest bash -lc '
  mkdir -p build-aarch64 && cd build-aarch64 &&
  /opt/Qt5.15/5.15.2/aarch64/bin/qmake ../your-project.pro &&
  make -j$(nproc)
'
```

### armv7

```bash
docker run --rm -it -v "$PWD":/workspace -w /workspace ghcr.io/lbbit/qt515-build-env:latest bash -lc '
  mkdir -p build-armv7 && cd build-armv7 &&
  /opt/Qt5.15/5.15.2/armv7/bin/qmake ../your-project.pro &&
  make -j$(nproc)
'
```

## 关于 QMake 工程的注意点

如果你的项目是 QMake 工程：

- 优先使用对应架构的 `qmake`
- 不建议混用 host qmake 和 cross mkspec
- 最稳的方式是直接调用目标架构 Qt 安装目录下的 `qmake`

也就是：

- x86_64 → `.../gcc_64/bin/qmake`
- aarch64 → `.../aarch64/bin/qmake`
- armv7 → `.../armv7/bin/qmake`

## GHCR 自动构建

仓库内置 GitHub Actions：

- push 到 `main` 自动构建镜像
- tag 可生成版本化镜像 tag
- 自动推送到 GHCR

## 适用场景

适合这些场景：

- 你有多个 Qt 5.15 项目想复用统一环境
- 你需要 CI 中做 x86_64 / aarch64 / armv7 构建
- 你使用的是 **QMake 工程**
- 你想把编译环境和业务项目解耦
