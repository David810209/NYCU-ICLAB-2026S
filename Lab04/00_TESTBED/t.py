import numpy as np
import struct
import os
import random

PATNUM = 1000  # Default 1000 patterns per Spec
os.makedirs("patterns", exist_ok=True)

def float_to_hex(f):
    """Convert float32 to IEEE-754 32-bit hex string"""
    return format(struct.unpack('<I', struct.pack('<f', np.float32(f)))[0], '08x')

def pad_image(img, pad_mode):
    # pad_mode: 0 = zero padding, 1 = replication padding
    mode = 'edge' if pad_mode == 1 else 'constant'
    # img: (C, H, W), pad 1 pixel around H and W dimensions
    return np.pad(img, ((0,0), (1,1), (1,1)), mode=mode)

def conv2d(img, kernel):
    out_c, in_c, kh, kw = kernel.shape
    _, H, W = img.shape
    out_h, out_w = H - kh + 1, W - kw + 1
    out = np.zeros((out_c, out_h, out_w), dtype=np.float32)
    
    for oc in range(out_c):
        for i in range(out_h):
            for j in range(out_w):
                # Simulate hardware "Channel-Separated Accumulation"
                # Sum Ch0 and Ch1 products separately, then add them up
                ch0_sum = np.sum(img[0, i:i+kh, j:j+kw] * kernel[oc, 0], dtype=np.float32)
                ch1_sum = np.sum(img[1, i:i+kh, j:j+kw] * kernel[oc, 1], dtype=np.float32)
                out[oc, i, j] = np.float32(ch0_sum + ch1_sum)
    return out

def max_pool2d_with_indices(img):
    C, H, W = img.shape
    out_h, out_w = H // 2, W // 2
    out = np.zeros((C, out_h, out_w), dtype=np.float32)
    indices = np.zeros((C, out_h, out_w), dtype=np.int32)
    
    for c in range(C):
        for i in range(out_h):
            for j in range(out_w):
                window = img[c, i*2:i*2+2, j*2:j*2+2]
                # numpy argmax picks the first (smallest) index in case of a tie
                idx = np.argmax(window) 
                out[c, i, j] = window.flatten()[idx]
                indices[c, i, j] = idx
    return out, indices

def unpool2d(img, indices, out_shape):
    C, H, W = img.shape
    out = np.zeros(out_shape, dtype=np.float32)
    
    for c in range(C):
        for i in range(H):
            for j in range(W):
                val = img[c, i, j]
                idx = indices[c, i, j]
                r, c_offset = divmod(idx, 2)
                out[c, i*2 + r, j*2 + c_offset] = val
    return out

def activate(img, act_mode):
    out = img.astype(np.float32)
    if act_mode == 0:   # Sigmoid
        out = np.float32(1.0 / (1.0 + np.exp(-out, dtype=np.float32)))
    elif act_mode == 1: # Tanh
        out = np.tanh(out, dtype=np.float32)
    elif act_mode == 2: # ReLU
        out = np.maximum(0.0, out, dtype=np.float32)
    elif act_mode == 3: # Leaky ReLU
        # Spec: -2^-123 < x <= 0, f(x) = 0
        threshold = -np.float32(2**-123)
        cond1 = (out > threshold) & (out <= 0.0)
        cond2 = (out <= threshold)
        out[cond1] = 0.0
        out[cond2] = np.float32(out[cond2] * 0.125)
    return out

def generate_patterns():
    print("Starting pattern generation and filtering...")
    
    # Use 'with' to handle multiple file pointers safely
    with open("patterns/inst.dat", "w") as f_inst, \
         open("patterns/weight.dat", "w") as f_weight, \
         open("patterns/image.dat", "w") as f_image, \
         open("patterns/golden.dat", "w") as f_golden:

        valid_count = 0
        while valid_count < PATNUM:
            # --- 1. Parameters Generation ---
            pad_mode = random.randint(0, 1)
            act_mode = random.randint(0, 3)
            inst_int = (pad_mode << 2) | act_mode

            weights = np.random.uniform(-1.0, 1.0, 144).astype(np.float32)
            images = np.random.uniform(-127.0, 128.0, 128).astype(np.float32)

            # --- 2. Golden Model Calculation ---
            w_reshaped = weights.reshape((4, 2, 2, 3, 3))
            w_conv0, w_conv1, w_deconv0, w_deconv1 = w_reshaped[0], w_reshaped[1], w_reshaped[2], w_reshaped[3]
            
            img_reshaped = images.reshape((2, 8, 8))
            
            # Normalization
            scaled_img = np.zeros_like(img_reshaped, dtype=np.float32)
            for c in range(2):
                c_min, c_max = np.min(img_reshaped[c]), np.max(img_reshaped[c])
                denom = (c_max - c_min) if (c_max - c_min) != 0 else 1.0
                scaled_img[c] = (img_reshaped[c] - c_min) / denom
                
            # >> ENCODER Stage <<
            p0 = pad_image(scaled_img, pad_mode)
            c0 = conv2d(p0, w_conv0)
            pool0, idx0 = max_pool2d_with_indices(c0)
            act0 = activate(pool0, act_mode)

            p1 = pad_image(act0, pad_mode)
            c1 = conv2d(p1, w_conv1)
            pool1, idx1 = max_pool2d_with_indices(c1)
            act1 = activate(pool1, act_mode)

            # >> DECODER Stage <<
            unp0 = unpool2d(act1, idx1, (2, 4, 4))
            p2 = pad_image(unp0, pad_mode)
            dc0 = conv2d(p2, w_deconv0)
            act2 = activate(dc0, act_mode)

            unp1 = unpool2d(act2, idx0, (2, 8, 8))
            p3 = pad_image(unp1, pad_mode)
            dc1 = conv2d(p3, w_deconv1)
            final_out = activate(dc1, act_mode)

            # --- 3. Filtering Mechanism ---
            # Avoid catastrophic cancellation or tiny floats (1e-5 to 1e-8) 
            # that cause hardware precision mismatches.
            if np.any((np.abs(final_out) > 0.0) & (np.abs(final_out) < 1e-4)):
                continue
            if np.any((np.abs(c0) > 0.0) & (np.abs(c0) < 1e-4)):
                continue
            if np.any((np.abs(dc1) > 0.0) & (np.abs(dc1) < 1e-4)):
                continue

            # --- 4. Write to Files ---
            f_inst.write(f"{inst_int:08x}\n")
            for w in weights:
                f_weight.write(f"{float_to_hex(w)}\n")
            for img in images:
                f_image.write(f"{float_to_hex(img)}\n")
            for val in final_out.flatten():
                f_golden.write(f"{float_to_hex(val)}\n")

            valid_count += 1
            if valid_count % 100 == 0:
                print(f"Generated {valid_count} / {PATNUM} patterns...")

    print(f"Success! {PATNUM} filtered patterns saved to 'patterns/' directory.")

if __name__ == '__main__':
    generate_patterns()