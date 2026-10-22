`ifdef RTL
    `define CYCLE_TIME_clk1 20.1
    `define CYCLE_TIME_clk2 11.3
    `define CYCLE_TIME_clk3 34.7
`endif
`ifdef Period_1
    `define CYCLE_TIME_clk1 34.7
    `define CYCLE_TIME_clk2 20.1
    `define CYCLE_TIME_clk3 11.3
`endif
`ifdef Period_2
    `define CYCLE_TIME_clk1 11.3
    `define CYCLE_TIME_clk2 20.1
    `define CYCLE_TIME_clk3 34.7
`endif
`ifdef Period_3
    `define CYCLE_TIME_clk1 20.1
    `define CYCLE_TIME_clk2 11.3
    `define CYCLE_TIME_clk3 34.7
`endif
`ifdef GATE
    `define CYCLE_TIME_clk1 20.1
    `define CYCLE_TIME_clk2 11.3
    `define CYCLE_TIME_clk3 34.7
`endif

module PATTERN(
    output reg      clk1,
    output reg      clk2,
    output reg      clk3,
    output reg      rst_n,
    
    // AXI4-Lite Master (clk2 domain)
    input [31:0]    ar_addr_clk2, 
    input           ar_valid_clk2, 
    input           ar_ready_clk2,
    input [63:0]    r_data_clk2,  
    input           r_valid_clk2, 
    input           r_ready_clk2,

    // AXI4-Lite Slave (clk3 domain)
    input [31:0]    ar_addr_clk3, 
    input           ar_valid_clk3, 
    input           ar_ready_clk3,
    input [63:0]    r_data_clk3,  
    input           r_valid_clk3, 
    input           r_ready_clk3,

    output reg      in_mode_valid,
    output reg      in_mode,
    output reg      in_valid,
    output reg [1:0]in_bank,
    output reg [5:0]in_src_row,
    
    input           out_valid,
    input [63:0]    out_data
);

//---------------------------------------------------------------------
//   PARAMETERS & VARIABLES
//---------------------------------------------------------------------
real CYCLE_clk1 = `CYCLE_TIME_clk1;
real CYCLE_clk2 = `CYCLE_TIME_clk2;
real CYCLE_clk3 = `CYCLE_TIME_clk3;


bit mode_array[];
parameter PATNUM = 100;
parameter TIMEOUT_LIMIT = 90000;

integer total_latency;
integer pat_latency;
integer pat_idx;

// Golden Memory for Verification
reg [63:0] golden_DRAM [0:65535];
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
initial $readmemh(DRAM_p_r, golden_DRAM);

// Golden Answers
reg [63:0] golden_out_arr [0:1024]; // Max 1024 outputs for GAUSS
integer golden_out_cnt;
integer out_receive_cnt;

// Error Flags
reg flag_axi_timeout;
reg flag_axi_stability;
reg flag_main_timeout;
reg flag_main_cycles;
reg flag_main_data;

//---------------------------------------------------------------------
//   AXI & DRAM PROTOCOL CHECKER QUEUES (新增)
//---------------------------------------------------------------------
reg [31:0] q_ar_clk2_to_clk3 [$]; // 檢查 1: clk2_ar 送出後，clk3_ar 是否相符
reg [31:0] q_ar_clk3_to_dram [$]; // 檢查 2: clk3_ar 送出後，DRAM 是否執行 READ
reg [63:0] q_r_expected_clk3 [$]; // 檢查 3: DRAM READ 後，預期 clk3_r 應該收到的 Golden Data
reg [63:0] q_r_clk3_to_clk2  [$]; // 檢查 4: clk3_r 收完後，clk2_r 是否相符

//---------------------------------------------------------------------
//   CLOCK GENERATION
//---------------------------------------------------------------------
initial clk1 = 0;
initial clk2 = 0;
initial clk3 = 0;
always #(CYCLE_clk1/2.0) clk1 = ~clk1;
always #(CYCLE_clk2/2.0) clk2 = ~clk2;
always #(CYCLE_clk3/2.0) clk3 = ~clk3;

//---------------------------------------------------------------------
//   SIMULATION FLOW
//---------------------------------------------------------------------
initial begin
    mode_array = new[PATNUM];
    foreach (mode_array[i]) begin
        mode_array[i] = (i < PATNUM / 2) ? 1'b0 : 1'b1;
    end
    mode_array.shuffle();
    reset_task;
    
    total_latency = 0;
    
    for (pat_idx = 0; pat_idx < PATNUM; pat_idx = pat_idx + 1) begin
        $display("Applying Pattern %0d...", pat_idx);
        input_task;
        wait_and_check_task;
        
        // Random delay between patterns
        repeat($urandom_range(2, 5)) @(negedge clk1);
    end
    
    YOU_PASS_task;
