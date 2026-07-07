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
`define DPC
`define DPC_CHECK
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
reg signed [6:0] blc_sel_val;
reg [11:0] blc_value;
reg blc_valid;
wire signed [12:0] blc_tmp;
wire [1:0] blc_sel;
reg [1:0] blc_sel_reg;
// stage 2 LSC
reg [1:0] lsc_x_cnt, lsc_y_cnt;
reg [1:0] lsc_x_cnt_r, lsc_y_cnt_r;
reg [3:0] x_2_idx, y_2_idx;
reg [11:0] g00, g01, g10, g11;
reg [11:0] blc_value_2;
reg blc_valid2;
// stage 3 mult 12
wire [20:0] result_1, result_2;
reg [20:0] result_1_reg, result_2_reg;
reg [1:0] lsc_y_cnt_reg;
reg [11:0] blc_value_3;
reg blc_valid3;
// stage 4 mult 3
wire       [29:0] result_3;
reg        [11:0] result_3_reg;
wire       [13:0] result_3_tmp;
reg [11:0] blc_value_4;
reg blc_valid4;
// stage 5 result
wire        [23:0] LSC_final_result_tmp;
wire        [13:0] LSC_final_result_tmp2;
reg [11:0] LSC_final_result;
reg blc_valid5;
// DPC layer
reg [11:0] dpc_mem [255:187];
reg [3:0] dpc_x_idx, dpc_y_idx;
reg [3:0] dpc_x_idx_r, dpc_y_idx_r;
reg [8:0] dpc_input_idx;
wire dpc_start;
wire [11:0] h [3:0];
wire [11:0] v [3:0];
wire [11:0] d1 [3:0];
wire [11:0] d2 [3:0];
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
reg [13:0] min_score1_r, min_score2_r;
reg [1:0] min_score1_type_r, min_score2_type_r;
reg [11:0] min_score1_median_r, min_score2_median_r;
wire hv_cmp, d1d2_cmp, min_score_sel;
wire [11:0] p_minus_target;
wire [11:0] dpc_result;
reg [11:0] dpc_result_reg;
reg dpc_valid, dpc_valid2, dpc_valid3, dpc_valid4, dpc_valid5, dpc_valid6;
reg [11:0] c_reg, c_reg2, c_reg3, c_reg4, c_reg5;
// bilinear layer
reg [11:0] bilinear_mem [214:0];
wire [11:0] bilinear_mem_head;
wire bilinear_calc_start;
reg biLinear_start;
reg [8:0] bilinear_idx;

reg [11:0] r_bilinear, g_bilinear, b_bilinear;
wire [12:0] h_sum, v_sum;
wire [13:0] hv_sum, d1d2_sum;
wire [11:0] h_sum_divide2, v_sum_divide2, d1d2_sum_divide4, hv_sum_divide4;

reg [11:0] r_bilinear_reg, g_bilinear_reg, b_bilinear_reg;
reg bilinear_reg;
reg bilinear_reg2;
// CCM layer
wire [22:0] r_1100, g_1100, b_1100;
wire signed [22:0] r_neg50, g_neg50, b_neg50;
wire signed [12:0] r_ccm_shift, g_ccm_shift, b_ccm_shift;
wire signed [22:0] r_ccm, g_ccm, b_ccm;
reg out_reg;
reg [11:0] r_out_reg, g_out_reg, b_out_reg;
//==============================
//   Design
//==============================
assign param_input_en[0] = param_input_cnt <= 35;
assign param_input_en[1] = param_input_cnt > 35 && param_input_cnt <= 71;
assign param_input_en[2] = param_input_cnt > 71 && param_input_cnt <= 107;
assign param_input_en[3] = param_input_cnt > 107;

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

