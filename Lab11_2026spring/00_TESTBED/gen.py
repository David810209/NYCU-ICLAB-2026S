import re
import argparse
import numpy as np


# ================================================================
# Input Parser
# ================================================================
def parse_sram_input_txt(file_path):
    """
    解析 input_1.txt ~ input_4.txt

    檔案格式範例：
    // SRAM0: 16 images x 256 pixels, sensor RAW+BLC (12-bit)
    // 16 entries x 256 pixels = 4096 values
    // Entry 00
    510 520 500 ...
    ...
    // Entry 01
    ...

    回傳：
        images[0] 是 Entry 00 的 256 筆 pixel
        images[1] 是 Entry 01 的 256 筆 pixel
    """
    images = []
    current_image_data = []

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        line = line.strip()

        if not line:
            continue

        if line.startswith("// Entry"):
            if current_image_data:
                images.append(current_image_data)
                current_image_data = []
            continue

        if line.startswith("//"):
            continue

        hex_values = re.findall(r"\b[0-9A-Fa-f]{3,4}\b", line)
        current_image_data.extend([int(x, 16) for x in hex_values])

    if current_image_data:
        images.append(current_image_data)

    return images


def load_one_image(sram_id, img_id):
    """
    sram_id:
        0 -> input_1.txt
        1 -> input_2.txt
        2 -> input_3.txt
        3 -> input_4.txt

    img_id:
        0 ~ 15
    """
    if sram_id < 0 or sram_id > 3:
        raise ValueError("sram must be 0, 1, 2, or 3")

    if img_id < 0 or img_id > 15:
        raise ValueError("img must be 0 ~ 15")

    file_path = f"input_{sram_id + 1}.txt"
    images = parse_sram_input_txt(file_path)

    if len(images) < 16:
        print(f"warning: {file_path} only has {len(images)} images")

    if img_id >= len(images):
        raise ValueError(
            f"{file_path} does not contain image index {img_id}. "
            f"Total images = {len(images)}"
        )

    raw_data = images[img_id]

    if len(raw_data) != 256:
        raise ValueError(
            f"{file_path}, image {img_id} data length mismatch: "
            f"expected 256, got {len(raw_data)}"
        )

    return raw_data, file_path


# ================================================================
# Gain Map Parser
# ================================================================
def parse_gain_map(file_path):
    """
    解析 lsc_gain_map.txt

    順序：
        R  36 values
        Gr 36 values
        Gb 36 values
        B  36 values
    """
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    cleaned_lines = []
    for line in content.splitlines():
        cleaned_lines.append(line.split("//")[0])

    cleaned_content = "\n".join(cleaned_lines)
    hex_values = re.findall(r"\b[0-9A-Fa-f]{3,4}\b", cleaned_content)

    if len(hex_values) < 144:
        raise ValueError(
            f"{file_path} should contain at least 144 HEX values, "
            f"but got {len(hex_values)}"
        )

    all_vals = [int(x, 16) for x in hex_values[:144]]

    tables = {}
    channels = ["R", "Gr", "Gb", "B"]

    for i, ch in enumerate(channels):
        tables[ch] = np.array(all_vals[i * 36 : (i + 1) * 36]).reshape(6, 6)

    return tables


