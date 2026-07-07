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

`define PATNUM 1000
`define MAX_LATENCY 40000

// `define DEBUG
module PATTERN(
    output reg      clk1,
    output reg      clk2,
    output reg      clk3,

    output reg      rst_n,
    // AXI4-Lite Master
    input      [31:0]  ar_addr_clk2, 
    input              ar_valid_clk2, 
    input              ar_ready_clk2,
    input       [63:0] r_data_clk2,  
    input              r_valid_clk2, 
    input              r_ready_clk2,

    input      [31:0]  ar_addr_clk3, 
    input              ar_valid_clk3, 
    input              ar_ready_clk3,
    input       [63:0] r_data_clk3,  
    input              r_valid_clk3, 
    input              r_ready_clk3,

    output reg       in_mode_valid,
    output reg       in_mode,
    output reg       in_valid,
    output reg [1:0] in_bank,
    output reg [5:0] in_src_row,
    
    input             out_valid,
    input [63:0]      out_data
);
real	CYCLE_clk1 = `CYCLE_TIME_clk1;
real	CYCLE_clk2 = `CYCLE_TIME_clk2;
real	CYCLE_clk3 = `CYCLE_TIME_clk3;

// =====================================================================
//  Golden DRAM
// =====================================================================
reg [63:0] golden_DRAM [0:65535];
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
initial $readmemh(DRAM_p_r, golden_DRAM);

// =====================================================================
//  Parameters & integers
// =====================================================================

integer patcount;
integer total_latency;
integer error_count;
integer passed_patterns;
integer failed_patterns;
integer wait_val_time;
integer i, j, k;
integer collected;
integer peak_cycle;
integer peak_cycle_patnum;
// =====================================================================
//  Pattern storage
// =====================================================================
reg        all_mode    [0:`PATNUM-1];
reg [5:0]  all_src_row [0:`PATNUM*4-1];
reg [1:0]  all_bank    [0:`PATNUM*4-1];

// =====================================================================
//  Pre-computed golden answer storage
//  (populated after input_task, consumed by collect_and_check_task)
// =====================================================================
reg [63:0]  exp_out_data [0:1025];
reg [15:0]  root_addr    [0:3];
integer     exp_out_num;          // total expected outputs for this pattern

// =====================================================================
//  Spec violation flags
// =====================================================================
integer main1, main2, main3, main4, main5;

// ---- clk2 AXI flags ----
integer axi1_clk2, axi2_clk2, axi4_clk2, axi5_clk2, axi6_clk2;

// ---- clk3 AXI flags ----
integer axi1_clk3, axi2_clk3, axi4_clk3, axi5_clk3, axi6_clk3;

// =====================================================================
//  Clock generation
// =====================================================================
initial clk1 = 0;
always #(CYCLE_clk1 / 2.0) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE_clk2 / 2.0) clk2 = ~clk2;

initial clk3 = 0;
always #(CYCLE_clk3 / 2.0) clk3 = ~clk3;

