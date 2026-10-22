#!/bin/bash
# regression.sh — randomize RANDOM_SEED / VALID_DATE_RATIO
#
# Usage:
#   ./regression.sh          # 預設跑 10 組 random config
#   ./regression.sh 30       # 跑 30 組 random config
#   ./regression.sh -r       # 跑 100 組 random config
#   ./regression.sh -r 30    # 跑 30 組 random config

set -u

RUN_CMD="./01_run_vcs_gate"
PASS_KEYWORD="Congratulations"

# ====================================================
# Parse arguments
# ====================================================
if [ $# -ge 1 ] && [ "$1" = "-r" ]; then
    NUM_RUNS=${2:-100}
elif [ $# -eq 0 ]; then
    NUM_RUNS=100
else
    NUM_RUNS=$1
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
    RANDOM_SEED=$(( (RANDOM << 16) ^ RANDOM ))

    # VALID_DATE_RATIO: 0 ~ 10
    VALID_DATE_RATIO=$(rand_range 0 10)
}

# ====================================================
# Run one config
# ====================================================
run_one_config() {
    gen_random_config

    printf "[RANDOM_SEED %10d] VALID_DATE_RATIO=%2d ... " \
        "$RANDOM_SEED" "$VALID_DATE_RATIO"

    EXTRA_ARGS="+define+SEED=${RANDOM_SEED}"
    EXTRA_ARGS="${EXTRA_ARGS} +define+VALID_DATE_RATIO=${VALID_DATE_RATIO}"

    OUTPUT=$($RUN_CMD EXTRA_ARGS="${EXTRA_ARGS}" 2>&1)
    local RC=$?

    if echo "$OUTPUT" | grep -q "$PASS_KEYWORD"; then
        echo "PASS"
        PASS=$((PASS + 1))
    else
        echo "FAIL  (rc=$RC)"
        FAIL=$((FAIL + 1))
        FAIL_CONFIGS+=("RANDOM_SEED=${RANDOM_SEED}, VALID_DATE_RATIO=${VALID_DATE_RATIO}")

        echo "-------------------- FAIL OUTPUT --------------------"
        echo "$OUTPUT"
        echo "-----------------------------------------------------"
    fi
}

# ====================================================
# Main regression
# ====================================================
echo "===================================================="
echo " Regression: ${NUM_RUNS} random configs"
echo "===================================================="

for i in $(seq 1 "$NUM_RUNS"); do
    run_one_config
done

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
    echo "   $RUN_CMD EXTRA_ARGS=\"+define+RANDOM_SEED=<seed> +define+VALID_DATE_RATIO=<ratio>\""
fi

echo "===================================================="

exit "$FAIL"