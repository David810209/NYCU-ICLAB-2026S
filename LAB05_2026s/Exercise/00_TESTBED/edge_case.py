import numpy as np

# =========================================================
# Utility / Helper Functions
# =========================================================

def gen_signed4(shape, rng):
    return rng.randint(-8, 8, size=shape).astype(np.int8)

def gen_image_u8(shape, rng):
    return rng.randint(0, 256, size=shape).astype(np.uint8)

def clip_u8(x):
    return np.clip(x, 0, 255).astype(np.uint8)

def to_hex_unsigned(val, bits):
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return format(int(val) & mask, '0{}X'.format(width))

def to_hex_signed(val, bits):
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return format(int(val) & mask, '0{}X'.format(width))

def parse_hex_unsigned(token):
    return int(token, 16)

def parse_hex_signed(token, bits):
    v = int(token, 16)
    if v >= (1 << (bits - 1)):
        v -= (1 << bits)
    return v


# =========================================================
# Edge Case Generators
# =========================================================

def gen_edge_case_image(case_id):
    img = np.zeros((64, 64), dtype=np.uint8)

    if case_id == 0:
        img.fill(0)  # all black
    elif case_id == 1:
        img.fill(255)  # all white
    elif case_id == 2:
        img.fill(128)  # constant gray
    elif case_id == 3:
        yy, xx = np.indices((64, 64))
        img = ((yy + xx) % 2 * 255).astype(np.uint8)  # checkerboard
    elif case_id == 4:
        img[:, ::2] = 0
        img[:, 1::2] = 255  # vertical stripes
    elif case_id == 5:
        img[::2, :] = 0
        img[1::2, :] = 255  # horizontal stripes
    elif case_id == 6:
        row = np.linspace(0, 255, 64, dtype=np.uint8)
        img = np.tile(row, (64, 1))  # horizontal gradient
    elif case_id == 7:
        col = np.linspace(0, 255, 64, dtype=np.uint8).reshape(64, 1)
        img = np.tile(col, (1, 64))  # vertical gradient
    elif case_id == 8:
        img.fill(0)
        img[24:40, 24:40] = 255  # bright square center
    elif case_id == 9:
        img.fill(255)
        img[24:40, 24:40] = 0  # dark square center
    elif case_id == 10:
        img = np.tri(64, 64, dtype=np.uint8) * 255  # lower triangle
    elif case_id == 11:
        img = np.flipud(np.tri(64, 64, dtype=np.uint8)) * 255
    elif case_id == 12:
        img = np.zeros((64, 64), dtype=np.uint8)
        img[:, 32] = 255  # one vertical line
    elif case_id == 13:
        img = np.zeros((64, 64), dtype=np.uint8)
        img[32, :] = 255  # one horizontal line
    elif case_id == 14:
        img = np.zeros((64, 64), dtype=np.uint8)
        np.fill_diagonal(img, 255)  # diagonal line
    else:
        raise ValueError(f"Unsupported edge image case_id: {case_id}")

    return img.astype(np.uint8)

