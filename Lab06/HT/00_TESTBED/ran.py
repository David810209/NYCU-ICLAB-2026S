import random
from collections import OrderedDict

CHARS = ['A', 'B', 'C', 'E', 'I', 'L', 'O', 'V']
MODE_STRING = {
    0: "ILOVE",
    1: "ICLAB",
}

RANDOM_CASES = 100000
RANDOM_SEED = 42

class Node:
    def __init__(self, weight, order, ch=None, left=None, right=None):
        self.weight = weight
        self.order = order
        self.ch = ch
        self.left = left
        self.right = right

def build_huffman(weights):
    nodes = [Node(weight=weights[i], order=i, ch=CHARS[i]) for i in range(8)]
    next_order = len(nodes)

    while len(nodes) > 1:
        # weight 大到小；同 weight 舊的在前
        nodes.sort(key=lambda n: (-n.weight, n.order))

        # 取最小兩個
        a = nodes.pop()
        b = nodes.pop()

        # 較大放左，較小放右；若相同，較舊放左
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

    for w in range(8):
        add_case(cases, [w] * 8, f"all_{w}")

    for i in range(8):
        arr = [0] * 8
        arr[i] = 7
        add_case(cases, arr, f"single_7_{CHARS[i]}")

        arr = [0] * 8
        arr[i] = 1
        add_case(cases, arr, f"single_1_{CHARS[i]}")

    for i in range(8):
        for j in range(i + 1, 8):
            arr = [0] * 8
            arr[i] = 7
            arr[j] = 7
            add_case(cases, arr, f"two_7_{CHARS[i]}_{CHARS[j]}")

            arr = [0] * 8
            arr[i] = 1
            arr[j] = 7
            add_case(cases, arr, f"two_1_7_{CHARS[i]}_{CHARS[j]}")

    for base in range(1, 8):
        for i in range(8):
            arr = [base] * 8
            arr[i] = 0
            add_case(cases, arr, f"one_zero_rest_{base}_{CHARS[i]}")

    for base in range(0, 7):
        for i in range(8):
            arr = [base] * 8
            arr[i] = 7
            add_case(cases, arr, f"one_7_rest_{base}_{CHARS[i]}")

    add_case(cases, [0, 1, 2, 3, 4, 5, 6, 7], "ascending")
    add_case(cases, [7, 6, 5, 4, 3, 2, 1, 0], "descending")
    add_case(cases, [0, 7, 0, 7, 0, 7, 0, 7], "alt_0_7")
    add_case(cases, [7, 0, 7, 0, 7, 0, 7, 0], "alt_7_0")
    add_case(cases, [1, 7, 1, 7, 1, 7, 1, 7], "alt_1_7")
    add_case(cases, [7, 1, 7, 1, 7, 1, 7, 1], "alt_7_1")

    add_case(cases, [3, 3, 3, 3, 3, 3, 3, 4], "seven_3_one_4")
    add_case(cases, [4, 3, 3, 3, 3, 3, 3, 3], "one_4_seven_3")
    add_case(cases, [2, 2, 2, 2, 3, 3, 3, 3], "four_2_four_3")
    add_case(cases, [1, 1, 1, 1, 1, 2, 2, 2], "five_1_three_2")
    add_case(cases, [0, 0, 0, 0, 1, 1, 1, 1], "four_0_four_1")
    add_case(cases, [0, 0, 1, 1, 2, 2, 3, 3], "pairwise_equal")

    add_case(cases, [1, 1, 1, 1, 1, 1, 1, 1], "all_1_tie")
    add_case(cases, [1, 1, 1, 1, 2, 2, 2, 2], "all_tie_merge")
    add_case(cases, [1, 1, 2, 2, 3, 3, 4, 4], "pair_ladder")
    add_case(cases, [1, 2, 1, 2, 1, 2, 1, 2], "interleave_1_2")
    add_case(cases, [2, 1, 2, 1, 2, 1, 2, 1], "interleave_2_1")

    add_case(cases, [7, 7, 0, 0, 7, 7, 0, 0], "bias_A_B_I_L")
    add_case(cases, [0, 0, 7, 7, 0, 0, 7, 7], "bias_C_E_O_V")
    add_case(cases, [7, 0, 7, 0, 7, 0, 7, 0], "mode_split_1")
    add_case(cases, [0, 7, 0, 7, 0, 7, 0, 7], "mode_split_2")

    return cases

def random_weights_biased(rng):
    """
    偏向產生容易撞到 bug 的 random：
    - 0 跟 7 機率高
    - 也常產生重複值
    """
    choices = [0, 0, 0, 1, 1, 2, 3, 4, 5, 6, 7, 7, 7]
    return [rng.choice(choices) for _ in range(8)]

def random_weights_uniform(rng):
    return [rng.randint(0, 7) for _ in range(8)]

def random_weights_tie_heavy(rng):
    """
    先選 2~3 個 base value，再重複填進去
    讓 tie 更常出現
    """
    k = rng.choice([2, 2, 3])
    vals = [rng.randint(0, 7) for _ in range(k)]
    return [rng.choice(vals) for _ in range(8)]

def generate_random_cases(case_dict, count=300, seed=42):
    rng = random.Random(seed)

    while len(case_dict) < count + len(generate_edge_cases()):
        mode = rng.randint(0, 2)
        if mode == 0:
            arr = random_weights_biased(rng)
        elif mode == 1:
            arr = random_weights_uniform(rng)
        else:
            arr = random_weights_tie_heavy(rng)

        add_case(case_dict, arr, "random")

def write_files(input_path="input.txt", output_path="output.txt",
                random_cases=300, seed=42):
    cases = generate_edge_cases()
    edge_count = len(cases)

    generate_random_cases(cases, count=random_cases, seed=seed)

    with open(input_path, "w") as fin, open(output_path, "w") as fout:
        for weights, tag in cases.items():
            for mode in [0, 1]:
                fin.write(" ".join(map(str, weights)) + "\n")
                fin.write(str(mode) + "\n")

                bitlen, bits = encode(list(weights), mode)
                fout.write(f"{bitlen} {bits}\n")

    total_patterns = len(cases)
    total_cases = total_patterns * 2

    print(f"edge patterns   = {edge_count}")
    print(f"total patterns  = {total_patterns}")
    print(f"total testcases = {total_cases}")
    print(f"input  -> {input_path}")
    print(f"output -> {output_path}")

if __name__ == "__main__":
    write_files(
        input_path="input.txt",
        output_path="output.txt",
        random_cases=RANDOM_CASES,
        seed=RANDOM_SEED
    )