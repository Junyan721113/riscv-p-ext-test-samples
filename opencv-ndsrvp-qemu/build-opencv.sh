#!/usr/bin/env bash
set -euo pipefail

WORK=${WORK:-/work/ndsrvp-opencv-pr28915}
RISCV=${RISCV:-$WORK/opt/andes}
JOBS=${JOBS:-4}
PR_NUMBER=${PR_NUMBER:-28915}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PATCH_FILE=${PATCH_FILE:-$SCRIPT_DIR/patches/opencv_ndsrvp_bilateral_build_workaround.patch}
FILTER2D_ISOLATED_PATCH_FILE=${FILTER2D_ISOLATED_PATCH_FILE:-$SCRIPT_DIR/patches/pr28915_filter2d_strip_border_isolated.patch}

mkdir -p "$WORK/src" "$WORK/build" "$WORK/logs"

export RISCV
export PATH="$RISCV/bin:$PATH"
export CFLAGS="-march=rv64gc -mext-dsp"
export CXXFLAGS="-march=rv64gc -mext-dsp"
unset CMAKE_PREFIX_PATH OpenJPEG_DIR TIFF_DIR JPEG_DIR PNG_DIR ZLIB_ROOT PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

clone_4x() {
  local dst=$1
  if [ ! -d "$dst/.git" ]; then
    git clone --depth 1 --branch 4.x https://github.com/opencv/opencv.git "$dst"
  fi
}

clone_pr() {
  local dst=$1
  if [ ! -d "$dst/.git" ]; then
    git clone --depth 1 --branch 4.x https://github.com/opencv/opencv.git "$dst"
    git -C "$dst" fetch --depth 1 origin "pull/$PR_NUMBER/head:pr-$PR_NUMBER"
    git -C "$dst" checkout "pr-$PR_NUMBER"
  fi
}

apply_workaround() {
  local dst=$1
  if [ "${APPLY_BILATERAL_WORKAROUND:-1}" != "1" ]; then
    return 0
  fi
  if git -C "$dst" apply --check "$PATCH_FILE" >/dev/null 2>&1; then
    git -C "$dst" apply "$PATCH_FILE"
  else
    echo "Skipping workaround for $dst; patch is already applied or no longer matches."
  fi
}

apply_filter2d_isolated_workaround() {
  local dst=$1
  if [ "${APPLY_FILTER2D_ISOLATED_WORKAROUND:-0}" != "1" ]; then
    return 0
  fi
  if git -C "$dst" apply --check "$FILTER2D_ISOLATED_PATCH_FILE" >/dev/null 2>&1; then
    git -C "$dst" apply "$FILTER2D_ISOLATED_PATCH_FILE"
  else
    echo "Skipping filter2D isolated workaround for $dst; patch is already applied or no longer matches."
  fi
}

clone_4x "$WORK/src/opencv-4x"
clone_pr "$WORK/src/opencv-pr28915"

if [ "${CLONE_OPENCV_EXTRA:-1}" = "1" ] && [ ! -d "$WORK/src/opencv_extra-4x/.git" ]; then
  git clone --depth 1 --branch 4.x https://github.com/opencv/opencv_extra.git "$WORK/src/opencv_extra-4x" || true
fi

apply_workaround "$WORK/src/opencv-4x"
apply_workaround "$WORK/src/opencv-pr28915"
apply_filter2d_isolated_workaround "$WORK/src/opencv-4x"
apply_filter2d_isolated_workaround "$WORK/src/opencv-pr28915"

common_opts=(
  -G Ninja
  -D CMAKE_BUILD_TYPE=Release
  -D CMAKE_INSTALL_PREFIX="$RISCV/opencv-install"
  -D CMAKE_FIND_USE_PACKAGE_REGISTRY=FALSE
  -D CMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=FALSE
  -D BUILD_SHARED_LIBS=OFF
  -D BUILD_TESTS=ON
  -D BUILD_PERF_TESTS=OFF
  -D BUILD_EXAMPLES=OFF
  -D BUILD_DOCS=OFF
  -D BUILD_LIST=core,imgproc,ts
  -D WITH_NDSRVP=ON
  -D WITH_HAL_RVV=OFF
  -D CPU_BASELINE=
  -D WITH_ITT=OFF
  -D WITH_OPENCL=OFF
  -D WITH_OPENJPEG=OFF
  -D BUILD_OPENJPEG=OFF
  -D WITH_AVIF=OFF
  -D WITH_TIFF=OFF
  -D BUILD_TIFF=OFF
  -D WITH_JASPER=OFF
  -D WITH_OPENEXR=OFF
  -D BUILD_opencv_python3=OFF
  -D CMAKE_TOOLCHAIN_FILE=platforms/linux/riscv64-andes-gcc.toolchain.cmake
)

configure_one() {
  local name=$1
  local src=$2
  local build=$WORK/build/opencv-$name
  case "$build" in
    "$WORK"/build/opencv-*) ;;
    *) echo "Refusing to remove unexpected build path: $build" >&2; exit 1 ;;
  esac
  rm -rf "$build"
  mkdir -p "$build"
  cmake -S "$src" -B "$build" "${common_opts[@]}" \
    2>&1 | tee "$WORK/logs/configure-opencv-$name.log"
}

build_one() {
  local name=$1
  /usr/bin/time -v ninja -C "$WORK/build/opencv-$name" opencv_test_imgproc -j "$JOBS" \
    2>&1 | tee "$WORK/logs/build-opencv-$name-imgproc.log"
}

configure_one 4x "$WORK/src/opencv-4x"
configure_one pr28915 "$WORK/src/opencv-pr28915"
build_one 4x
build_one pr28915

{
  echo "opencv_4x=$(git -C "$WORK/src/opencv-4x" rev-parse HEAD)"
  echo "opencv_pr28915=$(git -C "$WORK/src/opencv-pr28915" rev-parse HEAD)"
  if [ -d "$WORK/src/opencv_extra-4x/.git" ]; then
    echo "opencv_extra_4x=$(git -C "$WORK/src/opencv_extra-4x" rev-parse HEAD)"
  fi
  echo "toolchain=$( "$RISCV/bin/riscv64-linux-gcc" -dumpfullversion )"
  echo "qemu=$( "$RISCV/bin/qemu-riscv64" --version | head -1 )"
} | tee "$WORK/logs/opencv-shas.txt"
