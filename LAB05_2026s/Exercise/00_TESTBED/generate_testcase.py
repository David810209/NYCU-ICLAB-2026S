import numpy as np
# =========================================================
# Utility
# =========================================================
def gen_signed4(shape, rng):
    return rng.randint(-8, 8, size=shape).astype(np.int8)

def gen_image_u8(shape, rng):
    return rng.randint(0, 256, size=shape).astype(np.uint8)

def clip_u8(x):
    return np.clip(x, 0, 255).astype(np.uint8)

def arshift(x, bits):
    return np.asarray(x, dtype=np.int64) >> bits

# =========================================================
# Hex formatter
# =========================================================
def to_hex_unsigned(val, bits):
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return format(int(val) & mask, '0{}X'.format(width))

def to_hex_signed(val, bits):
    mask = (1 << bits) - 1
    width = (bits + 3) // 4
    return format(int(val) & mask, '0{}X'.format(width))

# =========================================================
# Convolution with ZERO PADDING
# =========================================================
def conv2d_stride4_input1_output16(img_u8, weight_s4):
    # img_u8: (64, 64), uint8
    # weight_s4: (3, 3, 1, 16)
    # output: (16, 16, 16), int64
    H, W = img_u8.shape
    kh, kw, cin, cout = weight_s4.shape

    if H != 64 or W != 64:
        raise ValueError("Input image must be 64x64")
    if kh != 3 or kw != 3 or cin != 1 or cout != 16:
        raise ValueError("Down-sampling conv weight must be 3x3x1x16")

    pad = 1
    stride = 4

    padded = np.pad(
        img_u8.astype(np.int64),
        ((pad, pad), (pad, pad)),
        mode='constant',
        constant_values=0
    )

    out = np.zeros((16, 16, 16), dtype=np.int64)

    for oy in range(16):
        for ox in range(16):
            sy = oy * stride
            sx = ox * stride
            patch = padded[sy:sy+3, sx:sx+3]

            for co in range(16):
                kernel = weight_s4[:, :, 0, co].astype(np.int64)
                out[oy, ox, co] = np.sum(patch * kernel)

    return out

def conv2d_same_16to1(feat_hwc_s8, weight_s4):
    # feat_hwc_s8: (16,16,16)
    # weight_s4: (3,3,16,1)
    # output: (16,16), int64
    H, W, C = feat_hwc_s8.shape
    kh, kw, cin, cout = weight_s4.shape

    if H != 16 or W != 16 or C != 16:
        raise ValueError("Input feature map must be 16x16x16")
    if kh != 3 or kw != 3 or cin != 16 or cout != 1:
        raise ValueError("Up-sampling conv weight must be 3x3x16x1")

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
# Reorder / Restore
# =========================================================
def feature_map_to_matrix(feat_hwc_u8):
    # (16,16,16) -> (256,16)
    return feat_hwc_u8.reshape(256, 16).astype(np.int64)

def matrix_to_feature_map(mat):
    # (256,16) -> (16,16,16)
    return mat.reshape(16, 16, 16)

# =========================================================
# Linear / Norm / Attention / FFN
# =========================================================
def linear_transform(x_256x16, w_16x16):
    return x_256x16.astype(np.int64).dot(w_16x16.astype(np.int64))

def norm_shift4(x):
    return arshift(x, 4)

def softmax_piecewise_linear(score_256x256):
    clipped = np.clip(score_256x256, -2048, 2047).astype(np.int64)
    fixpoint = np.clip((clipped >> 4) + 128, 0, 255).astype(np.int64)
    return fixpoint
def write_soft_and_reorder(soft, soft_path="soft.txt", reorder_path="reorder.txt"):
    # soft shape: (256, 256)
    
    # 1. 寫入 soft.txt: 原始 256x256 矩陣 (每行 256 筆)
    with open(soft_path, "w") as f:
        for row in range(256):
            row_data = [to_hex_unsigned(x, 8) for x in soft[row, :]]
            f.write(" ".join(row_data) + "\n")

    # 2. 寫入 reorder.txt: 32 組 8x8 方塊
    with open(reorder_path, "w") as f:
        # 總共要 32 組
        for group in range(32):
            col_start = group * 8
            col_end = col_start + 8
            
            # 每組取 8 條 Row (Row 0 ~ Row 7)
            for row_idx in range(8):
                # 取出 Row n 的這 8 個 column 資料
                tile_row = soft[row_idx, col_start:col_end]
                hex_row = [to_hex_unsigned(x, 8) for x in tile_row]
                f.write(" ".join(hex_row) + "\n")
            
            # 每組 8x8 結束後，依照你的要求多換一行（方便視覺區隔）
            f.write("\n")

