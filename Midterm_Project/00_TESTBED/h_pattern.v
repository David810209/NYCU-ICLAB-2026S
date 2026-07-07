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
	`define CYCLE_TIME 20.0
`elsif GATE
	`define CYCLE_TIME 20.0
`elsif CHIP
    `define CYCLE_TIME 20.0
`elsif POST
    `define CYCLE_TIME 20.0
`endif

`ifdef FUNC
`define PAT_NUM 952
`define MAX_WAIT_READY_CYCLE 2000
`endif
`ifdef PERF
`define PAT_NUM 952
`define MAX_WAIT_READY_CYCLE 100000
`endif

`define DRAM_COUNT     1
`define PAT_NUMBER     2000
`define MAX_WAIT_CYCLE 2000

// Number of prologue instructions inserted per core to initialize r1..r7.
// 7 target regs * 2 ADDIs each = 14.
`define PROLOGUE_CNT   14

`define COLOR_RED     "\033[1;31m"
`define COLOR_GREEN   "\033[1;32m"
`define COLOR_YELLOW  "\033[1;33m"
`define COLOR_BLUE    "\033[1;34m"
`define COLOR_MAGENTA "\033[1;35m"
`define COLOR_CYAN    "\033[1;36m"
`define COLOR_WHITE   "\033[1;37m"
`define COLOR_RESET   "\033[0m"

module PATTERN(
    clk, rst_n,
    stall_1, stall_2,
    //===== Inst DRAM 1 =====
    arid_s_inf_inst_1, araddr_s_inf_inst_1, arlen_s_inf_inst_1, arsize_s_inf_inst_1,
    arburst_s_inf_inst_1, arvalid_s_inf_inst_1, arready_s_inf_inst_1,
    rid_s_inf_inst_1, rdata_s_inf_inst_1, rresp_s_inf_inst_1, rlast_s_inf_inst_1,
    rvalid_s_inf_inst_1, rready_s_inf_inst_1,
    awid_s_inf_inst_1, awaddr_s_inf_inst_1, awsize_s_inf_inst_1, awburst_s_inf_inst_1,
    awlen_s_inf_inst_1, awvalid_s_inf_inst_1, awready_s_inf_inst_1,
    wdata_s_inf_inst_1, wlast_s_inf_inst_1, wvalid_s_inf_inst_1, wready_s_inf_inst_1,
    bid_s_inf_inst_1, bresp_s_inf_inst_1, bvalid_s_inf_inst_1, bready_s_inf_inst_1,
    //===== Inst DRAM 2 =====
    arid_s_inf_inst_2, araddr_s_inf_inst_2, arlen_s_inf_inst_2, arsize_s_inf_inst_2,
    arburst_s_inf_inst_2, arvalid_s_inf_inst_2, arready_s_inf_inst_2,
    rid_s_inf_inst_2, rdata_s_inf_inst_2, rresp_s_inf_inst_2, rlast_s_inf_inst_2,
    rvalid_s_inf_inst_2, rready_s_inf_inst_2,
    awid_s_inf_inst_2, awaddr_s_inf_inst_2, awsize_s_inf_inst_2, awburst_s_inf_inst_2,
    awlen_s_inf_inst_2, awvalid_s_inf_inst_2, awready_s_inf_inst_2,
    wdata_s_inf_inst_2, wlast_s_inf_inst_2, wvalid_s_inf_inst_2, wready_s_inf_inst_2,
    bid_s_inf_inst_2, bresp_s_inf_inst_2, bvalid_s_inf_inst_2, bready_s_inf_inst_2,
    //===== Data DRAM =====
    arid_s_inf_data, araddr_s_inf_data, arlen_s_inf_data, arsize_s_inf_data,
    arburst_s_inf_data, arvalid_s_inf_data, arready_s_inf_data,
    rid_s_inf_data, rdata_s_inf_data, rresp_s_inf_data, rlast_s_inf_data,
    rvalid_s_inf_data, rready_s_inf_data,
    awid_s_inf_data, awaddr_s_inf_data, awsize_s_inf_data, awburst_s_inf_data,
    awlen_s_inf_data, awvalid_s_inf_data, awready_s_inf_data,
    wdata_s_inf_data, wlast_s_inf_data, wvalid_s_inf_data, wready_s_inf_data,
    bid_s_inf_data, bresp_s_inf_data, bvalid_s_inf_data, bready_s_inf_data
);

parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=16, BURST_LEN=7;

output reg clk;
output reg rst_n;
input wire stall_1, stall_2;

// Inst DRAM 1
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

// Inst DRAM 2
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

// Data DRAM
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

//======================================================================
//  DRAM INSTANCES
//======================================================================
pseudo_DRAM_inst1 u_DRAM_inst1 (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf(awid_s_inf_inst_1), .awaddr_s_inf(awaddr_s_inf_inst_1),
    .awsize_s_inf(awsize_s_inf_inst_1), .awburst_s_inf(awburst_s_inf_inst_1),
    .awlen_s_inf(awlen_s_inf_inst_1), .awvalid_s_inf(awvalid_s_inf_inst_1),
    .awready_s_inf(awready_s_inf_inst_1),
    .wdata_s_inf(wdata_s_inf_inst_1), .wlast_s_inf(wlast_s_inf_inst_1),
    .wvalid_s_inf(wvalid_s_inf_inst_1), .wready_s_inf(wready_s_inf_inst_1),
    .bid_s_inf(bid_s_inf_inst_1), .bresp_s_inf(bresp_s_inf_inst_1),
    .bvalid_s_inf(bvalid_s_inf_inst_1), .bready_s_inf(bready_s_inf_inst_1),
    .arid_s_inf(arid_s_inf_inst_1), .araddr_s_inf(araddr_s_inf_inst_1),
    .arlen_s_inf(arlen_s_inf_inst_1), .arsize_s_inf(arsize_s_inf_inst_1),
    .arburst_s_inf(arburst_s_inf_inst_1), .arvalid_s_inf(arvalid_s_inf_inst_1),
    .arready_s_inf(arready_s_inf_inst_1),
    .rid_s_inf(rid_s_inf_inst_1), .rdata_s_inf(rdata_s_inf_inst_1),
    .rresp_s_inf(rresp_s_inf_inst_1), .rlast_s_inf(rlast_s_inf_inst_1),
    .rvalid_s_inf(rvalid_s_inf_inst_1), .rready_s_inf(rready_s_inf_inst_1)
);

