#include <iostream>
#include <vector>
#include <algorithm>
#include <ctime>

using namespace std;

enum OpType { ADD = 0, SUB = 1, MUL = 2, SHIFT = 3 };

struct Node {
    bool is_op;
    OpType op_type;
    int64_t value;
    Node *left, *right;
    Node() : is_op(false), op_type(ADD), value(0), left(nullptr), right(nullptr) {}
};

// 全域計數器
int total_node_count = 0;
int total_op_node_count = 0;

// 遞迴生成 8 層滿二元樹
Node* generate_full_tree(int current_depth, int max_depth) {
    Node* node = new Node();
    total_node_count++;

    if (current_depth == max_depth) {
        node->is_op = false;
        node->value = (rand() % 50) + 1;
        return node;
    }

    node->is_op = true;
    total_op_node_count++;
    node->op_type = static_cast<OpType>(rand() % 4);
    node->left = generate_full_tree(current_depth + 1, max_depth);
    node->right = generate_full_tree(current_depth + 1, max_depth);
    return node;
}

void simulate_harvester_logic(Node* root) {
    vector<Node*> op_stack;
    vector<bool> op_flag_stack; 
    vector<bool> is_expanded;   

    vector<int64_t> val_stack;
    vector<bool> val_flag_stack;

    int max_op_ptr = 0;
    int max_val_ptr = 0;
    int op_execute_cnt = 0; // 實際執行的運算次數

    if (!root->is_op) return;

    op_stack.push_back(root);
    op_flag_stack.push_back(false);
    is_expanded.push_back(false);

    while (!op_stack.empty()) {
        max_op_ptr = max(max_op_ptr, (int)op_stack.size());
        max_val_ptr = max(max_val_ptr, (int)val_stack.size());

        Node* curr = op_stack.back();
        bool curr_flag = op_flag_stack.back();
        bool expanded = is_expanded.back();
        
        op_stack.pop_back();
        op_flag_stack.pop_back();
        is_expanded.pop_back();

        if (expanded) {
            // 執行運算
            op_execute_cnt++;
            int64_t b = val_stack.back();
            bool b_flag = val_flag_stack.back();
            val_stack.pop_back();
            val_flag_stack.pop_back();

            int64_t a = val_stack.back();
            bool a_flag = val_flag_stack.back();
            val_stack.pop_back();
            val_flag_stack.pop_back();

            if (a_flag) { // 如果先彈出的是右子，交換順序
                int64_t tmp = a; a = b; b = tmp;
            }

            int64_t res = 0;
            if (curr->op_type == ADD)      res = a + b;
            else if (curr->op_type == SUB) res = a - b;
            else if (curr->op_type == MUL) res = a * b;
            else                           res = a >> (b & 0x3F);

            val_stack.push_back(res);
            val_flag_stack.push_back(curr_flag);

        } else {
            // 展開子節點
            op_stack.push_back(curr);
            op_flag_stack.push_back(curr_flag);
            is_expanded.push_back(true);

            // 先壓右子 (Flag = true)
            if (curr->right->is_op) {
                op_stack.push_back(curr->right);
                op_flag_stack.push_back(true);
                is_expanded.push_back(false);
            } else {
                val_stack.push_back(curr->right->value);
                val_flag_stack.push_back(true);
            }

            // 再壓左子 (Flag = false)
            if (curr->left->is_op) {
                op_stack.push_back(curr->left);
                op_flag_stack.push_back(false);
                is_expanded.push_back(false);
            } else {
                val_stack.push_back(curr->left->value);
                val_flag_stack.push_back(false);
            }
        }
    }

    printf("\n========================================\n");
    printf("Tree Statistics (8 Layers):\n");
    printf("Total Nodes in Tree:    %d (Expected: 255)\n", total_node_count);
    printf("Total Op Nodes:         %d (Expected: 127)\n", total_op_node_count);
    printf("Actual Ops Executed:    %d\n", op_execute_cnt);
    printf("----------------------------------------\n");
    printf("Hardware Stack Usage:\n");
    printf("Max OP Stack Depth:     %d\n", max_op_ptr);
    printf("Max VAL Stack Depth:    %d\n", max_val_ptr);
    printf("========================================\n");
}

int main() {
    srand(time(NULL));
    for(int i = 1;i <= 8;i++) {
        total_node_count = 0;
        total_op_node_count = 0;
        Node* root= generate_full_tree(1, i);
        simulate_harvester_logic(root);
    }
    return 0;
}