#!/usr/bin/env python3
"""
Check dram.dat against Lab09 spec constraints:
  - All field values within valid ranges
  - Date is a legal calendar date (day >= 1)
  - sales < level_threshold(level)
"""

import sys
import os

# ================================================================
# Config
# ================================================================
DRAM_FILE      = "./DRAM/dram.dat"
DRAM_BASE_ADDR = 0x10000
DATA_NUM       = 128
BYTES_PER_SHOP = 16


# ================================================================
# Spec helper functions
# ================================================================
def month_max_day(month: int) -> int:
    if month in [1, 3, 5, 7, 8, 10, 12]:
        return 31
    if month in [4, 6, 9, 11]:
        return 30
    if month == 2:
        return 28
    return -1  # illegal month


def level_threshold(level: int) -> int:
    lv10 = 10 if level >= 100 else level // 10
    return 10 if lv10 == 0 else 10 * lv10


# ================================================================
# Parse dram.dat
# ================================================================
def load_dram(path: str) -> dict:
    """Return {addr: byte_value} from a $readmemh-style .dat file."""
    mem = {}
    current_addr = None

    with open(path, "r") as f:
        for lineno, raw in enumerate(f, 1):
            line = raw.strip()
            if not line or line.startswith("//"):
                continue

            # Remove inline comments
            line = line.split("//")[0].strip()
            if not line:
                continue

            tokens = line.split()
            i = 0
            while i < len(tokens):
                tok = tokens[i]
                if tok.startswith("@"):
                    try:
                        current_addr = int(tok[1:], 16)
                    except ValueError:
                        print(f"[WARN] line {lineno}: bad address token '{tok}'")
                    i += 1
                else:
                    if current_addr is None:
                        print(f"[WARN] line {lineno}: data before any address")
                        i += 1
                        continue
                    try:
                        val = int(tok, 16)
                        mem[current_addr] = val & 0xFF
                        current_addr += 1
                    except ValueError:
                        print(f"[WARN] line {lineno}: bad data token '{tok}'")
                    i += 1
    return mem


def read_byte(mem: dict, addr: int) -> int:
    return mem.get(addr, 0)


def read_64(mem: dict, base: int) -> int:
    """Read 8 bytes little-endian from base, return 64-bit value MSB first."""
    val = 0
    for i in range(7, -1, -1):
        val = (val << 8) | read_byte(mem, base + i)
    return val


def unpack_record(mem: dict, no: int) -> dict:
    base  = DRAM_BASE_ADDR + no * BYTES_PER_SHOP
    data0 = read_64(mem, base)
    data1 = read_64(mem, base + 8)

    return dict(
        no      = no,
        flour   = (data0 >> 52) & 0xFFF,
        butter  = (data0 >> 40) & 0xFFF,
        month   = (data0 >> 32) & 0xFF,
        milk    = (data0 >> 20) & 0xFFF,
        sugar   = (data0 >>  8) & 0xFFF,
        day     = (data0 >>  0) & 0xFF,
        fruit   = (data1 >> 52) & 0xFFF,
        sales   = (data1 >> 40) & 0xFFF,
        staff   = (data1 >> 32) & 0xFF,
        balance = (data1 >>  8) & 0xFFFFFF,
        level   = (data1 >>  0) & 0xFF,
    )


# ================================================================
# Check one record
# ================================================================
def check_record(rec: dict) -> list:
    errors = []
    no = rec["no"]

    # ---- ingredient range [0, 4095] ----
    for field in ["flour", "butter", "milk", "sugar", "fruit"]:
        v = rec[field]
        if not (0 <= v <= 4095):
            errors.append(f"NO{no}: {field}={v} out of range [0,4095]")

    # ---- sales range [0, 4095] ----
    if not (0 <= rec["sales"] <= 4095):
        errors.append(f"NO{no}: sales={rec['sales']} out of range [0,4095]")

    # ---- staff range [0, 100] ----
    if not (0 <= rec["staff"] <= 100):
        errors.append(f"NO{no}: staff={rec['staff']} out of range [0,100]")

    # ---- level range [0, 100] ----
    if not (0 <= rec["level"] <= 100):
        errors.append(f"NO{no}: level={rec['level']} out of range [0,100]")

    # ---- balance range [0, 16777215] ----
    if not (0 <= rec["balance"] <= 0xFFFFFF):
        errors.append(
            f"NO{no}: balance={rec['balance']} out of range [0,16777215]"
        )

    # ---- month range [1, 12] ----
    m = rec["month"]
    if not (1 <= m <= 12):
        errors.append(f"NO{no}: month={m} out of range [1,12]")
        # cannot check day without valid month
    else:
        # ---- day range [1, max_day(month)] ----
        d   = rec["day"]
        max_d = month_max_day(m)
        if not (1 <= d <= max_d):
            errors.append(
                f"NO{no}: day={d} illegal for month={m} "
                f"(valid range [1,{max_d}])"
            )

    # ---- sales < level_threshold ----
    lv  = rec["level"]
    thr = level_threshold(lv)
    if rec["sales"] >= thr:
        errors.append(
            f"NO{no}: sales={rec['sales']} >= threshold={thr} "
            f"(level={lv})"
        )

    return errors


# ================================================================
# Main
# ================================================================
def main():
    path = DRAM_FILE if len(sys.argv) < 2 else sys.argv[1]

    if not os.path.exists(path):
        print(f"[ERROR] File not found: {path}")
        sys.exit(1)

    print(f"Loading {path} ...")
    mem = load_dram(path)
    print(f"  Parsed {len(mem)} bytes")
    print()

    all_errors = []
    records    = []

    for no in range(DATA_NUM):
        rec = unpack_record(mem, no)
        records.append(rec)
        errs = check_record(rec)
        all_errors.extend(errs)

    # ---- Report ----
    if all_errors:
        print(f"[FAIL] Found {len(all_errors)} error(s):\n")
        for e in all_errors:
            print(f"  {e}")
        print()
    else:
        print("[PASS] All 128 records satisfy spec constraints.")
        print()

    # ---- Summary table (first 10 + last 3 for quick sanity) ----
    print("=== Record Summary (NO0~9, NO125~127) ===")
    print(f"{'NO':>4}  {'flour':>5} {'butter':>6} {'milk':>4} "
          f"{'sugar':>5} {'fruit':>5}  "
          f"{'date':>5}  {'sales':>5} {'staff':>5} "
          f"{'bal':>8} {'lv':>3}  {'thr':>3}  {'ok':>2}")
    print("-" * 80)

    show = list(range(10)) + list(range(125, 128))
    for no in show:
        r   = records[no]
        m   = r["month"]
        d   = r["day"]
        thr = level_threshold(r["level"])
        ok  = "OK" if r["sales"] < thr else "NG"
        print(
            f"{no:>4}  {r['flour']:>5} {r['butter']:>6} {r['milk']:>4} "
            f"{r['sugar']:>5} {r['fruit']:>5}  "
            f"{m:>2}/{d:<2}   {r['sales']:>5} {r['staff']:>5} "
            f"{r['balance']:>8} {r['level']:>3}  {thr:>3}  {ok:>2}"
        )

    print()
    if all_errors:
        sys.exit(1)


if __name__ == "__main__":
    main()