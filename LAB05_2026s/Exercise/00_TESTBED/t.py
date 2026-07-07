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

def arshift(x, bits):
    return np.asarray(x, dtype=np.int64) >> bits

def to_hex_unsigned(val, bits):
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return format(int(val) & mask, '0{}X'.format(width))

def to_hex_signed(val, bits):
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return format(int(val) & mask, '0{}X'.format(width))

# =========================================================
# Convolution Kernels
# =========================================================
def conv2d_stride4_input1_output16(img_u8, weight_s4):
    H, W = img_u8.shape
    kh, kw, cin, cout = weight_s4.shape
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
    H, W, C = feat_hwc_s8.shape
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

# =========================================================
# File I/O
# =========================================================
def write_matrix_u8_hex(f, arr2d):
    for row in arr2d:
        f.write(" ".join(to_hex_unsigned(x, 8) for x in row) + "\n")

def write_weights_once(filename, weights):
    with open(filename, "w") as f:
        # down: 3x3x1x16
        for co in range(16):
            for ky in range(3):
                f.write(" ".join(
                    to_hex_signed(weights["down"][ky, kx, 0, co], 4)
                    for kx in range(3)
                ) + "\n")

        # q, k, v, ffn: each 16x16
        for name in ["q", "k", "v", "ffn"]:
            for row in weights[name]:
                f.write(" ".join(to_hex_signed(x, 4) for x in row) + "\n")

        # up: 3x3x16x1
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
    m = "w" if is_first else "a"
    with open(filename, m) as f:
        if not is_first:
            f.write("\n")
        for i, img in enumerate(history):
            write_matrix_u8_hex(f, img)
            if i < len(history) - 1:
                f.write("\n")

# =========================================================
# Entry Point
# =========================================================
def main():
    rng = np.random.RandomState()

    NUM_TESTCASES = 15

    # 整份 testcase.txt 只用一組固定 weights
    weights = {
        "down": gen_signed4((3, 3, 1, 16), rng),
        "q":    gen_signed4((16, 16), rng),
        "k":    gen_signed4((16, 16), rng),
        "v":    gen_signed4((16, 16), rng),
        "ffn":  gen_signed4((16, 16), rng),
        "up":   gen_signed4((3, 3, 16, 1), rng),
    }

    # 先清空 testcase / answer
    open("testcase.txt", "w").close()
    open("answer.txt", "w").close()

    # testcase.txt 開頭只寫一次 weights
    write_weights_once("testcase.txt", weights)

    for i in range(NUM_TESTCASES):
        print(f"Generating Testcase {i + 1}...")

        # iterations = rng.randint(1, 8)   # 1~7
        iterations = 1
        mode = rng.randint(0, 3)
        image = gen_image_u8((64, 64), rng)

        # 每筆 case 只追加 iter, mode, image
        append_testcase_case(
            "testcase.txt",
            iterations,
            mode,
            image,
            is_first_case=(i == 0)
        )

        # 計算答案
        history = []
        curr = image.copy()
        for _ in range(iterations):
            curr = one_iteration(curr, weights, mode)
            history.append(curr.copy())

        # 如果 answer.txt 只要最後一次結果，用這行
        write_answer("answer.txt", [history[-1]], is_first=(i == 0))

        # 如果你想保留每次 iteration 的結果，改回這行
        # write_answer("answer.txt", history, is_first=(i == 0))

    print(f"\nSuccess. Generated {NUM_TESTCASES} cases in testcase.txt and answer.txt")

if __name__ == "__main__":
    main()