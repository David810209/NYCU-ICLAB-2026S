module ISP(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in,
    param_valid,
    param_gain,

    //Output Port
    out_valid,
    r_out,
    g_out,
    b_out
    );

//==============================
//   INPUT/OUTPUT DECLARATION
//==============================
// `define LSC_CHECK
// `define DPC
// `define DPC_CHECK
input clk;
input rst_n;
input in_valid;
input [11:0] in;
input param_valid;
input [11:0] param_gain;

output reg out_valid;
output reg [11:0] r_out;
output reg [11:0] g_out;
output reg [11:0] b_out;
//==============================
//   Variable Declaration
//==============================
reg [11:0] param_mem [3:0] [35:0];
reg [7:0] param_input_cnt;
wire param_input_cnt_range0, param_input_cnt_range1, param_input_cnt_range2, param_input_cnt_range3;
wire        param_input_en [3:0];
reg [11:0] param_reg;
reg param_valid_reg;
reg extra_shift;
wire shift6_valid;
reg [11:0] g_sel [11:0];
reg [2:0] g_sel_idx;
// stage 0 register input
reg [11:0] in_reg;
reg in_valid_reg;
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
reg [3:0] dpc_x_idx_r, dpc_y_idx_r;
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
reg [11:0] bilinear_mem [211:0];
wire [11:0] bilinear_mem_head;
wire bilinear_calc_start;
reg biLinear_start;
reg [8:0] bilinear_idx;

reg [11:0] r_bilinear, g_bilinear, b_bilinear;
wire [12:0] h_sum, v_sum;
wire [13:0] hv_sum, d1d2_sum;
wire [11:0] h_sum_divide2, v_sum_divide2, d1d2_sum_divide4, hv_sum_divide4;

reg [11:0] r_bilinear_reg, g_bilinear_reg, b_bilinear_reg;
reg [13:0] rgb_add_reg;
reg bilinear_reg;
reg bilinear_reg2;
reg bilinear_reg3;
reg bilinear_reg4;
// CCM layer
wire [22:0] r_1150, g_1150, b_1150;
wire signed [23:0] rgb_neg50;
reg [22:0] r_1150_r, g_1150_r, b_1150_r;
reg [22:0] r_1150_r_r, g_1150_r_r, b_1150_r_r;
reg signed [23:0] rgb_neg50_r;
wire signed [14:0] r_ccm_shift, g_ccm_shift, b_ccm_shift;
wire signed [24:0] r_ccm, g_ccm, b_ccm;
reg out_reg;
reg [11:0] r_out_reg, g_out_reg, b_out_reg;
wire [11:0] r_out_sel, g_out_sel, b_out_sel;
//==============================
//   Design
//==============================
assign param_input_cnt_range0 = param_input_cnt <= 35;
assign param_input_cnt_range1 = param_input_cnt <= 71;
assign param_input_cnt_range2 = param_input_cnt <= 107;
assign param_input_en[0] = param_input_cnt_range0;
assign param_input_en[1] = ~param_input_cnt_range0 && param_input_cnt_range1;
assign param_input_en[2] = ~param_input_cnt_range1 && param_input_cnt_range2;
assign param_input_en[3] = ~param_input_cnt_range2;

assign shift6_valid = (x_2_idx == 15  && lsc_y_cnt == 2 && y_2_idx != 14) || extra_shift;
integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            param_mem[i] <= '{default: 0};
        end
    end
    else begin
        for(i = 0; i < 4; i = i + 1) begin
            if((param_valid_reg && param_input_en[i])) begin
                param_mem[i][35] <= param_reg;
                param_mem[i][34:0] <= param_mem[i][35:1];
            end
            else if(shift6_valid) begin
                param_mem[i][29:0] <= param_mem[i][35:6];
                param_mem[i][35:30] <= param_mem[i][5:0];
            end
            else begin
                param_mem[i][35:0] <= param_mem[i][35:0];
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        param_input_cnt <= 0;
    end
    else if(param_valid_reg) begin
        param_input_cnt <= param_input_cnt + 1;
    end
    else begin
        param_input_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) extra_shift <= 0;
    else extra_shift <= x_2_idx == 15 && y_2_idx == 15;
end