def gen_edge_case_weights(case_id):
    weights = {}

    if case_id == 0:
        val = 0
        weights["down"] = np.full((3, 3, 1, 16), val, dtype=np.int8)
        weights["q"]    = np.full((16, 16), val, dtype=np.int8)
        weights["k"]    = np.full((16, 16), val, dtype=np.int8)
        weights["v"]    = np.full((16, 16), val, dtype=np.int8)
        weights["ffn"]  = np.full((16, 16), val, dtype=np.int8)
        weights["up"]   = np.full((3, 3, 16, 1), val, dtype=np.int8)

    elif case_id == 1:
        val = 7
        weights["down"] = np.full((3, 3, 1, 16), val, dtype=np.int8)
        weights["q"]    = np.full((16, 16), val, dtype=np.int8)
        weights["k"]    = np.full((16, 16), val, dtype=np.int8)
        weights["v"]    = np.full((16, 16), val, dtype=np.int8)
        weights["ffn"]  = np.full((16, 16), val, dtype=np.int8)
        weights["up"]   = np.full((3, 3, 16, 1), val, dtype=np.int8)

    elif case_id == 2:
        val = -8
        weights["down"] = np.full((3, 3, 1, 16), val, dtype=np.int8)
        weights["q"]    = np.full((16, 16), val, dtype=np.int8)
        weights["k"]    = np.full((16, 16), val, dtype=np.int8)
        weights["v"]    = np.full((16, 16), val, dtype=np.int8)
        weights["ffn"]  = np.full((16, 16), val, dtype=np.int8)
        weights["up"]   = np.full((3, 3, 16, 1), val, dtype=np.int8)

    elif case_id == 3:
        base16 = np.fromfunction(
            lambda i, j: np.where((i + j) % 2 == 0, 7, -8),
            (16, 16), dtype=int
        ).astype(np.int8)

        down = np.fromfunction(
            lambda ky, kx, ci, co: np.where((ky + kx + co) % 2 == 0, 7, -8),
            (3, 3, 1, 16), dtype=int
        ).astype(np.int8)

        up = np.fromfunction(
            lambda ky, kx, ci, co: np.where((ky + kx + ci) % 2 == 0, 7, -8),
            (3, 3, 16, 1), dtype=int
        ).astype(np.int8)

        weights["down"] = down
        weights["q"]    = base16.copy()
        weights["k"]    = -base16.copy()
        weights["v"]    = base16.copy()
        weights["ffn"]  = -base16.copy()
        weights["up"]   = up

    elif case_id == 4:
        weights["down"] = np.zeros((3, 3, 1, 16), dtype=np.int8)
        weights["down"][1, 1, 0, :] = 7

        eye = np.zeros((16, 16), dtype=np.int8)
        np.fill_diagonal(eye, 7)

        weights["q"]    = eye.copy()
        weights["k"]    = eye.copy()
        weights["v"]    = eye.copy()
        weights["ffn"]  = eye.copy()

        weights["up"]   = np.zeros((3, 3, 16, 1), dtype=np.int8)
        weights["up"][1, 1, :, 0] = 7

    else:
        raise ValueError(f"Unsupported edge weight case_id: {case_id}")

    return weights


# =========================================================
# Convolution Kernels
# =========================================================

def conv2d_stride4_input1_output16(img_u8, weight_s4):
    pad, stride = 1, 4
    padded = np.pad(
        img_u8.astype(np.int64),
        ((pad, pad), (pad, pad)),
        mode='constant',
        constant_values=0
    )
    out = np.zeros((16, 16, 16), dtype=np.int64)

    for oy in range(16):
        for ox in range(16):
            sy, sx = oy * stride, ox * stride
            patch = padded[sy:sy+3, sx:sx+3]
            for co in range(16):
                kernel = weight_s4[:, :, 0, co].astype(np.int64)
                out[oy, ox, co] = np.sum(patch * kernel)
    return out

def conv2d_same_16to1(feat_hwc_s8, weight_s4):
    pad = 1
    padded = np.pad(
        feat_hwc_s8.astype(np.int64),
        ((pad, pad), (pad, pad), (0, 0)),
        mode='constant',
        constant_values=0
    )
    out = np.zeros((16, 16), dtype=np.int64)

    for y in range(16):
        for x in range(16):
            patch = padded[y:y+3, x:x+3, :]
            out[y, x] = np.sum(patch * weight_s4[:, :, :, 0].astype(np.int64))
    return out


# =========================================================
# Transformer Blocks
# =========================================================

def softmax_piecewise_linear(score_256x256):
    clipped = np.clip(score_256x256, -2048, 2047).astype(np.int64)
    fixpoint = np.clip((clipped >> 4) + 128, 0, 255).astype(np.int64)
    return fixpoint

def attention_block(q, k, v):
    score = (q.astype(np.int64).dot(k.astype(np.int64).T)) >> 2
    soft = softmax_piecewise_linear(score)
    out_full = soft.astype(np.int64).dot(v.astype(np.int64))
    return np.clip(out_full >> 16, -128, 127).astype(np.int8)

