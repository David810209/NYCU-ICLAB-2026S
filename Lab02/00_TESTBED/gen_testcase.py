import re
import numpy as np
import random

def generate_patterns():
    # 1. 生成 input.txt (每行 16 個 12-bit Hex)
    # 總共生成 1000 組像素，假設每組包含 256 個像素 (16x16)
    num_sets = 1000  # 你可以調整組數，4組 x 256 = 1024 接近 1000
    with open('input.txt', 'w') as f:
        for s in range(num_sets):
            f.write(f"// Pattern {s+1:03d}\n")
            for _ in range(16): # 每組 16 行
                row_vals = [random.randint(0, 4095) for _ in range(16)]
                hex_row = " ".join([f"{v:03X}" for v in row_vals])
                f.write(f"{hex_row}\n")
            f.write("\n")
    print("Successfully generated input.txt in 16x16 hex format.")

    # 2. 生成 lsc_gain_map.txt (1024-2048, 12-bit Hex)
    # 按照 R, Gr, Gb, B 通道排列，每個通道 36 個 Gain
    with open('lsc_gain_map.txt', 'w') as f:
        channels = ['R', 'Gr', 'Gb', 'B']
        for ch in channels:
            # f.write(f"// {ch} Channel Gain Table\n")
            gains = [random.randint(1024, 2048) for _ in range(36)]
            # 為了方便觀察，增益圖也以每行 6 個顯示 (6x6=36)
            for i in range(0, 36, 6):
                row_gains = " ".join([f"{g:03X}" for g in gains[i:i+6]])
                f.write(f"{row_gains}\n")
            # f.write("\n")
    print("Successfully generated lsc_gain_map.txt (Hex 400~800).")

def parse_input_txt(file_path):
    """解析 input.txt，提取所有 Pattern 的資料"""
    patterns = []
    current_pattern_data = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    for line in lines:
        line = line.strip()
        if not line: continue
        
        # 偵測到新 Pattern 開始
        if line.startswith("// Pattern"):
            if current_pattern_data:
                patterns.append(current_pattern_data)
                current_pattern_data = []
            continue
        
        # 忽略非資料註釋
        if line.startswith("//") or "有十組" in line:
            continue
            
        # 提取 16 進位數值
        hex_values = re.findall(r'[0-9A-Fa-f]{3}', line)
        current_pattern_data.extend([int(x, 16) for x in hex_values])
        
    if current_pattern_data:
        patterns.append(current_pattern_data)
        
    return patterns

def parse_gain_map(file_path):
    """解析 lsc_gain_map.txt (144 個 HEX 資料)"""
    with open(file_path, 'r', encoding='utf-8') as f:
        # 只提取符合 HEX 格式的字串
        content = f.read()
        hex_values = re.findall(r'[0-9A-Fa-f]{3,4}', content)
        
    all_vals = [int(x, 16) for x in hex_values[:144]]
    
    tables = {}
    # 順序為 R, Gr, Gb, B，各 36 個值 (6x6)
    channels = ['R', 'Gr', 'Gb', 'B']
    for i, ch in enumerate(channels):
        tables[ch] = np.array(all_vals[i*36 : (i+1)*36]).reshape(6, 6)
    return tables

