`timescale 1ns/1ps

// PATTERN
`include "../00_TESTBED/PATTERN.v"
// DESIGN
`ifdef RTL
	`include "HT.v"
`elsif GATE
	`include "HT_SYN.v"
`endif


module TESTBED();

	wire clk, in_valid, out_mode, out_valid, out_code;
	wire [2:0] in_weight;

initial begin
 	`ifdef RTL
    	$fsdbDumpfile("HT_TOP.fsdb");
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		$fsdbDumpfile("HT_TOP_SYN.fsdb");
		$fsdbDumpvars(0,"+mda");
		$sdf_annotate("HT_SYN.sdf",I_HT); 
	`endif
end

HT I_HT 
(
	 // Input signals
    .clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
    .in_weight(in_weight), 
	.out_mode(out_mode),
    // Output signals
    .out_valid(out_valid), 
	.out_code(out_code)
);

PATTERN I_PATTERN
(
	// Output signals
    .clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
    .in_weight(in_weight), 
	.out_mode(out_mode),
    // Input signals
    .out_valid(out_valid), 
	.out_code(out_code)
);

endmodule
