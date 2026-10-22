`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

module PATTERN(
    output reg       clk,
    output reg       rst_n,
    // AXI4-Lite Master
    input [31:0]     aw_addr,
    input            aw_valid,
    input            aw_ready,
    input [63:0]     w_data,
    input            w_valid,
    input            w_ready,
    input [1:0]      b_resp,
    input            b_valid,
    input            b_ready,

    input [31:0]     ar_addr,
    input            ar_valid,
    input            ar_ready,
    input [63:0]     r_data,
    input [1:0]      r_resp,
    input            r_valid,
    input            r_ready,

    output reg       in_mode_valid,
    output reg [1:0] in_mode,
    output reg       in_valid,
    output reg [1:0] in_bank,
    output reg [5:0] in_src_row,
    output reg [5:0] in_dst_row,
    output reg [63:0]in_data,

    input            out_valid,
    input [63:0]     out_data
);

// ======================================================
// Golden Memory
// ======================================================
reg [63:0] golden_DRAM [0:65535];
reg [63:0] golden_calc_result[0:3];
reg [63:0] write_row_data [0:255];

parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
initial $readmemh(DRAM_p_r, golden_DRAM);

integer hit_main1;
integer hit_axi6;
integer hit_main2;
integer hit_main3;
integer hit_main4;
integer hit_main5;
integer hit_axi1;
integer hit_axi2;
integer hit_axi3;
integer hit_axi4;
integer hit_axi5;



// $display("*************************************************************************");
// $display("*                           SPEC MAIN-1 FAIL                            *");
// $display("*                           SPEC MAIN-2 FAIL                            *");
// $display("*                           SPEC MAIN-3 FAIL                            *");
// $display("*                           SPEC MAIN-4 FAIL                            *");
// $display("*                           SPEC MAIN-5 FAIL                            *");
// $display("*************************************************************************");

// $display("*************************************************************************");
// $display("*                          SPEC AXI-1 FAIL                              *");
// $display("*                          SPEC AXI-2 FAIL                              *");
// $display("*                          SPEC AXI-3 FAIL                              *");
// $display("*                          SPEC AXI-4 FAIL                              *");
// $display("*                          SPEC AXI-5 FAIL                              *");
// $display("*                          SPEC AXI-6 FAIL                              *");
// $display("*************************************************************************");
// ======================================================
// reg / wires
// ======================================================


// ======================================================
// Parameters / integers
// ======================================================
integer total_latency;
real CYCLE = `CYCLE_TIME;

integer latency;
// integer i;


// ======================================================
// Clock
// ======================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

