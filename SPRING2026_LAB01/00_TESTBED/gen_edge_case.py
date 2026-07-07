import random

def width_check(has_val_row, prev_is_end_point, requirement, prev_accum_result, is_width_check):
    # prev_accum_result 是 60-bit 整數，拆解為 15 個 4-bit 數值
    prev_accum_cnt_row = [(prev_accum_result >> (4 * i)) & 0xF for i in range(15)]
    
    accum_cnt_row = [0] * 15
    is_end_point_list = [0] * 15
    tmp_drc_result = [0] * 15

    def get_bit(val, i):
        if i < 0 or i > 14: return 0
        return (val >> i) & 1

    # Index 0 邏輯 (完全比照你的 Verilog)
    if is_width_check == 1 and get_bit(has_val_row, 0) == 1:
        accum_cnt_row[0] = 1
        if get_bit(has_val_row, 1) == 0:
            is_end_point_list[0] = 1
            if get_bit(prev_is_end_point, 0) == 0:
                tmp_drc_result[0] = 1

    # Index 1 to 14 邏輯
    for i in range(1, 15):
        current_val = get_bit(has_val_row, i)
        prev_val = get_bit(has_val_row, i-1)
        
        # 判斷是否要累積計數
        cond = (current_val == is_width_check) and (
            (is_width_check == 1) or 
            (is_width_check == 0 and (prev_val == 1 or accum_cnt_row[i-1] > 0))
        )
        
        if cond:
            accum_cnt_row[i] = (accum_cnt_row[i-1] + 1) & 0xF
            
            # 結束點偵測
            is_end = False
            if is_width_check == 1:
                if i == 14 or get_bit(has_val_row, i+1) == 0:
                    is_end = True
            else: # Spacing check
                if i < 14 and get_bit(has_val_row, i+1) == 1:
                    is_end = True
            
            if is_end:
                if accum_cnt_row[i] < requirement:
                    is_end_point_list[i] = 1
                    prev_end = get_bit(prev_is_end_point, i)
                    if (prev_end == 0) or (prev_end == 1 and prev_accum_cnt_row[i] != accum_cnt_row[i]):
                        tmp_drc_result[i] = 1

    # 封裝輸出
    drc_result = sum(tmp_drc_result)
    is_end_point_out = sum(is_end_point_list[i] << i for i in range(15))
    accum_result_out = sum(accum_cnt_row[i] << (4 * i) for i in range(15))
        
    return {
        'is_end_point': is_end_point_out,
        'drc_result': drc_result,
        'accum_result': accum_result_out
    }

def drc(shape_arr, drc_sel):
    # 1. 決定 Requirement
    if drc_sel in [0, 1, 3, 4, 5, 7]:
        requirement = 2
    elif drc_sel in [2, 6, 9, 11]:
        requirement = 3
    elif drc_sel in [8, 10, 13]:
        requirement = 4
    elif drc_sel == 12:
        requirement = 5
    else:
        requirement = 0
    
    # 2. 建立 15x15 網格 (0 或 1)
    grid = [[0 for _ in range(15)] for _ in range(15)]
    shape_sel = (drc_sel >> 1) + 1
    for shape in shape_arr:
        # t, a, b, c, d = shape
        # a, c 是 row；b, d 是 col
        if shape[0] == shape_sel:
            for i in range(shape[1], shape[3]):
                for j in range(shape[2], shape[4]):
                    if 0 <= i < 15 and 0 <= j < 15:
                        grid[i][j] = 1

    # ~drc_sel[0] 邏輯
    is_width_check = 1 if (drc_sel & 1) == 0 else 0
    total_drc_out = 0

    # 3. X 方向 (水平)
    x_prev_is_end_point = 0
    x_prev_accum_result = 0
    for row_idx in range(15):
        # 將列表 [0,1,1...] 轉成 15-bit 整數
        row_int = sum(grid[row_idx][bit_idx] << bit_idx for bit_idx in range(15))
        
        res_x = width_check(row_int, x_prev_is_end_point, requirement, x_prev_accum_result, is_width_check)
        total_drc_out += res_x['drc_result']
        x_prev_is_end_point = res_x['is_end_point']
        x_prev_accum_result = res_x['accum_result']

    # 4. Y 方向 (垂直)
    y_prev_is_end_point = 0
    y_prev_accum_result = 0
    for col_idx in range(15):
        # 轉置邏輯：擷取各 Row 的同一 Column Bit 組合成整數
        col_int = sum(grid[row_idx][col_idx] << row_idx for row_idx in range(15))
            
        res_y = width_check(col_int, y_prev_is_end_point, requirement, y_prev_accum_result, is_width_check)
        total_drc_out += res_y['drc_result']
        y_prev_is_end_point = res_y['is_end_point']
        y_prev_accum_result = res_y['accum_result']
    
    return total_drc_out