# ================================================================
# ISP Step 1: BLC + LSC
# ================================================================
def process_isp(raw_1d, mesh_tables):
    BLC_OFFSETS = {
        "R": 64,
        "Gr": 48,
        "Gb": 52,
        "B": 72,
    }

    raw_2d = np.array(raw_1d).reshape(16, 16)
    output = np.zeros((16, 16), dtype=int)

    for y in range(16):
        for x in range(16):
            if y % 2 == 0:
                channel = "R" if x % 2 == 0 else "Gr"
            else:
                channel = "Gb" if x % 2 == 0 else "B"

            I_raw = raw_2d[y, x]
            B = BLC_OFFSETS[channel]
            I_blc = max(0, I_raw - B)

            x0 = min(x // 3, 4)
            y0 = min(y // 3, 4)

            m = mesh_tables[channel]
            g00 = m[y0, x0]
            g01 = m[y0, x0 + 1]
            g10 = m[y0 + 1, x0]
            g11 = m[y0 + 1, x0 + 1]

            rx = min(x - 3 * x0, 2)
            ry = min(y - 3 * y0, 2)

            dx = (rx * 256 + 1) // 3
            ix = 256 - dx
            dy = (ry * 256 + 1) // 3
            iy = 256 - dy

            gain_val = (
                g00 * ix * iy
                + g10 * ix * dy
                + g01 * dx * iy
                + g11 * dx * dy
                + (1 << 15)
            ) >> 16

            p_prime = (I_blc * gain_val + (1 << 9)) >> 10
            output[y, x] = min(p_prime, 4095)

    return output


# ================================================================
# ISP Step 2: DPC
# ================================================================
def apply_dpc(img_2d):
    H, W = img_2d.shape
    padded = np.pad(img_2d, 2, mode="reflect")
    output = np.copy(img_2d)

    TH = 320

    for y in range(H):
        for x in range(W):
            win = padded[y : y + 5, x : x + 5]
            P = win[2, 2]

            directions = {
                "H": [win[2, 0], win[2, 1], win[2, 3], win[2, 4]],
                "V": [win[0, 2], win[1, 2], win[3, 2], win[4, 2]],
                "D1": [win[0, 0], win[1, 1], win[3, 3], win[4, 4]],
                "D2": [win[0, 4], win[1, 3], win[3, 1], win[4, 0]],
            }

            scores = {}
            medians = {}

            for name in ["H", "V", "D1", "D2"]:
                vec = directions[name]
                m_val = int(np.median(vec))
                medians[name] = m_val
                scores[name] = sum(abs(int(p_i) - int(m_val)) for p_i in vec)

            order = ["H", "V", "D1", "D2"]
            best_dir = min(order, key=lambda d: scores[d])
            target = medians[best_dir]

            if abs(int(P) - int(target)) > TH:
                output[y, x] = target
            else:
                output[y, x] = P

    return output


# ================================================================
# ISP Step 3: Demosaicing
# ================================================================
def apply_demosaicing(img_2d):
    H, W = img_2d.shape
    padded = np.pad(img_2d, 1, mode="reflect")

    out_R = np.zeros((H, W), dtype=int)
    out_G = np.zeros((H, W), dtype=int)
    out_B = np.zeros((H, W), dtype=int)

    for y in range(H):
        for x in range(W):
            py = y + 1
            px = x + 1

            C = padded[py, px]
            N = padded[py - 1, px]
            S = padded[py + 1, px]
            E = padded[py, px + 1]
            W_ = padded[py, px - 1]

            NW = padded[py - 1, px - 1]
            NE = padded[py - 1, px + 1]
            SW = padded[py + 1, px - 1]
            SE = padded[py + 1, px + 1]

            if y % 2 == 0:
                if x % 2 == 0:
                    out_R[y, x] = C
                    out_G[y, x] = (N + S + E + W_) // 4
                    out_B[y, x] = (NW + NE + SW + SE) // 4
                else:
                    out_R[y, x] = (W_ + E) // 2
                    out_G[y, x] = C
                    out_B[y, x] = (N + S) // 2
            else:
                if x % 2 == 0:
                    out_R[y, x] = (N + S) // 2
                    out_G[y, x] = C
                    out_B[y, x] = (W_ + E) // 2
                else:
                    out_R[y, x] = (NW + NE + SW + SE) // 4
                    out_G[y, x] = (N + S + E + W_) // 4
                    out_B[y, x] = C

    return out_R, out_G, out_B


# ================================================================
# ISP Step 4: CCM
# ================================================================
def apply_ccm(R, G, B):
    Cint = np.array(
        [
            [1100, -50, -50],
            [-50, 1100, -50],
            [-50, -50, 1100],
        ]
    )

    H, W = R.shape

    final_R = np.zeros((H, W), dtype=int)
    final_G = np.zeros((H, W), dtype=int)
    final_B = np.zeros((H, W), dtype=int)

    for y in range(H):
        for x in range(W):
            rgb_raw = np.array([R[y, x], G[y, x], B[y, x]])

            res = np.dot(Cint, rgb_raw)
            res_rounded = (res + 512) >> 10
            res_clipped = np.clip(res_rounded, 0, 4095)

            final_R[y, x] = res_clipped[0]
            final_G[y, x] = res_clipped[1]
            final_B[y, x] = res_clipped[2]

    return final_R, final_G, final_B


# ================================================================
# Output Helpers
# ================================================================
def write_matrix(fp, mat, upper8=False):
    for row in mat:
        if upper8:
            fp.write(" ".join([f"{(int(v) >> 4):02X}" for v in row]) + "\n")
        else:
            fp.write(" ".join([f"{int(v):03X}" for v in row]) + "\n")


def write_one_output_file(path, header, mat, sram_id, img_id, upper8=False):
    with open(path, "w", encoding="utf-8") as f:
        f.write(header)
        f.write(f"// SRAM {sram_id}, IMG {img_id:02d}\n")
        write_matrix(f, mat, upper8=upper8)


# ================================================================
# Main Processing
# ================================================================
def run_one_image(sram_id, img_id):
    gain_tables = parse_gain_map("lsc_gain_map.txt")
    raw_data, input_file = load_one_image(sram_id, img_id)

    print(f"Read file: {input_file}")
    print(f"Selected SRAM: {sram_id}")
    print(f"Selected IMG : {img_id:02d}")

    lsc_2d = process_isp(raw_data, gain_tables)
    padded_lsc_2d = np.pad(lsc_2d, 2, mode="reflect")

    dpc_2d = apply_dpc(lsc_2d)
    padded_dpc_2d = np.pad(dpc_2d, 1, mode="reflect")

    res_r, res_g, res_b = apply_demosaicing(dpc_2d)

    final_r, final_g, final_b = apply_ccm(res_r, res_g, res_b)

    file_configs = [
        (
            "LSC_result.txt",
            "// After BLC + LSC\n",
            lsc_2d,
            False,
        ),
        (
            "LSC_result_padding.txt",
            "// After BLC + LSC with 2-px Padding\n",
            padded_lsc_2d,
            False,
        ),
        (
            "DPC_result.txt",
            "// After BLC + LSC + DPC\n",
            dpc_2d,
            False,
        ),
        (
            "DPC_result_padding.txt",
            "// After BLC + LSC + DPC with 1-px Padding\n",
            padded_dpc_2d,
            False,
        ),
        (
            "Demosaic_r.txt",
            "// Demosaic R channel\n",
            res_r,
            False,
        ),
        (
            "Demosaic_g.txt",
            "// Demosaic G channel\n",
            res_g,
            False,
        ),
        (
            "Demosaic_b.txt",
            "// Demosaic B channel\n",
            res_b,
            False,
        ),
        (
            "final_result_r.txt",
            "// Final CCM R channel, upper 8-bit of 12-bit result\n",
            final_r,
            True,
        ),
        (
            "final_result_g.txt",
            "// Final CCM G channel, upper 8-bit of 12-bit result\n",
            final_g,
            True,
        ),
        (
            "final_result_b.txt",
            "// Final CCM B channel, upper 8-bit of 12-bit result\n",
            final_b,
            True,
        ),
    ]

    for path, header, mat, upper8 in file_configs:
        write_one_output_file(path, header, mat, sram_id, img_id, upper8=upper8)

    print("ISP Pipeline Process completed.")
    print("Generated files:")
    for path, _, _, _ in file_configs:
        print(f"  {path}")


# ================================================================
# Argument Parser
# ================================================================
def main():
    parser = argparse.ArgumentParser(
        description="ISP pipeline for selected SRAM input and image index"
    )

    parser.add_argument(
        "--sram",
        type=int,
        default=1,
        help="SRAM index: 0~3. Default: 1. 0=input_1.txt, 1=input_2.txt, 2=input_3.txt, 3=input_4.txt",
    )

    parser.add_argument(
        "--img",
        type=int,
        default=6,
        help="Image index inside selected SRAM file: 0~15. Default: 6",
    )

    args = parser.parse_args()

    if args.sram < 0 or args.sram > 3:
        print("error: --sram must be 0~3")
        return

    if args.img < 0 or args.img > 15:
        print("error: --img must be 0~15")
        return

    run_one_image(args.sram, args.img)


if __name__ == "__main__":
    main()