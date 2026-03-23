#!/usr/bin/env bash
set -euo pipefail

QT_MAIN_VERSION="${QT_MAIN_VERSION:-5.15}"
QT_VERSION="${QT_VERSION:-5.15.2}"
QT_ROOT="/opt/Qt${QT_MAIN_VERSION}/${QT_VERSION}"
QT_HOST_DIR="${QT_ROOT}/gcc_64"
QT_AARCH64_DIR="${QT_ROOT}/aarch64"
QT_ARMV7_DIR="${QT_ROOT}/armv7"
QT_SRC_PARENT="/opt/src"
QT_SRC_DIR="${QT_SRC_PARENT}/qt-everywhere-src-${QT_VERSION}"
QT_ARCHIVE="qt-everywhere-src-${QT_VERSION}.tar.xz"
QT_URL="https://download.qt.io/archive/qt/${QT_MAIN_VERSION}/${QT_VERSION}/single/${QT_ARCHIVE}"

mkdir -p "${QT_ROOT}" "${QT_SRC_PARENT}"
cd "${QT_SRC_PARENT}"

if [[ ! -f "${QT_ARCHIVE}" ]]; then
  wget -O "${QT_ARCHIVE}" "${QT_URL}"
fi
if [[ ! -d "${QT_SRC_DIR}" ]]; then
  tar -xf "${QT_ARCHIVE}"
fi

prepare_system_host_qt() {
  mkdir -p "${QT_HOST_DIR}/bin" "${QT_HOST_DIR}/lib"
  ln -sf /usr/lib/qt5/bin/qmake "${QT_HOST_DIR}/bin/qmake"
  ln -sf /usr/lib/x86_64-linux-gnu "${QT_HOST_DIR}/system-libdir"
}

cd "${QT_SRC_DIR}"

if [[ ! -x "${QT_HOST_DIR}/bin/qmake" ]]; then
  mkdir -p build-host && cd build-host
  export CFLAGS="${CFLAGS:-} -O2"
  export CXXFLAGS="${CXXFLAGS:-} -O2 -std=gnu++11"
  ../configure -prefix "${QT_HOST_DIR}" -opensource -confirm-license -release -nomake examples -nomake tests -platform linux-g++
  make -j"$(nproc)" || {
    echo "Host Qt build failed, fallback to system host qmake" >&2
    cd ..
    prepare_system_host_qt
  }
  if [[ -f Makefile ]]; then
    make install || true
  fi
  cd ..
fi

if [[ ! -x "${QT_HOST_DIR}/bin/qmake" ]]; then
  prepare_system_host_qt
fi

if [[ ! -x "${QT_AARCH64_DIR}/bin/qmake" ]]; then
  mkdir -p build-aarch64 && cd build-aarch64
  export CFLAGS="${CFLAGS:-} -O2"
  export CXXFLAGS="${CXXFLAGS:-} -O2 -std=gnu++11"
  ../configure \
    -prefix "${QT_AARCH64_DIR}" \
    -opensource -confirm-license -release \
    -nomake examples -nomake tests \
    -platform linux-g++ \
    -xplatform linux-aarch64-gnu-g++ \
    -device-option CROSS_COMPILE=aarch64-linux-gnu- \
    -sysroot /usr/aarch64-linux-gnu \
    -qt-host-path "${QT_HOST_DIR}"
  make -j"$(nproc)"
  make install
  cd ..
fi

if [[ ! -x "${QT_ARMV7_DIR}/bin/qmake" ]]; then
  mkdir -p build-armv7 && cd build-armv7
  export CFLAGS="${CFLAGS:-} -O2"
  export CXXFLAGS="${CXXFLAGS:-} -O2 -std=gnu++11"
  ../configure \
    -prefix "${QT_ARMV7_DIR}" \
    -opensource -confirm-license -release \
    -nomake examples -nomake tests \
    -platform linux-g++ \
    -xplatform linux-arm-gnueabi-g++ \
    -device-option CROSS_COMPILE=arm-linux-gnueabihf- \
    -sysroot /usr/arm-linux-gnueabihf \
    -qt-host-path "${QT_HOST_DIR}"
  make -j"$(nproc)"
  make install
  cd ..
fi
