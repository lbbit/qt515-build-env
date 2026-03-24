#!/usr/bin/env bash
set -euo pipefail

QT_MAIN_VERSION="${QT_MAIN_VERSION:-5.15}"
QT_VERSION="${QT_VERSION:-5.15.2}"
QT_ROOT="/opt/Qt${QT_MAIN_VERSION}/${QT_VERSION}"
QT_HOST_DIR="${QT_ROOT}/gcc_64"
QT_AARCH64_DIR="${QT_ROOT}/aarch64"
QT_SRC_PARENT="/opt/src"
QT_SRC_DIR="${QT_SRC_PARENT}/qt-everywhere-src-${QT_VERSION}"
QT_ARCHIVE="qt-everywhere-src-${QT_VERSION}.tar.xz"
QTMQTT_VERSION="${QTMQTT_VERSION:-v${QT_VERSION}}"
QTMQTT_ARCHIVE="qtmqtt-${QTMQTT_VERSION}.tar.gz"
QTMQTT_SRC_DIR="${QT_SRC_PARENT}/qtmqtt-${QTMQTT_VERSION}"

mkdir -p "${QT_ROOT}" "${QT_SRC_PARENT}"
cd "${QT_SRC_PARENT}"

if [[ ! -f "${QT_ARCHIVE}" ]]; then
  echo "Missing source archive: ${QT_ARCHIVE}" >&2
  exit 2
fi
if [[ ! -d "${QT_SRC_DIR}" ]]; then
  tar -xf "${QT_ARCHIVE}"
fi
if [[ ! -f "${QTMQTT_ARCHIVE}" ]]; then
  echo "Missing qtmqtt source archive: ${QTMQTT_ARCHIVE}" >&2
  exit 2
fi
if [[ ! -d "${QTMQTT_SRC_DIR}" ]]; then
  tar -xf "${QTMQTT_ARCHIVE}"
fi
if [[ ! -d "${QT_SRC_DIR}/qtmqtt" ]]; then
  cp -a "${QTMQTT_SRC_DIR}" "${QT_SRC_DIR}/qtmqtt"
fi

python3 - <<'PY'
from pathlib import Path
files = [
    Path('/opt/src/qt-everywhere-src-5.15.2/qtbase/src/corelib/global/qfloat16.h'),
    Path('/opt/src/qt-everywhere-src-5.15.2/qtbase/src/corelib/global/qendian.h'),
    Path('/opt/src/qt-everywhere-src-5.15.2/qtbase/src/corelib/text/qbytearraymatcher.h'),
]
for path in files:
    text = path.read_text()
    if '#include <limits>' not in text:
        if '#include <type_traits>' in text:
            text = text.replace('#include <type_traits>', '#include <type_traits>\n#include <limits>', 1)
        elif '#include <QtCore/qglobal.h>' in text:
            text = text.replace('#include <QtCore/qglobal.h>', '#include <QtCore/qglobal.h>\n#include <limits>', 1)
        elif '#include <QtCore/qbytearray.h>' in text:
            text = text.replace('#include <QtCore/qbytearray.h>', '#include <QtCore/qbytearray.h>\n#include <limits>', 1)
        path.write_text(text)
PY

prepare_system_host_qt() {
  mkdir -p "${QT_HOST_DIR}/bin"
  ln -sf /usr/lib/qt5/bin/qmake "${QT_HOST_DIR}/bin/qmake"
  ln -sf /usr/lib/qt5/bin/moc "${QT_HOST_DIR}/bin/moc"
  ln -sf /usr/lib/qt5/bin/uic "${QT_HOST_DIR}/bin/uic"
  ln -sf /usr/lib/qt5/bin/rcc "${QT_HOST_DIR}/bin/rcc"
}