pseudo_DRAM_inst2 u_DRAM_inst2 (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf(awid_s_inf_inst_2), .awaddr_s_inf(awaddr_s_inf_inst_2),
    .awsize_s_inf(awsize_s_inf_inst_2), .awburst_s_inf(awburst_s_inf_inst_2),
    .awlen_s_inf(awlen_s_inf_inst_2), .awvalid_s_inf(awvalid_s_inf_inst_2),
    .awready_s_inf(awready_s_inf_inst_2),
    .wdata_s_inf(wdata_s_inf_inst_2), .wlast_s_inf(wlast_s_inf_inst_2),
    .wvalid_s_inf(wvalid_s_inf_inst_2), .wready_s_inf(wready_s_inf_inst_2),
    .bid_s_inf(bid_s_inf_inst_2), .bresp_s_inf(bresp_s_inf_inst_2),
    .bvalid_s_inf(bvalid_s_inf_inst_2), .bready_s_inf(bready_s_inf_inst_2),
    .arid_s_inf(arid_s_inf_inst_2), .araddr_s_inf(araddr_s_inf_inst_2),
    .arlen_s_inf(arlen_s_inf_inst_2), .arsize_s_inf(arsize_s_inf_inst_2),
    .arburst_s_inf(arburst_s_inf_inst_2), .arvalid_s_inf(arvalid_s_inf_inst_2),
    .arready_s_inf(arready_s_inf_inst_2),
    .rid_s_inf(rid_s_inf_inst_2), .rdata_s_inf(rdata_s_inf_inst_2),
    .rresp_s_inf(rresp_s_inf_inst_2), .rlast_s_inf(rlast_s_inf_inst_2),
    .rvalid_s_inf(rvalid_s_inf_inst_2), .rready_s_inf(rready_s_inf_inst_2)
);

pseudo_DRAM_data u_DRAM_data (
    .clk(clk), .rst_n(rst_n),
    .awid_s_inf(awid_s_inf_data), .awaddr_s_inf(awaddr_s_inf_data),
    .awsize_s_inf(awsize_s_inf_data), .awburst_s_inf(awburst_s_inf_data),
    .awlen_s_inf(awlen_s_inf_data), .awvalid_s_inf(awvalid_s_inf_data),
    .awready_s_inf(awready_s_inf_data),
    .wdata_s_inf(wdata_s_inf_data), .wlast_s_inf(wlast_s_inf_data),
    .wvalid_s_inf(wvalid_s_inf_data), .wready_s_inf(wready_s_inf_data),
    .bid_s_inf(bid_s_inf_data), .bresp_s_inf(bresp_s_inf_data),
    .bvalid_s_inf(bvalid_s_inf_data), .bready_s_inf(bready_s_inf_data),
    .arid_s_inf(arid_s_inf_data), .araddr_s_inf(araddr_s_inf_data),
    .arlen_s_inf(arlen_s_inf_data), .arsize_s_inf(arsize_s_inf_data),
    .arburst_s_inf(arburst_s_inf_data), .arvalid_s_inf(arvalid_s_inf_data),
    .arready_s_inf(arready_s_inf_data),
    .rid_s_inf(rid_s_inf_data), .rdata_s_inf(rdata_s_inf_data),
    .rresp_s_inf(rresp_s_inf_data), .rlast_s_inf(rlast_s_inf_data),
    .rvalid_s_inf(rvalid_s_inf_data), .rready_s_inf(rready_s_inf_data)
);

//======================================================================
//  VARIABLE DECLARATIONS
//======================================================================
integer dramcount, ic;
integer total_cycles, cur_cycles, cycles;
integer i, j;
integer inst_fp1, inst_fp2, data_fp;

// Golden register files for each core
reg signed [15:0] gr1 [0:7];
reg signed [15:0] gr2 [0:7];