assign blc_tmp = {1'b0, in_reg} - blc_sel_val;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        blc_value <= 0;
        blc_valid <= 0;
        blc_sel_reg <= 0;
    end
    else if(in_valid_reg) begin
        blc_value <= blc_tmp[12] ? 0 : blc_tmp[11:0];
        blc_valid <= 1;
        blc_sel_reg <= blc_sel;
    end
    else begin
        blc_value <= 0;
        blc_valid <= 0;
        blc_sel_reg <= 0;
    end
end

// stage 2 LSC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x_2_idx <= 0;
        y_2_idx <= 0;
        blc_value_2 <= 0;
        blc_valid2 <= 0;
    end
    else if(blc_valid) begin
        x_2_idx <= x_2_idx + 1;
        y_2_idx <= x_2_idx == 15 ? y_2_idx + 1 : y_2_idx;
        blc_value_2 <= blc_value;
        blc_valid2 <= 1;
    end
    else begin
        x_2_idx <= x_2_idx;
        y_2_idx <= y_2_idx;
        blc_value_2 <= blc_value_2;
        blc_valid2 <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) lsc_x_cnt <= 0;
    else if(blc_valid) begin
        if(x_2_idx == 14) lsc_x_cnt <= 2;
        else lsc_x_cnt <= lsc_x_cnt == 2 ? 0 : lsc_x_cnt + 1;
    end
    else lsc_x_cnt <= lsc_x_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  lsc_y_cnt <= 0;
    else if(blc_valid) begin
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
biLinear_1d biLinear_1d_1 (
    .a(g00),
    .dx_sel(lsc_x_cnt_r),
    .b(g01),
    .result(result_1)
);
biLinear_1d biLinear_1d_2 (
    .a(g10),
    .dx_sel(lsc_x_cnt_r),
    .b(g11),
    .result(result_2)
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result_1_reg <= 0;
        result_2_reg <= 0;
        lsc_y_cnt_reg <= 0;
        blc_value_3 <= 0;
        blc_valid3 <= 0;
    end
    else begin
        result_1_reg <= result_1;
        result_2_reg <= result_2;
        lsc_y_cnt_reg <= lsc_y_cnt_r;
        blc_value_3 <= blc_value_2;
        blc_valid3 <= blc_valid2;
    end
end

// stage 4 mult 3
biLinear_1d#(
    .DATA_W(21)
) biLinear_1d_3 (
    .a(result_1_reg),
    .dx_sel(lsc_y_cnt_reg),
    .b(result_2_reg),
    .result(result_3)
);

assign result_3_tmp = (result_3 >> 16) + result_3[15];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        result_3_reg <= 0;
        blc_value_4 <= 0;
        blc_valid4 <= 0;
    end
    else begin
        result_3_reg <= result_3_tmp[11:0];
        blc_value_4 <= blc_value_3;
        blc_valid4 <= blc_valid3;
    end
end

// stage 5 result
assign LSC_final_result_tmp =  blc_value_4 * result_3_reg;
assign LSC_final_result_tmp2 = (LSC_final_result_tmp >>> 10) + LSC_final_result_tmp[9];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        LSC_final_result <= 0;
        blc_valid5 <= 0;
    end
    else begin
        LSC_final_result <= LSC_final_result_tmp2 > 14'd4095 ? 12'd4095 : LSC_final_result_tmp2[11:0];
        blc_valid5 <= blc_valid4;
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
    else if(blc_valid5 || (dpc_start && dpc_input_idx > 0 && dpc_input_idx < 290)) begin
        dpc_input_idx <= dpc_input_idx + 1;
    end
    else begin
       dpc_input_idx <= 0;
    end
end

assign dpc_start = dpc_input_idx >= 35 && dpc_input_idx <= 290;
assign bilinear_calc_start = (biLinear_start && bilinear_idx >= 35);
wire [11:0] dpc_input_sel;
assign dpc_input_sel = blc_valid5 ? LSC_final_result : 
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

assign d1[0] = dpc_mem[187];
assign d1[1] = dpc_mem[204];
assign d1[2] = dpc_mem[238];
assign d1[3] = dpc_mem[255];    

