`timescale 1ns/10ps

`include "PATTERN.vp"

`ifdef RTL
    `include "ISP.v"
`elsif GATE
    `include "ISP_SYN.v"
`elsif POST
    `include "CHIP.v"
`endif
	  		  	
module TESTBED;

wire         clk, rst_n, in_data_valid, cmd_valid;
wire [11:0]  in_data;
wire [5:0]   cmd;
wire         out_valid;
wire [7:0]  r_out;
wire [7:0]  g_out;
wire [7:0]  b_out;


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
    `ifdef POST
        $sdf_annotate("CHIP.sdf", u_CHIP);
        //$fsdbDumpfile("CHIP.fsdb");
        //$fsdbDumpvars();    
    `endif
end

`ifdef RTL
    ISP u_ISP(
        // input signals
        .clk(clk),
        .rst_n(rst_n),

        .in_data_valid(in_data_valid),
        .in_data(in_data),

        .cmd_valid(cmd_valid),
        .cmd(cmd),

        // output signals
        .out_valid(out_valid),
        .r_out(r_out),
        .g_out(g_out),
        .b_out(b_out)
    );
`elsif GATE
    ISP u_ISP(
        .clk(clk),
        .rst_n(rst_n),
        .in_data_valid(in_data_valid),
        .in_data(in_data),
        .cmd_valid(cmd_valid),
        .cmd(cmd),
        .out_valid(out_valid),
        .r_out(r_out),
        .g_out(g_out),
        .b_out(b_out)
        );
`elsif POST
    CHIP u_CHIP(
        .clk(clk),
        .rst_n(rst_n),
        .in_data_valid(in_data_valid),
        .in_data(in_data),
        .cmd_valid(cmd_valid),
        .cmd(cmd),
        .out_valid(out_valid),
        .r_out(r_out),
        .g_out(g_out),
        .b_out(b_out)
        );
`endif
	
PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .in_data_valid(in_data_valid),
    .in_data(in_data),
    .cmd_valid(cmd_valid),
    .cmd(cmd),
    .out_valid(out_valid),
    .r_out(r_out),
    .g_out(g_out),
    .b_out(b_out)
    );
  
endmodule
