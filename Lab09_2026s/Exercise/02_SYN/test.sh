#!/usr/bin/env bash
set -euo pipefail

Design="DSS"
syn_tcl="syn_DSS.tcl"
num_CPU_cores=8

mkdir -p logs results

csv_file="results/cycle_area_perf.csv"
xlsx_file="results/cycle_area_perf.xlsx"

echo "cycle_time,area,performance,note" > "$csv_file"

for cycle in $(seq 2.5 0.1 3.3); do
    cycle_fmt=$(printf "%.1f" "$cycle")
    syn_log="logs/${Design}_C${cycle_fmt}.log"
    check_log="logs/${Design}_C${cycle_fmt}_check.log"

    echo "Running CYCLE=${cycle_fmt} ..."

    dcnxt_shell -f "${syn_tcl}" \
        -x "set_host_options -max_cores ${num_CPU_cores}; set CYCLE ${cycle_fmt}" \
        -output_log_file "${syn_log}"

    ./08_check > "${check_log}" 2>&1 || true

    area=$(grep 'Total cell area:' "Report/${Design}.area" | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | tail -n 1 || true)

    if [[ -z "${area}" ]]; then
        echo "Failed to parse area for CYCLE=${cycle_fmt}"
        area="NaN"
        perf="NaN"
        note="area grep failed"
    else
        perf=$(awk -v c="$cycle_fmt" -v a="$area" 'BEGIN {printf "%.6f", c*a}')
        note=""
    fi

    if grep -q "Fail" "${check_log}"; then
        if [[ -z "${note}" ]]; then
            note="08_check Fail"
        else
            note="${note}; 08_check Fail"
        fi
    fi

    echo "${cycle_fmt},${area},${perf},${note}" >> "$csv_file"
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