def decode_dram_index(hex_str):
    # Convert the input Hex string to an integer
    try:
        idx = int(hex_str, 16)
    except ValueError:
        print("Error: Please enter a valid hexadecimal number (e.g., 0xEAFF)")
        return

    # Define bit width according to specifications
    # Bank (2 bits) | Row (6 bits) | Column (8 bits)
    
    col = idx & 0xFF                 # Get the lowest 8 bits (2^8 = 256)
    row = (idx >> 8) & 0x3F          # Right shift 8 bits and get 6 bits (2^6 = 64)
    bank = (idx >> 14) & 0x03        # Right shift 14 bits and get 2 bits (2^2 = 4)

    print(f"Input Hex: {hex_str}")
    print(f"Linear Index (Dec): {idx}")
    print("-" * 30)
    print(f"Bank   : {bank}")
    print(f"Row    : {row}")
    print(f"Column : {col}")
    print("-" * 30)

# Test the value you just asked about 60159 (Hex is 0xEAFF)
decode_dram_index(input())

# You can also manually input other values for testing
# val = input("Please enter DRAM Hex address: ")
# decode_dram_index(val)