
import numpy as np
import struct
from pathlib import Path

PAD_ZERO = 0
PAD_REPLICATION = 1

ACT_SIGMOID = 0
ACT_TANH = 1
ACT_RELU = 2
ACT_LEAKY_RELU = 3

OUTPUT_DIR = Path(".")


def float_to_hex(value: float) -> str:
    value32 = np.float32(value)
    bits = struct.unpack(">I", struct.pack(">f", float(value32)))[0]
    return f"{bits:08X}"


def apply_activation(x: np.ndarray, act_type: int) -> np.ndarray:
    x = x.astype(np.float32)
    if act_type == ACT_SIGMOID:
        return (1.0 / (1.0 + np.exp(-x, dtype=np.float32))).astype(np.float32)
    if act_type == ACT_TANH:
        return np.tanh(x).astype(np.float32)
    if act_type == ACT_RELU:
        return np.maximum(x, np.float32(0.0)).astype(np.float32)
    if act_type == ACT_LEAKY_RELU:
        threshold = np.float32(-(2 ** -123))
        alpha = np.float32(0.125)
        return np.where(
            x > 0,
            x,
            np.where(x > threshold, np.float32(0.0), alpha * x)
        ).astype(np.float32)
    raise ValueError("Unknown activation type")


def pad_image(image: np.ndarray, pad_width: int, pad_type: int) -> np.ndarray:
    mode = "constant" if pad_type == PAD_ZERO else "edge"
    if mode == "constant":
        return np.pad(
            image,
            ((0, 0), (pad_width, pad_width), (pad_width, pad_width)),
            mode=mode,
            constant_values=0.0,
        ).astype(np.float32)
    return np.pad(
        image,
        ((0, 0), (pad_width, pad_width), (pad_width, pad_width)),
        mode=mode,
    ).astype(np.float32)


def min_max_scale_per_channel(image: np.ndarray) -> np.ndarray:
    out = np.empty_like(image, dtype=np.float32)
    for c in range(image.shape[0]):
        channel = image[c].astype(np.float32)
        cmin = np.min(channel)
        cmax = np.max(channel)
        if float(cmax - cmin) == 0.0:
            out[c] = np.zeros_like(channel, dtype=np.float32)
        else:
            out[c] = ((channel - cmin) / (cmax - cmin)).astype(np.float32)
    return out


def conv2d_same(image: np.ndarray, weight: np.ndarray, pad_type: int) -> np.ndarray:
    # image: [in_c, h, w]
    # weight: [out_c, in_c, 3, 3]
    in_c, h, w = image.shape
    out_c = weight.shape[0]
    padded = pad_image(image, 1, pad_type)
    out = np.zeros((out_c, h, w), dtype=np.float32)

    for oc in range(out_c):
        for ic in range(in_c):
            for i in range(h):
                for j in range(w):
                    region = padded[ic, i:i + 3, j:j + 3]
                    out[oc, i, j] += np.sum(region * weight[oc, ic], dtype=np.float32)
    return out.astype(np.float32)


def transposed_conv2d_same(image: np.ndarray, weight: np.ndarray, pad_type: int) -> np.ndarray:
    # image: [in_c, h, w]
    # weight: [out_c, in_c, 3, 3]
    # stride = 1, kernel = 3, padding = 1 -> output spatial size = input size
    in_c, h, w = image.shape
    out_c = weight.shape[0]
    out = np.zeros((out_c, h, w), dtype=np.float32)

    for ic in range(in_c):
        for i in range(h):
            for j in range(w):
                val = np.float32(image[ic, i, j])
                for oc in range(out_c):
                    for kh in range(3):
                        for kw in range(3):
                            oi = i + kh - 1
                            oj = j + kw - 1
                            if 0 <= oi < h and 0 <= oj < w:
                                out[oc, oi, oj] += np.float32(val * weight[oc, ic, kh, kw])
    return out.astype(np.float32)


