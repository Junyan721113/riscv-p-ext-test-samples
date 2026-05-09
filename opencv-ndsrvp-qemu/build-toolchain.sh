#!/usr/bin/env bash
set -euo pipefail

WORK=${WORK:-/work/ndsrvp-opencv-pr28915}
RISCV=${RISCV:-$WORK/opt/andes}
JOBS=${JOBS:-4}
TOOLCHAIN_BRANCH=${TOOLCHAIN_BRANCH:-ast-v5_1_1-release-v5}
QEMU_BRANCH=${QEMU_BRANCH:-ast-v5_2_0-RVP-branch}
QEMU_FALLBACK_BRANCH=${QEMU_FALLBACK_BRANCH:-ast-v5_4_2-release}

mkdir -p "$WORK/src" "$WORK/build" "$WORK/logs" "$WORK/opt"
export RISCV
export PATH="$RISCV/bin:$PATH"

if [ "${USE_PREBUILT_RISCV:-0}" = "1" ] && [ -x "$RISCV/bin/riscv64-linux-gcc" ]; then
  echo "Using prebuilt RISCV=$RISCV"
  "$RISCV/bin/riscv64-linux-gcc" --version | head -1 | tee "$WORK/logs/prebuilt-toolchain.txt"
  exit 0
fi

if [ ! -d "$WORK/src/nds-gnu-toolchain/.git" ]; then
  git clone --depth 1 --branch "$TOOLCHAIN_BRANCH" \
    https://github.com/andestech/nds-gnu-toolchain.git "$WORK/src/nds-gnu-toolchain"
fi

git -C "$WORK/src/nds-gnu-toolchain" submodule update --init --recursive \
  2>&1 | tee "$WORK/logs/nds-gnu-toolchain-submodule.log"

cp "$WORK/src/nds-gnu-toolchain/build_linux_toolchain.sh" "$WORK/scripts-build-toolchain.sh"
sed -i \
  -e "s|^TARGET=.*|TARGET=riscv64-linux|" \
  -e "s|^PREFIX=.*|PREFIX=$RISCV|" \
  -e "s|^ARCH=.*|ARCH=rv64imafdcxandes|" \
  -e "s|^ABI=.*|ABI=lp64d|" \
  -e "s|^CPU=.*|CPU=andes-25-series|" \
  -e "s|^XLEN=.*|XLEN=64|" \
  -e "s|^BUILD=.*|BUILD=$WORK/build/nds64le-linux-glibc-v5d|" \
  -e "s|^MAKE_PARALLEL=.*|MAKE_PARALLEL=-j$JOBS|" \
  "$WORK/scripts-build-toolchain.sh"

sh "$WORK/scripts-build-toolchain.sh" \
  2>&1 | tee "$WORK/logs/build-toolchain-rv64.log"

actual_qemu_branch="$QEMU_BRANCH"
if ! git ls-remote --exit-code --heads https://github.com/andestech/qemu.git "$QEMU_BRANCH" >/dev/null 2>&1; then
  echo "QEMU branch $QEMU_BRANCH not found; falling back to $QEMU_FALLBACK_BRANCH" \
    | tee "$WORK/logs/qemu-branch-fallback.txt"
  actual_qemu_branch="$QEMU_FALLBACK_BRANCH"
fi

if [ ! -d "$WORK/src/qemu/.git" ]; then
  git clone --depth 1 --branch "$actual_qemu_branch" \
    https://github.com/andestech/qemu.git "$WORK/src/qemu"
fi

mkdir -p "$WORK/build/qemu"
(
  cd "$WORK/build/qemu"
  "$WORK/src/qemu/configure" \
    --prefix="$RISCV" \
    --target-list=riscv32-linux-user,riscv64-linux-user \
    --disable-werror \
    --static 2>&1 | tee "$WORK/logs/configure-qemu.log"
  make -j "$JOBS" 2>&1 | tee "$WORK/logs/build-qemu.log"
  make install 2>&1 | tee "$WORK/logs/install-qemu.log"
)

"$RISCV/bin/riscv64-linux-gcc" --version | head -1 | tee "$WORK/logs/toolchain-version.txt"
"$RISCV/bin/qemu-riscv64" --version | head -1 | tee "$WORK/logs/qemu-version.txt"