def process_isp(raw_1d, mesh_tables):
    """核心 ISP 運算: BLC + LSC"""
    BLC_OFFSETS = {'R': 64, 'Gr': 48, 'Gb': 52, 'B': 72}
    raw_2d = np.array(raw_1d).reshape(16, 16)
    output = np.zeros((16, 16), dtype=int)

    for y in range(16):
        for x in range(16):
            # 1. 判定 Bayer Channel (RGGB Pattern)
            if y % 2 == 0:
                channel = 'R' if x % 2 == 0 else 'Gr'
            else:
                channel = 'Gb' if x % 2 == 0 else 'B'
            
            # 2. Black Level Correction (BLC)
            I_raw = raw_2d[y, x]
            B = BLC_OFFSETS[channel]
            I_blc = max(0, I_raw - B)

            # 3. Coordinate Mapping (依照 spec)
            x0, y0 = min(x // 3, 4), min(y // 3, 4)
            m = mesh_tables[channel]
            g00, g01 = m[y0, x0], m[y0, x0+1]
            g10, g11 = m[y0+1, x0], m[y0+1, x0+1]

            rx, ry = min(x - 3*x0, 2), min(y - 3*y0, 2)
            
            # 4. Bilinear Interpolation Weights
            dx = (rx * 256 + 1) // 3
            ix = 256 - dx
            dy = (ry * 256 + 1) // 3
            iy = 256 - dy

            # 5. Gain Calculation G(x, y)
            gain_val = (g00 * ix * iy + g10 * ix * dy + 
                        g01 * dx * iy + g11 * dx * dy + (1 << 15)) >> 16

            # 6. Apply Gain & Saturation Clip (12-bit)
            p_prime = (I_blc * gain_val + (1 << 9)) >> 10
            output[y, x] = min(p_prime, 4095)
            # print(f"Pixel ({x},{y}) Channel: {channel} BLC: {I_blc} Gains: [{g00:03x}, {g01:03x}, {g10:03x}, {g11:03x}] rx: {rx} ry: {ry} gain_val: {gain_val} Output: {output[y, x]:03X}")
            # print(f"  Weights: ix={ix} ({dx}), iy={iy} ({dy})")
    return output
def apply_dpc(img_2d):
    """
    執行 DPC (Defect Pixel Correction)
    輸入: BLC+LSC 後的 16x16 陣列
    輸出: 經過 DPC 修正後的 16x16 陣列
    """
    H, W = img_2d.shape
    padded = np.pad(img_2d, 2, mode='reflect') # 邊界擴充 2 像素 (Reflect Padding)
    output = np.copy(img_2d)
    TH = 320

    for y in range(H):
        for x in range(W):
            # 提取 5x5 window (對應原圖座標 x, y，在 padded 中座標為 x+2, y+2)
            # Window 範圍: [y:y+5, x:x+5]
            win = padded[y:y+5, x:x+5]
            P = win[2, 2] # 中心像素

            # 四個方向的向量 (由圖示 image_683c44.png 提取)
            # H: [H0, H1, H2, H3] -> [win[2,0], win[2,1], win[2,3], win[2,4]]
            directions = {
                'H':  [win[2, 0], win[2, 1], win[2, 3], win[2, 4]],
                'V':  [win[0, 2], win[1, 2], win[3, 2], win[4, 2]],
                'D1': [win[0, 0], win[1, 1], win[3, 3], win[4, 4]],
                'D2': [win[0, 4], win[1, 3], win[3, 1], win[4, 0]]
            }

            scores = {}
            medians = {}
            
            # 計算每個方向的 Median 與 SAD Score
            # Score = sum(|Pixel_i - Median|)
            for name in ['H', 'V', 'D1', 'D2']:
                vec = directions[name]
                # 計算四個鄰居的 Median: 偶數個取中間兩個的平均 (Spec 通常指四個排序後取中間)
                # 一般硬體實作四個數 median 常取排序後第 2 或第 3 小，這裡用 np.median 模擬
                m_val = int(np.median(vec)) 
                medians[name] = m_val
                scores[name] = sum(abs(p_i - m_val) for p_i in vec)

            # 挑選最小 SAD 的方向 (Tie-breaking: H > V > D1 > D2)
            # Python 的 min 在 key 相同時會回傳第一個遇到的，所以順序要排好
            order = ['H', 'V', 'D1', 'D2']
            best_dir = min(order, key=lambda d: scores[d])
            target = medians[best_dir]
           
            # 判斷是否替換中心像素
            if abs(int(P) - int(target)) > TH:
                output[y, x] = target
            else:
                output[y, x] = P
            # if y == 0 and (x == 1 or x == 0):
            #     # 格式化 Scores: 每個數值轉為 Hex
            #     hex_scores = {k: f"{v:X}" for k, v in scores.items()}
            #     # 格式化 Medians: 每個數值轉為 3 位 Hex (補零)
            #     hex_medians = {k: f"{v:03X}" for k, v in medians.items()}
                
            #     print(f"Pixel ({x},{y}) P: {P}\n"
            #         f"Medians: {hex_medians}\n"
            #         f"Scores: {hex_scores}\n"
            #         f"Best Dir: {best_dir}\n"
            #         f"Target: {target:03X}")
            #     print(f"Output = {output[y, x]:03X}\n")
    return output
def apply_demosaicing(img_2d):
    """
    執行 3x3 Bilinear Demosaicing
    輸入: DPC 後的 16x16 Bayer 影像 (RGGB)
    輸出: 三個 16x16 矩陣 (R, G, B)
    """
    H, W = img_2d.shape
    # 根據 spec 使用 1 pixel reflect padding
    padded = np.pad(img_2d, 1, mode='reflect')
    
    out_R = np.zeros((H, W), dtype=int)
    out_G = np.zeros((H, W), dtype=int)
    out_B = np.zeros((H, W), dtype=int)

    for y in range(H):
        for x in range(W):
            # 在 padded 中的座標需位移 +1
            py, px = y + 1, x + 1
            
            # 取得鄰居像素 (N, S, E, W, NW, NE, SW, SE)
            C  = padded[py, px]
            N  = padded[py-1, px]
            S  = padded[py+1, px]
            E  = padded[py, px+1]
            W_ = padded[py, px-1]
            NW = padded[py-1, px-1]
            NE = padded[py-1, px+1]
            SW = padded[py+1, px-1]
            SE = padded[py+1, px+1]

            # 判定目前位置在 Bayer Pattern (RGGB) 的哪種顏色
            if y % 2 == 0:
                if x % 2 == 0: # R Location
                    out_R[y, x] = C
                    out_G[y, x] = (N + S + E + W_) // 4
                    out_B[y, x] = (NW + NE + SW + SE) // 4
                else: # Gr Location (Green on Red row)
                    out_R[y, x] = (W_ + E) // 2
                    out_G[y, x] = C
                    out_B[y, x] = (N + S) // 2
            else:
                if x % 2 == 0: # Gb Location (Green on Blue row)
                    out_R[y, x] = (N + S) // 2
                    out_G[y, x] = C
                    out_B[y, x] = (W_ + E) // 2
                else: # B Location
                    out_R[y, x] = (NW + NE + SW + SE) // 4
                    out_G[y, x] = (N + S + E + W_) // 4
                    out_B[y, x] = C
                    
    return out_R, out_G, out_B

def apply_ccm(R, G, B):
    """
    執行 Color Correction Matrix (CCM) 運算
    依據提供之矩陣 Cint 並進行 12-bit Saturation
    """
    # 定義硬體矩陣與參數
    Cint = np.array([
        [1100, -50, -50],
        [-50, 1100, -50],
        [-50, -50, 1100]
    ])
    
    H, W = R.shape
    final_R = np.zeros((H, W), dtype=int)
    final_G = np.zeros((H, W), dtype=int)
    final_B = np.zeros((H, W), dtype=int)

    for y in range(H):
        for x in range(W):
            rgb_raw = np.array([R[y, x], G[y, x], B[y, x]])
            
            # CCM 運算: (Cint * Rraw + 512) >> 10
            res = np.dot(Cint, rgb_raw)
            res_rounded = (res + 512) >> 10
            
            # 12-bit 限制 (0 to 4095)
            res_clipped = np.clip(res_rounded, 0, 4095)
            
            final_R[y, x] = res_clipped[0]
            final_G[y, x] = res_clipped[1]
            final_B[y, x] = res_clipped[2]
            
    return final_R, final_G, final_B

def main():
    try:
        generate_patterns()
        gain_tables = parse_gain_map('lsc_gain_map.txt')
        patterns = parse_input_txt('input.txt')
    except FileNotFoundError as e:
        print(f"error: file not found - {e.filename}")
        return

    # 定義所有要輸出的檔案路徑與標題
    file_configs = {
        'f_lsc': ('LSC_result.txt', "// After BLC + LSC\n"),
        'f_lsc_pad': ('LSC_result_padding.txt', "// After BLC + LSC with 2-px Padding\n"),
        'f_dpc': ('DPC_result.txt', "// After BLC + LSC + DPC\n"),
        'f_dpc_pad': ('DPC_result_padding.txt', "// After BLC + LSC + DPC with 1-px Padding\n"),
        'f_r': ('result_r.txt', "// Demosaic R channel\n"),
        'f_g': ('result_g.txt', "// Demosaic G channel\n"),
        'f_b': ('result_b.txt', "// Demosaic B channel\n"),
        'f_fr': ('output_r_ccm.txt', "// Final CCM R channel\n"),
        'f_fg': ('output_g_ccm.txt', "// Final CCM G channel\n"),
        'f_fb': ('output_b_ccm.txt', "// Final CCM B channel\n")
    }

    # 使用字典管理開啟的檔案物件
    fps = {}
    try:
        for key, (path, header) in file_configs.items():
            fps[key] = open(path, 'w', encoding='utf-8')
            fps[key].write(header)

        for i, raw_data in enumerate(patterns):
            if len(raw_data) != 256:
                print(f"warning: Pattern {i+1:03d} data len mismatch ({len(raw_data)})")
                continue
            
            pattern_header = f"// Pattern {i+1:03d}\n"
            for f in fps.values():
                f.write(pattern_header)

            # --- 步驟 1: BLC + LSC ---
            lsc_2d = process_isp(raw_data, gain_tables)
            for row in lsc_2d:
                fps['f_lsc'].write(" ".join([f"{v:03X}" for v in row]) + "\n")

            # LSC Padding (2-pixel 為 DPC 準備)
            padded_lsc_2d = np.pad(lsc_2d, 2, mode='reflect')
            for row in padded_lsc_2d:
                fps['f_lsc_pad'].write(" ".join([f"{v:03X}" for v in row]) + "\n")

            # --- 步驟 2: DPC ---
            dpc_2d = apply_dpc(lsc_2d)
            for row in dpc_2d:
                fps['f_dpc'].write(" ".join([f"{v:03X}" for v in row]) + "\n")

            # DPC Padding (1-pixel 為 Demosaic 準備)
            padded_dpc_2d = np.pad(dpc_2d, 1, mode='reflect')
            for row in padded_dpc_2d:
                fps['f_dpc_pad'].write(" ".join([f"{v:03X}" for v in row]) + "\n")

            # --- 步驟 3: Demosaicing (插值) ---
            res_r, res_g, res_b = apply_demosaicing(dpc_2d)
            for row in res_r: fps['f_r'].write(" ".join([f"{v:03X}" for v in row]) + "\n")
            for row in res_g: fps['f_g'].write(" ".join([f"{v:03X}" for v in row]) + "\n")
            for row in res_b: fps['f_b'].write(" ".join([f"{v:03X}" for v in row]) + "\n")

            # --- 步驟 4: CCM (Matrix 運算) ---
            f_res_r, f_res_g, f_res_b = apply_ccm(res_r, res_g, res_b)
            for row in f_res_r: fps['f_fr'].write(" ".join([f"{v:03X}" for v in row]) + "\n")
            for row in f_res_g: fps['f_fg'].write(" ".join([f"{v:03X}" for v in row]) + "\n")
            for row in f_res_b: fps['f_fb'].write(" ".join([f"{v:03X}" for v in row]) + "\n")

        print("ISP Pipeline Process completed!")
        print("Generated files: " + ", ".join([v[0] for v in file_configs.values()]))

    finally:
        # 確保程式出錯也會關閉所有檔案
        for f in fps.values():
            f.close()
            
if __name__ == "__main__":
    main()