def max_pool_2x2_unique(image: np.ndarray):
    # image: [c, h, w], h and w even
    c, h, w = image.shape
    pooled = np.zeros((c, h // 2, w // 2), dtype=np.float32)
    mask = np.zeros_like(image, dtype=np.float32)

    for ch in range(c):
        for i in range(0, h, 2):
            for j in range(0, w, 2):
                window = image[ch, i:i + 2, j:j + 2].astype(np.float32)
                flat = window.reshape(-1)
                max_val = np.max(flat)
                max_positions = np.where(flat == max_val)[0]
                if len(max_positions) != 1:
                    return None, None, False
                idx = int(max_positions[0])
                pooled[ch, i // 2, j // 2] = max_val
                mask[ch, i + idx // 2, j + idx % 2] = np.float32(1.0)

    return pooled, mask, True


def unpool_2x2(pooled: np.ndarray, mask: np.ndarray) -> np.ndarray:
    # pooled: [c, h, w]
    # mask: [c, 2h, 2w]
    c, h, w = pooled.shape
    out = np.zeros_like(mask, dtype=np.float32)
    for ch in range(c):
        for i in range(h):
            for j in range(w):
                window_mask = mask[ch, 2 * i:2 * i + 2, 2 * j:2 * j + 2]
                positions = np.argwhere(window_mask == 1.0)
                if positions.shape[0] != 1:
                    raise ValueError("Unpooling mask is invalid.")
                di, dj = positions[0]
                out[ch, 2 * i + di, 2 * j + dj] = pooled[ch, i, j]
    return out.astype(np.float32)


def save_tensor_hex(path: Path, tensor: np.ndarray):
    tensor = tensor.astype(np.float32)
    with path.open("w", encoding="utf-8") as f:
        if tensor.ndim == 3:
            for c in range(tensor.shape[0]):
                for row in tensor[c]:
                    f.write(" ".join(float_to_hex(v) for v in row) + "\n")
                if c != tensor.shape[0] - 1:
                    f.write("\n")
        elif tensor.ndim == 4:
            first = True
            for a in range(tensor.shape[0]):
                for b in range(tensor.shape[1]):
                    if not first:
                        f.write("\n")
                    first = False
                    for row in tensor[a, b]:
                        f.write(" ".join(float_to_hex(v) for v in row) + "\n")
        else:
            raise ValueError("Unsupported tensor dimension for text export.")


def save_testcase(path: Path, pad_type: int, act_type: int, weights: np.ndarray, image: np.ndarray):
    with path.open("w", encoding="utf-8") as f:
        f.write(f"{pad_type}\n")
        f.write(f"{act_type}\n")

        first_kernel = True
        for layer in range(weights.shape[0]):          # 4 layers
            for oc in range(weights.shape[1]):         # 2 output channels
                for ic in range(weights.shape[2]):     # 2 input channels
                    if not first_kernel:
                        f.write("\n")
                    first_kernel = False
                    kernel = weights[layer, oc, ic]
                    for row in kernel:
                        f.write(" ".join(float_to_hex(v) for v in row) + "\n")

        f.write("\n")
        for ch in range(image.shape[0]):
            for row in image[ch]:
                f.write(" ".join(float_to_hex(v) for v in row) + "\n")
            if ch != image.shape[0] - 1:
                f.write("\n")

def apply_padding(x, pad, pad_type):
    if pad_type == 0:
        return np.pad(
            x,
            ((0, 0), (pad, pad), (pad, pad)),
            mode="constant",
            constant_values=0
        )
    else:
        return np.pad(
            x,
            ((0, 0), (pad, pad), (pad, pad)),
            mode="edge"
        )
def hex_to_float32(hex_str):
    u = np.uint32(int(hex_str, 16))
    return u.view(np.float32)

def load_case_from_txt(filename):
    with open(filename, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    pad_type = int(lines[0], 16) if any(c in lines[0].upper() for c in "ABCDEF") else int(lines[0])
    act_type = int(lines[1], 16) if any(c in lines[1].upper() for c in "ABCDEF") else int(lines[1])

    hex_tokens = []
    for line in lines[2:]:
        hex_tokens.extend(line.split())

    expected_weights = 4 * 2 * 2 * 3 * 3
    expected_image = 2 * 8 * 8
    expected_total = expected_weights + expected_image

    if len(hex_tokens) < expected_total:
        raise ValueError(f"hex 數量不夠，預期 {expected_total} 個，實際只有 {len(hex_tokens)} 個")

    float_vals = np.array([hex_to_float32(x) for x in hex_tokens[:expected_total]], dtype=np.float32)

    weights = float_vals[:expected_weights].reshape(4, 2, 2, 3, 3)
    image = float_vals[expected_weights:expected_total].reshape(2, 8, 8)

    return pad_type, act_type, weights, image

def generate_case(rng):
    pad_type = int(rng.randint(0, 2))
    act_type = int(rng.randint(0, 4))

    weights = rng.uniform(-1.0, 1.0, size=(4, 2, 2, 3, 3)).astype(np.float32)
    image = rng.uniform(-127.0, 128.0, size=(2, 8, 8)).astype(np.float32)
    # pad_type, act_type, weights, image = load_case_from_txt("testcase.txt")
    scaled = min_max_scale_per_channel(image)
    pad = 1
    scaled_padded = apply_padding(scaled, pad, pad_type)
    conv0 = conv2d_same(scaled, weights[0], pad_type)
    pool0, mask0, ok0 = max_pool_2x2_unique(conv0)
    if not ok0:
        return None

    act0 = apply_activation(pool0, act_type)
    act0_padded = apply_padding(act0, pad, pad_type)
    conv1 = conv2d_same(act0, weights[1], pad_type)
    pool1, mask1, ok1 = max_pool_2x2_unique(conv1)
    if not ok1:
        return None

    act1 = apply_activation(pool1, act_type)

    unpool2 = unpool_2x2(act1, mask1)
    deconv2 = conv2d_same(unpool2, weights[2], pad_type)
    act2 = apply_activation(deconv2, act_type)

    unpool3 = unpool_2x2(act2, mask0)
    deconv3 = conv2d_same(unpool3, weights[3], pad_type)
    act3 = apply_activation(deconv3, act_type)

    return {
        "pad_type": pad_type,
        "act_type": act_type,
        "weights": weights,
        "image": image,
        "scaled": scaled,
        "scaled_padding": scaled_padded,
        "after_conv0": conv0,
        "after_pooling0": pool0,
        "after_activation0": act0,
        "after_act0_padding": act0_padded,
        "after_conv1": conv1,
        "after_pooling1": pool1,
        "after_activation1": act1,
        "act1_mask": mask1,
        "unpool2": unpool2,
        "deconv2": deconv2,
        "after_activation2": act2,
        "unpool3": unpool3,
        "deconv3": deconv3,
        "after_activation3": act3,
    }


def main():
    seed = None
    rng = np.random.RandomState(seed)

    max_attempts = 1
    case = None
    for _ in range(max_attempts):
        case = generate_case(rng)
        if case is not None:
            break

    if case is None:
        raise RuntimeError("Failed to generate a testcase with unique maxima in all max-pooling windows.")

    save_testcase(OUTPUT_DIR / "testcase.txt", case["pad_type"], case["act_type"], case["weights"], case["image"])
    save_tensor_hex(OUTPUT_DIR / "min_max.txt", case["scaled"])
    save_tensor_hex(OUTPUT_DIR / "scaled_padding.txt", case["scaled_padding"])
    save_tensor_hex(OUTPUT_DIR / "after_conv0.txt", case["after_conv0"])
    save_tensor_hex(OUTPUT_DIR / "after_pooling0.txt", case["after_pooling0"])
    save_tensor_hex(OUTPUT_DIR / "after_activation0.txt", case["after_activation0"])
    save_tensor_hex(OUTPUT_DIR / "after_act0_padding.txt", case["after_act0_padding"])
    save_tensor_hex(OUTPUT_DIR / "after_conv1.txt", case["after_conv1"])
    save_tensor_hex(OUTPUT_DIR / "after_pooling1.txt", case["after_pooling1"])
    save_tensor_hex(OUTPUT_DIR / "after_activation1.txt", case["after_activation1"])
    save_tensor_hex(OUTPUT_DIR / "act1_mask.txt", case["act1_mask"])
    save_tensor_hex(OUTPUT_DIR / "unpool2.txt", case["unpool2"])
    save_tensor_hex(OUTPUT_DIR / "deconv2.txt", case["deconv2"])
    save_tensor_hex(OUTPUT_DIR / "after_activation2.txt", case["after_activation2"])
    save_tensor_hex(OUTPUT_DIR / "unpool3.txt", case["unpool3"])
    save_tensor_hex(OUTPUT_DIR / "deconv3.txt", case["deconv3"])
    save_tensor_hex(OUTPUT_DIR / "after_activation3.txt", case["after_activation3"])

    print("Generated:")
    print("  testcase.txt")
    print("  min_max.txt")
    print("  after_conv0.txt")
    print("  after_activation0.txt")
    print("  after_activation1.txt")
    print("  after_activation2.txt")
    print("  after_activation3.txt")
    print(f"Padding type      : {case['pad_type']} ({'zero' if case['pad_type'] == 0 else 'replication'})")
    act_names = {
        0: "sigmoid",
        1: "tanh",
        2: "relu",
        3: "leaky relu",
    }
    print(f"Activation type   : {case['act_type']:02b} ({act_names[case['act_type']]})")


if __name__ == "__main__":
    main()
