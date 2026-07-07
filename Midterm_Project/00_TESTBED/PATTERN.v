//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2026 Spring Midterm Project: Dual-Core CPU
//   Author                           : Ying-Yu Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN.v
//   Release version : V1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "../00_TESTBED/DRAM_MAP_define.v"
`include "../00_TESTBED/pseudo_DRAM_inst1.v"
`include "../00_TESTBED/pseudo_DRAM_inst2.v"
`include "../00_TESTBED/pseudo_DRAM_data.v"

`ifdef RTL
    `define CYCLE_TIME 3.5
`elsif GATE
    `define CYCLE_TIME 3.5
`elsif CHIP
    `define CYCLE_TIME 3.5
`elsif POST
    `define CYCLE_TIME 3.5
`endif

`ifdef FUNC
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define MAX_WAIT_READY_CYCLE 100000
`endif

// Directed test: covers corner cases, forward/backward branch and jump,
// and loop-based memory access patterns.
// Both cores execute the same number of ICs and eventually reach PC = 0x1FFE.

// random test: random generate instructions (only forward jump/branch) 
// in random test, instruction counts will be multiple of 50 
//(it won't reach 0x1ffe, but I think it can still work since I'm sure it will run 50x ICs)


//============================================================
// Test mode selection
//============================================================
// Select the test mode by setting TEST_TYPE.
//
// TEST_TYPE = 0: Run randomly generated instruction patterns.
//
// TEST_TYPE = 1: Run hand-written directed patterns.
//
//============================================================

// 0 for random, 1 for direct.
`define TEST_TYPE 0

// (can adjust)
`ifndef SEED
`define SEED 69
`endif 
// (can adjust)
// jump target max can be up to 128
// jump target min: 1
`ifndef JUMP_MAX
`define JUMP_MAX 128
`endif
`define JUMP_MIN 1
// (can adjust)
// branch target max can be up to 63
// branch target min: 0
`ifndef BRANCH_MAX
`define BRANCH_MAX 63
`endif
`define BRANCH_MIN 0

// 0x1000 ~ 0x2FFE (can adjust)
`ifndef MEM_START_ACCESS_ADDR
`define MEM_START_ACCESS_ADDR 16'h1300
`endif 

module PATTERN(
    clk,
    rst_n,
    stall_1,
    stall_2,
//===== AXI-4 Instruction1 DRAM =====
    arid_s_inf_inst_1,
    araddr_s_inf_inst_1,
    arlen_s_inf_inst_1,
    arsize_s_inf_inst_1,
    arburst_s_inf_inst_1,
    arvalid_s_inf_inst_1,
    arready_s_inf_inst_1,

    rid_s_inf_inst_1,
    rdata_s_inf_inst_1,
    rresp_s_inf_inst_1,
    rlast_s_inf_inst_1,
    rvalid_s_inf_inst_1,
    rready_s_inf_inst_1,

    awid_s_inf_inst_1,
    awaddr_s_inf_inst_1,
    awsize_s_inf_inst_1,
    awburst_s_inf_inst_1,
    awlen_s_inf_inst_1,
    awvalid_s_inf_inst_1,
    awready_s_inf_inst_1,

    wdata_s_inf_inst_1,
    wlast_s_inf_inst_1,
    wvalid_s_inf_inst_1,
    wready_s_inf_inst_1,

    bid_s_inf_inst_1,
    bresp_s_inf_inst_1,
    bvalid_s_inf_inst_1,
    bready_s_inf_inst_1,
//===== AXI-4 Instruction2 DRAM =====
    arid_s_inf_inst_2,
    araddr_s_inf_inst_2,
    arlen_s_inf_inst_2,
    arsize_s_inf_inst_2,
    arburst_s_inf_inst_2,
    arvalid_s_inf_inst_2,
    arready_s_inf_inst_2,

    rid_s_inf_inst_2,
    rdata_s_inf_inst_2,
    rresp_s_inf_inst_2,
    rlast_s_inf_inst_2,
    rvalid_s_inf_inst_2,
    rready_s_inf_inst_2,

    awid_s_inf_inst_2,
    awaddr_s_inf_inst_2,
    awsize_s_inf_inst_2,
    awburst_s_inf_inst_2,
    awlen_s_inf_inst_2,
    awvalid_s_inf_inst_2,
    awready_s_inf_inst_2,

    wdata_s_inf_inst_2,
    wlast_s_inf_inst_2,
    wvalid_s_inf_inst_2,
    wready_s_inf_inst_2,

    bid_s_inf_inst_2,
    bresp_s_inf_inst_2,
    bvalid_s_inf_inst_2,
    bready_s_inf_inst_2,
//===== AXI-4 Data Memory =====
    arid_s_inf_data,
    araddr_s_inf_data,
    arlen_s_inf_data,
    arsize_s_inf_data,
    arburst_s_inf_data,
    arvalid_s_inf_data,
    arready_s_inf_data,

    rid_s_inf_data,
    rdata_s_inf_data,
    rresp_s_inf_data,
    rlast_s_inf_data,
    rvalid_s_inf_data,
    rready_s_inf_data,

    awid_s_inf_data,
    awaddr_s_inf_data,
    awsize_s_inf_data,
    awburst_s_inf_data,
    awlen_s_inf_data,
    awvalid_s_inf_data,
    awready_s_inf_data,

    wdata_s_inf_data,
    wlast_s_inf_data,
    wvalid_s_inf_data,
    wready_s_inf_data,

    bid_s_inf_data,
    bresp_s_inf_data,
    bvalid_s_inf_data,
    bready_s_inf_data
);

output reg  clk, rst_n;
input  wire stall_1, stall_2;

parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=16, BURST_LEN=7;

input  wire [ID_WIDTH-1:0]   arid_s_inf_inst_1;
input  wire [ADDR_WIDTH-1:0] araddr_s_inf_inst_1;
input  wire [BURST_LEN-1:0]  arlen_s_inf_inst_1;
input  wire [2:0]            arsize_s_inf_inst_1;
input  wire [1:0]            arburst_s_inf_inst_1;
input  wire                  arvalid_s_inf_inst_1;
output wire                  arready_s_inf_inst_1;

output wire [ID_WIDTH-1:0]   rid_s_inf_inst_1;
output wire [DATA_WIDTH-1:0] rdata_s_inf_inst_1;
output wire [1:0]            rresp_s_inf_inst_1;
output wire                  rlast_s_inf_inst_1;
output wire                  rvalid_s_inf_inst_1;
input  wire                  rready_s_inf_inst_1;

input  wire [ID_WIDTH-1:0]   awid_s_inf_inst_1;
input  wire [ADDR_WIDTH-1:0] awaddr_s_inf_inst_1;
input  wire [2:0]            awsize_s_inf_inst_1;
input  wire [1:0]            awburst_s_inf_inst_1;
input  wire [BURST_LEN-1:0]  awlen_s_inf_inst_1;
input  wire                  awvalid_s_inf_inst_1;
output wire                  awready_s_inf_inst_1;

input  wire [DATA_WIDTH-1:0] wdata_s_inf_inst_1;
input  wire                  wlast_s_inf_inst_1;
input  wire                  wvalid_s_inf_inst_1;
output wire                  wready_s_inf_inst_1;

output wire [ID_WIDTH-1:0]   bid_s_inf_inst_1;
output wire [1:0]            bresp_s_inf_inst_1;
output wire                  bvalid_s_inf_inst_1;
input  wire                  bready_s_inf_inst_1;

input  wire [ID_WIDTH-1:0]   arid_s_inf_inst_2;
input  wire [ADDR_WIDTH-1:0] araddr_s_inf_inst_2;
input  wire [BURST_LEN-1:0]  arlen_s_inf_inst_2;
input  wire [2:0]            arsize_s_inf_inst_2;
input  wire [1:0]            arburst_s_inf_inst_2;
input  wire                  arvalid_s_inf_inst_2;
output wire                  arready_s_inf_inst_2;

output wire [ID_WIDTH-1:0]   rid_s_inf_inst_2;
output wire [DATA_WIDTH-1:0] rdata_s_inf_inst_2;
output wire [1:0]            rresp_s_inf_inst_2;
output wire                  rlast_s_inf_inst_2;
output wire                  rvalid_s_inf_inst_2;
input  wire                  rready_s_inf_inst_2;

input  wire [ID_WIDTH-1:0]   awid_s_inf_inst_2;
input  wire [ADDR_WIDTH-1:0] awaddr_s_inf_inst_2;
input  wire [2:0]            awsize_s_inf_inst_2;
input  wire [1:0]            awburst_s_inf_inst_2;
input  wire [BURST_LEN-1:0]  awlen_s_inf_inst_2;
input  wire                  awvalid_s_inf_inst_2;
output wire                  awready_s_inf_inst_2;

input  wire [DATA_WIDTH-1:0] wdata_s_inf_inst_2;
input  wire                  wlast_s_inf_inst_2;
input  wire                  wvalid_s_inf_inst_2;
output wire                  wready_s_inf_inst_2;

output wire [ID_WIDTH-1:0]   bid_s_inf_inst_2;
output wire [1:0]            bresp_s_inf_inst_2;
output wire                  bvalid_s_inf_inst_2;
input  wire                  bready_s_inf_inst_2;

input  wire [ID_WIDTH-1:0]   arid_s_inf_data;
input  wire [ADDR_WIDTH-1:0] araddr_s_inf_data;
input  wire [BURST_LEN-1:0]  arlen_s_inf_data;
input  wire [2:0]            arsize_s_inf_data;
input  wire [1:0]            arburst_s_inf_data;
input  wire                  arvalid_s_inf_data;
output wire                  arready_s_inf_data;

output wire [ID_WIDTH-1:0]   rid_s_inf_data;
output wire [DATA_WIDTH-1:0] rdata_s_inf_data;
output wire [1:0]            rresp_s_inf_data;
output wire                  rlast_s_inf_data;
output wire                  rvalid_s_inf_data;
input  wire                  rready_s_inf_data;

input  wire [ID_WIDTH-1:0]   awid_s_inf_data;
input  wire [ADDR_WIDTH-1:0] awaddr_s_inf_data;
input  wire [2:0]            awsize_s_inf_data;
input  wire [1:0]            awburst_s_inf_data;
input  wire [BURST_LEN-1:0]  awlen_s_inf_data;
input  wire                  awvalid_s_inf_data;
output wire                  awready_s_inf_data;

input  wire [DATA_WIDTH-1:0] wdata_s_inf_data;
input  wire                  wlast_s_inf_data;
input  wire                  wvalid_s_inf_data;
output wire                  wready_s_inf_data;

output wire [ID_WIDTH-1:0]   bid_s_inf_data;
output wire [1:0]            bresp_s_inf_data;
output wire                  bvalid_s_inf_data;
input  wire                  bready_s_inf_data;

pseudo_DRAM_inst1 u_DRAM_inst1 (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf   (awid_s_inf_inst_1),
    .awaddr_s_inf (awaddr_s_inf_inst_1),
    .awsize_s_inf (awsize_s_inf_inst_1),
    .awburst_s_inf(awburst_s_inf_inst_1),
    .awlen_s_inf  (awlen_s_inf_inst_1),
    .awvalid_s_inf(awvalid_s_inf_inst_1),
    .awready_s_inf(awready_s_inf_inst_1),
    .wdata_s_inf  (wdata_s_inf_inst_1),
    .wlast_s_inf  (wlast_s_inf_inst_1),
    .wvalid_s_inf (wvalid_s_inf_inst_1),
    .wready_s_inf (wready_s_inf_inst_1),
    .bid_s_inf    (bid_s_inf_inst_1),
    .bresp_s_inf  (bresp_s_inf_inst_1),
    .bvalid_s_inf (bvalid_s_inf_inst_1),
    .bready_s_inf (bready_s_inf_inst_1),
    .arid_s_inf   (arid_s_inf_inst_1),
    .araddr_s_inf (araddr_s_inf_inst_1),
    .arlen_s_inf  (arlen_s_inf_inst_1),
    .arsize_s_inf (arsize_s_inf_inst_1),
    .arburst_s_inf(arburst_s_inf_inst_1),
    .arvalid_s_inf(arvalid_s_inf_inst_1),
    .arready_s_inf(arready_s_inf_inst_1),
    .rid_s_inf    (rid_s_inf_inst_1),
    .rdata_s_inf  (rdata_s_inf_inst_1),
    .rresp_s_inf  (rresp_s_inf_inst_1),
    .rlast_s_inf  (rlast_s_inf_inst_1),
    .rvalid_s_inf (rvalid_s_inf_inst_1),
    .rready_s_inf (rready_s_inf_inst_1)
);

pseudo_DRAM_inst2 u_DRAM_inst2 (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf   (awid_s_inf_inst_2),
    .awaddr_s_inf (awaddr_s_inf_inst_2),
    .awsize_s_inf (awsize_s_inf_inst_2),
    .awburst_s_inf(awburst_s_inf_inst_2),
    .awlen_s_inf  (awlen_s_inf_inst_2),
    .awvalid_s_inf(awvalid_s_inf_inst_2),
    .awready_s_inf(awready_s_inf_inst_2),
    .wdata_s_inf  (wdata_s_inf_inst_2),
    .wlast_s_inf  (wlast_s_inf_inst_2),
    .wvalid_s_inf (wvalid_s_inf_inst_2),
    .wready_s_inf (wready_s_inf_inst_2),
    .bid_s_inf    (bid_s_inf_inst_2),
    .bresp_s_inf  (bresp_s_inf_inst_2),
    .bvalid_s_inf (bvalid_s_inf_inst_2),
    .bready_s_inf (bready_s_inf_inst_2),
    .arid_s_inf   (arid_s_inf_inst_2),
    .araddr_s_inf (araddr_s_inf_inst_2),
    .arlen_s_inf  (arlen_s_inf_inst_2),
    .arsize_s_inf (arsize_s_inf_inst_2),
    .arburst_s_inf(arburst_s_inf_inst_2),
    .arvalid_s_inf(arvalid_s_inf_inst_2),
    .arready_s_inf(arready_s_inf_inst_2),
    .rid_s_inf    (rid_s_inf_inst_2),
    .rdata_s_inf  (rdata_s_inf_inst_2),
    .rresp_s_inf  (rresp_s_inf_inst_2),
    .rlast_s_inf  (rlast_s_inf_inst_2),
    .rvalid_s_inf (rvalid_s_inf_inst_2),
    .rready_s_inf (rready_s_inf_inst_2)
);

pseudo_DRAM_data u_DRAM_data (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf   (awid_s_inf_data),
    .awaddr_s_inf (awaddr_s_inf_data),
    .awsize_s_inf (awsize_s_inf_data),
    .awburst_s_inf(awburst_s_inf_data),
    .awlen_s_inf  (awlen_s_inf_data),
    .awvalid_s_inf(awvalid_s_inf_data),
    .awready_s_inf(awready_s_inf_data),
    .wdata_s_inf  (wdata_s_inf_data),
    .wlast_s_inf  (wlast_s_inf_data),
    .wvalid_s_inf (wvalid_s_inf_data),
    .wready_s_inf (wready_s_inf_data),
    .bid_s_inf    (bid_s_inf_data),
    .bresp_s_inf  (bresp_s_inf_data),
    .bvalid_s_inf (bvalid_s_inf_data),
    .bready_s_inf (bready_s_inf_data),
    .arid_s_inf   (arid_s_inf_data),
    .araddr_s_inf (araddr_s_inf_data),
    .arlen_s_inf  (arlen_s_inf_data),
    .arsize_s_inf (arsize_s_inf_data),
    .arburst_s_inf(arburst_s_inf_data),
    .arvalid_s_inf(arvalid_s_inf_data),
    .arready_s_inf(arready_s_inf_data),
    .rid_s_inf    (rid_s_inf_data),
    .rdata_s_inf  (rdata_s_inf_data),
    .rresp_s_inf  (rresp_s_inf_data),
    .rlast_s_inf  (rlast_s_inf_data),
    .rvalid_s_inf (rvalid_s_inf_data),
    .rready_s_inf (rready_s_inf_data)
);


parameter CYCLE     = `CYCLE_TIME;
parameter MAX_CYCLE = `MAX_WAIT_READY_CYCLE;

parameter INST1_BASE  = 32'h0000_0000;
parameter INST2_BASE  = 32'h0000_0000;
parameter DATA_BASE   = 32'h0000_1000;
parameter DATA_TOP    = 32'h0000_2FFF;

parameter INST_DEPTH  = 4096;
parameter DATA_DEPTH  = 4096;

// NOTE: DATA_ACC_LO/HI are BYTE addresses (range that LS may access).
// Byte addresses come out of the effective-address formula directly.
parameter DATA_ACC_LO = 16'h1000;   // first legal byte addr
parameter DATA_ACC_HI = 16'h2FFE;   // last legal byte addr of a word (word ends at 0x2FFF)
parameter INST_ACC_HI = 13'h1FFF;

string reset_color        = "\033[1;0m";
string txt_red_prefix     = "\033[1;31m";
string txt_green_prefix   = "\033[1;32m";
string txt_yellow_prefix  = "\033[1;33m";
string txt_blue_prefix    = "\033[1;34m";
string txt_magenta_prefix = "\033[1;35m";
string txt_cyan_prefix    = "\033[1;36m";

integer ic_1, ic_2;
integer total_latency;
integer total_latency1, total_latency2;
reg [15:0] golden_inst1_DRAM [0:INST_DEPTH-1];
reg [15:0] golden_inst2_DRAM [0:INST_DEPTH-1];

// golden_data_DRAM: BYTE-ADDRESSABLE, mirrors u_DRAM_data.DRAM_r.
// Each entry holds ONE BYTE. A 16-bit word at byte-addr A uses
//   low byte  = golden_data_DRAM[A]
//   high byte = golden_data_DRAM[A+1]
reg [7:0]  golden_data_DRAM  [0:DATA_TOP];

reg signed [15:0] golden_reg_c1 [0:7];
reg signed [15:0] golden_reg_c2 [0:7];

reg [12:0] pc_1, pc_2;
reg pc_1_done, pc_2_done;
integer total_step;
// integer f_in;
reg [15:0] inst_c1, inst_c2;
reg [2:0]  op_c1,  op_c2;
reg [3:0]  rs_c1,  rs_c2;
reg [3:0]  rt_c1,  rt_c2;
reg [3:0]  rd_c1,  rd_c2;
reg        func_c1, func_c2;
reg signed [4:0]  imm_c1, imm_c2;
reg signed [12:0] addr_c1, addr_c2;

reg        c2_is_store_pending;
reg [15:0] c2_store_addr_pending;
reg [15:0] c2_store_data_pending;
integer inst_count;
always #(`CYCLE_TIME / 2.0) clk = ~clk;
initial clk = 0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) total_latency <= 0;
    else        total_latency <= total_latency + 1;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) total_latency1 <= 0;
    else  if(stall_1 === 1) total_latency1 <= total_latency1 + 1;
    else total_latency1 <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) total_latency2 <= 0;
    else  if(stall_2 === 1) total_latency2 <= total_latency2 + 1;
    else total_latency2 <= 0;