end

//---------------------------------------------------------------------
//   TASKS
//---------------------------------------------------------------------
task reset_task; begin
    // 清空所有追蹤 Queue (新增)
    q_ar_clk2_to_clk3.delete();
    q_ar_clk3_to_dram.delete();
    q_r_expected_clk3.delete();
    q_r_clk3_to_clk2.delete();

    // Initialize input signals
    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;

    rst_n = 1'b1;
    in_mode_valid = 1'b0;
    in_mode = 1'bx;
    in_valid = 1'b0;
    in_bank = 2'bx;
    in_src_row = 6'bx;
    
    // Initialize flags
    flag_axi_timeout = 0;
    flag_axi_stability = 0;
    flag_main_timeout = 0;
    flag_main_cycles = 0;
    flag_main_data = 0;

    // Apply Reset
    #(CYCLE_clk1);  rst_n = 0;
    #(CYCLE_clk1 * 3); rst_n = 1;
    
    //---------------------------------------------------------------------
    // SPEC MAIN-1 CHECK: 
    // All output signals including AXI signals should be reset after the 
    // reset signal is asserted.
    //---------------------------------------------------------------------
    if ((out_valid !== 1'b0) || (out_data !== 64'b0) ||
        (ar_addr_clk2 !== 32'b0) || (ar_valid_clk2 !== 1'b0) || (ar_ready_clk2 !== 1'b0) ||
        (r_data_clk2 !== 64'b0)  || (r_valid_clk2 !== 1'b0)  || (r_ready_clk2 !== 1'b0)  ||
        (ar_addr_clk3 !== 32'b0) || (ar_valid_clk3 !== 1'b0) || (ar_ready_clk3 !== 1'b0) ||
        (r_data_clk3 !== 64'b0)  || (r_valid_clk3 !== 1'b0)  || (r_ready_clk3 !== 1'b0)) begin
        
        $display("*************************************************************************");
        $display("* All output signals and AXI signals must be reset to 0 during reset.   *");
        $display("*************************************************************************");
        $finish;
    end
    #(CYCLE_clk1);
    release clk1;
    release clk2;
    release clk3;
end endtask

reg current_mode;
reg [1:0] calc_banks [0:3];
reg [5:0] calc_rows [0:3];
reg [5:0] gauss_target_row;

task input_task; 
    integer i;
begin

    current_mode = mode_array[pat_idx]; 

    $display("Input pattern for Pattern %0d applied. Mode: %s", pat_idx, (current_mode == 0) ? "CALC" : "GAUSS");
    
    // Drive mode
    @(negedge clk1);
    in_mode_valid = 1'b1;
    in_mode = current_mode;
    
    // Drive inputs for 4 cycles
    @(negedge clk1);
    in_mode_valid = 1'b0;
    in_mode = 1'bx;
    
    if (current_mode == 0) begin
        // CALC Mode: 4 different trees
        golden_out_cnt = 4;
        for (i = 0; i < 4; i = i + 1) begin
            calc_banks[i] = $urandom_range(0, 3);
            calc_rows[i] = $urandom_range(0, 63);
            
            in_valid = 1'b1;
            in_bank = calc_banks[i];
            in_src_row = calc_rows[i];
            
            // Pre-calculate golden answers for CALC
            golden_out_arr[i] = pre_tree({calc_banks[i], calc_rows[i], 8'd0});
            $display("  Tree %0d: Bank %0d, Row %0d, Golden Output = %h", i, calc_banks[i], calc_rows[i], golden_out_arr[i]);
            @(negedge clk1);
        end
    end 
    else begin
        // GAUSS Mode: 4 cycles of independent banks and rows
        for (i = 0; i < 4; i = i + 1) begin
            calc_banks[i] = $urandom_range(0, 3);
            calc_rows[i]  = $urandom_range(0, 63);
            
            in_valid = 1'b1;
            in_bank = calc_banks[i];
            in_src_row = calc_rows[i];
            @(negedge clk1);
        end
        calc_gauss_golden();
    end
    
    in_valid = 1'b0;
    in_bank = 2'bx;
    in_src_row = 6'bx;
end 
endtask

task wait_and_check_task; 
begin
    out_receive_cnt = 0;
    pat_latency = 0;
    $display("Waiting for outputs for Pattern %0d...", pat_idx);
    while (out_receive_cnt < golden_out_cnt) begin
        if (out_valid === 1'b1) begin
            if (out_data !== golden_out_arr[out_receive_cnt]) begin
                $display("*************************************************************************");
                $display("FAIL! Data mismatch at output index %0d. Expected: %h, Got: %h", out_receive_cnt, golden_out_arr[out_receive_cnt], out_data);
                $display("Latency for Pattern %0d: %0d cycles.", pat_idx, pat_latency);
                $display("*************************************************************************");
                flag_main_data = 1;
                YOU_FAIL_task;
                $finish;
            end
            out_receive_cnt = out_receive_cnt + 1;
        end
        // $display("Cycle %0d: out_valid=%b, out_data=%h, received_count=%0d/%0d", pat_latency, out_valid, out_data, out_receive_cnt, golden_out_cnt);
        
        pat_latency = pat_latency + 1;
        if (pat_latency > TIMEOUT_LIMIT) begin
            $display("*************************************************************************");
            $display("FAIL! Execution latency exceeded %0d cycles.", TIMEOUT_LIMIT);
            $display("*************************************************************************");
            flag_main_timeout = 1;
            YOU_FAIL_task;
            $finish;
        end
        
        @(negedge clk1);
    end
    $display("*************************************************************************");
    $display("All expected outputs received for Pattern %0d. Total outputs: %0d", pat_idx, golden_out_cnt);
    $display("*************************************************************************");
    // Check if out_valid stays high unnecessarily
    if (out_valid === 1'b1) begin
        $display("*************************************************************************");
        $display("FAIL! out_valid asserted for more cycles than expected (%0d).", golden_out_cnt);
        $display("latency for Pattern %0d: %0d cycles.", pat_idx, pat_latency);
        $display("*************************************************************************");
        flag_main_cycles = 1;
        YOU_FAIL_task;
        $finish;
    end

    //---------------------------------------------------------------------
    // SPEC CHECK (新增): 確認 Queue 是否完全清空 (確保次數、順序一致，無掉單)
    //---------------------------------------------------------------------
    if (q_ar_clk2_to_clk3.size() != 0 || q_ar_clk3_to_dram.size() != 0 ||
        q_r_expected_clk3.size() != 0 || q_r_clk3_to_clk2.size() != 0) begin
        $display("*************************************************************************");
        $display("FAIL! Transaction count mismatch at the end of Pattern %0d.", pat_idx);
        $display("Pending AR (clk2->clk3): %0d", q_ar_clk2_to_clk3.size());
        $display("Pending DRAM Reads     : %0d", q_ar_clk3_to_dram.size());
        $display("Pending R (DRAM->clk3) : %0d", q_r_expected_clk3.size());
        $display("Pending R (clk3->clk2) : %0d", q_r_clk3_to_clk2.size());
        $display("*************************************************************************");
        YOU_FAIL_task;
        $finish;
    end

    total_latency = total_latency + pat_latency;
    $display("Pattern %0d passed. Latency: %0d cycles.", pat_idx, pat_latency);
    
end endtask

//---------------------------------------------------------------------
//   GOLDEN CALCULATIONS
//---------------------------------------------------------------------
// 1. Recursive Prefix Tree Evaluation (CALC)
function automatic signed [63:0] pre_tree;
    input [15:0] addr;
    reg [63:0] node_data;
    reg [1:0] opcode;
    reg signed [63:0] left_val, right_val;
begin
    node_data = golden_DRAM[addr];
    if (node_data[63] == 0) begin // Number Node
        pre_tree = {{33{node_data[62]}}, node_data[62:32]}; // Sign extend
    end 
    else begin // Operator Node
        opcode = node_data[33:32];
        left_val = pre_tree(node_data[31:16]);
        right_val = pre_tree(node_data[15:0]);
        case (opcode)
            2'b00: pre_tree = left_val + right_val; // ADD
            2'b01: pre_tree = left_val - right_val; // SUB
            2'b10: pre_tree = left_val * right_val; // MUL
            2'b11: pre_tree = left_val >>> right_val[5:0]; // Arithmetic SHR
            default: pre_tree = 64'b0;
        endcase
    end
end
endfunction

// 2. Statistical Analysis & Filtering (GAUSS)
task calc_gauss_golden;
    integer b, c;
    reg [63:0] word;
    reg [63:0] val;
    reg [63:0] sum, mean, count;
    reg [127:0] var_sum, diff, diff_sq;
    reg is_valid, is_last;
begin
    sum = 0; count = 0;
    // Pass 1: Mean
    for (b = 0; b < 4; b = b + 1) begin
        for (c = 0; c < 256; c = c + 1) begin
            word = golden_DRAM[{calc_banks[b], calc_rows[b], c[7:0]}];
            if (word[63] == 0) begin
                val = {33'b0, word[62:32]};
                sum = sum + val; count = count + 1;
            end
        end
    end
    mean = (count > 0) ? (sum / count) : 0;
    
    // Pass 2: Variance
    var_sum = 0;
    for (b = 0; b < 4; b = b + 1) begin
        for (c = 0; c < 256; c = c + 1) begin
            word = golden_DRAM[{calc_banks[b], calc_rows[b], c[7:0]}];
            if (word[63] == 0) begin
                val = {33'b0, word[62:32]};
                diff = (val > mean) ? (val - mean) : (mean - val);
                var_sum = var_sum + (diff * diff);
            end
        end
    end
    if (count > 0) var_sum = var_sum / count; else var_sum = 0;
    
    // Pass 3: Filter and Append
    golden_out_cnt = 0;
    for (b = 0; b < 4; b = b + 1) begin
        for (c = 0; c < 256; c = c + 1) begin
            word = golden_DRAM[{calc_banks[b], calc_rows[b], c[7:0]}];
            is_valid = (word[63] == 0);
            is_last = (b == 3 && c == 255);
            
            if (is_valid) begin
                val = {33'b0, word[62:32]};
                diff = (val > mean) ? (val - mean) : (mean - val);
                diff_sq = diff * diff;
                
                if (diff_sq <= var_sum) begin
                    golden_out_arr[golden_out_cnt] = word;
                    golden_out_cnt = golden_out_cnt + 1;
                end 
                else if (is_last) begin
                    golden_out_arr[golden_out_cnt] = word;
                    golden_out_cnt = golden_out_cnt + 1;
                end
            end 
            else if (is_last) begin
                golden_out_arr[golden_out_cnt] = word;
                golden_out_cnt = golden_out_cnt + 1;
            end
        end
    end
end endtask

//---------------------------------------------------------------------
//   AXI PROTOCOL MONITORS (Concurrent Checking)
//---------------------------------------------------------------------
// Monitor CLK2 Domain (Master to Harvester CDC)
reg ar_valid_clk2_d;
reg ar_ready_clk2_d;
reg [31:0] ar_addr_clk2_d;
reg r_valid_clk2_d;
reg r_ready_clk2_d;
reg [63:0] r_data_clk2_d;

integer ar_timeout_clk2, r_timeout_clk2;

always @(negedge clk2) begin
    if (rst_n) begin
        // 1. Stability Check: ar_addr
        if (ar_valid_clk2_d && !ar_ready_clk2_d && (!ar_valid_clk2 || ar_addr_clk2 !== ar_addr_clk2_d)) begin
            $display("*************************************************************************");
            $display("AXI FAIL: ar_addr_clk2 unstable during handshake.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end
        if (ar_valid_clk2 === 0 && ar_addr_clk2 !== 0) begin
            $display("*************************************************************************");
            $display("AXI FAIL: ar_addr_clk2 should be 0 when ar_valid_clk2 is deasserted.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end

        // 2. Stability Check: r_data
        if (r_valid_clk2_d && !r_ready_clk2_d && (!r_valid_clk2 || r_data_clk2 !== r_data_clk2_d)) begin
            $display("*************************************************************************");
            $display("AXI FAIL: r_data_clk2 unstable during handshake.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end
        
        if (r_valid_clk2 === 0 && r_data_clk2 !== 0) begin
            $display("*************************************************************************");
            $display("AXI FAIL: r_data_clk2 should be 0 when r_valid_clk2 is deasserted.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end

        // 3. Timeout Check: AR Ready
        if (ar_valid_clk2 && !ar_ready_clk2) begin
            ar_timeout_clk2 = ar_timeout_clk2 + 1;
            if (ar_timeout_clk2 > 500) begin
                $display("*************************************************************************");
                $display("AXI FAIL: ar_ready_clk2 timeout.");
                $display("*************************************************************************");
                YOU_FAIL_task; $finish;
            end
        end else ar_timeout_clk2 = 0;

        // 4. Timeout Check: R Ready
        if (r_valid_clk2 && !r_ready_clk2) begin
            r_timeout_clk2 = r_timeout_clk2 + 1;
            if (r_timeout_clk2 > 500) begin
                $display("*************************************************************************");
                $display("AXI FAIL: r_ready_clk2 timeout.");
                $display("*************************************************************************");
                YOU_FAIL_task; 
                $finish;
            end
        end else r_timeout_clk2 = 0;

        // ====================================================================
        // Queue Check: AR Push (clk2 -> clk3) & R Pop (clk3 -> clk2) (新增)
        // ====================================================================
        if (ar_valid_clk2 && ar_ready_clk2) begin
            q_ar_clk2_to_clk3.push_back(ar_addr_clk2); // clk2 成功送出 AR
        end

        if (r_valid_clk2 && r_ready_clk2) begin
            if (q_r_clk3_to_clk2.size() == 0) begin
                $display("*************************************************************************");
                $display("AXI FAIL: clk2_r handshakes, but clk3_r never sent data!");
                $display("*************************************************************************");
                YOU_FAIL_task; $finish;
            end else begin
                logic [63:0] exp_data;
                exp_data = q_r_clk3_to_clk2.pop_front();
                if (r_data_clk2 !== exp_data) begin
                    $display("*************************************************************************");
                    $display("AXI FAIL: clk2_r data (%h) does not match clk3_r data (%h)!", r_data_clk2, exp_data);
                    $display("*************************************************************************");
                    YOU_FAIL_task; $finish;
                end
            end
        end
        // ====================================================================

        // Save states
        ar_valid_clk2_d = ar_valid_clk2;
        ar_ready_clk2_d = ar_ready_clk2;
        ar_addr_clk2_d = ar_addr_clk2;
        r_valid_clk2_d = r_valid_clk2;
        r_ready_clk2_d = r_ready_clk2;
        r_data_clk2_d = r_data_clk2;
    end else begin
        ar_valid_clk2_d = 0;
        r_valid_clk2_d = 0;
        ar_timeout_clk2 = 0;
        r_timeout_clk2 = 0;
    end
end

// Monitor CLK3 Domain (Harvester CDC to DRAM_SYS)
reg ar_valid_clk3_d;
reg ar_ready_clk3_d;
reg [31:0] ar_addr_clk3_d;

reg r_valid_clk3_d;
reg r_ready_clk3_d;  
reg [63:0] r_data_clk3_d;

integer ar_timeout_clk3, r_timeout_clk3;

always @(negedge clk3) begin
    if (rst_n) begin

        if (ar_valid_clk3_d && !ar_ready_clk3_d && (!ar_valid_clk3 || ar_addr_clk3 !== ar_addr_clk3_d)) begin
            $display("*************************************************************************");
            $display("AXI FAIL: ar_addr_clk3 unstable during handshake.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end

        if (ar_valid_clk3 === 0 && ar_addr_clk3 !== 0) begin
            $display("*************************************************************************");
            $display("AXI FAIL: ar_addr_clk3 should be 0 when ar_valid_clk3 is deasserted.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end
        
        if (r_valid_clk3_d && !r_ready_clk3_d && (!r_valid_clk3 || r_data_clk3 !== r_data_clk3_d)) begin
            $display("*************************************************************************");
            $display("AXI FAIL: r_data_clk3 unstable during handshake.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end

        if (r_valid_clk3 === 0 && r_data_clk3 !== 0) begin
            $display("*************************************************************************");
            $display("AXI FAIL: r_data_clk3 should be 0 when r_valid_clk3 is deasserted.");
            $display("*************************************************************************");
            YOU_FAIL_task; 
            $finish;
        end
        
        if (ar_valid_clk3 && !ar_ready_clk3) begin
            ar_timeout_clk3 = ar_timeout_clk3 + 1;
            if (ar_timeout_clk3 > 500) begin
                $display("AXI FAIL: ar_ready_clk3 timeout.");
                YOU_FAIL_task; 
                $finish;
            end
        end else ar_timeout_clk3 = 0;

        if (r_valid_clk3 && !r_ready_clk3) begin
            r_timeout_clk3 = r_timeout_clk3 + 1;
            if (r_timeout_clk3 > 500) begin
                $display("AXI FAIL: r_ready_clk3 timeout.");
                YOU_FAIL_task; 
                $finish;
            end
        end else r_timeout_clk3 = 0;

        // ====================================================================
        // Queue Check: AR Pop (clk2 -> clk3), AR Push (clk3 -> DRAM), R Pop & Push (新增)
        // ====================================================================
        if (ar_valid_clk3 && ar_ready_clk3) begin
            if (q_ar_clk2_to_clk3.size() == 0) begin
                $display("*************************************************************************");
                $display("AXI FAIL: clk3_ar handshakes, but clk2_ar never sent data (or order mismatch)!");
                $display("*************************************************************************");
                YOU_FAIL_task; $finish;
            end else begin
                logic [31:0] exp_addr;
                exp_addr = q_ar_clk2_to_clk3.pop_front();
                if (ar_addr_clk3 !== exp_addr) begin
                    $display("*************************************************************************");
                    $display("AXI FAIL: clk3_ar address (%h) does not match clk2_ar address (%h)!", ar_addr_clk3, exp_addr);
                    $display("*************************************************************************");
                    YOU_FAIL_task; $finish;
                end
                q_ar_clk3_to_dram.push_back(ar_addr_clk3); // 交接給 DRAM 追蹤 Queue
            end
        end

        if (r_valid_clk3 && r_ready_clk3) begin
            if (q_r_expected_clk3.size() == 0) begin
                $display("*************************************************************************");
                $display("AXI FAIL: clk3_r handshakes, but no DRAM READ data was expected!");
                $display("*************************************************************************");
                YOU_FAIL_task; $finish;
            end else begin
                logic [63:0] exp_data;
                exp_data = q_r_expected_clk3.pop_front();
                if (r_data_clk3 !== exp_data) begin
                    $display("*************************************************************************");
                    $display("AXI FAIL: clk3_r data (%h) does not match golden DRAM data (%h)!", r_data_clk3, exp_data);
                    $display("*************************************************************************");
                    YOU_FAIL_task; $finish;
                end
                q_r_clk3_to_clk2.push_back(r_data_clk3); // 交接給 clk2 追蹤 Queue
            end
        end
        // ====================================================================

        ar_valid_clk3_d <= ar_valid_clk3;
        ar_ready_clk3_d <= ar_ready_clk3;
        ar_addr_clk3_d  <= ar_addr_clk3;
        
        r_valid_clk3_d  <= r_valid_clk3;
        r_ready_clk3_d  <= r_ready_clk3;  
        r_data_clk3_d   <= r_data_clk3;
        
    end else begin
        ar_valid_clk3_d <= 0;
        ar_ready_clk3_d <= 0;
        r_valid_clk3_d  <= 0;
        r_ready_clk3_d  <= 0;
        ar_timeout_clk3 = 0;
        r_timeout_clk3  = 0;
    end
end

// ====================================================================
// Monitor DRAM Execution (獨立的 Monitor，專抓 DRAM CMD) (新增)
// ====================================================================
always @(negedge clk3) begin
    // 假設 DRAM 實例名稱為 u_DRAM 且在 TESTBED 底下。若路徑不同請自行調整
    if (rst_n && TESTBED.u_DRAM.dram_cmd === 4'b0101) begin // 4'b0101 = CMD_READ
        if (q_ar_clk3_to_dram.size() == 0) begin
            $display("*************************************************************************");
            $display("DRAM FAIL: DRAM performed a READ, but there was no pending ar_handshake!");
            $display("*************************************************************************");
            YOU_FAIL_task; $finish;
        end else begin
            logic [31:0] dram_read_addr;
            dram_read_addr = q_ar_clk3_to_dram.pop_front();
            // 將對應地址的 Golden Data 塞入 expected Queue 中，供後續 R 檢查
            q_r_expected_clk3.push_back(golden_DRAM[dram_read_addr[15:0]]);
        end
    end
end
// ====================================================================

//---------------------------------------------------------------------
//   PRINT TASKS
//---------------------------------------------------------------------
task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("* Congratulations!                                               *");
    $display("* Your execution cycles = %5d cycles                 *", total_latency);
    $display("* Your clock period = %.1f ns                        *", CYCLE_clk1);
    $display(" Avg Latency per Pattern = %.1f cycles                 *", total_latency / PATNUM);
    $display("* Total Latency = %.1f ns                            *", total_latency * CYCLE_clk1);
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_FAIL_task; begin
    $display("*************************************************************************");
    $display("* FAIL!                                            *");
    $display("* Error message from PATTERN.v                       *");
    $display("*************************************************************************");
end endtask

endmodule