def ffn_block(x_256x16_s8, w_ffn_16x16):
    tmp = x_256x16_s8.astype(np.int64).dot(w_ffn_16x16.astype(np.int64))
    tmp = (tmp >> 4) + 128
    return clip_u8(np.maximum(tmp, 0))


# =========================================================
# Interpolation Modes
# =========================================================

def interpolate_16to64(img16, mode):
    img16 = np.clip(img16.astype(np.int64), 0, 255)

    if mode == 0:
        return np.repeat(np.repeat(img16, 4, axis=0), 4, axis=1).astype(np.uint8)

    elif mode == 1:
        out16x64 = np.zeros((16, 64), dtype=np.int64)
        for y in range(16):
            for x in range(16):
                left = int(img16[y, x])
                if x < 15:
                    right = int(img16[y, x + 1])
                    diff = right - left
                    ds = diff >> 2
                    out16x64[y, 4*x:4*x+4] = [left, left+ds, left+ds*2, left+ds*3]
                else:
                    prev_l = int(img16[y, x-1])
                    curr_r = int(img16[y, x])
                    diff = curr_r - prev_l
                    ds = diff >> 2
                    out16x64[y, 4*x:4*x+4] = [curr_r, curr_r+ds, curr_r+ds*2, curr_r+ds*3]
        return clip_u8(np.repeat(out16x64, 4, axis=0))

    elif mode == 2:
        out64x16 = np.zeros((64, 16), dtype=np.int64)
        for x in range(16):
            for y in range(16):
                top = int(img16[y, x])
                if y < 15:
                    bottom = int(img16[y+1, x])
                    diff = bottom - top
                    ds = diff >> 2
                    out64x16[4*y:4*y+4, x] = [top, top+ds, top+ds*2, top+ds*3]
                else:
                    prev_t = int(img16[y-1, x])
                    curr_b = int(img16[y, x])
                    diff = curr_b - prev_t
                    ds = diff >> 2
                    out64x16[4*y:4*y+4, x] = [curr_b, curr_b+ds, curr_b+ds*2, curr_b+ds*3]
        return clip_u8(np.repeat(out64x16, 4, axis=1))

    else:
        raise ValueError(f"Unsupported mode: {mode}")


# =========================================================
# Core Logic
# =========================================================

def one_iteration(img_u8, weights, interp_mode):
    conv_out = conv2d_stride4_input1_output16(img_u8, weights["down"])
    shifted_u8 = clip_u8(np.maximum((conv_out >> 6) + 128, 0))

    calc_value = shifted_u8.reshape(256, 16).astype(np.int64) - 128
    q = np.clip((calc_value.dot(weights["q"])) >> 4, -128, 127).astype(np.int8)
    k = np.clip((calc_value.dot(weights["k"])) >> 4, -128, 127).astype(np.int8)
    v = np.clip((calc_value.dot(weights["v"])) >> 4, -128, 127).astype(np.int8)

    attn_s8 = attention_block(q, k, v)
    ffn_out = ffn_block(attn_s8, weights["ffn"])

    feat_hwc = ffn_out.reshape(16, 16, 16)
    up16 = conv2d_same_16to1(feat_hwc, weights["up"])
    up16_u8 = clip_u8(np.maximum((up16 >> 6) + 128, 0))

    interp64 = interpolate_16to64(up16_u8, interp_mode)
    denoise = clip_u8(img_u8.astype(np.int16) - (interp64.astype(np.int16) >> 3))

    return denoise

def simulate_case(image, weights, iterations, mode):
    curr = image.copy()
    history = []
    for _ in range(iterations):
        curr = one_iteration(curr, weights, mode)
        history.append(curr.copy())
    return history


# =========================================================
# File I/O
# =========================================================

def write_matrix_u8_hex(f, arr2d):
    for row in arr2d:
        f.write(" ".join(to_hex_unsigned(x, 8) for x in row) + "\n")

