import re

INPUT_FILE = "lsc_gain_map.txt"
OUTPUT_FILE = "lsc_gain_init.svh"

def read_hex_values(filename):
    values = []

    with open(filename, "r") as f:
        for line in f:
            line = line.split("//")[0]

            tokens = re.findall(r"[0-9a-fA-F]+", line)

            for token in tokens:
                values.append(token.upper())

    return values


values = read_hex_values(INPUT_FILE)

if len(values) != 144:
    raise ValueError(f"Expected 144 values, but got {len(values)}")

with open(OUTPUT_FILE, "w") as f:
    f.write("// Auto-generated from lsc_gain_map.txt\n")
    f.write("// Format: R(36), Gr(36), Gb(36), B(36)\n\n")

    for ch in range(4):
        if ch == 0:
            f.write("// R channel\n")
        elif ch == 1:
            f.write("// Gr channel\n")
        elif ch == 2:
            f.write("// Gb channel\n")
        else:
            f.write("// B channel\n")

        for idx in range(36):
            value = values[ch * 36 + idx]
            f.write(
                f"            {{2'd{ch}, 6'd{idx}}}: "
                f"lsc_init_value = 12'h{value};\n"
            )

        f.write("\n")

print(f"Generated {OUTPUT_FILE}")