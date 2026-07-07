import numpy as np
import os

# ==========================================
# Parameters
# ==========================================
PATNUM = 100       
IMAGE_SIZE = 64
DOWN_SIZE = 16
CHANNELS = 16
DIM = 16

def clip(val, min_val, max_val):
    return np.clip(val, min_val, max_val)

def arithmetic_right_shift(val, shift):
    # Python 的 >> 運算子預設就是 Arithmetic Right Shift (帶號右移)
    return val >> shift

class DiffusionModelGolden:
    def __init__(self):
        # 1. 產生權重 (4-bit signed: -8 ~ 7)
        # 用 np.random.randint 產生，後續存檔時轉成 4-bit unsigned hex
        
        # Down Sampling Conv: 3x3x1x16 (Out, In, H, W) -> (16, 1, 3, 3)
        self.w_down = np.random.randint(-8, 8, size=(16, 1, 3, 3)).astype(np.int64)
        
        # Transformer Q, K, V: 16x16 -> (16, 16)
        self.w_q = np.random.randint(-8, 8, size=(16, 16)).astype(np.int64)
        self.w_k = np.random.randint(-8, 8, size=(16, 16)).astype(np.int64)
        self.w_v = np.random.randint(-8, 8, size=(16, 16)).astype(np.int64)
        
        # Transformer FFN: 16x16 -> (16, 16)
        self.w_ffn = np.random.randint(-8, 8, size=(16, 16)).astype(np.int64)
        
        # Up Sampling Conv: 3x3x16x1 (Out, In, H, W) -> (1, 16, 3, 3)
        self.w_up = np.random.randint(-8, 8, size=(1, 16, 3, 3)).astype(np.int64)

    def down_sample_conv(self, img):
        # Input: (64, 64), Output: (16, 16, 16)
        out = np.zeros((DOWN_SIZE, DOWN_SIZE, CHANNELS), dtype=np.int64)
        # Zero padding to 66x66
        pad_img = np.zeros((IMAGE_SIZE + 2, IMAGE_SIZE + 2), dtype=np.int64)
        pad_img[1:65, 1:65] = img
        
        for oc in range(CHANNELS):
            for oy in range(DOWN_SIZE):
                for ox in range(DOWN_SIZE):
                    mac_sum = 0
                    for ky in range(3):
                        for kx in range(3):
                            iy = oy * 4 + ky # Stride 4
                            ix = ox * 4 + kx
                            mac_sum += pad_img[iy, ix] * self.w_down[oc, 0, ky, kx]
                    
                    # Normalization, ReLU + Clip
                    val = arithmetic_right_shift(mac_sum, 6) + 128
                    out[oy, ox, oc] = clip(val, 0, 255)
        return out

    def transformer_block(self, feature_map):
        # Input Feature Map Reordering: (16, 16, 16) -> (256, 16)
        x = feature_map.reshape((256, 16)).astype(np.int64)
        
        # - Mid point
        x_mid = x - 128
        
        # Linear Transformation + Norm + Clip for Q, K, V
        # matrix multiply: output[i, j] = sum(x[i, k] * w[k, j])
        q = clip(arithmetic_right_shift(np.dot(x_mid, self.w_q), 4), -128, 127)
        k = clip(arithmetic_right_shift(np.dot(x_mid, self.w_k), 4), -128, 127)
        v = clip(arithmetic_right_shift(np.dot(x_mid, self.w_v), 4), -128, 127)
        
        # ============== 新增這三行來攔截資料 ==============
        self._debug_q = q.reshape((16, 16, 16))
        self._debug_k = k.reshape((16, 16, 16))
        self._debug_v = v.reshape((16, 16, 16))
        # ===============================================
        
        # Attention: SoftMax(Q * K^T / 4) * V
        qk_t = np.dot(q, k.T)
        qk_t_div = arithmetic_right_shift(qk_t, 2) # divided by 4
        qk_t_clip = clip(qk_t_div, -2048, 2047)
        
        # Linear approach of SoftMax
        fixpoint = clip(arithmetic_right_shift(qk_t_clip, 4) + 128, 0, 255)
        
        print(f"SoftMax Q=0, K=0~3: {fixpoint[0, 0]}, {fixpoint[0, 1]}, {fixpoint[0, 2]}, {fixpoint[0, 3]}")
        
        # MatMul with V
        attn = np.dot(fixpoint, v)
        
        # ============== 新增這行來攔截資料 ==============
        self._debug_attn_acc = attn
        # ===============================================
        
        attn_out = clip(arithmetic_right_shift(attn, 16), -128, 127)
        
        # Feed Forward Network
        ffn = np.dot(attn_out, self.w_ffn)
        ffn_norm = arithmetic_right_shift(ffn, 4)
        ffn_out = clip(ffn_norm + 128, 0, 255)
        
        # ============== 新增這行來攔截 FFN 資料 ==============
        self._debug_ffn_out = ffn_out
        # ===============================================
        
        # Output Feature Map Reordering: (256, 16) -> (16, 16, 16)
        return ffn_out.reshape((DOWN_SIZE, DOWN_SIZE, CHANNELS))

    def up_sample_conv(self, feature_map):
        # Input: (16, 16, 16), Output: (16, 16)
        out = np.zeros((DOWN_SIZE, DOWN_SIZE), dtype=np.int64)
        
        # Padding (H, W, C) -> (18, 18, 16)
        pad_fm = np.zeros((DOWN_SIZE + 2, DOWN_SIZE + 2, CHANNELS), dtype=np.int64)
        pad_fm[1:17, 1:17, :] = feature_map
        
        for oy in range(DOWN_SIZE):
            for ox in range(DOWN_SIZE):
                mac_sum = 0
                for ic in range(CHANNELS):
                    for ky in range(3):
                        for kx in range(3):
                            iy = oy * 1 + ky # Stride 1
                            ix = ox * 1 + kx
                            mac_sum += pad_fm[iy, ix, ic] * self.w_up[0, ic, ky, kx]
                
                # Normalization, ReLU + Clip
                val = arithmetic_right_shift(mac_sum, 6) + 128
                out[oy, ox] = clip(val, 0, 255)
                
        self._debug_up_out = out
        return out

    def interpolation(self, img_16x16, mode):
        out = np.zeros((IMAGE_SIZE, IMAGE_SIZE), dtype=np.int64)
        
        if mode == 0: # Mode 0: Nearest-neighbor
            for i in range(DOWN_SIZE):
                for j in range(DOWN_SIZE):
                    out[i*4:(i+1)*4, j*4:(j+1)*4] = img_16x16[i, j]
                    
        elif mode == 1: # Mode 1: X-direction 2-point
            for i in range(DOWN_SIZE):
                for j in range(DOWN_SIZE):
                    val = img_16x16[i, j]
                    if j < 15:
                        step = arithmetic_right_shift(img_16x16[i, j+1] - img_16x16[i, j], 2)
                    else:
                        step = arithmetic_right_shift(img_16x16[i, j] - img_16x16[i, j-1], 2)
                    
                    for k in range(4):
                        interp_val = clip(val + step * k, 0, 255)
                        # Expand in Y-direction via nearest
                        for r in range(4):
                            out[i*4 + r, j*4 + k] = interp_val
                            
        elif mode == 2: # Mode 2: Y-direction 2-point
            for j in range(DOWN_SIZE):
                for i in range(DOWN_SIZE):
                    val = img_16x16[i, j]
                    if i < 15:
                        step = arithmetic_right_shift(img_16x16[i+1, j] - img_16x16[i, j], 2)
                    else:
                        step = arithmetic_right_shift(img_16x16[i, j] - img_16x16[i-1, j], 2)
                    
                    for k in range(4):
                        interp_val = clip(val + step * k, 0, 255)
                        # Expand in X-direction via nearest
                        for c in range(4):
                            out[i*4 + k, j*4 + c] = interp_val
        return out

    def run_iteration(self, input_image, mode):
        # 1. Down Sampling
        fm_down = self.down_sample_conv(input_image)
        # 2. Transformer Block
        fm_attn = self.transformer_block(fm_down)
        # 3. Up Sampling
        fm_up = self.up_sample_conv(fm_attn)
        # 4. Interpolation
        noise_pred = self.interpolation(fm_up, mode)
        # 5. Denoise
        scaled_noise = arithmetic_right_shift(noise_pred, 3)
        denoised = clip(input_image - scaled_noise, 0, 255)
        return denoised

