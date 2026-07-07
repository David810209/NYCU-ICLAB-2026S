#!/usr/bin/env bash
set -euo pipefail

Design="HT"
syn_tcl="syn.tcl"
num_CPU_cores=8

mkdir -p logs results

csv_file="results/cycle_area_perf.csv"
xlsx_file="results/cycle_area_perf.xlsx"

echo "cycle_time,area,performance" > "$csv_file"

for cycle in $(seq 7.6 0.1 11.0); do
    cycle_fmt=$(printf "%.1f" "$cycle")
    syn_log="logs/${Design}_C${cycle_fmt}.log"

    echo "Running CYCLE=${cycle_fmt} ..."

    dcnxt_shell -f "${syn_tcl}" \
        -x "set_host_options -max_cores ${num_CPU_cores}; set CYCLE ${cycle_fmt}" \
        -output_log_file "${syn_log}"

    area=$(grep 'Total cell area:' "Report/${Design}.area" | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tail -n 1)

    if [[ -z "${area}" ]]; then
        echo "Failed to parse area for CYCLE=${cycle_fmt}"
        area="NaN"
        perf="NaN"
    else
        perf=$(awk -v c="$cycle_fmt" -v a="$area" 'BEGIN {printf "%.6f", c*a}')
    fi

    echo "${cycle_fmt},${area},${perf}" >> "$csv_file"
done

python3 - <<'PY'
import pandas as pd

csv_file = "results/cycle_area_perf.csv"
xlsx_file = "results/cycle_area_perf.xlsx"

df = pd.read_csv(csv_file)
df.to_excel(xlsx_file, index=False)

print(f"Generated: {xlsx_file}")
PY

echo "Done."
echo "CSV : ${csv_file}"
echo "XLSX: ${xlsx_file}"