def attention_block(q, k, v):
    # score = (QK^T) / sqrt(d), d=16 => divide by 4 => right shift 2
    score = (q.astype(np.int64).dot(k.astype(np.int64).T)) >> 2
    soft = softmax_piecewise_linear(score)
    write_soft_and_reorder(soft, "soft.txt", "reorder.txt")
    out_full = soft.astype(np.int64).dot(v.astype(np.int64))
    out_s8 = np.clip(out_full >> 16, -128, 127).astype(np.int8)
    return out_s8

def ffn_block(x_256x16_s8, w_ffn_16x16):
    # Linear transformation
    tmp = x_256x16_s8.astype(np.int64).dot(w_ffn_16x16.astype(np.int64))
    # Normalization: >> 4
    tmp = tmp >> 4
    # FIX: FFN follows CNN post-processing: +128, ReLU, clip [0, 255]
    tmp = tmp + 128
    tmp = np.clip(tmp, 0, 255).astype(np.uint8)
    return tmp

# =========================================================
# Interpolation
# =========================================================
def interpolate_mode0_nn_16to64(img16):
    # nearest-neighbor interpolation, replicate each pixel into 4x4 block
    return np.repeat(np.repeat(img16, 4, axis=0), 4, axis=1)

def interpolate_mode1_x_16to64(img16):
    # two-point interpolation along x-direction
    out16x64 = np.zeros((16, 64), dtype=np.int64)

    for y in range(16):
        for x in range(16):
            left = int(img16[y, x])

            if x < 15:
                right = int(img16[y, x + 1])
            else:
                left = int(img16[y, x-1])
                right = int(img16[y, x])

            diff = right - left
            diff_shifted = diff >> 2 
            if x < 15:
                out16x64[y, 4*x + 0] = left
                out16x64[y, 4*x + 1] = left + diff_shifted
                out16x64[y, 4*x + 2] = left + diff_shifted * 2
                out16x64[y, 4*x + 3] = left + diff_shifted * 3
            else:
                out16x64[y, 4*x + 0] = right
                out16x64[y, 4*x + 1] = right + diff_shifted
                out16x64[y, 4*x + 2] = right + diff_shifted * 2
                out16x64[y, 4*x + 3] = right + diff_shifted * 3        

    out64x64 = np.repeat(out16x64, 4, axis=0)
    return clip_u8(out64x64)

def interpolate_mode2_y_16to64(img16):
    # two-point interpolation along y-direction
    out64x16 = np.zeros((64, 16), dtype=np.int64)

    for y in range(16):
        for x in range(16):
            top = int(img16[y, x])

            if y < 15:
                bottom = int(img16[y + 1, x])
            else:
                top = int(img16[y-1, x])
                bottom = int(img16[y, x])

            diff = bottom - top
            diff_shifted = diff >> 2 
            if y < 15:
                out64x16[4*y + 0, x] = top
                out64x16[4*y + 1, x] = top + diff_shifted
                out64x16[4*y + 2, x] = top + diff_shifted * 2
                out64x16[4*y + 3, x] = top + diff_shifted * 3
            else:
                out64x16[4*y + 0, x] = bottom
                out64x16[4*y + 1, x] = bottom + diff_shifted
                out64x16[4*y + 2, x] = bottom + diff_shifted * 2
                out64x16[4*y + 3, x] = bottom + diff_shifted * 3

    out64x64 = np.repeat(out64x16, 4, axis=1)
    return clip_u8(out64x64)

def interpolate_16to64(img16, mode):
    img16 = np.asarray(img16, dtype=np.int64)
    img16 = np.clip(img16, 0, 255)

    if mode == 0:
        return interpolate_mode0_nn_16to64(img16)
    elif mode == 1:
        return interpolate_mode1_x_16to64(img16)
    elif mode == 2:
        return interpolate_mode2_y_16to64(img16)
    else:
        raise ValueError("Interpolation mode must be 0, 1, or 2")

