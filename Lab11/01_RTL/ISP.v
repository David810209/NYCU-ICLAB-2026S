module ISP(
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

//==============================
//   INPUT/OUTPUT DECLARATION
//==============================
input clk;
input rst_n;
input in_data_valid;
input [11:0] in_data;
input cmd_valid;
input [5:0] cmd;

output reg out_valid;
output reg [7:0] r_out;
output reg [7:0] g_out;
output reg [7:0] b_out;

//==============================
//  Your Design 
//==============================

//==============================
//   Variable Declaration
//==============================
// sram
reg        mem0_web_r;
reg [11:0] mem0_waddr_r;
wire [11:0] mem0_addr_sel;
reg  [11:0] mem0_din_r;
wire [11:0] mem0_dout;
reg [11:0] mem0_dout_r;

reg        mem1_web_r;
reg [11:0] mem1_waddr_r;
wire [11:0] mem1_addr_sel;
reg  [11:0] mem1_din_r;
wire [11:0] mem1_dout;
reg [11:0] mem1_dout_r;

reg        mem2_web_r;
reg [11:0] mem2_waddr_r;
wire [11:0] mem2_addr_sel;
reg  [11:0] mem2_din_r;
wire [11:0] mem2_dout;
reg [11:0] mem2_dout_r;

reg        mem3_web_r;
reg [11:0] mem3_waddr_r;
wire [11:0] mem3_addr_sel;
reg  [11:0] mem3_din_r;
wire [11:0] mem3_dout;
reg [11:0] mem3_dout_r;

wire [1:0] sram_in_sel;
reg [14:0] sram_input_cnt;
// stage 0 register input
reg [11:0] in_reg;
reg in_valid_reg;
reg [5:0] cmd_reg;
reg [5:0] cmd_r;
reg cmd_valid_reg;
reg cmd_valid_r;
// stage 1 BLC
reg [3:0] x_idx, y_idx;
localparam R_BLC = 64, Gr_BLC = 48, Gb_BLC = 52, B_BLC = 72;
reg [6:0] blc_sel_val;
reg [11:0] blc_value [9:0];
reg blc_valid [11:0];
wire signed [12:0] blc_tmp;
wire [1:0] blc_sel;
reg [1:0] blc_sel_reg;
// stage 2 LSC
reg [1:0] lsc_x_cnt, lsc_y_cnt;
reg [1:0] lsc_x_cnt_r, lsc_y_cnt_r;
reg [3:0] x_2_idx, y_2_idx;
reg [11:0] g00, g01, g10, g11;
// stage 3 mult 12
wire [20:0] result_1, result_2;
reg [20:0] result_1_reg, result_2_reg;
reg [1:0] lsc_y_cnt_reg [3:0];
// stage 4 mult 3
wire       [29:0] result_3;
reg        [11:0] result_3_reg;
wire       [13:0] result_3_tmp;
// stage 5 result
wire        [23:0] LSC_final_result_tmp;
wire        [13:0] LSC_final_result_tmp2;
wire               LSC_result_overflow;
reg [11:0] LSC_final_result;
// DPC layer
reg [11:0] dpc_mem [255:187];
reg [3:0] dpc_x_idx, dpc_y_idx;
reg [8:0] dpc_input_idx;
wire dpc_start;
wire [11:0] h [3:0];
wire [11:0] v [3:0];
wire [11:0] c;
reg [11:0] h_sel [3:0];
reg [11:0] v_sel [3:0];
reg [11:0] d1_sel [3:0];
reg [11:0] d2_sel [3:0];

wire [11:0] partial_5x5_grid [4:0] [4:0];
wire [2:0] d10_x, d10_y, d11_x, d11_y, d12_x, d12_y, d13_x, d13_y;
wire [2:0] d20_x, d20_y, d21_x, d21_y, d22_x, d22_y, d23_x, d23_y;
wire [11:0] h_median, v_median, d1_median, d2_median;
wire [13:0] h_score, v_score, d1_score, d2_score;
reg [11:0] h_median_r, v_median_r, d1_median_r, d2_median_r;
reg [13:0] h_score_r, v_score_r, d1_score_r, d2_score_r;

wire [13:0] min_score1, min_score2;
wire [1:0] min_score1_type, min_score2_type;
wire [11:0] min_score1_median, min_score2_median, min_score_median;
reg [11:0] min_score_median_r;
reg [13:0] min_score1_r, min_score2_r;
reg [1:0] min_score1_type_r, min_score2_type_r;
reg [11:0] min_score1_median_r, min_score2_median_r;
wire hv_cmp, d1d2_cmp, min_score_sel;
wire [11:0] p_minus_target;
wire [11:0] dpc_result;
reg [11:0] dpc_result_reg;
reg dpc_valid[8:0];
reg [11:0] c_reg [7:0];
// bilinear layer
reg [3:0] bi_x_idx, bi_y_idx;
wire bilinear_calc_start;
reg biLinear_start;
reg [8:0] bilinear_idx;

reg [11:0] bilinear_mem [34:0];
wire [11:0] H0 ;
wire [11:0] H1 ;
wire [11:0] V0 ;
wire [11:0] V1 ;
wire [11:0] D00 ;
wire [11:0] D01 ;
wire [11:0] D10 ;
wire [11:0] D11 ;
wire [11:0] Center ;

reg [11:0] H0_sel, H1_sel;
reg [11:0] V0_sel, V1_sel;
reg [11:0] Center_sel;
reg [11:0] D00_sel, D01_sel;
reg [11:0] D10_sel, D11_sel;
wire X_is_zero, Y_is_zero, X_is_end, Y_is_end;
// NEW: sram read control
reg  [7:0]  sram_read_cnt;
wire        sram_read_active;
wire [1:0]  sram_read_sel;
wire [11:0] sram_read_addr;
wire [11:0] sram_read_dout;
wire [3:0] sram_addr_sel;
reg [11:0] r_bilinear, g_bilinear, b_bilinear;
wire [12:0] h_sum, v_sum;
wire [13:0] hv_sum, d1d2_sum;
wire [11:0] h_sum_divide2, v_sum_divide2, d1d2_sum_divide4, hv_sum_divide4;

reg [11:0] r_bilinear_reg, g_bilinear_reg, b_bilinear_reg;
reg [13:0] rgb_add_reg;
reg bilinear_reg;
reg bilinear_reg2;
// CCM layer
reg out_reg;
reg [7:0] r_out_reg, g_out_reg, b_out_reg;
//==============================
//   Design
//==============================

// sram

assign sram_in_sel = sram_input_cnt[13:12];
// assign sram_input_done = sram_input_cnt[14];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sram_input_cnt <= 0;
    end
    else if(dpc_valid[8])begin
        sram_input_cnt <= sram_input_cnt + 1;
    end
end

// ---------------- mem0 ----------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem0_din_r <= 0;
        mem0_web_r <= 1;
    end
    else if(dpc_valid[8] && sram_in_sel == 2'd0)begin
        mem0_din_r <= dpc_result_reg;
        mem0_web_r <= 0;
    end
    else begin
        mem0_din_r <= 0;
        mem0_web_r <= 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem0_waddr_r <= 0;
    end
    else if(mem0_web_r == 0)begin
        mem0_waddr_r <= mem0_waddr_r + 1;
    end
end
assign mem0_addr_sel = sram_read_active && sram_read_sel == 2'd0 ? sram_read_addr : mem0_waddr_r;
// ---------------- mem1 ----------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem1_din_r <= 0;
        mem1_web_r <= 1;
    end
    else if(dpc_valid[8] && sram_in_sel == 2'd1)begin
        mem1_din_r <= dpc_result_reg;
        mem1_web_r <= 0;
    end
    else begin
        mem1_din_r <= 0;
        mem1_web_r <= 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem1_waddr_r <= 0;
    end
    else if(mem1_web_r == 0)begin
        mem1_waddr_r <= mem1_waddr_r + 1;
    end
end
assign mem1_addr_sel = sram_read_active && sram_read_sel == 2'd1 ? sram_read_addr : mem1_waddr_r;

// ---------------- mem2 ----------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem2_din_r <= 0;
        mem2_web_r <= 1;
    end
    else if(dpc_valid[8] && sram_in_sel == 2'd2)begin
        mem2_din_r <= dpc_result_reg;
        mem2_web_r <= 0;
    end
    else begin
        mem2_din_r <= 0;
        mem2_web_r <= 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem2_waddr_r <= 0;
    end
    else if(mem2_web_r == 0)begin
        mem2_waddr_r <= mem2_waddr_r + 1;
    end
end
assign mem2_addr_sel = sram_read_active && sram_read_sel == 2'd2 ? sram_read_addr : mem2_waddr_r;

// ---------------- mem3 ----------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem3_din_r <= 0;
        mem3_web_r <= 1;
    end
    else if(dpc_valid[8] && sram_in_sel == 2'd3)begin
        mem3_din_r <= dpc_result_reg;
        mem3_web_r <= 0;
    end
    else begin
        mem3_din_r <= 0;
        mem3_web_r <= 1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem3_waddr_r <= 0;
    end
    else if(mem3_web_r == 0)begin
        mem3_waddr_r <= mem3_waddr_r + 1;
    end
end
assign mem3_addr_sel = sram_read_active && sram_read_sel == 2'd3 ? sram_read_addr : mem3_waddr_r;

SRAM_4096_12 sram0(.clk(clk), .addr(mem0_addr_sel), .data_i(mem0_din_r), .WEB(mem0_web_r), .data_o(mem0_dout));
SRAM_4096_12 sram1(.clk(clk), .addr(mem1_addr_sel), .data_i(mem1_din_r), .WEB(mem1_web_r), .data_o(mem1_dout));
SRAM_4096_12 sram2(.clk(clk), .addr(mem2_addr_sel), .data_i(mem2_din_r), .WEB(mem2_web_r), .data_o(mem2_dout));
SRAM_4096_12 sram3(.clk(clk), .addr(mem3_addr_sel), .data_i(mem3_din_r), .WEB(mem3_web_r), .data_o(mem3_dout));
always @(posedge clk) begin
        mem0_dout_r <= mem0_dout;
        mem1_dout_r <= mem1_dout;
        mem2_dout_r <= mem2_dout;
        mem3_dout_r <= mem3_dout;
end

// ---------------- sram read control (NEW) ----------------

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) sram_read_cnt <= 0;
    else if(sram_read_active) sram_read_cnt <= sram_read_cnt + 1;
    else sram_read_cnt <= 0;
end

assign sram_read_active = (cmd_valid_r || cmd_valid_reg);
assign sram_read_sel    = cmd_valid_reg ? cmd_reg[5:4] : cmd_r[5:4];
assign sram_addr_sel = cmd_valid_reg ? cmd_reg[3:0] : cmd_r[3:0];
assign sram_read_addr   = {sram_addr_sel, sram_read_cnt};

assign sram_read_dout   = (sram_read_sel == 2'd0) ? mem0_dout_r :
                          (sram_read_sel == 2'd1) ? mem1_dout_r :
                          (sram_read_sel == 2'd2) ? mem2_dout_r :
                                                    mem3_dout_r ;


// stage 0 register input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_reg <= 0;
        in_valid_reg <= 0;
        cmd_reg <= 0;
        cmd_valid_reg <= 0;
    end
    else  begin
        in_reg <= in_data;
        in_valid_reg <= in_data_valid;
        cmd_reg <= cmd;
        cmd_valid_reg <= cmd_valid;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cmd_r <= 0;
    end
    else if(cmd_valid_reg) begin
        cmd_r <= cmd_reg;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cmd_valid_r <= 0;
    end
    else if(cmd_valid_reg) begin
        cmd_valid_r <= 1;
    end
    else if(sram_read_cnt == 255) begin
        cmd_valid_r <= 0;
    end
end

// stage 1 BLC

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_idx <= 0;
        y_idx <= 0;
    end
    else if(in_valid_reg) begin
        x_idx <= x_idx + 1;
        y_idx <= x_idx == 15 ? y_idx + 1 : y_idx;
    end
    else begin
        x_idx <= x_idx;
        y_idx <= y_idx;
    end
end

assign blc_sel = {x_idx[0], y_idx[0]};
always @(*) begin
    case(blc_sel) 
        2'b00: blc_sel_val = R_BLC;
        2'b01: blc_sel_val = Gb_BLC;
        2'b10: blc_sel_val = Gr_BLC;
        2'b11: blc_sel_val = B_BLC;
        default: blc_sel_val = 0;
    endcase
end

assign blc_tmp = {1'b0, in_reg} - {1'b0, blc_sel_val};

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        blc_sel_reg <= 0;
    end
    else begin
        blc_sel_reg <= blc_sel;
    end
end

// stage 2 LSC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_2_idx <= 0;
        y_2_idx <= 0;
    end
    else if(blc_valid[0]) begin
        x_2_idx <= x_2_idx + 1;
        y_2_idx <= x_2_idx == 15 ? y_2_idx + 1 : y_2_idx;
    end
    else begin
        x_2_idx <= x_2_idx;
        y_2_idx <= y_2_idx;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        blc_valid[11:0] <= '{default: 0};
        blc_value[9:0] <= '{default: 0};
        dpc_valid[8:0] <= '{default: 0};
        c_reg [7:0] <= '{default: 0};
        lsc_y_cnt_reg [2:0] <= '{default: 0};
    end
    else begin
        blc_valid[11:1] <= blc_valid[10:0];
        blc_valid[0] <= in_valid_reg;

        blc_value[9:1] <= blc_value[8:0];
        blc_value[0] <= blc_tmp[12] ? 0 : blc_tmp[11:0];

        dpc_valid[0] <= dpc_start;
        dpc_valid[8:1] <= dpc_valid[7:0];

        c_reg[7:1] <= c_reg[6:0];
        c_reg[0] <= c;

        lsc_y_cnt_reg[3:1] <= lsc_y_cnt_reg[2:0];
        lsc_y_cnt_reg[0] <= lsc_y_cnt_r;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) lsc_x_cnt <= 0;
    else if(blc_valid[0]) begin
        if(x_2_idx == 14) lsc_x_cnt <= 2;
        else lsc_x_cnt <= lsc_x_cnt == 2 ? 0 : lsc_x_cnt + 1;
    end
    else lsc_x_cnt <= lsc_x_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  lsc_y_cnt <= 0;
    else if(blc_valid[0]) begin
        if(x_2_idx == 15)begin
            if(y_2_idx == 14) lsc_y_cnt <= 2;
            else lsc_y_cnt <= lsc_y_cnt == 2 ? 0 : lsc_y_cnt + 1;
        end
        else lsc_y_cnt <= lsc_y_cnt;
    end
    else begin
        lsc_y_cnt <= lsc_y_cnt;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  begin
        lsc_x_cnt_r <= 0;
        lsc_y_cnt_r <= 0;
    end
    else begin
        lsc_x_cnt_r <= lsc_x_cnt;
        lsc_y_cnt_r <= lsc_y_cnt;
    end
end
function [11:0] lsc_init_value;
    input [1:0] color;
    input [2:0] x0;
    input [2:0] y0;
    reg [2:0] rf_tmp, cf_tmp;
    reg [1:0] rf, cf;
    reg [2:0] sel;
begin
    rf_tmp = (y0 <= 3'd2) ? y0 : (3'd5 - y0);
    cf_tmp = (x0 <= 3'd2) ? x0 : (3'd5 - x0);
    rf = rf_tmp[1:0];
    cf = cf_tmp[1:0];

    case ({rf, cf})
        4'b00_00:            sel = 3'd0;
        4'b00_01, 4'b01_00:  sel = 3'd1;
        4'b00_10, 4'b10_00:  sel = 3'd2;
        4'b01_01:            sel = 3'd3;
        4'b01_10, 4'b10_01:  sel = 3'd4;
        4'b10_10:            sel = 3'd5;
        default:             sel = 3'd0;
    endcase

    case (color)
        2'b00: case (sel)
            3'd0: lsc_init_value = 12'h640; 3'd1: lsc_init_value = 12'h5DC;
            3'd2: lsc_init_value = 12'h5AA; 3'd3: lsc_init_value = 12'h546;
            3'd4: lsc_init_value = 12'h4E2; default: lsc_init_value = 12'h44C;
        endcase
        2'b11: case (sel)
            3'd0: lsc_init_value = 12'h6A4; 3'd1: lsc_init_value = 12'h62C;
            3'd2: lsc_init_value = 12'h5DC; 3'd3: lsc_init_value = 12'h58C;
            3'd4: lsc_init_value = 12'h528; default: lsc_init_value = 12'h47E;
        endcase
        default: case (sel)
            3'd0: lsc_init_value = 12'h5DC; 3'd1: lsc_init_value = 12'h58C;
            3'd2: lsc_init_value = 12'h550; 3'd3: lsc_init_value = 12'h500;
            3'd4: lsc_init_value = 12'h4B0; default: lsc_init_value = 12'h438;
        endcase
    endcase
end
endfunction
wire [1:0] ch_sel;
assign ch_sel = (blc_sel_reg == 2'b00) ? 2'd0 :
                (blc_sel_reg == 2'b10) ? 2'd1 :
                (blc_sel_reg == 2'b01) ? 2'd2 : 2'd3;

wire [2:0] x0 = (x_2_idx >= 12) ? 3'd4 :
                (x_2_idx >= 9)  ? 3'd3 :
                (x_2_idx >= 6)  ? 3'd2 :
                (x_2_idx >= 3)  ? 3'd1 : 3'd0;

wire [2:0] y0 = (y_2_idx >= 12) ? 3'd4 :
                (y_2_idx >= 9)  ? 3'd3 :
                (y_2_idx >= 6)  ? 3'd2 :
                (y_2_idx >= 3)  ? 3'd1 : 3'd0;

wire [2:0] x0p1 = x0 + 3'd1;
wire [2:0] y0p1 = y0 + 3'd1;

always @(posedge clk) begin
    g00 <= lsc_init_value(ch_sel, x0,   y0  );
    g01 <= lsc_init_value(ch_sel, x0p1, y0  );
    g10 <= lsc_init_value(ch_sel, x0,   y0p1);
    g11 <= lsc_init_value(ch_sel, x0p1, y0p1);
end

// stage 3 mult 12
biLinear_1d_4stage biLinear_1d_1 (
    .clk(clk),
    .rst_n(rst_n),
    .a(g00),
    .dx_sel(lsc_x_cnt_r),
    .b(g01),
    .result(result_1)
);
biLinear_1d_4stage biLinear_1d_2 (
    .clk(clk),
    .rst_n(rst_n),
    .a(g10),
    .dx_sel(lsc_x_cnt_r),
    .b(g11),
    .result(result_2)
);
always @(posedge clk) begin
        result_1_reg <= result_1;
        result_2_reg <= result_2;
end

// stage 4 mult 3
biLinear_1d_4stage#(
    .DATA_W(21)
) biLinear_1d_3 (
    .clk(clk),
    .rst_n(rst_n),
    .a(result_1_reg),
    .dx_sel(lsc_y_cnt_reg[3]),
    .b(result_2_reg),
    .result(result_3)
);

assign result_3_tmp = (result_3 >> 16) + result_3[15];
always @(posedge clk) begin
        result_3_reg <= result_3_tmp[11:0];
end

// stage 5 result
mult_12bit mult_12bit_1 (
    .clk(clk),
    .a(blc_value[9]),
    .b(result_3_reg),
    .result(LSC_final_result_tmp)
);
assign LSC_final_result_tmp2 = (LSC_final_result_tmp >>> 10) + LSC_final_result_tmp[9];
assign LSC_result_overflow = |LSC_final_result_tmp2[13:12];
always @(posedge clk) begin
        LSC_final_result <= LSC_result_overflow ? 12'hFFF : LSC_final_result_tmp2[11:0];
end

// DPC layer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_input_idx <= 0;
    end
    else if(blc_valid[11]) begin
        dpc_input_idx <= dpc_input_idx == 290 ? 35 : dpc_input_idx + 1;
    end
    else if(dpc_start) begin
        dpc_input_idx <= dpc_input_idx + 1;
    end
    else begin
       dpc_input_idx <= 0;
    end
end

assign dpc_start = dpc_input_idx >= 35 && dpc_input_idx <= 290;
assign bilinear_calc_start = (biLinear_start && bilinear_idx >= 18);
always @(posedge clk) begin
        dpc_mem[255] <= LSC_final_result;
        dpc_mem[254:187] <= dpc_mem[255:188];
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_x_idx <= 0;
        dpc_y_idx <= 0;
    end
    else if(dpc_start) begin
        dpc_x_idx <= dpc_x_idx + 1;
        dpc_y_idx <= dpc_x_idx == 15 ? dpc_y_idx + 1 : dpc_y_idx;
    end
    else begin
        dpc_x_idx <= dpc_x_idx;
        dpc_y_idx <= dpc_y_idx;
    end
end

assign h[0] = dpc_mem[219];     
assign h[1] = dpc_mem[220]; 
assign h[2] = dpc_mem[222]; 
assign h[3] = dpc_mem[223];   

assign v[0] = dpc_mem[189];
assign v[1] = dpc_mem[205];
assign v[2] = dpc_mem[237];
assign v[3] = dpc_mem[253];   

assign c = dpc_mem[221];

assign partial_5x5_grid[0][4:0] = dpc_mem[191:187];
assign partial_5x5_grid[1][4:0] = dpc_mem[207:203];
assign partial_5x5_grid[2][4:0] = dpc_mem[223:219];
assign partial_5x5_grid[3][4:0] = dpc_mem[239:235];
assign partial_5x5_grid[4][4:0] = dpc_mem[255:251];
assign d10_x = dpc_x_idx == 0 ? 4 : dpc_x_idx == 1 ? 2 : 0;
assign d10_y = dpc_y_idx == 0 ? 4 : dpc_y_idx == 1 ? 2 : 0;
assign d11_x = dpc_x_idx == 0 ? 3 : 1;
assign d11_y = dpc_y_idx == 0 ? 3 : 1;
assign d12_x = dpc_x_idx == 15 ? 1 : 3;
assign d12_y = dpc_y_idx == 15 ? 1 : 3;
assign d13_x = dpc_x_idx == 14 ? 2 : dpc_x_idx == 15 ? 0 : 4;
assign d13_y = dpc_y_idx == 14 ? 2 : dpc_y_idx == 15 ? 0 : 4;
assign d20_x = d13_x;
assign d20_y = d10_y;
assign d21_x = d12_x;
assign d21_y = d11_y;
assign d22_x = d11_x;
assign d22_y = d12_y;
assign d23_x = d10_x;
assign d23_y = d13_y;
always @(posedge clk) begin
        h_sel[0] <= dpc_x_idx == 0  ? h[3] :
                        dpc_x_idx == 1  ? c    : h[0];
        h_sel[1] <= dpc_x_idx == 0  ? h[2] : h[1];
        h_sel[2] <= dpc_x_idx == 15 ? h[1] : h[2];
        h_sel[3] <= dpc_x_idx == 15 ? h[0] :
                        dpc_x_idx == 14 ? c    : h[3];
        v_sel[0] <= dpc_y_idx == 0  ? v[3] :
                        dpc_y_idx == 1  ? c    : v[0];
        v_sel[1] <= dpc_y_idx == 0  ? v[2] : v[1];
        v_sel[2] <= dpc_y_idx == 15 ? v[1] : v[2];
        v_sel[3] <= dpc_y_idx == 15 ? v[0] :
                        dpc_y_idx == 14 ? c    : v[3];
        d1_sel[0] <= partial_5x5_grid[d10_y][d10_x];
        d1_sel[1] <= partial_5x5_grid[d11_y][d11_x];
        d1_sel[2] <= partial_5x5_grid[d12_y][d12_x];
        d1_sel[3] <= partial_5x5_grid[d13_y][d13_x];
        d2_sel[0] <= partial_5x5_grid[d20_y][d20_x];
        d2_sel[1] <= partial_5x5_grid[d21_y][d21_x];
        d2_sel[2] <= partial_5x5_grid[d22_y][d22_x];
        d2_sel[3] <= partial_5x5_grid[d23_y][d23_x];
end

median_score median_score_h (
    .clk(clk),
    .rst_n(rst_n),
    .in_0(h_sel[0]), .in_1(h_sel[1]), .in_2(h_sel[2]), .in_3(h_sel[3]),
    .median(h_median),
    .score(h_score)
);
median_score median_score_v (
    .clk(clk),
    .rst_n(rst_n),
    .in_0(v_sel[0]), .in_1(v_sel[1]), .in_2(v_sel[2]), .in_3(v_sel[3]),
    .median(v_median),
    .score(v_score)
);
median_score median_score_d1 (
    .clk(clk),
    .rst_n(rst_n),
    .in_0(d1_sel[0]), .in_1(d1_sel[1]), .in_2(d1_sel[2]), .in_3(d1_sel[3]),
    .median(d1_median),
    .score(d1_score)
);
median_score median_score_d2 (
    .clk(clk),
    .rst_n(rst_n),
    .in_0(d2_sel[0]), .in_1(d2_sel[1]), .in_2(d2_sel[2]), .in_3(d2_sel[3]),
    .median(d2_median),
    .score(d2_score)
);

assign hv_cmp = h_score_r <= v_score_r;
assign d1d2_cmp = d1_score_r <= d2_score_r;
assign min_score1 = hv_cmp? h_score_r : v_score_r;
assign min_score1_type = hv_cmp ? 3 : 2;
assign min_score1_median = hv_cmp ? h_median_r : v_median_r;

assign min_score2 = d1d2_cmp ? d1_score_r : d2_score_r;
assign min_score2_type = d1d2_cmp ? 1 : 0;
assign min_score2_median = d1d2_cmp ? d1_median_r : d2_median_r;

assign min_score_sel = (min_score1_r < min_score2_r) || (min_score1_r == min_score2_r && min_score1_type_r > min_score2_type_r);
assign min_score_median = min_score_sel ? min_score1_median_r : min_score2_median_r;

assign p_minus_target = c_reg[7] > min_score_median_r ? c_reg[7] - min_score_median_r : min_score_median_r - c_reg[7];

assign dpc_result = p_minus_target > 12'h140 ? min_score_median_r : c_reg[7];

always @(posedge clk) begin
        dpc_result_reg <= dpc_result;
        h_median_r <= h_median;
        v_median_r <= v_median;
        d1_median_r <= d1_median;
        d2_median_r <= d2_median;
        h_score_r <= h_score;
        v_score_r <= v_score;
        d1_score_r <= d1_score;
        d2_score_r <= d2_score;
        min_score1_r <= min_score1;
        min_score2_r <= min_score2;
        min_score1_type_r <= min_score1_type;
        min_score2_type_r <= min_score2_type;
        min_score1_median_r <= min_score1_median;
        min_score2_median_r <= min_score2_median;
        min_score_median_r <= min_score_median;
end

// bilinear layer (sram-read mode)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        biLinear_start <= 0;
    end
    else if(sram_read_active && sram_read_cnt == 1) begin
        biLinear_start <= 1;
    end
    else if(bilinear_idx == 9'd273) begin
       biLinear_start <= 0;
    end
    else begin
        biLinear_start <= biLinear_start;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bilinear_idx <= 0;
    end
    else if(biLinear_start) begin
        bilinear_idx <= bilinear_idx + 1;
    end
    else begin
       bilinear_idx <= 0;
    end
end
always @(posedge clk) begin
        bilinear_mem[34] <= sram_read_dout;
        bilinear_mem[33:0] <= bilinear_mem[34:1];
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bi_x_idx <= 0;
        bi_y_idx <= 0;
    end
    else if(bilinear_calc_start) begin
        bi_x_idx <= bi_x_idx + 1;
        bi_y_idx <= bi_x_idx == 15 ? bi_y_idx + 1 : bi_y_idx;
    end
    else begin
        bi_x_idx <= bi_x_idx;
        bi_y_idx <= bi_y_idx;
    end
end
assign X_is_zero = bi_x_idx == 0;
assign Y_is_zero = bi_y_idx == 0;
assign X_is_end = bi_x_idx == 15;
assign Y_is_end = bi_y_idx == 15;
assign Center = bilinear_mem[17];
assign H0 = bilinear_mem[16];
assign H1 = bilinear_mem[18];
assign V0 = bilinear_mem[1];
assign V1 = bilinear_mem[33];
assign D00 = bilinear_mem[0];
assign D01 = bilinear_mem[34];
assign D10 = bilinear_mem[2];
assign D11 = bilinear_mem[32];
always @(*) begin
    Center_sel = Center;

    // H0 / H1
    H0_sel = X_is_zero ? H1 : H0;
    H1_sel = X_is_end  ? H0 : H1;

    // V0 / V1
    V0_sel = Y_is_zero ? V1 : V0;
    V1_sel = Y_is_end  ? V0 : V1;

    // D00: left-up
    D00_sel = (X_is_zero && Y_is_zero) ? D01 :
              (X_is_zero)              ? D10 :
              (Y_is_zero)              ? D11 :
                                          D00;

    // D01: right-down
    D01_sel = (X_is_end && Y_is_end) ? D00 :
              (X_is_end)             ? D11 :
              (Y_is_end)             ? D10 :
                                        D01;

    // D10: right-up
    D10_sel = (X_is_end && Y_is_zero) ? D11 :
              (X_is_end)              ? D00 :
              (Y_is_zero)             ? D01 :
                                         D10;

    // D11: left-down
    D11_sel = (X_is_zero && Y_is_end) ? D10 :
              (X_is_zero)             ? D01 :
              (Y_is_end)              ? D00 :
                                         D11;
end

assign h_sum = H0_sel + H1_sel;
assign v_sum = V0_sel + V1_sel;
assign hv_sum = h_sum + v_sum;
assign d1d2_sum = D00_sel + D01_sel + D10_sel + D11_sel;
assign h_sum_divide2 = h_sum >> 1;
assign v_sum_divide2 = v_sum >> 1;
assign d1d2_sum_divide4 = d1d2_sum >> 2;
assign hv_sum_divide4 = hv_sum >> 2;
always @(*) begin
    case({bi_y_idx[0], bi_x_idx[0]})
    2'b00: begin
        r_bilinear = Center_sel;
        g_bilinear = hv_sum_divide4;
        b_bilinear = d1d2_sum_divide4;
    end
    2'b01: begin
        r_bilinear = h_sum_divide2;
        g_bilinear = Center_sel;
        b_bilinear = v_sum_divide2;
    end
    2'b10: begin
        r_bilinear = v_sum_divide2;
        g_bilinear = Center_sel;
        b_bilinear = h_sum_divide2;
    end
    2'b11: begin
        r_bilinear = d1d2_sum_divide4;
        g_bilinear = hv_sum_divide4;
        b_bilinear = Center_sel;
    end
    default: begin
        r_bilinear = 0;
        g_bilinear = 0;
        b_bilinear = 0;
    end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_bilinear_reg <= 0;
        g_bilinear_reg <= 0;
        b_bilinear_reg <= 0;
        bilinear_reg <= 0;
        bilinear_reg2 <= 0;
    end
    else begin
        r_bilinear_reg <= r_bilinear;
        g_bilinear_reg <= g_bilinear;
        b_bilinear_reg <= b_bilinear;
        bilinear_reg <= bilinear_calc_start;
        bilinear_reg2 <= bilinear_reg;
    end
end

// CCM layer
// Original formula:
//   R = 1150R - 50(R+G+B) = 1100R - 50G - 50B
//   G = 1150G - 50(R+G+B) = 1100G - 50R - 50B
//   B = 1150B - 50(R+G+B) = 1100B - 50R - 50G
//
// Area optimization:
//   Remove val_time_1150 x3 and val_time_neg50 x1.
//   Use shift-add to generate 1100*x and 50*x directly.

wire signed [24:0] r_x1100;
wire signed [24:0] g_x1100;
wire signed [24:0] b_x1100;

wire signed [24:0] r_x50;
wire signed [24:0] g_x50;
wire signed [24:0] b_x50;

wire signed [26:0] r_ccm_raw_w;
wire signed [26:0] g_ccm_raw_w;
wire signed [26:0] b_ccm_raw_w;

wire signed [26:0] r_ccm_round;
wire signed [26:0] g_ccm_round;
wire signed [26:0] b_ccm_round;

wire signed [15:0] r_ccm_shift;
wire signed [15:0] g_ccm_shift;
wire signed [15:0] b_ccm_shift;

wire [11:0] r_out_sel;
wire [11:0] g_out_sel;
wire [11:0] b_out_sel;


// ============================================================
// 1100 * x = 1024*x + 64*x + 8*x + 4*x
// ============================================================

assign r_x1100 = ($signed({1'b0, r_bilinear_reg}) <<< 10) +
                 ($signed({1'b0, r_bilinear_reg}) <<< 6 ) +
                 ($signed({1'b0, r_bilinear_reg}) <<< 3 ) +
                 ($signed({1'b0, r_bilinear_reg}) <<< 2 );

assign g_x1100 = ($signed({1'b0, g_bilinear_reg}) <<< 10) +
                 ($signed({1'b0, g_bilinear_reg}) <<< 6 ) +
                 ($signed({1'b0, g_bilinear_reg}) <<< 3 ) +
                 ($signed({1'b0, g_bilinear_reg}) <<< 2 );

assign b_x1100 = ($signed({1'b0, b_bilinear_reg}) <<< 10) +
                 ($signed({1'b0, b_bilinear_reg}) <<< 6 ) +
                 ($signed({1'b0, b_bilinear_reg}) <<< 3 ) +
                 ($signed({1'b0, b_bilinear_reg}) <<< 2 );


// ============================================================
// 50 * x = 32*x + 16*x + 2*x
// ============================================================

assign r_x50 = ($signed({1'b0, r_bilinear_reg}) <<< 5) +
               ($signed({1'b0, r_bilinear_reg}) <<< 4) +
               ($signed({1'b0, r_bilinear_reg}) <<< 1);

assign g_x50 = ($signed({1'b0, g_bilinear_reg}) <<< 5) +
               ($signed({1'b0, g_bilinear_reg}) <<< 4) +
               ($signed({1'b0, g_bilinear_reg}) <<< 1);

assign b_x50 = ($signed({1'b0, b_bilinear_reg}) <<< 5) +
               ($signed({1'b0, b_bilinear_reg}) <<< 4) +
               ($signed({1'b0, b_bilinear_reg}) <<< 1);


// ============================================================
// CCM raw result
// ============================================================

assign r_ccm_raw_w = {{2{r_x1100[24]}}, r_x1100} -
                     {{2{g_x50[24]}},   g_x50  } -
                     {{2{b_x50[24]}},   b_x50  };

assign g_ccm_raw_w = {{2{g_x1100[24]}}, g_x1100} -
                     {{2{r_x50[24]}},   r_x50  } -
                     {{2{b_x50[24]}},   b_x50  };

assign b_ccm_raw_w = {{2{b_x1100[24]}}, b_x1100} -
                     {{2{r_x50[24]}},   r_x50  } -
                     {{2{g_x50[24]}},   g_x50  };


// ============================================================
// Pipeline register
// ============================================================

// ============================================================
// Round and shift
// Original behavior:
//   (ccm >>> 10) + ccm[9]
// Equivalent positive rounding:
//   (ccm + 512) >>> 10
// ============================================================

assign r_ccm_round = r_ccm_raw_w + 27'sd512;
assign g_ccm_round = g_ccm_raw_w + 27'sd512;
assign b_ccm_round = b_ccm_raw_w + 27'sd512;

assign r_ccm_shift = r_ccm_round >>> 10;
assign g_ccm_shift = g_ccm_round >>> 10;
assign b_ccm_shift = b_ccm_round >>> 10;


// ============================================================
// Clamp to 12-bit range [0, 4095]
// ============================================================

assign r_out_sel = r_ccm_shift[15]      ? 12'd0    :
                   (|r_ccm_shift[14:12]) ? 12'd4095 :
                                           r_ccm_shift[11:0];

assign g_out_sel = g_ccm_shift[15]      ? 12'd0    :
                   (|g_ccm_shift[14:12]) ? 12'd4095 :
                                           g_ccm_shift[11:0];

assign b_out_sel = b_ccm_shift[15]      ? 12'd0    :
                   (|b_ccm_shift[14:12]) ? 12'd4095 :
                                           b_ccm_shift[11:0];


// ============================================================
// Output register
// ============================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_out_reg <= 8'd0;
        g_out_reg <= 8'd0;
        b_out_reg <= 8'd0;
        out_reg   <= 1'b0;
    end
    else if(bilinear_reg) begin
        r_out_reg <= r_out_sel[11:4];
        g_out_reg <= g_out_sel[11:4];
        b_out_reg <= b_out_sel[11:4];
        out_reg   <= 1'b1;
    end
    else begin
        r_out_reg <= 8'd0;
        g_out_reg <= 8'd0;
        b_out_reg <= 8'd0;
        out_reg   <= 1'b0;
    end
end


// ============================================================
// Result
// ============================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        r_out     <= 0;
        g_out     <= 0;
        b_out     <= 0;
    end else begin
        out_valid <= out_reg;
        r_out     <= r_out_reg;
        g_out     <= g_out_reg;
        b_out     <= b_out_reg;
    end
end

endmodule

module biLinear_1d_4stage #(
    parameter int DATA_W = 12,
    parameter int MUL_W = DATA_W + 9
)
(
    input clk,
    input rst_n,
    input  [DATA_W - 1:0] a,
    input [1:0]           dx_sel,
    input  [DATA_W - 1:0] b,
    output signed[MUL_W - 1:0] result
);
wire signed [DATA_W:0] a_signed = {1'b0, a};
wire signed [DATA_W:0] b_signed = {1'b0, b};
wire signed [DATA_W:0] b_sub_a = b_signed - a_signed;
reg signed [DATA_W:0] b_sub_a_r;
reg signed [MUL_W - 1:0] mul_reg; 
reg signed [MUL_W - 1:0] mul_reg0, mul_reg1; 
reg [MUL_W - 1:0] a_shift_8_r, a_shift_8_r_r, a_shift_8_r_r_r;
wire [MUL_W - 1:0] a_shift_8 = a << 8; 
reg [1:0] dx_sel_r;
always @(posedge clk) begin
        a_shift_8_r <= a_shift_8;
        a_shift_8_r_r <= a_shift_8_r;
        a_shift_8_r_r_r <= a_shift_8_r_r;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mul_reg <= 0;
        b_sub_a_r <= 0;
        dx_sel_r <= 0;
        mul_reg0 <= 0;
        mul_reg1 <= 0;
    end
    else begin
        b_sub_a_r <= b_sub_a;
        dx_sel_r <= dx_sel;
        mul_reg <= mul_reg0 + mul_reg1;
        case (dx_sel_r) 
            // * 85
            2'd1: begin
                mul_reg0 <= (b_sub_a_r <<< 6) + (b_sub_a_r <<< 4);
                mul_reg1 <= (b_sub_a_r <<< 2) + (b_sub_a_r);
            end
            // * 171
            2'd2: begin
                mul_reg0 <= (b_sub_a_r <<< 7) + (b_sub_a_r <<< 5);
                mul_reg1 <= (b_sub_a_r <<< 3) + (b_sub_a_r <<< 1) + (b_sub_a_r);
            end
            default: begin
                mul_reg0 <= 0;
                mul_reg1 <= 0;
            end
        endcase
    end
end

assign result = a_shift_8_r_r_r + mul_reg;
endmodule

module median_score(
    input clk,
    input rst_n,
    input  [11:0] in_0, in_1, in_2, in_3,
    output reg [11:0] median,
    output [13:0] score
);
wire [11:0] min1, max1, min2, max2, min3, max3;
reg [11:0] min1_r, max1_r, min2_r, max2_r;
wire [11:0] order0, order1, order2, order3;
reg [11:0] order0_r, order1_r, order2_r, order3_r;
reg [11:0] order0_r2, order3_r2;
wire [11:0] score0, score1, score2, score3;
reg [11:0] score0_r, score1_r, score2_r, score3_r;
wire [11:0] median_tmp;
wire [12:0] median_sum;
reg [11:0] min3_r, max3_r;
reg [11:0] median_r;
assign {min1, max1} = in_0 < in_1 ? {in_0, in_1} : {in_1, in_0};
assign {min2, max2} = in_2 < in_3 ? {in_2, in_3} : {in_3, in_2};
assign {order0, min3} = max1_r < max2_r ? {max2_r, max1_r} : {max1_r, max2_r};
assign {max3, order3} = min1_r < min2_r ? {min2_r, min1_r} : {min1_r, min2_r};

assign {order1, order2} = min3_r < max3_r ? {max3_r, min3_r} : {min3_r, max3_r};

assign median_sum = {1'b0, order1} + {1'b0, order2};
assign median_tmp = median_sum >> 1;

always @(posedge clk) begin
    median_r <= median_tmp;
    median <= median_r;
    order0_r <= order0;
    order1_r <= order1;
    order2_r <= order2;
    order3_r <= order3;
    order0_r2 <= order0_r;
    order3_r2 <= order3_r;
    min3_r <= min3;
    max3_r <= max3;
    score0_r <= score0;
    score1_r <= score1;
    score2_r <= score2;
    score3_r <= score3;
    min1_r <= min1;
    max1_r <= max1;
    min2_r <= min2;
    max2_r <= max2;
end

assign score0 = order0_r2 - median_r;
assign score1 = order1_r - median_r;
assign score2 = median_r - order2_r;
assign score3 = median_r - order3_r2;
assign score = {2'b0, score0_r} + {2'b0, score1_r} + {2'b0, score2_r} + {2'b0, score3_r};
endmodule

module mult_12bit(
    input clk,
    input [11:0] a,
    input [11:0] b,
    output reg [23:0] result
);
always @(posedge clk) begin
    result <= a * b;
end
endmodule

module SRAM_4096_12(
    clk, addr, data_i, WEB, data_o
);
input         clk;
input  [11:0]  addr;
input  [11:0] data_i;
input         WEB;
output [11:0] data_o;

SUMA180_4096X12 u_SRAM_4096_12
(
    .A0(addr[0]), .A1(addr[1]), .A2(addr[2]),.A3(addr[3]), .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), .A7(addr[7]), .A8(addr[8]), .A9(addr[9]), .A10(addr[10]), .A11(addr[11]),
    .DO0(data_o[0]),  .DO1(data_o[1]),  .DO2(data_o[2]),   .DO3(data_o[3]),   .DO4(data_o[4]),   .DO5(data_o[5]),   .DO6(data_o[6]),   .DO7(data_o[7]),  
    .DO8(data_o[8]),  .DO9(data_o[9]),  .DO10(data_o[10]), .DO11(data_o[11]), 
    .DI0(data_i[0]),   .DI1(data_i[1]),   .DI2(data_i[2]),    .DI3(data_i[3]),    .DI4(data_i[4]),    .DI5(data_i[5]),    .DI6(data_i[6]),    .DI7(data_i[7]),   
    .DI8(data_i[8]),   .DI9(data_i[9]),   .DI10(data_i[10]),  .DI11(data_i[11]), 
    .CK(clk),           .WEB(WEB),   	     .OE(1'b1), 	     .CS(1'b1)
);

endmodule