def get_weight_array(model):
    w_list = []
    # Down Conv: (16, 1, 3, 3)
    for oc in range(16):
        for ky in range(3):
            for kx in range(3):
                w_list.append(model.w_down[oc, 0, ky, kx])
    
    # Q, K, V: (16, 16) each
    for w_matrix in [model.w_q, model.w_k, model.w_v, model.w_ffn]:
        for i in range(16):
            for j in range(16):
                w_list.append(w_matrix[i, j])
                
    # Up Conv: (1, 16, 3, 3)
    for ic in range(16):
        for ky in range(3):
            for kx in range(3):
                w_list.append(model.w_up[0, ic, ky, kx])
                
    return w_list

def generate_patterns():
    print(f"Generating Golden Data for {PATNUM} patterns...")
    model = DiffusionModelGolden()
    
    with open('weight.dat', 'w') as f_w:
        for w in get_weight_array(model):
            f_w.write(f"{(w & 0xF):x}\n")
            
    with open('iter.dat', 'w') as f_it, \
         open('mode.dat', 'w') as f_md, \
         open('image.dat', 'w') as f_in, \
         open('golden.dat', 'w') as f_out:
         
        for p in range(PATNUM):
            iterations = np.random.randint(1, 8)
            mode = np.random.randint(0, 3)
            
            f_it.write(f"{iterations:x}\n")
            f_md.write(f"{mode:x}\n")
            
            img = np.random.randint(0, 256, size=(IMAGE_SIZE, IMAGE_SIZE)).astype(np.int64)
            for val in img.flatten():
                f_in.write(f"{val:02x}\n")
                
            # Run Model
            # Run Model
            current_img = img.copy()
            for iter_idx in range(iterations):
                # 為了拿到 fm_down，我們把它拆開來呼叫
                fm_down = model.down_sample_conv(current_img)
                
                # 呼叫我們寫好的 Debug 函數 (只會印出 Pattern 0, Iteration 0)
                dump_down_conv_debug(fm_down, p, iter_idx)
                
                fm_attn = model.transformer_block(fm_down)
                
                # ============== 新增這行呼叫 QKV Debug ==============
                dump_qkv_debug(model._debug_q, model._debug_k, model._debug_v, p, iter_idx)
                # ====================================================
                
                # ============== 新增這行呼叫 Attn Acc Debug ==============
                dump_attn_acc_debug(model._debug_attn_acc, p, iter_idx)
                # =========================================================
                
                # ============== 新增這行呼叫 FFN Debug ==============
                dump_ffn_debug(model._debug_ffn_out, p, iter_idx)
                # ====================================================
                
                # --- 執行到這裡時，Transformer 結束了 ---
                fm_up = model.up_sample_conv(fm_attn)
                
                # ============== 呼叫對拍函數 ==============
                dump_up_sample_debug(model._debug_up_out, p, iter_idx)
                # =========================================
                
                # ============== 呼叫對拍函數 ==============
                dump_denoise_debug(fm_up, current_img, mode, p, iter_idx, iterations)
                # =========================================
                
                noise_pred = model.interpolation(fm_up, mode)
                scaled_noise = arithmetic_right_shift(noise_pred, 3)
                current_img = clip(current_img - scaled_noise, 0, 255)
                
            for val in current_img.flatten():
                f_out.write(f"{val:02x}\n")
            
            if (p + 1) % 10 == 0:
                print(f"Pattern {p + 1}/{PATNUM} generated.")
                
    print("Done! Files saved: weight.dat, iter.dat, mode.dat, image.dat, golden.dat")