assign d2[0] = dpc_mem[191];
assign d2[1] = dpc_mem[206];
assign d2[2] = dpc_mem[236];
assign d2[3] = dpc_mem[251];  
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

assign p_minus_target = c_reg5 > min_score_median ? c_reg5 - min_score_median : min_score_median - c_reg5;

assign dpc_result = p_minus_target > 12'h140 ? min_score_median : c_reg5; // d 320

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dpc_result_reg <= 0;
        dpc_valid <= 0;
        dpc_valid2 <= 0;
        dpc_valid3 <= 0;
        dpc_valid4 <= 0;
        dpc_valid5 <= 0;
        dpc_valid6 <= 0;
        c_reg <= 0;
        c_reg2 <= 0;
        c_reg3 <= 0;
        c_reg4 <= 0;
        c_reg5 <= 0;    
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
    end
    else begin
        dpc_result_reg <= dpc_result;
        dpc_valid <= dpc_start;
        dpc_valid2 <= dpc_valid;
        dpc_valid3 <= dpc_valid2;
        dpc_valid4 <= dpc_valid3;
        dpc_valid5 <= dpc_valid4;
        dpc_valid6 <= dpc_valid5;
        c_reg <= c;
        c_reg2 <= c_reg;
        c_reg3 <= c_reg2;
        c_reg4 <= c_reg3;
        c_reg5 <= c_reg4;
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
    end
end

// `ifdef DPC_CHECK
// always @(*) begin
//     biLinear_start = 0;
//     bilinear_idx = 0;
//     out_valid = dpc_valid;
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
        bilinear_mem[214:0] <= {default: 0};
    end
    else begin
        bilinear_mem[214] <= dpc_valid6 ? dpc_result_reg : bilinear_mem[0];
        bilinear_mem[213:0] <= bilinear_mem[214:1];
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
        r_bilinear = c_reg;
        g_bilinear = hv_sum_divide4;
        b_bilinear = d1d2_sum_divide4;
    end
    2'b01: begin
        r_bilinear = h_sum_divide2;
        g_bilinear = c_reg;
        b_bilinear = v_sum_divide2;
    end
    2'b10: begin
        r_bilinear = v_sum_divide2;
        g_bilinear = c_reg;
        b_bilinear = h_sum_divide2;
    end
    2'b11: begin
        r_bilinear = d1d2_sum_divide4;
        g_bilinear = hv_sum_divide4;
        b_bilinear = c_reg;
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

// always @(*) begin
//     out_valid = bilinear_reg;
//     r_out = r_bilinear_reg;
//     g_out = g_bilinear_reg;
//     b_out = b_bilinear_reg;
// end

// `ifdef FINAL
// CCM layer
val_time_1100 val_time_1100_r (
    .val(r_bilinear_reg),
    .val_1100(r_1100)
);
val_time_1100 val_time_1100_g (
    .val(g_bilinear_reg),
    .val_1100(g_1100)
);
val_time_1100 val_time_1100_b (
    .val(b_bilinear_reg),
    .val_1100(b_1100)
);
val_time_neg50 val_time_neg50_r (
    .val(r_bilinear_reg),
    .val_neg50(r_neg50)
);
val_time_neg50 val_time_neg50_g (
    .val(g_bilinear_reg),
    .val_neg50(g_neg50)
);
val_time_neg50 val_time_neg50_b (
    .val(b_bilinear_reg),
    .val_neg50(b_neg50)
);
assign r_ccm = r_1100 + g_neg50 + b_neg50;
assign g_ccm = r_neg50 + g_1100 + b_neg50;
assign b_ccm = r_neg50 + g_neg50 + b_1100;
assign r_ccm_shift = (r_ccm >>> 10) + r_ccm[9];
assign g_ccm_shift = (g_ccm >>> 10) + g_ccm[9];
assign b_ccm_shift = (b_ccm >>> 10) + b_ccm[9];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_out_reg <= 0;
        g_out_reg <= 0;
        b_out_reg <= 0;
        out_reg <= 0;
    end
    else if(bilinear_reg2) begin
        r_out_reg <= r_ccm_shift[11:0];
        g_out_reg <= g_ccm_shift[11:0];
        b_out_reg <= b_ccm_shift[11:0];
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

