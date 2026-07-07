import random

def generate_random_hex_8bit(start_addr=0x1000, end_addr=0x17FF):
    output = []
    for addr in range(start_addr, end_addr + 1):
        value = random.randint(0, 255)  # 隨機產生一個 0~255 的整數
        hex_value = f"{value:02X}"      # 格式化成兩位數十六進位字串
        output.append(f"@{addr:04X}\n{hex_value}")  # 加入地址與值
    return "\n".join(output)

if __name__ == "__main__":

    result = generate_random_hex_8bit()
    with open("random_data.txt", "w") as f:
        f.write(result)
