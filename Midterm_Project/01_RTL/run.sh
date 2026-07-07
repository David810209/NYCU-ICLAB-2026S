#!/bin/bash
# regression.sh — 用不同 SEED 跑 ./01_run_vcs_rtl
# 透過 +define+SEED=<n> 從命令列覆蓋 PATTERN.v 的 `define SEED
#
# Usage:
#   ./regression.sh                # 預設跑 seed 1..10
#   ./regression.sh 20             # 跑 seed 1..20
#   ./regression.sh 1 100          # 跑 seed 1..100
#   ./regression.sh 42 42          # 只跑 seed 42
#   ./regression.sh -r 30          # 跑 30 個隨機 seed

set -u

RUN_CMD="./01_run_vcs_rtl"
LOG_DIR="regression_logs"
PASS_KEYWORD="Congratulations"

mkdir -p "$LOG_DIR"

# 解析參數
RANDOM_MODE=0
if [ $# -ge 1 ] && [ "$1" = "-r" ]; then
    RANDOM_MODE=1
    NUM_RUNS=${2:-10}
elif [ $# -eq 0 ]; then
    SEED_START=1
    SEED_END=10
elif [ $# -eq 1 ]; then
    SEED_START=1
    SEED_END=$1
else
    SEED_START=$1
    SEED_END=$2
fi

PASS=0
FAIL=0
FAIL_SEEDS=()

run_one_seed() {
    local SEED=$1
    local LOG="${LOG_DIR}/seed_${SEED}.log"
    printf "[SEED %6d] running ... " "$SEED"

    # 把 +define+SEED=<n> 透過 EXTRA_ARGS 傳進 makefile / vcs
    $RUN_CMD EXTRA_ARGS="+define+SEED=${SEED}" > "$LOG" 2>&1
    local RC=$?

    if grep -q "$PASS_KEYWORD" "$LOG"; then
        echo "PASS"
        PASS=$((PASS+1))
    else
        echo "FAIL  (rc=$RC, log: $LOG)"
        FAIL=$((FAIL+1))
        FAIL_SEEDS+=("$SEED")
    fi
}

echo "===================================================="
if [ "$RANDOM_MODE" -eq 1 ]; then
    echo " Regression: ${NUM_RUNS} random seeds"
    echo "===================================================="
    for i in $(seq 1 "$NUM_RUNS"); do
        SEED=$RANDOM
        run_one_seed "$SEED"
    done
else
    echo " Regression: SEED ${SEED_START} .. ${SEED_END}"
    echo "===================================================="
    for SEED in $(seq "$SEED_START" "$SEED_END"); do
        run_one_seed "$SEED"
    done
fi

echo "===================================================="
echo " Summary: PASS=${PASS}  FAIL=${FAIL}"
if [ "$FAIL" -gt 0 ]; then
    echo " Failed seeds: ${FAIL_SEEDS[*]}"
    echo " Reproduce:    $RUN_CMD EXTRA_ARGS=\"+define+SEED=<seed>\""
fi
echo "===================================================="

exit "$FAIL"