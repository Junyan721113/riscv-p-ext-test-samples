cmake_minimum_required (VERSION 3.8)

project ("ndsrvptest")

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mext-dsp")
SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mext-dsp")
SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}")
SET(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}")

add_executable(spike-test "spike-test.cpp")
add_executable(asm-test "asm-test.cpp")
add_executable(intrin-test "intrin-test.cpp")
add_executable(intrin-test-2 "intrin-test-2.cpp")
