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
`define PAT_NUM 1400
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 1400
`define MAX_WAIT_READY_CYCLE 100000
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
parameter PAT_NUM   = `PAT_NUM;
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

initial begin
    total_latency = 0;
    total_latency1 = 0;
    total_latency2 = 0;
    ic_1 = 0;
    ic_2 = 0;
    reset_task;
    gen_dram_files_task_memory;
    // gen_dram_files_task_basic;
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
    #(0.5 * CYCLE); rst_n = 1'b1;
    #(5 * CYCLE); release clk;
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
    // 25 groups: each group builds a base in r1 via ADDI chain, then
    // does 10 LS at base + various imm. Bases cover 0x1000~0x2F78.
    //
    // Constraint: |base_c2 - base_c1| <= 200 words (±200 data addr window)
    // Step = 160 words between groups, gap = 128 words within group
    // Base range: base_c2 + max_imm(60) <= 4095 -> max base_c2 = 3968+60=4028 OK
    // byte addr = 0x1000 + (base + imm) * 2 <= 0x2F78
    // ============================================================
    begin : extra_ls
        integer grp;
        integer base_c1, base_c2;

        for (grp = 0; grp < 25; grp = grp + 1) begin
            // All pairs: gap = 128 words < 200, step = 160 words across groups
            // byte_c1 = 0x1000 + base_c1*2, byte_c2 = 0x1000 + base_c2*2
            case (grp)
                0:  begin base_c1 = 0;    base_c2 = 128;  end // 0x1000 / 0x1100
                1:  begin base_c1 = 160;  base_c2 = 288;  end // 0x1140 / 0x1240
                2:  begin base_c1 = 320;  base_c2 = 448;  end // 0x1280 / 0x1380
                3:  begin base_c1 = 480;  base_c2 = 608;  end // 0x13C0 / 0x14C0
                4:  begin base_c1 = 640;  base_c2 = 768;  end // 0x1500 / 0x1600
                5:  begin base_c1 = 800;  base_c2 = 928;  end // 0x1640 / 0x1740
                6:  begin base_c1 = 960;  base_c2 = 1088; end // 0x1780 / 0x1880
                7:  begin base_c1 = 1120; base_c2 = 1248; end // 0x18C0 / 0x19C0
                8:  begin base_c1 = 1280; base_c2 = 1408; end // 0x1A00 / 0x1B00
                9:  begin base_c1 = 1440; base_c2 = 1568; end // 0x1B40 / 0x1C40
                10: begin base_c1 = 1600; base_c2 = 1728; end // 0x1C80 / 0x1D80
                11: begin base_c1 = 1760; base_c2 = 1888; end // 0x1DC0 / 0x1EC0
                12: begin base_c1 = 1920; base_c2 = 2048; end // 0x1F00 / 0x2000
                13: begin base_c1 = 2080; base_c2 = 2208; end // 0x2040 / 0x2140
                14: begin base_c1 = 2240; base_c2 = 2368; end // 0x2180 / 0x2280
                15: begin base_c1 = 2400; base_c2 = 2528; end // 0x22C0 / 0x23C0
                16: begin base_c1 = 2560; base_c2 = 2688; end // 0x2400 / 0x2500
                17: begin base_c1 = 2720; base_c2 = 2848; end // 0x2540 / 0x2640
                18: begin base_c1 = 2880; base_c2 = 3008; end // 0x2680 / 0x2780
                19: begin base_c1 = 3040; base_c2 = 3168; end // 0x27C0 / 0x28C0
                20: begin base_c1 = 3200; base_c2 = 3328; end // 0x2900 / 0x2A00
                21: begin base_c1 = 3360; base_c2 = 3488; end // 0x2A40 / 0x2B40
                22: begin base_c1 = 3520; base_c2 = 3648; end // 0x2B80 / 0x2C80
                23: begin base_c1 = 3680; base_c2 = 3808; end // 0x2CC0 / 0x2DC0
                24: begin base_c1 = 3840; base_c2 = 3968; end // 0x2E00 / 0x2F00
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

    for (step = 0; step < PAT_NUM; step = step + 1) begin
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

        if ((ic_1 == 49) || ((ic_1 > 49) && ((ic_1 + 1) % 50 == 0))) begin
            check_dram_task(step);
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
        beq_tgt1 = cur_pc1 + 2 + imm1g_ext;
        if ((beq_tgt1 & 1) != 0 || beq_tgt1 < 0 || beq_tgt1 > max_inst_addr) begin
            $display("  %0sPATTERN ERROR%0s  Core1 BEQ target illegal  pc=0x%04h tgt=0x%04h",
                     txt_red_prefix, reset_color, cur_pc1, beq_tgt1);
            $finish;
        end
    end
    if (op2g == 3'b110) begin
        beq_tgt2 = cur_pc2 + 2 + imm2g_ext;
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
    $display("                    All %0d Instructions Executed", PAT_NUM);
    $display("                       Cycle time = %-2f ns", CYCLE);
    $display("               Your execution cycles = %-4d cycles", total_latency);
    $display("======================================================================%0s", reset_color);
    $finish;
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

// task gen_dram_files_task; begin
//     integer fd_i1, fd_i2, fd_d;
//     integer i, rep;

//     reg [15:0] tmp_inst1 [0:INST_DEPTH-1];
//     reg [15:0] tmp_inst2 [0:INST_DEPTH-1];
//     reg [15:0] tmp_data  [0:DATA_TOP];

//     reg signed [15:0] sim_reg_c1 [0:7];
//     reg signed [15:0] sim_reg_c2 [0:7];

//     reg [15:0] NOP;
//     integer pc1, pc2, ic_count;

//     integer max_inst_addr;
//     integer cur_addr, target_addr, rel_imm, abs_delta;

//     NOP = 16'h0000;
//     max_inst_addr = (INST_DEPTH - 1) << 1;

//     // ------------------------------------------------------------
//     // Register usage
//     //   r1, r2 : ALU source
//     //   r3     : ALU / logic / slt / mult_hi destination
//     //   r4     : mult_lo destination
//     //   r5     : ADDI destination
//     //   r6     : SUBI destination, and STORE source
//     //   r7     : LOAD destination
//     //
//     // All functional writes avoid r0.
//     // ------------------------------------------------------------

//     for (i = 0; i < 8; i = i + 1) begin
//         sim_reg_c1[i] = 16'h0;
//         sim_reg_c2[i] = 16'h0;
//     end

//     for (i = 0; i < INST_DEPTH; i = i + 1) begin
//         tmp_inst1[i] = NOP;
//         tmp_inst2[i] = NOP;
//     end

//     for (i = 0; i < DATA_ACC_LO; i = i + 1)
//         tmp_data[i] = 16'h0;

//     for (i = DATA_ACC_LO; i <= DATA_ACC_HI; i = i + 1)
//         tmp_data[i] = $urandom_range(1024, 1);

//     // fixed data for LS tests
//     tmp_data[16'h1000] = 16'hA5A5;
//     tmp_data[16'h1002] = 16'h5A5A;
//     tmp_data[16'h1004] = 16'hCCCC;
//     tmp_data[16'h1006] = 16'hDDDD;

//     pc1 = 0;
//     pc2 = 0;
//     ic_count = 0;

//     // ============================================================
//     // 3 repeats x 18 instructions = 54 instructions
//     //
//     // Each repeat:
//     //   11 same instructions on both cores
//     //   7 LS pair patterns:
//     //     load nop
//     //     nop load
//     //     load load
//     //     nop store
//     //     store nop
//     //     load store
//     //     store load
//     //
//     // Array index is word index, but encoded/displayed address is byte
//     // address, i.e. @0000, @0002, @0004, ...
//     // ============================================================

//     for (rep = 0; rep < 3; rep = rep + 1) begin
//         // @ +0 : ADD  r3 = r1 + r2
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b000, 1'b0};
//         sim_reg_c1[3] = sim_reg_c1[1] + sim_reg_c1[2];
//         sim_reg_c2[3] = sim_reg_c2[1] + sim_reg_c2[2];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +1 : SUB  r3 = r1 - r2
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b001, 1'b0};
//         sim_reg_c1[3] = sim_reg_c1[1] - sim_reg_c1[2];
//         sim_reg_c2[3] = sim_reg_c2[1] - sim_reg_c2[2];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +2 : AND  r3 = r1 & r2
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b010, 1'b0};
//         sim_reg_c1[3] = sim_reg_c1[1] & sim_reg_c1[2];
//         sim_reg_c2[3] = sim_reg_c2[1] & sim_reg_c2[2];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +3 : OR   r3 = r1 | r2
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b011, 1'b0};
//         sim_reg_c1[3] = sim_reg_c1[1] | sim_reg_c1[2];
//         sim_reg_c2[3] = sim_reg_c2[1] | sim_reg_c2[2];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +4 : NAND r3 = ~(r1 & r2)
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b100, 1'b0};
//         sim_reg_c1[3] = ~(sim_reg_c1[1] & sim_reg_c1[2]);
//         sim_reg_c2[3] = ~(sim_reg_c2[1] & sim_reg_c2[2]);
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +5 : NOR  r3 = ~(r1 | r2)
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b101, 1'b0};
//         sim_reg_c1[3] = ~(sim_reg_c1[1] | sim_reg_c1[2]);
//         sim_reg_c2[3] = ~(sim_reg_c2[1] | sim_reg_c2[2]);
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +6 : XOR  r3 = r1 ^ r2
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b110, 1'b0};
//         sim_reg_c1[3] = sim_reg_c1[1] ^ sim_reg_c1[2];
//         sim_reg_c2[3] = sim_reg_c2[1] ^ sim_reg_c2[2];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +7 : SLT  r3 = (r1 < r2)
//         tmp_inst1[pc1] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
//         tmp_inst2[pc2] = {3'b000, 3'd1, 3'd2, 3'd3, 3'b111, 1'b0};
//         sim_reg_c1[3] = ($signed(sim_reg_c1[1]) < $signed(sim_reg_c1[2])) ? 16'h0001 : 16'h0000;
//         sim_reg_c2[3] = ($signed(sim_reg_c2[1]) < $signed(sim_reg_c2[2])) ? 16'h0001 : 16'h0000;
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +8 : MULT {r3,r4} = r1 * r2
//         tmp_inst1[pc1] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
//         tmp_inst2[pc2] = {3'b001, 3'd1, 3'd2, 3'd3, 3'd4, 1'b0};
//         begin
//             reg [31:0] prod1, prod2;
//             prod1 = sim_reg_c1[1] * sim_reg_c1[2];
//             prod2 = sim_reg_c2[1] * sim_reg_c2[2];
//             sim_reg_c1[3] = prod1[31:16];
//             sim_reg_c1[4] = prod1[15:0];
//             sim_reg_c2[3] = prod2[31:16];
//             sim_reg_c2[4] = prod2[15:0];
//         end
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +9 : ADDI r5 = r1 + 5
//         tmp_inst1[pc1] = {3'b010, 3'd1, 3'd5, 7'd5};
//         tmp_inst2[pc2] = {3'b010, 3'd1, 3'd5, 7'd5};
//         sim_reg_c1[5] = sim_reg_c1[1] + 16'sd5;
//         sim_reg_c2[5] = sim_reg_c2[1] + 16'sd5;
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +10 : SUBI r6 = r1 - 3
//         tmp_inst1[pc1] = {3'b011, 3'd1, 3'd6, 7'd3};
//         tmp_inst2[pc2] = {3'b011, 3'd1, 3'd6, 7'd3};
//         sim_reg_c1[6] = sim_reg_c1[1] - 16'sd3;
//         sim_reg_c2[6] = sim_reg_c2[1] - 16'sd3;
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +11 : core1 LOAD,  core2 NOP
//         tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, 7'd0}; // 0x1000
//         tmp_inst2[pc2] = NOP;
//         sim_reg_c1[7] = tmp_data[16'h1000];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +12 : core1 NOP,   core2 LOAD
//         tmp_inst1[pc1] = NOP;
//         tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, 7'd1}; // 0x1002
//         sim_reg_c2[7] = tmp_data[16'h1002];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +13 : core1 LOAD,  core2 LOAD
//         tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, 7'd0}; // 0x1000
//         tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, 7'd1}; // 0x1002
//         sim_reg_c1[7] = tmp_data[16'h1000];
//         sim_reg_c2[7] = tmp_data[16'h1002];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +14 : core1 NOP,   core2 STORE
//         tmp_inst1[pc1] = NOP;
//         tmp_inst2[pc2] = {3'b101, 3'd0, 3'd6, 7'd1}; // 0x1002
//         tmp_data[16'h1002] = sim_reg_c2[6];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +15 : core1 STORE, core2 NOP
//         tmp_inst1[pc1] = {3'b101, 3'd0, 3'd6, 7'd0}; // 0x1000
//         tmp_inst2[pc2] = NOP;
//         tmp_data[16'h1000] = sim_reg_c1[6];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +16 : core1 LOAD,  core2 STORE
//         // core2 store first, core1 load sees updated value
//         tmp_inst1[pc1] = {3'b100, 3'd0, 3'd7, 7'd2}; // 0x1004
//         tmp_inst2[pc2] = {3'b101, 3'd0, 3'd6, 7'd2}; // 0x1004
//         tmp_data[16'h1004] = sim_reg_c2[6];
//         sim_reg_c1[7]      = tmp_data[16'h1004];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//         // @ +17 : core1 STORE, core2 LOAD
//         // core2 load sees old value, then core1 store commits
//         tmp_inst1[pc1] = {3'b101, 3'd0, 3'd6, 7'd3}; // 0x1006
//         tmp_inst2[pc2] = {3'b100, 3'd0, 3'd7, 7'd3}; // 0x1006
//         sim_reg_c2[7]      = tmp_data[16'h1006];
//         tmp_data[16'h1006] = sim_reg_c1[6];
//         pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;
//     end

//     // ============================================================
//     // Branch tests
//     // PC/target are byte addresses, so:
//     //   not fall-through = pc + 2
//     //   taken target     = pc + 2 + imm
//     //
//     // target must be even
//     // ============================================================

//     // NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // Forward taken BEQ: target = current_pc + 2 + 4
//     cur_addr   = pc1 << 1;
//     target_addr = ((pc1 + 3) << 1); // skip two instructions, land on third
//     rel_imm    = target_addr - (cur_addr + 2);
//     if ((target_addr[0] != 0) || rel_imm < -64 || rel_imm > 63) begin
//         $display("====================================================================");
//         $display("  %0sPATTERN ERROR%0s  Illegal BEQ generated in gen_dram_files_task", txt_red_prefix, reset_color);
//         $display("  core1/core2 BEQ forward: pc=0x%04h target=0x%04h imm=%0d", cur_addr, target_addr, rel_imm);
//         $display("====================================================================");
//         $finish;
//     end
//     tmp_inst1[pc1] = {3'b110, 3'd0, 3'd0, rel_imm[6:0]};
//     tmp_inst2[pc2] = {3'b110, 3'd0, 3'd0, rel_imm[6:0]};
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // skipped NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // skipped NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // landing NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // Not-taken BEQ: target still must be even, though branch won't take
//     cur_addr    = pc1 << 1;
//     target_addr = ((pc1 + 2) << 1);
//     rel_imm     = target_addr - (cur_addr + 2);
//     if ((target_addr[0] != 0) || rel_imm < -64 || rel_imm > 63) begin
//         $display("====================================================================");
//         $display("  %0sPATTERN ERROR%0s  Illegal BEQ generated in gen_dram_files_task", txt_red_prefix, reset_color);
//         $display("  core1/core2 BEQ not-taken: pc=0x%04h target=0x%04h imm=%0d", cur_addr, target_addr, rel_imm);
//         $display("====================================================================");
//         $finish;
//     end
//     tmp_inst1[pc1] = {3'b110, 3'd5, 3'd6, rel_imm[6:0]};
//     tmp_inst2[pc2] = {3'b110, 3'd5, 3'd6, rel_imm[6:0]};
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // backward target NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // pad NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // Backward taken BEQ: target = one earlier NOP, still even
//     cur_addr    = pc1 << 1;
//     target_addr = ((pc1 - 2) << 1);
//     rel_imm     = target_addr - (cur_addr + 2);
//     if ((target_addr[0] != 0) || rel_imm < -64 || rel_imm > 63) begin
//         $display("====================================================================");
//         $display("  %0sPATTERN ERROR%0s  Illegal BEQ generated in gen_dram_files_task", txt_red_prefix, reset_color);
//         $display("  core1/core2 BEQ backward: pc=0x%04h target=0x%04h imm=%0d", cur_addr, target_addr, rel_imm);
//         $display("====================================================================");
//         $finish;
//     end
//     tmp_inst1[pc1] = {3'b110, 3'd0, 3'd0, rel_imm[6:0]};
//     tmp_inst2[pc2] = {3'b110, 3'd0, 3'd0, rel_imm[6:0]};
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // fall-through NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // ============================================================
//     // Jump tests
//     // Jump address is absolute byte address
//     // Must be even and |target - current_pc| <= 256
//     // ============================================================

//     cur_addr    = pc1 << 1;
//     target_addr = ((pc1 + 3) << 1); // skip two instructions, land at third
//     abs_delta   = (target_addr >= cur_addr) ? (target_addr - cur_addr) : (cur_addr - target_addr);

//     if ((target_addr[0] != 0) || (target_addr < 0) || (target_addr > max_inst_addr) || (abs_delta > 256)) begin
//         $display("====================================================================");
//         $display("  %0sPATTERN ERROR%0s  Illegal JUMP generated in gen_dram_files_task", txt_red_prefix, reset_color);
//         $display("  core1/core2 JUMP: pc=0x%04h target=0x%04h |delta|=%0d", cur_addr, target_addr, abs_delta);
//         $display("====================================================================");
//         $finish;
//     end

//     // JUMP -> landing
//     tmp_inst1[pc1] = {3'b111, target_addr[12:0]};
//     tmp_inst2[pc2] = {3'b111, target_addr[12:0]};
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // skipped NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // skipped NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // landing NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     // end marker NOP
//     tmp_inst1[pc1] = NOP;
//     tmp_inst2[pc2] = NOP;
//     pc1 = pc1 + 1; pc2 = pc2 + 1; ic_count = ic_count + 1;

//     $display("%0s[GEN] %0d ICs total (54 dual-core unit tests + 10 BEQ + 5 JUMP)%0s",
//              txt_cyan_prefix, ic_count, reset_color);

//     // ============================================================
//     // Write inst_1_dram_file.dat
//     // Address display is byte address: i << 1
//     // ============================================================
//     fd_i1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
//     for (i = 0; i < INST_DEPTH; i = i + 1) begin
//         reg [2:0]  cop, crs, crt, crd, crl, csub;
//         reg signed [6:0] cimm;
//         reg [12:0] caddr;

//         $fwrite(fd_i1, "@%04h\n", (i << 1));

//         cop   = tmp_inst1[i][15:13];
//         crs   = tmp_inst1[i][12:10];
//         crt   = tmp_inst1[i][9:7];
//         crd   = tmp_inst1[i][6:4];
//         crl   = tmp_inst1[i][3:1];
//         csub  = tmp_inst1[i][3:1];
//         cimm  = tmp_inst1[i][6:0];
//         caddr = tmp_inst1[i][12:0];

//         if (tmp_inst1[i] == NOP) begin
//             $fwrite(fd_i1, "%02h %02h // %d:NOP\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i);
//         end
//         else begin
//             case (cop)
//                 3'b000: begin
//                     case (csub)
//                         3'b000: $fwrite(fd_i1, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",       tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);   
//                         3'b001: $fwrite(fd_i1, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",       tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
//                         3'b010: $fwrite(fd_i1, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",       tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
//                         3'b011: $fwrite(fd_i1, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",       tmp_inst1[i][7:0], tmp_inst1[i][15:8], i,  crd, crs, crt);
//                         3'b100: $fwrite(fd_i1, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
//                         3'b101: $fwrite(fd_i1, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n",    tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
//                         3'b110: $fwrite(fd_i1, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",       tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
//                         3'b111: $fwrite(fd_i1, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",     tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crs, crt);
//                     endcase
//                 end
//                 3'b001: $fwrite(fd_i1, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n",       tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crd, crl, crs, crt);
//                 3'b011: $fwrite(fd_i1, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",                tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));   
//                 3'b100: $fwrite(fd_i1, "%02h %02h // %d:LOAD  r%0d <- DM[eff] rs=r%0d imm=%0d\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
//                 3'b101: $fwrite(fd_i1, "%02h %02h // %d:STORE DM[eff] <- r%0d rs=r%0d imm=%0d\n", tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crt, crs, $signed(cimm));
//                 3'b110: $fwrite(fd_i1, "%02h %02h // %d:BEQ   r%0d==r%0d ? target=(pc+2+%0d)\n",  tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, crs, crt, $signed(cimm));
//                 3'b111: $fwrite(fd_i1, "%02h %02h // %d:JUMP  0x%04h\n",                           tmp_inst1[i][7:0], tmp_inst1[i][15:8], i, caddr);
//             endcase
//         end
//     end
//     $fclose(fd_i1);

//     // ============================================================
//     // Write inst_2_dram_file.dat
//     // Address display is byte address: i << 1
//     // ============================================================
//     fd_i2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
//     for (i = 0; i < INST_DEPTH; i = i + 1) begin
//         reg [2:0]  cop, crs, crt, crd, crl, csub;
//         reg signed [6:0] cimm;
//         reg [12:0] caddr;

//         $fwrite(fd_i2, "@%04h\n", (i << 1));

//         cop   = tmp_inst2[i][15:13];
//         crs   = tmp_inst2[i][12:10];
//         crt   = tmp_inst2[i][9:7];
//         crd   = tmp_inst2[i][6:4];
//         crl   = tmp_inst2[i][3:1];
//         csub  = tmp_inst2[i][3:1];
//         cimm  = tmp_inst2[i][6:0];
//         caddr = tmp_inst2[i][12:0];

//         if (tmp_inst2[i] == NOP) begin
//                 $fwrite(fd_i2, "%02h %02h // %d:NOP\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i);
//         end
//         else begin
//             case (cop)
//                 3'b000: begin
//                     case (csub)
//                         3'b000: $fwrite(fd_i2, "%02h %02h // %d:ADD  r%0d = r%0d + r%0d\n",       tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
//                         3'b001: $fwrite(fd_i2, "%02h %02h // %d:SUB  r%0d = r%0d - r%0d\n",       tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
//                         3'b010: $fwrite(fd_i2, "%02h %02h // %d:AND  r%0d = r%0d & r%0d\n",       tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);       
//                         3'b011: $fwrite(fd_i2, "%02h %02h // %d:OR   r%0d = r%0d | r%0d\n",       tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
//                         3'b100: $fwrite(fd_i2, "%02h %02h // %d:NAND r%0d = ~(r%0d & r%0d)\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, i, crd, crs, crt);
//                         3'b101: $fwrite(fd_i2, "%02h %02h // %d:NOR  r%0d = ~(r%0d | r%0d)\n",    tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, i, crd, crs, crt);
//                         3'b110: $fwrite(fd_i2, "%02h %02h // %d:XOR  r%0d = r%0d ^ r%0d\n",       tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crs, crt);
//                         3'b111: $fwrite(fd_i2, "%02h %02h // %d:SLT  r%0d = (r%0d < r%0d)\n",     tmp_inst2[i][7:0], tmp_inst2[i][15:8], i      , crd, crs, crt);
//                     endcase
//                 end
//                 3'b001: $fwrite(fd_i2, "%02h %02h // %d:MULT {r%0d,r%0d} = r%0d * r%0d\n",       tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crd, crl, crs, crt);
//                 3'b011: $fwrite(fd_i2, "%02h %02h // %d:SUBI r%0d = r%0d - %0d\n",                tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
//                 3'b100: $fwrite(fd_i2, "%02h %02h // %d:LOAD  r%0d <- DM[eff] rs=r%0d imm=%0d\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
//                 3'b101: $fwrite(fd_i2, "%02h %02h // %d:STORE DM[eff] <- r%0d rs=r%0d imm=%0d\n", tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crt, crs, $signed(cimm));
//                 3'b110: $fwrite(fd_i2, "%02h %02h // %d:BEQ   r%0d==r%0d ? target=(pc+2+%0d)\n",  tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, crs, crt, $signed(cimm));
//                 3'b111: $fwrite(fd_i2, "%02h %02h // %d:JUMP  0x%04h\n",                           tmp_inst2[i][7:0], tmp_inst2[i][15:8], i, caddr);
//             endcase
//         end
//     end
//     $fclose(fd_i2);

//     // ============================================================
//     // Write shared data_dram_file.dat
//     // ============================================================
//     fd_d = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
//     for (i = DATA_ACC_LO; i <= DATA_ACC_HI; i = i + 1) begin
//         $fwrite(fd_d, "@%04h\n", (i << 1));
//         $fwrite(fd_d, "%02h %02h // DATA[%04h] = %d\n", tmp_data[i][15:8], tmp_data[i][7:0], i, tmp_data[i]);
   
//     end
//     $fclose(fd_d);

//     $display("%0s[GEN] .dat files written%0s", txt_cyan_prefix, reset_color);
// end endtask
endmodule