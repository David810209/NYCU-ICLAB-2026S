#!/usr/bin/env python3
import random

DRAM_BASE_ADDR = 0x10000
DATA_NUM = 128
BYTES_PER_SHOP = 16
OUT_FILE = "./DRAM/dram.dat"

SEED = 69
random.seed(SEED)


def level_threshold(level: int) -> int:
    lv10 = 10 if level >= 100 else level // 10
    return 10 if lv10 == 0 else 10 * lv10


def pack_record(
    flour: int,
    butter: int,
    milk: int,
    sugar: int,
    fruit: int,
    month: int,
    day: int,
    sales: int,
    staff: int,
    balance: int,
    level: int,
):
    data0 = (
        ((flour & 0xFFF) << 52)
        | ((butter & 0xFFF) << 40)
        | ((month & 0xFF) << 32)
        | ((milk & 0xFFF) << 20)
        | ((sugar & 0xFFF) << 8)
        | (day & 0xFF)
    )

    data1 = (
        ((fruit & 0xFFF) << 52)
        | ((sales & 0xFFF) << 40)
        | ((staff & 0xFF) << 32)
        | ((balance & 0xFFFFFF) << 8)
        | (level & 0xFF)
    )

    return data0, data1


def write_word_bytes(fd, addr: int, word32: int):
    fd.write(f"@{addr:05x}\n")
    b0 = word32 & 0xFF
    b1 = (word32 >> 8) & 0xFF
    b2 = (word32 >> 16) & 0xFF
    b3 = (word32 >> 24) & 0xFF
    fd.write(f"{b0:02x} {b1:02x} {b2:02x} {b3:02x}\n")


def write_record(fd, no: int, data0: int, data1: int):
    base = DRAM_BASE_ADDR + no * BYTES_PER_SHOP

    fd.write(f"// NO{no}:\n")

    write_word_bytes(fd, base + 0, data0 & 0xFFFFFFFF)
    write_word_bytes(fd, base + 4, (data0 >> 32) & 0xFFFFFFFF)

    write_word_bytes(fd, base + 8, data1 & 0xFFFFFFFF)
    write_word_bytes(fd, base + 12, (data1 >> 32) & 0xFFFFFFFF)


def make_random_record():
    level = random.randint(0, 100)
    sales_max = min(4095, max(0, level_threshold(level) - 1))

    return dict(
        flour=random.randint(0, 4095),
        butter=random.randint(0, 4095),
        milk=random.randint(0, 4095),
        sugar=random.randint(0, 4095),
        fruit=random.randint(0, 4095),
        month=1,
        day=2,
        sales=random.randint(0, sales_max),
        staff=random.randint(0, 100),
        balance=random.randint(0, 0xFFFFFF),
        level=level,
    )


records = []

for no in range(DATA_NUM):
    if no == 0:
        rec = make_random_record()
        rec["staff"] = 0
        rec["month"] = 1
        rec["day"] = 2

    elif no == 1:
        rec = make_random_record()
        rec["flour"] = 0
        rec["butter"] = 0
        rec["milk"] = 0
        rec["sugar"] = 0
        rec["fruit"] = 0
        rec["staff"] = 1
        rec["balance"] = 0
        rec["month"] = 1
        rec["day"] = 2

    elif no == 2:
        rec = make_random_record()
        rec["flour"] = 4095
        rec["butter"] = 4095
        rec["milk"] = 4095
        rec["sugar"] = 4095
        rec["fruit"] = 4095
        rec["staff"] = 100
        rec["balance"] = 0xFFFFFF
        rec["month"] = 1
        rec["day"] = 2

    else:
        rec = make_random_record()
        rec["month"] = 1
        rec["day"] = 2

    records.append(rec)


with open(OUT_FILE, "w") as fd:
    for no, rec in enumerate(records):
        data0, data1 = pack_record(**rec)
        write_record(fd, no, data0, data1)

print(f"Generated {OUT_FILE} with {DATA_NUM} shops.")
print("Special records:")
print("  index 0: staff=0, date=1/2")
print("  index 1: staff=1, stock=0, balance=0, date=1/2")
print("  index 2: stock=4095, staff=100, balance=max, date=1/2")
print("  index 3~127: random legal values, date=1/2")