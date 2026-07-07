import random as rd

NUM_INSTRUCTIONS = 4096      
DATA_MEM_WORDS = 4096  # Data DRAM: 4096 words = 8192 bytes (0x1000 ~ 0x2FFF)
INST_MEM_WORDS = 4096  # Inst DRAM: 4096 words = 8192 bytes (0x0000 ~ 0x1FFF)

F_INST_1 = "./inst_1_dram_file.dat"
F_INST_2 = "./inst_2_dram_file.dat"
F_DATA   = "./data_dram_file.dat"
F_GOLDEN = "./golden_regs.txt"

def to_signed_16(val):
    val = val & 0xFFFF
    return val if val < 32768 else val - 65536

def format_16bit_hex_little_endian(val):
    val = val & 0xFFFF
    hex_str = f"{val:04x}"
    return f"{hex_str[2:4]} {hex_str[0:2]}"

def encode_R_type(func_code, rs, rt, rd_reg):
    return (0b000 << 13) | (rs << 10) | (rt << 7) | (rd_reg << 4) | (func_code << 1) | rd.randint(0, 1)

def encode_Mult(rs, rt, rd_reg, rl):
    return (0b001 << 13) | (rs << 10) | (rt << 7) | (rd_reg << 4) | (rl << 1) | rd.randint(0, 1)

def encode_I_type(opcode, rs, rt, imm):
    return (opcode << 13) | (rs << 10) | (rt << 7) | (imm & 0x7F)

# 陷阱產生器
def generate_trap_instruction():
    opcode = 0b010 # ADDI
    rs = rd.randint(0, 7)
    rt = rd.randint(0, 7)
    imm = rd.randint(1, 63)
    return encode_I_type(opcode, rs, rt, imm)

def generate_and_simulate_instruction(pc_word, core_regs, state, remaining_ic, restrict_store=False):
    inst_types = ['R', 'Mult', 'ADDI', 'SUBI', 'Load']
    
    # ==========================================
    # 核心邏輯：current address 是 PC + 1 (以 Word 為單位)
    # ==========================================
    current_addr_word = pc_word + 1
    
    # 剩餘跑道計算：確保跳躍後有足夠的空間執行剩下的指令
    max_safe_word = INST_MEM_WORDS - 6 - remaining_ic 
    if max_safe_word > current_addr_word + 1:
        inst_types.append('Branch')
        inst_types.append('Jump')

    if not restrict_store:
        inst_types.append('Store')

    while True:
        choice = rd.choice(inst_types)
        rs = rd.randint(0, 7)
        rt = rd.randint(0, 7)
        # rd_reg = rd.randint(0, 7) 
        # rl = rd.randint(0, 7)
        
        if choice == 'Mult':
            rd_reg, rl = rd.sample(range(8), 2)
        else:
            rd_reg = rd.randint(0, 7) 
            rl = rd.randint(0, 7)
            
        func = rd.randint(0, 7)
        
        # ==========================================
        # Load/Store 限制：Data DRAM 上次存取位址 +/- 200 bytes (+/- 100 words)
        # ==========================================
        if choice in ['Load', 'Store']:
            valid_imms = []
            for test_imm in range(-64, 64):
                target_word_idx = core_regs[rs] + test_imm
                if 0 <= target_word_idx < DATA_MEM_WORDS: 
                    if abs(target_word_idx - state['current_data_word']) <= 100: 
                        valid_imms.append(test_imm)
            
            if not valid_imms:
                continue 
            
            imm = rd.choice(valid_imms)
            state['current_data_word'] = core_regs[rs] + imm 

            opcode = 0b100 if choice == 'Load' else 0b101
            encoded = encode_I_type(opcode, rs, rt, imm)
            return encoded, choice, current_addr_word, rs, rt, rd_reg, rl, imm, func

        # ==========================================
        # Branch 限制：current address +/- 256 bytes (+/- 128 words)
        # ==========================================
        elif choice == 'Branch':
            taken = rd.choice([True, False])
            if taken:
                rt = rs  
            else:
                attempts = 0
                while core_regs[rt] == core_regs[rs] and attempts < 10:
                    rt = rd.randint(0, 7)
                    attempts += 1
                if core_regs[rt] == core_regs[rs]:
                    taken = True 
            
            # max_imm = 63 (7-bit signed)，天然符合 +/- 128 words 的限制
            max_imm = min(63, 128, max_safe_word - current_addr_word)
            if max_imm < 1:
                continue
            imm = rd.randint(1, max_imm)
            
            encoded = encode_I_type(0b110, rs, rt, imm)
            # Branch Target = PC + 1 + imm = current_addr_word + imm
            next_pc_word = current_addr_word + imm if taken else current_addr_word
            return encoded, choice, next_pc_word, rs, rt, rd_reg, rl, imm, func
            
        # ==========================================
        # Jump 限制：current address +/- 256 bytes (+/- 128 words)
        # ==========================================
        elif choice == 'Jump':
            min_target_word = current_addr_word + 1
            max_target_word = min(current_addr_word + 128, max_safe_word)
            if min_target_word > max_target_word:
                continue
            target_word = rd.randint(min_target_word, max_target_word)
            
            encoded = (0b111 << 13) | (target_word & 0x1FFF)
            next_pc_word = target_word
            return encoded, choice, next_pc_word, 0, 0, 0, 0, 0, 0

        # ==========================================
        # 一般運算指令
        # ==========================================
        else:
            imm = rd.randint(-64, 63)
            if choice == 'R':
                encoded = encode_R_type(func, rs, rt, rd_reg)
            elif choice == 'Mult':
                encoded = encode_Mult(rs, rt, rd_reg, rl)
            elif choice in ['ADDI', 'SUBI']:
                opcode = {'ADDI':0b010, 'SUBI':0b011}[choice]
                encoded = encode_I_type(opcode, rs, rt, imm)
            
        return encoded, choice, current_addr_word, rs, rt, rd_reg, rl, imm, func