module biLinear_1d #(
    parameter int DATA_W = 12,
    parameter int MUL_W = DATA_W + 9
)
(
    input  [DATA_W - 1:0] a,
    input [1:0]           dx_sel,
    input  [DATA_W - 1:0] b,
    output signed[MUL_W - 1:0] result
);
wire signed [DATA_W:0] a_signed = {1'b0, a};
wire signed [DATA_W:0] b_signed = {1'b0, b};
wire signed [DATA_W:0] b_sub_a = b_signed - a_signed;
reg signed [MUL_W - 1:0] mul_reg; 

wire [MUL_W - 1:0] a_shift_8 = a << 8; 
always @(*) begin
    case (dx_sel) 
        // * 85
        2'd1: mul_reg = (b_sub_a <<< 6) +
                    (b_sub_a <<< 4) +
                    (b_sub_a <<< 2) +
                    (b_sub_a);
        // * 171
        2'd2: mul_reg = (b_sub_a <<< 7) +
                    (b_sub_a <<< 5) +
                    (b_sub_a <<< 3) +
                    (b_sub_a <<< 1) +
                    (b_sub_a);
        default: mul_reg = 0;
    endcase
end

assign result = a_shift_8 + mul_reg;
endmodule

module median_score(
    input clk,
    input rst_n,
    input  [11:0] in_0, in_1, in_2, in_3,
    output reg [11:0] median,
    output [13:0] score
);
wire [11:0] min1, max1, min2, max2, min3, max3;
wire [11:0] order0, order1, order2, order3;
reg [11:0] order0_r, order1_r, order2_r, order3_r;
reg [11:0] order0_r2, order1_r2, order2_r2, order3_r2;
wire [11:0] score0, score1, score2, score3;
wire [11:0] median_tmp;
wire [12:0] median_sum;

assign {min1, max1} = in_0 < in_1 ? {in_0, in_1} : {in_1, in_0};
assign {min2, max2} = in_2 < in_3 ? {in_2, in_3} : {in_3, in_2};
assign {order0, min3} = max1 < max2 ? {max2, max1} : {max1, max2};
assign {max3, order3} = min1 < min2 ? {min2, min1} : {min1, min2};
assign {order1, order2} = min3 < max3 ? {max3, min3} : {min3, max3};

assign median_sum = {1'b0, order1_r} + {1'b0, order2_r};
assign median_tmp = median_sum >> 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        median <= 0;
        order0_r <= 0;
        order1_r <= 0;
        order2_r <= 0;
        order3_r <= 0;
        order0_r2 <= 0;
        order1_r2 <= 0;
        order2_r2 <= 0;
        order3_r2 <= 0;
    end
    else begin
        median <= median_tmp;
        order0_r <= order0;
        order1_r <= order1;
        order2_r <= order2;
        order3_r <= order3;
        order0_r2 <= order0_r;
        order1_r2 <= order1_r;
        order2_r2 <= order2_r;
        order3_r2 <= order3_r;
    end
end

assign score0 = order0_r2 - median;
assign score1 = order1_r2 - median;
assign score2 = median - order2_r2;
assign score3 = median - order3_r2;
assign score = {2'b0, score0} + {2'b0, score1} + {2'b0, score2} + {2'b0, score3};
endmodule

module val_time_1100(
    input [11:0] val,
    output [22:0] val_1100
);
assign val_1100 = (val << 10) 
                + (val << 6)
                + (val << 3)
                + (val << 2);
endmodule

module val_time_neg50(
    input [11:0] val,
    output signed [22:0] val_neg50
);
wire [22:0] val_50;
assign val_50 = (val << 5)
                + (val << 4)
                + (val << 1);
assign val_neg50 = ~val_50 + 1;
endmodule