# =========================================================
# One iteration
# =========================================================
def write_attn_s8_hex(filename, attn_s8):
    # attn_s8 shape: (256, 16)
    with open(filename, "w") as f:
        for i in range(256):
            # 取出第 i 個 row 的 16 個數值
            # 使用 to_hex_unsigned(x, 8) 可以得到如 'E0', '09' 這種 2 位 16 進制
            row_data = [to_hex_unsigned(x, 8) for x in attn_s8[i, :]]
            f.write(" ".join(row_data) + "\n")
def write_out_to_txt(out, output_file="conv_out.txt"):
    with open(output_file, "w") as f:
        for row in out:
            f.write(" ".join(str(x) for x in row) + "\n")
def one_iteration(img_u8, weights, interp_mode):
    w_down = weights["down"]
    w_q    = weights["q"]
    w_k    = weights["k"]
    w_v    = weights["v"]
    w_ffn  = weights["ffn"]
    w_up   = weights["up"]

    # 1) Down-sampling convolution: 64x64 -> 16x16x16
    conv_out = conv2d_stride4_input1_output16(img_u8, w_down)

    # FIX: Normalization >> 6, then + 128 (midpoint), then ReLU + clip [0, 255]
    shifted = (conv_out >> 6) + 128

    # ReLU + clip
    shifted_u8 = clip_u8(np.maximum(shifted, 0))
    # 2) Reorder to 256x16
    mat_256x16 = feature_map_to_matrix(shifted_u8)
    # for i in range(mat_256x16.shape[0]):
    #     print(" ".join(f"{int(x):02X}" for x in mat_256x16[i]))
    # for c in range(shifted_u8.shape[2]):
    #     print(f"channel {c:02d}")
    #     for i in range(shifted_u8.shape[0]):
    #         print(" ".join(f"{int(x):02X}" for x in shifted_u8[i, :, c]))
    #     print()
    # 3) calc value = conv output - 128
    calc_value = mat_256x16.astype(np.int64) - 128

    # 4) Q / K / V linear transform + norm (>> 4) + clip to signed 8-bit [-128, 127]
    q_raw = norm_shift4(linear_transform(calc_value, w_q))
    k_raw = norm_shift4(linear_transform(calc_value, w_k))
    v_raw = norm_shift4(linear_transform(calc_value, w_v))

    q = np.clip(q_raw, -128, 127).astype(np.int8)
    k = np.clip(k_raw, -128, 127).astype(np.int8)
    v = np.clip(v_raw, -128, 127).astype(np.int8)

    # 5) Attention
    attn_s8 = attention_block(q, k, v)

    # 6) FFN: linear transform + norm (>> 4) + 128 + ReLU + clip [0, 255]
    ffn_out = ffn_block(attn_s8, w_ffn)

    # 7) Restore to 16x16x16
    feat_hwc = matrix_to_feature_map(ffn_out)

    # 8) Up-sampling convolution: 16x16x16 -> 16x16
    up16 = conv2d_same_16to1(feat_hwc, w_up)
    write_out_to_txt(up16, "up16.txt")
    # FIX: Up-sampling conv also has normalization >> 6, then + 128, ReLU + clip [0, 255]
    up16_u8 = clip_u8(np.maximum((up16 >> 6) + 128, 0))
    write_out_to_txt(up16_u8, "up16_u8.txt")
    # 10) Interpolation: 16x16 -> 64x64
    interp64 = interpolate_16to64(up16_u8, interp_mode)

    # 11) denoise image = min(255, max(0, input image - (interp64 >> 3)))
    scaled_noise = interp64.astype(np.int16) >> 3
    denoise = img_u8.astype(np.int16) - scaled_noise
    denoise = clip_u8(denoise)

    return denoise, calc_value, q, k, v, attn_s8, ffn_out

# =========================================================
# Hex writers
# =========================================================
def write_matrix_u8_hex(f, arr2d):
    h, w = arr2d.shape
    for i in range(h):
        row = []
        for j in range(w):
            row.append(to_hex_unsigned(arr2d[i, j], 8))
        f.write(" ".join(row) + "\n")

def write_matrix_s4_hex(f, arr2d):
    h, w = arr2d.shape
    for i in range(h):
        row = []
        for j in range(w):
            row.append(to_hex_signed(arr2d[i, j], 4))
        f.write(" ".join(row) + "\n")