def generate_patterns():
    f_golden = open(F_GOLDEN, "w")
    
    core1_regs = [0] * 8
    core2_regs = [0] * 8
    data_memory = [rd.randint(0, 0xFFFF) for _ in range(DATA_MEM_WORDS)]
    
    # 預先填滿 TRAP 陷阱
    inst_mem_1 = {i: generate_trap_instruction() for i in range(INST_MEM_WORDS)}
    inst_mem_2 = {i: generate_trap_instruction() for i in range(INST_MEM_WORDS)}
    inst_comments_1 = {i: " // TRAP" for i in range(INST_MEM_WORDS)}
    inst_comments_2 = {i: " // TRAP" for i in range(INST_MEM_WORDS)}
    
    pc_word1 = 0
    pc_word2 = 0
    state = {'current_data_word': 0} # 初始設定在 Index 0 (即 0x1000)，確保能合法開局
    
    f_data = open(F_DATA, "w")
    for i in range(DATA_MEM_WORDS):
        addr = 0x1000 + (i * 2) 
        f_data.write(f"@{addr:04x}\n") 
        f_data.write(format_16bit_hex_little_endian(data_memory[i]) + "\n")
    f_data.close()

    for ic in range(NUM_INSTRUCTIONS):
        remaining_ic = NUM_INSTRUCTIONS - ic 
        
        enc1, type1, next_pc_word1, rs1, rt1, rd1, rl1, imm1, func1 = generate_and_simulate_instruction(pc_word1, core1_regs, state, remaining_ic, restrict_store=False)
        enc2, type2, next_pc_word2, rs2, rt2, rd2, rl2, imm2, func2 = generate_and_simulate_instruction(pc_word2, core2_regs, state, remaining_ic, restrict_store=(type1=='Store'))
        
        inst_mem_1[pc_word1] = enc1
        inst_mem_2[pc_word2] = enc2
        inst_comments_1[pc_word1] = f"// Core 1: {type1} (IC={ic})"
        inst_comments_2[pc_word2] = f"// Core 2: {type2} (IC={ic})"
        
        next_c1_regs = list(core1_regs)
        next_c2_regs = list(core2_regs)
        
        mem_updates = []
        
        if type1 == 'Store': 
            m_addr = core1_regs[rs1] + imm1
            data = core1_regs[rt1]
            data_memory[m_addr] = data
            mem_updates.append(f"{0x1000 + (m_addr * 2):04x} {(data & 0xFFFF):04x}")
            
        if type2 == 'Store': 
            m_addr = core2_regs[rs2] + imm2
            data = core2_regs[rt2]
            data_memory[m_addr] = data
            mem_updates.append(f"{0x1000 + (m_addr * 2):04x} {(data & 0xFFFF):04x}")

        if type1 == 'Load': next_c1_regs[rt1] = to_signed_16(data_memory[core1_regs[rs1] + imm1])
        if type2 == 'Load': next_c2_regs[rt2] = to_signed_16(data_memory[core2_regs[rs2] + imm2])
        
        def alu_op(c_type, rs, rt, rd_reg, rl, imm, func, current_regs, next_regs):
            if c_type == 'R':
                if func == 0: next_regs[rd_reg] = to_signed_16(current_regs[rs] + current_regs[rt])
                elif func == 1: next_regs[rd_reg] = to_signed_16(current_regs[rs] - current_regs[rt])
                elif func == 2: next_regs[rd_reg] = to_signed_16(current_regs[rs] & current_regs[rt])
                elif func == 3: next_regs[rd_reg] = to_signed_16(current_regs[rs] | current_regs[rt])
                elif func == 4: next_regs[rd_reg] = to_signed_16(~(current_regs[rs] & current_regs[rt]))
                elif func == 5: next_regs[rd_reg] = to_signed_16(~(current_regs[rs] | current_regs[rt]))
                elif func == 6: next_regs[rd_reg] = to_signed_16(current_regs[rs] ^ current_regs[rt])
                elif func == 7: next_regs[rd_reg] = 1 if current_regs[rs] < current_regs[rt] else 0
            elif c_type == 'Mult':
                res = current_regs[rs] * current_regs[rt]
                res_32 = res & 0xFFFFFFFF
                next_regs[rd_reg] = to_signed_16(res_32 >> 16)
                next_regs[rl] = to_signed_16(res_32 & 0xFFFF)
            elif c_type == 'ADDI': next_regs[rt] = to_signed_16(current_regs[rs] + imm)
            elif c_type == 'SUBI': next_regs[rt] = to_signed_16(current_regs[rs] - imm)
            
        alu_op(type1, rs1, rt1, rd1, rl1, imm1, func1, core1_regs, next_c1_regs)
        alu_op(type2, rs2, rt2, rd2, rl2, imm2, func2, core2_regs, next_c2_regs)
        
        core1_regs = next_c1_regs
        core2_regs = next_c2_regs
        
        f_golden.write(f"IC={ic:04d}\n")
        f_golden.write("C1: " + " ".join([f"{(x & 0xFFFF):04x}" for x in core1_regs]) + "\n")
        f_golden.write("C2: " + " ".join([f"{(x & 0xFFFF):04x}" for x in core2_regs]) + "\n")
        
        f_golden.write(f"MEM_NUM: {len(mem_updates)}\n")
        for log in mem_updates:
            f_golden.write(log + "\n")
            
        if (ic + 1) % 50 == 0 or ic == NUM_INSTRUCTIONS - 1:
            f_golden.write("CHECK_DRAM: YES\n\n")
        else:
            f_golden.write("CHECK_DRAM: NO\n\n")

        pc_word1 = next_pc_word1
        pc_word2 = next_pc_word2

    f_golden.close()
    
    f_inst_1 = open(F_INST_1, "w")
    f_inst_2 = open(F_INST_2, "w")
    for i in range(INST_MEM_WORDS):
        addr = i * 2 # 轉回 Byte Address
        f_inst_1.write(f"@{addr:04x}\n")
        f_inst_1.write(format_16bit_hex_little_endian(inst_mem_1[i]) + f"{inst_comments_1[i]}\n")
        
        f_inst_2.write(f"@{addr:04x}\n")
        f_inst_2.write(format_16bit_hex_little_endian(inst_mem_2[i]) + f"{inst_comments_2[i]}\n")
        
    f_inst_1.close()
    f_inst_2.close()

    # print("✅ 完美遵照 PDF Spec 的 Data/Inst DRAM 與 PC+1 機制腳本生成完畢！")

if __name__ == '__main__':
    generate_patterns()