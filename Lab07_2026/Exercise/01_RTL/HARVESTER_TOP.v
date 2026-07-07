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
`include "DESIGN_module.v"
`include "synchronizer/Handshake_syn.v"
`include "synchronizer/FIFO_syn.v"
`include "synchronizer/NDFF_syn.v"
`include "synchronizer/NDFF_BUS_syn.v"

module HARVESTER_TOP (
    input               clk1, 
    input               clk2, 
    input               clk3, 
    input               rst_n,
    input               in_mode_valid,
    input               in_valid,
    input               in_mode,
    input       [1:0]   in_bank,
    input       [5:0]   in_src_row,
    output reg          out_valid,
    output reg  [63:0]  out_data,

    output      [31:0]  ar_addr_clk2, 
    output              ar_valid_clk2, 
    output              ar_ready_clk2,
    output       [63:0] r_data_clk2,  
    // output       [1:0]  r_resp_clk2, 
    output              r_valid_clk2, 
    output              r_ready_clk2,

    output      [31:0]  ar_addr_clk3, 
    output              ar_valid_clk3, 
    output              ar_ready_clk3,
    output       [63:0] r_data_clk3,  
    // output       [1:0]  r_resp_clk3, 
    output              r_valid_clk3, 
    output              r_ready_clk3,

    output   [3:0]      dram_cmd_clk3,  // {CS_n, RAS_n, CAS_n, WE_n}
    output   [1:0]      dram_ba_clk3,
    output   [10:0]     dram_addr_clk3,
    output   [63:0]     dram_wdata_clk3,
    input   [63:0]     dram_rdata_clk3,
    input              dram_valid_clk3
);
// --------------------------------------------------------------------
//   SIGNAL DECLARATION
// --------------------------------------------------------------------

//Handshake for INPUT
wire sidle;
wire data_valid_clk1;
wire [8:0] data_clk1;

wire harvester_busy;
wire in_data_valid_clk2;
wire [8:0] in_data_clk2;

// Custom flags to use if needed
wire flag_handshake_to_clk1;
wire flag_clk1_to_handshake;

wire flag_handshake_to_clk2;
wire flag_clk2_to_handshake;

//OUTPUT FIFO
wire output_fifo_empty;
wire output_fifo_rinc;
wire [31:0] output_fifo_rdata; 

wire output_fifo_full;
wire output_data_valid_clk2;
wire [31:0] output_data_clk2;

wire flag_fifo_to_clk2;
wire flag_clk2_to_fifo;

wire flag_fifo_to_clk1;
wire flag_clk1_to_fifo;

//AXI AR R CHANELL
wire  		r_fifo_empty;
wire 		r_fifo_rinc;
wire [31:0] r_fifo_rdata;

wire 	    r_fifo_full;
wire  		r_out_valid;
wire [31:0] r_out_data;

wire  		ar_fifo_empty;
wire 		ar_fifo_rinc;
wire [31:0] ar_fifo_rdata;

wire 	    ar_fifo_full;
wire  		ar_out_valid;
wire [31:0] ar_out_data;
// You can use the the custom flag ports for your design
wire  		ar_flag_fifo_to_wclk,r_flag_fifo_to_rclk;
wire 		ar_flag_wclk_to_fifo,r_flag_rclk_to_fifo;
wire  		r_flag_fifo_to_wclk,ar_flag_fifo_to_rclk;
wire 		r_flag_wclk_to_fifo,ar_flag_rclk_to_fifo;

//PATTERN <=> INPUT/OUTPUT
CLK_1_MODULE u_input_output (
    .clk(clk1), 
    .rst_n(rst_n),

    .in_mode_valid(in_mode_valid),
    .in_mode(in_mode),

    .in_valid(in_valid),
    .in_bank(in_bank),
    .in_src_row(in_src_row),

    .out_idle (sidle),
    .handshake_sready (data_valid_clk1),
    .handshake_din (data_clk1),
    .flag_handshake_to_clk1(flag_handshake_to_clk1),
    .flag_clk1_to_handshake(flag_clk1_to_handshake),
	

	.fifo_empty (output_fifo_empty),
    .fifo_rdata (output_fifo_rdata),
    .fifo_rinc (output_fifo_rinc),
    .out_valid (out_valid),
    .out_data (out_data),
    .flag_fifo_to_clk1(flag_fifo_to_clk1),
	.flag_clk1_to_fifo(flag_clk1_to_fifo)
);



// INPUT <=> HARVESTER
Handshake_syn #(.WIDTH(9)) u_Handshake_syn (
    .sclk (clk1),
    .dclk (clk2),
    .rst_n (rst_n),
    .sready (data_valid_clk1),
    .din (data_clk1),
    .dbusy (harvester_busy),
    .sidle (sidle),
    .dvalid (in_data_valid_clk2),
    .dout (in_data_clk2),

    .flag_handshake_to_clk1(flag_handshake_to_clk1),
    .flag_clk1_to_handshake(flag_clk1_to_handshake),

    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake)
);
// OUTPUT <=> HARVESTER
FIFO_syn #(.WIDTH(32), .WORDS(64)) u_FIFO_syn_output (
    .wclk (clk2),
    .rclk (clk1),
    .rst_n (rst_n),
    .winc (output_data_valid_clk2),
    .wdata (output_data_clk2),
    .wfull (output_fifo_full),
    .rinc (output_fifo_rinc),
    .rdata (output_fifo_rdata),
    .rempty (output_fifo_empty),

    .flag_fifo_to_clkw(flag_fifo_to_clk2),
    .flag_clkw_to_fifo(flag_clk2_to_fifo),

    .flag_fifo_to_clkr(flag_fifo_to_clk1),
	.flag_clkr_to_fifo(flag_clk1_to_fifo)
);



//HARVESTER
CLK_2_MODULE u_HARVESTER (
    .clk (clk2),
    .rst_n (rst_n),

    //INPUT
    .busy (harvester_busy),
    .in_valid (in_data_valid_clk2),
    .in_data (in_data_clk2),
    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake),

    //OUTPUT
    .out_fifo_full (output_fifo_full),
    .out_valid (output_data_valid_clk2),
    .out_data (output_data_clk2),
    .flag_fifo_to_clk2(flag_fifo_to_clk2),
    .flag_clk2_to_fifo(flag_clk2_to_fifo),

     //AR
    .ar_fifo_full (ar_fifo_full),
    .ar_out_valid (ar_out_valid),
    .ar_out_data (ar_out_data),
    .ar_flag_fifo_to_wclk(ar_flag_fifo_to_wclk),
    .ar_flag_wclk_to_fifo(ar_flag_wclk_to_fifo),

     //R
    .r_fifo_empty (r_fifo_empty),
    .r_fifo_rdata (r_fifo_rdata),
    .r_fifo_rinc (r_fifo_rinc),
    .r_flag_fifo_to_rclk(r_flag_fifo_to_rclk),
	.r_flag_rclk_to_fifo(r_flag_rclk_to_fifo),

    //for pattern check
    .ar_addr(ar_addr_clk2),      
    .ar_valid(ar_valid_clk2),  
    .ar_ready(ar_ready_clk2),
    .r_data(r_data_clk2),        
    // .r_resp(r_resp_clk3),      
    .r_valid(r_valid_clk2),    
    .r_ready(r_ready_clk2)
);




// HARVESTER <=> AR 
FIFO_syn #(.WIDTH(32), .WORDS(64)) u_FIFO_syn_AR (
    .wclk (clk2),
    .rclk (clk3),
    .rst_n (rst_n),
    .winc (ar_out_valid),
    .wdata (ar_out_data),
    .wfull (ar_fifo_full),
    .rinc (ar_fifo_rinc),
    .rdata (ar_fifo_rdata),
    .rempty (ar_fifo_empty),

    .flag_fifo_to_clkw(ar_flag_fifo_to_wclk),
    .flag_clkw_to_fifo(ar_flag_wclk_to_fifo),

    .flag_fifo_to_clkr(ar_flag_fifo_to_rclk),
	.flag_clkr_to_fifo(ar_flag_rclk_to_fifo)
);
// R <=> HARVESTER 
FIFO_syn #(.WIDTH(32), .WORDS(64)) u_FIFO_syn_R (
    .wclk (clk3),
    .rclk (clk2),
    .rst_n (rst_n),
    .winc (r_out_valid),
    .wdata (r_out_data),
    .wfull (r_fifo_full),
    .rinc (r_fifo_rinc),
    .rdata (r_fifo_rdata),
    .rempty (r_fifo_empty),

    .flag_fifo_to_clkw(r_flag_fifo_to_wclk),
    .flag_clkw_to_fifo(r_flag_wclk_to_fifo),

    .flag_fifo_to_clkr(r_flag_fifo_to_rclk),
	.flag_clkr_to_fifo(r_flag_rclk_to_fifo)
);




// AR/R <=> DRAM_CTRL
CLK_3_MODULE u_DRAM_SYS (
    .clk(clk3),
    .rst_n(rst_n),
    
    .r_fifo_full(r_fifo_full),
    .r_out_valid(r_out_valid),
    .r_out_data(r_out_data),

	.ar_fifo_empty(ar_fifo_empty),
    .ar_fifo_rdata(ar_fifo_rdata),
    .ar_fifo_rinc(ar_fifo_rinc),

    .ar_flag_fifo_to_rclk(ar_flag_fifo_to_rclk),
    .ar_flag_rclk_to_fifo(ar_flag_rclk_to_fifo),

	.r_flag_fifo_to_wclk(r_flag_fifo_to_wclk),
    .r_flag_wclk_to_fifo(r_flag_wclk_to_fifo),

    .ar_addr(ar_addr_clk3),      
    .ar_valid(ar_valid_clk3),  
    .ar_ready(ar_ready_clk3),
    .r_data(r_data_clk3),        
    // .r_resp(r_resp_clk3),      
    .r_valid(r_valid_clk3),    
    .r_ready(r_ready_clk3),

    .dram_cmd(dram_cmd_clk3),    
    .dram_ba(dram_ba_clk3),    
    .dram_addr(dram_addr_clk3),
    .dram_wdata(dram_wdata_clk3),
    .dram_rdata(dram_rdata_clk3), 
    .dram_valid(dram_valid_clk3)
);
endmodule