def dump_denoise_debug(up_matrix, orig_img, mode, pattern_idx, iter_idx, total_iters):
    # ★ 修復 1：只印出「最後一輪」的結果，這樣才會跟 golden.dat 100% 吻合！
    if pattern_idx != 0 or iter_idx != total_iters - 1:
        return

    print("\n==================================================")
    print(f"  [DEBUG] Denoise Output (Pattern {pattern_idx}, Iteration {iter_idx})")
    # print("  Mapping to RTL: DENOISE 狀態機 (dn_out_cnt 0~4095)")
    print("==================================================")
    
    with open('debug_denoise_out.txt', 'w') as f:
        f.write(f"// Denoise Output for Pattern {pattern_idx}, Final Iteration ({iter_idx})\n")
        f.write("// Format: Pixel_Idx | p0, p1 | diff, step | interp | scaled | orig -> OUT\n\n")
        
        for dn_out_cnt in range(4096):
            dn_oy = dn_out_cnt // 64
            dn_ox = dn_out_cnt % 64
            
            dn_iy = dn_oy // 4
            dn_ix = dn_ox // 4
            sub_y = dn_oy % 4
            sub_x = dn_ox % 4
            
            p0_y, p0_x = dn_iy, dn_ix
            
            # ★ 修復 2：完美還原邊界反向相減的座標邏輯
            if mode == 1:   
                p1_y = dn_iy
                p1_x = 14 if dn_ix == 15 else dn_ix + 1
            elif mode == 2: 
                p1_y = 14 if dn_iy == 15 else dn_iy + 1
                p1_x = dn_ix
            else:
                p1_y, p1_x = dn_iy, dn_ix
                
            p0 = int(up_matrix[p0_y, p0_x])
            p1 = int(up_matrix[p1_y, p1_x])
            
            if (mode == 1 and dn_ix == 15) or (mode == 2 and dn_iy == 15):
                diff = p0 - p1
            else:
                diff = p1 - p0
                
            step = arithmetic_right_shift(diff, 2)
            k_mult = sub_x if mode == 1 else (sub_y if mode == 2 else 0)
            
            interp_val_sgn = p0 + step * k_mult
            interp_val = max(0, min(255, interp_val_sgn))
            
            # ★ 修復 3：拿掉我腦補的 -128，還原最純粹的數學
            scaled_noise = arithmetic_right_shift(interp_val, 3) 
            
            orig_pixel = int(orig_img[dn_oy, dn_ox])
            denoised_sgn = orig_pixel - scaled_noise
            denoised_out = max(0, min(255, denoised_sgn))
            
            f.write(f"Pixel {dn_out_cnt:4d} (y={dn_oy:2d}, x={dn_ox:2d}): ")
            f.write(f"p0={p0:3d}, p1={p1:3d} | diff={diff:4d}, step={step:4d} | ")
            f.write(f"interp={interp_val:3d} | scaled={scaled_noise:4d} | ")
            f.write(f"orig={orig_pixel:3d} -> OUT={denoised_out:3d} ({denoised_out:02x})\n")
    
