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
QT_URL="https://download.qt.io/archive/qt/${QT_MAIN_VERSION}/${QT_VERSION}/single/${QT_ARCHIVE}"

mkdir -p "${QT_ROOT}" "${QT_SRC_PARENT}"
cd "${QT_SRC_PARENT}"

if [[ ! -f "${QT_ARCHIVE}" ]]; then
  echo "Missing source archive: ${QT_ARCHIVE}" >&2
  exit 2
fi
if [[ ! -d "${QT_SRC_DIR}" ]]; then
  tar -xf "${QT_ARCHIVE}"
fi

python3 - <<'PY'
from pathlib import Path
files = [
    Path("/opt/src/qt-everywhere-src-5.15.2/qtbase/src/corelib/global/qfloat16.h"),
    Path("/opt/src/qt-everywhere-src-5.15.2/qtbase/src/corelib/global/qendian.h"),
    Path("/opt/src/qt-everywhere-src-5.15.2/qtbase/src/corelib/text/qbytearraymatcher.h"),
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

prepare_system_host_qt
cd "${QT_SRC_DIR}"

if [[ ! -x "${QT_AARCH64_DIR}/bin/qmake" ]]; then
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
    -skip qtserialport \
    -skip qtconnectivity \
    -skip qtremoteobjects \
    -skip qtwebchannel \
    -skip qtwebsockets \
    -skip qtscxml \
    -skip qtdoc \
    -skip qttranslations \
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
    -no-openssl \
    -no-dbus \
    -no-sql-sqlite \
    -no-feature-xcb \
    -no-feature-xlib \
    -no-feature-xkbcommon \
    -no-feature-vulkan \
    -linuxfb
  make -j"$(nproc)"
  make install
  cd ..
fi
