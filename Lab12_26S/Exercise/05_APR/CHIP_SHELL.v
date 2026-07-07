// ##############################################################
//   You can modify by your own
//   You can modify by your own
//   You can modify by your own
// ##############################################################

module CHIP(
	clk,
	rst_n,
	i_valid,
    i_iter,
    i_mode,
    i_data,
    i_weight,
    o_valid,
    o_data
);

input       clk, rst_n, i_valid;
input       [7:0] i_data;
input       [2:0] i_iter;
input       [1:0] i_mode;
input       [3:0] i_weight;
output      o_valid;
output      [7:0] o_data;

//==================================================================
// reg & wire
//==================================================================
wire        C_clk, C_rst_n, C_i_valid;
wire [7:0]  C_i_data;
wire [2:0]  C_i_iter;
wire [1:0]  C_i_mode;
wire [3:0]  C_i_weight;

wire        C_o_valid;
wire [7:0]  C_o_data;

//==================================================================
// CORE
//==================================================================
DM CORE(
	// input signals
    .clk(C_clk),
    .rst_n(C_rst_n),
    .i_valid(C_i_valid),
	.i_iter(C_i_iter),
	.i_mode(C_i_mode),
	.i_data(C_i_data),
	.i_weight(C_i_weight),
	
    // output signals
    .o_valid(C_o_valid),
    .o_data(C_o_data)
);
//==================================================================
// INPUT PAD
// Syntax: XMD PAD_NAME ( .O(CORE_PORT_NAME), .I(CHIP_PORT_NAME), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//     Ex: XMD    I_CLK ( .O(C_clk),          .I(clk),            .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//==================================================================
// You need to finish this part

