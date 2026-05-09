# Recommended NDSRVP QEMU Environment for OpenCV imgproc Tests

This is the environment I recommend for reproducing OpenCV `hal/ndsrvp`
`opencv_test_imgproc` results without physical AX45 hardware.

## Scope

- Host baseline: Ubuntu 24.04, either native/WSL or Docker.
- Target: riscv64 Linux, Andes P-extension/NDSRVP enabled.
- Emulator: Andes QEMU linux-user mode with `-cpu andes-ax45`.
- OpenCV test target: `opencv_test_imgproc`.
- Purpose: accuracy/regression testing only. This is not a performance
  substitute for a real AX45 board.

## Toolchain

Use the Andes GNU toolchain source branch:

```bash
git clone --branch ast-v5_1_1-release-v5 \
  https://github.com/andestech/nds-gnu-toolchain.git
```

Recommended build settings:

```bash
export WORK=/work/ndsrvp-opencv-pr28915
export RISCV=$WORK/opt/andes
export PATH=$RISCV/bin:$PATH

TARGET=riscv64-linux
PREFIX=$RISCV
ARCH=rv64imafdcxandes
ABI=lp64d
CPU=andes-25-series
XLEN=64
```

Notes:

- `andes-25-series` is the conservative toolchain build CPU that worked with
  the tested v5.1.1 source tree.
- The OpenCV/QEMU test still runs with the AX45 QEMU CPU and `-mext-dsp`.

## QEMU

Recommended QEMU source:

```bash
git clone --branch ast-v5_4_2-release \
  https://github.com/andestech/qemu.git
```

The older `ast-v5_2_0-RVP-branch` was previously used for RVP work, but it may
not be available from upstream now. `ast-v5_4_2-release` is the currently
tested branch with `andes-ax45` linux-user support.

Recommended configure:

```bash
mkdir -p $WORK/build/qemu
cd $WORK/build/qemu
$WORK/src/qemu/configure \
  --prefix=$RISCV \
  --target-list=riscv32-linux-user,riscv64-linux-user \
  --disable-werror \
  --static
make -j$(nproc)
make install
```

Recommended runtime command:

```bash
$RISCV/bin/qemu-riscv64 \
  -cpu andes-ax45 \
  -L $RISCV/sysroot \
  ./opencv_test_imgproc \
  --gtest_filter='*Filter2D*:*padding_bounds*'
```

For the full imgproc test:

```bash
export OPENCV_TEST_DATA_PATH=/path/to/opencv_extra/testdata
$RISCV/bin/qemu-riscv64 \
  -cpu andes-ax45 \
  -L $RISCV/sysroot \
  ./opencv_test_imgproc
```

## OpenCV Build

Recommended OpenCV CMake options:

```bash
cmake -S opencv -B build-opencv -G Ninja \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_TOOLCHAIN_FILE=platforms/linux/riscv64-andes-gcc.toolchain.cmake \
  -D CMAKE_INSTALL_PREFIX=$RISCV/opencv-install \
  -D BUILD_SHARED_LIBS=OFF \
  -D BUILD_TESTS=ON \
  -D BUILD_PERF_TESTS=OFF \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_DOCS=OFF \
  -D BUILD_LIST=core,imgproc,ts \
  -D WITH_NDSRVP=ON \
  -D WITH_HAL_RVV=OFF \
  -D CPU_BASELINE= \
  -D WITH_OPENCL=OFF \
  -D WITH_ITT=OFF

ninja -C build-opencv opencv_test_imgproc -j$(nproc)
```

The CMake log should show:

```text
HAL: YES (ndsrvp ...)
```

At runtime, `opencv_test_imgproc` should also print:

```text
HAL: YES (ndsrvp (ver ...))
```

## Docker

The Docker environment lives in this directory:

```text
opencv-ndsrvp-qemu/
```

Build the image:

```bash
cd opencv-ndsrvp-qemu
docker build -t ndsrvp-opencv-pr28915 .
```

Full source build:

```bash
docker run --rm -it \
  -v "$PWD/cache:/work" \
  -e JOBS=8 \
  ndsrvp-opencv-pr28915

/opt/ndsrvp-scripts/build-toolchain.sh
/opt/ndsrvp-scripts/build-opencv.sh
RUN_BROAD=1 /opt/ndsrvp-scripts/run-imgproc-qemu.sh
```

Reuse a prebuilt toolchain/QEMU:

```bash
docker run --rm -it \
  -v /path/to/andes:/opt/andes:ro \
  -v "$PWD/cache:/work" \
  -e RISCV=/opt/andes \
  -e USE_PREBUILT_RISCV=1 \
  ndsrvp-opencv-pr28915

/opt/ndsrvp-scripts/build-toolchain.sh
/opt/ndsrvp-scripts/build-opencv.sh
/opt/ndsrvp-scripts/run-imgproc-qemu.sh
```

To test the proposed `filter2D()` `BORDER_ISOLATED` workaround discussed in
OpenCV PR #28915:

```bash
APPLY_FILTER2D_ISOLATED_WORKAROUND=1 /opt/ndsrvp-scripts/build-opencv.sh
/opt/ndsrvp-scripts/run-imgproc-qemu.sh
```

The default is `APPLY_FILTER2D_ISOLATED_WORKAROUND=0`, so the Docker path
builds the PR source unless this option is explicitly enabled.

Expected resources:

- First source build may take multiple hours.
- Disk use can be tens of GB.
- Keeping `/work` as a persistent mounted cache is strongly recommended.

## Current Local Validation Snapshot

Local environment used for PR #28915 validation:

```text
OpenCV 4.x: 9929b5ceb915fd48dd9281aef6e5f5cc68705188
PR #28915:  d8c068c134c5c3c58d8a0b6e0f80a6767efa5892
Toolchain:  andestech/nds-gnu-toolchain ast-v5_1_1-release-v5
QEMU:       andestech/qemu ast-v5_4_2-release
QEMU CPU:   andes-ax45
```

The Docker scripts intentionally keep logs and XML under:

```text
/work/ndsrvp-opencv-pr28915/logs/
```