end
always @(*) begin
    if (total_latency1 >= MAX_CYCLE || total_latency2 >= MAX_CYCLE) begin
        $display("====================================================================");
        $display("  %0sFAIL%0s  Total latency exceeded MAX_WAIT_READY_CYCLE = %0d",
                 txt_red_prefix, reset_color, MAX_CYCLE);
        $display("====================================================================");
        $finish;
    end
end
integer  a;
initial begin
    a = $urandom(`SEED);
    total_latency = 0;
    total_latency1 = 0;
    total_latency2 = 0;
    ic_1 = 0;
    ic_2 = 0;
    total_step = 0;
    pc_1_done = 0;
    pc_2_done = 0;
    reset_task;
    if (`TEST_TYPE == 1) begin
        gen_dram_files_task_direct;
    end
    else begin
        gen_dram_files_task_random;
    end
    
    $readmemh("../00_TESTBED/DRAM/inst_1_dram_file.dat", u_DRAM_inst1.DRAM_r);
    $readmemh("../00_TESTBED/DRAM/inst_2_dram_file.dat", u_DRAM_inst2.DRAM_r);
    $readmemh("../00_TESTBED/DRAM/data_dram_file.dat", u_DRAM_data.DRAM_r);
    set_env_task;
    run_simulation_task;
    you_pass_task;
end