// stage 0 register input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_reg <= 0;
        in_valid_reg <= 0;
        param_valid_reg <= 0;
        param_reg <= 0;
    end
    else  begin
        in_reg <= in;
        in_valid_reg <= in_valid;
        param_valid_reg <= param_valid;
        param_reg <= param_gain;
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
always @(*) begin
    case (blc_sel_reg) 
        2'b00: g_sel[11:0] = param_mem[0][11:0];
        2'b10: g_sel[11:0] = param_mem[1][11:0];
        2'b01: g_sel[11:0] = param_mem[2][11:0];
        2'b11: g_sel[11:0] = param_mem[3][11:0];
        default: g_sel[11:0] = '{default: 12'd0};
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)    g_sel_idx <= 0;
    else if(x_2_idx == 15) g_sel_idx <= 0;
    else if(lsc_x_cnt == 2 && x_2_idx <= 13) g_sel_idx <= g_sel_idx + 1;
    else g_sel_idx <= g_sel_idx;
end

always @(posedge clk or negedge rst_n)  begin
    if(!rst_n) begin
        g00 <= 0;
        g01 <= 0;
        g10 <= 0;
        g11 <= 0;
    end
    else begin
        case (g_sel_idx)
            0:  begin
                g00 <= g_sel[0];
                g01 <= g_sel[1];
                g10 <= g_sel[6];
                g11 <= g_sel[7];
            end
            1:  begin
                g00 <= g_sel[1];
                g01 <= g_sel[2];
                g10 <= g_sel[7];
                g11 <= g_sel[8];
            end
            2:  begin
                g00 <= g_sel[2];
                g01 <= g_sel[3];
                g10 <= g_sel[8];
                g11 <= g_sel[9];
            end
            3:  begin
                g00 <= g_sel[3];
                g01 <= g_sel[4];
                g10 <= g_sel[9];
                g11 <= g_sel[10];
            end
            4:  begin
                g00 <= g_sel[4];
                g01 <= g_sel[5];
                g10 <= g_sel[10];
                g11 <= g_sel[11];
            end
            default: begin
                g00 <= 0;
                g01 <= 0;
                g10 <= 0;
                g11 <= 0;
            end
        endcase
    end
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
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result_1_reg <= 0;
        result_2_reg <= 0;
    end
    else begin
        result_1_reg <= result_1;
        result_2_reg <= result_2;
    end
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
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result_3_reg <= 0;
    end
    else begin
        result_3_reg <= result_3_tmp[11:0];
    end
end

// stage 5 result
mult_12bit mult_12bit_1 (
    .clk(clk),
    .rst_n(rst_n),
    .a(blc_value[9]),
    .b(result_3_reg),
    .result(LSC_final_result_tmp)
);
// assign LSC_final_result_tmp =  blc_value_4_2 * result_3_reg;
assign LSC_final_result_tmp2 = (LSC_final_result_tmp >>> 10) + LSC_final_result_tmp[9];
assign LSC_result_overflow = |LSC_final_result_tmp2[13:12];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        LSC_final_result <= 0;
    end
    else begin
        LSC_final_result <= LSC_result_overflow ? 12'hFFF : LSC_final_result_tmp2[11:0];

    end
end
// `ifdef LSC_CHECK
// // tmp LSC check value
// always @(*) begin
//     out_valid = blc_valid5;
//     r_out = LSC_final_result;
//     g_out = 0;
//     b_out = 0;
// end
// `endif 
// `ifdef DPC 
// DPC layer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_input_idx <= 0;
    end
    else if(blc_valid[11] || (dpc_start)) begin
        dpc_input_idx <= dpc_input_idx + 1;
    end
    else begin
       dpc_input_idx <= 0;
    end
end

assign dpc_start = dpc_input_idx >= 35 && dpc_input_idx <= 290;
assign bilinear_calc_start = (biLinear_start && bilinear_idx >= 35);
wire [11:0] dpc_input_sel;
assign dpc_input_sel = blc_valid[11] ? LSC_final_result : 
                    biLinear_start ? bilinear_mem_head : 0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_mem[255:187] <= {default: 0};
    end
    else  begin
        dpc_mem[255] <= dpc_input_sel;
        dpc_mem[254:187] <= dpc_mem[255:188];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_x_idx <= 0;
        dpc_y_idx <= 0;
    end
    else if(dpc_start || bilinear_calc_start) begin
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
always @(posedge clk or negedge rst_n) begin
    /*
    0: 3,2,2,3
    1: c,1,2,3
    14: 0,1,2,c
    15: 0,1,1,0
    */
    if(!rst_n) begin
        h_sel[0] <= 0;
        h_sel[1] <= 0;
        h_sel[2] <= 0;
        h_sel[3] <= 0;
        v_sel[0] <= 0;
        v_sel[1] <= 0;
        v_sel[2] <= 0;
        v_sel[3] <= 0;
        d1_sel[0] <= 0;
        d1_sel[1] <= 0;
        d1_sel[2] <= 0;
        d1_sel[3] <= 0;
        d2_sel[0] <= 0;
        d2_sel[1] <= 0;
        d2_sel[2] <= 0;
        d2_sel[3] <= 0;
    end
    else begin
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