def dump_attn_acc_debug(attn_matrix, pattern_idx, iteration_idx):
    if pattern_idx != 0 or iteration_idx != 0:
        return

    print("\n==================================================")
    print("  [DEBUG] Attention Accumulator (attn_acc) Output")
    print("  Mapping to RTL: attn_acc[0~15][0~15] (before Shift 16)")
    print("==================================================")
    
    with open('debug_attn_acc.txt', 'w') as f:
        f.write("// Attention Accumulator Output for Pattern 0, Iteration 1\n")
        f.write("// Displaying FULL 256 Pixels!\n")
        f.write("// Format: 32-bit hex (2's complement)\n\n")
        
        # ★ 封印解除：直接迴圈 256 次，印出所有 Pixel
        for p_idx in range(256):
            # 幫你算好對應 RTL 的 q_blk_idx 跟 q_buf 的 index
            blk_idx = p_idx // 16
            buf_idx = p_idx % 16
            
            f.write(f"// --- Pixel {p_idx} (q_blk_idx={blk_idx}, q_buf[{buf_idx}]) ---\n")
            
            for ch in range(16):
                val = int(attn_matrix[p_idx, ch])
                val_hex = val & 0xFFFFFFFF
                f.write(f"Ch{ch:02d} : {val_hex:08x}\n")
                
    print("[INFO] Full 256 Pixels Attn Acc debug trace saved to 'debug_attn_acc.txt'\n")