def write_weights_once(filename, weights):
    with open(filename, "w") as f:
        for co in range(16):
            for ky in range(3):
                f.write(" ".join(
                    to_hex_signed(weights["down"][ky, kx, 0, co], 4)
                    for kx in range(3)
                ) + "\n")

        for name in ["q", "k", "v", "ffn"]:
            for row in weights[name]:
                f.write(" ".join(to_hex_signed(x, 4) for x in row) + "\n")

        for ci in range(16):
            for ky in range(3):
                f.write(" ".join(
                    to_hex_signed(weights["up"][ky, kx, ci, 0], 4)
                    for kx in range(3)
                ) + "\n")

def append_testcase_case(filename, iterations, mode, image, is_first_case):
    with open(filename, "a") as f:
        if not is_first_case:
            f.write("\n")
        f.write(to_hex_unsigned(iterations, 4) + "\n")
        f.write(to_hex_unsigned(mode, 4) + "\n")
        write_matrix_u8_hex(f, image)

def write_answer(filename, history, is_first):
    mode = "w" if is_first else "a"
    with open(filename, mode) as f:
        if not is_first:
            f.write("\n")
        for i, img in enumerate(history):
            write_matrix_u8_hex(f, img)
            if i < len(history) - 1:
                f.write("\n")


# =========================================================
# Read Back From testcase.txt
# =========================================================

def read_all_nonempty_lines(filename):
    with open(filename, "r") as f:
        return [line.strip() for line in f if line.strip()]

def read_weights_from_lines(lines, start_idx=0):
    idx = start_idx
    weights = {}

    down = np.zeros((3, 3, 1, 16), dtype=np.int8)
    for co in range(16):
        for ky in range(3):
            vals = lines[idx].split()
            idx += 1
            for kx in range(3):
                down[ky, kx, 0, co] = parse_hex_signed(vals[kx], 4)
    weights["down"] = down

    for name in ["q", "k", "v", "ffn"]:
        mat = np.zeros((16, 16), dtype=np.int8)
        for r in range(16):
            vals = lines[idx].split()
            idx += 1
            for c in range(16):
                mat[r, c] = parse_hex_signed(vals[c], 4)
        weights[name] = mat

    up = np.zeros((3, 3, 16, 1), dtype=np.int8)
    for ci in range(16):
        for ky in range(3):
            vals = lines[idx].split()
            idx += 1
            for kx in range(3):
                up[ky, kx, ci, 0] = parse_hex_signed(vals[kx], 4)
    weights["up"] = up

    return weights, idx

def read_cases_from_lines(lines, start_idx):
    cases = []
    idx = start_idx

    while idx < len(lines):
        iterations = parse_hex_unsigned(lines[idx])
        idx += 1

        mode = parse_hex_unsigned(lines[idx])
        idx += 1

        image = np.zeros((64, 64), dtype=np.uint8)
        for r in range(64):
            vals = lines[idx].split()
            idx += 1
            for c in range(64):
                image[r, c] = parse_hex_unsigned(vals[c])

        cases.append({
            "iterations": iterations,
            "mode": mode,
            "image": image
        })

    return cases

def read_testcase_file(filename):
    lines = read_all_nonempty_lines(filename)
    weights, next_idx = read_weights_from_lines(lines, 0)
    cases = read_cases_from_lines(lines, next_idx)
    return weights, cases


# =========================================================
# Generate answer.txt by reading testcase.txt
# =========================================================

def generate_answer_from_testcase(tc_file, ans_file):
    weights, cases = read_testcase_file(tc_file)

    open(ans_file, "w").close()

    for case_idx, case in enumerate(cases):
        history = simulate_case(
            case["image"],
            weights,
            case["iterations"],
            case["mode"]
        )

        write_answer(
            ans_file,
            [history[-1]],
            is_first=(case_idx == 0)
        )


# =========================================================
# Dataset Generators
# =========================================================

