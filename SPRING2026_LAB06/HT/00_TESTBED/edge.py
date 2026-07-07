from collections import OrderedDict

CHARS = ['A', 'B', 'C', 'E', 'I', 'L', 'O', 'V']
MODE_STRING = {
    0: "ILOVE",
    1: "ICLAB",
}

class Node:
    def __init__(self, weight, order, ch=None, left=None, right=None):
        self.weight = weight
        self.order = order
        self.ch = ch
        self.left = left
        self.right = right

def build_huffman(weights):
    """
    規則整理：
    1. 先依 weight 大到小排序
    2. 若 weight 相同，字元順序 A > B > C > E > I > L > O > V
       也就是原始 index 小者優先
    3. 每次取最小兩個合併
    4. 合併時，較大的放左邊、較小的放右邊
    5. 若一樣大，較舊的放左邊、較新的放右邊
    6. 左邊邊碼 = 0，右邊邊碼 = 1
    """
    nodes = [Node(weight=weights[i], order=i, ch=CHARS[i]) for i in range(8)]
    next_order = len(nodes)

    while len(nodes) > 1:
        # 排成 大 -> 小；同 weight 則較舊(order 小)在前
        nodes.sort(key=lambda n: (-n.weight, n.order))

        # 取最後兩個 = 最小兩個
        a = nodes.pop()
        b = nodes.pop()

        # parent 的 left/right:
        # bigger on left, smaller on right
        # 若相同，old subtree on left, new subtree on right
        if (a.weight > b.weight) or (a.weight == b.weight and a.order < b.order):
            left, right = a, b
        else:
            left, right = b, a

        parent = Node(
            weight=left.weight + right.weight,
            order=next_order,
            left=left,
            right=right
        )
        next_order += 1
        nodes.append(parent)

    return nodes[0]

def get_codes(root):
    codes = {}

    def dfs(node, code):
        if node.ch is not None:
            # 若真的遇到單一節點樹，給 0
            codes[node.ch] = code if code != "" else "0"
            return
        dfs(node.left, code + '0')
        dfs(node.right, code + '1')

    dfs(root, "")
    return codes

def encode(weights, mode):
    root = build_huffman(weights)
    codes = get_codes(root)
    s = MODE_STRING[mode]
    bits = ''.join(codes[ch] for ch in s)
    return len(bits)-1, bits

def add_case(case_dict, weights, tag=""):
    key = tuple(weights)
    if key not in case_dict:
        case_dict[key] = tag

def generate_edge_cases():
    cases = OrderedDict()

    # 1. 全相同
    for w in range(8):
        add_case(cases, [w] * 8, f"all_{w}")

    # 2. 單一非零
    for i in range(8):
        arr = [0] * 8
        arr[i] = 7
        add_case(cases, arr, f"single_7_at_{CHARS[i]}")
        arr2 = [0] * 8
        arr2[i] = 1
        add_case(cases, arr2, f"single_1_at_{CHARS[i]}")

    # 3. 兩個非零
    for i in range(8):
        for j in range(i + 1, 8):
            arr = [0] * 8
            arr[i], arr[j] = 7, 7
            add_case(cases, arr, f"two_7_{CHARS[i]}_{CHARS[j]}")
            arr2 = [0] * 8
            arr2[i], arr2[j] = 1, 7
            add_case(cases, arr2, f"two_1_7_{CHARS[i]}_{CHARS[j]}")

    # 4. 單一 0，其餘相同
    for zero_w in range(1, 8):
        for i in range(8):
            arr = [zero_w] * 8
            arr[i] = 0
            add_case(cases, arr, f"one_zero_rest_{zero_w}_{CHARS[i]}")

    # 5. 單一 7，其餘相同
    for base in range(0, 7):
        for i in range(8):
            arr = [base] * 8
            arr[i] = 7
            add_case(cases, arr, f"one_7_rest_{base}_{CHARS[i]}")

    # 6. 遞增 / 遞減 / 交錯
    add_case(cases, [0, 1, 2, 3, 4, 5, 6, 7], "ascending")
    add_case(cases, [7, 6, 5, 4, 3, 2, 1, 0], "descending")
    add_case(cases, [0, 7, 0, 7, 0, 7, 0, 7], "alternating_0_7")
    add_case(cases, [7, 0, 7, 0, 7, 0, 7, 0], "alternating_7_0")
    add_case(cases, [1, 7, 1, 7, 1, 7, 1, 7], "alternating_1_7")
    add_case(cases, [7, 1, 7, 1, 7, 1, 7, 1], "alternating_7_1")

    # 7. 大量 tie
    add_case(cases, [3, 3, 3, 3, 3, 3, 3, 4], "seven_3_one_4")
    add_case(cases, [4, 3, 3, 3, 3, 3, 3, 3], "one_4_seven_3")
    add_case(cases, [2, 2, 2, 2, 3, 3, 3, 3], "four_2_four_3")
    add_case(cases, [1, 1, 1, 1, 1, 2, 2, 2], "five_1_three_2")
    add_case(cases, [0, 0, 0, 0, 1, 1, 1, 1], "four_0_four_1")
    add_case(cases, [0, 0, 1, 1, 2, 2, 3, 3], "pairwise_equal")

    # 8. 很容易影響 old/new subtree 次序的 case
    add_case(cases, [1, 1, 1, 1, 1, 1, 1, 1], "all_1_tie")
    add_case(cases, [1, 1, 1, 1, 2, 2, 2, 2], "all_tie_merge")
    add_case(cases, [1, 1, 2, 2, 3, 3, 4, 4], "pair_ladder")
    add_case(cases, [1, 2, 1, 2, 1, 2, 1, 2], "interleave_1_2")
    add_case(cases, [2, 1, 2, 1, 2, 1, 2, 1], "interleave_2_1")

    # 9. mode 文字偏向字元測試
    # ILOVE 用到 I L O V E
    # ICLAB 用到 I C L A B
    add_case(cases, [7, 7, 0, 0, 7, 7, 0, 0], "bias_A_B_I_L")
    add_case(cases, [0, 0, 7, 7, 0, 0, 7, 7], "bias_C_E_O_V")
    add_case(cases, [7, 0, 7, 0, 7, 0, 7, 0], "mode_split_1")
    add_case(cases, [0, 7, 0, 7, 0, 7, 0, 7], "mode_split_2")

    return cases

def write_files(input_path="input.txt", output_path="output.txt"):
    cases = generate_edge_cases()

    with open(input_path, "w") as fin, open(output_path, "w") as fout:
        for weights, tag in cases.items():
            for mode in [0, 1]:
                fin.write(" ".join(map(str, weights)) + "\n")
                fin.write(str(mode) + "\n")

                bitlen, bits = encode(list(weights), mode)
                fout.write(f"{bitlen} {bits}\n")

    print(f"Generated {len(cases) * 2} cases")
    print(f"Unique weight patterns: {len(cases)}")
    print(f"input  -> {input_path}")
    print(f"output -> {output_path}")

if __name__ == "__main__":
    write_files()