assign dpc_result = p_minus_target > 12'h140 ? min_score_median_r : c_reg[7]; // d 320

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_result_reg <= 0;
        h_median_r <= 0;
        v_median_r <= 0;
        d1_median_r <= 0;
        d2_median_r <= 0;
        h_score_r <= 0;
        v_score_r <= 0;
        d1_score_r <= 0;
        d2_score_r <= 0;
        min_score1_r <= 0;
        min_score2_r <= 0;
        min_score1_type_r <= 0;
        min_score2_type_r <= 0;
        min_score1_median_r <= 0;
        min_score2_median_r <= 0;
        min_score_median_r <= 0;
    end
    else begin
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
end

// `ifdef DPC_CHECK
// always @(*) begin
//     biLinear_start = 0;
//     bilinear_idx = 0;
//     out_valid = dpc_valid7;
//     r_out = dpc_result_reg;
//     g_out = 0;
//     b_out = 0;
// end
// assign bilinear_mem_head = 0;
// `endif 
// `else 
// bilinear layer
// `ifdef FINAL
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        bilinear_mem[211:0] <= {default: 0};
    end
    else begin
        bilinear_mem[211] <= dpc_valid[8] ? dpc_result_reg : bilinear_mem[0];
        bilinear_mem[210:0] <= bilinear_mem[211:1];
    end
end
assign bilinear_mem_head = bilinear_mem[0];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        biLinear_start <= 0;
    end
    else if(dpc_input_idx == 255) begin
        biLinear_start <= 1;
    end
    else if(bilinear_idx == 290) begin
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

assign h_sum = h_sel[1] + h_sel[2];
assign v_sum = v_sel[1] + v_sel[2];
assign hv_sum = h_sum + v_sum;
assign d1d2_sum = d1_sel[1] + d1_sel[2] + d2_sel[1] + d2_sel[2];
assign h_sum_divide2 = h_sum >> 1;
assign v_sum_divide2 = v_sum >> 1;
assign d1d2_sum_divide4 = d1d2_sum >> 2;
assign hv_sum_divide4 = hv_sum >> 2;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_x_idx_r <= 0;
        dpc_y_idx_r <= 0;
    end
    else begin
        dpc_x_idx_r <= dpc_x_idx;
        dpc_y_idx_r <= dpc_y_idx;
    end
end

always @(*) begin
    case({dpc_y_idx_r[0], dpc_x_idx_r[0]})
    2'b00: begin
        r_bilinear = c_reg[0];
        g_bilinear = hv_sum_divide4;
        b_bilinear = d1d2_sum_divide4;
    end
    2'b01: begin
        r_bilinear = h_sum_divide2;
        g_bilinear = c_reg[0];
        b_bilinear = v_sum_divide2;
    end
    2'b10: begin
        r_bilinear = v_sum_divide2;
        g_bilinear = c_reg[0];
        b_bilinear = h_sum_divide2;
    end
    2'b11: begin
        r_bilinear = d1d2_sum_divide4;
        g_bilinear = hv_sum_divide4;
        b_bilinear = c_reg[0];
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
        bilinear_reg3 <= 0;
        bilinear_reg4 <= 0;
        rgb_add_reg <= 0;
    end
    else begin
        r_bilinear_reg <= r_bilinear;
        g_bilinear_reg <= g_bilinear;
        b_bilinear_reg <= b_bilinear;
        bilinear_reg <= bilinear_calc_start;
        bilinear_reg2 <= bilinear_reg;
        bilinear_reg3 <= bilinear_reg2;
        bilinear_reg4 <= bilinear_reg3;
        rgb_add_reg <= r_bilinear_reg + g_bilinear_reg + b_bilinear_reg;
    end
end

