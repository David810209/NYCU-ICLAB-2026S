import random

def to_bin(value, bits):
    return format(value, f'0{bits}b')

def generate_test_instructions(num_instructions=4096):
    output = []
    output_comment = []
    addr = 0
    store_offset = 0

    for _ in range(num_instructions):
        instr_type = random.choice(["add", "sub", "mult", "load", "store"])
        rs = random.randint(0, 15)
        rt = random.randint(0, 15)
        rd = random.randint(0, 15)

        if instr_type == "add":
            op = '000'
            func = '0'
            instr = op + to_bin(rs, 4) + to_bin(rt, 4) + to_bin(rd, 4) + func
            comment = f"add r{rd} = r{rs} + r{rt}"

        elif instr_type == "sub":
            op = '000'
            func = '1'
            instr = op + to_bin(rs, 4) + to_bin(rt, 4) + to_bin(rd, 4) + func
            comment = f"sub r{rd} = r{rs} - r{rt}"

        elif instr_type == "mult":
            op = '001'
            func = '1'
            instr = op + to_bin(rs, 4) + to_bin(rt, 4) + to_bin(rd, 4) + func
            comment = f"mult r{rd} = r{rs} * r{rt}"

        elif instr_type == "load":
            imm = random.randint(0, 15)
            op = '010'
            instr = op + to_bin(rs, 4) + to_bin(rt, 4) + to_bin(imm, 5)
            comment = f"load r{rt} = DRAM[r{rs} * {imm} + {imm}]"

        elif instr_type == "store":
            imm = random.randint(0, 15)
            op = '011'
            instr = op + to_bin(rs, 4) + to_bin(rt, 4) + to_bin(imm, 5)
            comment = f"store DRAM[r{rs} * {imm} + {imm}] = r{rt}"

        output_comment.append(f"@{addr:04X} ({addr}) // {comment}\n{instr}")
        output.append(f"@{addr:04X}\n{instr}")
        addr += 1

    return "\n".join(output) , "\n".join(output_comment)

if __name__ == "__main__":

    result , result_comment = generate_test_instructions(4096)
    with open("random_instructions_commend.txt", "w") as f:
        f.write(result_comment)
    
    with open("random_instructions.txt", "w") as f:
        f.write(result)
