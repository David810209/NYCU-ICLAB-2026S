#!/usr/bin/env bash
set -euo pipefail

Design="DCCPU"
syn_tcl="syn.tcl"
num_CPU_cores=8

mkdir -p logs results

csv_file="../02_SYN/results/cycle_area_perf.csv"
csv2_file="../02_SYN/results/cycle_power_perf.csv"

echo "cycle_time,area,performance" > "$csv_file"
echo "cycle_time,total_power,peak_power,performance" > "$csv2_file"
cd ../04_PTPX
cp ptpx.tcl ptpx_original.tcl
cd ../02_SYN
cp syn.tcl syn_original.tcl
for cycle in $(seq 4.1 0.1 5.1); do
    cycle_fmt=$(printf "%.1f" "$cycle")

    # ── 02_SYN ──────────────────────────────────────────
    cd ../02_SYN
    sed -i "11s/set CYCLE.*/set CYCLE ${cycle_fmt}/" syn.tcl
    syn_log="logs/${Design}_C${cycle_fmt}.log"
    echo "Running CYCLE=${cycle_fmt} ..."

    dcnxt_shell -f "${syn_tcl}" \
        -x "set_host_options -max_cores ${num_CPU_cores}" \
        -output_log_file "${syn_log}"

    area=$(grep 'Total cell area:' "Report/${Design}.area" \
           | awk '{print $NF}')

    if [[ -z "${area}" ]]; then
        echo "Failed to parse area for CYCLE=${cycle_fmt}"
        area="NaN"
        perf="NaN"
    else
        perf=$(awk -v c="$cycle_fmt" -v a="$area" 'BEGIN {printf "%.6f", c*a}')
    fi

    echo "${cycle_fmt},${area},${perf}" >> "$csv_file"

    # ── 03_GATE ─────────────────────────────────────────
    cd ../03_GATE
    sed -i "28s/\`define CYCLE_TIME.*\$/\`define CYCLE_TIME ${cycle_fmt}/" PATTERN.v
    ./01_run_vcs_gate

    # ── 04_PTPX ─────────────────────────────────────────
    cd ../04_PTPX
    sed -i "s|report_power > Report/\$DESIGN\\\\_POWER.*|report_power > Report/\$DESIGN\\\\_POWER_${cycle_fmt}|" ptpx.tcl
    pt_shell -f ptpx.tcl | tee CORE_power.log

    total_power=$(grep 'Total Power' "Report/${Design}_POWER_${cycle_fmt}" \
              | awk -F'=' '{print $2}' | awk '{print $1}')
    peak_power=$(grep 'Peak Power' "Report/${Design}_POWER_${cycle_fmt}" \
             | awk -F'=' '{print $2}' | awk '{print $1}')

    if [[ -z "${total_power}" || -z "${peak_power}" ]]; then
        echo "Failed to parse power for CYCLE=${cycle_fmt}"
        total_power="NaN"
        peak_power="NaN"
        perf2="NaN"
    else
        perf2=$(awk -v c="$cycle_fmt" -v tp="$total_power" -v pp="$peak_power" \
                'BEGIN {printf "%.6e", c*tp*pp}')
    fi

    echo "${cycle_fmt},${total_power},${peak_power},${perf2}" >> "$csv2_file"

done
cd ../03_GATE
rm PATTERN.v
ln -s ../00_TESTBED/PATTERN.v PATTERN.v
cd ../04_PTPX
cp ptpx_original.tcl ptpx.tcl 
rm ptpx_original.tcl
cd ../02_SYN
cp syn_original.tcl syn.tcl 
rm syn_original.tcl
echo "Done."
echo "CSV1: ${csv_file}"
echo "CSV2: ${csv2_file}"