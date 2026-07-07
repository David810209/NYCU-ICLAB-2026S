/**************************************************************************/
// Copyright (c) 2026, SI2 Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: Feb 21, 2026
// AUTHOR: Kuan-Chen Chen, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2026 Spring IC Lab / Exersise Lab03 /
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
`timescale 1ns/10ps

`include "../00_TESTBED/PATTERN.vp"
`ifdef RTL
    `include "HARVESTER_TOP.v"
`endif
`ifdef GATE
    `include "HARVESTER_TOP_SYN.v"
`endif

`include "../00_TESTBED/pseudo_DRAM.vp"

module TESTBED;

wire rst_n;
wire clk1,clk2,clk3;
// AXI4-Lite Signals
wire [31:0] ar_addr_clk2;
wire        ar_valid_clk2;
wire        ar_ready_clk2;
wire [63:0] r_data_clk2;
// wire [1:0]  r_resp_clk2;
wire        r_valid_clk2;
wire        r_ready_clk2;

wire [31:0] ar_addr_clk3;
wire        ar_valid_clk3;
wire        ar_ready_clk3;
wire [63:0] r_data_clk3;
// wire [1:0]  r_resp_clk3;
wire        r_valid_clk3;
wire        r_ready_clk3;
// DRAM Interface
//wire dram_cs_n, dram_ras_n, dram_cas_n, dram_we_n;
wire [3:0]  dram_cmd_clk3;
wire [1:0]  dram_ba_clk3;
wire [10:0] dram_addr_clk3;
wire [63:0] dram_wdata_clk3;
wire [63:0] dram_rdata_clk3;
wire        dram_valid_clk3;
// Pattern to DMA Interface
wire        out_valid;
wire [63:0] out_data;

wire         in_mode_valid;
wire         in_valid;
wire [1:0]   in_bank;
wire [5:0]   in_src_row;
wire         in_mode;

initial begin
    `ifdef RTL
        // $fsdbDumpfile("HARVESTER_TOP.fsdb");
        // $fsdbDumpvars(0,"+mda");
    `endif
    `ifdef GATE
        $sdf_annotate("HARVESTER_TOP_SYN_pt.sdf", u_HARVESTER_TOP);
        // $fsdbDumpfile("HARVESTER_TOP_SYN.fsdb");
        // $fsdbDumpvars(0,"+mda"); 
    `endif
end
//1. Pattern Generator 
PATTERN u_PATTERN (
    .clk1(clk1),              
    .clk2(clk2),              
    .clk3(clk3),              
    .rst_n(rst_n),

    .ar_addr_clk2(ar_addr_clk2), 
    .ar_valid_clk2(ar_valid_clk2), 
    .ar_ready_clk2(ar_ready_clk2),
    .r_data_clk2(r_data_clk2),   
    // .r_resp_clk2(r_resp_clk2),     
    .r_valid_clk2(r_valid_clk2), 
    .r_ready_clk2(r_ready_clk2),

    .ar_addr_clk3(ar_addr_clk3), 
    .ar_valid_clk3(ar_valid_clk3), 
    .ar_ready_clk3(ar_ready_clk3),
    .r_data_clk3(r_data_clk3),   
    // .r_resp_clk3(r_resp_clk3),     
    .r_valid_clk3(r_valid_clk3), 
    .r_ready_clk3(r_ready_clk3),

    .in_valid(in_valid),
    .in_mode_valid(in_mode_valid),
    .in_mode(in_mode),
    .in_bank(in_bank),
    .in_src_row(in_src_row),

    .out_valid(out_valid),
    .out_data(out_data)
);
// 2. Your Design (You need to implement this file: DRAM_CTRL.v 、 HARVESTER.v)
HARVESTER_TOP u_HARVESTER_TOP (
    .clk1(clk1), 
    .clk2(clk2), 
    .clk3(clk3), 
    .rst_n(rst_n),

    .in_valid(in_valid),
    .in_mode_valid(in_mode_valid),
    .in_mode(in_mode),
    .in_bank(in_bank),
    .in_src_row(in_src_row),

    .out_valid(out_valid), 
    .out_data(out_data),

    .ar_addr_clk2(ar_addr_clk2), 
    .ar_valid_clk2(ar_valid_clk2), 
    .ar_ready_clk2(ar_ready_clk2),
    .r_data_clk2(r_data_clk2),   
    // .r_resp_clk2(r_resp_clk2),     
    .r_valid_clk2(r_valid_clk2), 
    .r_ready_clk2(r_ready_clk2),

    .ar_addr_clk3(ar_addr_clk3), 
    .ar_valid_clk3(ar_valid_clk3), 
    .ar_ready_clk3(ar_ready_clk3),
    .r_data_clk3(r_data_clk3),   
    // .r_resp_clk3(r_resp_clk3),     
    .r_valid_clk3(r_valid_clk3), 
    .r_ready_clk3(r_ready_clk3),

    .dram_cmd_clk3(dram_cmd_clk3),//{dram_cs_n, dram_ras_n, dram_cas_n, dram_we_n}
    .dram_ba_clk3(dram_ba_clk3),
    .dram_addr_clk3(dram_addr_clk3),
    .dram_wdata_clk3(dram_wdata_clk3),
    .dram_rdata_clk3(dram_rdata_clk3),
    .dram_valid_clk3(dram_valid_clk3)
);
// 3. Pseudo DRAM Model 
pseudo_DRAM u_DRAM (
    .clk(clk3),//clk3
    .rst_n(rst_n),
    .dram_cmd(dram_cmd_clk3),//{dram_cs_n, dram_ras_n, dram_cas_n, dram_we_n}
    .dram_ba(dram_ba_clk3),
    .dram_addr(dram_addr_clk3),
    .dram_wdata(dram_wdata_clk3),
    .dram_rdata(dram_rdata_clk3),
    .dram_valid(dram_valid_clk3)
);
endmodule
