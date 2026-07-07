#!/bin/bash
# regression.sh — randomize SEED / JUMP_MAX / BRANCH_MAX / MEM_START_ACCESS_ADDR
#
# Usage:
#   ./regression.sh                # 預設跑 seed 1..10，只 random 其他參數
#   ./regression.sh 20             # 跑 seed 1..20，只 random 其他參數
#   ./regression.sh 1 100          # 跑 seed 1..100，只 random 其他參數
#   ./regression.sh 42 42          # 只跑 seed 42，只 random 其他參數
#   ./regression.sh -r             # 跑 100 組 random config
#   ./regression.sh -r 30          # 跑 30 組 random config

set -u

RUN_CMD="./01_run_vcs_gate"
LOG_DIR="regression_logs"
PASS_KEYWORD="Congratulations"

mkdir -p "$LOG_DIR"

# ====================================================
# Parse arguments
# ====================================================
RANDOM_MODE=0

if [ $# -ge 1 ] && [ "$1" = "-r" ]; then
    RANDOM_MODE=1
    NUM_RUNS=${2:-100}
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
FAIL_CONFIGS=()

# ====================================================
# Random helpers
# ====================================================
rand_range() {
    local MIN=$1
    local MAX=$2
    echo $(( MIN + RANDOM % (MAX - MIN + 1) ))
}

gen_random_config() {
    local FIXED_SEED=$1

    if [ "$FIXED_SEED" = "RANDOM" ]; then
        SEED=$(( (RANDOM << 16) ^ RANDOM ))
    else
        SEED=$FIXED_SEED
    fi

    # JUMP_MAX: 1 ~ 128
    JUMP_MAX=$(rand_range 1 128)

    # BRANCH_MAX: 0 ~ 63
    BRANCH_MAX=$(rand_range 0 63)

    # MEM_START_ACCESS_ADDR:
    # 你的合法 access range 是 0x1000 ~ 0x2FFE
    # 但如果後面會加 offset，建議不要太靠近邊界
    # 這裡先 random 0x1000 ~ 0x2E00，且對齊 2 bytes
    MEM_DEC=$(rand_range $((0x1000)) $((0x2E00)))
    MEM_DEC=$(( MEM_DEC & ~1 ))
    MEM_START_ACCESS_ADDR=$(printf "16'h%04X" "$MEM_DEC")
}

# ====================================================
# Run one config
# ====================================================
run_one_config() {
    local FIXED_SEED=$1

    gen_random_config "$FIXED_SEED"

    local TAG="seed_${SEED}_jmp_${JUMP_MAX}_br_${BRANCH_MAX}_mem_${MEM_DEC}"
    local LOG="${LOG_DIR}/${TAG}.log"

    printf "[SEED %10d] JUMP_MAX=%3d BRANCH_MAX=%2d MEM_START=%s ... " \
        "$SEED" "$JUMP_MAX" "$BRANCH_MAX" "$MEM_START_ACCESS_ADDR"

    EXTRA_ARGS="+define+SEED=${SEED}"
    EXTRA_ARGS="${EXTRA_ARGS} +define+JUMP_MAX=${JUMP_MAX}"
    EXTRA_ARGS="${EXTRA_ARGS} +define+BRANCH_MAX=${BRANCH_MAX}"
    EXTRA_ARGS="${EXTRA_ARGS} +define+MEM_START_ACCESS_ADDR=${MEM_START_ACCESS_ADDR}"

    $RUN_CMD EXTRA_ARGS="${EXTRA_ARGS}" > "$LOG" 2>&1
    local RC=$?

    if grep -q "$PASS_KEYWORD" "$LOG"; then
        echo "PASS"
        PASS=$((PASS + 1))
    else
        echo "FAIL  (rc=$RC, log: $LOG)"
        FAIL=$((FAIL + 1))
        FAIL_CONFIGS+=("SEED=${SEED}, JUMP_MAX=${JUMP_MAX}, BRANCH_MAX=${BRANCH_MAX}, MEM_START_ACCESS_ADDR=${MEM_START_ACCESS_ADDR}")
    fi
}

# ====================================================
# Main regression
# ====================================================
echo "===================================================="

if [ "$RANDOM_MODE" -eq 1 ]; then
    echo " Regression: ${NUM_RUNS} random configs"
    echo "===================================================="

    declare -A USED_SEEDS

    for i in $(seq 1 "$NUM_RUNS"); do
        while true; do
            TEST_SEED=$(( (RANDOM << 16) ^ RANDOM ))

            if [ -z "${USED_SEEDS[$TEST_SEED]+x}" ]; then
                USED_SEEDS[$TEST_SEED]=1
                break
            fi
        done

        run_one_config "$TEST_SEED"
    done
else
    echo " Regression: SEED ${SEED_START} .. ${SEED_END}, random other configs"
    echo "===================================================="

    for SEED_I in $(seq "$SEED_START" "$SEED_END"); do
        run_one_config "$SEED_I"
    done
fi

# ====================================================
# Summary
# ====================================================
echo "===================================================="
echo " Summary: PASS=${PASS}  FAIL=${FAIL}"

if [ "$FAIL" -gt 0 ]; then
    echo " Failed configs:"
    for cfg in "${FAIL_CONFIGS[@]}"; do
        echo "   ${cfg}"
    done

    echo ""
    echo " Reproduce example:"
    echo "   $RUN_CMD EXTRA_ARGS=\"+define+SEED=<seed> +define+JUMP_MAX=<jump_max> +define+BRANCH_MAX=<branch_max> +define+MEM_START_ACCESS_ADDR=<addr>\""
fi

echo "===================================================="

exit "$FAIL"