// always @(*) begin
//     out_valid = bilinear_reg;
//     r_out = r_bilinear;
//     g_out = g_bilinear;
//     b_out = b_bilinear;
// end

// `ifdef FINAL
// CCM layer
val_time_1150 val_time_1100_r (
    .val(r_bilinear_reg),
    .val_1150(r_1150)
);
val_time_1150 val_time_1100_g (
    .val(g_bilinear_reg),
    .val_1150(g_1150)
);
val_time_1150 val_time_1100_b (
    .val(b_bilinear_reg),
    .val_1150(b_1150)
);
val_time_neg50 val_time_neg50_r (
    .val(rgb_add_reg),
    .val_neg50(rgb_neg50)
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_1150_r <= 0;
        g_1150_r <= 0;
        b_1150_r <= 0;
        r_1150_r_r <= 0;
        g_1150_r_r <= 0;
        b_1150_r_r <= 0;
        rgb_neg50_r <= 0;
    end
    else begin
        r_1150_r <= r_1150;
        g_1150_r <= g_1150;
        b_1150_r <= b_1150;
        r_1150_r_r <= r_1150_r;
        g_1150_r_r <= g_1150_r;
        b_1150_r_r <= b_1150_r;
        rgb_neg50_r <= rgb_neg50;
    end
end
assign r_ccm = $signed({1'b0, r_1150_r_r}) + rgb_neg50_r;
assign g_ccm = $signed({1'b0, g_1150_r_r}) + rgb_neg50_r;
assign b_ccm = $signed({1'b0, b_1150_r_r}) + rgb_neg50_r;
assign r_ccm_shift = (r_ccm >>> 10) + r_ccm[9];
assign g_ccm_shift = (g_ccm >>> 10) + g_ccm[9];
assign b_ccm_shift = (b_ccm >>> 10) + b_ccm[9];

assign r_out_sel = r_ccm_shift[14] ? 12'd0 : (r_ccm_shift[13:12] ? 12'd4095 : r_ccm_shift[11:0]);
assign g_out_sel = g_ccm_shift[14] ? 12'd0 : (g_ccm_shift[13:12] ? 12'd4095 : g_ccm_shift[11:0]);
assign b_out_sel = b_ccm_shift[14] ? 12'd0 : (b_ccm_shift[13:12] ? 12'd4095 : b_ccm_shift[11:0]);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_out_reg <= 0;
        g_out_reg <= 0;
        b_out_reg <= 0;
        out_reg <= 0;
    end
    else if(bilinear_reg4) begin
        r_out_reg <= r_out_sel;
        g_out_reg <= g_out_sel;
        b_out_reg <= b_out_sel;
        out_reg <= 1;
    end
    else begin
        r_out_reg <= 0;
        g_out_reg <= 0;
        b_out_reg <= 0;
        out_reg <= 0;
    end
end
// result
always @(*) begin
    out_valid = out_reg;
    r_out = r_out_reg;
    g_out = g_out_reg;
    b_out = b_out_reg;
end
// `endif 
endmodule

// module biLinear_1d #(
//     parameter int DATA_W = 12,
//     parameter int MUL_W = DATA_W + 9
// )
// (
//     input  [DATA_W - 1:0] a,
//     input [1:0]           dx_sel,
//     input  [DATA_W - 1:0] b,
//     output signed[MUL_W - 1:0] result
// );
// wire signed [DATA_W:0] a_signed = {1'b0, a};
// wire signed [DATA_W:0] b_signed = {1'b0, b};
// wire signed [DATA_W:0] b_sub_a = b_signed - a_signed;
// reg signed [MUL_W - 1:0] mul_reg; 

// wire [MUL_W - 1:0] a_shift_8 = a << 8; 
// always @(*) begin
//     case (dx_sel) 
//         // * 85
//         2'd1: mul_reg = (b_sub_a <<< 6) +
//                     (b_sub_a <<< 4) +
//                     (b_sub_a <<< 2) +
//                     (b_sub_a);
//         // * 171
//         2'd2: mul_reg = (b_sub_a <<< 7) +
//                     (b_sub_a <<< 5) +
//                     (b_sub_a <<< 3) +
//                     (b_sub_a <<< 1) +
//                     (b_sub_a);
//         default: mul_reg = 0;
//     endcase
// end

// assign result = a_shift_8 + mul_reg;
// endmodule

// module biLinear_1d_2stage #(
//     parameter int DATA_W = 12,
//     parameter int MUL_W = DATA_W + 9
// )
// (
//     input clk,
//     input rst_n,
//     input  [DATA_W - 1:0] a,
//     input [1:0]           dx_sel,
//     input  [DATA_W - 1:0] b,
//     output signed[MUL_W - 1:0] result
// );
// wire signed [DATA_W:0] a_signed = {1'b0, a};
// wire signed [DATA_W:0] b_signed = {1'b0, b};
// wire signed [DATA_W:0] b_sub_a = b_signed - a_signed;
// reg signed [DATA_W:0] b_sub_a_r;
// reg signed [MUL_W - 1:0] mul_reg; 
// reg [MUL_W - 1:0] a_shift_8_r, a_shift_8_r_r;
// wire [MUL_W - 1:0] a_shift_8 = a << 8; 
// reg [1:0] dx_sel_r;
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         a_shift_8_r <= 0;
//         a_shift_8_r_r <= 0;
//     end
//     else begin
//         a_shift_8_r <= a_shift_8;
//         a_shift_8_r_r <= a_shift_8_r;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         mul_reg <= 0;
//         b_sub_a_r <= 0;
//         dx_sel_r <= 0;
//     end
//     else begin
//         b_sub_a_r <= b_sub_a;
//         dx_sel_r <= dx_sel;
//         case (dx_sel_r) 
//             // * 85
//             2'd1: mul_reg <= (b_sub_a_r <<< 6) +
//                         (b_sub_a_r <<< 4) +
//                         (b_sub_a_r <<< 2) +
//                         (b_sub_a_r);
//             // * 171
//             2'd2: mul_reg <= (b_sub_a_r <<< 7) +
//                         (b_sub_a_r <<< 5) +
//                         (b_sub_a_r <<< 3) +
//                         (b_sub_a_r <<< 1) +
//                         (b_sub_a_r);
//             default: mul_reg <= 0;
//         endcase
//     end
// end

// assign result = a_shift_8_r_r + mul_reg;
// endmodule

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
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        a_shift_8_r <= 0;
        a_shift_8_r_r <= 0;
        a_shift_8_r_r_r <= 0;
    end
    else begin
        a_shift_8_r <= a_shift_8;
        a_shift_8_r_r <= a_shift_8_r;
        a_shift_8_r_r_r <= a_shift_8_r_r;
    end
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

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        median <= 0;
        median_r <= 0;
        order0_r <= 0;
        order1_r <= 0;
        order2_r <= 0;
        order3_r <= 0;
        order0_r2 <= 0;
        order3_r2 <= 0;
        min3_r <= 0;
        max3_r <= 0;
        score0_r <= 0;
        score1_r <= 0;
        score2_r <= 0;
        score3_r <= 0;
        min1_r <= 0;
        max1_r <= 0;
        min2_r <= 0;
        max2_r <= 0;
    end
    else begin
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
end

assign score0 = order0_r2 - median_r;
assign score1 = order1_r - median_r;
assign score2 = median_r - order2_r;
assign score3 = median_r - order3_r2;
assign score = {2'b0, score0_r} + {2'b0, score1_r} + {2'b0, score2_r} + {2'b0, score3_r};
endmodule

module val_time_1150(
    input  [11:0]  val,
    output [22:0]  val_1150
);
    wire [22:0] v23 = {11'b0, val};
    assign val_1150 = (v23 << 10) + (v23 << 7) - (v23 << 1);
endmodule

module val_time_neg50(
    input  [13:0]         val,   
    output signed [23:0]  val_neg50
);
    wire signed [23:0] s = $signed({10'b0, val});
    
    assign val_neg50 = (s <<< 4) - (s <<< 6) - (s <<< 1); 
endmodule

module mult_12bit(
    input clk,
    input rst_n,
    input [11:0] a,
    input [11:0] b,
    output [23:0] result
);
reg [11:0] ll, lh, hl, hh;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ll <= 0;
        lh <= 0;
        hl <= 0;
        hh <= 0;
    end
    else begin
        ll <= a[5:0] * b[5:0];
        lh <= a[5:0] * b[11:6];
        hl <= a[11:6] * b[5:0];
        hh <= a[11:6] * b[11:6];
    end
end
assign result = {hh, 12'b0} + {lh, 6'b0} + {hl, 6'b0} + ll;
endmodule