def generate_normal_set(rng, tc_file):
    weights = {
        "down": gen_signed4((3, 3, 1, 16), rng),
        "q":    gen_signed4((16, 16), rng),
        "k":    gen_signed4((16, 16), rng),
        "v":    gen_signed4((16, 16), rng),
        "ffn":  gen_signed4((16, 16), rng),
        "up":   gen_signed4((3, 3, 16, 1), rng),
    }

    open(tc_file, "w").close()
    write_weights_once(tc_file, weights)

    case_idx = 0
    for mode in range(3):
        for iterations in range(1, 8):
            image = gen_image_u8((64, 64), rng)

            append_testcase_case(
                tc_file,
                iterations,
                mode,
                image,
                is_first_case=(case_idx == 0)
            )
            case_idx += 1

def generate_abnormal_img_only_set(rng, tc_file):
    weights = {
        "down": gen_signed4((3, 3, 1, 16), rng),
        "q":    gen_signed4((16, 16), rng),
        "k":    gen_signed4((16, 16), rng),
        "v":    gen_signed4((16, 16), rng),
        "ffn":  gen_signed4((16, 16), rng),
        "up":   gen_signed4((3, 3, 16, 1), rng),
    }

    open(tc_file, "w").close()
    write_weights_once(tc_file, weights)

    for case_idx in range(10):
        iterations = (case_idx % 7) + 1
        mode = case_idx % 3
        image = gen_edge_case_image(case_idx)

        append_testcase_case(
            tc_file,
            iterations,
            mode,
            image,
            is_first_case=(case_idx == 0)
        )

def generate_abnormal_weight_only_set(rng, tc_file):
    weights = gen_edge_case_weights(4)  # sparse / identity-like

    open(tc_file, "w").close()
    write_weights_once(tc_file, weights)

    for case_idx in range(5):
        iterations = (case_idx % 7) + 1
        mode = case_idx % 3
        image = gen_image_u8((64, 64), rng)

        append_testcase_case(
            tc_file,
            iterations,
            mode,
            image,
            is_first_case=(case_idx == 0)
        )

def generate_abnormal_both_set(rng, tc_file):
    weights = gen_edge_case_weights(3)  # alternating 7/-8

    open(tc_file, "w").close()
    write_weights_once(tc_file, weights)

    for case_idx in range(15):
        iterations = 1
        mode = case_idx % 3
        image = gen_edge_case_image(case_idx % 15)

        append_testcase_case(
            tc_file,
            iterations,
            mode,
            image,
            is_first_case=(case_idx == 0)
        )


# =========================================================
# Entry Point
# =========================================================

def main():
    rng = np.random.RandomState(1234)

    # 1. 先產生 testcase
    generate_normal_set(
        rng,
        "normal_testcase.txt"
    )

    generate_abnormal_img_only_set(
        rng,
        "abnormal_img_only_testcase.txt"
    )

    generate_abnormal_weight_only_set(
        rng,
        "abnormal_weight_only_testcase.txt"
    )

    generate_abnormal_both_set(
        rng,
        "abnormal_both_testcase.txt"
    )

    # 2. 再從 testcase.txt 讀回來，重新計算 answer
    generate_answer_from_testcase(
        "normal_testcase.txt",
        "normal_answer.txt"
    )

    generate_answer_from_testcase(
        "abnormal_img_only_testcase.txt",
        "abnormal_img_only_answer.txt"
    )

    generate_answer_from_testcase(
        "abnormal_weight_only_testcase.txt",
        "abnormal_weight_only_answer.txt"
    )

    generate_answer_from_testcase(
        "abnormal_both_testcase.txt",
        "abnormal_both_answer.txt"
    )

    print("Done.")
    print("Generated:")
    print("  normal_testcase.txt / normal_answer.txt")
    print("  abnormal_img_only_testcase.txt / abnormal_img_only_answer.txt")
    print("  abnormal_weight_only_testcase.txt / abnormal_weight_only_answer.txt")
    print("  abnormal_both_testcase.txt / abnormal_both_answer.txt")

if __name__ == "__main__":
    main()