XMD    I_CLK          ( .O(C_clk),          .I(clk),          .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_RST_N        ( .O(C_rst_n),        .I(rst_n),        .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_VALID        ( .O(C_i_valid),      .I(i_valid),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_ITER_0       ( .O(C_i_iter[0]),    .I(i_iter[0]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_ITER_1       ( .O(C_i_iter[1]),    .I(i_iter[1]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_ITER_2       ( .O(C_i_iter[2]),    .I(i_iter[2]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_MODE_0       ( .O(C_i_mode[0]),    .I(i_mode[0]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_MODE_1       ( .O(C_i_mode[1]),    .I(i_mode[1]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_DATA_0       ( .O(C_i_data[0]),    .I(i_data[0]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_1       ( .O(C_i_data[1]),    .I(i_data[1]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_2       ( .O(C_i_data[2]),    .I(i_data[2]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_3       ( .O(C_i_data[3]),    .I(i_data[3]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_4       ( .O(C_i_data[4]),    .I(i_data[4]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_5       ( .O(C_i_data[5]),    .I(i_data[5]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_6       ( .O(C_i_data[6]),    .I(i_data[6]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_DATA_7       ( .O(C_i_data[7]),    .I(i_data[7]),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_WEIGHT_0     ( .O(C_i_weight[0]),  .I(i_weight[0]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_WEIGHT_1     ( .O(C_i_weight[1]),  .I(i_weight[1]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_WEIGHT_2     ( .O(C_i_weight[2]),  .I(i_weight[2]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_WEIGHT_3     ( .O(C_i_weight[3]),  .I(i_weight[3]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));

//==================================================================
// OUTPUT PAD
// Syntax: YA2GSD PAD_NAME (.I(CORE_PIN_NAME), .O(PAD_PIN_NAME), .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//     Ex: YA2GSD  O_VALID (.I(C_out_valid),   .O(out_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//==================================================================
// You need to finish this part

YA2GSD    O_VALID     ( .I(C_o_valid),    .O(o_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));

YA2GSD    O_DATA_0    ( .I(C_o_data[0]),  .O(o_data[0]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_1    ( .I(C_o_data[1]),  .O(o_data[1]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_2    ( .I(C_o_data[2]),  .O(o_data[2]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_3    ( .I(C_o_data[3]),  .O(o_data[3]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_4    ( .I(C_o_data[4]),  .O(o_data[4]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_5    ( .I(C_o_data[5]),  .O(o_data[5]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_6    ( .I(C_o_data[6]),  .O(o_data[6]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD    O_DATA_7    ( .I(C_o_data[7]),  .O(o_data[7]),  .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));

//==================================================================
// I/O power 3.3V pads x20 (DVDD + DGND)
// Syntax: VCC3IOD/GNDIOD PAD_NAME ();
//    Ex1: VCC3IOD        VDDP0 ();
//    Ex2: GNDIOD         GNDP0 ();
//==================================================================
// You need to finish this part

VCC3IOD     VDDP0  ();
GNDIOD      GNDP0  ();
VCC3IOD     VDDP1  ();
GNDIOD      GNDP1  ();
VCC3IOD     VDDP2  ();
GNDIOD      GNDP2  ();
VCC3IOD     VDDP3  ();
GNDIOD      GNDP3  ();
VCC3IOD     VDDP4  ();
GNDIOD      GNDP4  ();
VCC3IOD     VDDP5  ();
GNDIOD      GNDP5  ();
VCC3IOD     VDDP6  ();
GNDIOD      GNDP6  ();
VCC3IOD     VDDP7  ();
GNDIOD      GNDP7  ();
VCC3IOD     VDDP8  ();
GNDIOD      GNDP8  ();
VCC3IOD     VDDP9  ();
GNDIOD      GNDP9  ();
VCC3IOD     VDDP10 ();
GNDIOD      GNDP10 ();
VCC3IOD     VDDP11 ();
GNDIOD      GNDP11 ();
VCC3IOD     VDDP12 ();
GNDIOD      GNDP12 ();
VCC3IOD     VDDP13 ();
GNDIOD      GNDP13 ();
VCC3IOD     VDDP14 ();
GNDIOD      GNDP14 ();
VCC3IOD     VDDP15 ();
GNDIOD      GNDP15 ();
VCC3IOD     VDDP16 ();
GNDIOD      GNDP16 ();
VCC3IOD     VDDP17 ();
GNDIOD      GNDP17 ();
VCC3IOD     VDDP18 ();
GNDIOD      GNDP18 ();
VCC3IOD     VDDP19 ();
GNDIOD      GNDP19 ();

//==================================================================
// Core power 1.8V pads x24 (VDD + GND)
// Syntax: VCCKD/GNDKD PAD_NAME ();
//    Ex1: VCCKD       VDDC0 ();
//    Ex2: GNDKD       GNDC0 ();
//==================================================================
// You need to finish this part

VCCKD      VDDC0  ();
GNDKD      GNDC0  ();
VCCKD      VDDC1  ();
GNDKD      GNDC1  ();
VCCKD      VDDC2  ();
GNDKD      GNDC2  ();
VCCKD      VDDC3  ();
GNDKD      GNDC3  ();
VCCKD      VDDC4  ();
GNDKD      GNDC4  ();
VCCKD      VDDC5  ();
GNDKD      GNDC5  ();
VCCKD      VDDC6  ();
GNDKD      GNDC6  ();
VCCKD      VDDC7  ();
GNDKD      GNDC7  ();
VCCKD      VDDC8  ();
GNDKD      GNDC8  ();
VCCKD      VDDC9  ();
GNDKD      GNDC9  ();
VCCKD      VDDC10 ();
GNDKD      GNDC10 ();
VCCKD      VDDC11 ();
GNDKD      GNDC11 ();
VCCKD      VDDC12 ();
GNDKD      GNDC12 ();
VCCKD      VDDC13 ();
GNDKD      GNDC13 ();
VCCKD      VDDC14 ();
GNDKD      GNDC14 ();
VCCKD      VDDC15 ();
GNDKD      GNDC15 ();
VCCKD      VDDC16 ();
GNDKD      GNDC16 ();
VCCKD      VDDC17 ();
GNDKD      GNDC17 ();
VCCKD      VDDC18 ();
GNDKD      GNDC18 ();
VCCKD      VDDC19 ();
GNDKD      GNDC19 ();
VCCKD      VDDC20 ();
GNDKD      GNDC20 ();
VCCKD      VDDC21 ();
GNDKD      GNDC21 ();
VCCKD      VDDC22 ();
GNDKD      GNDC22 ();
VCCKD      VDDC23 ();
GNDKD      GNDC23 ();
endmodule