// Golden data memory
reg [7:0] gdata [0:16'h2FFF];

// Golden PC (byte address)
reg [15:0] gpc1, gpc2;

// Instruction storage (byte-addressable)
reg [7:0] inst1_mem [0:16'h1FFF];
reg [7:0] inst2_mem [0:16'h1FFF];

// Current instruction decode fields
reg [15:0] inst_c1, inst_c2;
reg [2:0]  op1, op2;
reg [2:0]  rs1, rt1, rd1, func1, rl1;
reg [2:0]  rs2, rt2, rd2, func2, rl2;
reg [6:0]  imm1, imm2;
reg [12:0] addr1, addr2;

// Flags for this-IC behavior
reg c1_is_store, c2_is_store;
reg c1_is_load,  c2_is_load;
reg [15:0] c1_addr, c2_addr;

// ============================================================
// Shadow register model for pattern generation
// Tracks approximate values so LOAD/STORE can pick a safe rs.
// ============================================================
reg signed [15:0] reg_val1     [0:7];
reg signed [15:0] reg_val2     [0:7];
reg               reg_unknown1 [0:7];
reg               reg_unknown2 [0:7];

// Safe range: we want R[rs]*2 + 0x1000 + imm*2 to stay in [0x1000, 0x2FFF]
// => R[rs] + imm in [0, 0xFFF]. With imm in [0, 31], pick R[rs] in [0x40, 0xF00].
localparam integer SAFE_LO = 16'h0040;
localparam integer SAFE_HI = 16'h0F00;

//======================================================================
//  CLOCK
//======================================================================
initial clk = 0;
always #(`CYCLE_TIME/2.0) clk = ~clk;

//======================================================================
//  MAIN
//======================================================================
initial begin
    total_cycles = 0;

    gen_dram_task(0);
    $readmemh("../00_TESTBED/DRAM/inst_1_dram_file.dat", u_DRAM_inst1.DRAM_r);
    $readmemh("../00_TESTBED/DRAM/inst_2_dram_file.dat", u_DRAM_inst2.DRAM_r);
    $readmemh("../00_TESTBED/DRAM/data_dram_file.dat",   u_DRAM_data.DRAM_r);

    reset_task;

    for (dramcount = 0; dramcount < `DRAM_COUNT; dramcount = dramcount + 1) begin
        if (dramcount > 0) begin
            gen_dram_task(dramcount);
            $readmemh("../00_TESTBED/DRAM/inst_1_dram_file.dat", u_DRAM_inst1.DRAM_r);
            $readmemh("../00_TESTBED/DRAM/inst_2_dram_file.dat", u_DRAM_inst2.DRAM_r);
            $readmemh("../00_TESTBED/DRAM/data_dram_file.dat",   u_DRAM_data.DRAM_r);
        end

        read_golden_data_task;
        for (i = 0; i < 8; i = i + 1) begin
            gr1[i] = 0;
            gr2[i] = 0;
        end
        gpc1 = 16'h0000;
        gpc2 = 16'h0000;

        @(negedge clk);

        for (ic = 0; ic < `PAT_NUMBER; ic = ic + 1) begin
            cur_cycles = total_cycles;

            inst_c1 = {inst1_mem[gpc1+1], inst1_mem[gpc1]};
            inst_c2 = {inst2_mem[gpc2+1], inst2_mem[gpc2]};
            $display("IC=%0d  inst_c1=%h  inst_c2=%h", ic, inst_c1, inst_c2);
            decode_inst(inst_c1, op1, rs1, rt1, rd1, func1, rl1, imm1, addr1);
            decode_inst(inst_c2, op2, rs2, rt2, rd2, func2, rl2, imm2, addr2);

            classify_mem_op(op1, rs1, imm1, 1, c1_is_store, c1_is_load, c1_addr);
            classify_mem_op(op2, rs2, imm2, 2, c2_is_store, c2_is_load, c2_addr);

            if (c2_is_store) execute_core2;
            execute_core1;
            if (!c2_is_store) execute_core2;

            wait_both_stall_low_task;
            check_reg_task;

            $display({`COLOR_GREEN, "PASS IC = %0d, latency = %0d", `COLOR_RESET, "\n"}, ic, total_cycles);

            if ((ic + 1) % 50 == 0 || ic == `PAT_NUMBER - 1) begin
                check_data_dram_task;
                $display({`COLOR_CYAN, "====================================", `COLOR_RESET});
                $display({`COLOR_CYAN, "========PASS DRAM CHECK TASK========", `COLOR_RESET});
                $display({`COLOR_CYAN, "========PASS DRAM CHECK TASK========", `COLOR_RESET});
                $display({`COLOR_CYAN, "========PASS DRAM CHECK TASK========", `COLOR_RESET});
                $display({`COLOR_CYAN, "========PASS DRAM CHECK TASK========", `COLOR_RESET});
                $display({`COLOR_CYAN, "====================================\n", `COLOR_RESET});
            end
        end
    end

    YOU_PASS_task;
    $finish;
end

//======================================================================
//  RESET
//======================================================================
task reset_task; begin
    force clk = 0;
    rst_n = 1;
    #5  rst_n = 0;
    #100;
    if (stall_1 !== 1'b1 || stall_2 !== 1'b1) begin
        $display("FAIL: stall_1/stall_2 must be HIGH after reset");
        f_ail_task;
    end
    if (u_DCCPU.core_1_r0 !== 0 || u_DCCPU.core_1_r1 !== 0 ||
        u_DCCPU.core_1_r2 !== 0 || u_DCCPU.core_1_r3 !== 0 ||
        u_DCCPU.core_1_r4 !== 0 || u_DCCPU.core_1_r5 !== 0 ||
        u_DCCPU.core_1_r6 !== 0 || u_DCCPU.core_1_r7 !== 0 ||
        u_DCCPU.core_2_r0 !== 0 || u_DCCPU.core_2_r1 !== 0 ||
        u_DCCPU.core_2_r2 !== 0 || u_DCCPU.core_2_r3 !== 0 ||
        u_DCCPU.core_2_r4 !== 0 || u_DCCPU.core_2_r5 !== 0 ||
        u_DCCPU.core_2_r6 !== 0 || u_DCCPU.core_2_r7 !== 0) begin
        $display("FAIL: registers must be 0 after reset");
        f_ail_task;
    end
    #10 rst_n = 1;
    #100 release clk;
end endtask

//======================================================================
//  WAIT STALL LOW
//======================================================================
task wait_both_stall_low_task; begin
    cycles = 0;
    @(negedge clk);   // Sample at negedge to avoid race condition
    while (stall_1 !== 1'b0 || stall_2 !== 1'b0) begin
        cycles = cycles + 1;
        if (cycles >= `MAX_WAIT_CYCLE) begin
            $display("FAIL: stall high > %0d cycles (IC=%0d)", `MAX_WAIT_CYCLE, ic);
            f_ail_task;
        end
        @(negedge clk);
    end
    total_cycles = total_cycles + cycles;
end endtask

//======================================================================
//  CHECK REGISTERS
//======================================================================
task check_reg_task; begin
    // print_reg_task;
    if (u_DCCPU.core_1_r0 !== gr1[0] || u_DCCPU.core_1_r1 !== gr1[1] ||
        u_DCCPU.core_1_r2 !== gr1[2] || u_DCCPU.core_1_r3 !== gr1[3] ||
        u_DCCPU.core_1_r4 !== gr1[4] || u_DCCPU.core_1_r5 !== gr1[5] ||
        u_DCCPU.core_1_r6 !== gr1[6] || u_DCCPU.core_1_r7 !== gr1[7]) begin
        $display("FAIL: Core 1 register mismatch at IC=%0d", ic);
        print_reg_task;
        f_ail_task;
    end
    if (u_DCCPU.core_2_r0 !== gr2[0] || u_DCCPU.core_2_r1 !== gr2[1] ||
        u_DCCPU.core_2_r2 !== gr2[2] || u_DCCPU.core_2_r3 !== gr2[3] ||
        u_DCCPU.core_2_r4 !== gr2[4] || u_DCCPU.core_2_r5 !== gr2[5] ||
        u_DCCPU.core_2_r6 !== gr2[6] || u_DCCPU.core_2_r7 !== gr2[7]) begin
        $display("FAIL: Core 2 register mismatch at IC=%0d", ic);
        print_reg_task;
        f_ail_task;
    end
end endtask

task print_reg_task; begin
    for (i = 0; i < 8; i = i + 1)
        $display("  C1.r%0d: dut=%5d golden=%5d  |  C2.r%0d: dut=%5d golden=%5d",
                 i, $signed(get_core1_reg(i)), gr1[i],
                 i, $signed(get_core2_reg(i)), gr2[i]);
end endtask

function [15:0] get_core1_reg(input [2:0] idx);
    case (idx)
        0: get_core1_reg = u_DCCPU.core_1_r0;
        1: get_core1_reg = u_DCCPU.core_1_r1;
        2: get_core1_reg = u_DCCPU.core_1_r2;
        3: get_core1_reg = u_DCCPU.core_1_r3;
        4: get_core1_reg = u_DCCPU.core_1_r4;
        5: get_core1_reg = u_DCCPU.core_1_r5;
        6: get_core1_reg = u_DCCPU.core_1_r6;
        7: get_core1_reg = u_DCCPU.core_1_r7;
    endcase
endfunction

function [15:0] get_core2_reg(input [2:0] idx);
    case (idx)
        0: get_core2_reg = u_DCCPU.core_2_r0;
        1: get_core2_reg = u_DCCPU.core_2_r1;
        2: get_core2_reg = u_DCCPU.core_2_r2;
        3: get_core2_reg = u_DCCPU.core_2_r3;
        4: get_core2_reg = u_DCCPU.core_2_r4;
        5: get_core2_reg = u_DCCPU.core_2_r5;
        6: get_core2_reg = u_DCCPU.core_2_r6;
        7: get_core2_reg = u_DCCPU.core_2_r7;
    endcase
endfunction

//======================================================================
//  CHECK DATA DRAM
//======================================================================
task check_data_dram_task; begin
    for (i = 16'h1000; i < 16'h2000; i = i + 2) begin
        if ({u_DRAM_data.DRAM_r[i+1], u_DRAM_data.DRAM_r[i]}
            !== {gdata[i+1], gdata[i]}) begin
            $display("FAIL: DATA DRAM mismatch @0x%4x: dut=%4x golden=%4x (IC=%0d)",
                i, {u_DRAM_data.DRAM_r[i+1], u_DRAM_data.DRAM_r[i]},
                {gdata[i+1], gdata[i]}, ic);
            f_ail_task;
        end
    end
end endtask

task read_golden_data_task; begin
    for (i = 16'h1000; i < 16'h2000; i = i + 1)
        gdata[i] = u_DRAM_data.DRAM_r[i];
end endtask

//======================================================================
//  DECODE
//======================================================================
task decode_inst(
    input [15:0] inst,
    output reg [2:0] op, rs, rt, rd, func, rl,
    output reg [6:0] imm,
    output reg [12:0] addr
);
begin
    op   = inst[15:13];
    rs   = inst[12:10];
    rt   = inst[9:7];
    rd   = inst[6:4];
    func = inst[3:1];
    rl   = inst[3:1];
    imm  = inst[6:0];
    addr = inst[12:0];
end endtask

task classify_mem_op(
    input [2:0] op,
    input [2:0] rs_idx,
    input [6:0] imm7,
    input integer which_core,
    output reg is_store,
    output reg is_load,
    output reg [15:0] mem_addr
);
    reg signed [15:0] rs_val;
    reg signed [15:0] sext_imm;
begin
    is_store = (op === 3'b101);
    is_load  = (op === 3'b100);
    if (which_core == 1) rs_val = gr1[rs_idx];
    else                 rs_val = gr2[rs_idx];
    sext_imm = {{9{imm7[6]}}, imm7};
    mem_addr = (rs_val + sext_imm) * 2 + 16'h1000;
end endtask

//======================================================================
//  EXECUTE (update golden model)
//======================================================================
task execute_core1; begin
    exec_one(1, op1, rs1, rt1, rd1, func1, rl1, imm1, addr1, gpc1);
end endtask

task execute_core2; begin
    exec_one(2, op2, rs2, rt2, rd2, func2, rl2, imm2, addr2, gpc2);
end endtask

task exec_one(
    input integer which,
    input [2:0] op, rs, rt, rd, func, rl,
    input [6:0] imm,
    input [12:0] addr,
    inout [15:0] pc
);
    reg signed [15:0] a, b, result, sext_imm;
    reg signed [31:0] mult_res;
    reg [15:0] mem_addr;
begin
    if (which == 1) begin a = gr1[rs]; b = gr1[rt]; end
    else            begin a = gr2[rs]; b = gr2[rt]; end
    sext_imm = {{9{imm[6]}}, imm};
    pc = pc + 2;
    case (op)
        3'b000: begin
            case (func)
                3'b000: result = a + b;
                3'b001: result = a - b;
                3'b010: result = a & b;
                3'b011: result = a | b;
                3'b100: result = ~(a & b);
                3'b101: result = ~(a | b);
                3'b110: result = a ^ b;
                3'b111: result = (a < b) ? 16'd1 : 16'd0;
            endcase
            if (which == 1) gr1[rd] = result; else gr2[rd] = result;
        end
        3'b001: begin
            mult_res = a * b;
            if (which == 1) begin
                gr1[rd] = mult_res[31:16];
                gr1[rl] = mult_res[15:0];
            end else begin
                gr2[rd] = mult_res[31:16];
                gr2[rl] = mult_res[15:0];
            end
        end
        3'b010: begin
            if (which == 1) gr1[rt] = a + sext_imm;
            else            gr2[rt] = a + sext_imm;
        end
        3'b011: begin
            if (which == 1) gr1[rt] = a - sext_imm;
            else            gr2[rt] = a - sext_imm;
        end
        3'b100: begin
            mem_addr = (a + sext_imm) * 2 + 16'h1000;
            if (which == 1)
                gr1[rt] = {gdata[mem_addr+1], gdata[mem_addr]};
            else
                gr2[rt] = {gdata[mem_addr+1], gdata[mem_addr]};
        end
        3'b101: begin
            mem_addr = (a + sext_imm) * 2 + 16'h1000;
            gdata[mem_addr]   = b[7:0];
            gdata[mem_addr+1] = b[15:8];
        end
        3'b110: begin
            if (a === b)
                pc = pc + sext_imm * 2;
        end
        3'b111: begin
            pc = {addr, 1'b0};
        end
    endcase
end endtask

//======================================================================
//  SHADOW REGISTER MODEL (for pattern generation)
//======================================================================
task init_shadow_regs;
    integer n;
    begin
        for (n = 0; n < 8; n = n + 1) begin
            reg_val1[n]     = 16'd0;   // CPU resets regs to 0
            reg_val2[n]     = 16'd0;
            reg_unknown1[n] = 1'b0;
            reg_unknown2[n] = 1'b0;
        end
    end
endtask

// Is register `r` of `which` core safe to use as LOAD/STORE rs?
function is_safe_rs(input integer which, input [2:0] r);
    reg signed [15:0] v;
    reg unk;
begin
    if (which == 1) begin
        v   = reg_val1[r];
        unk = reg_unknown1[r];
    end else begin
        v   = reg_val2[r];
        unk = reg_unknown2[r];
    end
    is_safe_rs = (!unk) && (v >= SAFE_LO) && (v <= SAFE_HI);
end endfunction

// Count how many registers in core `which` are safe
function integer count_safe(input integer which);
    integer n, cnt;
begin
    cnt = 0;
    for (n = 0; n < 8; n = n + 1)
        if (is_safe_rs(which, n[2:0])) cnt = cnt + 1;
    count_safe = cnt;
end endfunction

// Pick a random safe register (caller must ensure count_safe > 0)
function [2:0] pick_safe_rs(input integer which);
    integer n, pick, cnt;
    reg [2:0] result;
begin
    cnt = count_safe(which);
    pick = $random % cnt;
    if (pick < 0) pick = -pick;
    cnt = 0;
    result = 3'd0;
    for (n = 0; n < 8; n = n + 1) begin
        if (is_safe_rs(which, n[2:0])) begin
            if (cnt == pick) result = n[2:0];
            cnt = cnt + 1;
        end
    end
    pick_safe_rs = result;
end endfunction

// Update shadow regs after emitting an instruction
task update_shadow(input integer which, input [15:0] inst);
    reg [2:0] op, rs, rt, rd, rl;
    reg [6:0] imm7;
    reg signed [15:0] sext_imm;
    reg signed [15:0] v_rs;
    reg               unk_rs;
begin
    op   = inst[15:13];
    rs   = inst[12:10];
    rt   = inst[9:7];
    rd   = inst[6:4];
    rl   = inst[3:1];
    imm7 = inst[6:0];
    sext_imm = {{9{imm7[6]}}, imm7};

    if (which == 1) begin
        v_rs   = reg_val1[rs];
        unk_rs = reg_unknown1[rs];
    end else begin
        v_rs   = reg_val2[rs];
        unk_rs = reg_unknown2[rs];
    end

    case (op)
        3'b000: begin
            // R-type writes rd with a computed value -> mark unknown
            if (which == 1) reg_unknown1[rd] = 1'b1;
            else            reg_unknown2[rd] = 1'b1;
        end
        3'b001: begin
            // MULT writes rd and rl -> mark both unknown
            if (which == 1) begin
                reg_unknown1[rd] = 1'b1;
                reg_unknown1[rl] = 1'b1;
            end else begin
                reg_unknown2[rd] = 1'b1;
                reg_unknown2[rl] = 1'b1;
            end
        end
        3'b010: begin
            // ADDI: rt = rs + imm
            if (which == 1) begin
                reg_unknown1[rt] = unk_rs;
                reg_val1[rt]     = v_rs + sext_imm;
            end else begin
                reg_unknown2[rt] = unk_rs;
                reg_val2[rt]     = v_rs + sext_imm;
            end
        end
        3'b011: begin
            // SUBI: rt = rs - imm
            if (which == 1) begin
                reg_unknown1[rt] = unk_rs;
                reg_val1[rt]     = v_rs - sext_imm;
            end else begin
                reg_unknown2[rt] = unk_rs;
                reg_val2[rt]     = v_rs - sext_imm;
            end
        end
        3'b100: begin
            // LOAD: rt = DM[...] -> value unpredictable, mark unknown
            if (which == 1) reg_unknown1[rt] = 1'b1;
            else            reg_unknown2[rt] = 1'b1;
        end
        3'b101: begin
            // STORE: doesn't change registers
        end
        default: ;
    endcase
end endtask

//======================================================================
//  INSTRUCTION GENERATION
//======================================================================
task gen_dram_task(input integer dcnt);
    integer k;
    integer t;
    reg [15:0] inst_val1, inst_val2;
    reg [15:0] pc_sim1, pc_sim2;
    reg [15:0] word_val;
    reg [15:0] iv;

    // PC -> instruction index mapping
    //  >= 0 : random-pattern index
    //  -1   : not an instruction position
    //  -2   : prologue instruction
    integer inst_idx_map1 [0:16'h1FFF];
    integer inst_idx_map2 [0:16'h1FFF];
begin
    for (k = 0; k < 16'h2000; k = k + 1) begin
        inst1_mem[k] = 8'h00;
        inst2_mem[k] = 8'h00;
        inst_idx_map1[k] = -1;
        inst_idx_map2[k] = -1;
    end

    for (k = 16'h1000; k < 16'h3000; k = k + 1)
        gdata[k] = $random;

    pc_sim1 = 16'h0000;
    pc_sim2 = 16'h0000;

    init_shadow_regs();

    //---------------- Prologue: boost r1..r7 into safe range ----------------
    // Step 1: ADDI r_t, r0, +63       -> r_t = 63
    // Step 2: ADDI r_t, r_t, +63      -> r_t = 126  (in SAFE range)
    // Both cores get the same prologue.
    for (t = 1; t <= 7; t = t + 1) begin
        // ADDI: op=010 | rs=000 | rt=t | imm=0x3F (+63)
        iv = {3'b010, 3'd0, t[2:0], 7'h3F};

        // Core 1
        inst1_mem[pc_sim1]     = iv[7:0];
        inst1_mem[pc_sim1+1]   = iv[15:8];
        inst_idx_map1[pc_sim1] = -2;
        update_shadow(1, iv);
        pc_sim1 = pc_sim1 + 2;

        // Core 2
        inst2_mem[pc_sim2]     = iv[7:0];
        inst2_mem[pc_sim2+1]   = iv[15:8];
        inst_idx_map2[pc_sim2] = -2;
        update_shadow(2, iv);
        pc_sim2 = pc_sim2 + 2;
    end
    for (t = 1; t <= 7; t = t + 1) begin
        // ADDI: op=010 | rs=t | rt=t | imm=0x3F (+63)
        iv = {3'b010, t[2:0], t[2:0], 7'h3F};

        // Core 1
        inst1_mem[pc_sim1]     = iv[7:0];
        inst1_mem[pc_sim1+1]   = iv[15:8];
        inst_idx_map1[pc_sim1] = -2;
        update_shadow(1, iv);
        pc_sim1 = pc_sim1 + 2;

        // Core 2
        inst2_mem[pc_sim2]     = iv[7:0];
        inst2_mem[pc_sim2+1]   = iv[15:8];
        inst_idx_map2[pc_sim2] = -2;
        update_shadow(2, iv);
        pc_sim2 = pc_sim2 + 2;
    end

    //---------------- Generate random instructions ----------------
    // Total instructions per core = PAT_NUMBER (prologue + random)
    for (k = 0; k < `PAT_NUMBER - `PROLOGUE_CNT; k = k + 1) begin
        // Core 1
        inst_val1 = gen_one_inst(k, 1, pc_sim1);
        inst1_mem[pc_sim1]     = inst_val1[7:0];
        inst1_mem[pc_sim1+1]   = inst_val1[15:8];
        inst_idx_map1[pc_sim1] = k;
        pc_sim1 = advance_pc(inst_val1, pc_sim1);

        // Core 2
        inst_val2 = gen_one_inst(k, 2, pc_sim2);
        if (inst_val1[15:13] === 3'b101 && inst_val2[15:13] === 3'b101)
            inst_val2[15:13] = 3'b010;  // avoid store/store collision
        inst2_mem[pc_sim2]     = inst_val2[7:0];
        inst2_mem[pc_sim2+1]   = inst_val2[15:8];
        inst_idx_map2[pc_sim2] = k;
        pc_sim2 = advance_pc(inst_val2, pc_sim2);
    end

    //---------------- Write inst_1_dram_file ----------------
    inst_fp1 = $fopen("../00_TESTBED/DRAM/inst_1_dram_file.dat", "w");
    for (k = 0; k < 16'h2000; k = k + 2) begin
        $fwrite(inst_fp1, "@%04x\n", k);
        word_val = {inst1_mem[k+1], inst1_mem[k]};
        if (inst_idx_map1[k] >= 0) begin
            $fwrite(inst_fp1, "%02x %02x // [#%0d] %s\n",
                    inst1_mem[k], inst1_mem[k+1],
                    inst_idx_map1[k], describe_inst(word_val));
        end
        else if (inst_idx_map1[k] == -2) begin
            $fwrite(inst_fp1, "%02x %02x // [PROLOGUE] %s\n",
                    inst1_mem[k], inst1_mem[k+1],
                    describe_inst(word_val));
        end
        else begin
            $fwrite(inst_fp1, "%02x %02x //\n",
                    inst1_mem[k], inst1_mem[k+1]);
        end
    end
    $fclose(inst_fp1);

    //---------------- Write inst_2_dram_file ----------------
    inst_fp2 = $fopen("../00_TESTBED/DRAM/inst_2_dram_file.dat", "w");
    for (k = 0; k < 16'h2000; k = k + 2) begin
        $fwrite(inst_fp2, "@%04x\n", k);
        word_val = {inst2_mem[k+1], inst2_mem[k]};
        if (inst_idx_map2[k] >= 0) begin
            $fwrite(inst_fp2, "%02x %02x // [#%0d] %s\n",
                    inst2_mem[k], inst2_mem[k+1],
                    inst_idx_map2[k], describe_inst(word_val));
        end
        else if (inst_idx_map2[k] == -2) begin
            $fwrite(inst_fp2, "%02x %02x // [PROLOGUE] %s\n",
                    inst2_mem[k], inst2_mem[k+1],
                    describe_inst(word_val));
        end
        else begin
            $fwrite(inst_fp2, "%02x %02x //\n",
                    inst2_mem[k], inst2_mem[k+1]);
        end
    end
    $fclose(inst_fp2);

    //---------------- Write data_dram_file ----------------
    data_fp = $fopen("../00_TESTBED/DRAM/data_dram_file.dat", "w");
    for (k = 16'h1000; k < 16'h3000; k = k + 2) begin
        $fwrite(data_fp, "@%04x\n", k);
        word_val = {gdata[k+1], gdata[k]};
        $fwrite(data_fp, "%02x %02x // %0d\n",
                gdata[k], gdata[k+1], $signed(word_val));
    end
    $fclose(data_fp);
end endtask

function [8*80-1:0] describe_inst(input [15:0] inst);
    reg [2:0]  op, rs, rt, rd, func;
    reg [6:0]  imm7;
    reg [12:0] addr13;
    reg signed [15:0] sext_imm;
begin
    op     = inst[15:13];
    rs     = inst[12:10];
    rt     = inst[9:7];
    rd     = inst[6:4];
    func   = inst[3:1];
    imm7   = inst[6:0];
    addr13 = inst[12:0];
    sext_imm = {{9{imm7[6]}}, imm7};

    case (op)
        3'b000: begin
            case (func)
                3'b000: describe_inst = $sformatf("R_inst: ADD  %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b001: describe_inst = $sformatf("R_inst: SUB  %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b010: describe_inst = $sformatf("R_inst: AND  %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b011: describe_inst = $sformatf("R_inst: OR   %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b100: describe_inst = $sformatf("R_inst: NAND %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b101: describe_inst = $sformatf("R_inst: NOR  %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b110: describe_inst = $sformatf("R_inst: XOR  %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
                3'b111: describe_inst = $sformatf("R_inst: SLT  %16b rs=%0d, rt=%0d, rd=%0d",
                                                  inst, rs, rt, rd);
            endcase
        end
        3'b001: describe_inst = $sformatf("M_inst: MULT %16b rs=%0d, rt=%0d, rd=%0d, rl=%0d",
                                           inst, rs, rt, rd, inst[3:1]);
        3'b010: describe_inst = $sformatf("I_inst: ADDI %16b rs=%0d, rt=%0d, imm = %4d",
                                           inst, rs, rt, sext_imm);
        3'b011: describe_inst = $sformatf("I_inst: SUBI %16b rs=%0d, rt=%0d, imm = %4d",
                                           inst, rs, rt, sext_imm);
        3'b100: describe_inst = $sformatf("I_inst: LOAD %16b rs=%0d, rt=%0d, imm = %4d",
                                           inst, rs, rt, sext_imm);
        3'b101: describe_inst = $sformatf("I_inst: STORE %16b rs=%0d, rt=%0d, imm = %4d",
                                           inst, rs, rt, sext_imm);
        3'b110: describe_inst = $sformatf("I_inst: BEQ  %16b rs=%0d, rt=%0d, imm = %4d",
                                           inst, rs, rt, sext_imm);
        3'b111: describe_inst = $sformatf("J_inst: JUMP %16b addr = 0x%04x",
                                           inst, addr13);
        default: describe_inst = "UNKNOWN";
    endcase
end endfunction

// Pick a register that is NOT currently in the safe pool. Used for
// write destinations of instructions whose result we cannot predict
// (R-type, MULT) or whose result would escape the safe range (ADDI/SUBI
// where the destination is currently safe). This preserves the safe
// pool so LOAD/STORE always have a valid rs to choose.
function [2:0] pick_unsafe_dst(input integer which);
    integer n, pick, cnt;
    reg [2:0] result;
begin
    cnt = 0;
    for (n = 0; n < 8; n = n + 1)
        if (!is_safe_rs(which, n[2:0])) cnt = cnt + 1;

    if (cnt == 0) begin
        pick_unsafe_dst = $random & 3'h7;   // all safe -> fall back
    end else begin
        pick = $random % cnt;
        if (pick < 0) pick = -pick;
        cnt = 0;
        result = 3'd0;
        for (n = 0; n < 8; n = n + 1) begin
            if (!is_safe_rs(which, n[2:0])) begin
                if (cnt == pick) result = n[2:0];
                cnt = cnt + 1;
            end
        end
        pick_unsafe_dst = result;
    end
end endfunction

function [15:0] gen_one_inst(input integer ic_idx, input integer which, input [15:0] cur_pc);
    reg [2:0] op, rs, rt, rd, func, rl;
    reg [6:0] imm;
    reg [15:0] inst;
    integer pick;
    integer safe_cnt;
begin
    rs   = $random & 3'h7;
    rt   = $random & 3'h7;
    rd   = $random & 3'h7;
    rl   = $random & 3'h7;
    func = $random & 3'h7;

    safe_cnt = count_safe(which);

    // Opcode weighting (out of 8):
    //   R-type  1/8   (12.5%)
    //   MULT    1/8   (12.5%)
    //   ADDI    1/8   (12.5%)
    //   SUBI    1/8   (12.5%)
    //   LOAD    2/8   (25%)
    //   STORE   2/8   (25%)
    // -> memory instructions ~50% of the mix.
    pick = $random % 8;
    if (pick < 0) pick = -pick;
    case (pick)
        0: op = 3'b000;       // R-type
        1: op = 3'b001;       // MULT
        2: op = 3'b010;       // ADDI
        3: op = 3'b011;       // SUBI
        4,5: op = 3'b100;     // LOAD
        default: op = 3'b101; // STORE
    endcase

    // If no safe rs exists, we cannot legally emit LOAD/STORE.
    // Fall back to ADDI (to help grow the safe pool).
    if ((op == 3'b100 || op == 3'b101) && safe_cnt == 0) begin
        op = 3'b010;
    end

    case (op)
        3'b000: begin
            // R-type result is unpredictable -> write to an unsafe rd
            // to keep the safe pool intact.
            rd   = pick_unsafe_dst(which);
            inst = {op, rs, rt, rd, func, 1'b0};
        end

        3'b001: begin
            // MULT writes two registers -> both must be unsafe slots
            rd = pick_unsafe_dst(which);
            rl = pick_unsafe_dst(which);
            while (rl == rd) rl = $random & 3'h7;
            inst = {op, rs, rt, rd, rl, 1'b0};
        end

        3'b010, 3'b011: begin
            // ADDI / SUBI: imm is 7-bit signed. Force sign bit = 0 so
            // registers drift predictably. Use r0 (=0) or a safe rs so
            // the destination value stays controllable. Avoid clobbering
            // an already-safe rt with an unpredictable value.
            if (is_safe_rs(which, rt)) rt = pick_unsafe_dst(which);
            imm = $random & 7'h3F;
            inst = {op, rs, rt, imm};
        end

        3'b100, 3'b101: begin
            // LOAD / STORE: force rs to be a safe register
            rs  = pick_safe_rs(which);
            imm = $random & 7'h1F;    // 5-bit magnitude, sign bit = 0
            // For LOAD, rt becomes unknown -> also avoid clobbering safe rt
            if (op == 3'b100 && is_safe_rs(which, rt))
                rt = pick_unsafe_dst(which);
            inst = {op, rs, rt, imm};
        end

        default: inst = 16'h0000;
    endcase

    // Update shadow register model for this core
    update_shadow(which, inst);

    gen_one_inst = inst;
end endfunction

function [15:0] advance_pc(input [15:0] inst, input [15:0] cur_pc);
    reg [2:0] op, rs, rt;
    reg [6:0] imm;
    reg [12:0] addr;
    reg signed [15:0] sext_imm;
    reg [15:0] next_pc;
begin
    op       = inst[15:13];
    rs       = inst[12:10];
    rt       = inst[9:7];
    imm      = inst[6:0];
    addr     = inst[12:0];
    sext_imm = {{9{imm[6]}}, imm};

    next_pc = cur_pc + 2;

    case (op)
        3'b110: begin
            if (rs == rt)
                next_pc = cur_pc + 2 + sext_imm * 2;
        end
        3'b111: begin
            next_pc = {addr, 1'b0};
        end
    endcase

    if (next_pc >= 16'h2000)
        next_pc = 16'h0000;

    advance_pc = next_pc;
end endfunction

//======================================================================
//  PASS / FAIL
//======================================================================
task YOU_PASS_task; begin
    $display("========================================================");
    $display("              Congratulations! ALL PASS!                ");
    $display("  Total cycles = %0d                                    ", total_cycles);
    $display("  Clock period = %.1f ns                                ", `CYCLE_TIME);
    $display("  Total time   = %.1f ns                                ", total_cycles*`CYCLE_TIME);
    $display("========================================================");
end endtask

task f_ail_task;
    integer dump_i;
begin
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    $display("");
    $display("\033[1;31m================================================================\033[0m");
    $display("\033[1;31m||                                                            ||\033[0m");
    $display("\033[1;31m||           :(    F   A   I   L    :(                       ||\033[0m");
    $display("\033[1;31m||                                                            ||\033[0m");
    $display("\033[1;31m||     FFFFF   AAA   IIIII  L                                 ||\033[0m");
    $display("\033[1;31m||     F      A   A    I    L                                 ||\033[0m");
    $display("\033[1;31m||     FFF    AAAAA    I    L                                 ||\033[0m");
    $display("\033[1;31m||     F      A   A    I    L                                 ||\033[0m");
    $display("\033[1;31m||     F      A   A  IIIII  LLLLL                             ||\033[0m");
    $display("\033[1;31m||                                                            ||\033[0m");
    $display("\033[1;31m================================================================\033[0m");
    $display("\033[1;33m  Failed at:  IC = %0d   PC1 = 0x%4h   PC2 = 0x%4h\033[0m",
             ic, gpc1, gpc2);
    $display("\033[1;33m  Total cycles so far: %0d\033[0m", total_cycles);
    $display("\033[1;33m  Simulation time:     %0t\033[0m", $time);
    $display("");

    #100 $finish;
end
endtask

endmodule