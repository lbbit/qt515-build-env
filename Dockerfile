FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV QT_MAIN_VERSION=5.15
ENV QT_VERSION=5.15.2
ENV QT_ROOT=/opt/Qt${QT_MAIN_VERSION}/${QT_VERSION}
ENV QT_HOST_DIR=${QT_ROOT}/gcc_64
ENV QT_AARCH64_DIR=${QT_ROOT}/aarch64
ENV QT_ARMV7_DIR=${QT_ROOT}/armv7

RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    bc \
    wget \
    curl \
    git \
    zip \
    unzip \
    perl \
    make \
    ninja-build \
    patchelf \
    ca-certificates \
    xz-utils \
    g++ \
    gcc \
    g++-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    g++-arm-linux-gnueabihf \
    gcc-arm-linux-gnueabihf \
    libc6-arm64-cross \
    libc6-dev-arm64-cross \
    libc6-armhf-cross \
    libc6-dev-armhf-cross \
    qtbase5-dev \
    qtbase5-dev-tools \
    qtchooser \
    qt5-qmake \
    libfontconfig1-dev \
    libfreetype6-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxrender-dev \
    libxcb1-dev \
    libxcb-glx0-dev \
    libxcb-keysyms1-dev \
    libxcb-image0-dev \
    libxcb-shm0-dev \
    libxcb-icccm4-dev \
    libxcb-sync-dev \
    libxcb-xfixes0-dev \
    libxcb-shape0-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libxcb-xtest0-dev \
    libxcb-xinerama0-dev \
    libxcb-xkb-dev \
    libglu1-mesa-dev \
    libxcb-util-dev \
  && rm -rf /var/lib/apt/lists/*

COPY qt-everywhere-src-5.15.2.tar.xz /opt/src/qt-everywhere-src-5.15.2.tar.xz
COPY scripts/build_qt_all.sh /usr/local/bin/build_qt_all.sh
RUN chmod +x /usr/local/bin/build_qt_all.sh \
    && /usr/local/bin/build_qt_all.sh || { \
      echo '===== build_qt_all.sh failed; dumping partial logs if present ====='; \
      find /opt/src -maxdepth 5 \( -name config.log -o -name config.summary -o -name '*.log' -o -name '*.txt' \) -type f -print | head -n 400; \
      if [ -f /opt/src/qt-everywhere-src-5.15.2/build-aarch64/config.summary ]; then \
        echo '===== build-aarch64/config.summary ====='; \
        cat /opt/src/qt-everywhere-src-5.15.2/build-aarch64/config.summary; \
      fi; \
      if [ -f /opt/src/qt-everywhere-src-5.15.2/build-aarch64/config.log ]; then \
        echo '===== build-aarch64/config.log ====='; \
        cat /opt/src/qt-everywhere-src-5.15.2/build-aarch64/config.log; \
      fi; \
      find /opt/src/qt-everywhere-src-5.15.2/build-aarch64/config.tests -maxdepth 4 -type f \( -name Makefile -o -name '*.log' -o -name '*.txt' -o -name '*.out' -o -name '*.err' \) -print -exec sh -c 'echo "===== {} ====="; sed -n "1,220p" "{}"' \; 2>/dev/null || true; \
      exit 1; \
    }

ENV PATH=${QT_HOST_DIR}/bin:${QT_AARCH64_DIR}/bin:$PATH

WORKDIR /workspace