def dump_ffn_debug(ffn_matrix, pattern_idx, iteration_idx):
    # 一樣只印出 Pattern 0, Iteration 0 的資料來 Debug
    if pattern_idx != 0 or iteration_idx != 0:
        return

    print("\n==================================================")
    print("  [DEBUG] FFN Final Output")
    # print("  Mapping to RTL: Phase 3 寫入 K_SRAM 的 k_sram_wdata")
    print("  Format: 32-bit hex ({Ch3, Ch2, Ch1, Ch0})")
    print("==================================================")
    
    with open('debug_ffn_out.txt', 'w') as f:
        f.write("// FFN Output for Pattern 0, Iteration 1\n")
        f.write("// Format: 32-bit hex ( {Ch_N+3, Ch_N+2, Ch_N+1, Ch_N} )\n\n")
        
        # ffn_matrix 的形狀是 (256, 16)
        for p_idx in range(256):
            f.write(f"// --- Pixel {p_idx} ---\n")
            
            # 分成 4 個 fold，跟 RTL 一模一樣
            for fold in range(4):
                c0 = fold * 4 + 0
                c1 = fold * 4 + 1
                c2 = fold * 4 + 2
                c3 = fold * 4 + 3
                
                v0 = int(ffn_matrix[p_idx, c0]) & 0xFF
                v1 = int(ffn_matrix[p_idx, c1]) & 0xFF
                v2 = int(ffn_matrix[p_idx, c2]) & 0xFF
                v3 = int(ffn_matrix[p_idx, c3]) & 0xFF
                
                # 打包成 32-bit 寫入格式
                wdata = (v3 << 24) | (v2 << 16) | (v1 << 8) | v0
                
                f.write(f"Fold {fold}: {wdata:08x}\n")
                
                # 為了方便，我們把 Pixel 0 的前兩包印在 Console
                if p_idx == 0:
                    print(f"Pixel 0, Fold {fold} (Ch{c3}~{c0}): {wdata:08x}  (Dec: {v3:3d}, {v2:3d}, {v1:3d}, {v0:3d})")
                    
    print("\n[INFO] Full FFN debug trace saved to 'debug_ffn_out.txt'\n")
    
def dump_up_sample_debug(up_matrix, pattern_idx, iteration_idx):
    # 只針對 Pattern 0, Iteration 0 輸出
    if pattern_idx != 0 or iteration_idx != 0:
        return

    print("\n==================================================")
    print("  [DEBUG] Up Sampling Output (fm_up)")
    print("  Mapping to RTL: K_SRAM Address 0~255")
    print("==================================================")
    
    with open('debug_up_out.txt', 'w') as f:
        f.write("// Up Sampling Conv Output for Pattern 0, Iteration 1\n")
        f.write("// Format: 8-bit hex (one pixel per line)\n\n")
        
        # up_matrix 是一個 (16, 16) 的陣列
        for oy in range(16):
            for ox in range(16):
                val = int(up_matrix[oy, ox])
                p_idx = oy * 16 + ox
                
                f.write(f"Addr {p_idx:3d} (y={oy:2d}, x={ox:2d}): {val:02x}\n")
                
                # 在終端機印出前 5 個點方便快速對拍
                if p_idx < 5:
                    print(f"Pixel {p_idx} (Addr {p_idx}): {val:02x} (Dec: {val})")

    print("[INFO] Up Sample debug trace saved to 'debug_up_out.txt'\n")
    
    
