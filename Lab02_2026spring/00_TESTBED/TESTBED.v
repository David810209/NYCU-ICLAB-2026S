`timescale 1ns/10ps

`include "PATTERN.v"
`ifdef RTL
  `include "ISP.v"
`endif
`ifdef GATE
  `include "ISP_SYN.v"
`endif
	  		  	
module TESTBED;

wire         clk, rst_n, in_valid;
wire [11:0]  in;
wire         param_valid;
wire [11:0]  param_gain;
wire         out_valid;
wire [11:0]  r_out;
wire [11:0]  g_out;
wire [11:0]  b_out;


initial begin
  `ifdef RTL
    $fsdbDumpfile("ISP.fsdb");
	  $fsdbDumpvars(0,"+mda");
  `endif
  `ifdef GATE
    $sdf_annotate("ISP_SYN.sdf", u_ISP);
    // $fsdbDumpfile("ISP_SYN.fsdb");
	  // $fsdbDumpvars(0,"+mda"); 
  `endif
end

ISP u_ISP(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in(in),
    .param_valid(param_valid),
    .param_gain(param_gain),
    .out_valid(out_valid),
    .r_out(r_out),
    .g_out(g_out),
    .b_out(b_out)
    );
	
PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
	  .in(in),
    .param_valid(param_valid),
    .param_gain(param_gain),
    .out_valid(out_valid),
    .r_out(r_out),
    .g_out(g_out),
    .b_out(b_out)
    );
  
endmodule
