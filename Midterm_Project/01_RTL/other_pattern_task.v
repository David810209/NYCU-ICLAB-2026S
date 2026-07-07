task gen_dram_files_task_all; begin
    integer fd_i1, fd_i2, fd_d;
    integer i, ic_count;

    reg [15:0] tmp_inst1 [0:INST_DEPTH-1];
    reg [15:0] tmp_inst2 [0:INST_DEPTH-1];

    // BYTE-ADDRESSABLE data memory
    reg [7:0]  tmp_data_init [0:DATA_TOP];
    reg [7:0]  tmp_data_live [0:DATA_TOP];

    reg signed [15:0] sim_reg_c1 [0:7];
    reg signed [15:0] sim_reg_c2 [0:7];

    reg signed [15:0] rs_val_c1 [0:INST_DEPTH-1];
    reg signed [15:0] rs_val_c2 [0:INST_DEPTH-1];

    reg [15:0] NOP;
    reg [15:0] w_tmp;
    integer pc1, pc2;

    NOP = 16'h0000;

    // ------------------------------------------------------------
    // Initialize
    // ------------------------------------------------------------
    for (i = 0; i < 8; i = i + 1) begin
        sim_reg_c1[i] = 16'h0;
        sim_reg_c2[i] = 16'h0;
    end

    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        tmp_inst1[i] = NOP;
        tmp_inst2[i] = NOP;
        rs_val_c1[i] = 0;
        rs_val_c2[i] = 0;
    end

    for (i = 0; i <= DATA_TOP; i = i + 1)
        tmp_data_init[i] = 8'h0;

    for (i = DATA_ACC_LO; i <= DATA_ACC_HI + 1; i = i + 1)
        tmp_data_init[i] = $urandom_range(255, 0);

    // Seed known 16-bit words
    `define SEED_WORD(BA, VAL) \
    begin \
        tmp_data_init[(BA)]   = ((VAL)      & 16'h00FF); \
        tmp_data_init[(BA)+1] = (((VAL)>>8) & 16'h00FF); \
    end

    // -------- Low region 0x1000 ~ 0x15FE --------
    `SEED_WORD(16'h1000, 16'hA5A5)
    `SEED_WORD(16'h1002, 16'h5A5A)
    `SEED_WORD(16'h1004, 16'hCCCC)
    `SEED_WORD(16'h1006, 16'hDDDD)
    `SEED_WORD(16'h1010, 16'h1111)
    `SEED_WORD(16'h1020, 16'h2222)
    `SEED_WORD(16'h1040, 16'h4444)
    `SEED_WORD(16'h1060, 16'h6666)
    `SEED_WORD(16'h107E, 16'h7E7E)
    `SEED_WORD(16'h1080, 16'h8080)
    `SEED_WORD(16'h10FE, 16'hFEFE)
    `SEED_WORD(16'h1100, 16'hB100)
    `SEED_WORD(16'h1180, 16'hB180)
    `SEED_WORD(16'h11FE, 16'hFE11)
    `SEED_WORD(16'h1200, 16'hB200)
    `SEED_WORD(16'h1280, 16'hB280)
    `SEED_WORD(16'h12FE, 16'hFE22)
    `SEED_WORD(16'h1300, 16'hB300)
    `SEED_WORD(16'h1380, 16'hB380)
    `SEED_WORD(16'h13FE, 16'hFE33)
    `SEED_WORD(16'h1400, 16'hB400)
    `SEED_WORD(16'h1480, 16'hB480)
    `SEED_WORD(16'h14FE, 16'hFE44)
    `SEED_WORD(16'h1500, 16'hB500)
    `SEED_WORD(16'h1580, 16'hB580)
    `SEED_WORD(16'h15FE, 16'hFE55)

    // -------- Mid region 0x1600 ~ 0x1FFE --------
    `SEED_WORD(16'h1600, 16'hC600)
    `SEED_WORD(16'h1680, 16'hC680)
    `SEED_WORD(16'h16FE, 16'hFE66)
    `SEED_WORD(16'h1700, 16'hC700)
    `SEED_WORD(16'h1780, 16'hC780)
    `SEED_WORD(16'h17FE, 16'hFE77)
    `SEED_WORD(16'h1800, 16'hC800)
    `SEED_WORD(16'h1880, 16'hC880)
    `SEED_WORD(16'h18FE, 16'hFE88)
    `SEED_WORD(16'h1900, 16'hC900)
    `SEED_WORD(16'h1980, 16'hC980)
    `SEED_WORD(16'h19FE, 16'hFE99)
    `SEED_WORD(16'h1A00, 16'hCA00)
    `SEED_WORD(16'h1A80, 16'hCA80)
    `SEED_WORD(16'h1AFE, 16'hFEAA)
    `SEED_WORD(16'h1B00, 16'hCB00)
    `SEED_WORD(16'h1B80, 16'hCB80)
    `SEED_WORD(16'h1BFE, 16'hFEBB)
    `SEED_WORD(16'h1C00, 16'hCC00)
    `SEED_WORD(16'h1CFE, 16'hFECC)
    `SEED_WORD(16'h1D00, 16'hCD00)
    `SEED_WORD(16'h1DFE, 16'hFEDD)
    `SEED_WORD(16'h1E00, 16'hCE00)
    `SEED_WORD(16'h1EFE, 16'hFEEE)
    `SEED_WORD(16'h1F00, 16'hCF00)
    `SEED_WORD(16'h1FFE, 16'hFEFF)

    // -------- High region 0x2000 ~ 0x2FFE --------
    `SEED_WORD(16'h2000, 16'hD000)
    `SEED_WORD(16'h2080, 16'hD080)
    `SEED_WORD(16'h20FE, 16'hFE00)
    `SEED_WORD(16'h2100, 16'hD100)
    `SEED_WORD(16'h2180, 16'hD180)
    `SEED_WORD(16'h21FE, 16'hFE10)
    `SEED_WORD(16'h2200, 16'hD200)
    `SEED_WORD(16'h2280, 16'hD280)
    `SEED_WORD(16'h22FE, 16'hFE20)
    `SEED_WORD(16'h2300, 16'hD300)
    `SEED_WORD(16'h2380, 16'hD380)
    `SEED_WORD(16'h23FE, 16'hFE30)
    `SEED_WORD(16'h2400, 16'hD400)
    `SEED_WORD(16'h2480, 16'hD480)
    `SEED_WORD(16'h24FE, 16'hFE40)
    `SEED_WORD(16'h2500, 16'hD500)
    `SEED_WORD(16'h2580, 16'hD580)
    `SEED_WORD(16'h25FE, 16'hFE50)
    `SEED_WORD(16'h2600, 16'hD600)
    `SEED_WORD(16'h2680, 16'hD680)
    `SEED_WORD(16'h26FE, 16'hFE60)
    `SEED_WORD(16'h2700, 16'hD700)
    `SEED_WORD(16'h2780, 16'hD780)
    `SEED_WORD(16'h27FE, 16'hFE70)
    `SEED_WORD(16'h2800, 16'hD800)
    `SEED_WORD(16'h2880, 16'hD880)
    `SEED_WORD(16'h28FE, 16'hFE80)
    `SEED_WORD(16'h2900, 16'hD900)
    `SEED_WORD(16'h2980, 16'hD980)
    `SEED_WORD(16'h29FE, 16'hFE90)
    `SEED_WORD(16'h2A00, 16'hDA00)
    `SEED_WORD(16'h2A80, 16'hDA80)
    `SEED_WORD(16'h2AFE, 16'hFEA0)
    `SEED_WORD(16'h2B00, 16'hDB00)
    `SEED_WORD(16'h2B80, 16'hDB80)
    `SEED_WORD(16'h2BFE, 16'hFEB0)
    `SEED_WORD(16'h2C00, 16'hDC00)
    `SEED_WORD(16'h2C80, 16'hDC80)
    `SEED_WORD(16'h2CFE, 16'hFEC0)
    `SEED_WORD(16'h2D00, 16'hDD00)
    `SEED_WORD(16'h2D80, 16'hDD80)
    `SEED_WORD(16'h2DFE, 16'hFED0)
    `SEED_WORD(16'h2E00, 16'hDE00)
    `SEED_WORD(16'h2E80, 16'hDE80)
    `SEED_WORD(16'h2EFE, 16'hFEE0)
    `SEED_WORD(16'h2F00, 16'hDF00)
    `SEED_WORD(16'h2F80, 16'hDF80)
    `SEED_WORD(16'h2FFE, 16'hFEF0)

    `undef SEED_WORD

    for (i = 0; i <= DATA_TOP; i = i + 1)
        tmp_data_live[i] = tmp_data_init[i];

    pc1      = 0;
    pc2      = 0;
    ic_count = 0;

    // ============================================================
    // ============================================================
    // PART 1: BASIC TEST
    // ============================================================
    // ============================================================

    // ADDI init (basic): reg1=1..reg7=7 for BOTH cores
    begin : init_regs_basic
        integer ri;
        for (ri = 1; ri <= 7; ri = ri + 1) begin
            tmp_inst1[pc1] = {3'b010, 3'd0, ri[2:0], ri[6:0]};
            tmp_inst2[pc2] = {3'b010, 3'd0, ri[2:0], ri[6:0]};
            sim_reg_c1[ri] = ri;
            sim_reg_c2[ri] = ri;
            pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
        end
    end

    // 11 inst * 18 repeats = 198
    repeat (18) begin
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] & sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] & sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] | sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] | sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] & sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] & sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] | sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] | sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] ^ sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] ^ sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        sim_reg_c1[3] = ($signed(sim_reg_c1[1]) < $signed(sim_reg_c1[2])) ? 16'h0001 : 16'h0000;
        sim_reg_c2[3] = ($signed(sim_reg_c2[1]) < $signed(sim_reg_c2[2])) ? 16'h0001 : 16'h0000;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        tmp_inst2[pc2] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        begin
            reg [31:0] prod1, prod2;
            prod1 = sim_reg_c1[1] * sim_reg_c1[2];
            prod2 = sim_reg_c2[1] * sim_reg_c2[2];
            sim_reg_c1[3] = prod1[31:16];
            sim_reg_c1[4] = prod1[15:0];
            sim_reg_c2[3] = prod2[31:16];
            sim_reg_c2[4] = prod2[15:0];
        end
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b010, 3'd1, 3'd5, 7'd5};
        tmp_inst2[pc2] = {3'b010, 3'd1, 3'd5, 7'd5};
        sim_reg_c1[5] = sim_reg_c1[1] + 16'sd5;
        sim_reg_c2[5] = sim_reg_c2[1] + 16'sd5;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b011, 3'd1, 3'd6, 7'd3};
        tmp_inst2[pc2] = {3'b011, 3'd1, 3'd6, 7'd3};
        sim_reg_c1[6] = sim_reg_c1[1] - 16'sd3;
        sim_reg_c2[6] = sim_reg_c2[1] - 16'sd3;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
    end
    // End of basic test: pc1 = pc2 = 205

    // ============================================================
    // ============================================================
    // PART 2: MEMORY TEST
    // ============================================================
    // ============================================================

    begin : init_regs_mem
        integer ri;
        integer ri2;
        for (ri = 1; ri <= 7; ri = ri + 1) begin
            ri2 = ri + 1;
            tmp_inst1[pc1] = {3'b010, 3'd0, ri[2:0],  ri[6:0]};
            tmp_inst2[pc2] = {3'b010, 3'd0, ri[2:0], ri2[6:0]};
            sim_reg_c1[ri] = ri;
            sim_reg_c2[ri] = ri2;
            pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
        end
    end

    begin : main_loop
        integer iter;
        integer addr_A, addr_B;
        integer baddr_A, baddr_B;

        for (iter = 0; iter < 10; iter = iter + 1) begin

        case (iter)
            0: begin addr_A = 0;   addr_B = 1;   end
            1: begin addr_A = 2;   addr_B = 3;   end
            2: begin addr_A = 8;   addr_B = 9;   end
            3: begin addr_A = 16;  addr_B = 17;  end
            4: begin addr_A = 24;  addr_B = 25;  end
            5: begin addr_A = 32;  addr_B = 33;  end
            6: begin addr_A = 40;  addr_B = 48;  end
            7: begin addr_A = 50;  addr_B = 56;  end
            8: begin addr_A = 60;  addr_B = 62;  end
            9: begin addr_A = 63;  addr_B = 2;   end
            default: begin addr_A = 0; addr_B = 1; end
        endcase
        baddr_A = 16'h1000 + (addr_A << 1);
        baddr_B = 16'h1000 + (addr_B << 1);

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] & sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] & sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] | sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] | sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] & sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] & sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] | sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] | sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] ^ sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] ^ sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        sim_reg_c1[3] = ($signed(sim_reg_c1[1]) < $signed(sim_reg_c1[2])) ? 16'h0001 : 16'h0000;
        sim_reg_c2[3] = ($signed(sim_reg_c2[1]) < $signed(sim_reg_c2[2])) ? 16'h0001 : 16'h0000;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        tmp_inst2[pc2] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        begin
            reg [31:0] prod1, prod2;
            prod1 = sim_reg_c1[1] * sim_reg_c1[2];
            prod2 = sim_reg_c2[1] * sim_reg_c2[2];
            sim_reg_c1[3] = prod1[31:16];
            sim_reg_c1[4] = prod1[15:0];
            sim_reg_c2[3] = prod2[31:16];
            sim_reg_c2[4] = prod2[15:0];
        end
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b010, 3'd1, 3'd5, 7'd5};
        tmp_inst2[pc2] = {3'b010, 3'd1, 3'd5, 7'd5};
        sim_reg_c1[5] = sim_reg_c1[1] + 16'sd5;
        sim_reg_c2[5] = sim_reg_c2[1] + 16'sd5;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b011, 3'd1, 3'd6, 7'd3};
        tmp_inst2[pc2] = {3'b011, 3'd1, 3'd6, 7'd3};
        sim_reg_c1[6] = sim_reg_c1[1] - 16'sd3;
        sim_reg_c2[6] = sim_reg_c2[1] - 16'sd3;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // LS sub-sequence
        tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, addr_A[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = NOP;
        sim_reg_c1[7] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = NOP;
        tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, addr_A[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        sim_reg_c2[7] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b100, 3'd0, 3'd6, addr_A[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = {3'b100, 3'd0, 3'd6, addr_B[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        sim_reg_c1[6] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        sim_reg_c2[6] = {tmp_data_live[baddr_B+1], tmp_data_live[baddr_B]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = NOP;
        tmp_inst2[pc2] = {3'b101, 3'd0, 3'd5, addr_A[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        w_tmp = sim_reg_c2[5];
        tmp_data_live[baddr_A]   = w_tmp[7:0];
        tmp_data_live[baddr_A+1] = w_tmp[15:8];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b101, 3'd0, 3'd5, addr_B[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = NOP;
        w_tmp = sim_reg_c1[5];
        tmp_data_live[baddr_B]   = w_tmp[7:0];
        tmp_data_live[baddr_B+1] = w_tmp[15:8];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, addr_A[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = {3'b101, 3'd0, 3'd6, addr_A[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        w_tmp = sim_reg_c2[6];
        tmp_data_live[baddr_A]   = w_tmp[7:0];
        tmp_data_live[baddr_A+1] = w_tmp[15:8];
        sim_reg_c1[7] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b101, 3'd0, 3'd6, addr_B[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, addr_B[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        sim_reg_c2[7] = {tmp_data_live[baddr_B+1], tmp_data_live[baddr_B]};
        w_tmp = sim_reg_c1[6];
        tmp_data_live[baddr_B]   = w_tmp[7:0];
        tmp_data_live[baddr_B+1] = w_tmp[15:8];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
        end // for iter
    end

    repeat(12) begin
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
    end

    tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
    tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
    sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
    sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

    begin : extra_ls
        integer grp;
        integer base_c1, base_c2;

        for (grp = 0; grp < 25; grp = grp + 1) begin
            case (grp)
                0:  begin base_c1 = 0;    base_c2 = 2048; end
                1:  begin base_c1 = 160;  base_c2 = 2208; end
                2:  begin base_c1 = 320;  base_c2 = 2368; end
                3:  begin base_c1 = 480;  base_c2 = 2528; end
                4:  begin base_c1 = 640;  base_c2 = 2688; end
                5:  begin base_c1 = 800;  base_c2 = 2848; end
                6:  begin base_c1 = 960;  base_c2 = 3008; end
                7:  begin base_c1 = 1120; base_c2 = 3168; end
                8:  begin base_c1 = 1280; base_c2 = 3328; end
                9:  begin base_c1 = 1440; base_c2 = 3488; end
                10: begin base_c1 = 1600; base_c2 = 3648; end
                11: begin base_c1 = 1760; base_c2 = 3808; end
                12: begin base_c1 = 1920; base_c2 = 3968; end
                13: begin base_c1 = 2048; base_c2 = 2176; end
                14: begin base_c1 = 2208; base_c2 = 2336; end
                15: begin base_c1 = 2368; base_c2 = 2496; end
                16: begin base_c1 = 2528; base_c2 = 2656; end
                17: begin base_c1 = 2688; base_c2 = 2816; end
                18: begin base_c1 = 2848; base_c2 = 2976; end
                19: begin base_c1 = 3008; base_c2 = 3136; end
                20: begin base_c1 = 3168; base_c2 = 3296; end
                21: begin base_c1 = 3328; base_c2 = 3456; end
                22: begin base_c1 = 3488; base_c2 = 3616; end
                23: begin base_c1 = 3648; base_c2 = 3776; end
                24: begin base_c1 = 3808; base_c2 = 3936; end
                default: begin base_c1 = 0; base_c2 = 0; end
            endcase

            begin : build_bases
                integer acc1, acc2;
                integer chunk1, chunk2;
                integer first1, first2;
                integer done1, done2;

                acc1 = 0; acc2 = 0;
                first1 = 1; first2 = 1;
                done1 = 0; done2 = 0;

                while (!(done1 && done2)) begin
                    if (!done1) begin
                        chunk1 = base_c1 - acc1;
                        if (chunk1 > 63) chunk1 = 63;
                        if (first1) begin
                            tmp_inst1[pc1] = {3'b010, 3'd0, 3'd1, chunk1[6:0]};
                            sim_reg_c1[1] = chunk1;
                            first1 = 0;
                        end else begin
                            tmp_inst1[pc1] = {3'b010, 3'd1, 3'd1, chunk1[6:0]};
                            sim_reg_c1[1] = sim_reg_c1[1] + chunk1;
                        end
                        acc1 = acc1 + chunk1;
                        if (acc1 >= base_c1) done1 = 1;
                    end else begin
                        tmp_inst1[pc1] = {3'b010, 3'd1, 3'd1, 7'd0};
                    end

                    if (!done2) begin
                        chunk2 = base_c2 - acc2;
                        if (chunk2 > 63) chunk2 = 63;
                        if (first2) begin
                            tmp_inst2[pc2] = {3'b010, 3'd0, 3'd1, chunk2[6:0]};
                            sim_reg_c2[1] = chunk2;
                            first2 = 0;
                        end else begin
                            tmp_inst2[pc2] = {3'b010, 3'd1, 3'd1, chunk2[6:0]};
                            sim_reg_c2[1] = sim_reg_c2[1] + chunk2;
                        end
                        acc2 = acc2 + chunk2;
                        if (acc2 >= base_c2) done2 = 1;
                    end else begin
                        tmp_inst2[pc2] = {3'b010, 3'd1, 3'd1, 7'd0};
                    end

                    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
                end
            end

            begin : do_ls
                integer k;
                integer imm_k;
                integer c1_is_st, c2_is_st;
                integer eff1_byte, eff2_byte;

                for (k = 0; k < 10; k = k + 1) begin
                    case (k)
                        0: imm_k = 0;
                        1: imm_k = 3;
                        2: imm_k = 7;
                        3: imm_k = 15;
                        4: imm_k = 31;
                        5: imm_k = 60;
                        6: imm_k = 5;
                        7: imm_k = 20;
                        8: imm_k = 40;
                        9: imm_k = 55;
                        default: imm_k = 0;
                    endcase

                    case (k)
                        0: begin c1_is_st = 0; c2_is_st = 1; end
                        1: begin c1_is_st = 1; c2_is_st = 0; end
                        2: begin c1_is_st = 0; c2_is_st = 0; end
                        3: begin c1_is_st = 1; c2_is_st = 0; end
                        4: begin c1_is_st = 0; c2_is_st = 1; end
                        5: begin c1_is_st = 1; c2_is_st = 0; end
                        6: begin c1_is_st = 0; c2_is_st = 0; end
                        7: begin c1_is_st = 0; c2_is_st = 1; end
                        8: begin c1_is_st = 1; c2_is_st = 0; end
                        9: begin c1_is_st = 0; c2_is_st = 0; end
                        default: begin c1_is_st = 0; c2_is_st = 0; end
                    endcase

                    eff1_byte = 16'h1000 + ((sim_reg_c1[1] + imm_k) << 1);
                    eff2_byte = 16'h1000 + ((sim_reg_c2[1] + imm_k) << 1);

                    if (c1_is_st) begin
                        tmp_inst1[pc1] = {3'b101, 3'd1, 3'd5, imm_k[6:0]};
                        rs_val_c1[pc1] = sim_reg_c1[1];
                        w_tmp = sim_reg_c1[5];
                        tmp_data_live[eff1_byte]   = w_tmp[7:0];
                        tmp_data_live[eff1_byte+1] = w_tmp[15:8];
                    end else begin
                        tmp_inst1[pc1] = {3'b100, 3'd1, 3'd7, imm_k[6:0]};
                        rs_val_c1[pc1] = sim_reg_c1[1];
                        sim_reg_c1[7] = {tmp_data_live[eff1_byte+1], tmp_data_live[eff1_byte]};
                    end

                    if (c2_is_st) begin
                        tmp_inst2[pc2] = {3'b101, 3'd1, 3'd5, imm_k[6:0]};
                        rs_val_c2[pc2] = sim_reg_c2[1];
                        w_tmp = sim_reg_c2[5];
                        tmp_data_live[eff2_byte]   = w_tmp[7:0];
                        tmp_data_live[eff2_byte+1] = w_tmp[15:8];
                    end else begin
                        tmp_inst2[pc2] = {3'b100, 3'd1, 3'd7, imm_k[6:0]};
                        rs_val_c2[pc2] = sim_reg_c2[1];
                        sim_reg_c2[7] = {tmp_data_live[eff2_byte+1], tmp_data_live[eff2_byte]};
                    end

                    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
                end
            end
        end
    end
    // End of memory test: pc1 = pc2 = 1870 (word idx)

    // ============================================================
    // ============================================================
    // PART 3: BRANCH / JUMP TEST
    //
    // ALIGNMENT RULE: PC is a BYTE address. Every instruction is
    // 2 bytes, so every legal PC is EVEN. All branch targets and
    // jump targets must be 2-byte-aligned (even).
    //
    // ENCODINGS:
    //   BEQ  110 rs(3) rt(3) imm(7 signed)
    //        if (rs==rt) next_pc = pc + 2 + imm   (byte)
    //        else        next_pc = pc + 2
    //        -> imm MUST BE EVEN so that target stays 2-aligned.
    //
    //   J    111 address(13)
    //        next_pc byte = {3'b0, address[12:0]}
    //        i.e. the 13-bit address field IS the low 13 bits of
    //        the target BYTE address (LSB must be 0 -> even).
    //        Range (per problem spec): target within ±256 bytes of
    //        current pc  -> |next_pc_byte - current_pc_byte| <= 256.
    //
    // TEST PLAN:
    //   1) BEQ taken  (r0==r0, imm=0). imm=0 is even.
    //      taken target == fall-through, exercises taken datapath.
    //   2) BEQ not-taken (r1!=r2, imm=+4). imm=+4 is even.
    //      branch fails -> fall through.
    //   3) Jump chain: each jump hops +256 bytes (= +128 word slots);
    //      NOPs fill the skipped slots. Last hop is shorter to land
    //      exactly on target byte = 0x1FFE (word index 4095).
    //   4) Instruction at target word (byte 0x1FFE) = NOP. Sim ends.
    // ============================================================
    // ============================================================

    begin : branch_jump_test
        integer pc_cur_word;
        integer target_word;
        integer hop_word;
        integer next_pc_word;
        integer gap_word;
        integer f;
        reg [15:0] cur_byte, tgt_byte;
        reg [12:0] jaddr_field;

        if (pc1 != pc2) begin
            $display("ERROR: pc1(%0d) != pc2(%0d) before branch/jump test", pc1, pc2);
        end

        target_word = 16'h1FFE >> 1;   // = 4095

        // --------------------------------------------------------
        // Step 1: BEQ TAKEN -- r0==r0, imm=0 (even, 2-aligned delta).
        //   Target byte = (pc_cur<<1) + 2 + 0 = (pc_cur+1)<<1 = even.
        // --------------------------------------------------------
        tmp_inst1[pc1] = {3'b110, 3'd0, 3'd0, 7'd0};
        tmp_inst2[pc2] = {3'b110, 3'd0, 3'd0, 7'd0};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // --------------------------------------------------------
        // Step 2: BEQ NOT-TAKEN -- r1(=1) != r2(=2), imm=+4 (even).
        //   Branch fails -> fall through to pc+2.
        //   Even imm ensures alignment in case the branch WERE taken.
        // --------------------------------------------------------
        tmp_inst1[pc1] = {3'b110, 3'd1, 3'd2, 7'd4};
        tmp_inst2[pc2] = {3'b110, 3'd1, 3'd2, 7'd4};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // --------------------------------------------------------
        // Step 3: Jump chain. Each hop = +128 word slots (= +256 bytes).
        //   Jump address field = target BYTE addr (low 13 bits).
        //   target_byte = next_pc_word << 1  (always even).
        // --------------------------------------------------------
        pc_cur_word = pc1;

        while (pc_cur_word < target_word) begin
            gap_word = target_word - pc_cur_word;
            if (gap_word > 128) hop_word = 128;   // 128 word = 256 byte
            else                hop_word = gap_word;

            next_pc_word = pc_cur_word + hop_word;

            cur_byte    = pc_cur_word  << 1;
            tgt_byte    = next_pc_word << 1;
            jaddr_field = tgt_byte[12:0];   // low 13 bits of BYTE addr

            // Sanity: target byte must be 2-aligned
            if (tgt_byte[0] != 1'b0) begin
                $display("ERROR: jump target byte 0x%04h at pc 0x%04h not 2-aligned",
                         tgt_byte, cur_byte);
            end
            // Sanity: range must be <= 256 bytes
            if ((tgt_byte - cur_byte) > 16'd256) begin
                $display("ERROR: jump delta %0d > 256 bytes (pc=0x%04h tgt=0x%04h)",
                         (tgt_byte - cur_byte), cur_byte, tgt_byte);
            end

            // Encode jump: opcode(111) + 13-bit target byte addr
            tmp_inst1[pc_cur_word] = {3'b111, jaddr_field};
            tmp_inst2[pc_cur_word] = {3'b111, jaddr_field};
            ic_count = ic_count + 1;

            // NOP-fill skipped slots (never executed, for cleanliness)
            for (f = pc_cur_word + 1; f < next_pc_word; f = f + 1) begin
                tmp_inst1[f] = NOP;
                tmp_inst2[f] = NOP;
            end

            pc_cur_word = next_pc_word;
        end

        // Landing slot at target_word (byte 0x1FFE) stays NOP --
        // simulation halts here.
        tmp_inst1[target_word] = NOP;
        tmp_inst2[target_word] = NOP;

        pc1 = target_word + 1;
        pc2 = target_word + 1;
    end

    $display("%0s[task_full] %0d instructions generated (rest NOP)%0s",
             txt_cyan_prefix, ic_count, reset_color);

    // ============================================================
    // Write inst_1_dram_file.dat
    // ============================================================
    fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        reg [2:0]         cop, crs, crt, crd, crl, csub;
        reg signed [6:0]  cimm;
        reg        [12:0] cjaddr;
        reg        [31:0] eff_byte_addr;

        $fwrite(fd_i1, "@%04h\n", (i << 1));

        cop    = tmp_inst1[i][15:13];
        crs    = tmp_inst1[i][12:10];
        crt    = tmp_inst1[i][9:7];
        crd    = tmp_inst1[i][6:4];
        crl    = tmp_inst1[i][3:1];
        csub   = tmp_inst1[i][3:1];
        cimm   = tmp_inst1[i][6:0];
        cjaddr = tmp_inst1[i][12:0];

        eff_byte_addr = DATA_BASE + ((rs_val_c1[i] + $signed(cimm)) << 1);

        if (tmp_inst1[i] == NOP) begin
            $fwrite(fd_i1, "%02h %02h // %d:NOP\n", tmp_inst1[i][15:8], tmp_inst1[i][7:0], i);
        end else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i1, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b001: $fwrite(fd_i1, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b010: $fwrite(fd_i1, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b011: $fwrite(fd_i1, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b100: $fwrite(fd_i1, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b101: $fwrite(fd_i1, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b110: $fwrite(fd_i1, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b111: $fwrite(fd_i1, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",  tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                    endcase
                end
                3'b001: $fwrite(fd_i1, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crl, crs, crt);
                3'b010: $fwrite(fd_i1, "%02h %02h // %d:ADDI r%0d = r%0d + %0d\n",          tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
                3'b011: $fwrite(fd_i1, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",          tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
                3'b100: $fwrite(fd_i1, "%02h %02h // %d:LOAD  r%0d <- DM[0x%04h] rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, eff_byte_addr[15:0], crs, rs_val_c1[i], $signed(cimm));
                3'b101: $fwrite(fd_i1, "%02h %02h // %d:STORE DM[0x%04h] <- r%0d rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, eff_byte_addr[15:0], crt, crs, rs_val_c1[i], $signed(cimm));
                3'b110: $fwrite(fd_i1, "%02h %02h // %d:BEQ  if(r%0d==r%0d) pc+=2+%0d (target byte 0x%04h)\n",
                                 tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crs, crt, $signed(cimm), ((i<<1) + 2 + $signed(cimm)));
                3'b111: $fwrite(fd_i1, "%02h %02h // %d:JUMP -> byte 0x%04h\n",
                                 tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, {3'b0, cjaddr});
                default: $fwrite(fd_i1, "%02h %02h // %d:UNKNOWN\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i);
            endcase
        end
    end
    $fclose(fd_i1);

    // ============================================================
    // Write inst_2_dram_file.dat
    // ============================================================
    fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        reg [2:0]         cop, crs, crt, crd, crl, csub;
        reg signed [6:0]  cimm;
        reg        [12:0] cjaddr;
        reg        [31:0] eff_byte_addr;

        $fwrite(fd_i2, "@%04h\n", (i << 1));

        cop    = tmp_inst2[i][15:13];
        crs    = tmp_inst2[i][12:10];
        crt    = tmp_inst2[i][9:7];
        crd    = tmp_inst2[i][6:4];
        crl    = tmp_inst2[i][3:1];
        csub   = tmp_inst2[i][3:1];
        cimm   = tmp_inst2[i][6:0];
        cjaddr = tmp_inst2[i][12:0];

        eff_byte_addr = DATA_BASE + ((rs_val_c2[i] + $signed(cimm)) << 1);

        if (tmp_inst2[i] == NOP) begin
            $fwrite(fd_i2, "%02h %02h // %d:NOP\n", tmp_inst2[i][15:8], tmp_inst2[i][7:0], i);
        end else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i2, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b001: $fwrite(fd_i2, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b010: $fwrite(fd_i2, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b011: $fwrite(fd_i2, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b100: $fwrite(fd_i2, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b101: $fwrite(fd_i2, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b110: $fwrite(fd_i2, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b111: $fwrite(fd_i2, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",  tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                    endcase
                end
                3'b001: $fwrite(fd_i2, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crl, crs, crt);
                3'b010: $fwrite(fd_i2, "%02h %02h // %d:ADDI r%0d = r%0d + %0d\n",          tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
                3'b011: $fwrite(fd_i2, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",          tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
                3'b100: $fwrite(fd_i2, "%02h %02h // %d:LOAD  r%0d <- DM[0x%04h] rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, eff_byte_addr[15:0], crs, rs_val_c2[i], $signed(cimm));
                3'b101: $fwrite(fd_i2, "%02h %02h // %d:STORE DM[0x%04h] <- r%0d rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, eff_byte_addr[15:0], crt, crs, rs_val_c2[i], $signed(cimm));
                3'b110: $fwrite(fd_i2, "%02h %02h // %d:BEQ  if(r%0d==r%0d) pc+=2+%0d (target byte 0x%04h)\n",
                                 tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crs, crt, $signed(cimm), ((i<<1) + 2 + $signed(cimm)));
                3'b111: $fwrite(fd_i2, "%02h %02h // %d:JUMP -> byte 0x%04h\n",
                                 tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, {3'b0, cjaddr});
                default: $fwrite(fd_i2, "%02h %02h // %d:UNKNOWN\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i);
            endcase
        end
    end
    $fclose(fd_i2);

    // ============================================================
    // Write shared data_dram_file.dat (INITIAL state)
    // ============================================================
    fd_d = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
    for (i = DATA_ACC_LO; i <= DATA_ACC_HI; i = i + 2) begin
        $fwrite(fd_d, "@%04h\n", i);
        $fwrite(fd_d, "%02h %02h // DATA[%04h] = %0d\n",
                tmp_data_init[i],
                tmp_data_init[i+1],
                i,
                {tmp_data_init[i+1], tmp_data_init[i]});
    end
    $fclose(fd_d);
    $display("%0s[task_full] .dat files written%0s", txt_cyan_prefix, reset_color);
end endtask

task gen_dram_files_task_basic; begin
    integer fd_i1, fd_i2;
    integer i, ic_count;

    reg [15:0] tmp_inst1 [0:INST_DEPTH-1];
    reg [15:0] tmp_inst2 [0:INST_DEPTH-1];

    reg signed [15:0] sim_reg_c1 [0:7];
    reg signed [15:0] sim_reg_c2 [0:7];

    reg [15:0] NOP;
    integer pc1, pc2;

    NOP = 16'h0000;

    // ------------------------------------------------------------
    // Initialize
    // ------------------------------------------------------------
    for (i = 0; i < 8; i = i + 1) begin
        sim_reg_c1[i] = 16'h0;
        sim_reg_c2[i] = 16'h0;
    end

    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        tmp_inst1[i] = NOP;
        tmp_inst2[i] = NOP;
    end

    pc1      = 0;
    pc2      = 0;
    ic_count = 0;

    // ============================================================
    // ADDI init: reg1=1, reg2=2, ..., reg7=7  (r_i = r0 + i)
    // ============================================================
    begin : init_regs
        integer ri;
        integer ri2;
        for (ri = 1; ri <= 7; ri = ri + 1) begin
            // ADDI rt = rs + imm  =>  {3'b010, rs(r0), rt(ri), imm(ri)}
            ri2 = ri + 1;
            tmp_inst1[pc1] = {3'b010, 3'd0, ri[2:0], ri[6:0]};
            tmp_inst2[pc2] = {3'b010, 3'd0, ri[2:0], ri2[6:0]};
            sim_reg_c1[ri] = ri;
            sim_reg_c2[ri] = ri;
            pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
        end
    end

    // ============================================================
    // 11 instructions x 18 repeats = 198, then 2 extra = 200 total
    // Remaining slots stay NOP.
    // ============================================================

    repeat (18) begin
        // @ +0 : ADD  r3 = r1 + r2
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +1 : SUB  r3 = r1 - r2
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +2 : AND  r3 = r1 & r2
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] & sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] & sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +3 : OR   r3 = r1 | r2
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] | sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] | sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +4 : NAND r3 = ~(r1 & r2)
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] & sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] & sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +5 : NOR  r3 = ~(r1 | r2)
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] | sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] | sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +6 : XOR  r3 = r1 ^ r2
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] ^ sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] ^ sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +7 : SLT  r3 = (r1 < r2)
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        sim_reg_c1[3] = ($signed(sim_reg_c1[1]) < $signed(sim_reg_c1[2])) ? 16'h0001 : 16'h0000;
        sim_reg_c2[3] = ($signed(sim_reg_c2[1]) < $signed(sim_reg_c2[2])) ? 16'h0001 : 16'h0000;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +8 : MULT {r3,r4} = r1 * r2
        tmp_inst1[pc1] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        tmp_inst2[pc2] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        begin
            reg [31:0] prod1, prod2;
            prod1 = sim_reg_c1[1] * sim_reg_c1[2];
            prod2 = sim_reg_c2[1] * sim_reg_c2[2];
            sim_reg_c1[3] = prod1[31:16];
            sim_reg_c1[4] = prod1[15:0];
            sim_reg_c2[3] = prod2[31:16];
            sim_reg_c2[4] = prod2[15:0];
        end
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +9 : ADDI r5 = r1 + 5
        tmp_inst1[pc1] = {3'b010, 3'd1, 3'd5, 7'd5};
        tmp_inst2[pc2] = {3'b010, 3'd1, 3'd5, 7'd5};
        sim_reg_c1[5] = sim_reg_c1[1] + 16'sd5;
        sim_reg_c2[5] = sim_reg_c2[1] + 16'sd5;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // @ +10 : SUBI r6 = r1 - 3
        tmp_inst1[pc1] = {3'b011, 3'd1, 3'd6, 7'd3};
        tmp_inst2[pc2] = {3'b011, 3'd1, 3'd6, 7'd3};
        sim_reg_c1[6] = sim_reg_c1[1] - 16'sd3;
        sim_reg_c2[6] = sim_reg_c2[1] - 16'sd3;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
    end

    // 2 extra instructions to reach exactly 200
    // @ +198 : ADD  r3 = r1 + r2
    tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
    tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
    sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
    sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

    // @ +199 : SUB  r3 = r1 - r2
    tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
    tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
    sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
    sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

    $display("%0s[task_basic] %0d instructions generated (rest NOP)%0s",
             txt_cyan_prefix, ic_count, reset_color);

    // ============================================================
    // Write inst_1_dram_file.dat
    // ============================================================
    fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        reg [2:0]        cop, crs, crt, crd, crl, csub;
        reg signed [6:0] cimm;

        $fwrite(fd_i1, "@%04h\n", (i << 1));

        cop  = tmp_inst1[i][15:13];
        crs  = tmp_inst1[i][12:10];
        crt  = tmp_inst1[i][9:7];
        crd  = tmp_inst1[i][6:4];
        crl  = tmp_inst1[i][3:1];
        csub = tmp_inst1[i][3:1];
        cimm = tmp_inst1[i][6:0];

        if (tmp_inst1[i] == NOP) begin
            $fwrite(fd_i1, "%02h %02h // %d:NOP\n", tmp_inst1[i][15:8], tmp_inst1[i][7:0], i);
        end else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i1, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b001: $fwrite(fd_i1, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);  
                        3'b010: $fwrite(fd_i1, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b011: $fwrite(fd_i1, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b100: $fwrite(fd_i1, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b101: $fwrite(fd_i1, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b110: $fwrite(fd_i1, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i , crd, crs, crt);
                        3'b111: $fwrite(fd_i1, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",  tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                    endcase
                end
                3'b001: $fwrite(fd_i1, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crl, crs, crt);
                3'b010: $fwrite(fd_i1, "%02h %02h // %d:ADDI r%0d = r%0d + %0d\n",          tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
                3'b011: $fwrite(fd_i1, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",          tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
                default: $fwrite(fd_i1, "%02h %02h // %d:UNKNOWN\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i);
            endcase
        end
    end
    $fclose(fd_i1);

    // ============================================================
    // Write inst_2_dram_file.dat
    // ============================================================
    fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        reg [2:0]        cop, crs, crt, crd, crl, csub;
        reg signed [6:0] cimm;

        $fwrite(fd_i2, "@%04h\n", (i << 1));

        cop  = tmp_inst2[i][15:13];
        crs  = tmp_inst2[i][12:10];
        crt  = tmp_inst2[i][9:7];
        crd  = tmp_inst2[i][6:4];
        crl  = tmp_inst2[i][3:1];
        csub = tmp_inst2[i][3:1];
        cimm = tmp_inst2[i][6:0];

        if (tmp_inst2[i] == NOP) begin
            $fwrite(fd_i2, "%02h %02h // %d:NOP\n", tmp_inst2[i][15:8], tmp_inst2[i][7:0], i);
        end else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i2, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b001: $fwrite(fd_i2, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b010: $fwrite(fd_i2, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);  
                        3'b011: $fwrite(fd_i2, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b100: $fwrite(fd_i2, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b101: $fwrite(fd_i2, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b110: $fwrite(fd_i2, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b111: $fwrite(fd_i2, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",  tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                    endcase
                end
                    3'b001: $fwrite(fd_i2, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crl, crs, crt);
                3'b010: $fwrite(fd_i2, "%02h %02h // %d:ADDI r%0d = r%0d + %0d\n",          tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
                3'b011: $fwrite(fd_i2, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",          tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
                default: $fwrite(fd_i2, "%02h %02h // %d:UNKNOWN\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i);
            endcase
        end
    end
    $fclose(fd_i2);

    $display("%0s[task_basic] .dat files written%0s", txt_cyan_prefix, reset_color);
end endtask


// =============================================================
// Helper macros for word access to byte-addressable tmp_data_live
// and golden_data_DRAM.  A word at byte addr BA uses BA (low) and
// BA+1 (high).
// =============================================================
task gen_dram_files_task_memory; begin
    integer fd_i1, fd_i2, fd_d;
    integer i, ic_count;

    reg [15:0] tmp_inst1 [0:INST_DEPTH-1];
    reg [15:0] tmp_inst2 [0:INST_DEPTH-1];

    // BYTE-ADDRESSABLE. Seed once into _init, then copy to _live for
    // simulation reads/writes. _init is what gets written to .dat.
    reg [7:0]  tmp_data_init [0:DATA_TOP];
    reg [7:0]  tmp_data_live [0:DATA_TOP];

    reg signed [15:0] sim_reg_c1 [0:7];
    reg signed [15:0] sim_reg_c2 [0:7];

    reg signed [15:0] rs_val_c1 [0:INST_DEPTH-1];
    reg signed [15:0] rs_val_c2 [0:INST_DEPTH-1];

    reg [15:0] NOP;
    reg [15:0] w_tmp;   // scratch for packing word writes
    integer pc1, pc2;

    NOP = 16'h0000;

    // ------------------------------------------------------------
    // Initialize
    // ------------------------------------------------------------
    for (i = 0; i < 8; i = i + 1) begin
        sim_reg_c1[i] = 16'h0;
        sim_reg_c2[i] = 16'h0;
    end

    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        tmp_inst1[i] = NOP;
        tmp_inst2[i] = NOP;
        rs_val_c1[i] = 0;
        rs_val_c2[i] = 0;
    end

    // Zero the whole data memory first (byte-granularity).
    for (i = 0; i <= DATA_TOP; i = i + 1)
        tmp_data_init[i] = 8'h0;

    // Random-fill the accessible byte range [DATA_ACC_LO .. DATA_ACC_HI+1].
    for (i = DATA_ACC_LO; i <= DATA_ACC_HI + 1; i = i + 1)
        tmp_data_init[i] = $urandom_range(255, 0);

    // Seed known 16-bit words (little-endian: low byte at even addr).
    // word at byte-addr A holds value V:  init[A]=V[7:0]; init[A+1]=V[15:8]
    `define SEED_WORD(BA, VAL) \
    begin \
        tmp_data_init[(BA)]   = ((VAL)      & 16'h00FF); \
        tmp_data_init[(BA)+1] = (((VAL)>>8) & 16'h00FF); \
    end

    // -------- Low region 0x1000 ~ 0x15FE --------
    `SEED_WORD(16'h1000, 16'hA5A5)
    `SEED_WORD(16'h1002, 16'h5A5A)
    `SEED_WORD(16'h1004, 16'hCCCC)
    `SEED_WORD(16'h1006, 16'hDDDD)
    `SEED_WORD(16'h1010, 16'h1111)
    `SEED_WORD(16'h1020, 16'h2222)
    `SEED_WORD(16'h1040, 16'h4444)
    `SEED_WORD(16'h1060, 16'h6666)
    `SEED_WORD(16'h107E, 16'h7E7E)
    `SEED_WORD(16'h1080, 16'h8080)
    `SEED_WORD(16'h10FE, 16'hFEFE)
    `SEED_WORD(16'h1100, 16'hB100)
    `SEED_WORD(16'h1180, 16'hB180)
    `SEED_WORD(16'h11FE, 16'hFE11)
    `SEED_WORD(16'h1200, 16'hB200)
    `SEED_WORD(16'h1280, 16'hB280)
    `SEED_WORD(16'h12FE, 16'hFE22)
    `SEED_WORD(16'h1300, 16'hB300)
    `SEED_WORD(16'h1380, 16'hB380)
    `SEED_WORD(16'h13FE, 16'hFE33)
    `SEED_WORD(16'h1400, 16'hB400)
    `SEED_WORD(16'h1480, 16'hB480)
    `SEED_WORD(16'h14FE, 16'hFE44)
    `SEED_WORD(16'h1500, 16'hB500)
    `SEED_WORD(16'h1580, 16'hB580)
    `SEED_WORD(16'h15FE, 16'hFE55)

    // -------- Mid region 0x1600 ~ 0x1FFE --------
    `SEED_WORD(16'h1600, 16'hC600)
    `SEED_WORD(16'h1680, 16'hC680)
    `SEED_WORD(16'h16FE, 16'hFE66)
    `SEED_WORD(16'h1700, 16'hC700)
    `SEED_WORD(16'h1780, 16'hC780)
    `SEED_WORD(16'h17FE, 16'hFE77)
    `SEED_WORD(16'h1800, 16'hC800)
    `SEED_WORD(16'h1880, 16'hC880)
    `SEED_WORD(16'h18FE, 16'hFE88)
    `SEED_WORD(16'h1900, 16'hC900)
    `SEED_WORD(16'h1980, 16'hC980)
    `SEED_WORD(16'h19FE, 16'hFE99)
    `SEED_WORD(16'h1A00, 16'hCA00)
    `SEED_WORD(16'h1A80, 16'hCA80)
    `SEED_WORD(16'h1AFE, 16'hFEAA)
    `SEED_WORD(16'h1B00, 16'hCB00)
    `SEED_WORD(16'h1B80, 16'hCB80)
    `SEED_WORD(16'h1BFE, 16'hFEBB)
    `SEED_WORD(16'h1C00, 16'hCC00)
    `SEED_WORD(16'h1CFE, 16'hFECC)
    `SEED_WORD(16'h1D00, 16'hCD00)
    `SEED_WORD(16'h1DFE, 16'hFEDD)
    `SEED_WORD(16'h1E00, 16'hCE00)
    `SEED_WORD(16'h1EFE, 16'hFEEE)
    `SEED_WORD(16'h1F00, 16'hCF00)
    `SEED_WORD(16'h1FFE, 16'hFEFF)

    // -------- High region 0x2000 ~ 0x2FFE --------
    `SEED_WORD(16'h2000, 16'hD000)
    `SEED_WORD(16'h2080, 16'hD080)
    `SEED_WORD(16'h20FE, 16'hFE00)
    `SEED_WORD(16'h2100, 16'hD100)
    `SEED_WORD(16'h2180, 16'hD180)
    `SEED_WORD(16'h21FE, 16'hFE10)
    `SEED_WORD(16'h2200, 16'hD200)
    `SEED_WORD(16'h2280, 16'hD280)
    `SEED_WORD(16'h22FE, 16'hFE20)
    `SEED_WORD(16'h2300, 16'hD300)
    `SEED_WORD(16'h2380, 16'hD380)
    `SEED_WORD(16'h23FE, 16'hFE30)
    `SEED_WORD(16'h2400, 16'hD400)
    `SEED_WORD(16'h2480, 16'hD480)
    `SEED_WORD(16'h24FE, 16'hFE40)
    `SEED_WORD(16'h2500, 16'hD500)
    `SEED_WORD(16'h2580, 16'hD580)
    `SEED_WORD(16'h25FE, 16'hFE50)
    `SEED_WORD(16'h2600, 16'hD600)
    `SEED_WORD(16'h2680, 16'hD680)
    `SEED_WORD(16'h26FE, 16'hFE60)
    `SEED_WORD(16'h2700, 16'hD700)
    `SEED_WORD(16'h2780, 16'hD780)
    `SEED_WORD(16'h27FE, 16'hFE70)
    `SEED_WORD(16'h2800, 16'hD800)
    `SEED_WORD(16'h2880, 16'hD880)
    `SEED_WORD(16'h28FE, 16'hFE80)
    `SEED_WORD(16'h2900, 16'hD900)
    `SEED_WORD(16'h2980, 16'hD980)
    `SEED_WORD(16'h29FE, 16'hFE90)
    `SEED_WORD(16'h2A00, 16'hDA00)
    `SEED_WORD(16'h2A80, 16'hDA80)
    `SEED_WORD(16'h2AFE, 16'hFEA0)
    `SEED_WORD(16'h2B00, 16'hDB00)
    `SEED_WORD(16'h2B80, 16'hDB80)
    `SEED_WORD(16'h2BFE, 16'hFEB0)
    `SEED_WORD(16'h2C00, 16'hDC00)
    `SEED_WORD(16'h2C80, 16'hDC80)
    `SEED_WORD(16'h2CFE, 16'hFEC0)
    `SEED_WORD(16'h2D00, 16'hDD00)
    `SEED_WORD(16'h2D80, 16'hDD80)
    `SEED_WORD(16'h2DFE, 16'hFED0)
    `SEED_WORD(16'h2E00, 16'hDE00)
    `SEED_WORD(16'h2E80, 16'hDE80)
    `SEED_WORD(16'h2EFE, 16'hFEE0)
    `SEED_WORD(16'h2F00, 16'hDF00)
    `SEED_WORD(16'h2F80, 16'hDF80)
    `SEED_WORD(16'h2FFE, 16'hFEF0)

    `undef SEED_WORD

    // Copy init -> live (byte by byte).
    for (i = 0; i <= DATA_TOP; i = i + 1)
        tmp_data_live[i] = tmp_data_init[i];

    pc1      = 0;
    pc2      = 0;
    ic_count = 0;

    // ============================================================
    // ADDI init: core1 reg[ri]=ri, core2 reg[ri]=ri+1
    // ============================================================
    begin : init_regs
        integer ri;
        integer ri2;
        for (ri = 1; ri <= 7; ri = ri + 1) begin
            ri2 = ri + 1;
            tmp_inst1[pc1] = {3'b010, 3'd0, ri[2:0],  ri[6:0]};
            tmp_inst2[pc2] = {3'b010, 3'd0, ri[2:0], ri2[6:0]};
            sim_reg_c1[ri] = ri;
            sim_reg_c2[ri] = ri2;   // FIX: was ri, must match inst2's imm
            pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
        end
    end

    // ============================================================
    // Main loop (10 iterations). LS addresses now span 0x1000~0x2FFE.
    // addr_A / addr_B are WORD OFFSETs (0..4095), byte = 0x1000 + off*2.
    // Keep within imm7-signed? NO -- here we feed the full 7-bit field
    // of ADDR into the instruction. Since this LS uses rs=r0 (=0) and
    // the HW treats imm as unsigned byte-address selector in the
    // original code (addr_A[6:0]), we must keep addr_A,addr_B <= 127
    // for THIS main-loop encoding. To reach higher addresses we use
    // extra_ls below which builds a base in r1 via ADDI chain.
    // So keep main_loop addresses within 0..127 (byte 0x1000~0x10FE).
    // ============================================================
    begin : main_loop
        integer iter;
        integer addr_A, addr_B;         // WORD OFFSETs (0..127)
        integer baddr_A, baddr_B;       // BYTE addresses in DRAM

        for (iter = 0; iter < 10; iter = iter + 1) begin

        case (iter)
            0: begin addr_A = 0;   addr_B = 1;   end
            1: begin addr_A = 2;   addr_B = 3;   end
            2: begin addr_A = 8;   addr_B = 9;   end
            3: begin addr_A = 16;  addr_B = 17;  end
            4: begin addr_A = 24;  addr_B = 25;  end
            5: begin addr_A = 32;  addr_B = 33;  end
            6: begin addr_A = 40;  addr_B = 48;  end
            7: begin addr_A = 50;  addr_B = 56;  end
            8: begin addr_A = 60;  addr_B = 62;  end
            9: begin addr_A = 63;  addr_B = 2;   end
            default: begin addr_A = 0; addr_B = 1; end
        endcase
        baddr_A = 16'h1000 + (addr_A << 1);
        baddr_B = 16'h1000 + (addr_B << 1);

        // --- ALU / MULT / ADDI / SUBI block ---
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] & sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] & sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] | sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] | sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] & sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] & sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
        sim_reg_c1[3] = ~(sim_reg_c1[1] | sim_reg_c1[2]);
        sim_reg_c2[3] = ~(sim_reg_c2[1] | sim_reg_c2[2]);
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] ^ sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] ^ sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
        sim_reg_c1[3] = ($signed(sim_reg_c1[1]) < $signed(sim_reg_c1[2])) ? 16'h0001 : 16'h0000;
        sim_reg_c2[3] = ($signed(sim_reg_c2[1]) < $signed(sim_reg_c2[2])) ? 16'h0001 : 16'h0000;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        tmp_inst2[pc2] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
        begin
            reg [31:0] prod1, prod2;
            prod1 = sim_reg_c1[1] * sim_reg_c1[2];
            prod2 = sim_reg_c2[1] * sim_reg_c2[2];
            sim_reg_c1[3] = prod1[31:16];
            sim_reg_c1[4] = prod1[15:0];
            sim_reg_c2[3] = prod2[31:16];
            sim_reg_c2[4] = prod2[15:0];
        end
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b010, 3'd1, 3'd5, 7'd5};
        tmp_inst2[pc2] = {3'b010, 3'd1, 3'd5, 7'd5};
        sim_reg_c1[5] = sim_reg_c1[1] + 16'sd5;
        sim_reg_c2[5] = sim_reg_c2[1] + 16'sd5;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        tmp_inst1[pc1] = {3'b011, 3'd1, 3'd6, 7'd3};
        tmp_inst2[pc2] = {3'b011, 3'd1, 3'd6, 7'd3};
        sim_reg_c1[6] = sim_reg_c1[1] - 16'sd3;
        sim_reg_c2[6] = sim_reg_c2[1] - 16'sd3;
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // ========================================================
        // LS sub-sequence.
        // LOAD  w = {live[BA+1], live[BA]}
        // STORE live[BA]=w[7:0]; live[BA+1]=w[15:8]
        // ========================================================

        // +11: c1 LOAD A, c2 NOP
        tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, addr_A[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = NOP;
        sim_reg_c1[7] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // +12: c1 NOP, c2 LOAD A
        tmp_inst1[pc1] = NOP;
        tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, addr_A[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        sim_reg_c2[7] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // +13: c1 LOAD A, c2 LOAD B
        tmp_inst1[pc1] = {3'b100, 3'd0, 3'd6, addr_A[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = {3'b100, 3'd0, 3'd6, addr_B[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        sim_reg_c1[6] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        sim_reg_c2[6] = {tmp_data_live[baddr_B+1], tmp_data_live[baddr_B]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // +14: c1 NOP, c2 STORE A <- r5
        tmp_inst1[pc1] = NOP;
        tmp_inst2[pc2] = {3'b101, 3'd0, 3'd5, addr_A[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        w_tmp = sim_reg_c2[5];
        tmp_data_live[baddr_A]   = w_tmp[7:0];
        tmp_data_live[baddr_A+1] = w_tmp[15:8];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // +15: c1 STORE B <- r5, c2 NOP
        tmp_inst1[pc1] = {3'b101, 3'd0, 3'd5, addr_B[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = NOP;
        w_tmp = sim_reg_c1[5];
        tmp_data_live[baddr_B]   = w_tmp[7:0];
        tmp_data_live[baddr_B+1] = w_tmp[15:8];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // +16: c1 LOAD A, c2 STORE A <- r6 (store first, load sees new)
        tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, addr_A[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = {3'b101, 3'd0, 3'd6, addr_A[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        w_tmp = sim_reg_c2[6];
        tmp_data_live[baddr_A]   = w_tmp[7:0];
        tmp_data_live[baddr_A+1] = w_tmp[15:8];
        sim_reg_c1[7] = {tmp_data_live[baddr_A+1], tmp_data_live[baddr_A]};
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

        // +17: c1 STORE B <- r6, c2 LOAD B (load sees old, then store commits)
        tmp_inst1[pc1] = {3'b101, 3'd0, 3'd6, addr_B[6:0]};
        rs_val_c1[pc1] = sim_reg_c1[0];
        tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, addr_B[6:0]};
        rs_val_c2[pc2] = sim_reg_c2[0];
        sim_reg_c2[7] = {tmp_data_live[baddr_B+1], tmp_data_live[baddr_B]};
        w_tmp = sim_reg_c1[6];
        tmp_data_live[baddr_B]   = w_tmp[7:0];
        tmp_data_live[baddr_B+1] = w_tmp[15:8];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
        end // for iter
    end

    // Fill-up to PC 200
    repeat(12) begin
        tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
        sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
        sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
        pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
    end

    // +199: SUB
    tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
    tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
    sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
    sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

    // ============================================================
    // Cross-block LS after PC 200.
    // 25 groups x 10 LS each. Covers 0x1000~0x2F78.
    //
    // ±200 constraint: consecutive LS within same core must differ
    // by <= 200 words. The imm sequence [0,3,7,15,31,60,5,20,40,55]
    // has max consecutive delta = 55 words -> always satisfies ±200.
    // Cross-group transitions contain ADDI chain (not LS), so they
    // are exempt from the LS address constraint.
    //
    // Two-class layout:
    //   grp 0~12 : c1 sweeps 0x1xxx, c2 sweeps 0x2xxx (gap=2048 words)
    //              -> tests cross-region dependency prediction
    //   grp 13~24: both cores in 0x2xxx, gap=128 words
    //              -> dense 0x2xxx coverage
    //
    // byte addr = 0x1000 + (base + imm) * 2
    // max: base_c2=3936+60=3996 -> 0x1000+3996*2 = 0x2F38 <= 0x2FFE OK
    // ============================================================
    begin : extra_ls
        integer grp;
        integer base_c1, base_c2;

        for (grp = 0; grp < 25; grp = grp + 1) begin
            case (grp)
                // grp 0~12: c1=0x1xxx, c2=0x2xxx, step=160 words
                0:  begin base_c1 = 0;    base_c2 = 2048; end // 0x1000 / 0x2000
                1:  begin base_c1 = 160;  base_c2 = 2208; end // 0x1140 / 0x2140
                2:  begin base_c1 = 320;  base_c2 = 2368; end // 0x1280 / 0x2280
                3:  begin base_c1 = 480;  base_c2 = 2528; end // 0x13C0 / 0x23C0
                4:  begin base_c1 = 640;  base_c2 = 2688; end // 0x1500 / 0x2500
                5:  begin base_c1 = 800;  base_c2 = 2848; end // 0x1640 / 0x2640
                6:  begin base_c1 = 960;  base_c2 = 3008; end // 0x1780 / 0x2780
                7:  begin base_c1 = 1120; base_c2 = 3168; end // 0x18C0 / 0x28C0
                8:  begin base_c1 = 1280; base_c2 = 3328; end // 0x1A00 / 0x2A00
                9:  begin base_c1 = 1440; base_c2 = 3488; end // 0x1B40 / 0x2B40
                10: begin base_c1 = 1600; base_c2 = 3648; end // 0x1C80 / 0x2C80
                11: begin base_c1 = 1760; base_c2 = 3808; end // 0x1DC0 / 0x2DC0
                12: begin base_c1 = 1920; base_c2 = 3968; end // 0x1F00 / 0x2F00
                // grp 13~24: both in 0x2xxx, gap=128 words, step=160 words
                13: begin base_c1 = 2048; base_c2 = 2176; end // 0x2000 / 0x2100
                14: begin base_c1 = 2208; base_c2 = 2336; end // 0x2140 / 0x2240
                15: begin base_c1 = 2368; base_c2 = 2496; end // 0x2280 / 0x2380
                16: begin base_c1 = 2528; base_c2 = 2656; end // 0x23C0 / 0x24C0
                17: begin base_c1 = 2688; base_c2 = 2816; end // 0x2500 / 0x2600
                18: begin base_c1 = 2848; base_c2 = 2976; end // 0x2640 / 0x2740
                19: begin base_c1 = 3008; base_c2 = 3136; end // 0x2780 / 0x2880
                20: begin base_c1 = 3168; base_c2 = 3296; end // 0x28C0 / 0x29C0
                21: begin base_c1 = 3328; base_c2 = 3456; end // 0x2A00 / 0x2B00
                22: begin base_c1 = 3488; base_c2 = 3616; end // 0x2B40 / 0x2C40
                23: begin base_c1 = 3648; base_c2 = 3776; end // 0x2C80 / 0x2D80
                24: begin base_c1 = 3808; base_c2 = 3936; end // 0x2DC0 / 0x2EC0
                default: begin base_c1 = 0; base_c2 = 0; end
            endcase

            // Stage 1: ADDI chain to build base in r1
            begin : build_bases
                integer acc1, acc2;
                integer chunk1, chunk2;
                integer first1, first2;
                integer done1, done2;

                acc1 = 0; acc2 = 0;
                first1 = 1; first2 = 1;
                done1 = 0; done2 = 0;

                while (!(done1 && done2)) begin
                    if (!done1) begin
                        chunk1 = base_c1 - acc1;
                        if (chunk1 > 63) chunk1 = 63;
                        if (first1) begin
                            tmp_inst1[pc1] = {3'b010, 3'd0, 3'd1, chunk1[6:0]};
                            sim_reg_c1[1] = chunk1;
                            first1 = 0;
                        end else begin
                            tmp_inst1[pc1] = {3'b010, 3'd1, 3'd1, chunk1[6:0]};
                            sim_reg_c1[1] = sim_reg_c1[1] + chunk1;
                        end
                        acc1 = acc1 + chunk1;
                        if (acc1 >= base_c1) done1 = 1;
                    end else begin
                        tmp_inst1[pc1] = {3'b010, 3'd1, 3'd1, 7'd0};
                    end

                    if (!done2) begin
                        chunk2 = base_c2 - acc2;
                        if (chunk2 > 63) chunk2 = 63;
                        if (first2) begin
                            tmp_inst2[pc2] = {3'b010, 3'd0, 3'd1, chunk2[6:0]};
                            sim_reg_c2[1] = chunk2;
                            first2 = 0;
                        end else begin
                            tmp_inst2[pc2] = {3'b010, 3'd1, 3'd1, chunk2[6:0]};
                            sim_reg_c2[1] = sim_reg_c2[1] + chunk2;
                        end
                        acc2 = acc2 + chunk2;
                        if (acc2 >= base_c2) done2 = 1;
                    end else begin
                        tmp_inst2[pc2] = {3'b010, 3'd1, 3'd1, 7'd0};
                    end

                    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
                end
            end

            // Stage 2: 10 LS per group, rs=r1, varied imm
            begin : do_ls
                integer k;
                integer imm_k;
                integer c1_is_st, c2_is_st;
                integer eff1_byte, eff2_byte;

                for (k = 0; k < 10; k = k + 1) begin
                    case (k)
                        0: imm_k = 0;
                        1: imm_k = 3;
                        2: imm_k = 7;
                        3: imm_k = 15;
                        4: imm_k = 31;
                        5: imm_k = 60;
                        6: imm_k = 5;
                        7: imm_k = 20;
                        8: imm_k = 40;
                        9: imm_k = 55;
                        default: imm_k = 0;
                    endcase

                    case (k)
                        0: begin c1_is_st = 0; c2_is_st = 1; end
                        1: begin c1_is_st = 1; c2_is_st = 0; end
                        2: begin c1_is_st = 0; c2_is_st = 0; end
                        3: begin c1_is_st = 1; c2_is_st = 0; end
                        4: begin c1_is_st = 0; c2_is_st = 1; end
                        5: begin c1_is_st = 1; c2_is_st = 0; end
                        6: begin c1_is_st = 0; c2_is_st = 0; end
                        7: begin c1_is_st = 0; c2_is_st = 1; end
                        8: begin c1_is_st = 1; c2_is_st = 0; end
                        9: begin c1_is_st = 0; c2_is_st = 0; end
                        default: begin c1_is_st = 0; c2_is_st = 0; end
                    endcase

                    eff1_byte = 16'h1000 + ((sim_reg_c1[1] + imm_k) << 1);
                    eff2_byte = 16'h1000 + ((sim_reg_c2[1] + imm_k) << 1);

                    // Core1
                    if (c1_is_st) begin
                        tmp_inst1[pc1] = {3'b101, 3'd1, 3'd5, imm_k[6:0]};
                        rs_val_c1[pc1] = sim_reg_c1[1];
                        w_tmp = sim_reg_c1[5];
                        tmp_data_live[eff1_byte]   = w_tmp[7:0];
                        tmp_data_live[eff1_byte+1] = w_tmp[15:8];
                    end else begin
                        tmp_inst1[pc1] = {3'b100, 3'd1, 3'd7, imm_k[6:0]};
                        rs_val_c1[pc1] = sim_reg_c1[1];
                        sim_reg_c1[7] = {tmp_data_live[eff1_byte+1], tmp_data_live[eff1_byte]};
                    end

                    // Core2
                    if (c2_is_st) begin
                        tmp_inst2[pc2] = {3'b101, 3'd1, 3'd5, imm_k[6:0]};
                        rs_val_c2[pc2] = sim_reg_c2[1];
                        w_tmp = sim_reg_c2[5];
                        tmp_data_live[eff2_byte]   = w_tmp[7:0];
                        tmp_data_live[eff2_byte+1] = w_tmp[15:8];
                    end else begin
                        tmp_inst2[pc2] = {3'b100, 3'd1, 3'd7, imm_k[6:0]};
                        rs_val_c2[pc2] = sim_reg_c2[1];
                        sim_reg_c2[7] = {tmp_data_live[eff2_byte+1], tmp_data_live[eff2_byte]};
                    end

                    pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
                end
            end
        end
    end

    $display("%0s[task_basic] %0d instructions generated (rest NOP)%0s",
             txt_cyan_prefix, ic_count, reset_color);

    // ============================================================
    // Write inst_1_dram_file.dat
    // ============================================================
    fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        reg [2:0]        cop, crs, crt, crd, crl, csub;
        reg signed [6:0] cimm;
        reg [31:0]       eff_byte_addr;

        $fwrite(fd_i1, "@%04h\n", (i << 1));

        cop  = tmp_inst1[i][15:13];
        crs  = tmp_inst1[i][12:10];
        crt  = tmp_inst1[i][9:7];
        crd  = tmp_inst1[i][6:4];
        crl  = tmp_inst1[i][3:1];
        csub = tmp_inst1[i][3:1];
        cimm = tmp_inst1[i][6:0];

        eff_byte_addr = DATA_BASE + ((rs_val_c1[i] + $signed(cimm)) << 1);

        if (tmp_inst1[i] == NOP) begin
            $fwrite(fd_i1, "%02h %02h // %d:NOP\n", tmp_inst1[i][15:8], tmp_inst1[i][7:0], i);
        end else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i1, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b001: $fwrite(fd_i1, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b010: $fwrite(fd_i1, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b011: $fwrite(fd_i1, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b100: $fwrite(fd_i1, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b101: $fwrite(fd_i1, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                        3'b110: $fwrite(fd_i1, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i , crd, crs, crt);
                        3'b111: $fwrite(fd_i1, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",  tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
                    endcase
                end
                3'b001: $fwrite(fd_i1, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crl, crs, crt);
                3'b010: $fwrite(fd_i1, "%02h %02h // %d:ADDI r%0d = r%0d + %0d\n",          tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
                3'b011: $fwrite(fd_i1, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",          tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
                3'b100: $fwrite(fd_i1, "%02h %02h // %d:LOAD  r%0d <- DM[0x%04h] rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, eff_byte_addr[15:0], crs, rs_val_c1[i], $signed(cimm));
                3'b101: $fwrite(fd_i1, "%02h %02h // %d:STORE DM[0x%04h] <- r%0d rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, eff_byte_addr[15:0], crt, crs, rs_val_c1[i], $signed(cimm));
                default: $fwrite(fd_i1, "%02h %02h // %d:UNKNOWN\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i);
            endcase
        end
    end
    $fclose(fd_i1);

    // ============================================================
    // Write inst_2_dram_file.dat
    // ============================================================
    fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        reg [2:0]        cop, crs, crt, crd, crl, csub;
        reg signed [6:0] cimm;
        reg [31:0]       eff_byte_addr;

        $fwrite(fd_i2, "@%04h\n", (i << 1));

        cop  = tmp_inst2[i][15:13];
        crs  = tmp_inst2[i][12:10];
        crt  = tmp_inst2[i][9:7];
        crd  = tmp_inst2[i][6:4];
        crl  = tmp_inst2[i][3:1];
        csub = tmp_inst2[i][3:1];
        cimm = tmp_inst2[i][6:0];

        eff_byte_addr = DATA_BASE + ((rs_val_c2[i] + $signed(cimm)) << 1);

        if (tmp_inst2[i] == NOP) begin
            $fwrite(fd_i2, "%02h %02h // %d:NOP\n", tmp_inst2[i][15:8], tmp_inst2[i][7:0], i);
        end else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i2, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b001: $fwrite(fd_i2, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b010: $fwrite(fd_i2, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b011: $fwrite(fd_i2, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b100: $fwrite(fd_i2, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b101: $fwrite(fd_i2, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b110: $fwrite(fd_i2, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                        3'b111: $fwrite(fd_i2, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",  tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
                    endcase
                end
                3'b001: $fwrite(fd_i2, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crl, crs, crt);
                3'b010: $fwrite(fd_i2, "%02h %02h // %d:ADDI r%0d = r%0d + %0d\n",          tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
                3'b011: $fwrite(fd_i2, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",          tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
                3'b100: $fwrite(fd_i2, "%02h %02h // %d:LOAD  r%0d <- DM[0x%04h] rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, eff_byte_addr[15:0], crs, rs_val_c2[i], $signed(cimm));
                3'b101: $fwrite(fd_i2, "%02h %02h // %d:STORE DM[0x%04h] <- r%0d rs=r%0d(=%0d) imm=%0d\n",
                                 tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, eff_byte_addr[15:0], crt, crs, rs_val_c2[i], $signed(cimm));
                default: $fwrite(fd_i2, "%02h %02h // %d:UNKNOWN\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i);
            endcase
        end
    end
    $fclose(fd_i2);

    // ============================================================
    // Write shared data_dram_file.dat using the INITIAL state.
    // Format:  @<byte_addr_even>
    //          <low_byte> <high_byte> // comment
    // ============================================================
    fd_d = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
    for (i = DATA_ACC_LO; i <= DATA_ACC_HI; i = i + 2) begin
        $fwrite(fd_d, "@%04h\n", i);
        $fwrite(fd_d, "%02h %02h // DATA[%04h] = %0d\n",
                tmp_data_init[i],           // low  byte first
                tmp_data_init[i+1],         // high byte second
                i,
                {tmp_data_init[i+1], tmp_data_init[i]});
    end
    $fclose(fd_d);
    $display("%0s[task_basic] .dat files written%0s", txt_cyan_prefix, reset_color);
end endtask