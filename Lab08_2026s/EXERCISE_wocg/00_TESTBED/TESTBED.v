//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2025 ICLAB FALL Course
//   Lab08       : Testbench and Pattern
//   Author      : Ying-Yu (Inyi) Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`timescale 1ns/10ps

// PATTERN
`include "PATTERN.v"

// DESIGN
`ifdef RTL
	`include "LAB8_DESIGN_wocg.v"
`elsif GATE
	`include "LAB8_DESIGN_SYN.v"
`endif

module TESTBED();
	wire clk, rst_n, in_valid;
	// wire cg_en;
	wire [7:0] in_data;

	wire out_valid;
	wire [11:0] out_data;	

initial begin
  	`ifdef RTL
    	$fsdbDumpfile("LAB8_DESIGN.fsdb");
		$fsdbDumpvars(0,"+mda");
    	$fsdbDumpvars();
  	`endif
  	`ifdef GATE
    	$sdf_annotate("LAB8_DESIGN_SYN.sdf", u_LAB8_DESIGN);
    	$fsdbDumpfile("LAB8_DESIGN_SYN.fsdb");
    	$fsdbDumpvars();    
  	`endif
end

LAB8_DESIGN u_LAB8_DESIGN
(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_data(in_data),

	// Output signals
	.out_valid(out_valid),
	.out_data(out_data)
);


PATTERN u_PATTERN
(
	// Output signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.in_data(in_data),

	// Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);

endmodule
