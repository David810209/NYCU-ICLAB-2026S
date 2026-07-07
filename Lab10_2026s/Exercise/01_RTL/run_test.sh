#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'

run_and_check() {
    local cmd="$1"
    local arg="$2"
    local expected="$3"
    
    if [ -z "$arg" ]; then
        local full_cmd="$cmd"
        printf "Running: %-20s " "$full_cmd"
    else
        local full_cmd="$cmd $arg"
        printf "Running: %-20s " "$full_cmd"
    fi


    if eval "$full_cmd" 2>&1 | grep -q "$expected"; then
        echo -e "${GREEN}[PASS]${NC} Found: \"$expected\""
    else
        echo -e "${RED}[FAIL]${NC} Missing expected output: \"$expected\""
    fi
}

echo -e "${YELLOW}======================================================${NC}"
echo -e "${YELLOW}       Lab10 Auto Grading Script �Ұ�                 ${NC}"
echo -e "${YELLOW}======================================================${NC}"

# ---------------------------------------------------------
# 1. ./00_run_cov
# ---------------------------------------------------------
echo -e "\n${YELLOW}>>> Phase 1: Testing ./00_run_cov <<<${NC}"
run_and_check "./00_run_cov" "" "Congratulations"

for i in {1..5}; do
    run_and_check "./00_run_cov" "FAIL_$i" "Wrong Answer"
done

# ---------------------------------------------------------
# 2. ./01_run
# ---------------------------------------------------------
echo -e "\n${YELLOW}>>> Phase 2: Testing ./01_run <<<${NC}"
run_and_check "./01_run" "" "Congratulations"

# SPEC_1
for i in {1..4}; do run_and_check "./01_run" "SPEC_1_$i" "Assertion 1 is violated"; done

# SPEC_2
for i in {1..4}; do run_and_check "./01_run" "SPEC_2_$i" "Assertion 2 is violated"; done

# SPEC_3
for i in {1..2}; do run_and_check "./01_run" "SPEC_3_$i" "Assertion 3 is violated"; done

# SPEC_4
for i in {1..4}; do run_and_check "./01_run" "SPEC_4_$i" "Assertion 4 is violated"; done

# SPEC_5
for i in {1..4}; do run_and_check "./01_run" "SPEC_5_$i" "Assertion 5 is violated"; done

# SPEC_6
run_and_check "./01_run" "SPEC_6_1" "Assertion 6 is violated"

# SPEC_7
run_and_check "./01_run" "SPEC_7_1" "Assertion 7 is violated"

# SPEC_8
for i in {1..6}; do run_and_check "./01_run" "SPEC_8_$i" "Assertion 8 is violated"; done

# SPEC_9
for i in {1..2}; do run_and_check "./01_run" "SPEC_9_$i" "Assertion 9 is violated"; done

echo -e "\n${YELLOW}======================================================${NC}"
echo -e "${YELLOW}       All Tests Completed!                           ${NC}"
echo -e "${YELLOW}======================================================${NC}"