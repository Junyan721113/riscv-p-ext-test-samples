# RISC-V P Extension Test Samples

## Important

*shell*
```shell
export RISCV=/opt/andes
export OPENCV_TEST_DATA_PATH=**path_to_opencv_extra**/testdata
```

*extra c & cxx flags*
```shell
-mext-dsp
```

*extra exe & shared linker flags*
```shell
-Wl,-Ttext-segment=0x50000
```

## RISC-V P Extension v0.5.2

### Toolchain

Suggested Version: v5_1_1

[nds-gnu-toolchain](https://github.com/andestech/nds-gnu-toolchain)

Prebuilt Releases: [Andes-Development-Kit](https://github.com/andestech/Andes-Development-Kit/releases)

*build_linux_toolchain.sh*
```shell
TARGET=riscv64-linux
PREFIX=/opt/andes
ARCH=rv64imafdcxandes
ABI=lp64d
CPU=andes-25-series
XLEN=64
BUILD=`pwd`/build-nds64le-linux-glibc-v5d
```

### Qemu

[qemu](https://github.com/andestech/qemu/tree/ast-v5_2_0-RVP-branch)

*shell*
```shell
../configure --prefix=/opt/andes --target-list=riscv32-linux-user,riscv64-linux-user --disable-werror --static
```

### Board

Use the installed toolchain's sysroot, or the prebuilt releases above.

*/etc/ld.so.conf*
```shell
include /etc/ld.so.conf.d/*.conf
/path/to/the/sysroot/library
```

*shell*
```shell
ldconfig -v
```

Then the sysroot library should appear in the result.

### OpenCV Test

[OpenCV](https://github.com/opencv/opencv)

*shell*
```shell
cmake -D CMAKE_BUILD_TYPE=Debug -D CMAKE_INSTALL_PREFIX=/opt/andes -D BUILD_SHARED_LIBS=OFF -D CMAKE_TOOLCHAIN_FILE=../platforms/linux/riscv64-andes-gcc.toolchain.cmake ..
```

### Test Tips

dnn module test
*shell*
```
qemu-riscv64 -cpu andes-ax25 -L /opt/riscv/sysroot opencv_test_dnn
# int8layers/layers_common_simd.hpp
# --gtest_filter=*Int8*
# --gtest_filter=*Conv*
# --gtest_filter=*Gemm*
```

imgproc module test
*shell*
```
qemu-riscv64 -cpu andes-ax25 -L /opt/riscv/sysroot opencv_test_imgproc
# imgwarp.rvp.cpp
# --gtest_filter=*Affine*
#
# resize.rvp.cpp
# --gtest_filter=*Resize*
#
# sumpixels.simd.hpp
# --gtest_filter=*Integ*
```

features2d module test
*shell*
```
qemu-riscv64 -cpu andes-ax25 -L /opt/riscv/sysroot opencv_test_features2d
# fast.rvp.cpp
# --gtest_filter=*FAST*
# --gtest_filter=*ORB*
```


## RISC-V P Extension v0.9.11

### Toolchain

[riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)

[riscv-gcc](https://github.com/plctlab/riscv-gcc)

[riscv-binutils-gdb](https://github.com/plctlab/riscv-binutils-gdb)

*shell*
```shell
git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git
git clone https://github.com/plctlab/riscv-gcc.git -b riscv-gcc-p-ext
git clone https://github.com/plctlab/riscv-binutils-gdb.git -b riscv-binutils-p-ext
cd riscv-gnu-toolchain
sudo ./configure --prefix=/opt/riscv --with-arch=rv64imafd_zicsr_zifencei_zpn --with-abi=lp64d --with-gcc-src=/home/mzero/workspace/riscv-gcc --with-binutils-src=/home/mzero/workspace/riscv-binutils-gdb
sudo make linux -j4
```

### Spike

[riscv-isa-sim](https://github.com/riscv-software-src/riscv-isa-sim)

*shell*
```shell
git clone https://github.com/riscv-software-src/riscv-isa-sim.git
cd riscv-isa-sim
mkdir build
cd build
../configure --prefix=$RISCV --with-isa=rv64imafdp --with-target=riscv64-unknown-linux-gnu
make -j4
sudo make install
```

### Proxy Kernel

[riscv-pk](https://github.com/riscv-software-src/riscv-pk)

*shell*
```shell
git clone https://github.com/riscv-software-src/riscv-pk.git
cd riscv-pk
mkdir build
../configure --prefix=$RISCV --host=riscv64-unknown-linux-gnu --with-arch=rv64imafd_zicsr_zifencei_zpn --with-abi=lp64d
make -j4
sudo make install
```

### Trick

*rvp_intrinsic.h*
```shell
//CREATE_RVP_INTRINSIC_EMPTY_ARGS (void, clrov)
//CREATE_RVP_INTRINSIC_EMPTY_ARGS (uintXLEN_t, rdov)
```

### Cross Compile

#### VSCode CMake & CMake Tools Extensions

*shell*
```shell
cmake --no-warn-unused-cli -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -DCMAKE_BUILD_TYPE:STRING=Debug -DCMAKE_C_COMPILER:FILEPATH=/opt/riscv/bin/riscv64-unknown-linux-gnu-gcc -DCMAKE_CXX_COMPILER:FILEPATH=/opt/riscv/bin/riscv64-unknown-linux-gnu-g++ -S/home/mzero/workspace/rvtest -B/home/mzero/workspace/rvtest/build -G Ninja
```

### Run

*shell*
```shell
cd build

spike pk spike-test
bbl loader
bcdf10dec0df0cde

spike pk asm-test
bbl loader
bcdeffffc0deffff

spike pk intrin-test
bbl loader
bcdeffffc0deffff

spike pk intrin-test-2
bbl loader
ffffc0deffffbcde
```

### Important

*cpp file*
```cpp
//Little-Endian Style
uint64_t intA = 0xFBCDAFCDFFCDABCD; 
uint16x4_t vecA = {0xABCD, 0xFFCD, 0xAFCD, 0xFBCD};
```
