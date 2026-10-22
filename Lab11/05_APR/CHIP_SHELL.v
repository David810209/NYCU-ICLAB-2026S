// ##############################################################
//   You can modify by your own
//   You can modify by your own
//   You can modify by your own
// ##############################################################

module CHIP(
    //Input Port
    clk,
    rst_n,

    in_data_valid,
    in_data,
    cmd_valid,
    cmd,

    //Output Port
    out_valid,
    r_out,
    g_out,
    b_out
);

input             clk;
input             rst_n;
		  
input             in_data_valid;
input     [11:0]  in_data;
input             cmd_valid;
input     [5:0]   cmd;
		  
output            out_valid;
output    [7:0]   r_out;
output    [7:0]   g_out;
output    [7:0]   b_out;

//==================================================================
// reg & wire
//==================================================================
wire             C_clk;
wire             C_rst_n;

wire             C_in_data_valid;
wire    [11:0]   C_in_data;
wire             C_cmd_valid;
wire    [5:0]    C_cmd;
		  
wire             C_out_valid;
wire    [7:0]    C_r_out;
wire    [7:0]    C_g_out;
wire    [7:0]    C_b_out;

//==================================================================
// CORE
//==================================================================
ISP CORE(
	// input signals
	.clk(C_clk),
	.rst_n(C_rst_n),

    .in_data_valid(C_in_data_valid),
    .in_data(C_in_data),
    .cmd_valid(C_cmd_valid),
    .cmd(C_cmd),
    .out_valid(C_out_valid),

    .r_out(C_r_out),
    .g_out(C_g_out),
    .b_out(C_b_out)
);

//==================================================================
// INPUT PAD: XMD
// Syntax: XMD PAD_NAME ( .O(CORE_PORT_NAME), .I(CHIP_PORT_NAME), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//     Ex: XMD    I_CLK ( .O(C_clk),          .I(clk),            .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//==================================================================
// You need to finish this part

XMD    I_CLK              ( .O(C_clk),              .I(clk),              .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_RST_N            ( .O(C_rst_n),            .I(rst_n),            .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_IN_DATA_VALID    ( .O(C_in_data_valid),    .I(in_data_valid),    .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_0        ( .O(C_in_data[0]),       .I(in_data[0]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_1        ( .O(C_in_data[1]),       .I(in_data[1]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_2        ( .O(C_in_data[2]),       .I(in_data[2]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_3        ( .O(C_in_data[3]),       .I(in_data[3]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_4        ( .O(C_in_data[4]),       .I(in_data[4]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_5        ( .O(C_in_data[5]),       .I(in_data[5]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_6        ( .O(C_in_data[6]),       .I(in_data[6]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_7        ( .O(C_in_data[7]),       .I(in_data[7]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_8        ( .O(C_in_data[8]),       .I(in_data[8]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_9        ( .O(C_in_data[9]),       .I(in_data[9]),       .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_10       ( .O(C_in_data[10]),      .I(in_data[10]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_IN_DATA_11       ( .O(C_in_data[11]),      .I(in_data[11]),      .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_CMD_VALID        ( .O(C_cmd_valid),        .I(cmd_valid),        .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CMD_0            ( .O(C_cmd[0]),           .I(cmd[0]),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CMD_1            ( .O(C_cmd[1]),           .I(cmd[1]),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CMD_2            ( .O(C_cmd[2]),           .I(cmd[2]),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CMD_3            ( .O(C_cmd[3]),           .I(cmd[3]),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CMD_4            ( .O(C_cmd[4]),           .I(cmd[4]),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CMD_5            ( .O(C_cmd[5]),           .I(cmd[5]),           .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//==================================================================
// OUTPUT PAD: YA2GSD
// Syntax: YA2GSD PAD_NAME (.I(CORE_PIN_NAME), .O(PAD_PIN_NAME), .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//     Ex: YA2GSD  O_VALID (.I(C_out_valid),   .O(out_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//==================================================================
// You need to finish this part

YA2GSD    O_OUT_VALID    ( .I(C_out_valid),    .O(out_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));

YA2GSD    O_R_OUT_0      ( .I(C_r_out[0]),     .O(r_out[0]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_1      ( .I(C_r_out[1]),     .O(r_out[1]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_2      ( .I(C_r_out[2]),     .O(r_out[2]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_3      ( .I(C_r_out[3]),     .O(r_out[3]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_4      ( .I(C_r_out[4]),     .O(r_out[4]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_5      ( .I(C_r_out[5]),     .O(r_out[5]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_6      ( .I(C_r_out[6]),     .O(r_out[6]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_R_OUT_7      ( .I(C_r_out[7]),     .O(r_out[7]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));

YA2GSD    O_G_OUT_0      ( .I(C_g_out[0]),     .O(g_out[0]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_1      ( .I(C_g_out[1]),     .O(g_out[1]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_2      ( .I(C_g_out[2]),     .O(g_out[2]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_3      ( .I(C_g_out[3]),     .O(g_out[3]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_4      ( .I(C_g_out[4]),     .O(g_out[4]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_5      ( .I(C_g_out[5]),     .O(g_out[5]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_6      ( .I(C_g_out[6]),     .O(g_out[6]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_G_OUT_7      ( .I(C_g_out[7]),     .O(g_out[7]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));

YA2GSD    O_B_OUT_0      ( .I(C_b_out[0]),     .O(b_out[0]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_1      ( .I(C_b_out[1]),     .O(b_out[1]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_2      ( .I(C_b_out[2]),     .O(b_out[2]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_3      ( .I(C_b_out[3]),     .O(b_out[3]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_4      ( .I(C_b_out[4]),     .O(b_out[4]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_5      ( .I(C_b_out[5]),     .O(b_out[5]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_6      ( .I(C_b_out[6]),     .O(b_out[6]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
YA2GSD    O_B_OUT_7      ( .I(C_b_out[7]),     .O(b_out[7]),     .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b1), .SR(1'b0));
//==================================================================
// I/O power 3.3V pads: VCC3IOD/GNDIOD 
// Syntax: VCC3IOD/GNDIOD PAD_NAME ();
//    Ex1: VCC3IOD        VDDP0 ();
//    Ex2: GNDIOD         GNDP0 ();
//==================================================================
// You need to finish this part

VCC3IOD     VDDP0 ();
GNDIOD      GNDP0 ();
VCC3IOD     VDDP1 ();
GNDIOD      GNDP1 ();
VCC3IOD     VDDP2 ();
GNDIOD      GNDP2 ();
VCC3IOD     VDDP3 ();
GNDIOD      GNDP3 ();
//==================================================================
// Core power 1.8V pads: VCCKD/GNDKD
// Syntax: VCCKD/GNDKD PAD_NAME ();
//    Ex1: VCCKD       VDDC0 ();
//    Ex2: GNDKD       GNDC0 ();
//==================================================================
// You need to finish this part
VCCKD VDDC0 ();
GNDKD GNDC0 ();

VCCKD VDDC1 ();
GNDKD GNDC1 ();

VCCKD VDDC2 ();
GNDKD GNDC2 ();

VCCKD VDDC3 ();
GNDKD GNDC3 ();

endmodule

