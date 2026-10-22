#!/bin/bash

# ==========================================================
# ISP Synthesis Sweep Script - AT Product Optimization
# ==========================================================

# --- 基礎參數設定 ---
DESIGN="ISP"                  # Top Module 名稱
SYN_TCL="syn.tcl"             # 合成腳本
NUM_CPU_CORES=4               # CPU 核心數
REPORT_DIR="Report_Sweep"     # 存放結果資料夾

# 設定掃描範圍 (3.1ns 到 5.0ns, 每 0.2ns 一步)
START=3.1
END=6.0
STEP=0.1

# 建立 Report 資料夾
mkdir -p ${REPORT_DIR}

# 紀錄檔標題 (CSV 格式)
RESULT_CSV="sweep_results.csv"
echo "Cycle(ns),Area,Performance" > ${RESULT_CSV}

echo "Starting Sweep: ${START}ns to ${END}ns (Step: ${STEP}ns)"
echo "--------------------------------------------------------"

# --- 進入循環 ---
curr=$START
while (( $(echo "$curr <= $END" | bc -l) )); do
    
    # 定義本次運行的 Log 與報表名稱
    SYN_LOG="${REPORT_DIR}/syn_${curr}ns.log"
    
    echo -n "Testing Cycle: ${curr}ns ... "

    # 執行助教給的 dcnxt_shell 指令
    # 透過 -x 將 CLK_PERIOD 與 DESIGN 傳入 tcl 環境
    dcnxt_shell -f ${SYN_TCL} \
        -x "set CYCLE ${curr}; set DESIGN ${DESIGN}; set_host_options -max_cores ${NUM_CPU_CORES}" \
        -output_log_file ${SYN_LOG}

    # --- 解析面積 (Total cell area) ---
    AREA=`cat Report/${DESIGN}.area | grep 'Total cell area:' | grep -Eo '[+-]?[0-9]+([.][0-9]+)?'`
    AT2_PRODUCT=$(echo "$curr * ($AREA * $AREA)" | bc -l)
    # 寫入 CSV 檔案
    echo "$curr,$AREA,$AT2_PRODUCT" >> ${RESULT_CSV}

    # 累加步進值
    curr=$(echo "$curr + $STEP" | bc -l)
done

echo "--------------------------------------------------------"
echo "Sweep Finished! Results saved in ${RESULT_CSV}"
sort -t',' -k3 -n ${RESULT_CSV} | head -n 2 | tail -n 1