task check_reset_signals; begin
    if (stall_1 !== 1'b1 || stall_2 !== 1'b1) begin
        $display("FAIL: stall must be HIGH after reset, got stall_1=%b stall_2=%b", stall_1, stall_2);
        $finish;
    end
    if (TESTBED.u_DCCPU.core_1_r0 !== 16'h0) begin $display("FAIL: core_1_r0 not reset, got %h", TESTBED.u_DCCPU.core_1_r0); $finish; end
    if (TESTBED.u_DCCPU.core_1_r1 !== 16'h0) begin $display("FAIL: core_1_r1 not reset, got %h", TESTBED.u_DCCPU.core_1_r1); $finish; end
    if (TESTBED.u_DCCPU.core_1_r2 !== 16'h0) begin $display("FAIL: core_1_r2 not reset, got %h", TESTBED.u_DCCPU.core_1_r2); $finish; end
    if (TESTBED.u_DCCPU.core_1_r3 !== 16'h0) begin $display("FAIL: core_1_r3 not reset, got %h", TESTBED.u_DCCPU.core_1_r3); $finish; end
    if (TESTBED.u_DCCPU.core_1_r4 !== 16'h0) begin $display("FAIL: core_1_r4 not reset, got %h", TESTBED.u_DCCPU.core_1_r4); $finish; end
    if (TESTBED.u_DCCPU.core_1_r5 !== 16'h0) begin $display("FAIL: core_1_r5 not reset, got %h", TESTBED.u_DCCPU.core_1_r5); $finish; end
    if (TESTBED.u_DCCPU.core_1_r6 !== 16'h0) begin $display("FAIL: core_1_r6 not reset, got %h", TESTBED.u_DCCPU.core_1_r6); $finish; end
    if (TESTBED.u_DCCPU.core_1_r7 !== 16'h0) begin $display("FAIL: core_1_r7 not reset, got %h", TESTBED.u_DCCPU.core_1_r7); $finish; end

    if (TESTBED.u_DCCPU.core_2_r0 !== 16'h0) begin $display("FAIL: core_2_r0 not reset, got %h", TESTBED.u_DCCPU.core_2_r0); $finish; end
    if (TESTBED.u_DCCPU.core_2_r1 !== 16'h0) begin $display("FAIL: core_2_r1 not reset, got %h", TESTBED.u_DCCPU.core_2_r1); $finish; end
    if (TESTBED.u_DCCPU.core_2_r2 !== 16'h0) begin $display("FAIL: core_2_r2 not reset, got %h", TESTBED.u_DCCPU.core_2_r2); $finish; end
    if (TESTBED.u_DCCPU.core_2_r3 !== 16'h0) begin $display("FAIL: core_2_r3 not reset, got %h", TESTBED.u_DCCPU.core_2_r3); $finish; end
    if (TESTBED.u_DCCPU.core_2_r4 !== 16'h0) begin $display("FAIL: core_2_r4 not reset, got %h", TESTBED.u_DCCPU.core_2_r4); $finish; end
    if (TESTBED.u_DCCPU.core_2_r5 !== 16'h0) begin $display("FAIL: core_2_r5 not reset, got %h", TESTBED.u_DCCPU.core_2_r5); $finish; end
    if (TESTBED.u_DCCPU.core_2_r6 !== 16'h0) begin $display("FAIL: core_2_r6 not reset, got %h", TESTBED.u_DCCPU.core_2_r6); $finish; end
    if (TESTBED.u_DCCPU.core_2_r7 !== 16'h0) begin $display("FAIL: core_2_r7 not reset, got %h", TESTBED.u_DCCPU.core_2_r7); $finish; end
end endtask

task reset_task; begin
    integer i;
    rst_n = 1'b1;
    pc_1  = 0;
    pc_2  = 0;
    for (i = 0; i < 8; i = i + 1) begin
        golden_reg_c1[i] = 16'sd0;
        golden_reg_c2[i] = 16'sd0;
    end
    c2_is_store_pending   = 1'b0;
    c2_store_addr_pending = 16'h0;
    c2_store_data_pending = 16'h0;

    force clk = 1'b0;
    #CYCLE; rst_n = 1'b0;
    repeat(3) #CYCLE;
    check_reset_signals;
    rst_n = 1'b1;
    #(3 * CYCLE); release clk;
end endtask

task set_env_task; begin
    integer i;
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        golden_inst1_DRAM[i] = {u_DRAM_inst1.DRAM_r[i*2+1], u_DRAM_inst1.DRAM_r[i*2]};
        golden_inst2_DRAM[i] = {u_DRAM_inst2.DRAM_r[i*2+1], u_DRAM_inst2.DRAM_r[i*2]};
    end
    // Byte-by-byte copy of data DRAM.
    for (i = 0; i <= DATA_TOP; i = i + 1) begin
        golden_data_DRAM[i] = u_DRAM_data.DRAM_r[i];
    end
end endtask

task run_simulation_task; begin
    integer step;

    ic_1 = -1;
    ic_2 = -1;

    @(negedge clk);
    @(negedge clk);

    for (step = 0; ; step = step + 1) begin
        
        wait_stall_low_task(1);
        wait_stall_low_task(2);

        @(negedge clk);
        ic_1 = ic_1 + 1;
        ic_2 = ic_2 + 1;

        check_ic_ordering_task;
        execute_golden_task;
        check_registers_task(step);

        $display("%0s[IC %4d] both cores executed | Latency so far: %0d%0s",
                 txt_blue_prefix, step, total_latency, reset_color);

        if ((ic_1 == 49) || ((ic_1 > 49) && ((ic_1 + 1) % 50 == 0)) || (pc_1_done && pc_2_done)) begin
            check_dram_task(step);
        end
        if(ic_1 == inst_count - 1) begin
            total_step = inst_count;
            break;
        end
        
    end
end endtask

task wait_stall_low_task;
    input integer core_id;
    begin
        if (core_id == 1) begin
            while (stall_1 !== 1'b0) @(negedge clk);
        end else begin
            while (stall_2 !== 1'b0) @(negedge clk);
        end
    end
endtask

task check_ic_ordering_task; begin
    if ((ic_1 - ic_2) > 1) begin
        $display("====================================================================");
        $display("  %0sFAIL%0s  Rule R1 violated: ic_1=%0d > ic_2+1=%0d",
                 txt_red_prefix, reset_color, ic_1, ic_2 + 1);
        $display("====================================================================");
        $finish;
    end
end endtask

task execute_golden_task; begin
    reg [2:0]  op1g, op2g;
    reg [2:0]  rs1g, rt1g, rd1g, rl1g, sub1g;
    reg [2:0]  rs2g, rt2g, rd2g, rl2g, sub2g;
    reg signed [6:0]  imm1g_raw, imm2g_raw;
    reg signed [15:0] imm1g_ext, imm2g_ext;
    reg [12:0] addr1g, addr2g;

    reg signed [17:0] word_off1, word_off2;
    reg        [15:0] eff_addr1, eff_addr2;   // byte addr (low byte)
    reg        [15:0] old_mem1, old_mem2;     // 16-bit word
    reg        [31:0] prod1, prod2;

    reg        pending_store1, pending_store2;
    reg [15:0] pending_addr1, pending_addr2;
    reg [15:0] pending_data1, pending_data2;
    reg [15:0] addr1_in_cache, addr2_in_cache;

    integer cur_pc1, cur_pc2;
    integer nxt_pc1, nxt_pc2;
    integer beq_tgt1, beq_tgt2;
    integer jump_delta1, jump_delta2;
    integer max_inst_addr;

    max_inst_addr = (INST_DEPTH - 1) << 1;

    if (pc_1[0] !== 1'b0 || pc_2[0] !== 1'b0) begin
        $display("  %0sPATTERN ERROR%0s  Odd PC  pc_1=0x%04h pc_2=0x%04h",
                 txt_red_prefix, reset_color, pc_1, pc_2);
        $finish;
    end

    if ((pc_1 > max_inst_addr) || (pc_2 > max_inst_addr)) begin
        $display("  %0sPATTERN ERROR%0s  PC out of range  pc_1=0x%04h pc_2=0x%04h max=0x%04h",
                 txt_red_prefix, reset_color, pc_1, pc_2, max_inst_addr);
        $finish;
    end
    // $display("pc1 = 0x%04h  pc2 = 0x%04h", pc_1, pc_2);
    inst_c1 = golden_inst1_DRAM[pc_1 >> 1];
    inst_c2 = golden_inst2_DRAM[pc_2 >> 1];
    
    decode_and_print_instr(0, pc_1, inst_c1);
    decode_and_print_instr(1, pc_2, inst_c2);
    op1g      = inst_c1[15:13];
    rs1g      = inst_c1[12:10];
    rt1g      = inst_c1[9:7];
    rd1g      = inst_c1[6:4];
    rl1g      = inst_c1[3:1];
    sub1g     = inst_c1[3:1];
    imm1g_raw = inst_c1[6:0];
    imm1g_ext = {{9{imm1g_raw[6]}}, imm1g_raw};
    addr1g    = inst_c1[12:0];

    op2g      = inst_c2[15:13];
    rs2g      = inst_c2[12:10];
    rt2g      = inst_c2[9:7];
    rd2g      = inst_c2[6:4];
    rl2g      = inst_c2[3:1];
    sub2g     = inst_c2[3:1];
    imm2g_raw = inst_c2[6:0];
    imm2g_ext = {{9{imm2g_raw[6]}}, imm2g_raw};
    addr2g    = inst_c2[12:0];

    cur_pc1 = pc_1;
    cur_pc2 = pc_2;

    // BEQ / JUMP legality (unchanged)
    if (op1g == 3'b110) begin
        beq_tgt1 = cur_pc1 + 2 + (imm1g_ext * 2);
        if ((beq_tgt1 & 1) != 0 || beq_tgt1 < 0 || beq_tgt1 > max_inst_addr) begin
            $display("  %0sPATTERN ERROR%0s  Core1 BEQ target illegal  pc=0x%04h tgt=0x%04h",
                     txt_red_prefix, reset_color, cur_pc1, beq_tgt1);
            $finish;
        end
    end
    if (op2g == 3'b110) begin
        beq_tgt2 = cur_pc2 + 2 + (imm2g_ext*2);
        if ((beq_tgt2 & 1) != 0 || beq_tgt2 < 0 || beq_tgt2 > max_inst_addr) begin
            $display("  %0sPATTERN ERROR%0s  Core2 BEQ target illegal  pc=0x%04h tgt=0x%04h",
                     txt_red_prefix, reset_color, cur_pc2, beq_tgt2);
            $finish;
        end
    end
    if (op1g == 3'b111) begin
        jump_delta1 = (addr1g >= cur_pc1) ? (addr1g - cur_pc1) : (cur_pc1 - addr1g);
        if (addr1g[0] != 1'b0 || addr1g > max_inst_addr || jump_delta1 > 256) begin
            $display("  %0sPATTERN ERROR%0s  Core1 JUMP illegal  pc=0x%04h tgt=0x%04h |d|=%0d",
                     txt_red_prefix, reset_color, cur_pc1, addr1g, jump_delta1);
            $finish;
        end
    end
    if (op2g == 3'b111) begin
        jump_delta2 = (addr2g >= cur_pc2) ? (addr2g - cur_pc2) : (cur_pc2 - addr2g);
        if (addr2g[0] != 1'b0 || addr2g > max_inst_addr || jump_delta2 > 256) begin
            $display("  %0sPATTERN ERROR%0s  Core2 JUMP illegal  pc=0x%04h tgt=0x%04h |d|=%0d",
                     txt_red_prefix, reset_color, cur_pc2, addr2g, jump_delta2);
            $finish;
        end
    end

    // --------------------------------------------------------------
    // Effective BYTE address (ISA spec): eff = (signed(rs)+imm)*2 + 0x1000
    // --------------------------------------------------------------
    word_off1 = $signed(golden_reg_c1[rs1g]) + $signed(imm1g_ext);
    word_off2 = $signed(golden_reg_c2[rs2g]) + $signed(imm2g_ext);
    eff_addr1 = (word_off1 <<< 1) + 16'h1000;
    eff_addr2 = (word_off2 <<< 1) + 16'h1000;

    // Range check (byte-addr based).
    if ((op1g == 3'b100) || (op1g == 3'b101)) begin
        if ((eff_addr1[0] != 1'b0) || (eff_addr1 < DATA_ACC_LO) || (eff_addr1 > DATA_ACC_HI)) begin
            $display("  %0sPATTERN ERROR%0s  Core1 data addr illegal  pc=0x%04h rs=r%0d(=%0d) imm=%0d eff=0x%04h",
                     txt_red_prefix, reset_color, cur_pc1, rs1g, $signed(golden_reg_c1[rs1g]), imm1g_ext, eff_addr1);
            $finish;
        end
    end
    if ((op2g == 3'b100) || (op2g == 3'b101)) begin
        if ((eff_addr2[0] != 1'b0) || (eff_addr2 < DATA_ACC_LO) || (eff_addr2 > DATA_ACC_HI)) begin
            $display("  %0sPATTERN ERROR%0s  Core2 data addr illegal  pc=0x%04h rs=r%0d(=%0d) imm=%0d eff=0x%04h",
                     txt_red_prefix, reset_color, cur_pc2, rs2g, $signed(golden_reg_c2[rs2g]), imm2g_ext, eff_addr2);
            $finish;
        end
    end

    // --------------------------------------------------------------
    // Read current word values BEFORE any store commits.
    //   word = { high_byte, low_byte } = { mem[BA+1], mem[BA] }
    // --------------------------------------------------------------
    old_mem1 = {golden_data_DRAM[eff_addr1 + 1], golden_data_DRAM[eff_addr1]};
    old_mem2 = {golden_data_DRAM[eff_addr2 + 1], golden_data_DRAM[eff_addr2]};

    pending_store1 = (op1g == 3'b101);
    pending_store2 = (op2g == 3'b101);
    pending_addr1  = eff_addr1;
    pending_addr2  = eff_addr2;
    pending_data1  = golden_reg_c1[rt1g];
    pending_data2  = golden_reg_c2[rt2g];

    if (pending_store1 && pending_store2) begin
        $display("  %0sPATTERN ERROR%0s  Rule R3: both cores STORE in same cycle  pc_1=0x%04h pc_2=0x%04h",
                 txt_red_prefix, reset_color, cur_pc1, cur_pc2);
        $finish;
    end

    nxt_pc1 = cur_pc1 + 2;
    nxt_pc2 = cur_pc2 + 2;

    // --------------------------------------------------------------
    // Execute core1
    // --------------------------------------------------------------
    case (op1g)
        3'b000: begin
            case (sub1g)
                3'b000: golden_reg_c1[rd1g] =  golden_reg_c1[rs1g] + golden_reg_c1[rt1g];
                3'b001: golden_reg_c1[rd1g] =  golden_reg_c1[rs1g] - golden_reg_c1[rt1g];
                3'b010: golden_reg_c1[rd1g] =  golden_reg_c1[rs1g] & golden_reg_c1[rt1g];
                3'b011: golden_reg_c1[rd1g] =  golden_reg_c1[rs1g] | golden_reg_c1[rt1g];
                3'b100: golden_reg_c1[rd1g] = ~(golden_reg_c1[rs1g] & golden_reg_c1[rt1g]);
                3'b101: golden_reg_c1[rd1g] = ~(golden_reg_c1[rs1g] | golden_reg_c1[rt1g]);
                3'b110: golden_reg_c1[rd1g] =  golden_reg_c1[rs1g] ^ golden_reg_c1[rt1g];
                3'b111: golden_reg_c1[rd1g] = ($signed(golden_reg_c1[rs1g]) < $signed(golden_reg_c1[rt1g])) ? 16'h0001 : 16'h0000;
            endcase
        end
        3'b001: begin
            prod1 = golden_reg_c1[rs1g] * golden_reg_c1[rt1g];
            golden_reg_c1[rd1g] = prod1[31:16];
            golden_reg_c1[rl1g] = prod1[15:0];
        end
        3'b010: golden_reg_c1[rt1g] = golden_reg_c1[rs1g] + imm1g_ext;
        3'b011: golden_reg_c1[rt1g] = golden_reg_c1[rs1g] - imm1g_ext;
        3'b100: begin
            // LOAD: if c2 stores to same addr this cycle, c1 sees NEW.
            if (pending_store2 && (pending_addr2 == eff_addr1))
                golden_reg_c1[rt1g] = pending_data2;
            else
                golden_reg_c1[rt1g] = old_mem1;
                $display("core1:load, pc=0x%04h addr=0x%04h data=%x, idx=%b, tag=%b", cur_pc1, eff_addr1, golden_reg_c1[rt1g], eff_addr1[8], eff_addr1[12:9]);
        end
        3'b101: begin /* STORE deferred */ end
        3'b110: if (golden_reg_c1[rs1g] == golden_reg_c1[rt1g]) nxt_pc1 = beq_tgt1;
        3'b111: nxt_pc1 = addr1g;
    endcase
    // $display("op1g = %b", op1g);
    // $display("pending_store1=%b pending_addr1=0x%04h pending_data1=%d", pending_store1, pending_addr1, pending_data1);
    // $display("pending_store2=%b pending_addr2=0x%04h pending_data2=%d", pending_store2, pending_addr2, pending_data2);
    // $display("core1 rf[7]  = %d", golden_reg_c1[7]);
    // --------------------------------------------------------------
    // Execute core2 (c1 STORE + c2 LOAD same addr => c2 sees OLD)
    // --------------------------------------------------------------
    case (op2g)
        3'b000: begin
            case (sub2g)
                3'b000: golden_reg_c2[rd2g] =  golden_reg_c2[rs2g] + golden_reg_c2[rt2g];
                3'b001: golden_reg_c2[rd2g] =  golden_reg_c2[rs2g] - golden_reg_c2[rt2g];
                3'b010: golden_reg_c2[rd2g] =  golden_reg_c2[rs2g] & golden_reg_c2[rt2g];
                3'b011: golden_reg_c2[rd2g] =  golden_reg_c2[rs2g] | golden_reg_c2[rt2g];
                3'b100: golden_reg_c2[rd2g] = ~(golden_reg_c2[rs2g] & golden_reg_c2[rt2g]);
                3'b101: golden_reg_c2[rd2g] = ~(golden_reg_c2[rs2g] | golden_reg_c2[rt2g]);
                3'b110: golden_reg_c2[rd2g] =  golden_reg_c2[rs2g] ^ golden_reg_c2[rt2g];
                3'b111: golden_reg_c2[rd2g] = ($signed(golden_reg_c2[rs2g]) < $signed(golden_reg_c2[rt2g])) ? 16'h0001 : 16'h0000;
            endcase
        end
        3'b001: begin
            prod2 = golden_reg_c2[rs2g] * golden_reg_c2[rt2g];
            golden_reg_c2[rd2g] = prod2[31:16];
            golden_reg_c2[rl2g] = prod2[15:0];
        end
        3'b010: golden_reg_c2[rt2g] = golden_reg_c2[rs2g] + imm2g_ext;
        3'b011: golden_reg_c2[rt2g] = golden_reg_c2[rs2g] - imm2g_ext;
        3'b100: begin
            // LOAD: if c1 stores to same addr this cycle, c1 sees NEW.
            if (pending_store1 && (pending_addr1 == eff_addr2))
                golden_reg_c2[rt2g] = pending_data1;
            else
                golden_reg_c2[rt2g] = old_mem2;
            $display("core2:load, pc=0x%04h addr=0x%04h data=%x, idx=%b, tag=%b", cur_pc2, eff_addr2, golden_reg_c2[rt2g], eff_addr2[8], eff_addr2[12:9]);
        end
        3'b101: begin /* STORE deferred */ end
        3'b110: if (golden_reg_c2[rs2g] == golden_reg_c2[rt2g]) nxt_pc2 = beq_tgt2;
        3'b111: nxt_pc2 = addr2g;
    endcase

    // --------------------------------------------------------------
    // Deferred STORE commit.  Split 16-bit word into two bytes:
    //   mem[BA]   = data[7:0]
    //   mem[BA+1] = data[15:8]
    // Rule R3 already guaranteed at most one STORE per cycle.
    // --------------------------------------------------------------
    if (pending_store1) begin
        golden_data_DRAM[pending_addr1]     = pending_data1[7:0];
        golden_data_DRAM[pending_addr1 + 1] = pending_data1[15:8];
        addr1_in_cache = pending_addr1 - 16'h1000;
        $display("core1:store, pc=0x%04h addr=0x%04h data=%x, idx=%b, tag=%b", cur_pc1, pending_addr1, pending_data1,addr1_in_cache[8], addr1_in_cache[12:9]);
    end
    if (pending_store2) begin
        golden_data_DRAM[pending_addr2]     = pending_data2[7:0];
        golden_data_DRAM[pending_addr2 + 1] = pending_data2[15:8];
        addr2_in_cache = pending_addr2 - 16'h1000;
        $display("core2:store, pc=0x%04h addr=0x%04h data=%x, idx=%b, tag=%b", cur_pc2, pending_addr2, pending_data2, addr2_in_cache[8], addr2_in_cache[12:9]);
    end
    if(pc_1 == 13'h1FFE) pc_1_done = 1;
    if(pc_2 == 13'h1FFE) pc_2_done = 1;
    pc_1 = nxt_pc1;
    pc_2 = nxt_pc2;
end endtask

task check_registers_task;
    input integer step;
    begin
    reg fail;
    fail = 0;

    if (TESTBED.u_DCCPU.core_1_r0 !== golden_reg_c1[0]) begin $display("FAIL core_1_r0 ic=%0d exp=%x got=%x", step, golden_reg_c1[0], TESTBED.u_DCCPU.core_1_r0); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r1 !== golden_reg_c1[1]) begin $display("FAIL core_1_r1 ic=%0d exp=%x got=%x", step, golden_reg_c1[1], TESTBED.u_DCCPU.core_1_r1); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r2 !== golden_reg_c1[2]) begin $display("FAIL core_1_r2 ic=%0d exp=%x got=%x", step, golden_reg_c1[2], TESTBED.u_DCCPU.core_1_r2); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r3 !== golden_reg_c1[3]) begin $display("FAIL core_1_r3 ic=%0d exp=%x got=%x", step, golden_reg_c1[3], TESTBED.u_DCCPU.core_1_r3); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r4 !== golden_reg_c1[4]) begin $display("FAIL core_1_r4 ic=%0d exp=%x got=%x", step, golden_reg_c1[4], TESTBED.u_DCCPU.core_1_r4); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r5 !== golden_reg_c1[5]) begin $display("FAIL core_1_r5 ic=%0d exp=%x got=%x", step, golden_reg_c1[5], TESTBED.u_DCCPU.core_1_r5); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r6 !== golden_reg_c1[6]) begin $display("FAIL core_1_r6 ic=%0d exp=%x got=%x", step, golden_reg_c1[6], TESTBED.u_DCCPU.core_1_r6); fail=1; end
    if (TESTBED.u_DCCPU.core_1_r7 !== golden_reg_c1[7]) begin $display("FAIL core_1_r7 ic=%0d exp=%x got=%x", step, golden_reg_c1[7], TESTBED.u_DCCPU.core_1_r7); fail=1; end

    if (TESTBED.u_DCCPU.core_2_r0 !== golden_reg_c2[0]) begin $display("FAIL core_2_r0 ic=%0d exp=%x got=%x", step, golden_reg_c2[0], TESTBED.u_DCCPU.core_2_r0); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r1 !== golden_reg_c2[1]) begin $display("FAIL core_2_r1 ic=%0d exp=%x got=%x", step, golden_reg_c2[1], TESTBED.u_DCCPU.core_2_r1); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r2 !== golden_reg_c2[2]) begin $display("FAIL core_2_r2 ic=%0d exp=%x got=%x", step, golden_reg_c2[2], TESTBED.u_DCCPU.core_2_r2); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r3 !== golden_reg_c2[3]) begin $display("FAIL core_2_r3 ic=%0d exp=%x got=%x", step, golden_reg_c2[3], TESTBED.u_DCCPU.core_2_r3); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r4 !== golden_reg_c2[4]) begin $display("FAIL core_2_r4 ic=%0d exp=%x got=%x", step, golden_reg_c2[4], TESTBED.u_DCCPU.core_2_r4); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r5 !== golden_reg_c2[5]) begin $display("FAIL core_2_r5 ic=%0d exp=%x got=%x", step, golden_reg_c2[5], TESTBED.u_DCCPU.core_2_r5); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r6 !== golden_reg_c2[6]) begin $display("FAIL core_2_r6 ic=%0d exp=%x got=%x", step, golden_reg_c2[6], TESTBED.u_DCCPU.core_2_r6); fail=1; end
    if (TESTBED.u_DCCPU.core_2_r7 !== golden_reg_c2[7]) begin $display("FAIL core_2_r7 ic=%0d exp=%x got=%x", step, golden_reg_c2[7], TESTBED.u_DCCPU.core_2_r7); fail=1; end

    if (fail) begin
        $display("====================================================================");
        $display("  %0sFAIL%0s  Register mismatch at IC=%0d",
                 txt_red_prefix, reset_color, step);
        $display("====================================================================");
        $finish;
    end
end endtask

// check DRAM: byte-by-byte compare across the accessible range.
task check_dram_task;
    input integer step;
    begin
    integer j;
    reg fail_flag;
    reg [15:0] your_word, gold_word;
    fail_flag = 1;

    // Compare word by word so the log is human-readable.
    for (j = DATA_ACC_LO; j <= DATA_ACC_HI; j = j + 2) begin
        your_word = {u_DRAM_data.DRAM_r[j+1],  u_DRAM_data.DRAM_r[j]};
        gold_word = {golden_data_DRAM[j+1],    golden_data_DRAM[j]};
        if (your_word !== gold_word) begin
            if (fail_flag) begin
                $display("====================================================================");
                $display("  %0sFAIL%0s  DRAM mismatch at IC=%0d",
                         txt_red_prefix, reset_color, step);
                $display("  byte_addr  |  your_word |  golden_word");
                $display("  ---------- | ---------- | -----------");
                fail_flag = 0;
            end
            $display("  0x%04h     |  0x%04h    |  0x%04h",
                     j, your_word, gold_word);
        end
    end

    if (!fail_flag) begin
        $display("====================================================================");
        $finish;
    end
    $display("%0s=== PASS DRAM CHECK at IC=%0d ===%0s",
             txt_green_prefix, step, reset_color);
end endtask

task you_pass_task; begin
    $display("%0s======================================================================", txt_magenta_prefix);
    $display("                          Congratulations!!");
    $display("                    All %0d Instruction Counter Executed", total_step);
    $display("                    All %0d Instructions Executed", total_step*2);
    $display("                       Cycle time = %-2f ns", CYCLE);
    $display("               Your execution cycles = %-4d cycles", total_latency);
    $display("               Your CPIC       = %-2f cycles per instruction counter", (total_latency*1.00) / total_step);
    $display("               Your CPI       = %-2f cycles per instruction", (total_latency*1.00) / (total_step*2));
    $display("======================================================================%0s", reset_color);
    $finish;
end endtask

task gen_dram_files_task_random; begin
    integer fd_i1, fd_i2, fd_d;
    integer i, k;

    reg [15:0] tmp_inst1 [0:INST_DEPTH-1];
    reg [15:0] tmp_inst2 [0:INST_DEPTH-1];

    reg [7:0]  tmp_data_init [0:DATA_TOP];
    reg [7:0]  tmp_data_live [0:DATA_TOP];

    reg signed [15:0] sim_reg_c1 [0:7];
    reg signed [15:0] sim_reg_c2 [0:7];

    reg signed [15:0] rs_val_c1 [0:INST_DEPTH-1];
    reg signed [15:0] rs_val_c2 [0:INST_DEPTH-1];

    reg [15:0] NOP;
    reg [15:0] w_tmp;

    integer pc1, pc2;
    integer pc1_start, pc2_start;

    integer op1, op2;
    integer rs1, rs2, rt1, rt2, rd1, rd2, rl1, rl2;
    integer sub1, sub2, imm1, imm2;
    integer rand_op;

    integer len1, len2, max_len;
    integer gap1, gap2;
    integer lottary, lottary2;
    integer jtarget_word1, jtarget_word2;
    reg [12:0] jfield1, jfield2;

    integer next_ls_eff_byte_c1;

    // Keep the original variable names; although target_word_base1/2 are no longer the main model in the new LS version,
    // their declarations are still kept to maintain compatibility with the original code structure.
    integer target_word_base1, target_word_base2;
    integer delta_word1, delta_word2;
    integer step_word1, step_word2;
    integer eff_byte1, eff_byte2;

    // [MOD-3] Temporary variables required by the LS word-index model.
    integer target_word_idx1, target_word_idx2;
    integer step_rand1, step_rand2;
    integer eff_word_idx1, eff_word_idx2;

    integer TARGET_WORD;
    integer STOP_WORD;

    reg [2:0]        cop, crs, crt, crd, crl, csub;
    reg signed [6:0] cimm;
    reg [12:0]       cjaddr;
    reg [31:0]       eff_byte_addr;
    reg [31:0]       br_tgt_byte;

    reg [31:0]       prod1, prod2;

    integer pc_cur, gap, hop, next_pc, f;
    reg [15:0] tgt_byte;
    reg [12:0] jfield;

    NOP = 16'h0000;

    TARGET_WORD = 4095;
    STOP_WORD   = TARGET_WORD - 180;

    // Not specified: keep using your original file path and f_in variable.
    // f_in = $fopen("../00_TESTBED/op_gen.txt", "w");

    // --------------------------------------------------------
    // Initialize
    // --------------------------------------------------------
    for (i = 0; i < 8; i = i + 1) begin
        sim_reg_c1[i] = 0;
        sim_reg_c2[i] = 0;
    end

    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        tmp_inst1[i] = NOP;
        tmp_inst2[i] = NOP;
        rs_val_c1[i] = 0;
        rs_val_c2[i] = 0;
    end

    for (i = 0; i <= DATA_TOP; i = i + 1)
        tmp_data_init[i] = 8'h00;

    for (i = DATA_ACC_LO; i <= DATA_ACC_HI + 1; i = i + 1)
        tmp_data_init[i] = $urandom_range(255, 0);

    for (i = 0; i <= DATA_TOP; i = i + 1)
        tmp_data_live[i] = tmp_data_init[i];

    pc1 = 0;
    pc2 = 0;
    inst_count = 0;

    next_ls_eff_byte_c1 = `MEM_START_ACCESS_ADDR;

    // --------------------------------------------------------
    // Prologue: ADDI r1..r7 = 1..7
    // Each loop = 1 IC
    // --------------------------------------------------------
    for (i = 1; i <= 7; i = i + 1) begin
        tmp_inst1[pc1] = {3'b010, 3'd0, i[2:0], i[6:0]};
        tmp_inst2[pc2] = {3'b010, 3'd0, i[2:0], i[6:0]};
        sim_reg_c1[i]  = i;
        sim_reg_c2[i]  = i;

        pc1 = pc1 + 1;
        pc2 = pc2 + 1;
        inst_count = inst_count + 1;
    end

    // --------------------------------------------------------
    // Main random loop
    // Each while iteration = 1 IC
    // --------------------------------------------------------
    while (pc1 < STOP_WORD && pc2 < STOP_WORD) begin
        pc1_start = pc1;
        pc2_start = pc2;

        // Clear per-IC sequence buffers
        len1 = 0;
        len2 = 0;

        // -----------------------------
        // Pick main op of this IC
        // -----------------------------
        rand_op = $urandom_range(15, 0);
        case (rand_op)
            4'd0, 4'd1: op1 = 0; // ALU
            4'd2,4'd3:           op1 = 1; // MULT
            4'd4,4'd5:           op1 = 2; // ADDI
            4'd6, 4'd7:           op1 = 3; // SUBI
            4'd8,4'd9, 4'd13:         op1 = 4; // LOAD
            4'd10, 4'd11, 4'd14:             op1 = 5; // STORE
            4'd12:         op1 = 6; // BEQ
            default:             op1 = 7; // JUMP
        endcase

        rand_op = $urandom_range(15, 0);
        case (rand_op)
            4'd0, 4'd1: op2 = 0;
            4'd2,4'd3:           op2 = 1;
            4'd4,4'd5:           op2 = 2;
            4'd6, 4'd7:           op2 = 3;
            4'd8,4'd9, 4'd13:         op2 = 4;
            4'd10, 4'd11, 4'd14:               op2 = 5;
            4'd12:         op2 = 6;
            default:             op2 = 7;
        endcase

        // [MOD] Same IC cannot be STORE/STORE
        if (op1 == 5 && op2 == 5) begin
            op2 = 4;
        end
        // ================================================================
        // Build core1 sequence for THIS IC only
        // ================================================================
        rs1  = $urandom_range(7, 0);

        rt1  = $urandom_range(7, 2);
        rd1  = $urandom_range(7, 2);
        rl1  = $urandom_range(7, 2);
        while(rd1 === rl1)begin
            rl1  = $urandom_range(7, 2);
        end
        sub1 = $urandom_range(7, 0);
        imm1 = $urandom_range(63, -64);
            
        case (op1)
            0: begin
                reg signed [16:0] add_check, sub_check;
                add_check = sim_reg_c1[rs1] + sim_reg_c1[rt1];  
                sub_check = sim_reg_c1[rs1] - sim_reg_c1[rt1];
                if (sub1 == 3'd0 && (add_check > 32767 || add_check < -32768)) begin
                    sub1 = 3'd2;   
                end
                if (sub1 == 3'd1 && (sub_check > 32767 || sub_check < -32768)) begin
                    sub1 = 3'd2;  
                end
                tmp_inst1[pc1] = {3'b000, rs1[2:0], rt1[2:0], rd1[2:0], sub1[2:0], 1'b0};
                case (sub1)
                    0: sim_reg_c1[rd1] = sim_reg_c1[rs1] + sim_reg_c1[rt1];
                    1: sim_reg_c1[rd1] = sim_reg_c1[rs1] - sim_reg_c1[rt1];
                    2: sim_reg_c1[rd1] = sim_reg_c1[rs1] & sim_reg_c1[rt1];
                    3: sim_reg_c1[rd1] = sim_reg_c1[rs1] | sim_reg_c1[rt1];
                    4: sim_reg_c1[rd1] = ~(sim_reg_c1[rs1] & sim_reg_c1[rt1]);
                    5: sim_reg_c1[rd1] = ~(sim_reg_c1[rs1] | sim_reg_c1[rt1]);
                    6: sim_reg_c1[rd1] = sim_reg_c1[rs1] ^ sim_reg_c1[rt1];
                    7: sim_reg_c1[rd1] = ($signed(sim_reg_c1[rs1]) < $signed(sim_reg_c1[rt1])) ? 16'h0001 : 16'h0000;
                endcase
                len1 = 1;
                pc1 = pc1 + 1;
            end

            1: begin
                tmp_inst1[pc1] = {3'b001, rs1[2:0], rt1[2:0], rd1[2:0], rl1[2:0], 1'b0};
                prod1 = sim_reg_c1[rs1] * sim_reg_c1[rt1];
                sim_reg_c1[rd1] = prod1[31:16];
                sim_reg_c1[rl1] = prod1[15:0];
                len1 = 1;
                pc1 = pc1 + 1;
            end

            2: begin
                reg signed [16:0] addi_check;
                rd1 = $urandom_range(7, 2);
                addi_check = sim_reg_c1[rs1] + imm1;
                if (addi_check > 32767) begin
                    imm1 = 0;
                end
                tmp_inst1[pc1] = {3'b010, rs1[2:0], rd1[2:0], imm1[6:0]};
                sim_reg_c1[rd1] = sim_reg_c1[rs1] + imm1;
                len1 = 1;
                pc1 = pc1 + 1;
            end

            3: begin
                reg signed [16:0] subi_check;
                rd1 = $urandom_range(7, 2);
                subi_check = sim_reg_c1[rs1] - imm1;
                if (subi_check > 32767 || subi_check < -32768) begin
                    imm1 = 0;
                end
                tmp_inst1[pc1] = {3'b011, rs1[2:0], rd1[2:0], imm1[6:0]};
                sim_reg_c1[rd1] = sim_reg_c1[rs1] - imm1;
                len1 = 1;
                pc1 = pc1 + 1;
            end

            4: begin
                len1 = 0;

                // [-200, +200] address
                step_rand1 = $urandom_range(400, 0) - 200;
                next_ls_eff_byte_c1 = next_ls_eff_byte_c1 + step_rand1;

                if (next_ls_eff_byte_c1 < 16'h1000) next_ls_eff_byte_c1 = 16'h1000;
                if (next_ls_eff_byte_c1 > 16'h2FFE) next_ls_eff_byte_c1 = 16'h2FFE;

                target_word_idx1 = (next_ls_eff_byte_c1 - 16'h1000) >> 1;
                delta_word1      = target_word_idx1 - sim_reg_c1[1];

                while (delta_word1 != 0) begin
                    step_word1 = (delta_word1 > 63) ? 63 : (delta_word1 < -64) ? -64 : delta_word1;
                    tmp_inst1[pc1] = {3'b010, 3'd1, 3'd1, step_word1[6:0]}; // ADDI r1,r1,step
                    sim_reg_c1[1] = sim_reg_c1[1] + step_word1;
                    len1 = len1 + 1;
                    pc1 = pc1 + 1;
                    delta_word1 = target_word_idx1 - sim_reg_c1[1];
                end

                eff_word_idx1 = sim_reg_c1[1];
                eff_byte1 = 16'h1000 + (eff_word_idx1 << 1);
                if (eff_byte1 < 16'h1000 || eff_byte1 > 16'h2FFE) begin
                    $display("GEN ERROR CORE1 LOAD byte_addr overflow rs=%0d imm=%0d eff=0x%04h",
                                eff_word_idx1, 0, eff_byte1[15:0]);
                    $finish;
                end
                rd1 = $urandom_range(7, 2);
                tmp_inst1[pc1]    = {3'b100, 3'd1, rd1[2:0], 7'd0};
                rs_val_c1[pc1] = sim_reg_c1[1];

                sim_reg_c1[rd1] = {tmp_data_live[eff_byte1+1], tmp_data_live[eff_byte1]};
                len1 = len1 + 1;
                pc1 = pc1 + 1;
            end

            // ------------------------------------------------------------
            // [MOD-3] STORE: same as LOAD, changed to the word-index model.
            // ------------------------------------------------------------
            5: begin
                len1 = 0;

                // [-200, +200] address
                step_rand1 = $urandom_range(400, 0) - 200;
                next_ls_eff_byte_c1 = next_ls_eff_byte_c1 + step_rand1;

                if (next_ls_eff_byte_c1 < 16'h1000) next_ls_eff_byte_c1 = 16'h1000;
                if (next_ls_eff_byte_c1 > 16'h2FFE) next_ls_eff_byte_c1 = 16'h2FFE;

                target_word_idx1 = (next_ls_eff_byte_c1 - 16'h1000) >> 1;
                delta_word1      = target_word_idx1 - sim_reg_c1[1];

                while (delta_word1 != 0) begin
                    step_word1 = (delta_word1 > 63) ? 63 : (delta_word1 < -64) ? -64 : delta_word1;
                    tmp_inst1[pc1] = {3'b010, 3'd1, 3'd1, step_word1[6:0]}; // ADDI r1,r1,step
                    sim_reg_c1[1] = sim_reg_c1[1] + step_word1;
                    len1 = len1 + 1;
                    pc1 = pc1 + 1;
                    delta_word1 = target_word_idx1 - sim_reg_c1[1];
                end

                eff_word_idx1 = sim_reg_c1[1];
                eff_byte1 = 16'h1000 + (eff_word_idx1 << 1);
                if (eff_byte1 < 16'h1000 || eff_byte1 > 16'h2FFE) begin
                    $display("GEN ERROR CORE1 LOAD byte_addr overflow rs=%0d imm=%0d eff=0x%04h",
                                eff_word_idx1, 0, eff_byte1[15:0]);
                    $finish;
                end
                rt1 = $urandom_range(7, 2);
                tmp_inst1[pc1]    = {3'b101, 3'd1, rt1[2:0], 7'd0};
                rs_val_c1[pc1] = sim_reg_c1[1];

                w_tmp = sim_reg_c1[rt1];
                tmp_data_live[eff_byte1]   = w_tmp[7:0];
                tmp_data_live[eff_byte1+1] = w_tmp[15:8];
                len1 = len1 + 1;
                pc1 = pc1 + 1;
            end

            6: begin
                gap1 = $urandom_range(`BRANCH_MAX, `BRANCH_MIN);
                tmp_inst1[pc1] = {3'b110, 3'd0, 3'd0, gap1[6:0]};
                pc1 = pc1 + 1 + gap1;
                len1 = 1;
            end

            default: begin
                gap1 = $urandom_range(`JUMP_MAX, `JUMP_MIN);
                jtarget_word1 = pc1 + gap1;
                jfield1 = (jtarget_word1 << 1) & 13'h1FFF;
                tmp_inst1[pc1] = {3'b111, jfield1};
                len1 = 1;
                pc1 = jtarget_word1;
                // $fdisplay(f_in, "[task_random] JUMP op generated in CORE1, pc1=%0d->%0d",
                //          pc1_start, pc1);
            end
        endcase

        // ================================================================
        // Build core2 sequence for THIS IC only
        // ================================================================
        rs2  = $urandom_range(7, 0);

        // [MOD-1] All rd/rt/rl selections always avoid r0/r1.
        rt2  = $urandom_range(7, 2);
        rd2  = $urandom_range(7, 2);
        rl2  = $urandom_range(7, 2);
        while(rd2 === rl2)begin
            rl2  = $urandom_range(7, 2);
        end

        sub2 = $urandom_range(7, 0);
        imm2 = $urandom_range(63, -64);
            
        case (op2)
            0: begin
                reg signed [16:0] add_check, sub_check;
                add_check = sim_reg_c2[rs2] + sim_reg_c1[rt2];  
                sub_check = sim_reg_c2[rs2] - sim_reg_c1[rt2];
                if (sub2 == 3'd0 && (add_check > 32767 || add_check < -32768)) begin
                    sub2 = 3'd2;   
                end
                if (sub2 == 3'd1 && (sub_check > 32767 || sub_check < -32768)) begin
                    sub2 = 3'd2;  
                end
                tmp_inst2[pc2] = {3'b000, rs2[2:0], rt2[2:0], rd2[2:0], sub2[2:0], 1'b0};
                case (sub2)
                    0: sim_reg_c2[rd2] = sim_reg_c2[rs2] + sim_reg_c2[rt2];
                    1: sim_reg_c2[rd2] = sim_reg_c2[rs2] - sim_reg_c2[rt2];
                    2: sim_reg_c2[rd2] = sim_reg_c2[rs2] & sim_reg_c2[rt2];
                    3: sim_reg_c2[rd2] = sim_reg_c2[rs2] | sim_reg_c2[rt2];
                    4: sim_reg_c2[rd2] = ~(sim_reg_c2[rs2] & sim_reg_c2[rt2]);
                    5: sim_reg_c2[rd2] = ~(sim_reg_c2[rs2] | sim_reg_c2[rt2]);
                    6: sim_reg_c2[rd2] = sim_reg_c2[rs2] ^ sim_reg_c2[rt2];
                    7: sim_reg_c2[rd2] = ($signed(sim_reg_c2[rs2]) < $signed(sim_reg_c2[rt2])) ? 16'h0001 : 16'h0000;
                endcase
                len2 = 1;
                pc2 = pc2 + 1;
            end

            1: begin
                tmp_inst2[pc2] = {3'b001, rs2[2:0], rt2[2:0], rd2[2:0], rl2[2:0], 1'b0};
                prod2 = sim_reg_c2[rs2] * sim_reg_c2[rt2];
                sim_reg_c2[rd2] = prod2[31:16];
                sim_reg_c2[rl2] = prod2[15:0];
                len2 = 1;
                pc2 = pc2 + 1;
            end

            2: begin
                reg signed [16:0] addi_check;
                rd2 = $urandom_range(7, 2);
                addi_check = sim_reg_c2[rs2] + imm2;
                if (addi_check > 32767 || addi_check < -32768) begin
                    imm2 = 0;
                end
                tmp_inst2[pc2]  = {3'b010, rs2[2:0], rd2[2:0], imm2[6:0]};
                sim_reg_c2[rd2] = sim_reg_c2[rs2] + imm2;
                len2 = 1;
                pc2 = pc2 + 1;
            end

            3: begin
                reg signed [16:0] subi_check;
                rd2 = $urandom_range(7, 2);
                subi_check = sim_reg_c2[rs2] - imm2;
                if (subi_check > 32767 || subi_check < -32768) begin
                    imm2 = 0;
                end
                tmp_inst2[pc2]  = {3'b011, rs2[2:0], rd2[2:0], imm2[6:0]};
                sim_reg_c2[rd2] = sim_reg_c2[rs2] - imm2;
                len2 = 1;
                pc2 = pc2 + 1;
            end

            4: begin
                len2 = 0;

                // [-200, +200] address
                step_rand2 = $urandom_range(400, 0) - 200;
                next_ls_eff_byte_c1 = next_ls_eff_byte_c1 + step_rand2;

                if (next_ls_eff_byte_c1 < 16'h1000) next_ls_eff_byte_c1 = 16'h1000;
                if (next_ls_eff_byte_c1 > 16'h2FFE) next_ls_eff_byte_c1 = 16'h2FFE;

                target_word_idx2 = (next_ls_eff_byte_c1 - 16'h1000) >> 1;
                delta_word2      = target_word_idx2 - sim_reg_c2[1];
                while (delta_word2 != 0) begin
                    step_word2 = (delta_word2 > 63) ? 63 : (delta_word2 < -64) ? -64 : delta_word2;
                    tmp_inst2[pc2] = {3'b010, 3'd1, 3'd1, step_word2[6:0]}; // ADDI r1,r1,step
                    sim_reg_c2[1] = sim_reg_c2[1] + step_word2;
                    len2 = len2 + 1;
                    pc2 = pc2 + 1;
                    delta_word2 = target_word_idx2 - sim_reg_c2[1];
                end

                eff_word_idx2 = sim_reg_c2[1];
                eff_byte2 = 16'h1000 + (eff_word_idx2 << 1);
                if (eff_byte2 < 16'h1000 || eff_byte2 > 16'h2FFE) begin
                    $display("GEN ERROR CORE2 LOAD byte_addr overflow rs=%0d imm=%0d eff=0x%04h",
                                eff_word_idx2, 0, eff_byte2[15:0]);
                    $finish;
                end
                rd2 = $urandom_range(7, 2);
                tmp_inst2[pc2]    = {3'b100, 3'd1, rd2[2:0], 7'd0};
                rs_val_c2[pc2] = sim_reg_c2[1];

                sim_reg_c2[rd2] = {tmp_data_live[eff_byte2+1], tmp_data_live[eff_byte2]};
                len2 = len2 + 1;
                pc2 = pc2 + 1;
            end

            5: begin
                len2 = 0;

                // [-200, +200] address
                step_rand2 = $urandom_range(400, 0) - 200;
                next_ls_eff_byte_c1 = next_ls_eff_byte_c1 + step_rand2;

                if (next_ls_eff_byte_c1 < 16'h1000) next_ls_eff_byte_c1 = 16'h1000;
                if (next_ls_eff_byte_c1 > 16'h2FFE) next_ls_eff_byte_c1 = 16'h2FFE;

                target_word_idx2 = (next_ls_eff_byte_c1 - 16'h1000) >> 1;
                delta_word2      = target_word_idx2 - sim_reg_c2[1];
                while (delta_word2 != 0) begin
                    step_word2 = (delta_word2 > 63) ? 63 : (delta_word2 < -64) ? -64 : delta_word2;
                    tmp_inst2[pc2] = {3'b010, 3'd1, 3'd1, step_word2[6:0]}; // ADDI r1,r1,step
                    sim_reg_c2[1] = sim_reg_c2[1] + step_word2;
                    len2 = len2 + 1;
                    pc2 = pc2 + 1;
                    delta_word2 = target_word_idx2 - sim_reg_c2[1];
                end

                eff_word_idx2 = sim_reg_c2[1];
                eff_byte2 = 16'h1000 + (eff_word_idx2 << 1);
                if (eff_byte2 < 16'h1000 || eff_byte2 > 16'h2FFE) begin
                    $display("GEN ERROR CORE2 LOAD byte_addr overflow rs=%0d imm=%0d eff=0x%04h",
                                eff_word_idx2, 0, eff_byte2[15:0]);
                    $finish;
                end
                rt2 = $urandom_range(7, 2);
                tmp_inst2[pc2]    = {3'b101, 3'd1, rt2[2:0], 7'd0};
                rs_val_c2[pc2] = sim_reg_c2[1];

                w_tmp = sim_reg_c2[rt2];
                tmp_data_live[eff_byte2]   = w_tmp[7:0];
                tmp_data_live[eff_byte2+1] = w_tmp[15:8];
                len2 = len2 + 1;
                pc2 = pc2 + 1;
            end

            6: begin
                gap2 = $urandom_range(`BRANCH_MAX, `BRANCH_MIN);
                tmp_inst2[pc2] = {3'b110, 3'd0, 3'd0, gap2[6:0]};
                pc2 = pc2 + 1 + gap2;
                len2 = 1;
            end

            default: begin
                gap2 = $urandom_range(`JUMP_MAX, `JUMP_MIN);
                jtarget_word2 = pc2 + gap2;
                jfield2 = (jtarget_word2 << 1) & 13'h1FFF;
                tmp_inst2[pc2] = {3'b111, jfield2};
                len2 = 1;
                pc2 = jtarget_word2;
                // $fdisplay(f_in, "[task_random] JUMP op generated in CORE2, pc2=%0d->%0d",
                //          pc2_start, pc2);
            end
        endcase

        // ================================================================
        // Align THIS IC
        // ================================================================
        max_len = (len1 > len2) ? len1 : len2;

        // ================================================================
        // Emit THIS IC together
        // Only now update pc1 / pc2
        // ================================================================
        if(max_len == len1)begin
            for (k = 0; k < max_len - len2; k = k + 1) begin
                pc2 = pc2 + 1;
            end
        end
        else begin
            for (k = 0; k < max_len - len1; k = k + 1) begin
                pc1 = pc1 + 1;
            end
        end
        inst_count = inst_count + max_len;
        // $fdisplay(f_in, "[task_random] IC%0d: pc1=%0d->%0d pc2=%0d->%0d len1=%0d len2=%0d",
        //          inst_count, pc1_start, pc1, pc2_start, pc2, len1, len2);
    end

    if (inst_count % 50 != 0) inst_count = inst_count + (50 - inst_count % 50);

    $display("%0s[task_random] %0d ICs generated%0s",
             txt_cyan_prefix, inst_count, reset_color);

    // --------------------------------------------------------
    // Write inst_1_dram_file.dat
    // --------------------------------------------------------
    fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
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
        br_tgt_byte   = i + 16'd1 + ($signed(cimm));
        br_tgt_byte = br_tgt_byte << 1;

        if (tmp_inst1[i] == NOP) begin
            $fwrite(fd_i1, "%02h %02h // %0d:NOP\n",
                    tmp_inst1[i][15:8], tmp_inst1[i][7:0], i);
        end
        else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i1,"%02h %02h // %0d:ADD  r%0d=r%0d+r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b001: $fwrite(fd_i1,"%02h %02h // %0d:SUB  r%0d=r%0d-r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b010: $fwrite(fd_i1,"%02h %02h // %0d:AND  r%0d=r%0d&r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b011: $fwrite(fd_i1,"%02h %02h // %0d:OR   r%0d=r%0d|r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b100: $fwrite(fd_i1,"%02h %02h // %0d:NAND r%0d=~(r%0d&r%0d)\n", tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b101: $fwrite(fd_i1,"%02h %02h // %0d:NOR  r%0d=~(r%0d|r%0d)\n", tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b110: $fwrite(fd_i1,"%02h %02h // %0d:XOR  r%0d=r%0d^r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b111: $fwrite(fd_i1,"%02h %02h // %0d:SLT  r%0d=(r%0d<r%0d)\n",  tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                    endcase
                end
                3'b001: $fwrite(fd_i1,"%02h %02h // %0d:MULT {r%0d,r%0d}=r%0d*r%0d\n",  tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crl,crs,crt);
                3'b010: $fwrite(fd_i1,"%02h %02h // %0d:ADDI r%0d=r%0d+%0d\n",           tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,crs,$signed(cimm));
                3'b011: $fwrite(fd_i1,"%02h %02h // %0d:SUBI r%0d=r%0d-%0d\n",           tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,crs,$signed(cimm));
                3'b100: $fwrite(fd_i1,"%02h %02h // %0d:LOAD  r%0d<-DM[0x%04h] rs=r%0d(=%0d) imm=%0d\n",
                                tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,eff_byte_addr[15:0],crs,rs_val_c1[i],$signed(cimm));
                3'b101: $fwrite(fd_i1,"%02h %02h // %0d:STORE DM[0x%04h]<-r%0d rs=r%0d(=%0d) imm=%0d\n",
                                tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,eff_byte_addr[15:0],crt,crs,rs_val_c1[i],$signed(cimm));
                3'b110: $fwrite(fd_i1,"%02h %02h // %0d:BEQ  if(r%0d==r%0d) -> 0x%04h\n",
                                tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crs,crt,br_tgt_byte[15:0]);
                3'b111: $fwrite(fd_i1,"%02h %02h // %0d:JUMP -> 0x%04h\n",
                                tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,{3'b0,cjaddr});
                default:$fwrite(fd_i1,"%02h %02h // %0d:NOP\n", 8'h00, 8'h00, i);
            endcase
        end
    end
    $fclose(fd_i1);

    // --------------------------------------------------------
    // Write inst_2_dram_file.dat
    // --------------------------------------------------------
    fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
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
        br_tgt_byte   = i + 16'd1 + ($signed(cimm));
        br_tgt_byte = br_tgt_byte << 1;

        if (tmp_inst2[i] == NOP) begin
            $fwrite(fd_i2, "%02h %02h // %0d:NOP\n",
                    tmp_inst2[i][15:8], tmp_inst2[i][7:0], i);
        end
        else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i2,"%02h %02h // %0d:ADD  r%0d=r%0d+r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b001: $fwrite(fd_i2,"%02h %02h // %0d:SUB  r%0d=r%0d-r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b010: $fwrite(fd_i2,"%02h %02h // %0d:AND  r%0d=r%0d&r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b011: $fwrite(fd_i2,"%02h %02h // %0d:OR   r%0d=r%0d|r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b100: $fwrite(fd_i2,"%02h %02h // %0d:NAND r%0d=~(r%0d&r%0d)\n", tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b101: $fwrite(fd_i2,"%02h %02h // %0d:NOR  r%0d=~(r%0d|r%0d)\n", tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b110: $fwrite(fd_i2,"%02h %02h // %0d:XOR  r%0d=r%0d^r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b111: $fwrite(fd_i2,"%02h %02h // %0d:SLT  r%0d=(r%0d<r%0d)\n",  tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                    endcase
                end
                3'b001: $fwrite(fd_i2,"%02h %02h // %0d:MULT {r%0d,r%0d}=r%0d*r%0d\n",  tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crl,crs,crt);
                3'b010: $fwrite(fd_i2,"%02h %02h // %0d:ADDI r%0d=r%0d+%0d\n",           tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,crs,$signed(cimm));
                3'b011: $fwrite(fd_i2,"%02h %02h // %0d:SUBI r%0d=r%0d-%0d\n",           tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,crs,$signed(cimm));
                3'b100: $fwrite(fd_i2,"%02h %02h // %0d:LOAD  r%0d<-DM[0x%04h] rs=r%0d(=%0d) imm=%0d\n",
                                tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,eff_byte_addr[15:0],crs,rs_val_c2[i],$signed(cimm));
                3'b101: $fwrite(fd_i2,"%02h %02h // %0d:STORE DM[0x%04h]<-r%0d rs=r%0d(=%0d) imm=%0d\n",
                                tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,eff_byte_addr[15:0],crt,crs,rs_val_c2[i],$signed(cimm));
                3'b110: $fwrite(fd_i2,"%02h %02h // %0d:BEQ  if(r%0d==r%0d) -> 0x%04h\n",
                                tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crs,crt,br_tgt_byte[15:0]);
                3'b111: $fwrite(fd_i2,"%02h %02h // %0d:JUMP -> 0x%04h\n",
                                tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,{3'b0,cjaddr});
                default:$fwrite(fd_i2,"%02h %02h // %0d:NOP\n", 8'h00, 8'h00, i);
            endcase
        end
    end
    $fclose(fd_i2);

    // --------------------------------------------------------
    // Write data_dram_file.dat
    // --------------------------------------------------------
    fd_d = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
    for (i = DATA_ACC_LO; i <= DATA_ACC_HI; i = i + 2) begin
        $fwrite(fd_d, "@%04h\n", i);
        $fwrite(fd_d, "%02h %02h // DATA[%04h]=%0d\n",
                tmp_data_init[i], tmp_data_init[i+1], i,
                $signed({tmp_data_init[i+1], tmp_data_init[i]}));
    end
    $fclose(fd_d);

    $display("%0s[task_random] .dat files written%0s", txt_cyan_prefix, reset_color);
end endtask


task decode_and_print_instr;
    input integer core_id;
    input integer pc_word;
    input [15:0] instr;
    reg [2:0] op, rs, rt, rd, rl, sub;
    reg signed [6:0] imm;
    reg [12:0] jaddr;
    begin
        op    = instr[15:13];
        rs    = instr[12:10];
        rt    = instr[9:7];
        rd    = instr[6:4];
        rl    = instr[3:1];
        sub   = instr[3:1];
        imm   = instr[6:0];
        jaddr = instr[12:0];

        $write("[CORE%0d] PC=0x%04h INSTR=0x%04h -> ", core_id,pc_word, instr);

        if (instr == 16'h0000) begin
            $display("NOP");
        end
        else begin
            case (op)
                3'b000: begin
                    case (sub)
                        3'b000: $display("ADD   r%0d = r%0d + r%0d", rd, rs, rt);
                        3'b001: $display("SUB   r%0d = r%0d - r%0d", rd, rs, rt);
                        3'b010: $display("AND   r%0d = r%0d & r%0d", rd, rs, rt);
                        3'b011: $display("OR    r%0d = r%0d | r%0d", rd, rs, rt);
                        3'b100: $display("NAND  r%0d = ~(r%0d & r%0d)", rd, rs, rt);
                        3'b101: $display("NOR   r%0d = ~(r%0d | r%0d)", rd, rs, rt);
                        3'b110: $display("XOR   r%0d = r%0d ^ r%0d", rd, rs, rt);
                        3'b111: $display("SLT   r%0d = (r%0d < r%0d)", rd, rs, rt);
                        default:$display("UNKNOWN ALU");
                    endcase
                end
                3'b001: begin
                    $display("MULT  {r%0d,r%0d} = r%0d * r%0d", rd, rl, rs, rt);
                end
                3'b010: begin
                    $display("ADDI  r%0d = r%0d + %0d", rt, rs, $signed(imm));
                end
                3'b011: begin
                    $display("SUBI  r%0d = r%0d - %0d", rt, rs, $signed(imm));
                end
                3'b100: begin
                    $display("LOAD  r%0d <- MEM[r%0d + %0d]", rt, rs, $signed(imm));
                end
                3'b101: begin
                    $display("STORE MEM[r%0d + %0d] <- r%0d", rs, $signed(imm), rt);
                end
                3'b110: begin
                    $display("BEQ   if (r%0d == r%0d) branch %0d bytes to 0x%04h",
                             rs, rt, $signed(imm), ((pc_word) + 16'd2 + ($signed(imm) * 2)));
                end
                3'b111: begin
                    $display("JUMP  -> 0x%04h", {3'b000, jaddr});
                end
                default: begin
                    $display("UNKNOWN");
                end
            endcase
        end
    end
endtask
task gen_dram_files_task_direct; begin
    integer fd_i1, fd_i2, fd_d;
    integer i;
    integer pc;
    integer exec_ic;

    reg [15:0] tmp_inst1 [0:INST_DEPTH-1];
    reg [15:0] tmp_inst2 [0:INST_DEPTH-1];
    reg [7:0]  tmp_data_init [0:DATA_TOP];

    reg [15:0] NOP;

    integer imm;
    integer loop_top_pc;
    integer loop_end_pc;
    integer beq_pc;

    integer branch_loop_top_pc;
    integer branch_loop_end_pc;

    integer target_word;
    integer target_byte;
    integer final_word;
    integer jump_step_word;

    integer arr_base;
    integer word_addr;
    integer value;

    // instruction decode variables for output comments
    reg [2:0]  cop;
    reg [2:0]  crs;
    reg [2:0]  crt;
    reg [2:0]  crd;
    reg [2:0]  crl;
    reg [2:0]  csub;
    reg signed [6:0] cimm;
    reg [12:0] cjaddr;
    reg [31:0] br_tgt_byte;

    NOP = 16'h0000;
    pc  = 0;
    exec_ic = 0;

    final_word     = 4095; // byte address = 0x1FFE
    jump_step_word = 128;   

    // --------------------------------------------------------
    // Initialize instruction/data memory image
    // --------------------------------------------------------
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        tmp_inst1[i] = NOP;
        tmp_inst2[i] = NOP;
    end

    for (i = 0; i <= DATA_TOP; i = i + 1) begin
        tmp_data_init[i] = 8'h00;
    end

    // --------------------------------------------------------
    // Directed data initialization
    //
    // Part A: MULT operands at 0x1000 ~ 0x1017
    // The data memory is byte-addressable:
    //   low byte  = mem[addr]
    //   high byte = mem[addr+1]
    //
    // Part B: loop array at 0x1100
    //   core0: arr[50+i]  = arr[i]     + arr[25+i]
    //   core1: arr[150+i] = arr[100+i] + arr[125+i]
    // --------------------------------------------------------

    // ---------------- MULT operands ----------------
    // Case 0: 0x8000 * 0x8000 = 0x40000000
    tmp_data_init[16'h1000] = 8'h00;
    tmp_data_init[16'h1001] = 8'h80;
    tmp_data_init[16'h1002] = 8'h00;
    tmp_data_init[16'h1003] = 8'h80;

    // Case 1: 0x8000 * 0x7FFF = 0xC0008000
    tmp_data_init[16'h1004] = 8'h00;
    tmp_data_init[16'h1005] = 8'h80;
    tmp_data_init[16'h1006] = 8'hFF;
    tmp_data_init[16'h1007] = 8'h7F;

    // Case 2: 0xFFFF * 0xFFFF = 0x00000001
    tmp_data_init[16'h1008] = 8'hFF;
    tmp_data_init[16'h1009] = 8'hFF;
    tmp_data_init[16'h100A] = 8'hFF;
    tmp_data_init[16'h100B] = 8'hFF;

    // Case 3: 0xFFFF * 0x0001 = 0xFFFFFFFF
    tmp_data_init[16'h100C] = 8'hFF;
    tmp_data_init[16'h100D] = 8'hFF;
    tmp_data_init[16'h100E] = 8'h01;
    tmp_data_init[16'h100F] = 8'h00;

    // Case 4: 0x0000 * 0xFFFF = 0x00000000
    tmp_data_init[16'h1010] = 8'h00;
    tmp_data_init[16'h1011] = 8'h00;
    tmp_data_init[16'h1012] = 8'hFF;
    tmp_data_init[16'h1013] = 8'hFF;

    // Case 5: 0x7FFF * 0x7FFF = 0x3FFF0001
    tmp_data_init[16'h1014] = 8'hFF;
    tmp_data_init[16'h1015] = 8'h7F;
    tmp_data_init[16'h1016] = 8'hFF;
    tmp_data_init[16'h1017] = 8'h7F;

    // ---------------- loop array data ----------------
    arr_base = 16'h1100;

    for (i = 0; i < 25; i = i + 1) begin
        // arr[0..24] = 1..25
        word_addr = arr_base + ((i + 0) << 1);
        value = $urandom_range(1023, -1024);
        tmp_data_init[word_addr]     = value[7:0];
        tmp_data_init[word_addr + 1] = value[15:8];

        // arr[25..49] = 2..26
        word_addr = arr_base + ((i + 25) << 1);
        value = $urandom_range(1023, -1024);
        tmp_data_init[word_addr]     = value[7:0];
        tmp_data_init[word_addr + 1] = value[15:8];

        // arr[100..124] = 3..27
        word_addr = arr_base + ((i + 100) << 1);
        value = $urandom_range(1023, -1024);
        tmp_data_init[word_addr]     = value[7:0];
        tmp_data_init[word_addr + 1] = value[15:8];

        // arr[125..149] = 4..28
        word_addr = arr_base + ((i + 125) << 1);
        value = $urandom_range(1023, -1024);
        tmp_data_init[word_addr]     = value[7:0];
        tmp_data_init[word_addr + 1] = value[15:8];
    end

    // ========================================================
    // Phase 1: SLT with negative numbers
    // ========================================================

    tmp_inst1[pc] = {3'b011, 3'd0, 3'd4, 7'd5};  // core0: SUBI r4 = r0 - 5, r4 = -5
    tmp_inst2[pc] = {3'b011, 3'd0, 3'd4, 7'd5};  // core1: SUBI r4 = r0 - 5, r4 = -5
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd5, 7'd3};  // core0: ADDI r5 = r0 + 3
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd5, 7'd3};  // core1: ADDI r5 = r0 + 3
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: SLT r6 = (-5 < 3), expect 1
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: SLT r6 = (-5 < 3), expect 1
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd5, 3'd4, 3'd7, 3'd7, 1'b0}; // core0: SLT r7 = (3 < -5), expect 0
    tmp_inst2[pc] = {3'b000, 3'd5, 3'd4, 3'd7, 3'd7, 1'b0}; // core1: SLT r7 = (3 < -5), expect 0
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b011, 3'd0, 3'd4, 7'd1};  // core0: SUBI r4 = r0 - 1, r4 = -1
    tmp_inst2[pc] = {3'b011, 3'd0, 3'd4, 7'd1};  // core1: SUBI r4 = r0 - 1, r4 = -1
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b011, 3'd0, 3'd5, 7'd2};  // core0: SUBI r5 = r0 - 2, r5 = -2
    tmp_inst2[pc] = {3'b011, 3'd0, 3'd5, 7'd2};  // core1: SUBI r5 = r0 - 2, r5 = -2
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: SLT r6 = (-1 < -2), expect 0
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: SLT r6 = (-1 < -2), expect 0
    pc = pc + 1; exec_ic = exec_ic + 1;

    // ========================================================
    // Phase 2: MULT robust test
    //
    // r1 = 0, so LOAD address = 0x1000 + imm * 2.
    // Use LOAD to get large operands such as 0x8000 and 0x7FFF.
    //
    // MULT result format:
    //   {rd, rl} = rs * rt
    //
    // Here:
    //   r4 = operand A
    //   r5 = operand B
    //   r6 = product[31:16]
    //   r7 = product[15:0]
    // ========================================================

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd1, 7'd0};  // core0: ADDI r1 = r0 + 0, set LS base to 0
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd1, 7'd0};  // core1: ADDI r1 = r0 + 0, set LS base to 0
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Case 0: 0x8000 * 0x8000 = 0x40000000
    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd0};  // core0: LOAD r4 <- DM[0x1000] = 0x8000
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd0};  // core1: LOAD r4 <- DM[0x1000] = 0x8000
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd1};  // core0: LOAD r5 <- DM[0x1002] = 0x8000
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd1};  // core1: LOAD r5 <- DM[0x1002] = 0x8000
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: MULT, expect {r6,r7}=0x40000000
    tmp_inst2[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: MULT, expect {r6,r7}=0x40000000
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Case 1: 0x8000 * 0x7FFF = 0xC0008000
    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd2};  // core0: LOAD r4 <- DM[0x1004] = 0x8000
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd2};  // core1: LOAD r4 <- DM[0x1004] = 0x8000
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd3};  // core0: LOAD r5 <- DM[0x1006] = 0x7FFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd3};  // core1: LOAD r5 <- DM[0x1006] = 0x7FFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: MULT, expect {r6,r7}=0xC0008000
    tmp_inst2[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: MULT, expect {r6,r7}=0xC0008000
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Case 2: 0xFFFF * 0xFFFF = 0x00000001
    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd4};  // core0: LOAD r4 <- DM[0x1008] = 0xFFFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd4};  // core1: LOAD r4 <- DM[0x1008] = 0xFFFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd5};  // core0: LOAD r5 <- DM[0x100A] = 0xFFFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd5};  // core1: LOAD r5 <- DM[0x100A] = 0xFFFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: MULT, expect {r6,r7}=0x00000001
    tmp_inst2[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: MULT, expect {r6,r7}=0x00000001
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Case 3: 0xFFFF * 0x0001 = 0xFFFFFFFF
    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd6};  // core0: LOAD r4 <- DM[0x100C] = 0xFFFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd6};  // core1: LOAD r4 <- DM[0x100C] = 0xFFFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd7};  // core0: LOAD r5 <- DM[0x100E] = 0x0001
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd7};  // core1: LOAD r5 <- DM[0x100E] = 0x0001
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: MULT, expect {r6,r7}=0xFFFFFFFF
    tmp_inst2[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: MULT, expect {r6,r7}=0xFFFFFFFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Case 4: 0x0000 * 0xFFFF = 0x00000000
    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd8};  // core0: LOAD r4 <- DM[0x1010] = 0x0000
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd8};  // core1: LOAD r4 <- DM[0x1010] = 0x0000
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd9};  // core0: LOAD r5 <- DM[0x1012] = 0xFFFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd9};  // core1: LOAD r5 <- DM[0x1012] = 0xFFFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: MULT, expect {r6,r7}=0x00000000
    tmp_inst2[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: MULT, expect {r6,r7}=0x00000000
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Case 5: 0x7FFF * 0x7FFF = 0x3FFF0001
    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd10}; // core0: LOAD r4 <- DM[0x1014] = 0x7FFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd10}; // core1: LOAD r4 <- DM[0x1014] = 0x7FFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd11}; // core0: LOAD r5 <- DM[0x1016] = 0x7FFF
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd11}; // core1: LOAD r5 <- DM[0x1016] = 0x7FFF
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core0: MULT, expect {r6,r7}=0x3FFF0001
    tmp_inst2[pc] = {3'b001, 3'd4, 3'd5, 3'd6, 3'd7, 1'b0}; // core1: MULT, expect {r6,r7}=0x3FFF0001
    pc = pc + 1; exec_ic = exec_ic + 1;

    // ========================================================
    // Phase 3: R-type / ADDI / SUBI corner cases
    // No overflow cases.
    // ========================================================

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd4, 7'd15}; // core0: ADDI r4 = 15
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd4, 7'd15}; // core1: ADDI r4 = 15
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd5, 7'd10}; // core0: ADDI r5 = 10
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd5, 7'd10}; // core1: ADDI r5 = 10
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd0, 1'b0}; // core0: ADD r6 = r4 + r5
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd0, 1'b0}; // core1: ADD r6 = r4 + r5
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd1, 1'b0}; // core0: SUB r6 = r4 - r5
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd1, 1'b0}; // core1: SUB r6 = r4 - r5
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd2, 1'b0}; // core0: AND r6 = r4 & r5
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd2, 1'b0}; // core1: AND r6 = r4 & r5
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd3, 1'b0}; // core0: OR r6 = r4 | r5
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd3, 1'b0}; // core1: OR r6 = r4 | r5
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd4, 1'b0}; // core0: NAND r6 = ~(r4 & r5)
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd4, 1'b0}; // core1: NAND r6 = ~(r4 & r5)
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd5, 1'b0}; // core0: NOR r6 = ~(r4 | r5)
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd5, 1'b0}; // core1: NOR r6 = ~(r4 | r5)
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd6, 1'b0}; // core0: XOR r6 = r4 ^ r5
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd6, 1'b0}; // core1: XOR r6 = r4 ^ r5
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd4, 3'd6, 7'd63}; // core0: ADDI r6 = r4 + 63
    tmp_inst2[pc] = {3'b010, 3'd4, 3'd6, 7'd63}; // core1: ADDI r6 = r4 + 63
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b011, 3'd4, 3'd6, 7'd63}; // core0: SUBI r6 = r4 - 63
    tmp_inst2[pc] = {3'b011, 3'd4, 3'd6, 7'd63}; // core1: SUBI r6 = r4 - 63
    pc = pc + 1; exec_ic = exec_ic + 1;

    imm = -64;
    tmp_inst1[pc] = {3'b010, 3'd0, 3'd6, imm[6:0]}; // core0: ADDI r6 = r0 - 64
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd6, imm[6:0]}; // core1: ADDI r6 = r0 - 64
    pc = pc + 1; exec_ic = exec_ic + 1;

    imm = -64;
    tmp_inst1[pc] = {3'b011, 3'd0, 3'd6, imm[6:0]}; // core0: SUBI r6 = r0 - (-64)
    tmp_inst2[pc] = {3'b011, 3'd0, 3'd6, imm[6:0]}; // core1: SUBI r6 = r0 - (-64)
    pc = pc + 1; exec_ic = exec_ic + 1;

    // ========================================================
    // Phase 4: LOAD/STORE combination test
    //
    // First use r1 = 0:
    //   address = 0x1000 + imm * 2
    //
    // Then use r1 = 64:
    //   address = 0x1000 + (64 + imm) * 2
    //
    // This covers:
    //   LOAD / NOP
    //   NOP / LOAD
    //   STORE / NOP
    //   NOP / STORE
    //   LOAD / LOAD
    //   LOAD / STORE different address
    //   STORE / LOAD different address
    //   LOAD / STORE same address
    //   STORE / LOAD same address
    // ========================================================

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd1, 7'd0};  // core0: r1 = 0
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd1, 7'd0};  // core1: r1 = 0
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd6, 7'd33}; // core0: r6 = 33, store data
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd6, 7'd44}; // core1: r6 = 44, store data
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd0};  // core0: LOAD  r4 <- DM[0x1000]
    tmp_inst2[pc] = NOP;                          // core1: NOP
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = NOP;                          // core0: NOP
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd8};  // core1: LOAD  r4 <- DM[0x1010]
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b101, 3'd1, 3'd6, 7'd16}; // core0: STORE DM[0x1020] <- r6
    tmp_inst2[pc] = NOP;                          // core1: NOP
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = NOP;                          // core0: NOP
    tmp_inst2[pc] = {3'b101, 3'd1, 3'd6, 7'd24}; // core1: STORE DM[0x1030] <- r6
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd32}; // core0: LOAD  r4 <- DM[0x1040]
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd40}; // core1: LOAD  r4 <- DM[0x1050]
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd48}; // core0: LOAD  r4 <- DM[0x1060]
    tmp_inst2[pc] = {3'b101, 3'd1, 3'd6, 7'd56}; // core1: STORE DM[0x1070] <- r6
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd1, 7'd63}; // core0: r1 = 63
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd1, 7'd63}; // core1: r1 = 63
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd1, 3'd1, 7'd1};  // core0: r1 = 64
    tmp_inst2[pc] = {3'b010, 3'd1, 3'd1, 7'd1};  // core1: r1 = 64
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b101, 3'd1, 3'd6, 7'd0};  // core0: STORE DM[0x1080] <- r6
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd8};  // core1: LOAD  r4 <- DM[0x1090]
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd16}; // core0: LOAD  r4 <- DM[0x10A0]
    tmp_inst2[pc] = {3'b101, 3'd1, 3'd6, 7'd16}; // core1: STORE DM[0x10A0] <- r6, same addr, STORE first
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b101, 3'd1, 3'd6, 7'd24}; // core0: STORE DM[0x10B0] <- r6, same addr, STORE first
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd24}; // core1: LOAD  r4 <- DM[0x10B0]
    pc = pc + 1; exec_ic = exec_ic + 1;

    // ========================================================
    // Phase 5: small backward branch loop
    //
    // This phase is used to test backward BEQ.
    // r2 counts from 0 to 3.
    //
    // pseudo code:
    //   r2 = 0
    //   r3 = 3
    // loop_top:
    //   r2 = r2 + 1
    //   if (r2 == r3) goto loop_end
    //   if (r0 == r0) goto loop_top
    // loop_end:
    // ========================================================

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd2, 7'd0};  // core0: r2 = 0
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd2, 7'd0};  // core1: r2 = 0
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd3, 7'd3};  // core0: r3 = 3
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd3, 7'd3};  // core1: r3 = 3
    pc = pc + 1; exec_ic = exec_ic + 1;

    branch_loop_top_pc = pc;

    tmp_inst1[pc] = {3'b010, 3'd2, 3'd2, 7'd1};  // core0: r2 = r2 + 1
    tmp_inst2[pc] = {3'b010, 3'd2, 3'd2, 7'd1};  // core1: r2 = r2 + 1
    pc = pc + 1;

    beq_pc = pc;
    pc = pc + 1; // fill forward BEQ after branch_loop_end_pc is known

    imm = branch_loop_top_pc - (pc + 1);
    tmp_inst1[pc] = {3'b110, 3'd0, 3'd0, imm[6:0]}; // core0: backward BEQ r0,r0,branch_loop_top
    tmp_inst2[pc] = {3'b110, 3'd0, 3'd0, imm[6:0]}; // core1: backward BEQ r0,r0,branch_loop_top
    pc = pc + 1;

    branch_loop_end_pc = pc;

    imm = branch_loop_end_pc - (beq_pc + 1);
    tmp_inst1[beq_pc] = {3'b110, 3'd2, 3'd3, imm[6:0]}; // core0: BEQ r2,r3,branch_loop_end
    tmp_inst2[beq_pc] = {3'b110, 3'd2, 3'd3, imm[6:0]}; // core1: BEQ r2,r3,branch_loop_end

    // Dynamic execution count:
    //   ADDI r2 executes 3 times
    //   BEQ r2,r3 executes 3 times
    //   backward BEQ executes 2 times
    exec_ic = exec_ic + 8;

    // ========================================================
    // Phase 6: main loop
    //
    // core0:
    //   arr[50+i] = arr[i] + arr[25+i]
    //
    // core1:
    //   arr[150+i] = arr[100+i] + arr[125+i]
    //
    // Register usage:
    //   r1 = base pointer
    //   r2 = loop counter i
    //   r3 = loop bound 25
    //   r4 = first load value
    //   r5 = second load value
    //   r6 = sum
    //
    // Address mapping:
    //   effective address = 0x1000 + (r1 + imm) * 2
    //
    // core0:
    //   r1 = 128 -> 0x1100 = arr[0]
    //   LOAD  imm 0  -> arr[i]
    //   LOAD  imm 25 -> arr[25+i]
    //   STORE imm 50 -> arr[50+i]
    //
    // core1:
    //   r1 = 228 -> 0x11C8 = arr[100]
    //   LOAD  imm 0  -> arr[100+i]
    //   LOAD  imm 25 -> arr[125+i]
    //   STORE imm 50 -> arr[150+i]
    //
    // Important:
    //   Two cores cannot both STORE in the same IC.
    //   Therefore, STORE is split into two ICs:
    //     IC A: core0 NOP,   core1 STORE
    //     IC B: core0 STORE, core1 NOP
    // ========================================================

    // Setup r1 base pointer.
    tmp_inst1[pc] = {3'b010, 3'd0, 3'd1, 7'd63}; // core0: r1 = 63
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd1, 7'd63}; // core1: r1 = 63
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd1, 3'd1, 7'd63}; // core0: r1 = 126
    tmp_inst2[pc] = {3'b010, 3'd1, 3'd1, 7'd63}; // core1: r1 = 126
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd1, 3'd1, 7'd2};  // core0: r1 = 128
    tmp_inst2[pc] = {3'b010, 3'd1, 3'd1, 7'd63}; // core1: r1 = 189
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = NOP;                          // core0: NOP, keep r1 = 128
    tmp_inst2[pc] = {3'b010, 3'd1, 3'd1, 7'd39}; // core1: r1 = 228
    pc = pc + 1; exec_ic = exec_ic + 1;

    // Setup loop counter.
    tmp_inst1[pc] = {3'b010, 3'd0, 3'd2, 7'd0};  // core0: r2 = 0
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd2, 7'd0};  // core1: r2 = 0
    pc = pc + 1; exec_ic = exec_ic + 1;

    tmp_inst1[pc] = {3'b010, 3'd0, 3'd3, 7'd25}; // core0: r3 = 25
    tmp_inst2[pc] = {3'b010, 3'd0, 3'd3, 7'd25}; // core1: r3 = 25
    pc = pc + 1; exec_ic = exec_ic + 1;

    loop_top_pc = pc;

    beq_pc = pc;
    pc = pc + 1; // fill BEQ after loop_end_pc is known

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd4, 7'd0};  // core0: LOAD r4 <- arr[i]
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd4, 7'd0};  // core1: LOAD r4 <- arr[100+i]
    pc = pc + 1;

    tmp_inst1[pc] = {3'b100, 3'd1, 3'd5, 7'd25}; // core0: LOAD r5 <- arr[25+i]
    tmp_inst2[pc] = {3'b100, 3'd1, 3'd5, 7'd25}; // core1: LOAD r5 <- arr[125+i]
    pc = pc + 1;

    tmp_inst1[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd0, 1'b0}; // core0: ADD r6 = r4 + r5
    tmp_inst2[pc] = {3'b000, 3'd4, 3'd5, 3'd6, 3'd0, 1'b0}; // core1: ADD r6 = r4 + r5
    pc = pc + 1;

    tmp_inst1[pc] = NOP;                          // core0: NOP, avoid STORE/STORE
    tmp_inst2[pc] = {3'b101, 3'd1, 3'd6, 7'd50}; // core1: STORE arr[150+i] <- r6
    pc = pc + 1;

    tmp_inst1[pc] = {3'b101, 3'd1, 3'd6, 7'd50}; // core0: STORE arr[50+i] <- r6
    tmp_inst2[pc] = NOP;                          // core1: NOP, avoid STORE/STORE
    pc = pc + 1;

    tmp_inst1[pc] = {3'b010, 3'd1, 3'd1, 7'd1};  // core0: r1 = r1 + 1
    tmp_inst2[pc] = {3'b010, 3'd1, 3'd1, 7'd1};  // core1: r1 = r1 + 1
    pc = pc + 1;

    tmp_inst1[pc] = {3'b010, 3'd2, 3'd2, 7'd1};  // core0: r2 = r2 + 1
    tmp_inst2[pc] = {3'b010, 3'd2, 3'd2, 7'd1};  // core1: r2 = r2 + 1
    pc = pc + 1;

    target_byte = loop_top_pc << 1;
    tmp_inst1[pc] = {3'b111, target_byte[12:0]}; // core0: backward JUMP loop_top
    tmp_inst2[pc] = {3'b111, target_byte[12:0]}; // core1: backward JUMP loop_top
    pc = pc + 1;

    loop_end_pc = pc;

    imm = loop_end_pc - (beq_pc + 1);
    tmp_inst1[beq_pc] = {3'b110, 3'd2, 3'd3, imm[6:0]}; // core0: forward BEQ r2,r3,loop_end
    tmp_inst2[beq_pc] = {3'b110, 3'd2, 3'd3, imm[6:0]}; // core1: forward BEQ r2,r3,loop_end

    // Main loop dynamic execution count:
    // 25 iterations:
    //   BEQ + LOAD + LOAD + ADD + NOP/STORE + STORE/NOP + ADDI + ADDI + JUMP = 9 IC
    // Final exit:
    //   BEQ taken = 1 IC
    exec_ic = exec_ic + (25 * 9) + 1;

    // ========================================================
    // Phase 7: Jump padding to 0x1FFE
    //
    // Both cores use the same control flow and the same PC.
    // Use forward JUMPs with 128-byte distance until reaching 0x1FFE.
    // ========================================================

    while (pc < final_word) begin
        if ((final_word - pc) > jump_step_word)
            target_word = pc + jump_step_word;
        else
            target_word = final_word;

        target_byte = target_word << 1;

        tmp_inst1[pc] = {3'b111, target_byte[12:0]}; // core0: JUMP forward
        tmp_inst2[pc] = {3'b111, target_byte[12:0]}; // core1: JUMP forward

        pc = target_word;
        exec_ic = exec_ic + 1;
    end

    tmp_inst1[final_word] = NOP; // core0: final NOP at 0x1FFE
    tmp_inst2[final_word] = NOP; // core1: final NOP at 0x1FFE
    exec_ic = exec_ic + 1;

    inst_count = exec_ic;

    $display("%0s[task_direct] direct test generated, executed IC = %0d%0s",
             txt_cyan_prefix, inst_count, reset_color);

    // --------------------------------------------------------
    // Write inst_1_dram_file.dat
    // --------------------------------------------------------
    fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        $fwrite(fd_i1, "@%04h\n", (i << 1));

        cop    = tmp_inst1[i][15:13];
        crs    = tmp_inst1[i][12:10];
        crt    = tmp_inst1[i][9:7];
        crd    = tmp_inst1[i][6:4];
        crl    = tmp_inst1[i][3:1];
        csub   = tmp_inst1[i][3:1];
        cimm   = tmp_inst1[i][6:0];
        cjaddr = tmp_inst1[i][12:0];

        br_tgt_byte = (i + 1 + $signed(cimm)) << 1;

        if (tmp_inst1[i] == NOP) begin
            $fwrite(fd_i1, "%02h %02h // %0d:NOP\n",
                    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i);
        end
        else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i1,"%02h %02h // %0d:ADD  r%0d=r%0d+r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b001: $fwrite(fd_i1,"%02h %02h // %0d:SUB  r%0d=r%0d-r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b010: $fwrite(fd_i1,"%02h %02h // %0d:AND  r%0d=r%0d&r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b011: $fwrite(fd_i1,"%02h %02h // %0d:OR   r%0d=r%0d|r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b100: $fwrite(fd_i1,"%02h %02h // %0d:NAND r%0d=~(r%0d&r%0d)\n", tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b101: $fwrite(fd_i1,"%02h %02h // %0d:NOR  r%0d=~(r%0d|r%0d)\n", tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b110: $fwrite(fd_i1,"%02h %02h // %0d:XOR  r%0d=r%0d^r%0d\n",    tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                        3'b111: $fwrite(fd_i1,"%02h %02h // %0d:SLT  r%0d=(r%0d<r%0d)\n",  tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crs,crt);
                    endcase
                end
                3'b001: $fwrite(fd_i1,"%02h %02h // %0d:MULT {r%0d,r%0d}=r%0d*r%0d\n", tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crd,crl,crs,crt);
                3'b010: $fwrite(fd_i1,"%02h %02h // %0d:ADDI r%0d=r%0d+%0d\n",          tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,crs,$signed(cimm));
                3'b011: $fwrite(fd_i1,"%02h %02h // %0d:SUBI r%0d=r%0d-%0d\n",          tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,crs,$signed(cimm));
                3'b100: $fwrite(fd_i1,"%02h %02h // %0d:LOAD  r%0d<-DM, rs=r%0d imm=%0d\n",  tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,crs,$signed(cimm));
                3'b101: $fwrite(fd_i1,"%02h %02h // %0d:STORE DM<-r%0d, rs=r%0d imm=%0d\n",  tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crt,crs,$signed(cimm));
                3'b110: $fwrite(fd_i1,"%02h %02h // %0d:BEQ  if(r%0d==r%0d) -> 0x%04h\n",   tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,crs,crt,br_tgt_byte[15:0]);
                3'b111: $fwrite(fd_i1,"%02h %02h // %0d:JUMP -> 0x%04h\n",                 tmp_inst1[i][7:0],tmp_inst1[i][15:8],i,{3'b0,cjaddr});
                default:$fwrite(fd_i1,"%02h %02h // %0d:NOP\n", tmp_inst1[i][7:0],tmp_inst1[i][15:8],i);
            endcase
        end
    end
    $fclose(fd_i1);

    // --------------------------------------------------------
    // Write inst_2_dram_file.dat
    // --------------------------------------------------------
    fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    for (i = 0; i < INST_DEPTH; i = i + 1) begin
        $fwrite(fd_i2, "@%04h\n", (i << 1));

        cop    = tmp_inst2[i][15:13];
        crs    = tmp_inst2[i][12:10];
        crt    = tmp_inst2[i][9:7];
        crd    = tmp_inst2[i][6:4];
        crl    = tmp_inst2[i][3:1];
        csub   = tmp_inst2[i][3:1];
        cimm   = tmp_inst2[i][6:0];
        cjaddr = tmp_inst2[i][12:0];

        br_tgt_byte = (i + 1 + $signed(cimm)) << 1;

        if (tmp_inst2[i] == NOP) begin
            $fwrite(fd_i2, "%02h %02h // %0d:NOP\n",
                    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i);
        end
        else begin
            case (cop)
                3'b000: begin
                    case (csub)
                        3'b000: $fwrite(fd_i2,"%02h %02h // %0d:ADD  r%0d=r%0d+r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b001: $fwrite(fd_i2,"%02h %02h // %0d:SUB  r%0d=r%0d-r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b010: $fwrite(fd_i2,"%02h %02h // %0d:AND  r%0d=r%0d&r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b011: $fwrite(fd_i2,"%02h %02h // %0d:OR   r%0d=r%0d|r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b100: $fwrite(fd_i2,"%02h %02h // %0d:NAND r%0d=~(r%0d&r%0d)\n", tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b101: $fwrite(fd_i2,"%02h %02h // %0d:NOR  r%0d=~(r%0d|r%0d)\n", tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b110: $fwrite(fd_i2,"%02h %02h // %0d:XOR  r%0d=r%0d^r%0d\n",    tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                        3'b111: $fwrite(fd_i2,"%02h %02h // %0d:SLT  r%0d=(r%0d<r%0d)\n",  tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crs,crt);
                    endcase
                end
                3'b001: $fwrite(fd_i2,"%02h %02h // %0d:MULT {r%0d,r%0d}=r%0d*r%0d\n", tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crd,crl,crs,crt);
                3'b010: $fwrite(fd_i2,"%02h %02h // %0d:ADDI r%0d=r%0d+%0d\n",          tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,crs,$signed(cimm));
                3'b011: $fwrite(fd_i2,"%02h %02h // %0d:SUBI r%0d=r%0d-%0d\n",          tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,crs,$signed(cimm));
                3'b100: $fwrite(fd_i2,"%02h %02h // %0d:LOAD  r%0d<-DM, rs=r%0d imm=%0d\n",  tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,crs,$signed(cimm));
                3'b101: $fwrite(fd_i2,"%02h %02h // %0d:STORE DM<-r%0d, rs=r%0d imm=%0d\n",  tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crt,crs,$signed(cimm));
                3'b110: $fwrite(fd_i2,"%02h %02h // %0d:BEQ  if(r%0d==r%0d) -> 0x%04h\n",   tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,crs,crt,br_tgt_byte[15:0]);
                3'b111: $fwrite(fd_i2,"%02h %02h // %0d:JUMP -> 0x%04h\n",                 tmp_inst2[i][7:0],tmp_inst2[i][15:8],i,{3'b0,cjaddr});
                default:$fwrite(fd_i2,"%02h %02h // %0d:NOP\n", tmp_inst2[i][7:0],tmp_inst2[i][15:8],i);
            endcase
        end
    end
    $fclose(fd_i2);

    // --------------------------------------------------------
    // Write data_dram_file.dat
    // --------------------------------------------------------
    fd_d = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
    for (i = DATA_ACC_LO; i <= DATA_ACC_HI; i = i + 2) begin
        $fwrite(fd_d, "@%04h\n", i);
        $fwrite(fd_d, "%02h %02h // DATA[%04h]=%0d\n",
                tmp_data_init[i], tmp_data_init[i+1], i,
                $signed({tmp_data_init[i+1], tmp_data_init[i]}));
    end
    $fclose(fd_d);

    $display("%0s[task_direct] .dat files written%0s",
             txt_cyan_prefix, reset_color);
end endtask
endmodule