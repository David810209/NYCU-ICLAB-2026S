
`define CYCLE_TIME 24.5

// `define PREPROCESS
// `define CONV_L1
// `define CONV_L2
// `define DECONV_L1
`define GOLDEN
`define NUMS_PATTERN 10
module PATTERN(
    // Output Port (To DUT)
    clk,
    rst_n,
    instruction_in_valid,
    image_in_valid,
    weight_in_valid,
    in_data,

    // Input Port (From DUT)
    out_valid,
    out_data
);

// ================================================================
// I/O declaration
// ================================================================
output reg        clk;
output reg        rst_n;
output reg        instruction_in_valid;
output reg        image_in_valid;
output reg        weight_in_valid;
output reg [31:0] in_data;

input             out_valid;
input      [31:0] out_data;

// ================================================================
// Parameters
// ================================================================
real CYCLE = `CYCLE_TIME;

parameter PATNUM               = `NUMS_PATTERN;

parameter TOTAL_INPUT_PIXELS   = 128;
parameter WEIGHT_SIZE          = 9;
parameter TOTAL_WEIGHTS        = 144;
parameter TOTAL_INSTRUCTIONS   = 1;

// file path
parameter INPUT_FILE              = "../00_TESTBED/testcase.txt";

parameter PREPROCESSING_GOLDEN    = "../00_TESTBED/after_conv0.txt";
parameter PREPROCESS_OUTPUT_SIZE  = 128;

parameter CONV_L1_GOLDEN          = "../00_TESTBED/after_activation0.txt";
parameter CONV_L1_OUTPUT_SIZE     = 32;

parameter CONV_L2_GOLDEN          = "../00_TESTBED/after_activation1.txt";
parameter CONV_L2_OUTPUT_SIZE     = 8;

parameter DECONV_L1_GOLDEN        = "../00_TESTBED/after_activation2.txt";
parameter DECONV_L1_OUTPUT_SIZE   = 32;

parameter OUTPUT_GOLDEN           = "../00_TESTBED/golden.txt";
parameter OUTPUT_SIZE             = 128;

parameter MAX_STAGE_OUTPUT_SIZE   = 128;
parameter MAX_LATENCY             = 1200;

// ================================================================
// Stage selection by define
// ================================================================
`ifdef PREPROCESS
    localparam integer CHECK_OUTPUT_SIZE = PREPROCESS_OUTPUT_SIZE;
`elsif CONV_L1
    localparam integer CHECK_OUTPUT_SIZE = CONV_L1_OUTPUT_SIZE;
`elsif CONV_L2
    localparam integer CHECK_OUTPUT_SIZE = CONV_L2_OUTPUT_SIZE;
`elsif DECONV_L1
    localparam integer CHECK_OUTPUT_SIZE = DECONV_L1_OUTPUT_SIZE;
`else
    localparam integer CHECK_OUTPUT_SIZE = OUTPUT_SIZE;
`endif

// ================================================================
// Memories / Registers
// input.txt format per pattern:
//   instr         x 1
//   weight        x 144
//   image/data    x 128
// total = 273 entries per pattern
// ================================================================
integer patcount, total_latency, wait_val_time;
integer i, j;

localparam integer INPUT_BLOCK_SIZE = TOTAL_INSTRUCTIONS + TOTAL_WEIGHTS + TOTAL_INPUT_PIXELS;

reg [31:0] all_input_stream     [0:PATNUM*INPUT_BLOCK_SIZE-1];
reg [31:0] all_golden_data      [0:PATNUM*MAX_STAGE_OUTPUT_SIZE-1];

reg [31:0] current_instruction  [0:TOTAL_INSTRUCTIONS-1];
reg [31:0] current_weight       [0:TOTAL_WEIGHTS-1];
reg [31:0] current_input        [0:TOTAL_INPUT_PIXELS-1];
reg [31:0] current_golden       [0:MAX_STAGE_OUTPUT_SIZE-1];

reg [31:0] received_output      [0:MAX_STAGE_OUTPUT_SIZE-1];

integer output_count;
integer error_count;
integer tolerant_error_count;
integer total_errors;
integer passed_patterns;
integer failed_patterns;

reg seen_out_valid;
reg burst_started;
reg burst_finished;

// ================================================================
// Clock generation
// ================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

