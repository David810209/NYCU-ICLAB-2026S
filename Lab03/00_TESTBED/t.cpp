
//g++ -o t t.cpp -static-libstdc++ -static-libgcc
//./t

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iomanip>
#include <map>
#include <stdint.h>  // 解決 uint16_t 未定義的問題
#include <cstdio>
#include <cstdlib>

using namespace std;

// 模擬 DRAM 存儲
map<uint16_t, uint64_t> golden_DRAM;

// 讀取 DRAM_init.txt
void load_dram() {
    ifstream infile("DRAM_init.dat");
    if (!infile) {
        printf("Error: Cannot open DRAM_init.dat\n");
        return;
    }
    string addr_str, data_str;
    while (infile >> addr_str >> data_str) {
        // addr_str 格式可能是 @00000, 去掉第一個字元 '@'
        uint16_t addr = (uint16_t)strtoul(addr_str.c_str() + 1, NULL, 16);
        uint64_t data = strtoull(data_str.c_str(), NULL, 16);
        golden_DRAM[addr] = data;
    }
    infile.close();
}

int64_t calculate_tree_extreme(uint16_t root_addr) {
    uint64_t op_stack[512];
    bool op_flag_stack[512];
    int64_t val_stack[512];
    bool val_flag[512]; 
    int op_stack_ptr = -1;
    int val_stack_ptr = -1;

    // 開啟檔案 (Append 模式)
    FILE* fp = fopen("calc.txt", "a");
    if (!fp) return 0;

    fprintf(fp, "\n--- Start Calculation for root_addr: %04x ---\n", root_addr);

    uint64_t root_node = golden_DRAM[root_addr];
    
    // Verilog: node[63] == 1'b1 是運算節點
    if (!((root_node >> 63) & 1ULL)) {
        // 常數處理
        int64_t val = (int64_t)((root_node >> 32) & 0x7FFFFFFF);
        if ((root_node >> 62) & 1ULL) val |= 0xFFFFFFFF80000000LL;
        fprintf(fp, "Root is constant: %lld\n", val);
        fclose(fp);
        return val;
    }

    // 壓入第一個運算節點
    op_stack[++op_stack_ptr] = root_node;
    op_flag_stack[op_stack_ptr] = false;

    while (op_stack_ptr >= 0) {
        uint64_t curr = op_stack[op_stack_ptr];
        bool curr_flag = op_flag_stack[op_stack_ptr];
        op_stack_ptr--;
        // 使用 bit 61 做為「已展開標記」
        if (curr & 0x2000000000000000ULL) {
            int op = (curr >> 32) & 0x3;
            int64_t b = val_stack[val_stack_ptr];
            int64_t a = val_stack[val_stack_ptr-1];
            bool b_flag = val_flag[val_stack_ptr];
            bool a_flag = val_flag[val_stack_ptr-1];
            val_stack_ptr -= 2;
            int64_t res = 0;
            if(a_flag){
                int64_t tmp = a;
                a = b;
                b = tmp;
            }
            if (op == 0)      res = a + b;
            else if (op == 1) res = a - b;
            else if (op == 2) res = a * b;
            else              res = a >> (b & 0x3F);

            val_stack[++val_stack_ptr] = res;
            if(curr_flag) val_flag[val_stack_ptr] = true; 
            else val_flag[val_stack_ptr] = false;
            

            fprintf(fp, "curr=%016llx 標記位元為 1：執行運算\n", curr);
            fprintf(fp, "  a=%lld b=%lld op=%d result=%lld\n", a, b, op, res);
        }
        else {
            uint16_t left_addr  = (uint16_t)((curr >> 16) & 0xFFFF);
            uint16_t right_addr = (uint16_t)(curr & 0xFFFF);
            
            fprintf(fp, "獲取左右子節點資料，父節點: %016llx (L:%04x, R:%04x)\n", curr, left_addr, right_addr);

            uint64_t left_node  = golden_DRAM[left_addr];
            uint64_t right_node = golden_DRAM[right_addr];

            // 壓回當前節點並標記 bit 61
            op_stack[++op_stack_ptr] = curr | 0x2000000000000000ULL;
            // 左子處理
            if ((left_node >> 63) & 1ULL) {
                op_stack[++op_stack_ptr] = left_node;
                op_flag_stack[op_stack_ptr] = false;
                fprintf(fp, "  左子節點 %04x 是運算節點, 數值是%016llx\n", left_addr, left_node);
            } else {
                int64_t l_val = (int64_t)((left_node >> 32) & 0x7FFFFFFF);
                if ((left_node >> 62) & 1ULL) l_val |= 0xFFFFFFFF80000000LL;
                val_stack[++val_stack_ptr] = l_val;
                val_flag[val_stack_ptr] = false;
                fprintf(fp, "  左子節點 %04x 是常數: %lld\n", left_addr, l_val);
            }
            // 右子處理
            if ((right_node >> 63) & 1ULL) {
                op_stack[++op_stack_ptr] = right_node;
                op_flag_stack[op_stack_ptr] = true;
                fprintf(fp, "  右子節點 %04x 是運算節點, 數值是%016llx\n", right_addr, right_node);
            } else {
                int64_t r_val = (int64_t)((right_node >> 32) & 0x7FFFFFFF);
                if ((right_node >> 62) & 1ULL) r_val |= 0xFFFFFFFF80000000LL;
                val_stack[++val_stack_ptr] = r_val;
                val_flag[val_stack_ptr] = true; 
                fprintf(fp, "  右子節點 %04x 是常數: %lld\n", right_addr, r_val);
            }

            
        }
    }

    int64_t result = val_stack[0];
    fprintf(fp, "--- Final Result: %lld ---\n", result);
    fclose(fp);
    return result;
}

int main() {
    load_dram();
    // 呼叫 root 0
    calculate_tree_extreme(0x1700);
    return 0;
}