def dump_qkv_debug(q_matrix, k_matrix, v_matrix, pattern_idx, iteration_idx):
    # 一樣只印出 Pattern 0, Iteration 1 的資料來 Debug
    if pattern_idx != 0 or iteration_idx != 0:
        return

    print("\n==================================================")
    print("  [DEBUG] Transformer Q, K, V Output")
    print("  Mapping to RTL: q/k/v_sram_wdata (32-bit)")
    print("==================================================")
    
    with open('debug_qkv_wdata.txt', 'w') as f:
        f.write("// Q, K, V Output for Pattern 0, Iteration 1\n")
        f.write("// Format: 32-bit hex ( {Ch_N+3, Ch_N+2, Ch_N+1, Ch_N} )\n")
        f.write("// Values are in 2's complement representation.\n\n")
        
        print_limit = 2 # 只印前 2 個 Pixel 在終端機，免得洗版
        count = 0

        for oy in range(DOWN_SIZE):
            for ox in range(DOWN_SIZE):
                if count < print_limit:
                    print(f"\n--- Output Pixel y={oy}, x={ox} ---")
                f.write(f"// --- y={oy}, x={ox} ---\n")
                
                for fold in range(4):
                    c0 = fold * 4 + 0
                    c1 = fold * 4 + 1
                    c2 = fold * 4 + 2
                    c3 = fold * 4 + 3
                    
                    # 取出對應的 Q, K, V 值 (這些值目前是 -128 ~ 127)
                    # Python 的負數轉 8-bit hex 需要用 & 0xFF (二補數轉換)
                    q0, q1, q2, q3 = q_matrix[oy, ox, c0], q_matrix[oy, ox, c1], q_matrix[oy, ox, c2], q_matrix[oy, ox, c3]
                    wq = ((q3 & 0xFF) << 24) | ((q2 & 0xFF) << 16) | ((q1 & 0xFF) << 8) | (q0 & 0xFF)
                    
                    k0, k1, k2, k3 = k_matrix[oy, ox, c0], k_matrix[oy, ox, c1], k_matrix[oy, ox, c2], k_matrix[oy, ox, c3]
                    wk = ((k3 & 0xFF) << 24) | ((k2 & 0xFF) << 16) | ((k1 & 0xFF) << 8) | (k0 & 0xFF)
                    
                    v0, v1, v2, v3 = v_matrix[oy, ox, c0], v_matrix[oy, ox, c1], v_matrix[oy, ox, c2], v_matrix[oy, ox, c3]
                    wv = ((v3 & 0xFF) << 24) | ((v2 & 0xFF) << 16) | ((v1 & 0xFF) << 8) | (v0 & 0xFF)
                    
                    log_str = f"fold={fold}: Q={wq:08x} | K={wk:08x} | V={wv:08x}"
                    if count < print_limit:
                        print(log_str)
                        
                    f.write(f"{wq:08x} {wk:08x} {wv:08x}\n")
                count += 1
    print("\n[INFO] Full QKV debug trace saved to 'debug_qkv_wdata.txt'\n")
    
def dump_down_conv_debug(fm_down, pattern_idx, iteration_idx):
    # 只針對 Pattern 0 的第 1 次 Iteration 印出 Debug 資訊
    if pattern_idx != 0 or iteration_idx != 0:
        return

    print("\n==================================================")
    print("  [DEBUG] Down Sampling Convolution Output")
    print("  Mapping to RTL: feat_sram_wdata (32-bit)")
    print("==================================================")
    
    with open('debug_feat_wdata.txt', 'w') as f:
        f.write("// Down Sampling Conv Output for Pattern 0, Iteration 1\n")
        f.write("// Format: 32-bit hex ( {Ch_N+3, Ch_N+2, Ch_N+1, Ch_N} )\n\n")
        
        # 只在 Console 印出前幾個 Pixel，免得洗版
        print_limit = 4 
        count = 0

        for oy in range(DOWN_SIZE):
            for ox in range(DOWN_SIZE):
                if count < print_limit:
                    print(f"\n--- Output Pixel y={oy}, x={ox} ---")
                f.write(f"// --- y={oy}, x={ox} ---\n")
                
                # 硬體分 4 個 fold_cnt 寫入 (0~3)
                for fold in range(4):
                    c0 = fold * 4 + 0
                    c1 = fold * 4 + 1
                    c2 = fold * 4 + 2
                    c3 = fold * 4 + 3
                    
                    # 取出 4 個 Channel 的 8-bit 結果
                    v0 = fm_down[oy, ox, c0]
                    v1 = fm_down[oy, ox, c1]
                    v2 = fm_down[oy, ox, c2]
                    v3 = fm_down[oy, ox, c3]
                    
                    # 打包成 32-bit: {v3, v2, v1, v0}
                    wdata = (v3 << 24) | (v2 << 16) | (v1 << 8) | v0
                    
                    log_str = f"fold={fold} (ch{c3:02d}~ch{c0:02d}) : {wdata:08x}"
                    
                    if count < print_limit:
                        print(log_str)
                        
                    f.write(f"{wdata:08x}\n")
                count += 1
    print("\n[INFO] Full debug trace saved to 'debug_feat_wdata.txt'\n")

if __name__ == "__main__":
    np.random.seed() # 固定隨機變數 seed，讓每次重產生的資料一致
    generate_patterns()