// ================================================================
// Main flow
// ================================================================
initial begin
    rst_n                = 1'b1;
    instruction_in_valid = 1'b0;
    image_in_valid       = 1'b0;
    weight_in_valid      = 1'b0;
    in_data              = 32'bx;

    force clk = 0;

    total_latency   = 0;
    wait_val_time   = 0;
    output_count    = 0;
    error_count     = 0;
    tolerant_error_count = 0;
    total_errors    = 0;
    passed_patterns = 0;
    failed_patterns = 0;

    seen_out_valid  = 0;
    burst_started   = 0;
    burst_finished  = 0;

    load_test_data;
    reset_signal_task;

    #(CYCLE*3);

    $display("============================================================");
    $display("Total Patterns : %0d", PATNUM);
`ifdef PREPROCESS
    $display("Check Stage    : PREPROCESS");
`elsif CONV_L1
    $display("Check Stage    : CONV_L1");
`elsif CONV_L2
    $display("Check Stage    : CONV_L2");
`elsif DECONV_L1
    $display("Check Stage    : DECONV_L1");
`else
    $display("Check Stage    : OUTPUT");
`endif
    $display("Check Size     : %0d", CHECK_OUTPUT_SIZE);
    $display("============================================================");

    for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
        $display("");
        $display("------------------------------------------------------------");
        $display("Testing Pattern %0d / %0d", patcount+1, PATNUM);
        $display("------------------------------------------------------------");

        repeat($urandom_range(1, 3)) @(negedge clk);

        extract_pattern(patcount);

        output_count   = 0;
        error_count    = 0;
        tolerant_error_count = 0;
        seen_out_valid = 0;
        burst_started  = 0;
        burst_finished = 0;

        input_task;
        wait_out_valid_task;
        check_ans_task;

        if (error_count == 0) begin
            passed_patterns = passed_patterns + 1;
            $display("============================================================");
            $display("============================================================");
            $display("[PASS] Pattern %0d: all %0d outputs are correct.", patcount+1, CHECK_OUTPUT_SIZE);
            if (tolerant_error_count > 0) begin
                $display("Note: %0d tolerable mismatches found (<= 0.02 difference in float).",
                        tolerant_error_count);
            end
            $display("============================================================");
            $display("============================================================");
        end
        else begin
            failed_patterns = failed_patterns + 1;
            $display("[FAIL] Pattern %0d: %0d mismatches found.", patcount+1, error_count);
            $display("============================================================");
            $finish;
        end
    end

    YOU_PASS_task;
end

// ================================================================
// Rule 1: out_valid=0 => out_data must be 0
// ================================================================
always @(negedge clk) begin
    if (out_valid === 1'b0 && out_data !== 32'b0) begin
        $display("------------------------------------------------------------");
        $display("FAIL! out_data should be 0 when out_valid is 0.");
        $display("Time = %0t, out_data = %h", $time, out_data);
        $display("------------------------------------------------------------");
        repeat(2) #(CYCLE);
        $finish;
    end
end

