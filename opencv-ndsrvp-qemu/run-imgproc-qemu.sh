#!/usr/bin/env bash
set -uo pipefail

WORK=${WORK:-/work/ndsrvp-opencv-pr28915}
RISCV=${RISCV:-$WORK/opt/andes}
QEMU_CPU=${QEMU_CPU:-andes-ax45}
TIMEOUT_SECONDS=${TIMEOUT_SECONDS:-1800}
OPENCV_TEST_DATA_PATH=${OPENCV_TEST_DATA_PATH:-}

if [ -z "$OPENCV_TEST_DATA_PATH" ] && [ -d "$WORK/src/opencv_extra-4x/testdata" ]; then
  OPENCV_TEST_DATA_PATH="$WORK/src/opencv_extra-4x/testdata"
fi

export RISCV OPENCV_TEST_DATA_PATH
export PATH="$RISCV/bin:$PATH"

LOG_DIR="$WORK/logs/gtest"
mkdir -p "$LOG_DIR"

run_one() {
  local name=$1
  local label=$2
  local filter=$3
  local bin="$WORK/build/opencv-$name/bin/opencv_test_imgproc"
  local base="$LOG_DIR/${name}-${label}"

  "$RISCV/bin/qemu-riscv64" -cpu "$QEMU_CPU" -L "$RISCV/sysroot" \
    "$bin" --gtest_list_tests > "$LOG_DIR/${name}-gtest-list.txt" 2>&1

  echo "Running $name $label: $filter"
  timeout "$TIMEOUT_SECONDS" "$RISCV/bin/qemu-riscv64" -cpu "$QEMU_CPU" -L "$RISCV/sysroot" \
    "$bin" \
    --gtest_filter="$filter" \
    --gtest_output=xml:"$base.xml" \
    > "$base.log" 2>&1
  local status=$?
  echo "$status" > "$base.status"
  echo "$name $label exit=$status log=$base.log xml=$base.xml"
  return 0
}

run_one 4x focused '*Filter2D*:*padding_bounds*'
run_one pr28915 focused '*Filter2D*:*padding_bounds*'

if [ "${RUN_BROAD:-0}" = "1" ]; then
  run_one 4x broad '*:-Imgproc_Hist_Compare.accuracy'
  run_one pr28915 broad '*:-Imgproc_Hist_Compare.accuracy'
fi

{
  echo "WORK=$WORK"
  echo "RISCV=$RISCV"
  echo "QEMU_CPU=$QEMU_CPU"
  echo "TIMEOUT_SECONDS=$TIMEOUT_SECONDS"
  echo "OPENCV_TEST_DATA_PATH=$OPENCV_TEST_DATA_PATH"
  echo "opencv_4x=$(git -C "$WORK/src/opencv-4x" rev-parse HEAD)"
  echo "opencv_pr28915=$(git -C "$WORK/src/opencv-pr28915" rev-parse HEAD)"
  echo "opencv_4x_status=$(cat "$LOG_DIR/4x-focused.status" 2>/dev/null || true)"
  echo "opencv_pr28915_status=$(cat "$LOG_DIR/pr28915-focused.status" 2>/dev/null || true)"
  if [ -f "$LOG_DIR/4x-broad.status" ]; then
    echo "opencv_4x_broad_status=$(cat "$LOG_DIR/4x-broad.status")"
  fi
  if [ -f "$LOG_DIR/pr28915-broad.status" ]; then
    echo "opencv_pr28915_broad_status=$(cat "$LOG_DIR/pr28915-broad.status")"
  fi
} | tee "$LOG_DIR/summary.txt"
