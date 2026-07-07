//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2026 Spring
//   lab08 Exercise		
//   Author     		: Cho-Hsun Lee 
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`define CYCLE_TIME      15.0
`define SEED_NUMBER     321
`define PATTERN_NUMBER  100

module PATTERN(
    // Output Port
    clk,
    rst_n,
    in_valid,
    in_data,

    // Input Port
    out_valid,
    out_data
    );

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output  logic        clk, rst_n, in_valid;
output  logic[7:0]  in_data;

input           out_valid;
input   [11:0]   out_data;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;

integer patcount;
integer i, j, k;
integer total_latency;
integer wait_val_time;
integer error_count;

//---------------------------------------------------------------------
//   TEST DATA
//---------------------------------------------------------------------
reg task_num;
reg [7:0]  A  [0:3][0:3];
reg [7:0]  B  [0:3][0:3];

reg [3:0]  F1 [0:3][0:3];
reg [3:0]  H1 [0:3][0:3];
reg [3:0]  F2 [0:3][0:3];
reg [3:0]  H2 [0:3][0:3];

reg [11:0] golden_out [0:31];

//---------------------------------------------------------------------
//   CLOCK
//---------------------------------------------------------------------
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//   MAIN SIMULATION
//---------------------------------------------------------------------
initial begin
    rst_n    = 1'b1;
    in_valid = 1'b0;
    in_data  = 'bx;

    total_latency = 0;
    error_count   = 0;

    reset_signal_task;
    for (patcount = 0; patcount < `PATTERN_NUMBER; patcount = patcount + 1) begin
        repeat($urandom_range(2,5)) @(negedge clk);

        generate_random_testcase;
        compute_golden;
        input_task;
        wait_out_valid;
        check_ans;

        $display("Pattern %0d PASS, task_num=%d, latency = %0d", patcount, task_num,wait_val_time);
    end

    YOU_PASS_task;
end

//---------------------------------------------------------------------
//   RESET
//---------------------------------------------------------------------
task reset_signal_task;
begin
    force clk = 0;
    #(CYCLE);
    rst_n = 1'b0;
    in_valid = 1'b0;
    in_data = 'bx;

    #(CYCLE*2);

    if (out_valid !== 1'b0 || out_data !== 12'd0) begin
        $display("Reset error: out_valid or out_data should be zero after reset.");
        YOU_FAIL_task;
    end

    rst_n = 1'b1;
    #(CYCLE);
    release clk;
end
endtask
//---------------------------------------------------------------------
//   RANDOM TESTCASE
//---------------------------------------------------------------------
task generate_random_testcase;
begin
    task_num = $urandom_range(1,0);
    // task_num = 0;

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            A[i][j]  = $urandom_range(0,255);
            B[i][j]  = $urandom_range(0,255);

            F1[i][j] = $urandom_range(0,15);
            H1[i][j] = $urandom_range(0,15);
            F2[i][j] = $urandom_range(0,15);
            H2[i][j] = $urandom_range(0,15);
        end
    end
end
endtask

//---------------------------------------------------------------------
//   MATRIX MULTIPLICATION GOLDEN FUNCTION
//---------------------------------------------------------------------
function automatic [19:0] matmul_4x4;
    input [3:0] M [0:3][0:3];
    input [11:0] X [0:3][0:3];
    input integer row;
    input integer col;

    integer t;
    reg [19:0] sum;
begin
    sum = 20'd0;
    for (t = 0; t < 4; t = t + 1) begin
        sum = sum + M[row][t] * X[t][col];
    end
    matmul_4x4 = sum;
end
endfunction

//---------------------------------------------------------------------
//   GOLDEN MODEL
//---------------------------------------------------------------------
task compute_golden;
    reg [11:0] A12 [0:3][0:3];
    reg [11:0] B12 [0:3][0:3];

    reg [3:0]  X1 [0:3][0:3];
    reg [3:0]  X2 [0:3][0:3];

    reg [7:0]  Y1 [0:3][0:3];
    reg [7:0]  Y2 [0:3][0:3];

    reg [11:0] BX1     [0:3][0:3];
    reg [11:0] Mid_B   [0:3][0:3];
    reg [11:0] Mid_A   [0:3][0:3];
    reg [11:0] Mid_AX2 [0:3][0:3];

    reg [11:0] OUT_A [0:3][0:3];
    reg [11:0] OUT_B [0:3][0:3];

    integer idx;