// ================================================================
// Rule 3: out_valid cannot overlap with any input valid
// ================================================================
always @(negedge clk) begin
    if (out_valid === 1'b1 &&
       (instruction_in_valid === 1'b1 ||
        image_in_valid       === 1'b1 ||
        weight_in_valid      === 1'b1)) begin
        $display("------------------------------------------------------------");
        $display("FAIL! out_valid should not overlap with any input valid.");
        $display("Time = %0t", $time);
        $display("instruction_in_valid = %b, image_in_valid = %b, weight_in_valid = %b, out_valid = %b",
                 instruction_in_valid, image_in_valid, weight_in_valid, out_valid);
        $display("------------------------------------------------------------");
        repeat(2) #(CYCLE);
        $finish;
    end
end

// ================================================================
// Capture output and check too many cycles
// ================================================================
always @(negedge clk) begin
    if (out_valid === 1'b1) begin
        if (output_count < CHECK_OUTPUT_SIZE) begin
            received_output[output_count] = out_data;
            output_count = output_count + 1;
        end
        else begin
            $display("------------------------------------------------------------");
            $display("FAIL! out_valid asserted too many cycles.");
            $display("Expected output count = %0d, but got more at time %0t", CHECK_OUTPUT_SIZE, $time);
            $display("------------------------------------------------------------");
            repeat(2) #(CYCLE);
            $finish;
        end
    end
end

// ================================================================
// Rule 2: out_valid must be continuous and exact length
// ================================================================
always @(negedge clk) begin
    if (out_valid === 1'b1) begin
        seen_out_valid <= 1'b1;

        if (!burst_started) begin
            burst_started <= 1'b1;
        end

        if (burst_finished) begin
            $display("------------------------------------------------------------");
            $display("FAIL! out_valid re-asserted after burst finished.");
            $display("This means output burst is interrupted or split.");
            $display("Time = %0t", $time);
            $display("------------------------------------------------------------");
            repeat(2) #(CYCLE);
            $finish;
        end
    end
    else begin
        if (burst_started && !burst_finished && output_count < CHECK_OUTPUT_SIZE) begin
            $display("------------------------------------------------------------");
            $display("FAIL! out_valid burst is interrupted before sending enough data.");
            $display("Current output_count = %0d, expected = %0d, time = %0t",
                     output_count, CHECK_OUTPUT_SIZE, $time);
            $display("------------------------------------------------------------");
            repeat(2) #(CYCLE);
            $finish;
        end

        if (burst_started && output_count == CHECK_OUTPUT_SIZE) begin
            burst_finished <= 1'b1;
        end
    end
end

// ================================================================
// Tasks
// ================================================================
task load_test_data;
    integer fd;
    integer code;
    integer p, idx;
    reg [31:0] token32;
    reg        pad_type;
    reg [1:0]  act_type;
begin
    $display("Input file       : %s", INPUT_FILE);

`ifdef PREPROCESS
    $display("Golden file      : %s", PREPROCESSING_GOLDEN);
`elsif CONV_L1
    $display("Golden file      : %s", CONV_L1_GOLDEN);
`elsif CONV_L2
    $display("Golden file      : %s", CONV_L2_GOLDEN);
`elsif DECONV_L1
    $display("Golden file      : %s", DECONV_L1_GOLDEN);
`else
    $display("Golden file      : %s", OUTPUT_GOLDEN);
`endif

    fd = $fopen(INPUT_FILE, "r");
    if (fd == 0) begin
        $display("FAIL! Cannot open input file: %s", INPUT_FILE);
        $finish;
    end

    // input.txt format per pattern:
    // token 1 : pad_type   (e.g. 0 or 1)
    // token 2 : act_type   (e.g. 00~11, file may show 01)
    // token 3~ : weight/data hex words
    for (p = 0; p < PATNUM; p = p + 1) begin
        idx = p * INPUT_BLOCK_SIZE;

        // read pad_type
        code = $fscanf(fd, "%h\n", token32);
        if (code != 1) begin
            $display("FAIL! Cannot read pad_type for pattern %0d", p);
            $finish;
        end
        pad_type = token32[0];

        // read act_type
        code = $fscanf(fd, "%h\n", token32);
        if (code != 1) begin
            $display("FAIL! Cannot read act_type for pattern %0d", p);
            $finish;
        end
        act_type = token32[1:0];
        $display("Pattern %0d: pad_type = %b, act_type = %b", p+1, pad_type, act_type);
        // merge instruction
        all_input_stream[idx] = {29'b0, pad_type, act_type};

        // read remaining 144 weights + 128 image data
        for (j = 1; j < INPUT_BLOCK_SIZE; j = j + 1) begin
            code = $fscanf(fd, "%h\n", all_input_stream[idx + j]);
            if (code != 1) begin
                $display("FAIL! Cannot read input token %0d for pattern %0d", j, p);
                $finish;
            end
        end
    end

    $fclose(fd);

`ifdef PREPROCESS
    $readmemh(PREPROCESSING_GOLDEN, all_golden_data);
`elsif CONV_L1
    $readmemh(CONV_L1_GOLDEN, all_golden_data);
`elsif CONV_L2
    $readmemh(CONV_L2_GOLDEN, all_golden_data);
`elsif DECONV_L1
    $readmemh(DECONV_L1_GOLDEN, all_golden_data);
`else
    $readmemh(OUTPUT_GOLDEN, all_golden_data);
`endif
end
endtask

task extract_pattern;
    input integer pattern_id;
    integer base_idx, golden_base;
begin
    base_idx    = pattern_id * INPUT_BLOCK_SIZE;
    golden_base = pattern_id * CHECK_OUTPUT_SIZE;

    // instruction: 1 entry
    for (j = 0; j < TOTAL_INSTRUCTIONS; j = j + 1) begin
        current_instruction[j] = all_input_stream[base_idx + j];
    end

    // weight: next 144 entries
    for (j = 0; j < TOTAL_WEIGHTS; j = j + 1) begin
        current_weight[j] = all_input_stream[base_idx + TOTAL_INSTRUCTIONS + j];
    end

    // image/data: next 128 entries
    for (j = 0; j < TOTAL_INPUT_PIXELS; j = j + 1) begin
        current_input[j] = all_input_stream[base_idx + TOTAL_INSTRUCTIONS + TOTAL_WEIGHTS + j];
    end

    // golden
    for (j = 0; j < CHECK_OUTPUT_SIZE; j = j + 1) begin
        current_golden[j] = all_golden_data[golden_base + j];
    end
end
endtask

task reset_signal_task;
begin
    #(CYCLE);
    rst_n = 1'b0;
    #(CYCLE*3);
    rst_n = 1'b1;

    if ((out_valid !== 1'b0) || (out_data !== 32'b0)) begin
        $display("------------------------------------------------------------");
        $display("FAIL! Output signals should be reset to 0 after reset.");
        $display("Time = %0t, out_valid = %b, out_data = %h", $time, out_valid, out_data);
        $display("------------------------------------------------------------");
        $finish;
    end

    #(CYCLE);
    release clk;
end
endtask

task input_task;
    integer gap;
begin
    // instruction: high for 1 cycle
    instruction_in_valid = 1'b1;
    weight_in_valid      = 1'b0;
    image_in_valid       = 1'b0;
    in_data              = current_instruction[0];
    @(negedge clk);

    instruction_in_valid = 1'b0;
    in_data              = 32'bx;

    // gap 2~5 cycles
    gap = $urandom_range(2, 5);
    repeat(gap) @(negedge clk);

    // weight: high for 144 cycles
    instruction_in_valid = 1'b0;
    weight_in_valid      = 1'b1;
    image_in_valid       = 1'b0;
    for (i = 0; i < TOTAL_WEIGHTS; i = i + 1) begin
        in_data = current_weight[i];
        @(negedge clk);
    end
    weight_in_valid = 1'b0;
    in_data         = 32'bx;

    // gap 2~5 cycles
    gap = $urandom_range(2, 5);
    repeat(gap) @(negedge clk);

    // image/data: high for 128 cycles
    instruction_in_valid = 1'b0;
    weight_in_valid      = 1'b0;
    image_in_valid       = 1'b1;
    for (i = 0; i < TOTAL_INPUT_PIXELS; i = i + 1) begin
        in_data = current_input[i];
        @(negedge clk);
    end
    image_in_valid = 1'b0;
    in_data        = 32'bx;
end
endtask

task wait_out_valid_task;
begin
    wait_val_time = 0;

    while (out_valid == 1'b0) begin
        wait_val_time = wait_val_time + 1;
        if (wait_val_time > MAX_LATENCY) begin
            $display("------------------------------------------------------------");
            $display("FAIL! The execution latency is over %0d cycles.", MAX_LATENCY);
            $display("Received only %0d/%0d outputs", output_count, CHECK_OUTPUT_SIZE);
            $display("Pattern = %0d", patcount+1);
            $display("------------------------------------------------------------");
            repeat(2) #(CYCLE);
            $finish;
        end
        @(negedge clk);
    end
    while (output_count < CHECK_OUTPUT_SIZE) begin
        @(negedge clk);
    end
    total_latency = total_latency + wait_val_time;
    $display("  Output completed in %0d cycles", wait_val_time);
    if(out_valid == 1) begin
        $display("  Note: out_valid is still high at the end of burst. This is acceptable as long as it does not violate the rules.");
        $finish;
    end
end
endtask

task check_ans_task;
shortreal golden_float, output_float;
begin
    for (i = 0; i < CHECK_OUTPUT_SIZE; i = i + 1) begin
        golden_float = $bitstoshortreal(current_golden[i]);
        output_float = $bitstoshortreal(received_output[i]);
        if (received_output[i] !== current_golden[i]) begin
            if($abs(golden_float - output_float) <= 0.02) begin
                tolerant_error_count = tolerant_error_count + 1;
                // $display("Tolerable mismatch at index %0d: golden = %h (%f), output = %h (%f), difference = %f",
                //          i, current_golden[i], golden_float, received_output[i], output_float, $abs(golden_float - output_float));
                continue;
            end
            else begin
                error_count  = error_count + 1;
                total_errors = total_errors + 1;

                $display("Mismatch at index %0d", i);
                $display("  Golden : %h", current_golden[i]);
                $display("  Output : %h", received_output[i]);
            end
 
        end
    end
end
endtask

task YOU_PASS_task;
begin
    $display("");
    $display("============================================================");
    $display("Congratulations! All patterns passed!");
    $display("Total latency   : %0d cycles", total_latency);
    $display("============================================================");
    $finish;
end
endtask

endmodule