# =========================================================
# File output
# =========================================================
def write_testcase(filename, iterations, mode, image, weights):
    with open(filename, "w") as f:
        

        # f.write("=== Down Sampling Conv Weights: 3x3x1x16 ===\n")
        for co in range(16):
            # f.write("[out_channel {}]\n".format(co))
            for ky in range(3):
                row = []
                for kx in range(3):
                    row.append(to_hex_signed(weights["down"][ky, kx, 0, co], 4))
                f.write(" ".join(row) + "\n")

        # f.write("=== Q Weights: 16x16 ===\n")
        write_matrix_s4_hex(f, weights["q"])

        # f.write("=== K Weights: 16x16 ===\n")
        write_matrix_s4_hex(f, weights["k"])

        # f.write("=== V Weights: 16x16 ===\n")
        write_matrix_s4_hex(f, weights["v"])

        # f.write("=== FFN Weights: 16x16 ===\n")
        write_matrix_s4_hex(f, weights["ffn"])

        # f.write("=== Up Sampling Conv Weights: 3x3x16x1 ===\n")
        for ci in range(16):
            # f.write("[in_channel {}]\n".format(ci))
            for ky in range(3):
                row = []
                for kx in range(3):
                    row.append(to_hex_signed(weights["up"][ky, kx, ci, 0], 4))
                f.write(" ".join(row) + "\n")
        f.write(to_hex_unsigned(iterations, 4) + "\n")
        f.write(to_hex_unsigned(mode, 4) + "\n")
        # f.write("=== Input Image: 64x64 unsigned 8-bit ===\n")
        write_matrix_u8_hex(f, image)

def write_answer(filename, denoise_history):
    with open(filename, "w") as f:
        for it in range(len(denoise_history)):
            # f.write("=== Iteration {} Denoised Image ===\n".format(it + 1))
            write_matrix_u8_hex(f, denoise_history[it])
            if it != len(denoise_history) - 1:
                f.write("\n")

# =========================================================
# Main
# =========================================================
def main():
    rng = np.random.RandomState()

    # random generate:
    # iterations: 1~7
    # mode: 0~2
    # iterations = rng.randint(1, 8)
    iterations = 1
    mode = rng.randint(0, 3)
    # mode = 2

    weights = {
        "down": gen_signed4((3, 3, 1, 16), rng),
        "q":    gen_signed4((16, 16), rng),
        "k":    gen_signed4((16, 16), rng),
        "v":    gen_signed4((16, 16), rng),
        "ffn":  gen_signed4((16, 16), rng),
        "up":   gen_signed4((3, 3, 16, 1), rng),
    }
    # weights = {
    #     "down": np.full((3, 3, 1, 16), -8, dtype=np.int8),
    #     "q":    np.full((16, 16),      -8, dtype=np.int8),
    #     "k":    np.full((16, 16),      -8, dtype=np.int8),
    #     "v":    np.full((16, 16),      -8, dtype=np.int8),
    #     "ffn":  np.full((16, 16),      -8, dtype=np.int8),
    #     "up":   np.full((3, 3, 16, 1), -8, dtype=np.int8),
    # }
    image = gen_image_u8((64, 64), rng)
    # image = np.full((64, 64), 0, dtype=np.uint8)

    write_testcase("testcase.txt", iterations, mode, image, weights)

    current = image.copy()
    denoise_history = []
    calc_value_history = []
    q_history = []
    k_history = []
    v_history = []
    attn_s8_history = []
    ffn_out_history = []
    for _ in range(iterations):
        current, calc_value, q, k, v, attn_s8, ffn_out = one_iteration(current, weights, mode)
        denoise_history.append(current.copy())
        calc_value_history.append(calc_value.copy())
        q_history.append(q.copy())
        k_history.append(k.copy())
        v_history.append(v.copy())
        attn_s8_history.append(attn_s8.copy())
        ffn_out_history.append(ffn_out.copy())

    write_answer("each-iter_result.txt", denoise_history)
    write_answer("answer.txt", [denoise_history[-1]])
    write_answer("calc_value.txt", calc_value_history)
    write_answer("q.txt", q_history)
    write_answer("k.txt", k_history)
    write_answer("v.txt", v_history)
    write_answer("attn_s8.txt", attn_s8_history)
    write_answer("ffn_out.txt", ffn_out_history)
    print("Done.")
    print("Random iterations =", iterations)
    print("Random interpolation mode =", mode)
    print("Generated files:")
    print("  testcase.txt")
    print("  answer.txt")

if __name__ == "__main__":
    main()