//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2026 Spring
//   Lab05 Exercise		: Diffusion Model (DM)
//   Author     		: Chih-Yu Hu (hedyhe.ee14@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2026-02)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
    `include "DM.v"
`elsif GATE
    `include "DM_SYN.v"
`elsif POST
    `include "CHIP.v"
`endif

	  		  	
module TESTBED;

wire                clk;
wire                rst_n;
wire                i_valid;

wire         [7:0]  i_data;
wire    	 [2:0]  i_iter;
wire    	 [1:0]  i_mode;
wire	     [3:0]  i_weight;

wire                o_valid;
wire signed  [7:0]  o_value;

initial begin
	`ifdef RTL
		$fsdbDumpfile("DM.fsdb");
		$fsdbDumpvars(0,"+mda");
		$fsdbDumpvars();
	`endif
	`ifdef GATE
		$sdf_annotate("DM_SYN.sdf", u_DM);
		//$fsdbDumpfile("DM_SYN.fsdb");
		//$fsdbDumpvars();    
	`endif
	`ifdef POST
		$sdf_annotate("CHIP.sdf", u_CHIP);
		$fsdbDumpfile("CHIP.fsdb");
		$fsdbDumpvars();    
	`endif
end

`ifdef RTL
	DM u_DM(
		// input signals
    	.clk(clk),
    	.rst_n(rst_n),
    	.i_valid(i_valid),
		.i_iter(i_iter),
		.i_mode(i_mode),
    	.i_data(i_data),
		.i_weight(i_weight),

    	// output signals
    	.o_valid(o_valid),
    	.o_data(o_value)
	);
`elsif GATE
	DM u_DM(
		// input signals
    	.clk(clk),
    	.rst_n(rst_n),
    	.i_valid(i_valid),
    	.i_iter(i_iter),
		.i_mode(i_mode),
    	.i_data(i_data),
		.i_weight(i_weight),

    	// output signals
    	.o_valid(o_valid),
    	.o_data(o_value)
	);
`elsif POST
	CHIP u_CHIP(
		// input signals
    	.clk(clk),
    	.rst_n(rst_n),
    	.i_valid(i_valid),
    	.i_iter(i_iter),
		.i_mode(i_mode),
    	.i_data(i_data),
		.i_weight(i_weight),

    	// output signals
    	.o_valid(o_valid),
    	.o_data(o_value)
	);
`endif

PATTERN u_PATTERN(
	// input signals
	.clk(clk),
	.rst_n(rst_n),
	.i_valid(i_valid),
	.i_iter(i_iter),
	.i_mode(i_mode),
    .i_data(i_data),
	.i_weight(i_weight),

	// output signals
	.o_valid(o_valid),
	.o_data(o_value)
);
 
endmodule
