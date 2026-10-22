`define CYCLE_TIME 7.0

// ============================================================
// Checkpoint select
// ============================================================

module PATTERN(
    // output signals
    clk,
    rst_n,
    i_valid,
    i_iter,
    i_mode,
    i_data,
    i_weight,

    // input signals
    o_valid,
    o_data
);

// ========================================
// I/O declaration
// ========================================
// Output
output reg          clk;
output reg          rst_n;
output reg          i_valid;
output reg    [2:0] i_iter;
output reg    [1:0] i_mode;
output reg    [7:0] i_data;
output reg    [3:0] i_weight;

// Input
input               o_valid;
input         [7:0] o_data;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

// ========================================
// integer & parameter
// ========================================
parameter PATNUM               = 20;
parameter TOTAL_WEIGHT_NUM     = 1312;
parameter TOTAL_IMAGE_NUM      = 4096;
parameter MAX_OUTPUT_SIZE      = 4096;
parameter MAX_LATENCY          = 150000;

parameter INPUT_FILE           = "../00_TESTBED/testcase.txt";
parameter FINAL_GOLDEN_FILE    = "../00_TESTBED/answer.txt";

localparam integer CHECK_OUTPUT_SIZE = 4096;

// ========================================
// wire & reg
// ========================================
integer patcount, total_latency, latency_cnt;
integer i, j;
integer output_count;
integer error_count;
integer passed_patterns;
integer failed_patterns;
integer code;
integer fd;

reg [3:0] all_weight_data [0:TOTAL_WEIGHT_NUM-1];
reg [2:0] all_iter_data   [0:PATNUM-1];
reg [1:0] all_mode_data   [0:PATNUM-1];
reg [7:0] all_image_data  [0:PATNUM*TOTAL_IMAGE_NUM-1];
reg [7:0] all_golden_data [0:PATNUM*MAX_OUTPUT_SIZE-1];

reg [3:0] current_weight  [0:TOTAL_WEIGHT_NUM-1];
reg [2:0] current_iter;
reg [1:0] current_mode;
reg [7:0] current_image   [0:TOTAL_IMAGE_NUM-1];
reg [7:0] current_golden  [0:MAX_OUTPUT_SIZE-1];
reg [7:0] received_output [0:MAX_OUTPUT_SIZE-1];

// ================================================================
// design
// ================================================================
initial begin
    rst_n           = 1'b1;
    i_valid         = 1'b0;
    i_iter          = 'bx;
    i_mode          = 'bx;
    i_data          = 'bx;
    i_weight        = 'bx;

    force clk = 0;

    total_latency   = 0;
    latency_cnt     = 0;
    output_count    = 0;
    error_count     = 0;
    passed_patterns = 0;
    failed_patterns = 0;

    load_test_data;
    reset_signal_task;

    // #(CYCLE*3);
    @(negedge clk);
    $display("============================================================");
    $display("LAB5 PATTERN START");
    $display("PATNUM            = %0d", PATNUM);
    $display("CHECK_OUTPUT_SIZE = %0d", CHECK_OUTPUT_SIZE);
    $display("CHECKPOINT        = FINAL");
    $display("GOLDEN FILE       = %s", FINAL_GOLDEN_FILE);
    $display("============================================================");

    for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
        
        extract_pattern(patcount);

        output_count = 0;
        error_count  = 0;

        input_task;
        wait_out_valid_task;
        check_ans_task;

        if (error_count == 0) begin
            passed_patterns = passed_patterns + 1;
            // $display("[PASS] Pattern %0d passed.", patcount+1);
        end
        else begin
            failed_patterns = failed_patterns + 1;
            $display("[FAIL] Pattern %0d failed. error_count = %0d", patcount+1, error_count);
            $finish;
        end
        repeat($urandom_range(1,3)) @(negedge clk);
    end

    YOU_PASS_task;
end

// ================================================================
// Rule 1: when o_valid = 0, o_data must be 0
// ================================================================
always @(negedge clk) begin
    if (o_valid === 1'b0 && o_data !== 8'b0) begin
        $display("------------------------------------------------------------");
        $display("FAIL! o_data should be 0 when o_valid is low.");
        $display("Time = %0t, o_data = %h", $time, o_data);
        $display("------------------------------------------------------------");
        repeat(2) #(CYCLE);
        $finish;
    end
end

// ================================================================
// Rule 2: i_valid and o_valid cannot overlap
// ================================================================
// always @(negedge clk) begin
//     if (i_valid === 1'b1 && o_valid === 1'b1) begin
//         $display("------------------------------------------------------------");
//         $display("FAIL! i_valid and o_valid cannot overlap.");
//         $display("Time = %0t", $time);
//         $display("i_valid = %b, o_valid = %b", i_valid, o_valid);
//         $display("------------------------------------------------------------");
//         repeat(2) #(CYCLE);
//         $finish;
//     end
// end

// ================================================================
// Capture output
// o_valid does NOT need to be continuous
// only total CHECK_OUTPUT_SIZE outputs are required
// ================================================================
always @(negedge clk) begin
    if (o_valid === 1'b1) begin
        if (output_count < CHECK_OUTPUT_SIZE) begin
            received_output[output_count] = o_data;
            output_count = output_count + 1;
        end
        else begin
            $display("------------------------------------------------------------");
            $display("FAIL! Output count exceeds expected size.");
            $display("Time = %0t", $time);
            $display("CHECK_OUTPUT_SIZE = %0d", CHECK_OUTPUT_SIZE);
            $display("------------------------------------------------------------");
            repeat(2) #(CYCLE);
            $finish;
        end
    end
end

// testcase format:
//   shared 1312 x 4-bit weight (only once at file beginning)
//   then for each pattern:
//     1 line iter
//     1 line mode
//     4096 x 8-bit image data
task load_test_data;
    integer p, idx_w, idx_img;
    reg [3:0] tmp_weight;
    reg [2:0] tmp_iter;
    reg [1:0] tmp_mode;
    reg [7:0] tmp_data;
begin
    $display("Input file : %s", INPUT_FILE);

    fd = $fopen(INPUT_FILE, "r");
    if (fd == 0) begin
        $display("FAIL! Cannot open input file: %s", INPUT_FILE);
        $finish;
    end

    // ========================================================
    // Read one shared weight block first
    // ========================================================
    for (idx_w = 0; idx_w < TOTAL_WEIGHT_NUM; idx_w = idx_w + 1) begin
        code = $fscanf(fd, "%h", tmp_weight);
        if (code != 1) begin
            $display("FAIL! Cannot read shared weight, idx %0d", idx_w);
            $finish;
        end
        all_weight_data[idx_w] = tmp_weight;
    end

    // ========================================================
    // Then read PATNUM patterns: iter, mode, image
    // ========================================================
    for (p = 0; p < PATNUM; p = p + 1) begin
        code = $fscanf(fd, "%h", tmp_iter);
        if (code != 1) begin
            $display("FAIL! Cannot read iter at pattern %0d", p);
            $finish;
        end
        all_iter_data[p] = tmp_iter;

        code = $fscanf(fd, "%h", tmp_mode);
        if (code != 1) begin
            $display("FAIL! Cannot read mode at pattern %0d", p);
            $finish;
        end
        all_mode_data[p] = tmp_mode;

        for (idx_img = 0; idx_img < TOTAL_IMAGE_NUM; idx_img = idx_img + 1) begin
            code = $fscanf(fd, "%h", tmp_data);
            if (code != 1) begin
                $display("FAIL! Cannot read image data at pattern %0d, idx %0d", p, idx_img);
                $finish;
            end
            all_image_data[p*TOTAL_IMAGE_NUM + idx_img] = tmp_data;
        end
    end

    $fclose(fd);

    $readmemh(FINAL_GOLDEN_FILE, all_golden_data);
end
endtask

// ================================================================
// extract one pattern
// ================================================================
task extract_pattern;
    input integer pattern_id;
    integer base_img, base_golden;
begin
    base_img    = pattern_id * TOTAL_IMAGE_NUM;
    base_golden = pattern_id * CHECK_OUTPUT_SIZE;

    for (j = 0; j < TOTAL_WEIGHT_NUM; j = j + 1) begin
        current_weight[j] = all_weight_data[j];
    end

    current_iter = all_iter_data[pattern_id];
    current_mode = all_mode_data[pattern_id];

    for (j = 0; j < TOTAL_IMAGE_NUM; j = j + 1) begin
        current_image[j] = all_image_data[base_img + j];
    end

    for (j = 0; j < CHECK_OUTPUT_SIZE; j = j + 1) begin
        current_golden[j] = all_golden_data[base_golden + j];
    end
end
endtask

// ================================================================
// reset task
// ================================================================
task reset_signal_task;
begin
    #(CYCLE);
    rst_n = 1'b0;
    #(CYCLE*3);
    rst_n = 1'b1;

    if ((o_valid !== 1'b0) || (o_data !== 8'b0)) begin
        $display("------------------------------------------------------------");
        $display("FAIL! Output signals should be reset to 0 after reset.");
        $display("Time = %0t, o_valid = %b, o_data = %h", $time, o_valid, o_data);
        $display("------------------------------------------------------------");
        $finish;
    end

    #(CYCLE);
    release clk;
end
endtask

// ================================================================
// input task
// 1. i_valid high for 1312 cycles, send i_weight
// 2. i_valid low for 1~3 cycles
// 3. i_valid high for 4096 cycles, send i_data
//    and send i_iter/i_mode only at the first cycle
// ================================================================
task input_task;
    integer gap;
begin
    // ========================================================
    // Send shared weight only once at the first pattern
    // ========================================================
    if (patcount == 0) begin
        i_valid  = 1'b1;
        i_iter   = 'bx;
        i_mode   = 'bx;
        i_data   = 'bx;

        for (i = 0; i < TOTAL_WEIGHT_NUM; i = i + 1) begin
            i_weight = current_weight[i];
            @(negedge clk);
        end

        i_valid  = 1'b0;
        i_weight = 'bx;

        gap = $urandom_range(1,3);
        repeat(gap) @(negedge clk);
    end

    // ========================================================
    // Image phase for every pattern
    // ========================================================
    i_valid  = 1'b1;
    i_weight = 'bx;

    for (i = 0; i < TOTAL_IMAGE_NUM; i = i + 1) begin
        i_data = current_image[i];

        if (i == 0) begin
            i_iter = current_iter;
            i_mode = current_mode;
        end
        else begin
            i_iter = 'bx;
            i_mode = 'bx;
        end

        @(negedge clk);
    end

    i_valid  = 1'b0;
    i_weight = 'bx;
    i_iter   = 'bx;
    i_mode   = 'bx;
    i_data   = 'bx;
    $display("pattern NO. %d: mode=%d, iter=%d, input done", patcount+1, current_mode, current_iter);
end
endtask

// ================================================================
// wait output task
// latency rule:
// measured from falling edge of the last i_valid cycle
// until all outputs are completed
// during this interval, only o_valid == 0 cycles are counted
// if o_valid pulls high immediately after input end, latency = 1
// ================================================================
task wait_out_valid_task;
begin
    latency_cnt = 0;

    while (output_count < CHECK_OUTPUT_SIZE) begin
        @(negedge clk);

        if (o_valid === 1'b0)
            latency_cnt = latency_cnt + 1;

        if (latency_cnt > MAX_LATENCY*current_iter) begin
            $display("------------------------------------------------------------");
            $display("FAIL! The execution latency is over %0d cycles.", MAX_LATENCY*current_iter);
            $display("Pattern = %0d", patcount+1);
            $display("Current output_count = %0d / %0d", output_count, CHECK_OUTPUT_SIZE);
            $display("------------------------------------------------------------");
            repeat(2) #(CYCLE);
            $finish;
        end
    end

    total_latency = total_latency + latency_cnt;
    $display("============================================================");
    $display("------------------------------------------------------------");
    $display("\033[1;32mpass Pattern %0d, Latency = %0d cycles\033[0m", patcount+1, latency_cnt);
    $display("------------------------------------------------------------");
    $display("============================================================");
    latency_cnt = 0;
    
end
endtask

// ================================================================
// check answer
// exact compare only
// ================================================================
task check_ans_task;
begin
    for (i = 0; i < CHECK_OUTPUT_SIZE; i = i + 1) begin
        if (received_output[i] !== current_golden[i]) begin
            error_count = error_count + 1;

            $display("Mismatch at index %0d", i);
            $display("  Golden : %h", current_golden[i]);
            $display("  Output : %h", received_output[i]);
        end
    end
end
endtask

task YOU_PASS_task;
begin
    $display("");
    $display("============================================================");
    $display("Congratulations! All patterns passed!");
    $display("Total execution cycles : %0d cycles", total_latency);
    $display("Clock period           : %.1f ns", CYCLE);
    $display("Total execution time   : %.1f ns", total_latency * CYCLE);
    $display("============================================================");
    $finish;
end
endtask

endmodule