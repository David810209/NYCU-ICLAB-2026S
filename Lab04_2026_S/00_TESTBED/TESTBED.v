`timescale 1ns/10ps

`include "PATTERN.v"

`ifdef RTL
  `include "CDNA.v"
`endif
`ifdef GATE
  `include "CDNA_SYN.v"
`endif

	  		  	
module TESTBED;

wire        clk;
wire        rst_n;
wire        instruction_in_valid;
wire        image_in_valid;
wire        weight_in_valid;
wire [31:0] in_data;

wire        out_valid;
wire [31:0] out_data;


initial begin
  `ifdef RTL
    $fsdbDumpfile("CDNA.fsdb");
	  $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("CDNA_SYN.sdf", u_CDNA);
    $fsdbDumpfile("CDNA_SYN.fsdb");
    $fsdbDumpvars();    
  `endif
end

`ifdef RTL
CDNA u_CDNA(
    .clk(clk),
    .rst_n(rst_n),
    .instruction_in_valid(instruction_in_valid),
    .image_in_valid(image_in_valid),
    .weight_in_valid(weight_in_valid),
    .in_data(in_data),
    
    .out_valid(out_valid),
    .out_data(out_data)
    );
`endif

`ifdef GATE
CDNA u_CDNA(
    .clk(clk),
    .rst_n(rst_n),
    .instruction_in_valid(instruction_in_valid),
    .image_in_valid(image_in_valid),
    .weight_in_valid(weight_in_valid),
    .in_data(in_data),
    
    .out_valid(out_valid),
    .out_data(out_data)
    );
`endif

PATTERN u_PATTERN(
    .clk(clk),
    .rst_n(rst_n),
    .instruction_in_valid(instruction_in_valid),
    .image_in_valid(image_in_valid),
    .weight_in_valid(weight_in_valid),
    .in_data(in_data),
    
    .out_valid(out_valid),
    .out_data(out_data)
    );
  
 
endmodule