begin
    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            A12[i][j] = {4'd0, A[i][j]};
            B12[i][j] = {4'd0, B[i][j]};
        end
    end

    if (task_num == 1'b0) begin
        // forward

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                X1[i][j] = (matmul_4x4(F1, A12, i, j) % 15) + 1;
                Y1[i][j] =  matmul_4x4(H1, A12, i, j) % 256;
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                BX1[i][j]   = X1[i][j] * B12[i][j];
                Mid_A[i][j] = A12[i][j];
                Mid_B[i][j] = BX1[i][j] ^ {4'd0, Y1[i][j]};
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                X2[i][j] = (matmul_4x4(F2, Mid_B, i, j) % 15) + 1;
                Y2[i][j] =  matmul_4x4(H2, Mid_B, i, j) % 256;
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                Mid_AX2[i][j] = X2[i][j] * Mid_A[i][j];
                OUT_A[i][j]   = Mid_AX2[i][j] ^ {4'd0, Y2[i][j]};
                OUT_B[i][j]   = Mid_B[i][j];
            end
        end
    end
    else begin
        // backward

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                X2[i][j] = (matmul_4x4(F2, B12, i, j) % 15) + 1;
                Y2[i][j] =  matmul_4x4(H2, B12, i, j) % 256;
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                Mid_AX2[i][j] = A12[i][j] ^ {4'd0, Y2[i][j]};
                Mid_A[i][j]   = Mid_AX2[i][j] / X2[i][j];
                Mid_B[i][j]   = B12[i][j];
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                X1[i][j] = (matmul_4x4(F1, Mid_A, i, j) % 15) + 1;
                Y1[i][j] =  matmul_4x4(H1, Mid_A, i, j) % 256;
            end
        end

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                BX1[i][j]  = Mid_B[i][j] ^ {4'd0, Y1[i][j]};
                OUT_A[i][j] = Mid_A[i][j];
                OUT_B[i][j] = BX1[i][j] / X1[i][j];
            end
        end
    end

    idx = 0;

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            golden_out[idx] = OUT_A[i][j];
            idx = idx + 1;
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            golden_out[idx] = OUT_B[i][j];
            idx = idx + 1;
        end
    end
end
endtask

//---------------------------------------------------------------------
//   INPUT TASK: 97 CYCLES
//---------------------------------------------------------------------
task input_task;
begin
    in_valid = 1'b1;

    in_data = {7'd0, task_num};
    @(negedge clk);

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_data = A[i][j];
            @(negedge clk);
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_data = B[i][j];
            @(negedge clk);
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_data = {4'd0, F1[i][j]};
            @(negedge clk);
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_data = {4'd0, H1[i][j]};
            @(negedge clk);
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_data = {4'd0, F2[i][j]};
            @(negedge clk);
        end
    end

    for (i = 0; i < 4; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            in_data = {4'd0, H2[i][j]};
            @(negedge clk);
        end
    end

    in_valid = 1'b0;
    in_data  = 'bx;
end
endtask

//---------------------------------------------------------------------
//   WAIT OUT_VALID
//---------------------------------------------------------------------
task wait_out_valid;
begin
    wait_val_time = 0;

    while (out_valid !== 1'b1) begin
        wait_val_time = wait_val_time + 1;

        if (wait_val_time > 200) begin
            $display("Latency error: latency exceeds 200 cycles.");
            YOU_FAIL_task;
        end

        if (out_valid === 1'b1 && in_valid === 1'b1) begin
            $display("Spec error: out_valid overlaps with in_valid.");
            YOU_FAIL_task;
        end

        @(negedge clk);
    end

    total_latency = total_latency + wait_val_time;
end
endtask

//---------------------------------------------------------------------
//   CHECK ANSWER
//---------------------------------------------------------------------
task check_ans;
    integer idx;
begin
    for (idx = 0; idx < 32; idx = idx + 1) begin
        if (out_valid !== 1'b1) begin
            $display("Output error: out_valid should stay high for 32 cycles.");
            $display("Pattern = %0d, output cycle = %0d", patcount, idx);
            YOU_FAIL_task;
        end

        if (out_data !== golden_out[idx]) begin
            $display("Answer mismatch.");
            $display("Pattern      = %0d", patcount);
            $display("Task         = %0d", task_num);
            $display("Output index = %0d", idx);
            $display("Golden       = %0d", golden_out[idx]);
            $display("Your output  = %0d", out_data);
            error_count = error_count + 1;
            YOU_FAIL_task;
        end

        @(negedge clk);
    end

    if (out_valid !== 1'b0) begin
        $display("Output error: out_valid should be low after 32 cycles.");
        YOU_FAIL_task;
    end

    if (out_data !== 12'd0) begin
        $display("Output error: out_data should be zero when out_valid is low.");
        YOU_FAIL_task;
    end
end
endtask

//---------------------------------------------------------------------
//   PASS / FAIL
//---------------------------------------------------------------------
task YOU_FAIL_task;
begin
    $display("============================================================");
    $display("FAIL");
    $display("============================================================");
    $finish;
end
endtask

task YOU_PASS_task;
begin
    $display("============================================================");
    $display("PASS");
    $display("Total patterns = %0d", `PATTERN_NUMBER);
    $display("Total latency  = %0d cycles", total_latency);
    $display("Clock period   = %.1f ns", CYCLE);
    $display("============================================================");
    $finish;
end
endtask

endmodule
