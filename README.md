# RISC-V P Extension Test Samples

## Note

```shell
export RISCV=/opt/riscv
```

## RISC-V P Extension v0.9.11

### Toolchain

[riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)

[riscv-gcc](https://github.com/plctlab/riscv-gcc)

[riscv-binutils-gdb](https://github.com/plctlab/riscv-binutils-gdb)

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

```shell
git clone https://github.com/riscv-software-src/riscv-pk.git
cd riscv-pk
mkdir build
../configure --prefix=$RISCV --host=riscv64-unknown-linux-gnu --with-arch=rv64imafd_zicsr_zifencei_zpn --with-abi=lp64d
make -j4
sudo make install
```

### Trick

#### rvp_intrinsic.h

```shell
//CREATE_RVP_INTRINSIC_EMPTY_ARGS (void, clrov)
//CREATE_RVP_INTRINSIC_EMPTY_ARGS (uintXLEN_t, rdov)
```

### Cross Compile

#### VSCode CMake & CMake Tools Extensions

```shell
cmake --no-warn-unused-cli -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE -DCMAKE_BUILD_TYPE:STRING=Debug -DCMAKE_C_COMPILER:FILEPATH=/opt/riscv/bin/riscv64-unknown-linux-gnu-gcc -DCMAKE_CXX_COMPILER:FILEPATH=/opt/riscv/bin/riscv64-unknown-linux-gnu-g++ -S/home/mzero/workspace/rvtest -B/home/mzero/workspace/rvtest/build -G Ninja
```

### Run

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

```cpp
//Little-Endian Style
uint64_t intA = 0xFBCDAFCDFFCDABCD; 
uint16x4_t vecA = {0xABCD, 0xFFCD, 0xAFCD, 0xFBCD};
```

## RISC-V P Extension v0.5.2

### Toolchain

[nds-gnu-toolchain](https://github.com/andestech/nds-gnu-toolchain)

build_linux_toolchain.sh
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

```shell
../configure --prefix=/opt/andes --target-list=riscv32-linux-user,riscv64-linux-user --disable-werror --static
```

### Run

[OpenCV](https://github.com/opencv/opencv)

```shell
cmake -D CMAKE_BUILD_TYPE=Debug -D CMAKE_INSTALL_PREFIX=/opt/andes -D BUILD_SHARED_LIBS=OFF --toolchain ../platforms/linux/riscv64-andes-gcc.toolchain.cmake ..
```

**Do not use andes sysroot**

**Use riscv sysroot instead**

```
qemu-riscv64 -cpu andes-ax25 -L /opt/riscv/sysroot opencv_test_dnn
```
