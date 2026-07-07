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
import os

def verify_from_file(file_path="input.txt"):
    if not os.path.exists(file_path):
        print(f"Error: Cannot find {file_path}")
        return

    # 指定 utf-8 讀取檔案內容
    with open(file_path, "r", encoding='utf-8') as f:
        tokens = f.read().split()
        
    if not tokens:
        print("Error: File is empty.")
        return

    it = iter(tokens)
    try:
        num_cases = int(next(it))
    except (StopIteration, ValueError):
        print("Error: Invalid format, cannot read number of cases.")
        return

    print(f"--- Starting Verification: {file_path} (Total: {num_cases} cases) ---")
    print("-" * 50)

    pass_count = 0
    for i in range(1, num_cases + 1):
        try:
            expected_ans = int(next(it))
            test_type = int(next(it))
            
            shape_arr = []
            for _ in range(16):
                t = int(next(it))
                a = int(next(it))
                b = int(next(it))
                c = int(next(it))
                d = int(next(it))
                shape_arr.append([t, a, b, c, d])
            
            # 呼叫你的 drc 函式
            actual_ans = drc(shape_arr, test_type)
            
            if actual_ans == expected_ans:
                print(f"Case {i:3d}: PASS (Ans: {actual_ans})")
                pass_count += 1
            else:
                print(f"Case {i:3d}: FAIL | Expected: {expected_ans}, Got: {actual_ans} (Type: {test_type})")
                
        except StopIteration:
            print(f"Warning: Unexpected end of file at case {i}")
            break
        except ValueError:
            print(f"Error: Data format error at case {i}")
            break

    print("-" * 50)
    print(f"Final Result: {pass_count}/{num_cases} Passed")

if __name__ == "__main__":
    verify_from_file("input.txt")