build_qtbase_stack() {
  cd "${QT_SRC_DIR}"
  if [[ ! -d "${QT_AARCH64_DIR}/include" || ! -d "${QT_AARCH64_DIR}/lib" ]]; then
    mkdir -p build-aarch64 && cd build-aarch64
    export CFLAGS="${CFLAGS:-} -O2"
    export CXXFLAGS="${CXXFLAGS:-} -O2 -std=gnu++11"
    ../configure \
      -prefix "${QT_AARCH64_DIR}" \
      -hostprefix "${QT_HOST_DIR}" \
      -extprefix "${QT_AARCH64_DIR}" \
      -opensource -confirm-license -release \
      -nomake examples -nomake tests \
      -platform linux-g++ \
      -xplatform linux-aarch64-gnu-g++ \
      -device-option CROSS_COMPILE=aarch64-linux-gnu- \
      -sysroot / \
      -skip qtwebengine \
      -skip qt3d \
      -skip qtquick3d \
      -skip qtmultimedia \
      -skip qtwayland \
      -skip qtlocation \
      -skip qtsensors \
      -skip qtconnectivity \
      -skip qtremoteobjects \
      -skip qtwebchannel \
      -skip qtwebsockets \
      -skip qtscxml \
      -skip qtdoc \
      -skip qttools \
      -skip qtdeclarative \
      -skip qtgamepad \
      -skip qtlottie \
      -skip qtspeech \
      -skip qtvirtualkeyboard \
      -skip qtcharts \
      -skip qtactiveqt \
      -skip qtmacextras \
      -skip qtx11extras \
      -skip qtwinextras \
      -skip qtpurchasing \
      -no-openssl \
      -no-dbus \
      -no-sql-sqlite \
      -no-feature-xcb \
      -no-feature-xlib \
      -no-feature-xkbcommon \
      -no-feature-vulkan \
      -no-opengl \
      -no-eglfs \
      -linuxfb
    make -j"$(nproc)"
    make install
    cd ..
  fi
}

build_module_from_qt_tree() {
  local module_name="$1"
  local module_src_dir="${QT_SRC_DIR}/${module_name}"
  local stamp_file="${QT_AARCH64_DIR}/lib/.${module_name}.installed"
  if [[ -f "${stamp_file}" ]]; then
    echo "${module_name} already installed; skip"
    return 0
  fi
  if [[ ! -d "${module_src_dir}" ]]; then
    echo "Missing module source directory in qt tree: ${module_src_dir}" >&2
    exit 3
  fi

  local module_pro="${module_src_dir}/${module_name}.pro"
  if [[ ! -f "${module_pro}" ]]; then
    module_pro="${module_src_dir}/src/${module_name}/${module_name}.pro"
  fi
  if [[ ! -f "${module_pro}" ]]; then
    echo "Missing module project file for ${module_name}" >&2
    exit 3
  fi

  mkdir -p "${module_src_dir}/build-aarch64"
  cd "${module_src_dir}/build-aarch64"
  export PATH="${QT_HOST_DIR}/bin:${PATH}"
  export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
  export PKG_CONFIG_SYSROOT_DIR="/"
  echo "Building ${module_name} from ${module_pro}"
  "${QT_HOST_DIR}/bin/qmake" -spec linux-aarch64-gnu-g++ \
    QMAKE_CC=aarch64-linux-gnu-gcc \
    QMAKE_CXX=aarch64-linux-gnu-g++ \
    QMAKE_LINK=aarch64-linux-gnu-g++ \
    QMAKE_STRIP=aarch64-linux-gnu-strip \
    QMAKE_CFLAGS+="--sysroot=/" \
    QMAKE_CXXFLAGS+="--sysroot=/" \
    QMAKE_LFLAGS+="--sysroot=/" \
    "${module_pro}"
  make -j"$(nproc)"
  make install
  mkdir -p "$(dirname "${stamp_file}")"
  touch "${stamp_file}"
  cd "${QT_SRC_DIR}"
}

prepare_system_host_qt
build_qtbase_stack
build_module_from_qt_tree qtsvg
build_module_from_qt_tree qtserialbus
build_module_from_qt_tree qtmqtt

echo "Built Qt aarch64 SDK with modules: qtbase, qtserialport, qttranslations, qtsvg, qtserialbus, qtmqtt"
