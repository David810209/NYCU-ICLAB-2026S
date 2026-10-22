/*
g++ -o t run_tree.cpp -static-libstdc++ -static-libgcc; ./t
*/ 

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <iomanip>
#include <map>
#include <stdint.h>
#include <cstdio>
#include <cstdlib>
#include <algorithm>

using namespace std;

map<uint16_t, uint64_t> golden_DRAM;

void load_dram() {
    ifstream infile("DRAM_init.dat");
    if (!infile) {
        printf("Error: Cannot open DRAM_init.dat\n");
        return;
    }

    string addr_str, data_str;
    while (infile >> addr_str >> data_str) {
        uint16_t addr = (uint16_t)strtoul(addr_str.c_str() + 1, NULL, 16);
        uint64_t data = strtoull(data_str.c_str(), NULL, 16);
        golden_DRAM[addr] = data;
    }

    infile.close();
}

int64_t get_const_value(uint64_t node) {
    int64_t val = (int64_t)((node >> 32) & 0x7FFFFFFF);
    if ((node >> 62) & 1ULL) {
        val |= 0xFFFFFFFF80000000LL;
    }
    return val;
}

int64_t calculate_tree_extreme(uint16_t root_addr) {
    uint64_t op_stack[512];
    bool op_flag_stack[512];

    int64_t val_stack[512];
    bool val_flag[512];

    int op_stack_ptr = -1;
    int val_stack_ptr = -1;

    int max_op_stack_depth = 0;
    int max_val_stack_depth = 0;
    long long check_stack_top_count = 0;

    FILE* fp = fopen("calc.txt", "w");
    if (!fp) {
        printf("Error: Cannot open calc.txt\n");
        return 0;
    }

    fprintf(fp, "\n--- Start Calculation for root_addr: %04x ---\n", root_addr);

    uint64_t root_node = golden_DRAM[root_addr];

    if (!((root_node >> 63) & 1ULL)) {
        int64_t val = get_const_value(root_node);

        fprintf(fp, "Root is constant: %lld\n", val);
        fprintf(fp, "Max op stack depth = 0\n");
        fprintf(fp, "Max val stack depth = 1\n");
        fprintf(fp, "Check stack top count = 0\n");

        printf("Final Result = %lld\n", val);
        printf("Max op stack depth = 0\n");
        printf("Max val stack depth = 1\n");
        printf("Check stack top count = 0\n");

        fclose(fp);
        return val;
    }

    // root_node
    op_stack[++op_stack_ptr] = (root_node & 0x0000000300000000ULL)   // op  (bit 33-32)
                         | (root_node & 0x00000000FFFFFFFFULL);  // L/R (bit 31-0)
    op_flag_stack[op_stack_ptr] = false;
    max_op_stack_depth = max(max_op_stack_depth, op_stack_ptr + 1);

    while (op_stack_ptr >= 0) {
        check_stack_top_count++;

        uint64_t curr = op_stack[op_stack_ptr];
        bool curr_flag = op_flag_stack[op_stack_ptr];
        op_stack_ptr--;

        if (curr & 0x2000000000000000ULL) {
            int op = (curr >> 32) & 0x3;

            int64_t b = val_stack[val_stack_ptr];
            int64_t a = val_stack[val_stack_ptr - 1];

            bool b_flag = val_flag[val_stack_ptr];
            bool a_flag = val_flag[val_stack_ptr - 1];

            val_stack_ptr -= 2;

            if (a_flag) {
                int64_t tmp = a;
                a = b;
                b = tmp;
            }

            int64_t res = 0;

            if (op == 0) {
                res = a + b;
            }
            else if (op == 1) {
                res = a - b;
            }
            else if (op == 2) {
                res = a * b;
            }
            else {
                res = a >> (b & 0x3F);
            }

            val_stack[++val_stack_ptr] = res;
            val_flag[val_stack_ptr] = curr_flag;

            max_val_stack_depth = max(max_val_stack_depth, val_stack_ptr + 1);

            fprintf(fp, "curr=%016llx 標記位元為 1：執行運算\n", curr);
            fprintf(fp, "  a=%lld b=%lld op=%d result=%lld\n", a, b, op, res);
        }
        else {
            uint16_t left_addr  = (uint16_t)((curr >> 16) & 0xFFFF);
            uint16_t right_addr = (uint16_t)(curr & 0xFFFF);

            fprintf(fp,
                    "獲取左右子節點資料，父節點: %016llx (L:%04x, R:%04x)\n",
                    curr, left_addr, right_addr);

            uint64_t left_node  = golden_DRAM[left_addr];
            uint64_t right_node = golden_DRAM[right_addr];

            op_stack[++op_stack_ptr] = curr | 0x2000000000000000ULL;
            op_flag_stack[op_stack_ptr] = curr_flag;
            max_op_stack_depth = max(max_op_stack_depth, op_stack_ptr + 1);

            if ((left_node >> 63) & 1ULL) {
                op_stack[++op_stack_ptr] = (left_node & 0x0000000300000000ULL)
                         | (left_node & 0x00000000FFFFFFFFULL);
                op_flag_stack[op_stack_ptr] = false;
                max_op_stack_depth = max(max_op_stack_depth, op_stack_ptr + 1);

                fprintf(fp,
                        "  左子節點 %04x 是運算節點, 節點數值是%016llx\n",
                        left_addr, left_node);
            }
            else {
                int64_t l_val = get_const_value(left_node);

                val_stack[++val_stack_ptr] = l_val;
                val_flag[val_stack_ptr] = false;
                max_val_stack_depth = max(max_val_stack_depth, val_stack_ptr + 1);

                fprintf(fp, "  左子節點 %04x 是常數: %lld, 節點數值是%016llx\n", left_addr, l_val, left_node);
            }

            if ((right_node >> 63) & 1ULL) {
                op_stack[++op_stack_ptr] = (right_node & 0x0000000300000000ULL)
                         | (right_node & 0x00000000FFFFFFFFULL);
                op_flag_stack[op_stack_ptr] = true;
                max_op_stack_depth = max(max_op_stack_depth, op_stack_ptr + 1);

                fprintf(fp,
                        "  右子節點 %04x 是運算節點, 節點數值是%016llx\n",
                        right_addr, right_node);
            }
            else {
                int64_t r_val = get_const_value(right_node);

                val_stack[++val_stack_ptr] = r_val;
                val_flag[val_stack_ptr] = true;
                max_val_stack_depth = max(max_val_stack_depth, val_stack_ptr + 1);

                fprintf(fp, "  右子節點 %04x 是常數: %lld, 節點數值是%016llx\n", right_addr, r_val, right_node);
            }
        }
    }

    int64_t result = val_stack[0];

    fprintf(fp, "--- Final Result: %lld ---\n", result);
    fprintf(fp, "Max op stack depth = %d\n", max_op_stack_depth);
    fprintf(fp, "Max val stack depth = %d\n", max_val_stack_depth);
    fprintf(fp, "Check stack top count = %lld\n", check_stack_top_count);
    printf("root address = %x\n",root_addr);
    printf("Final Result = %llx\n", result);
    printf("Max op stack depth = %d\n", max_op_stack_depth);
    printf("Max val stack depth = %d\n", max_val_stack_depth);
    printf("Check stack top count = %lld\n", check_stack_top_count);

    fclose(fp);
    return result;
}

int main() {
    load_dram();

    calculate_tree_extreme(0xb600);

    return 0;
}