import struct

INPUT_FILE = "testcase.txt"
OUTPUT_FILE = "input_decimal.txt"


def hex_to_float32(hex_str: str) -> float:
    bits = int(hex_str, 16)
    return struct.unpack(">f", struct.pack(">I", bits))[0]


def is_8digit_hex(s: str) -> bool:
    if len(s) != 8:
        return False
    try:
        int(s, 16)
        return True
    except ValueError:
        return False


with open(INPUT_FILE, "r") as fin, open(OUTPUT_FILE, "w") as fout:
    for line in fin:
        tokens = line.strip().split()
        converted = []

        for tok in tokens:
            if is_8digit_hex(tok):
                value = hex_to_float32(tok)
                converted.append(f"{value:.10f}")
            else:
                converted.append(tok)

        fout.write(" ".join(converted) + "\n")

print(f"Done. Output written to {OUTPUT_FILE}")