def generate_edge_case_shapes(test_type):
    shape_sel = (test_type >> 1) + 1
    is_width = (test_type & 1) == 0
    
    # 取得當前規則的 requirement
    if test_type in [0, 1, 3, 4, 5, 7]: req = 2
    elif test_type in [2, 6, 9, 11]: req = 3
    elif test_type in [8, 10, 13]: req = 4
    elif test_type == 12: req = 5
    else: req = 0

    edge_shapes = []
    # 隨機選擇一種攻擊模式
    mode = random.choice(['boundary', 'staircase', 'fragment', 'spacing_trap', 'full_bar'])

    if mode == 'boundary':
        # 模式 1：攻擊邊界 Index 0 與 Index 14
        # 在 (0,0) 放一個 1x1，在 (14,14) 放一個 1x1
        edge_shapes.append([shape_sel, 0, 0, 1, 1])
        edge_shapes.append([shape_sel, 14, 14, 15, 15])

    elif mode == 'staircase':
        # 模式 2：階梯形 (測試連續性判斷：長度不同但結束點位置相同)
        # 第一列長度為 req，第二列長度為 req-1
        edge_shapes.append([shape_sel, 2, 5, 3, 5 + req])
        edge_shapes.append([shape_sel, 3, 5 + 1, 4, 5 + req])

    elif mode == 'fragment':
        # 模式 3：碎屑 (大量 1x1，測試計數器頻繁切換)
        for i in range(0, 8, 2):
            edge_shapes.append([shape_sel, i, i, i+1, i+1])

    elif mode == 'spacing_trap':
        # 模式 4：間距陷阱 (兩個大方塊中間夾一個剛好違反 spacing 的小縫隙)
        if not is_width: # Spacing check 模式下最有用
            edge_shapes.append([shape_sel, 2, 0, 10, 5])
            edge_shapes.append([shape_sel, 2, 5 + (req-1), 10, 15])

    elif mode == 'full_bar':
        # 模式 5：滿格長條 (測試 15-bit 溢位與邊界結束偵測)
        edge_shapes.append([shape_sel, 7, 0, 8, 15])

    return edge_shapes

def generate_testcases(filename="input.txt", num_cases=1000):
    with open(filename, "w", encoding='utf-8') as f:
        f.write(f"{num_cases}\n\n")
        for _ in range(num_cases):
            test_type = random.randint(0, 13)
            shape_sel = (test_type >> 1) + 1
            
            # 1. 產生 Edge Case 目標形狀
            target_shapes = generate_edge_case_shapes(test_type)
            
            # 2. 產生一些雜訊 (t != shape_sel)，增加電路選擇電路的壓力
            noise_shapes = []
            for _ in range(5):
                t_noise = random.choice([t for t in range(8) if t != shape_sel])
                a, b = random.randint(0, 13), random.randint(0, 13)
                c, d = random.randint(a+1, 15), random.randint(b+1, 15)
                noise_shapes.append([t_noise, a, b, c, d])
            
            # 3. 合併並嚴格補足至 16 行
            final_shapes = (target_shapes + noise_shapes)
            # 如果超過 16 行則截斷，不足則補 0 (IC LAB 常見的 dummy data)
            final_shapes = final_shapes[:16]
            while len(final_shapes) < 16:
                final_shapes.append([0, 0, 0, 0, 0])

            # 4. 計算答案並寫入檔案
            ans = drc(final_shapes, test_type)
            f.write(f"{ans}\n")
            f.write(f"{test_type}\n")
            for s in final_shapes:
                f.write(f"{s[0]} {s[1]} {s[2]} {s[3]} {s[4]}\n")
            f.write("\n")
if __name__ == "__main__":
    N = 5000
    generate_testcases("input.txt", N)
    print(f"Successfully generated {N} cases to input.txt")