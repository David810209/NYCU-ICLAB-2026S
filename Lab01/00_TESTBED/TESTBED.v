`include "../00_TESTBED/PATTERN.v"
`ifdef RTL
  `include "DRCA.v"
`endif
`ifdef GATE
  `include "DRCA_SYN.v"
`endif

module TESTBED ();

initial begin
  `ifdef RTL
    $fsdbDumpfile("DRCA.fsdb");
	$fsdbDumpvars(0,"+all");
    $fsdbDumpvars();
  `endif
  `ifdef GATE
    $sdf_annotate("DRCA_SYN.sdf", u_DRCA);
    $fsdbDumpfile("DRCA_SYN.fsdb");
	$fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();    
  `endif
end

wire [3:0]  drc_sel;
wire [18:0] shape0 ;
wire [18:0] shape1 ;
wire [18:0] shape2 ;
wire [18:0] shape3 ;
wire [18:0] shape4 ;
wire [18:0] shape5 ;
wire [18:0] shape6 ;
wire [18:0] shape7 ;
wire [18:0] shape8 ;
wire [18:0] shape9 ;
wire [18:0] shape10 ;
wire [18:0] shape11 ;
wire [18:0] shape12 ;
wire [18:0] shape13 ;
wire [18:0] shape14 ;
wire [18:0] shape15 ;
wire [4:0]  drc_out;

PATTERN u_PATTERN (
    .drc_sel(drc_sel),
    .shape0 (shape0 ),
    .shape1 (shape1 ),
    .shape2 (shape2 ),
    .shape3 (shape3 ),
    .shape4 (shape4 ),
    .shape5 (shape5 ),
    .shape6 (shape6 ),
    .shape7 (shape7 ),
    .shape8 (shape8 ),
    .shape9 (shape9 ),
    .shape10(shape10),
    .shape11(shape11),
    .shape12(shape12),
    .shape13(shape13),
    .shape14(shape14),
    .shape15(shape15),
    .drc_out(drc_out)
);

DRCA u_DRCA (
    .drc_sel(drc_sel),
    .shape0 (shape0 ),
    .shape1 (shape1 ),
    .shape2 (shape2 ),
    .shape3 (shape3 ),
    .shape4 (shape4 ),
    .shape5 (shape5 ),
    .shape6 (shape6 ),
    .shape7 (shape7 ),
    .shape8 (shape8 ),
    .shape9 (shape9 ),
    .shape10(shape10),
    .shape11(shape11),
    .shape12(shape12),
    .shape13(shape13),
    .shape14(shape14),
    .shape15(shape15),
    .drc_out(drc_out)
);
endmodule