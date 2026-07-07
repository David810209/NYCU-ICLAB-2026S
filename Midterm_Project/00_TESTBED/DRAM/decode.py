#!/usr/bin/env python3
# decode_inst.py
# Reads inst_1_dram_file.dat and inst_2_dram_file.dat,
# decodes each instruction per ISA, writes decoded txt files.
#
# ISA (16-bit, big-endian instruction, little-endian in .dat file):
#   [15:13] opcode
#   000  ALU   [12:10]rs [9:7]rt [6:4]rd [3:1]sub [0]x
#              sub: 000=ADD 001=SUB 010=AND 011=OR
#                   100=NAND 101=NOR 110=XOR 111=SLT
#   001  MULT  [12:10]rs [9:7]rt [6:4]rd [3:1]rl [0]x
#              {rd,rl} = rs * rt
#   010  ADDI  [12:10]rs [9:7]rt [6:0]imm(signed)
#   011  SUBI  [12:10]rs [9:7]rt [6:0]imm(signed)
#   100  LOAD  [12:10]rs [9:7]rt [6:0]imm(signed)  rt <- MEM[rs+imm]
#   101  STORE [12:10]rs [9:7]rt [6:0]imm(signed)  MEM[rs+imm] <- rt
#   110  BEQ   [12:10]rs [9:7]rt [6:0]imm(signed)
#              if rs==rt: next_pc = pc + 2 + imm  else pc+2
#   111  JUMP  [12:0]addr  next_pc = addr (byte, must be even)

import sys
import os

ALU_OP = {
    0b000: "ADD",
    0b001: "SUB",
    0b010: "AND",
    0b011: "OR",
    0b100: "NAND",
    0b101: "NOR",
    0b110: "XOR",
    0b111: "SLT",
}

def sign7(v):
    """7-bit unsigned -> signed"""
    return v if v < 64 else v - 128

def decode(addr, inst):
    """Decode a 16-bit instruction at byte address addr."""
    op   = (inst >> 13) & 0x7
    rs   = (inst >> 10) & 0x7
    rt   = (inst >>  7) & 0x7
    rd   = (inst >>  4) & 0x7
    rl   = (inst >>  1) & 0x7
    sub  = (inst >>  1) & 0x7
    imm7 = inst & 0x7F
    simm = sign7(imm7)
    jaddr = inst & 0x1FFF

    if inst == 0x0000:
        return "NOP"

    if op == 0b000:
        name = ALU_OP[sub]
        return f"{name:<4} r{rd} = r{rs} , r{rt}"
    elif op == 0b001:
        return f"MULT {{r{rd},r{rl}}} = r{rs} * r{rt}"
    elif op == 0b010:
        return f"ADDI r{rt} = r{rs} + {simm}"
    elif op == 0b011:
        return f"SUBI r{rt} = r{rs} - {simm}"
    elif op == 0b100:
        return f"LOAD r{rt} <- MEM[r{rs} + {simm}]  ; eff_byte = DATA_BASE + (r{rs}+{simm})*2"
    elif op == 0b101:
        return f"STORE MEM[r{rs} + {simm}] <- r{rt}  ; eff_byte = DATA_BASE + (r{rs}+{simm})*2"
    elif op == 0b110:
        tgt = (addr + 2 + simm) & 0xFFFF
        taken = f"taken->0x{tgt:04X}" if tgt % 2 == 0 else f"taken->0x{tgt:04X} [MISALIGNED!]"
        return f"BEQ  if r{rs}==r{rt}: pc += 2+({simm}) ; {taken}"
    elif op == 0b111:
        tgt = jaddr  # address field IS the target byte address
        align = "" if tgt % 2 == 0 else " [MISALIGNED!]"
        return f"JUMP -> 0x{tgt:04X}{align}"
    else:
        return f"UNKNOWN op={op:03b}"

def parse_dat(filepath):
    """
    Parse a .dat file.
    Returns dict: byte_addr (int) -> instruction (int, 16-bit)
    Supports both:
      @XXXX          <- set current address
      LO HI          <- two hex bytes (little-endian word)
    """
    instructions = {}
    cur_addr = 0

    with open(filepath, 'r') as f:
        for raw in f:
            line = raw.split('//')[0].strip()  # strip comments
            if not line:
                continue
            if line.startswith('@'):
                cur_addr = int(line[1:], 16)
            else:
                parts = line.split()
                if len(parts) >= 2:
                    lo = int(parts[0], 16)
                    hi = int(parts[1], 16)
                    inst = (hi << 8) | lo   # little-endian
                    instructions[cur_addr] = inst
                    cur_addr += 2
                elif len(parts) == 1:
                    # single byte (shouldn't happen for 16-bit inst, but handle)
                    pass
    return instructions

def decode_file(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"ERROR: {input_path} not found")
        return

    instructions = parse_dat(input_path)

    # Build full address range 0x0000 ~ 0x1FFE (step 2)
    with open(output_path, 'w') as f:
        f.write(f"# Decoded from: {input_path}\n")
        f.write(f"# Format: @ADDR  RAW_HEX  BINARY           DECODED\n")
        f.write(f"# ISA: op[15:13] rs[12:10] rt[9:7] rd[6:4] sub/imm[6:0]\n")
        f.write("-" * 80 + "\n")
        ic = 0
        for addr in range(0x0000, 0x2000, 2):
            inst = instructions.get(addr, 0x0000)  # default NOP if missing
            lo = inst & 0xFF
            hi = (inst >> 8) & 0xFF
            binary = f"{inst:016b}"
            binary_spaced = f"{binary[0:3]} {binary[3:6]} {binary[6:9]} {binary[9:16]}"
            decoded = decode(addr, inst)
            f.write(f"{ic}:@{addr:04X}  {lo:02X} {hi:02X}  {binary_spaced}  {decoded}\n")
            ic = ic + 1

    print(f"Decoded {len(instructions)} instructions -> {output_path}")

if __name__ == "__main__":
    pairs = [
        ("inst_1_dram_file.dat", "inst1_decoded.txt"),
        ("inst_2_dram_file.dat", "inst2_decoded.txt"),
    ]

    for inp, out in pairs:
        decode_file(inp, out)