// =====================================================================
//  Spec-violation monitor (clk1 negedge)
// =====================================================================
always @(negedge clk1) begin
    if (main1 === 1) begin
        $display("*************************************************************************");
        $display("*                         SPEC MAIN-1 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    if (main2 === 1) begin
        $display("*************************************************************************");
        $display("*                         SPEC MAIN-2 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    if (main3 === 1) begin
        $display("*************************************************************************");
        $display("*                         SPEC MAIN-3 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    if (main4 === 1) begin
        $display("*************************************************************************");
        $display("*                         SPEC MAIN-4 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    if (main5 === 1) begin
        $display("*************************************************************************");
        $display("*                         SPEC MAIN-5 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
end

// =====================================================================
//  AXI-clk2 checker  (read-only: AR + R channels)
// =====================================================================

always @(negedge clk2) begin
    if (ar_valid_clk2 === 0 && ar_addr_clk2 !== 0) begin
        axi1_clk2 = 1;
        $display("[clk2] AXI-1: ar_valid=0 but ar_addr=%0h", ar_addr_clk2);
    end
    if (r_valid_clk2 === 0 && (r_data_clk2 !== 0)) begin
        axi1_clk2 = 1;
        $display("[clk2] AXI-1: r_valid=0 but r_data=%0h", r_data_clk2);
    end
end

reg [31:0]  prev_ar_addr_clk2;
reg         start_ar_addr_clk2;
integer     wait_ar_ready_clk2;

always @(posedge clk2 or negedge rst_n) begin
    if (!rst_n) begin
        prev_ar_addr_clk2   <= 0;
        start_ar_addr_clk2  <= 0;
        wait_ar_ready_clk2  <= 0;
    end else begin
        if (start_ar_addr_clk2 && !ar_valid_clk2 && !ar_ready_clk2) begin
            axi2_clk2 = 1;
            $display("[clk2] AXI-2: ar_valid deasserted before ar_ready; prev_ar_addr=%0h", prev_ar_addr_clk2);
        end
        if (ar_valid_clk2 && !ar_ready_clk2) begin
            if (start_ar_addr_clk2 && ar_addr_clk2 != prev_ar_addr_clk2) begin
                axi2_clk2 = 1;
                $display("[clk2] AXI-2: ar_addr changed during handshake: %0h -> %0h",
                         prev_ar_addr_clk2, ar_addr_clk2);
            end
            prev_ar_addr_clk2  <= ar_addr_clk2;
            start_ar_addr_clk2 <= 1;
            wait_ar_ready_clk2 <= wait_ar_ready_clk2 + 1;
            if (wait_ar_ready_clk2 >= 500) begin
                axi5_clk2 = 1;
                $display("[clk2] AXI-5: ar_ready not asserted within 500 cycles");
            end
        end else begin
            start_ar_addr_clk2 <= 0;
            prev_ar_addr_clk2  <= 0;
            wait_ar_ready_clk2 <= 0;
        end
    end
end

always @(posedge clk2 or negedge rst_n) begin
    if (!rst_n) begin
    end else begin
        if (ar_valid_clk2 && (ar_addr_clk2 > 32'hFFFF)) begin
            axi4_clk2 = 1;
            $display("[clk2] AXI-4: ar_addr out of range: %0h", ar_addr_clk2);
        end
    end
end

reg         start_r_clk2;
reg [63:0]  prev_r_data_clk2;
integer     wait_r_ready_clk2;

always @(posedge clk2 or negedge rst_n) begin
    if (!rst_n) begin
        start_r_clk2       <= 0;
        prev_r_data_clk2   <= 0;
        wait_r_ready_clk2  <= 0;
    end else begin
        if (start_r_clk2 && !r_valid_clk2 && !r_ready_clk2) begin
            axi2_clk2 = 1;
            $display("[clk2] AXI-2: r_valid deasserted before r_ready; prev_r_data=%0h", prev_r_data_clk2);
        end
        if (r_valid_clk2 && !r_ready_clk2) begin
            if (start_r_clk2 && r_data_clk2 != prev_r_data_clk2) begin
                axi2_clk2 = 1;
                $display("[clk2] AXI-2: r_data changed during handshake: %0h -> %0h",
                         prev_r_data_clk2, r_data_clk2);
            end
            prev_r_data_clk2  <= r_data_clk2;
            start_r_clk2      <= 1;
            wait_r_ready_clk2 <= wait_r_ready_clk2 + 1;
            if (wait_r_ready_clk2 >= 500) begin
                axi5_clk2 = 1;
                $display("[clk2] AXI-5: r_ready not asserted within 500 cycles");
            end
        end else begin
            start_r_clk2      <= 0;
            prev_r_data_clk2  <= 0;
            wait_r_ready_clk2 <= 0;
        end
    end
end

integer ar_has_communicate_clk2;
integer r_vr_has_response_clk2;
integer wait_r_vr_response_clk2;

always @(posedge clk2 or negedge rst_n) begin
    if (!rst_n) begin
        ar_has_communicate_clk2 <= 0;
        r_vr_has_response_clk2  <= 0;
    end else begin
        if (ar_valid_clk2 && ar_ready_clk2 && !(r_valid_clk2 && r_ready_clk2)) begin
            ar_has_communicate_clk2 <= 1;
        end else if (ar_has_communicate_clk2 && r_valid_clk2 && r_ready_clk2) begin
            ar_has_communicate_clk2 <= 0;
            r_vr_has_response_clk2  <= 1;
        end else begin
            r_vr_has_response_clk2 <= 0;
        end
    end
end

always @(posedge clk2 or negedge rst_n) begin
    if (!rst_n) begin
        wait_r_vr_response_clk2 <= 0;
    end else begin
        if (ar_has_communicate_clk2 && r_vr_has_response_clk2 === 0) begin
            wait_r_vr_response_clk2 <= wait_r_vr_response_clk2 + 1;
            if (wait_r_vr_response_clk2 >= 500) begin
                axi6_clk2 = 1;
                $display("[clk2] AXI-6: No r response within 500 cycles after ar handshake");
            end
        end else begin
            wait_r_vr_response_clk2 <= 0;
        end
    end
end

always @(negedge clk2) begin
    if (axi1_clk2 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-1 (clk2) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi2_clk2 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-2 (clk2) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi4_clk2 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-4 (clk2) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi5_clk2 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-5 (clk2) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi6_clk2 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-6 (clk2) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
end

// =====================================================================
//  AXI-clk3 checker  (read-only: AR + R channels)
// =====================================================================

always @(negedge clk3) begin
    if (ar_valid_clk3 === 0 && ar_addr_clk3 !== 0) begin
        axi1_clk3 = 1;
        $display("[clk3] AXI-1: ar_valid=0 but ar_addr=%0h", ar_addr_clk3);
    end
    if (r_valid_clk3 === 0 && (r_data_clk3 !== 0)) begin
        axi1_clk3 = 1;
        $display("[clk3] AXI-1: r_valid=0 but r_data=%0h", r_data_clk3);
    end
end

reg [31:0]  prev_ar_addr_clk3;
reg         start_ar_addr_clk3;
integer     wait_ar_ready_clk3;

always @(posedge clk3 or negedge rst_n) begin
    if (!rst_n) begin
        prev_ar_addr_clk3   <= 0;
        start_ar_addr_clk3  <= 0;
        wait_ar_ready_clk3  <= 0;
    end else begin
        if (start_ar_addr_clk3 && !ar_valid_clk3 && !ar_ready_clk3) begin
            axi2_clk3 = 1;
            $display("[clk3] AXI-2: ar_valid deasserted before ar_ready; prev_ar_addr=%0h", prev_ar_addr_clk3);
        end
        if (ar_valid_clk3 && !ar_ready_clk3) begin
            if (start_ar_addr_clk3 && ar_addr_clk3 != prev_ar_addr_clk3) begin
                axi2_clk3 = 1;
                $display("[clk3] AXI-2: ar_addr changed during handshake: %0h -> %0h",
                         prev_ar_addr_clk3, ar_addr_clk3);
            end
            prev_ar_addr_clk3  <= ar_addr_clk3;
            start_ar_addr_clk3 <= 1;
            wait_ar_ready_clk3 <= wait_ar_ready_clk3 + 1;
            if (wait_ar_ready_clk3 >= 500) begin
                axi5_clk3 = 1;
                $display("[clk3] AXI-5: ar_ready not asserted within 500 cycles");
            end
        end else begin
            start_ar_addr_clk3 <= 0;
            prev_ar_addr_clk3  <= 0;
            wait_ar_ready_clk3 <= 0;
        end
    end
end

always @(posedge clk3 or negedge rst_n) begin
    if (!rst_n) begin
    end else begin
        if (ar_valid_clk3 && (ar_addr_clk3 > 32'hFFFF)) begin
            axi4_clk3 = 1;
            $display("[clk3] AXI-4: ar_addr out of range: %0h", ar_addr_clk3);
        end
    end
end

reg         start_r_clk3;
reg [63:0]  prev_r_data_clk3;
integer     wait_r_ready_clk3;

always @(posedge clk3 or negedge rst_n) begin
    if (!rst_n) begin
        start_r_clk3       <= 0;
        prev_r_data_clk3   <= 0;
        wait_r_ready_clk3  <= 0;
    end else begin
        if (start_r_clk3 && !r_valid_clk3 && !r_ready_clk3) begin
            axi2_clk3 = 1;
            $display("[clk3] AXI-2: r_valid deasserted before r_ready; prev_r_data=%0h", prev_r_data_clk3);
        end
        if (r_valid_clk3 && !r_ready_clk3) begin
            if (start_r_clk3 && r_data_clk3 != prev_r_data_clk3) begin
                axi2_clk3 = 1;
                $display("[clk3] AXI-2: r_data changed during handshake: %0h -> %0h",
                         prev_r_data_clk3, r_data_clk3);
            end
            prev_r_data_clk3  <= r_data_clk3;
            start_r_clk3      <= 1;
            wait_r_ready_clk3 <= wait_r_ready_clk3 + 1;
            if (wait_r_ready_clk3 >= 500) begin
                axi5_clk3 = 1;
                $display("[clk3] AXI-5: r_ready not asserted within 500 cycles");
            end
        end else begin
            start_r_clk3      <= 0;
            prev_r_data_clk3  <= 0;
            wait_r_ready_clk3 <= 0;
        end
    end
end

integer ar_has_communicate_clk3;
integer r_vr_has_response_clk3;
integer wait_r_vr_response_clk3;

always @(posedge clk3 or negedge rst_n) begin
    if (!rst_n) begin
        ar_has_communicate_clk3 <= 0;
        r_vr_has_response_clk3  <= 0;
    end else begin
        if (ar_valid_clk3 && ar_ready_clk3 && !(r_valid_clk3 && r_ready_clk3)) begin
            ar_has_communicate_clk3 <= 1;
        end else if (ar_has_communicate_clk3 && r_valid_clk3 && r_ready_clk3) begin
            ar_has_communicate_clk3 <= 0;
            r_vr_has_response_clk3  <= 1;
        end else begin
            r_vr_has_response_clk3 <= 0;
        end
    end
end

always @(posedge clk3 or negedge rst_n) begin
    if (!rst_n) begin
        wait_r_vr_response_clk3 <= 0;
    end else begin
        if (ar_has_communicate_clk3 && r_vr_has_response_clk3 === 0) begin
            wait_r_vr_response_clk3 <= wait_r_vr_response_clk3 + 1;
            if (wait_r_vr_response_clk3 >= 500) begin
                axi6_clk3 = 1;
                $display("[clk3] AXI-6: No r response within 500 cycles after ar handshake");
            end
        end else begin
            wait_r_vr_response_clk3 <= 0;
        end
    end
end

always @(negedge clk3) begin
    if (axi1_clk3 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-1 (clk3) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi2_clk3 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-2 (clk3) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi4_clk3 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-4 (clk3) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi5_clk3 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-5 (clk3) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
    if (axi6_clk3 === 1) begin
        $display("*************************************************************************");
        $display("*                      SPEC AXI-6 (clk3) FAIL                          *");
        $display("*************************************************************************");
        $finish;
    end
end

// =====================================================================
//  Main simulation (clk1 domain)
// =====================================================================
initial begin
    rst_n         = 1'b1;
    in_mode_valid = 1'b0;
    in_mode       = 1'bx;
    in_valid      = 1'b0;
    in_bank       = 2'bx;
    in_src_row    = 6'bx;
    peak_cycle = 0;
    peak_cycle_patnum = 0;
    total_latency   = 0;
    passed_patterns = 0;
    failed_patterns = 0;
    main1 = 0; main2 = 0; main3 = 0; main4 = 0; main5 = 0;
    axi1_clk2 = 0; axi2_clk2 = 0; axi4_clk2 = 0; axi5_clk2 = 0; axi6_clk2 = 0;
    axi1_clk3 = 0; axi2_clk3 = 0; axi4_clk3 = 0; axi5_clk3 = 0; axi6_clk3 = 0;

    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;

    generate_testcase;
    reset_signal_task;

    #(CYCLE_clk1 * 3);
    $display("========================================================================");
    $display("Total Patterns  : %0d", `PATNUM);
    $display("========================================================================");

    for (patcount = 0; patcount < `PATNUM; patcount = patcount + 1) begin
        $display("------------------------------------------------------------------------");
        $display("  Testing Pattern %0d/%0d", patcount+1, `PATNUM);
        $display("------------------------------------------------------------------------");
        repeat($urandom_range(1, 3)) @(negedge clk1);

        // Step 1: send inputs
        input_task;

        // Step 2: compute golden answer into exp_out_data[] / exp_out_num
        //         (done BEFORE we watch the DUT output)
        calc_golden_task;

        // Step 3: wait for & collect all DUT outputs, check against golden
        collect_and_check_task;

        if (error_count == 0) begin
            passed_patterns = passed_patterns + 1;
            $display("  [PASS] Pattern %0d", patcount+1);
        end else begin
            failed_patterns = failed_patterns + 1;
            YOU_FAIL_task;
        end
    end

    YOU_PASS_task;
end

// =====================================================================
//  generate_testcase
// =====================================================================
task generate_testcase;
    integer gi;
    begin
        for (gi = 0; gi < `PATNUM; gi = gi + 1) begin
            all_mode[gi] = $urandom_range(1, 0);
            for (j = 0; j < 4; j = j + 1) begin
                all_bank[gi*4+j]    = $urandom_range(0, 3);
                all_src_row[gi*4+j] = $urandom_range(0, 63);
            end
        end
    end
endtask

// =====================================================================
//  reset_signal_task
// =====================================================================
task reset_signal_task;
    begin
        #(CYCLE_clk1); rst_n = 0;
        #200;
        if (out_valid !== 1'b0 || out_data !== 64'b0) begin
            main1 = 1;
        end
        #(CYCLE_clk1);
        rst_n = 1;
        #(CYCLE_clk1);
        release clk1;
        release clk2;
        release clk3;
    end
endtask

// =====================================================================
//  input_task  (clk1 domain)
//  Only drives inputs; does NOT compute golden answer here.
// =====================================================================
task input_task;
    integer ii;
    begin
        error_count = 0;

        in_mode_valid = 1'b1;
        in_mode       = all_mode[patcount];
        @(negedge clk1);
        in_mode_valid = 1'b0;
        in_mode       = 1'bx;

        for (ii = 0; ii < 4; ii = ii + 1) begin
            in_valid   = 1'b1;
            in_bank    = all_bank[patcount*4+ii];
            in_src_row = all_src_row[patcount*4+ii];
            @(negedge clk1);
        end

        in_valid   = 1'b0;
        in_bank    = 2'bx;
        in_src_row = 6'bx;
    end
endtask

// =====================================================================
//  calc_golden_task
//  Computes exp_out_data[0..exp_out_num-1] for the current pattern.
//  Called after input_task, before watching DUT outputs.
// =====================================================================
task calc_golden_task;
    begin
        exp_out_num = 0;
        if (all_mode[patcount] === 0) begin
            calc_golden_calc_mode;
        end else begin
            calc_golden_gauss_mode;
        end
        $display("  Golden computed: exp_out_num = %0d", exp_out_num);
    end
endtask

// ---- CALC mode golden ----
reg signed [63:0] expected_calc_result [0:3];
reg signed [63:0] node_value [0:65535];
reg               node_done  [0:65535];

task calc_golden_calc_mode;
    integer b;
    reg [15:0] root_ptr;
    begin
        for (b = 0; b < 4; b = b + 1) begin
            root_ptr = {all_bank[patcount*4+b], all_src_row[patcount*4+b], 8'h00};
            calc_tree_no_recursive_task(root_ptr, expected_calc_result[b]);
            exp_out_data[b] = expected_calc_result[b];
            root_addr[b] = root_ptr;
        end
        exp_out_num = 4;
    end
endtask

task calc_tree_no_recursive_task;
    input  [15:0]            root_addr;
    output reg signed [63:0] result;

    reg [15:0] stack_addr   [0:511];
    reg        stack_expand [0:511];
    integer    sp;
    reg [15:0] cur_addr;
    reg        cur_expand;
    reg [63:0] node;
    reg [1:0]  opcode;
    reg [15:0] left_ptr, right_ptr;
    reg signed [63:0] left_val, right_val;
    integer kk;
    begin
        for (kk = 0; kk < 65536; kk = kk + 1) begin
            node_done[kk]  = 1'b0;
            node_value[kk] = 64'sd0;
        end

        sp = 0;
        stack_addr[sp]   = root_addr;
        stack_expand[sp] = 1'b0;
        sp = sp + 1;

        while (sp > 0) begin
            sp = sp - 1;
            cur_addr   = stack_addr[sp];
            cur_expand = stack_expand[sp];

            if (!node_done[cur_addr]) begin
                node = golden_DRAM[cur_addr];

                if (node[63] == 1'b0) begin
                    node_value[cur_addr] = {{33{node[62]}}, node[62:32]};
                    node_done[cur_addr]  = 1'b1;
                end else begin
                    opcode    = node[33:32];
                    left_ptr  = node[31:16];
                    right_ptr = node[15:0];

                    if (!cur_expand) begin
                        stack_addr[sp]   = cur_addr;
                        stack_expand[sp] = 1'b1;
                        sp = sp + 1;
                        if (!node_done[right_ptr]) begin
                            stack_addr[sp]   = right_ptr;
                            stack_expand[sp] = 1'b0;
                            sp = sp + 1;
                        end
                        if (!node_done[left_ptr]) begin
                            stack_addr[sp]   = left_ptr;
                            stack_expand[sp] = 1'b0;
                            sp = sp + 1;
                        end
                    end else begin
                        left_val  = node_value[left_ptr];
                        right_val = node_value[right_ptr];
                        case (opcode)
                            2'b00: node_value[cur_addr] = left_val + right_val;
                            2'b01: node_value[cur_addr] = left_val - right_val;
                            2'b10: node_value[cur_addr] = left_val * right_val;
                            2'b11: node_value[cur_addr] = left_val >>> right_val[5:0];
                            default: node_value[cur_addr] = 64'sd0;
                        endcase
                        node_done[cur_addr] = 1'b1;
                    end
                end
            end
        end

        result = node_value[root_addr];
    end
endtask
// ---- GAUSS mode golden ----
reg  [63:0]   gauss_words    [0:1023];
reg           gauss_valid    [0:1023];
reg  [30:0]   gauss_val      [0:1023];   // 31-bit unsigned, 維持原樣
reg           gauss_filter   [0:1023];
integer       gauss_N;

// integer (floor) versions — 與 RTL bit-exact
integer              gauss_mean_int;     // floor(sum / N), unsigned 結果但用 integer 容納
reg  [71:0]          gauss_sum_sq_int;   // sum of (diff)^2,  72-bit
reg  [71:0]          gauss_sigma2_int;   // floor(sum_sq / N)

// real versions — debug 印出來看用
real          gauss_mu;
real          gauss_sigma2;
real          gauss_sigma;

integer       gauss_debug_fp;
task calc_golden_gauss_mode;
    integer col, bank_idx, addr16;
    integer vv;

    // integer arithmetic versions (match RTL)
    reg  [41:0]          sum_val_int;       // 31-bit × 1024 ≤ 2^41，41-bit 夠，給 42-bit 保險
    integer signed       diff_int;
    reg  [63:0]          diff_sq_int;
    integer              filter_cnt;
    integer              last_already_output;
    begin
        gauss_debug_fp = $fopen("../00_TESTBED/gauss_debug.txt", "w");

        if (gauss_debug_fp == 0) begin
            $display("[ERROR] Failed to open gauss_debug.txt");
            $finish;
        end

        $fdisplay(gauss_debug_fp, "========== GAUSS DEBUG ==========");
        $fdisplay(gauss_debug_fp, "patcount = %0d", patcount);
        $fdisplay(gauss_debug_fp, "");

        gauss_N      = 0;
        sum_val_int  = 42'd0;

        for (bank_idx = 0; bank_idx < 4; bank_idx = bank_idx + 1) begin
            for (col = 0; col < 256; col = col + 1) begin
                addr16 = (all_bank[patcount*4+bank_idx]  << 14) |
                         (all_src_row[patcount*4+bank_idx] << 8) |
                         col;

                vv = bank_idx * 256 + col;

                gauss_words[vv]  = golden_DRAM[addr16];
                gauss_valid[vv]  = (golden_DRAM[addr16][63] == 1'b0) ? 1 : 0;
                gauss_val[vv]    = golden_DRAM[addr16][62:32];   // 31-bit unsigned
                gauss_filter[vv] = 0;

                if (gauss_valid[vv]) begin
                    gauss_N     = gauss_N + 1;
                    sum_val_int = sum_val_int + {11'b0, gauss_val[vv]};   // unsigned add
                end
            end
        end

        if (gauss_N == 0) begin
            gauss_mean_int   = 0;
            gauss_sum_sq_int = 72'd0;
            gauss_sigma2_int = 72'd0;
            gauss_mu         = 0.0;
            gauss_sigma2     = 0.0;
            gauss_sigma      = 0.0;
        end
        else begin
            // mean: integer floor division (unsigned)
            gauss_mean_int = sum_val_int / gauss_N;

            // sum of squares
            gauss_sum_sq_int = 72'd0;
            for (vv = 0; vv < 1024; vv = vv + 1) begin
                if (gauss_valid[vv]) begin
                    diff_int         = $signed({1'b0, gauss_val[vv]}) - gauss_mean_int;
                    diff_sq_int      = diff_int * diff_int;             // diff^2 ≥ 0
                    gauss_sum_sq_int = gauss_sum_sq_int + diff_sq_int;
                end
            end

            gauss_sigma2_int = gauss_sum_sq_int / gauss_N;

            // real versions for debug print
            gauss_mu     = $itor(sum_val_int)      / $itor(gauss_N);
            gauss_sigma2 = $itor(gauss_sum_sq_int) / $itor(gauss_N);
            gauss_sigma  = $sqrt(gauss_sigma2);
        end
        `ifdef DEBUG
        $display("  GAUSS: N=%0d  mean_int=%0d  sigma2_int=%0d  (real mu=%.6f sigma=%.6f)",
                 gauss_N, gauss_mean_int, gauss_sigma2_int, gauss_mu, gauss_sigma);
                 
        $fdisplay(gauss_debug_fp, "valid count N        = %0d", gauss_N);
        $fdisplay(gauss_debug_fp, "sum (int)            = %0d", sum_val_int);
        $fdisplay(gauss_debug_fp, "mean (int floor)     = %0d", gauss_mean_int);
        $fdisplay(gauss_debug_fp, "mu   (real)          = %.6f", gauss_mu);
        $fdisplay(gauss_debug_fp, "sum_sq (int)         = %0d", gauss_sum_sq_int);
        $fdisplay(gauss_debug_fp, "sigma2 (int floor)   = %0d", gauss_sigma2_int);
        $fdisplay(gauss_debug_fp, "sigma2 (real)        = %.6f", gauss_sigma2);
        $fdisplay(gauss_debug_fp, "sigma  (real)        = %.6f", gauss_sigma);
        $fdisplay(gauss_debug_fp, "");
        $fdisplay(gauss_debug_fp, "Formula used (matches RTL, integer arithmetic):");
        $fdisplay(gauss_debug_fp, "  (Word_i - mean_int)^2 <= sigma2_int");
        $fdisplay(gauss_debug_fp, "  where mean_int   = floor(sum / N)");
        $fdisplay(gauss_debug_fp, "        sigma2_int = floor(sum_sq / N)");
        $fdisplay(gauss_debug_fp, "");
        $fdisplay(gauss_debug_fp, "idx | addr16 | word_hex          | valid |     value     |     diff      |    diff^2    | filter | gauss_sum_sq_int|");
        $fdisplay(gauss_debug_fp, "----+--------+-------------------+-------+---------------+---------------+--------------+--------+--------");
        `endif
        filter_cnt = 0;
        gauss_sum_sq_int = 0;
        for (vv = 0; vv < 1024; vv = vv + 1) begin
            bank_idx = vv / 256;
            col      = vv % 256;
            addr16   = (all_bank[patcount*4+bank_idx]  << 14) |
                       (all_src_row[patcount*4+bank_idx] << 8) |
                       col;

            if (gauss_valid[vv]) begin
                diff_int    = $signed({1'b0, gauss_val[vv]}) - gauss_mean_int;
                diff_sq_int = diff_int * diff_int;
                gauss_sum_sq_int = gauss_sum_sq_int + diff_sq_int;

                if (diff_sq_int <= gauss_sigma2_int) begin
                    gauss_filter[vv] = 1;
                    filter_cnt = filter_cnt + 1;
                end

                $fdisplay(gauss_debug_fp,
                    "%4d | %6h | %16h |   %1d   | %13d | %13d | %12d |   %1d | %16d |",
                    vv,
                    addr16,
                    gauss_words[vv],
                    gauss_valid[vv],
                    gauss_val[vv],
                    diff_int,
                    diff_sq_int,
                    gauss_filter[vv],
                    gauss_sum_sq_int
                );
            end
            else begin
                $fdisplay(gauss_debug_fp,
                    "%4d | %6h | %16h |   %1d   |       X       |       X       |       X      |   0|x|",
                    vv,
                    addr16,
                    gauss_words[vv],
                    gauss_valid[vv]
                );
            end
        end

        exp_out_num         = 0;
        last_already_output = 0;

        for (vv = 0; vv < 1024; vv = vv + 1) begin
            if (gauss_filter[vv]) begin
                exp_out_data[exp_out_num] = gauss_words[vv];
                exp_out_num = exp_out_num + 1;
                if (vv == 1023) last_already_output = 1;
            end
        end

        if (!last_already_output) begin
            exp_out_data[exp_out_num] = gauss_words[1023];
            exp_out_num = exp_out_num + 1;
        end

        $fdisplay(gauss_debug_fp, "");
        $fdisplay(gauss_debug_fp, "========== SUMMARY ==========");
        $fdisplay(gauss_debug_fp, "valid count N       = %0d", gauss_N);
        $fdisplay(gauss_debug_fp, "filtered count      = %0d", filter_cnt);
        $fdisplay(gauss_debug_fp, "last already output = %0d", last_already_output);
        $fdisplay(gauss_debug_fp, "exp_out_num         = %0d", exp_out_num);
        $fdisplay(gauss_debug_fp, "last word[1023]     = %16h", gauss_words[1023]);

        $fclose(gauss_debug_fp);
    end
endtask

// =====================================================================
//  collect_and_check_task
//
//  Supports NON-CONSECUTIVE out_valid for BOTH modes.
//
//  Flow:
//    - Wait for out_valid to go high (with timeout → main2)
//    - Each cycle out_valid is high: consume one output, compare to golden
//    - Keep a running cycle counter (latency) from the first cycle after
//      input_task until the last out_valid cycle (inclusive)
//    - After collecting exp_out_num outputs, verify out_valid drops low
// =====================================================================

task collect_and_check_task;
    
    begin
        collected     = 0;
        wait_val_time = 0;
        `ifdef DEBUG
        for(integer p = 0; p <= 3;p = p + 1)begin
                        $display("in_bank = %x, in_src_row = %x",
                                all_bank[patcount*4+p], all_src_row[patcount*4+p]);
                        end
        `endif 
        while (collected < exp_out_num) begin

            while (out_valid !== 1'b1) begin
                wait_val_time = wait_val_time + 1;
                if (wait_val_time > `MAX_LATENCY) begin
                    main2 = 1;
                end
                @(negedge clk1);
            end

            // out_valid === 1: counts toward latency & timeout
            wait_val_time = wait_val_time + 1;
            if (wait_val_time > `MAX_LATENCY) begin
                main2 = 1;
            end
            if(wait_val_time > peak_cycle)begin
                peak_cycle = wait_val_time;
                peak_cycle_patnum = patcount;
            end
            // compare
            
            if (out_data !== exp_out_data[collected]) begin
                if (all_mode[patcount] === 0)begin
                    $display("  CALC FAIL root address=%x, [output %0d]: expect=%x got=%x",
                            root_addr[collected], collected, $signed(exp_out_data[collected]),
                             $signed(out_data));
                    
                end
                else
                    $display("  GAUSS FAIL [output %0d]: expect=%0h got=%0h",
                             collected, exp_out_data[collected], out_data);
                error_count = error_count + 1;
                main4 = 1;
            end
            `ifdef DEBUG
                // else begin
                // $display("  CALC pass, root address=%x, [output %0d]: expect=%x got=%x",
                //                 root_addr[collected], collected, $signed(exp_out_data[collected]),
                //                 $signed(out_data));
                // end
            `endif
            collected = collected + 1;

            @(negedge clk1);
        end

        total_latency = total_latency + wait_val_time;
        $display("  All %0d outputs collected, latency = %0d cycles",
                 exp_out_num, wait_val_time);

        if (out_valid !== 1'b0) begin
            $display("  FAIL: out_valid still high after last expected output");
            error_count = error_count + 1;
            main3 = 1;
        end
    end
endtask

// =====================================================================
//  Pass / Fail tasks
// =====================================================================
task YOU_PASS_task;
    real avg_latency;
    begin
        avg_latency = total_latency * 1.0 / `PATNUM;

        $display("*************************************************************************");
        $display("*                         Congratulations!                              *");
        $display("*            Your execution cycles = %5d cycles               *", total_latency);
            $display("*            Average cycles        = %.2f cycles              *", avg_latency);
            $display("*            Peak cycles at patnum:%d=%d cycles              *", peak_cycle_patnum, peak_cycle);
        $display("*            Your clock period     = %.1f ns                    *", CYCLE_clk1);
        $display("*            Total Latency         = %.1f ns                    *",
                 total_latency * CYCLE_clk1);
        $display("*************************************************************************");
        if (avg_latency > 8000.0) begin
            $display("*************************************************************************");
            $display("*                         Ha Ha!                                        *");
            $display("*                  You did not achieve the GOAL!                        *");
            $display("*            Average cycles        = %.2f cycles              *", avg_latency);
            $display("*                  Average cycles > 8000 cycles                         *");
            $display("*            (Ignore this message when it isn't Period_3)                        *");
            $display("*************************************************************************");
        end
        else begin
            $display("*************************************************************************");
            $display("*                         Great Job!                                    *");
            $display("*                    Congratulations! GOAL Passed!                      *");
            $display("*            Average cycles        = %.2f cycles              *", avg_latency);
            $display("*                  Average cycles <= 8000 cycles                        *");
            $display("*            (Ignore this message when it isn't Period_3)                        *");
            $display("*************************************************************************");
        end

        $finish;
    end
endtask

task YOU_FAIL_task;
    begin
        $display("*                              FAIL!                                    *");
        $display("*                    Error message from PATTERN.v                       *");
    end
endtask

endmodule