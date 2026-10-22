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
    `include "DRAM_CTRL.v"
    `include "HARVESTER.v"
`endif
`ifdef GATE
    `include "DRAM_CTRL_SYN.v"
    `include "HARVESTER_SYN.v"
`endif

`include "../00_TESTBED/pseudo_DRAM.vp"

module TESTBED;

wire clk, rst_n;

// AXI4-Lite Signals
wire [31:0] aw_addr;
wire        aw_valid;
wire        aw_ready;
wire [63:0] w_data;
wire        w_valid;
wire        w_ready;
wire [1:0]  b_resp;
wire        b_valid;
wire        b_ready;
wire [31:0] ar_addr;
wire        ar_valid;
wire        ar_ready;
wire [63:0] r_data;
wire [1:0]  r_resp;
wire        r_valid;
wire        r_ready;
// DRAM Interface
//wire dram_cs_n, dram_ras_n, dram_cas_n, dram_we_n;
wire [3:0]  dram_cmd;
wire [1:0]  dram_ba;
wire [10:0] dram_addr;
wire [63:0] dram_wdata;
wire [63:0] dram_rdata;
wire        dram_valid;
// Pattern to DMA Interface
wire        out_valid;
wire [63:0] out_data;

wire         in_mode_valid;
wire         in_valid;
wire [63:0]  in_data;
wire [1:0]   in_bank;
wire [5:0]   in_src_row;
wire [5:0]   in_dst_row;
wire [1:0]   in_mode;

initial begin
    `ifdef RTL
        // $fsdbDumpfile("HARVESTER.fsdb");
        // $fsdbDumpvars(0,"+mda");
    `endif
    `ifdef GATE
        $sdf_annotate("HARVESTER_SYN.sdf", u_HARVESTER);
        $sdf_annotate("DRAM_CTRL_SYN.sdf", u_DRAM_CTRL);
        // $fsdbDumpfile("HARVESTER_SYN.fsdb");
        // $fsdbDumpvars(0,"+mda"); 
    `endif
end
//1. Pattern Generator 
PATTERN u_PATTERN (
    .clk(clk),              
    .rst_n(rst_n),

    .aw_addr(aw_addr),      
    .aw_valid(aw_valid),  
    .aw_ready(aw_ready),
    .w_data(w_data),        
    .w_valid(w_valid),    
    .w_ready(w_ready),
    .b_resp(b_resp),        
    .b_valid(b_valid),    
    .b_ready(b_ready),
    .ar_addr(ar_addr),      
    .ar_valid(ar_valid),  
    .ar_ready(ar_ready),
    .r_data(r_data),        
    .r_resp(r_resp),      
    .r_valid(r_valid),    
    .r_ready(r_ready),

    .in_valid(in_valid),
    .in_mode_valid(in_mode_valid),
    .in_mode(in_mode),
    .in_bank(in_bank),
    .in_src_row(in_src_row),
    .in_dst_row(in_dst_row),
    .in_data(in_data),

    .out_valid(out_valid),
    .out_data(out_data)
);
// 2. Your Design (You need to implement this file: DRAM_CTRL.v 、 HARVESTER.v)
//    AXI Master
HARVESTER u_HARVESTER (
    .clk(clk), 
    .rst_n(rst_n),

    .in_valid(in_valid),
    .in_mode_valid(in_mode_valid),
    .in_mode(in_mode),
    .in_bank(in_bank),
    .in_src_row(in_src_row),
    .in_dst_row(in_dst_row),
    .in_data(in_data),

    .out_valid(out_valid), 
    .out_data(out_data),

    .aw_addr(aw_addr), 
    .aw_valid(aw_valid), 
    .aw_ready(aw_ready),
    .w_data(w_data),   
    .w_valid(w_valid),   
    .w_ready(w_ready),
    .b_resp(b_resp),   
    .b_valid(b_valid),   
    .b_ready(b_ready),
    .ar_addr(ar_addr), 
    .ar_valid(ar_valid), 
    .ar_ready(ar_ready),
    .r_data(r_data),   
    .r_resp(r_resp),     
    .r_valid(r_valid), 
    .r_ready(r_ready)
);
//    AXI Slave
DRAM_CTRL u_DRAM_CTRL (
    .clk(clk),              
    .rst_n(rst_n),
    .aw_addr(aw_addr),      
    .aw_valid(aw_valid),  
    .aw_ready(aw_ready),
    .w_data(w_data),        
    .w_valid(w_valid),    
    .w_ready(w_ready),
    .b_resp(b_resp),        
    .b_valid(b_valid),    
    .b_ready(b_ready),
    .ar_addr(ar_addr),      
    .ar_valid(ar_valid),  
    .ar_ready(ar_ready),
    .r_data(r_data),        
    .r_resp(r_resp),      
    .r_valid(r_valid),    
    .r_ready(r_ready),

    .dram_cmd(dram_cmd),    
    .dram_ba(dram_ba),    
    .dram_addr(dram_addr),
    .dram_wdata(dram_wdata),
    .dram_rdata(dram_rdata), 
    .dram_valid(dram_valid)
);
// 3. Pseudo DRAM Model 
pseudo_DRAM u_DRAM (
    .clk(clk),
    .rst_n(rst_n),
    .dram_cmd(dram_cmd),//{dram_cs_n, dram_ras_n, dram_cas_n, dram_we_n}
    .dram_ba(dram_ba),
    .dram_addr(dram_addr),
    .dram_wdata(dram_wdata),
    .dram_rdata(dram_rdata),
    .dram_valid(dram_valid)
);
endmodule