// ======================================================
// PASS / FAIL
// ======================================================
task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles                    *", total_latency);
    $display("*                Your clock period = %.1f ns                           *", CYCLE);
    $display("*                Total Latency = %.1f ns                               *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

// ======================================================
// Helper
// row base = bank*0x4000 + row*0x100
// ======================================================
function [15:0] get_row_base_addr;
    input [1:0] bank;
    input [5:0] row;
    begin
        get_row_base_addr = (bank << 14) + (row << 8);
    end
endfunction


// ======================================================
// INIT INPUT 
// ======================================================
task init_input_task; begin
    force clk = 0;
    in_mode_valid = 1'b0;
    in_mode       = 'bx;
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
end endtask

// ======================================================
// Reset CHECK 
// ======================================================
task reset_task; begin
    #(CYCLE);  rst_n = 0;
    #(CYCLE*3); rst_n = 1;

    if (out_valid !== 1'b0 || out_data !== 64'b0 ||
        aw_addr   !== 32'b0 || aw_valid !== 1'b0 || aw_ready !== 1'b0 ||
        w_data    !== 64'b0 || w_valid  !== 1'b0 || w_ready  !== 1'b0 ||
        b_resp    !== 2'b0  || b_valid  !== 1'b0 || b_ready  !== 1'b0 ||
        ar_addr   !== 32'b0 || ar_valid !== 1'b0 || ar_ready !== 1'b0 ||
        r_data    !== 64'b0 || r_resp   !== 2'b0 || r_valid  !== 1'b0 || r_ready !== 1'b0) begin
        hit_main1 = 1;
        YOU_FAIL_task;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-1 FAIL                            *");
        $display("*************************************************************************");
        // $finish;
    end

    #(CYCLE);
    release clk;
end endtask

// ======================================================
// Send one READ command
// ======================================================
task input_read_task;
    input [1:0] bank;
    input [5:0] src_row;
begin
    in_mode_valid = 1'b1;
    in_mode       = 2'd0; // READ
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
    @(negedge clk);
    
    in_mode_valid = 1'b0;
    in_mode       = 'bx;
    in_valid      = 1'b1;
    in_bank       = bank;
    in_src_row    = src_row;
    in_dst_row    = 'bx;
    in_data       = 'bx;
    @(negedge clk);

    
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
end
endtask



task input_write_task;
    input [1:0] bank;
    input [5:0] dst_row;
    integer j;
begin

    // prepare write data
    gen_write_row_data_task;

    // update golden first
    update_golden_write_row_task(bank, dst_row);

    // mode phase
    in_mode_valid = 1'b1;
    in_mode       = 2'd1; // WRITE
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
    @(negedge clk);

    // data phase: first beat carries bank/dst_row
    in_mode_valid = 1'b0;
    in_mode       = 'bx;
    in_valid      = 1'b1;
    in_bank       = bank;
    in_src_row    = 6'b0;
    in_dst_row    = dst_row;
    in_data       = write_row_data[0];
    @(negedge clk);

    // remaining 255 beats
    for (j = 1; j < 256; j = j + 1) begin
        in_valid      = 1'b1;
        in_bank       = 'bx;
        in_src_row    = 'bx;
        in_dst_row    = 'bx;
        in_data       = write_row_data[j];
        @(negedge clk);
    end

    // deassert inputs
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
end
endtask

// ======================================================
// Send CALC command
// ======================================================
task input_calc_task;
    input [5:0] src_row;
begin
   
    in_mode_valid = 1'b1;
    in_mode       = 2'd2; // READ
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
    @(negedge clk);
    
    in_mode_valid = 1'b0;
    in_mode       = 'bx;
    in_valid      = 1'b1;
    in_bank       = 'bx;
    in_src_row    = src_row;
    in_dst_row    = 'bx;
    in_data       = 'bx;
    @(negedge clk);

    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;

end
endtask

// ======================================================
// Send SORT command
// ======================================================
task input_sort_task;
    input [5:0] src_row;
    input [5:0] dst_row;
begin
    

    in_mode_valid = 1'b1;
    in_mode       = 2'd3; // SORT
    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
    @(negedge clk);
    
    in_mode_valid = 1'b0;
    in_mode       = 'bx;
    in_valid      = 1'b1;
    in_bank       = 'bx;
    in_src_row    = src_row;
    in_dst_row    = dst_row;   // 這裡要改
    in_data       = 'bx;
    @(negedge clk);

    in_valid      = 1'b0;
    in_bank       = 'bx;
    in_src_row    = 'bx;
    in_dst_row    = 'bx;
    in_data       = 'bx;
     @(negedge clk);
end
endtask

// ======================================================
// Wait until first out_valid
// ======================================================
task wait_out_valid_task;
begin
    latency = 0;
    while (out_valid != 1'b1) begin
        latency = latency + 1;
        total_latency = total_latency + 1;

        if (latency > 10000) begin
            YOU_FAIL_task;
            hit_main2 = 1;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-2 FAIL                            *");
            $display("*                  Execution latency is limited in 10000 cycles         *");
            $display("*************************************************************************");
            // $finish;
        end

        @(negedge clk);
    end
end
endtask


task check_read_task;
    input [1:0] bank;
    input [5:0] src_row;
    reg [15:0] row_base;
    reg [63:0] golden_out;
    reg [15:0] addr;
    integer j;
    integer i;
begin
    row_base = get_row_base_addr(bank, src_row);


    
    for (j = 0; j < 65536; j = j + 1) begin
        addr = row_base + j;
        if ( !((addr >= 16'h3F00 && addr <= 16'h3FFF) || (addr >= 16'h7F00 && addr <= 16'h7FFF) || (addr >= 16'hBF00 && addr <= 16'hBFFF) || (addr >= 16'hFF00 && addr <= 16'hFFFF)) ) begin
            if (u_DRAM.DRAM[addr] !== golden_DRAM[addr]) begin
                // YOU_FAIL_task;
                hit_main5 = 1;
                $display("*************************************************************************");
                $display("*                         SPEC MAIN-5 FAIL                              *");
                $display("*                DRAM content changed unexpectedly during READ          *");
                $display("* bank=%0d row=%0d col=%0d addr=%h                                      *", bank, src_row, i, row_base+i);
                $display("* golden_DRAM = %h                                                      *", golden_DRAM[row_base + i]);
                $display("* u_DRAM.DRAM = %h                                                      *", u_DRAM.DRAM[row_base + i]);
                $display("*************************************************************************");
            end
        end
    end


    for (i = 0; i < 256; i = i + 1) begin
        golden_out = golden_DRAM[row_base + i];

        if (out_valid !== 1'b1) begin
            YOU_FAIL_task;
            hit_main3 = 1;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-3 FAIL                            *");
            $display("*            out_valid should stay high for 256 consecutive cycles      *");
            $display("*            bank=%0d row=%0d col=%0d                                   *", bank, src_row, i);
            $display("*************************************************************************");
            // $finish;
        end

        if (out_data !== golden_out) begin
            YOU_FAIL_task;
            hit_main4 = 1;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-4 FAIL                            *");
            $display("*                      READ output data mismatch                        *");
            $display("* bank=%0d row=%0d col=%0d addr=%h                                      *", bank, src_row, i, row_base+i);
            $display("* golden_out = %h                                                       *", golden_out);
            $display("* out_data   = %h                                                       *", out_data);
            $display("*************************************************************************");
            // $finish;
        end

        if (i != 255) begin
            total_latency = total_latency + 1;
            @(negedge clk);
        end
    end

    

    @(negedge clk);
    total_latency = total_latency + 1;
    if (out_valid !== 1'b0) begin
        YOU_FAIL_task;
        hit_main3 = 1;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*                out_valid should be deasserted after 256 cycles        *");
        $display("*************************************************************************");
        // $finish;
    end
end
endtask



task check_write_task;
    input [1:0] bank;
    input [5:0] dst_row;
    reg [15:0] row_base;
    reg [15:0] addr;
    integer j;
begin
    row_base = get_row_base_addr(bank, dst_row);

    if (out_valid !== 1'b1) begin
        YOU_FAIL_task;
        hit_main3 = 1;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*                 out_valid should be asserted for 1 cycle              *");
        $display("*************************************************************************");
        // $finish;
    end

    // check written row
    // check written row
    for (j = 0; j < 65536; j = j + 1) begin
        addr = row_base + j;
        if ( !((addr >= 16'h3F00 && addr <= 16'h3FFF) || (addr >= 16'h7F00 && addr <= 16'h7FFF) || (addr >= 16'hBF00 && addr <= 16'hBFFF) || (addr >= 16'hFF00 && addr <= 16'hFFFF)) ) begin
            if (u_DRAM.DRAM[addr] !== golden_DRAM[addr]) begin
                // YOU_FAIL_task;
                hit_main5 = 1;
                // $display("*************************************************************************");
                // $display("*                           SPEC MAIN-5 FAIL                            *");
                // $display("*                    WRITE result written back wrong                    *");
                // $display("* bank=%0d dst_row=%0d col=%0d addr=%h                                  *", bank, dst_row, j, addr);
                // $display("* golden_DRAM = %h                                                      *", golden_DRAM[addr]);
                // $display("* u_DRAM.DRAM = %h                                                      *", u_DRAM.DRAM[addr]);
                // $display("*************************************************************************");
                // $finish;
            end
        end
    end

    @(negedge clk);
    total_latency = total_latency + 1;
    if (out_valid !== 1'b0) begin
        YOU_FAIL_task;
        hit_main3 = 1;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*               out_valid should be deasserted after 1 cycle            *");
        $display("*************************************************************************");
        $finish;
    end
end
endtask


task check_calc_task;
    input [5:0] src_row;
    reg signed [63:0] golden_out;
    integer i;
begin

    update_golden_calc_task(src_row);

    // Check 4 consecutive output cycles: Bank0 -> Bank1 -> Bank2 -> Bank3
    for (i = 0; i < 4; i = i + 1) begin
        golden_out = golden_calc_result[i];

        if (out_valid !== 1'b1) begin
            YOU_FAIL_task;
            hit_main3 = 1;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-3 FAIL                            *");
            $display("*          out_valid should stay high for 4 consecutive cycles          *");
            $display("*                  CALC src_row=%0d bank=%0d                            *", src_row, i);
            $display("*************************************************************************");
            // $finish;
        end

        if ($signed(out_data) !== $signed(golden_out)) begin
            YOU_FAIL_task;
            hit_main4 = 1;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-4 FAIL                            *");
            $display("*                     CALC output data mismatch                         *");
            $display("*                  src_row=%0d bank=%0d                                 *", src_row, i);
            $display("*                  golden_out = %0d (%h)                                *", $signed(golden_out), golden_out);
            $display("*                  out_data   = %0d (%h)                                *", $signed(out_data), out_data);
            $display("*************************************************************************");
            // $finish;
        end

        if (i != 3) begin
            total_latency = total_latency + 1;
            @(negedge clk);
        end
    end

    // After 4 cycles, out_valid must be deasserted
    @(negedge clk);
    total_latency = total_latency + 1;
    if (out_valid !== 1'b0) begin
        YOU_FAIL_task;
        hit_main3 = 1;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*               out_valid should be deasserted after 4 cycles           *");
        $display("*                    CALC src_row=%0d                                   *", src_row);
        $display("*************************************************************************");
        // $finish;
    end
end
endtask


task check_sort_task;
    input [5:0] src_row;
    input [5:0] dst_row;
    reg [15:0] row_base;
    reg [15:0] addr;
    integer b, j;
begin
    // update golden first
    update_golden_sort_task(src_row, dst_row);

    if (out_valid !== 1'b1) begin
        YOU_FAIL_task;
        hit_main3 = 1;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*                 out_valid should be asserted for 1 cycle              *");
        $display("*************************************************************************");
        // $finish;
    end

    // only check destination row across 4 banks
    for (j = 0; j < 65536; j = j + 1) begin
        addr = row_base + j;
        if ( !((addr >= 16'h3F00 && addr <= 16'h3FFF) || (addr >= 16'h7F00 && addr <= 16'h7FFF) || (addr >= 16'hBF00 && addr <= 16'hBFFF) || (addr >= 16'hFF00 && addr <= 16'hFFFF)) ) begin
            if (u_DRAM.DRAM[addr] !== golden_DRAM[addr]) begin
                YOU_FAIL_task;
                hit_main5 = 1;
                $display("*************************************************************************");
                $display("*                           SPEC MAIN-5 FAIL                            *");
                $display("*                    WRITE result written back wrong                    *");
                $display("*dst_row=%0d col=%0d addr=%h                                  *",dst_row, j, addr);
                $display("* golden_DRAM = %h                                                      *", golden_DRAM[addr]);
                $display("* u_DRAM.DRAM = %h                                                      *", u_DRAM.DRAM[addr]);
                $display("*************************************************************************");
                // $finish;
            end
        end
    end

    @(negedge clk);
    total_latency = total_latency + 1;
    if (out_valid !== 1'b0) begin
        YOU_FAIL_task;
        hit_main3 = 1;
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*               out_valid should be deasserted after 1 cycle            *");
        $display("*************************************************************************");
        // $finish;
    end
end
endtask



// =======================================================================================================
// main
// =======================================================================================================
integer testcase;

reg [1:0] read_bank_rand;
reg [5:0] read_row_rand;
reg [5:0] sort_src_row_rand;
reg [5:0] sort_dst_row_rand;
reg [1:0] write_bank_rand;
reg [5:0] write_row_rand;
reg [5:0] calc_row_rand;

initial begin
    total_latency = 0;
    init_input_task;
    rst_n = 1'b1;

    hit_main1 = 0;
    hit_axi6 = 0;
    hit_main2 = 0;
    hit_main3 = 0;
    hit_main4 = 0;
    hit_main5 = 0;
    hit_axi1 = 0;
    hit_axi2 = 0;
    hit_axi3 = 0;
    hit_axi4 = 0;
    hit_axi5 = 0;

    reset_task;



    for (testcase = 0; testcase < 100; testcase = testcase + 1) begin
        
        read_bank_rand     = $urandom_range(0, 3);
        read_row_rand      = $urandom_range(0, 62);   // read: 0~62
        sort_src_row_rand  = $urandom_range(32, 62);  // sort: 32~62
        sort_dst_row_rand  = $urandom_range(32, 62);  // sort: 32~62
        write_bank_rand    = $urandom_range(0, 3);
        write_row_rand     = $urandom_range(32, 62);  // write: 32~62
        calc_row_rand      = $urandom_range(0, 31);   // calc: 0~31

        $display("testcase %0d", testcase);
        $display("  READ  bank=%0d row=%0d", read_bank_rand, read_row_rand);
        input_read_task(read_bank_rand, read_row_rand);
        wait_out_valid_task;
        check_read_task(read_bank_rand, read_row_rand);

        $display("  SORT  src=%0d dst=%0d", sort_src_row_rand, sort_dst_row_rand);  
        input_sort_task(sort_src_row_rand, sort_dst_row_rand);
        wait_out_valid_task;
        check_sort_task(sort_src_row_rand, sort_dst_row_rand);

        $display("  WRITE bank=%0d row=%0d", write_bank_rand, write_row_rand);
        input_write_task(write_bank_rand, write_row_rand);
        wait_out_valid_task;
        check_write_task(write_bank_rand, write_row_rand);

        $display("  CALC  row=%0d", calc_row_rand);
        input_calc_task(calc_row_rand);
        wait_out_valid_task;
        check_calc_task(calc_row_rand);
    end

    YOU_PASS_task;
end


// ======================================================
// Basic AXI checker
// ======================================================

// AXI-1
always @(negedge clk) begin
    if (rst_n) begin
        if (!aw_valid && aw_addr !== 32'b0) begin
            YOU_FAIL_task;
            hit_axi1 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-1 FAIL                              *");
            $display("*                aw_addr should be 0 when aw_valid is low               *");
            $display("*************************************************************************");
            // $finish;
        end
        if (!w_valid && w_data !== 64'b0) begin
            hit_axi1 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-1 FAIL                              *");
            $display("*                aw_addr should be 0 when aw_valid is low               *");
            $display("*************************************************************************");
            // $finish;
        end
        if (!ar_valid && ar_addr !== 32'b0) begin
            hit_axi1 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-1 FAIL                              *");
            $display("*                aw_addr should be 0 when aw_valid is low               *");
            $display("*************************************************************************");
            // $finish;
        end
        if (!b_valid && b_resp !== 2'b0) begin
           hit_axi1 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-1 FAIL                              *");
            $display("*                aw_addr should be 0 when aw_valid is low               *");
            $display("*************************************************************************");
            // $finish;
        end
        if (!r_valid) begin
            if (r_resp !== 2'b0 || r_data !== 64'b0) begin
                hit_axi1 = 1;
                $display("*************************************************************************");
                $display("*                          SPEC AXI-1 FAIL                              *");
                $display("*                aw_addr should be 0 when aw_valid is low               *");
                $display("*************************************************************************");
                // $finish;
            end
        end
    end
end

// ======================================================
// AXI Stability Check for 5 Channels
// AW / W / B / AR / R
// ======================================================

// -------------------------
// Hold registers
// -------------------------
reg        aw_hold_valid;
reg [31:0] aw_addr_hold;

reg        w_hold_valid;
reg [63:0] w_data_hold;

reg        b_hold_valid;
reg [1:0]  b_resp_hold;

reg        ar_hold_valid;
reg [31:0] ar_addr_hold;

reg        r_hold_valid;
reg [63:0] r_data_hold;
reg [1:0]  r_resp_hold;

// ======================================================
// Stability check
// Rule:
// Once VALID goes high, if READY is still low,
// VALID and payload must remain stable until handshake.
// ======================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_hold_valid <= 1'b0;
        aw_addr_hold  <= 32'b0;

        w_hold_valid  <= 1'b0;
        w_data_hold   <= 64'b0;

        b_hold_valid  <= 1'b0;
        b_resp_hold   <= 2'b0;

        ar_hold_valid <= 1'b0;
        ar_addr_hold  <= 32'b0;

        r_hold_valid  <= 1'b0;
        r_data_hold   <= 64'b0;
        r_resp_hold   <= 2'b0;
    end
    else begin
        // =================================================
        // AW channel
        // AW_VALID and AW_ADDR should remain stable
        // until AW_READY goes high
        // =================================================
        if (aw_hold_valid && !aw_ready && !aw_valid) begin
            YOU_FAIL_task;
            hit_axi2 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-2 FAIL                              *");
            $display("*               AW_VALID dropped before AW handshake                    *");
            $display("*************************************************************************");
            // $finish;
        end

        if (aw_valid && !aw_ready) begin
            if (aw_hold_valid) begin
                if (aw_addr !== aw_addr_hold) begin
                    YOU_FAIL_task;
                    hit_axi2 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-2 FAIL                              *");
                    $display("*               AW_ADDR changed before AW handshake                     *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
            aw_hold_valid <= 1'b1;
            aw_addr_hold  <= aw_addr;
        end
        else begin
            aw_hold_valid <= 1'b0;
            aw_addr_hold  <= 32'b0;
        end

        // =================================================
        // W channel
        // W_VALID and W_DATA should remain stable
        // until W_READY goes high
        // =================================================
        if (w_hold_valid && !w_ready && !w_valid) begin
            YOU_FAIL_task;
            hit_axi2 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-2 FAIL                              *");
            $display("*                W_VALID dropped before W handshake                     *");
            $display("*************************************************************************");
            // $finish;
        end

        if (w_valid && !w_ready) begin
            if (w_hold_valid) begin
                if (w_data !== w_data_hold) begin
                    YOU_FAIL_task;
                    hit_axi2 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-2 FAIL                              *");
                    $display("*                W_DATA changed before W handshake                      *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
            w_hold_valid <= 1'b1;
            w_data_hold  <= w_data;
        end
        else begin
            w_hold_valid <= 1'b0;
            w_data_hold  <= 64'b0;
        end

        // =================================================
        // B channel
        // B_VALID and B_RESP should remain stable
        // until B_READY goes high
        // =================================================
        if (b_hold_valid && !b_ready && !b_valid) begin
            YOU_FAIL_task;
            hit_axi2 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-2 FAIL                              *");
            $display("*                B_VALID dropped before B handshake                     *");
            $display("*************************************************************************");
            // $finish;
        end

        if (b_valid && !b_ready) begin
            if (b_hold_valid) begin
                if (b_resp !== b_resp_hold) begin
                    YOU_FAIL_task;
                    hit_axi2 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-2 FAIL                              *");
                    $display("*               B_RESP changed before B handshake                       *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
            b_hold_valid <= 1'b1;
            b_resp_hold  <= b_resp;
        end
        else begin
            b_hold_valid <= 1'b0;
            b_resp_hold  <= 2'b0;
        end

        // =================================================
        // AR channel
        // AR_VALID and AR_ADDR should remain stable
        // until AR_READY goes high
        // =================================================
        if (ar_hold_valid && !ar_ready && !ar_valid) begin
            YOU_FAIL_task;
            hit_axi2 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-2 FAIL                              *");
            $display("*               AR_VALID dropped before AR handshake                    *");
            $display("*************************************************************************");
            // $finish;
        end

        if (ar_valid && !ar_ready) begin
            if (ar_hold_valid) begin
                if (ar_addr !== ar_addr_hold) begin
                    YOU_FAIL_task;
                    hit_axi2 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-2 FAIL                              *");
                    $display("*               AR_ADDR changed before AR handshake                     *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
            ar_hold_valid <= 1'b1;
            ar_addr_hold  <= ar_addr;
        end
        else begin
            ar_hold_valid <= 1'b0;
            ar_addr_hold  <= 32'b0;
        end

        // =================================================
        // R channel
        // R_VALID, R_DATA and R_RESP should remain stable
        // until R_READY goes high
        // =================================================
        if (r_hold_valid && !r_ready && !r_valid) begin
            YOU_FAIL_task;
            hit_axi2 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-2 FAIL                              *");
            $display("*                 R_VALID dropped before R handshake                    *");
            $display("*************************************************************************");
            // $finish;
        end

        if (r_valid && !r_ready) begin
            if (r_hold_valid) begin
                if ((r_data !== r_data_hold) || (r_resp !== r_resp_hold)) begin
                    YOU_FAIL_task;
                    hit_axi2 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-2 FAIL                              *");
                    $display("*             R_DATA or R_RESP changed before R handshake               *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
            r_hold_valid <= 1'b1;
            r_data_hold  <= r_data;
            r_resp_hold  <= r_resp;
        end
        else begin
            r_hold_valid <= 1'b0;
            r_data_hold  <= 64'b0;
            r_resp_hold  <= 2'b0;
        end
    end
end



reg aw_seen_for_w;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_seen_for_w <= 1'b0;
    end
    else begin
        // =================================================
        // SPEC AXI-3
        // W_VALID cannot be asserted before corresponding AW_VALID
        // AW must come earlier than or at the same time as W
        // =================================================

        // Case 1:
        // W_VALID=1 but neither previous AW exists nor current AW_VALID=1
        // -> illegal, W comes before AW
        if (w_valid && !aw_seen_for_w && !aw_valid) begin
            YOU_FAIL_task;
            hit_axi3 = 1;
            $display("*************************************************************************");
            $display("*                          SPEC AXI-3 FAIL                              *");
            $display("*         W_VALID asserted without corresponding AW_VALID               *");
            $display("*************************************************************************");
            // $finish;
        end

        // Once AW handshake happens, record that AW has been issued
        if (aw_valid && aw_ready) begin
            aw_seen_for_w <= 1'b1;
        end

        // Once W handshake happens, consume that AW/W dependency
        if (w_valid && w_ready) begin
            aw_seen_for_w <= 1'b0;
        end
    end
end


// AXI-4
always @(posedge clk) begin
    if (ar_addr > 32'd65535 || aw_addr > 32'd65535) begin
        YOU_FAIL_task;
        hit_axi4 = 1;
        $display("*************************************************************************");
        $display("*                          SPEC AXI-4 FAIL                              *");
        $display("*                   AR address should be within 0~65535                 *");
        $display("*************************************************************************");
    end
end

// AXI-5
integer aw_wait_cnt;
integer w_wait_cnt;
integer b_wait_cnt;
integer ar_wait_cnt;
integer r_wait_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_wait_cnt <= 0;
        w_wait_cnt  <= 0;
        b_wait_cnt  <= 0;
        ar_wait_cnt <= 0;
        r_wait_cnt  <= 0;
    end
    else begin
        // =================================================
        // AW channel
        // =================================================
        if (aw_valid && !aw_ready) begin
            aw_wait_cnt <= aw_wait_cnt + 1;
            if (aw_wait_cnt >= 50) begin
                YOU_FAIL_task;
                hit_axi5 = 1;
                $display("*************************************************************************");
                $display("*                          SPEC AXI-5 FAIL                              *");
                $display("*            aw_ready should be asserted within 100 cycles              *");
                $display("*************************************************************************");
                // $finish;
            end
        end
        else begin
            aw_wait_cnt <= 0;
        end

        // =================================================
        // W channel
        // =================================================
        if (w_valid && !w_ready) begin
            w_wait_cnt <= w_wait_cnt + 1;
            if (w_wait_cnt >= 100) begin
                YOU_FAIL_task;
                hit_axi5 = 1;
                $display("*************************************************************************");
                $display("*                          SPEC AXI-5 FAIL                              *");
                $display("*             w_ready should be asserted within 100 cycles              *");
                $display("*************************************************************************");
                // $finish;
            end
        end
        else begin
            w_wait_cnt <= 0;
        end

        // =================================================
        // B channel
        // =================================================
        if (b_valid && !b_ready) begin
            b_wait_cnt <= b_wait_cnt + 1;
            if (b_wait_cnt >= 100) begin
                YOU_FAIL_task;
                hit_axi5 = 1;
                $display("*************************************************************************");
                $display("*                          SPEC AXI-5 FAIL                              *");
                $display("*             b_ready should be asserted within 100 cycles              *");
                $display("*************************************************************************");
                // $finish;
            end
        end
        else begin
            b_wait_cnt <= 0;
        end

        // =================================================
        // AR channel
        // =================================================
        if (ar_valid && !ar_ready) begin
            ar_wait_cnt <= ar_wait_cnt + 1;
            if (ar_wait_cnt >= 50) begin
                YOU_FAIL_task;
                hit_axi5 = 1;
                $display("*************************************************************************");
                $display("*                          SPEC AXI-5 FAIL                              *");
                $display("*            ar_ready should be asserted within 100 cycles              *");
                $display("*************************************************************************");
                // $finish;
            end
        end
        else begin
            ar_wait_cnt <= 0;
        end

        // =================================================
        // R channel
        // =================================================
        if (r_valid && !r_ready) begin
            r_wait_cnt <= r_wait_cnt + 1;
            if (r_wait_cnt >= 100) begin
                YOU_FAIL_task;
                hit_axi5 = 1;
                $display("*************************************************************************");
                $display("*                          SPEC AXI-5 FAIL                              *");
                $display("*             r_ready should be asserted within 100 cycles              *");
                $display("*************************************************************************");
                // $finish;
            end
        end
        else begin
            r_wait_cnt <= 0;
        end
    end
end

integer aw_to_w_cnt;
integer w_to_b_cnt;
integer ar_to_r_cnt;

reg aw_to_w_pending;
reg w_to_b_pending;
reg ar_to_r_pending;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_to_w_cnt     <= 0;
        w_to_b_cnt      <= 0;
        ar_to_r_cnt     <= 0;

        aw_to_w_pending <= 1'b0;
        w_to_b_pending  <= 1'b0;
        ar_to_r_pending <= 1'b0;
    end
    else begin
        // =================================================
        // 1) AW handshake -> W handshake within 150 cycles
        // =================================================
        if (aw_valid && aw_ready) begin
            aw_to_w_pending <= 1'b1;
            aw_to_w_cnt     <= 0;
        end
        if (aw_to_w_pending) begin
            if (w_valid && w_ready) begin
                aw_to_w_pending <= 1'b0;
                aw_to_w_cnt     <= 0;
            end
            else begin
                aw_to_w_cnt <= aw_to_w_cnt + 1;
                if (aw_to_w_cnt >= 150) begin
                    YOU_FAIL_task;
                    hit_axi6 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-6 FAIL                              *");
                    $display("*          W channel should be asserted within 150 cycles after AW      *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
        end

        // =================================================
        // 2) W handshake -> B_VALID within 150 cycles
        // =================================================
        if (w_valid && w_ready) begin
            w_to_b_pending <= 1'b1;
            w_to_b_cnt     <= 0;
        end
        if (w_to_b_pending) begin
            if (b_valid) begin
                w_to_b_pending <= 1'b0;
                w_to_b_cnt     <= 0;
            end
            else begin
                w_to_b_cnt <= w_to_b_cnt + 1;
                if (w_to_b_cnt >= 150) begin
                    YOU_FAIL_task;
                    hit_axi6 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-6 FAIL                              *");
                    $display("*          B_VALID should be asserted within 150 cycles after W         *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
        end

        // =================================================
        // 3) AR handshake -> R handshake within 150 cycles
        // =================================================
        if (ar_valid && ar_ready) begin
            ar_to_r_pending <= 1'b1;
            ar_to_r_cnt     <= 0;
        end
        if (ar_to_r_pending) begin
            if (r_valid && r_ready) begin
                ar_to_r_pending <= 1'b0;
                ar_to_r_cnt     <= 0;
            end
            else begin
                ar_to_r_cnt <= ar_to_r_cnt + 1;
                if (ar_to_r_cnt >= 150) begin
                    YOU_FAIL_task;
                    hit_axi6 = 1;
                    $display("*************************************************************************");
                    $display("*                          SPEC AXI-6 FAIL                              *");
                    $display("*          R channel should be asserted within 150 cycles after AR      *");
                    $display("*************************************************************************");
                    // $finish;
                end
            end
        end
    end
end



always @(*) begin
    // if (!rst_n) begin
    //     // do nothing
    // end
    // else begin
        if (hit_main1) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-1 FAIL                            *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_axi1) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC AXI-1 FAIL                             *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_axi2) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC AXI-2 FAIL                             *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_axi3) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC AXI-3 FAIL                             *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_axi4) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC AXI-4 FAIL                             *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_axi5) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC AXI-5 FAIL                             *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_axi6) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC AXI-6 FAIL                             *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_main2) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-2 FAIL                            *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_main3) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-3 FAIL                            *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_main4) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-4 FAIL                            *");
            $display("*************************************************************************");
            $finish;
        end
        else if (hit_main5) begin
            YOU_FAIL_task;
            $display("*************************************************************************");
            $display("*                           SPEC MAIN-5 FAIL                            *");
            $display("*************************************************************************");
            $finish;
        end
    // end//
end


// ======================================================
// WRITE ANSWER
// ======================================================


task gen_write_row_data_task;
    integer j;
begin
    for (j = 0; j < 256; j = j + 1) begin
        write_row_data[j][31:0]  = $urandom;
        write_row_data[j][63:32] = $urandom;
    end
end
endtask

task update_golden_write_row_task;
    input [1:0] bank;
    input [5:0] dst_row;
    reg [15:0] row_base;
    integer j;
begin
    row_base = get_row_base_addr(bank, dst_row);

    for (j = 0; j < 256; j = j + 1) begin
        golden_DRAM[row_base + j] = write_row_data[j];
    end
end
endtask

// ======================================================
// SORT ANSWER
// ======================================================


reg [63:0] sort_word     [0:1023];
reg [15:0] sort_src_addr [0:1023];
reg [63:0] sort_tmp_word [0:1023];
reg [15:0] sort_tmp_addr [0:1023];



task update_golden_sort_task;
    input [5:0] src_row;
    input [5:0] dst_row;

    integer b, c;
    integer idx;
    integer width;
    integer left, mid, right;
    integer n;

    reg [15:0] src_base;
    reg [15:0] dst_base;
begin
    n = 1024;
    idx = 0;

    // --------------------------------------------------
    // Load 1024 words from source row across 4 banks
    // Order: B0 -> B1 -> B2 -> B3
    // --------------------------------------------------
    for (b = 0; b < 4; b = b + 1) begin
        src_base = {b[1:0], src_row, 8'd0};
        for (c = 0; c < 256; c = c + 1) begin
            sort_word[idx]     = golden_DRAM[src_base + c];
            sort_src_addr[idx] = src_base + c;
            idx = idx + 1;
        end
    end

    // --------------------------------------------------
    // Bottom-up merge sort
    // --------------------------------------------------
    width = 1;
    while (width < n) begin
        left = 0;
        while (left < n) begin
            mid   = left + width - 1;
            right = left + (width << 1) - 1;

            if (mid >= n)
                mid = n - 1;
            if (right >= n)
                right = n - 1;

            if (mid < right)
                merge_range_task(left, mid, right);

            left = left + (width << 1);
        end
        width = width << 1;
    end

    // --------------------------------------------------
    // Write sorted result back to golden_DRAM
    // Order: B0_C0~255 -> B1_C0~255 -> B2_C0~255 -> B3_C0~255
    // --------------------------------------------------
    idx = 0;
    for (b = 0; b < 4; b = b + 1) begin
        dst_base = {b[1:0], dst_row, 8'd0};
        for (c = 0; c < 256; c = c + 1) begin
            golden_DRAM[dst_base + c] = sort_word[idx];
            idx = idx + 1;
        end
    end

end
endtask



task merge_range_task;
    input integer left;
    input integer mid;
    input integer right;

    integer i, j, k;
begin
    i = left;
    j = mid + 1;
    k = left;

    while (i <= mid && j <= right) begin
        if (is_less_for_sort(sort_word[i], sort_src_addr[i],
                             sort_word[j], sort_src_addr[j])) begin
            sort_tmp_word[k] = sort_word[i];
            sort_tmp_addr[k] = sort_src_addr[i];
            i = i + 1;
        end
        else begin
            sort_tmp_word[k] = sort_word[j];
            sort_tmp_addr[k] = sort_src_addr[j];
            j = j + 1;
        end
        k = k + 1;
    end

    while (i <= mid) begin
        sort_tmp_word[k] = sort_word[i];
        sort_tmp_addr[k] = sort_src_addr[i];
        i = i + 1;
        k = k + 1;
    end

    while (j <= right) begin
        sort_tmp_word[k] = sort_word[j];
        sort_tmp_addr[k] = sort_src_addr[j];
        j = j + 1;
        k = k + 1;
    end

    for (k = left; k <= right; k = k + 1) begin
        sort_word[k]     = sort_tmp_word[k];
        sort_src_addr[k] = sort_tmp_addr[k];
    end
end
endtask

function is_less_for_sort;
    input [63:0] word_a;
    input [15:0] addr_a;
    input [63:0] word_b;
    input [15:0] addr_b;
    reg [30:0] key_a;
    reg [30:0] key_b;
begin
    key_a = word_a[62:32];
    key_b = word_b[62:32];

    if (key_a < key_b)
        is_less_for_sort = 1'b1;
    else if (key_a > key_b)
        is_less_for_sort = 1'b0;
    else
        is_less_for_sort = (addr_a < addr_b);
end
endfunction


// ======================================================
// CALC ANSWER
// ======================================================


// reg signed [63:0] golden_calc_result [0:3];
reg signed [63:0] node_value [0:65535];
reg               node_done  [0:65535];

task calc_tree_no_recursive_task;
    input  [15:0] root_addr;
    output reg signed [63:0] result;

    reg [15:0] stack_addr [0:511];
    reg        stack_expand [0:511];   // 0: first time seen, 1: children should already be done
    integer sp;

    reg [15:0] cur_addr;
    reg        cur_expand;
    reg [63:0] node;
    reg [1:0]  opcode;
    reg [15:0] left_ptr, right_ptr;
    reg signed [63:0] left_val, right_val;

    integer k;
begin
    // clear done/value
    for (k = 0; k < 65536; k = k + 1) begin
        node_done[k]  = 1'b0;
        node_value[k] = 64'sd0;
    end

    sp = 0;
    stack_addr[sp]   = root_addr;
    stack_expand[sp] = 1'b0;
    sp = sp + 1;

    while (sp > 0) begin
        sp = sp - 1;
        cur_addr   = stack_addr[sp];
        cur_expand = stack_expand[sp];

        if (node_done[cur_addr])
            ;
        else begin
            node = golden_DRAM[cur_addr];

            // Type 0 : number node
            if (node[63] == 1'b0) begin
                node_value[cur_addr] = {{33{node[62]}}, node[62:32]};
                node_done[cur_addr]  = 1'b1;
            end
            else begin
                opcode    = node[33:32];
                left_ptr  = node[31:16];
                right_ptr = node[15:0];

                if (!cur_expand) begin
                    // Postorder:
                    // push self again (expanded), then right, then left
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
                end
                else begin
                    left_val  = node_value[left_ptr];
                    right_val = node_value[right_ptr];

                    case (opcode)
                        2'b00: node_value[cur_addr] = left_val + right_val;          // ADD
                        2'b01: node_value[cur_addr] = left_val - right_val;          // SUB
                        2'b10: node_value[cur_addr] = left_val * right_val;          // MULT
                        2'b11: node_value[cur_addr] = left_val >>> right_val[5:0];   // ASR
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


task update_golden_calc_task;
    input [5:0] src_row;
    reg [15:0] root_addr;
    integer b;
begin
    for (b = 0; b < 4; b = b + 1) begin
        root_addr = {b[1:0], src_row, 8'd0};
        calc_tree_no_recursive_task(root_addr, golden_calc_result[b]);
    end

    // $display("============================================================");
    // $display("[GOLDEN_CALC] src_row = %0d", src_row);
    // $display("Bank0 = %0d (0x%h)", $signed(golden_calc_result[0]), golden_calc_result[0]);
    // $display("Bank1 = %0d (0x%h)", $signed(golden_calc_result[1]), golden_calc_result[1]);
    // $display("Bank2 = %0d (0x%h)", $signed(golden_calc_result[2]), golden_calc_result[2]);
    // $display("Bank3 = %0d (0x%h)", $signed(golden_calc_result[3]), golden_calc_result[3]);
    // $display("============================================================");
end
endtask




endmodule

