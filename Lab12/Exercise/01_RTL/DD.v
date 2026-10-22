module DM(
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
output reg  o_valid;
output reg  [7:0] o_data;
// reg / wire / parameter / integer
// input register
reg in_valid_reg;
reg [7:0] in_data_reg;
reg [3:0] in_weight_reg;
reg [1:0] in_mode_reg;
reg [2:0] in_iter_reg;

// write weight
reg [10:0] write_weight_cnt;
reg [31:0] weight_input_accum;
wire [31:0] weight_read_data;
reg [31:0] weight_read_data_r;
reg weight_web;
reg [7:0] weight_addr;
reg [3:0] read_weight_cnt;
reg read_weight;

// write image
reg [8:0] in_img_addr;
reg [63:0] image_input_accum;
reg image_web;
reg [11:0] write_img_cnt;
reg write_image;

wire [63:0] image_read_data;
reg [63:0] image_read_data_r;
// convolution
reg [7:0] SR_CONV_data [130:0];
reg [3:0] SR_CONV_weight [71:0];
reg start_conv;
reg start_conv_down_calc;
reg start_conv_down;
reg [3:0] conv_down_iter;
reg conv_down_ch;
reg [12:0] conv_write_cnt_down;
reg [11:0] conv_cnt;
reg [11:0] conv_cnt_down;
reg conv_partial_sram_sel;

// partial result sram ctrl

reg [31:0] partial_sram0_input_accum;
wire [31:0] partial_sram0_read_data;
reg [31:0] partial_sram0_read_data_r;
reg partial_sram0_web;
reg [7:0] partial_sram0_addr;

reg [31:0] partial_sram1_input_accum;
wire [31:0] partial_sram1_read_data;
reg [31:0] partial_sram1_read_data_r;
reg partial_sram1_web;
reg [7:0] partial_sram1_addr;
reg [12:0] conv_write_cnt;
integer i, j, k;

reg [7:0] H0 ;
reg [7:0] H1 ;
reg [7:0] V0 ;
reg [7:0] V1 ;
reg [7:0] D00 ;
reg [7:0] D01 ;
reg [7:0] D10 ;
reg [7:0] D11 ;
reg [7:0] Center ;

reg [7:0] mult_a_sel [8:0];
wire X_is_zero, Y_is_zero, X_is_bound, Y_is_bound;
reg [7:0] mult_a [8:0];
reg [3:0] mult_b [7:0] [8:0];
reg signed [11:0] mult_result_r [7:0] [8:0];
wire signed [11:0] mult_result [7:0] [8:0];
reg signed [13:0] three_add0 [7:0] [2:0];
reg signed [15:0] three_add1 [7:0];
reg signed [15:0] three_add1_sel;
reg signed [31:0] accum_result_reg;
wire signed [25:0] accum_result_reg_shift;
reg signed [7:0] accum_result_clip;
reg signed [31:0] partial_result_sel;
reg signed [9:0] conv_result_shift [7:0];
reg [7:0] conv_result_clip [7:0];
reg [63:0] conv_result_clip_reg;
reg [5:0] X_r, Y_r;
genvar idx, jdx;
reg [63:0] conv_result_accum;
reg conv_stage1_valid;
reg conv_stage2, conv_stage3, conv_stage4, conv_stage5;
reg conv_iter2;
// conv result sram

reg [8:0] conv_result_addr;
reg conv_result_web;
wire [63:0] conv_result_read_data;
reg [63:0] conv_result_read_data_r;

// refetch img data
reg refetch_img_data;
reg [2:0] refetch_cnt;
reg [63:0] refetch_data_shift;
// tmp check conv result
reg output_check_fetch;
reg output_check;
reg [12:0] output_check_cnt;
reg [2:0] out_check_cnt;
reg [63:0] out_check_data_shift;
// Linear transformation, systolic array
reg  [7:0] pe_vertical_data_reg [7:0];
reg  [8:0] pe_horizontal_data_reg [7:0];

reg  [7:0] pe_vertical_data_i [63:0];
reg  [8:0] pe_horizontal_data_i [63:0];
wire [7:0] pe_vertical_data_o [63:0];
wire [8:0] pe_horizontal_data_o [63:0];
wire signed [23:0] pe_result_o [63:0];
wire [63:0] A_data_sel;
reg [8:0] A_buffer [7:0] [7:0];
reg [7:0] B_buffer2 [7:0] [7:0];
reg [7:0] B_buffer [7:0];
reg [7:0] B_buffer_delay1;
reg [7:0] B_buffer_delay2 [1:0];
reg [7:0] B_buffer_delay3 [2:0];
reg [7:0] B_buffer_delay4 [3:0];
reg [7:0] B_buffer_delay5 [4:0];
reg [7:0] B_buffer_delay6 [5:0];
reg [7:0] B_buffer_delay7 [6:0];
reg start_tpu;
reg [8:0] tpu_cnt;
reg [8:0] tpu_cnt_end;
wire [8:0] tpu_cnt_end_m1;
wire start_fetch_wire;
reg start_fetch;
reg [8:0] fetch_cnt;
wire [8:0] fetch_cnt_m3, fetch_cnt_m2;
reg tpu_data_valid;
reg tpu_data_valid2;
reg [7:0] tpu_result_data_clip [63:0];
reg [63:0] tpu_result_data_clip_r;
reg signed [21:0] tpu_result_data_shift2 [7:0];
reg signed [19:0] tpu_result_data_shift4 [7:0];
reg signed [7:0] tpu_result_data_shift16 [7:0];
reg signed [8:0] tpu_result_data_add [7:0];
reg signed [19:0] tpu_result_data_add_sel [7:0];
reg signed [17:0] tpu_result_data_shift6 [7:0];
reg signed  [23:0] tpu_result_data [63:0];
reg [6:0] tpu_result_cnt;
reg [8:0] fetch_start_idx;
wire [8:0] fetch_start_idx2;
wire [8:0] fetch_end_idx;
// wire [8:0] fetch_end_idx2;
// reg [4:0] tpu_shift_number;
reg start_write_q;
reg [2:0] q_write_cnt;
reg [63:0] q_data_accum;

reg [8:0] q_data_addr;
reg q_data_web;
wire [63:0] q_data_read_data;
reg [63:0] q_data_read_data_r;

reg [63:0] k_data_accum;

reg [8:0] k_data_addr;
reg k_data_web;
wire [63:0] k_data_read_data;
reg [63:0] k_data_read_data_r;

reg [63:0] v_data_accum;

reg [8:0] v_data_addr;
reg v_data_web;
wire [63:0] v_data_read_data;
reg [63:0] v_data_read_data_r;

reg [7:0] weight_addr_start_idx;
wire [7:0] weight_addr_start_idx2;
wire [7:0] weight_addr_end_idx;
reg [2:0] curr_tpu_iter;
reg [8:0] q_fetch_start_idx;
wire [8:0] q_fetch_start_idx2;
wire [8:0] q_fetch_end_idx;
// wire [8:0] q_fetch_end_idx2;

reg [8:0] k_fetch_start_idx;
wire [8:0] k_fetch_start_idx2;
wire [8:0] k_fetch_end_idx;
// wire [8:0] k_fetch_end_idx2;

reg [7:0] tpu_result_cnt_L2;

// QK sram ctrl
reg [63:0] qk_data_accum;

reg [7:0] qk_data_addr;
reg qk_data_web;
wire [63:0] qk_data_read_data;
reg [63:0] qk_data_read_data_r;
reg [8:0] fetch_cnt_end;
// QKV ctrl
// reg [63:0] qkv_data_accum;

// reg [8:0] qkv_data_addr;
// reg qkv_data_web;
// wire [63:0] qkv_data_read_data;
// reg [63:0] qkv_data_read_data_r;
reg [8:0] qkv_write_start_idx;
wire [8:0] qkv_write_start_idx2;
wire [8:0] qkv_write_end_idx;

// reg [63:0] ffn_data_accum;

// reg [8:0] ffn_data_addr;
// reg ffn_data_web;
// wire [63:0] ffn_data_read_data;
// reg [63:0] ffn_data_read_data_r;
reg [1:0] state, next_state;
localparam IDLE = 0;
localparam CALC = 1;
localparam SUB = 2;
reg [4:0] calc_cnt;
reg [1:0] sub_cnt;
reg [6:0] sub_cnt2;
reg [4:0] interpolation_iter;
reg [7:0] prev_data;
reg [7:0] prev_data2;
reg signed [8:0] diff;
wire signed [8:0] diff_shift2;
wire signed[8:0] diff_p2;
wire signed [8:0] diff_p3;
reg signed [9:0] t0, t1, t2, t3;
wire [7:0] t0_clip, t1_clip, t2_clip, t3_clip;
wire [4:0] t0_shift, t1_shift, t2_shift, t3_shift;
reg [19:0] SR_inter_result [15:0];
reg [4:0] SR_inter_result_sel;
reg [19:0] t_shift_tmp;
reg signed [8:0] sub_res [7:0];
reg [7:0] sub_res_clip [7:0];
reg read_iter_mode;
reg [2:0] iter_reg;
reg [1:0] mode_reg;
reg [3:0] partial_next_fetch_idx;
wire partial_next_col;
reg [2:0] img_next_fetch_idx;
wire img_next_col;
reg [6:0] sub_end_point;
reg right_side;
reg [3:0] iter;
reg [6:0] iter2_wait_conv_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iter <= 1;
    end
    else if(sub_cnt2 == sub_end_point && sub_cnt == 3 && interpolation_iter == 15)begin
        if(iter == iter_reg) begin
            iter <= 1;
        end
        else iter <= iter + 1;
    end
    else begin
        iter <= iter;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iter2_wait_conv_cnt <= 0;
    end
    else if(iter > 1 && refetch_img_data && start_conv == 0)begin
        iter2_wait_conv_cnt <= iter2_wait_conv_cnt + 1;
    end
    else begin
        iter2_wait_conv_cnt <= 0;
    end
end
// design
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_valid_reg <= 0;
        in_data_reg <= 0;
        in_weight_reg <= 0;
        in_mode_reg <= 0;
        in_iter_reg <= 0;
    end
    else begin
        in_valid_reg <= i_valid;
        in_data_reg <= i_data;
        in_weight_reg <= i_weight;
        in_mode_reg <= i_mode;
        in_iter_reg <= i_iter;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_iter_mode <= 0;
    end
    else if(in_valid_reg && write_image == 1) begin
        read_iter_mode <= 1;
    end
    else if(curr_tpu_iter == 7) begin
        read_iter_mode <= 0;
    end
    else begin
        read_iter_mode <= read_iter_mode;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iter_reg <= 0;
        mode_reg <= 0;
    end
    else if(in_valid_reg && read_iter_mode == 0) begin
        iter_reg <= in_iter_reg;
        mode_reg <= in_mode_reg;
    end
    else begin
        iter_reg <= iter_reg;
        mode_reg <= mode_reg;
    end
end
// write weight
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_weight_cnt <= 0;
    end
    else if(write_image == 0 && in_valid_reg) begin
        write_weight_cnt <= write_weight_cnt + 1;
    end
    else begin
        write_weight_cnt <= 0;
    end
end
// weight sram ctrl
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        weight_input_accum <= 0;
    end
    else if(write_image == 0 && in_valid_reg) begin
        weight_input_accum <= {weight_input_accum[27:0], in_weight_reg};
    end
    else begin
        weight_input_accum <= weight_input_accum;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        weight_web <= 1;
    end
    else if(write_weight_cnt[2:0] == 3'd7) begin
        weight_web <= 0;
    end
    else begin
        weight_web <= 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        weight_addr <= 0;
    end
    else if(in_valid_reg && write_image == 0) begin
        if(weight_web == 0) weight_addr <= weight_addr + 1;
        else weight_addr <= weight_addr;
    end
    else if(read_weight) begin
        weight_addr <= weight_addr + 1;
    end
    else if(conv_cnt == 4095) begin
        weight_addr <= 9;
    end
    else if(curr_tpu_iter == 5 && tpu_result_cnt == 64) begin
        weight_addr <= 146;
    end
    else if(start_conv_down && conv_down_iter == 7 && conv_cnt_down == 276) begin
        weight_addr <= 155;
    end
    else if(start_fetch_wire) begin
        weight_addr <= tpu_result_cnt < 31 || tpu_result_cnt == 64 ? weight_addr_start_idx : weight_addr_start_idx2;
    end
    else if(start_fetch) begin
        weight_addr <= weight_addr + 2;
    end
    else begin
        weight_addr <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        weight_read_data_r <= 0;
    end
    else begin
        weight_read_data_r <= weight_read_data;
    end
end

weight_256X32X1BM1 weight_sram (.CK(clk), .WEB(weight_web), .OE(1'b1), .CS(1'b1), 
.A0(weight_addr[0]), .A1(weight_addr[1]), .A2(weight_addr[2]), .A3(weight_addr[3]), .A4(weight_addr[4]), .A5(weight_addr[5]), .A6(weight_addr[6]), .A7(weight_addr[7]), 
.DI0(weight_input_accum[0]), .DI1(weight_input_accum[1]), .DI2(weight_input_accum[2]), .DI3(weight_input_accum[3]), .DI4(weight_input_accum[4]), .DI5(weight_input_accum[5]), .DI6(weight_input_accum[6]), .DI7(weight_input_accum[7]), 
.DI8(weight_input_accum[8]), .DI9(weight_input_accum[9]), .DI10(weight_input_accum[10]), .DI11(weight_input_accum[11]), .DI12(weight_input_accum[12]), .DI13(weight_input_accum[13]), .DI14(weight_input_accum[14]), .DI15(weight_input_accum[15]), 
.DI16(weight_input_accum[16]), .DI17(weight_input_accum[17]), .DI18(weight_input_accum[18]), .DI19(weight_input_accum[19]), .DI20(weight_input_accum[20]), .DI21(weight_input_accum[21]), .DI22(weight_input_accum[22]), .DI23(weight_input_accum[23]), 
.DI24(weight_input_accum[24]), .DI25(weight_input_accum[25]), .DI26(weight_input_accum[26]), .DI27(weight_input_accum[27]), .DI28(weight_input_accum[28]), .DI29(weight_input_accum[29]), .DI30(weight_input_accum[30]), .DI31(weight_input_accum[31]),
.DO0(weight_read_data[0]), .DO1(weight_read_data[1]), .DO2(weight_read_data[2]), .DO3(weight_read_data[3]), .DO4(weight_read_data[4]), .DO5(weight_read_data[5]), .DO6(weight_read_data[6]), .DO7(weight_read_data[7]),
.DO8(weight_read_data[8]), .DO9(weight_read_data[9]), .DO10(weight_read_data[10]), .DO11(weight_read_data[11]), .DO12(weight_read_data[12]), .DO13(weight_read_data[13]), .DO14(weight_read_data[14]), .DO15(weight_read_data[15]),
.DO16(weight_read_data[16]), .DO17(weight_read_data[17]), .DO18(weight_read_data[18]), .DO19(weight_read_data[19]), .DO20(weight_read_data[20]), .DO21(weight_read_data[21]), .DO22(weight_read_data[22]), .DO23(weight_read_data[23]),
.DO24(weight_read_data[24]), .DO25(weight_read_data[25]), .DO26(weight_read_data[26]), .DO27(weight_read_data[27]), .DO28(weight_read_data[28]), .DO29(weight_read_data[29]), .DO30(weight_read_data[30]), .DO31(weight_read_data[31]));

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_weight <= 0;
    end
    else if(in_valid_reg && write_img_cnt == 0 && write_image == 1) begin
        read_weight <= 1;
    end
    else if(start_conv && conv_cnt == 4095 && conv_iter2 == 0) begin
        read_weight <= 1;
    end
    else if(curr_tpu_iter == 5 && tpu_result_cnt == 64) begin
        read_weight <= 1;
    end
    else if(start_conv_down && conv_down_iter == 7 && conv_cnt_down == 276) begin
        read_weight <= 1;
    end
    else if(sub_cnt2 == sub_end_point && sub_cnt == 3 && interpolation_iter == 15 && iter != iter_reg) begin
        read_weight <= 1;
    end
    else if(read_weight_cnt == 10) begin
        read_weight <= 0;
    end
    else begin
        read_weight <= read_weight;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_weight_cnt <= 0;
    end
    else if(read_weight) begin
        read_weight_cnt <= read_weight_cnt + 1;
    end
    else begin
        read_weight_cnt <= 0;
    end
end

// write image
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        image_input_accum <= 64'd0;
    end
    else if (write_image && in_valid_reg) begin
        image_input_accum <= {image_input_accum[55:0], in_data_reg};
    end
    else if (state == SUB && sub_cnt == 2) begin
        if(mode_reg == 2) begin
            if(right_side)
                image_input_accum <= {image_read_data_r[63:32], sub_res_clip[4], sub_res_clip[5], sub_res_clip[6], sub_res_clip[7]};
            else begin
                image_input_accum <= {sub_res_clip[0], sub_res_clip[1], sub_res_clip[2], sub_res_clip[3], image_read_data_r[31:0]};
            end
        end
        else 
        image_input_accum <= {sub_res_clip[0], sub_res_clip[1], sub_res_clip[2], sub_res_clip[3], sub_res_clip[4], sub_res_clip[5], sub_res_clip[6], sub_res_clip[7]};
    end
    else begin
        image_input_accum <= image_input_accum;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        image_web <= 1'b1;
    end
    else if (write_img_cnt[2:0] == 3'd7) begin
        image_web <= 1'b0;
    end
    else if (state == SUB && sub_cnt == 2) begin
        image_web <= 1'b0;
    end
    else begin
        image_web <= 1'b1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_img_addr <= 9'd0;
    end
    else if(output_check_fetch) begin
        if(out_check_cnt == 3'd7) begin
            in_img_addr <= in_img_addr + 1'b1;
        end
        else begin
            in_img_addr <= in_img_addr;
        end
    end
    else if (in_valid_reg && write_image) begin
        if (image_web == 0)
            in_img_addr <= in_img_addr + 1'b1;
        else
            in_img_addr <= in_img_addr;
    end
    else if(refetch_img_data) begin
        if(refetch_cnt == 3'd7) begin
            in_img_addr <= in_img_addr + 1'b1;
        end
        else begin
            in_img_addr <= in_img_addr;
        end
    end
    else if(state == SUB || state == CALC) begin
        if(sub_cnt == 3) begin
            if(mode_reg == 2) begin
                in_img_addr <= img_next_col ? img_next_fetch_idx : in_img_addr + 8;
            end
            else in_img_addr <= in_img_addr + 1;
        end
        else begin
            in_img_addr <= in_img_addr;
        end
    end
    else begin
        in_img_addr <= 0;
    end
end
assign img_next_col = in_img_addr > 503;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        img_next_fetch_idx <= 0;
    end
    else if(state == SUB && img_next_col && sub_cnt == 2 && right_side == 1)begin
        // if(right_side == 1 || mode_reg < 2)
            img_next_fetch_idx <= img_next_fetch_idx + 1;
        // else 
        //     img_next_fetch_idx <= img_next_fetch_idx;
    end
    else begin
        img_next_fetch_idx <= img_next_fetch_idx;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        right_side <= 0;
    end
    else if(sub_cnt2 == sub_end_point && sub_cnt == 3)begin
        right_side <= ~right_side;
    end
    else begin
        right_side <= right_side;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        image_read_data_r <= 0;
    end
    else begin
        image_read_data_r <= image_read_data;
    end
end

Linear_512X64X1BM1 in_img_sram (
    .CK(clk), .WEB(image_web), .OE(1'b1), .CS(1'b1),
    .A0(in_img_addr[0]), .A1(in_img_addr[1]), .A2(in_img_addr[2]), .A3(in_img_addr[3]), .A4(in_img_addr[4]), .A5(in_img_addr[5]), .A6(in_img_addr[6]), .A7(in_img_addr[7]), .A8(in_img_addr[8]), 
    .DI0(image_input_accum[0]),  .DI1(image_input_accum[1]),  .DI2(image_input_accum[2]),  .DI3(image_input_accum[3]),  .DI4(image_input_accum[4]),  .DI5(image_input_accum[5]),  .DI6(image_input_accum[6]),  .DI7(image_input_accum[7]),
    .DI8(image_input_accum[8]),  .DI9(image_input_accum[9]),  .DI10(image_input_accum[10]), .DI11(image_input_accum[11]), .DI12(image_input_accum[12]), .DI13(image_input_accum[13]), .DI14(image_input_accum[14]), .DI15(image_input_accum[15]),
    .DI16(image_input_accum[16]), .DI17(image_input_accum[17]), .DI18(image_input_accum[18]), .DI19(image_input_accum[19]), .DI20(image_input_accum[20]), .DI21(image_input_accum[21]), .DI22(image_input_accum[22]), .DI23(image_input_accum[23]),
    .DI24(image_input_accum[24]), .DI25(image_input_accum[25]), .DI26(image_input_accum[26]), .DI27(image_input_accum[27]), .DI28(image_input_accum[28]), .DI29(image_input_accum[29]), .DI30(image_input_accum[30]), .DI31(image_input_accum[31]),
    .DI32(image_input_accum[32]), .DI33(image_input_accum[33]), .DI34(image_input_accum[34]), .DI35(image_input_accum[35]), .DI36(image_input_accum[36]), .DI37(image_input_accum[37]), .DI38(image_input_accum[38]), .DI39(image_input_accum[39]),
    .DI40(image_input_accum[40]), .DI41(image_input_accum[41]), .DI42(image_input_accum[42]), .DI43(image_input_accum[43]), .DI44(image_input_accum[44]), .DI45(image_input_accum[45]), .DI46(image_input_accum[46]), .DI47(image_input_accum[47]),
    .DI48(image_input_accum[48]), .DI49(image_input_accum[49]), .DI50(image_input_accum[50]), .DI51(image_input_accum[51]), .DI52(image_input_accum[52]), .DI53(image_input_accum[53]), .DI54(image_input_accum[54]), .DI55(image_input_accum[55]),
    .DI56(image_input_accum[56]), .DI57(image_input_accum[57]), .DI58(image_input_accum[58]), .DI59(image_input_accum[59]), .DI60(image_input_accum[60]), .DI61(image_input_accum[61]), .DI62(image_input_accum[62]), .DI63(image_input_accum[63]),
    .DO0(image_read_data[0]),  .DO1(image_read_data[1]),  .DO2(image_read_data[2]),  .DO3(image_read_data[3]),  .DO4(image_read_data[4]),  .DO5(image_read_data[5]),  .DO6(image_read_data[6]),  .DO7(image_read_data[7]),
    .DO8(image_read_data[8]),  .DO9(image_read_data[9]),  .DO10(image_read_data[10]), .DO11(image_read_data[11]), .DO12(image_read_data[12]), .DO13(image_read_data[13]), .DO14(image_read_data[14]), .DO15(image_read_data[15]),
    .DO16(image_read_data[16]), .DO17(image_read_data[17]), .DO18(image_read_data[18]), .DO19(image_read_data[19]), .DO20(image_read_data[20]), .DO21(image_read_data[21]), .DO22(image_read_data[22]), .DO23(image_read_data[23]),
    .DO24(image_read_data[24]), .DO25(image_read_data[25]), .DO26(image_read_data[26]), .DO27(image_read_data[27]), .DO28(image_read_data[28]), .DO29(image_read_data[29]), .DO30(image_read_data[30]), .DO31(image_read_data[31]),
    .DO32(image_read_data[32]), .DO33(image_read_data[33]), .DO34(image_read_data[34]), .DO35(image_read_data[35]), .DO36(image_read_data[36]), .DO37(image_read_data[37]), .DO38(image_read_data[38]), .DO39(image_read_data[39]),
    .DO40(image_read_data[40]), .DO41(image_read_data[41]), .DO42(image_read_data[42]), .DO43(image_read_data[43]), .DO44(image_read_data[44]), .DO45(image_read_data[45]), .DO46(image_read_data[46]), .DO47(image_read_data[47]),
    .DO48(image_read_data[48]), .DO49(image_read_data[49]), .DO50(image_read_data[50]), .DO51(image_read_data[51]), .DO52(image_read_data[52]), .DO53(image_read_data[53]), .DO54(image_read_data[54]), .DO55(image_read_data[55]),
    .DO56(image_read_data[56]), .DO57(image_read_data[57]), .DO58(image_read_data[58]), .DO59(image_read_data[59]), .DO60(image_read_data[60]), .DO61(image_read_data[61]), .DO62(image_read_data[62]), .DO63(image_read_data[63])
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_image <= 0;
    end
    else if(in_valid_reg && write_weight_cnt == 1311) begin
        write_image <= 1;
    end
    // else if(write_image && write_img_cnt == 4095) begin
    //     write_image <= 0;
    // end
    else begin
        write_image <= write_image;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        write_img_cnt <= 0;
    end
    else if(write_image == 1 && in_valid_reg) begin
        write_img_cnt <= write_img_cnt + 1;
    end
    else begin
        write_img_cnt <= 0;
    end
end

// convolution
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_conv <= 0;
    end
    else if(write_img_cnt == 65) begin
        start_conv <= 1;
    end
    else if(iter2_wait_conv_cnt == 68) begin
        start_conv <= 1;
    end
    else if(read_weight && read_weight_cnt == 10 && conv_iter2 && curr_tpu_iter < 6) begin
        start_conv <= 1;
    end
    else if(conv_cnt == 4095 || conv_write_cnt == 4096)begin
        start_conv <= 0;
    end
    else begin 
        start_conv <= start_conv;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_conv_down <= 0;
    end
    else if(curr_tpu_iter == 5 && tpu_result_cnt == 64) begin
        start_conv_down <= 1;
    end
    else if(conv_write_cnt_down == 4095)begin
        start_conv_down <= 0;
    end
    else begin 
        start_conv_down <= start_conv_down;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_write_cnt_down <= 0;
    end
    else if(partial_sram0_web == 0 || partial_sram1_web == 0) begin
        conv_write_cnt_down <= conv_write_cnt_down + 1;
    end
    else if(curr_tpu_iter == 7)begin 
        conv_write_cnt_down <= 0;
    end
    else begin 
        conv_write_cnt_down <= conv_write_cnt_down;
    end
end
always @(*) begin
        start_conv_down_calc = (start_conv_down && conv_cnt_down >= 20);
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_down_iter <= 0;
    end
    else if(conv_cnt_down == 280)begin
        conv_down_iter <= conv_down_iter == 15 ? 15 : conv_down_iter + 1;
    end
    else if (curr_tpu_iter == 0)begin
        conv_down_iter <= 0;
    end
    else begin 
        conv_down_iter <= conv_down_iter;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_partial_sram_sel <= 0;
    end
    else if(conv_cnt_down == 280)begin
        conv_partial_sram_sel <= ~conv_partial_sram_sel;
    end
    else begin 
        conv_partial_sram_sel <= conv_partial_sram_sel;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_down_ch <= 0;
    end
    else if(conv_down_iter == 7 && v_data_addr == 510)begin
        conv_down_ch <= 1;
    end
    else if(conv_write_cnt_down == 4095)begin
        conv_down_ch <= 0;
    end
    else begin 
        conv_down_ch <= conv_down_ch;
    end
end

// partial result sram ctrl
// partial sram0 input data
always @(*) begin
    partial_sram0_input_accum = conv_down_iter == 15 ? $signed(accum_result_clip) : accum_result_reg;
end

// partial sram0 web
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_sram0_web <= 1;
    end
    else if(conv_partial_sram_sel == 1 && conv_cnt_down >= 24 && conv_cnt_down <= 279 && conv_down_iter < 15) begin
        partial_sram0_web <= 0;
    end
    else if(conv_partial_sram_sel == 1 && conv_cnt_down >= 25 && conv_down_iter == 15) begin
        partial_sram0_web <= 0;
    end
    else begin
        partial_sram0_web <= 1;
    end
end

// partial sram0 addr
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_sram0_addr <= 0;
    end
    // else if(output_check_fetch) begin
    //     partial_sram0_addr <= partial_sram0_addr + 1;
    // end
    else if(state == CALC && calc_cnt <= 15) begin
        if(mode_reg == 2) begin
            partial_sram0_addr <= partial_next_col ? partial_next_fetch_idx : partial_sram0_addr + 16;
        end
        else begin
            partial_sram0_addr <= partial_sram0_addr + 1;
        end
    end
    else if(conv_partial_sram_sel == 0 && conv_cnt_down >= 22 && conv_cnt_down <= 277) begin
        partial_sram0_addr <= partial_sram0_addr + 1;
    end
    else if(conv_partial_sram_sel == 1 && conv_cnt_down >= 25 && conv_cnt_down <= 280 && conv_down_iter < 15) begin
        partial_sram0_addr <= partial_sram0_addr + 1;
    end
    else if(conv_partial_sram_sel == 1 && conv_cnt_down >= 26 && conv_down_iter == 15) begin
        partial_sram0_addr <= partial_sram0_addr + 1;
    end
    else if(conv_write_cnt_down == 4095) begin
        partial_sram0_addr <= 0;
    end
    else begin
        partial_sram0_addr <= partial_sram0_addr;
    end
end
assign partial_next_col = partial_sram0_addr > 239;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_next_fetch_idx <= 1;
    end
    else if(state == CALC && calc_cnt == 15 && partial_next_col && mode_reg == 2)begin
        partial_next_fetch_idx <= partial_next_fetch_idx + 1;
    end
    else begin
        partial_next_fetch_idx <= partial_next_fetch_idx;
    end
end
// partial sram0 read data reg
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_sram0_read_data_r <= 0;
    end
    else begin
        partial_sram0_read_data_r <= partial_sram0_read_data;
    end
end

always @(*) begin
    partial_sram1_input_accum = accum_result_reg;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_sram1_web <= 1;
    end
    else if(conv_partial_sram_sel == 0 && conv_cnt_down >= 24 && conv_cnt_down <= 279) begin
        partial_sram1_web <= 0;
    end
    else begin
        partial_sram1_web <= 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_sram1_addr <= 0;
    end
    else if(conv_partial_sram_sel == 1 && conv_cnt_down >= 22 && conv_cnt_down <= 277) begin
        partial_sram1_addr <= partial_sram1_addr + 1;
    end
    else if(conv_partial_sram_sel == 0 && conv_cnt_down >= 25 && conv_cnt_down <= 280) begin
        partial_sram1_addr <= partial_sram1_addr + 1;
    end
    else begin
        partial_sram1_addr <= partial_sram1_addr;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_sram1_read_data_r <= 0;
    end
    else begin
        partial_sram1_read_data_r <= partial_sram1_read_data;
    end
end


weight_256X32X1BM1 partial_sram0 (
    .CK(clk), .WEB(partial_sram0_web), .OE(1'b1), .CS(1'b1),
    .A0(partial_sram0_addr[0]), .A1(partial_sram0_addr[1]), .A2(partial_sram0_addr[2]), .A3(partial_sram0_addr[3]),
    .A4(partial_sram0_addr[4]), .A5(partial_sram0_addr[5]), .A6(partial_sram0_addr[6]), .A7(partial_sram0_addr[7]),
    .DI0(partial_sram0_input_accum[0]), .DI1(partial_sram0_input_accum[1]), .DI2(partial_sram0_input_accum[2]), .DI3(partial_sram0_input_accum[3]),
    .DI4(partial_sram0_input_accum[4]), .DI5(partial_sram0_input_accum[5]), .DI6(partial_sram0_input_accum[6]), .DI7(partial_sram0_input_accum[7]),
    .DI8(partial_sram0_input_accum[8]), .DI9(partial_sram0_input_accum[9]), .DI10(partial_sram0_input_accum[10]), .DI11(partial_sram0_input_accum[11]),
    .DI12(partial_sram0_input_accum[12]), .DI13(partial_sram0_input_accum[13]), .DI14(partial_sram0_input_accum[14]), .DI15(partial_sram0_input_accum[15]),
    .DI16(partial_sram0_input_accum[16]), .DI17(partial_sram0_input_accum[17]), .DI18(partial_sram0_input_accum[18]), .DI19(partial_sram0_input_accum[19]),
    .DI20(partial_sram0_input_accum[20]), .DI21(partial_sram0_input_accum[21]), .DI22(partial_sram0_input_accum[22]), .DI23(partial_sram0_input_accum[23]),
    .DI24(partial_sram0_input_accum[24]), .DI25(partial_sram0_input_accum[25]), .DI26(partial_sram0_input_accum[26]), .DI27(partial_sram0_input_accum[27]),
    .DI28(partial_sram0_input_accum[28]), .DI29(partial_sram0_input_accum[29]), .DI30(partial_sram0_input_accum[30]), .DI31(partial_sram0_input_accum[31]),
    .DO0(partial_sram0_read_data[0]), .DO1(partial_sram0_read_data[1]), .DO2(partial_sram0_read_data[2]), .DO3(partial_sram0_read_data[3]),
    .DO4(partial_sram0_read_data[4]), .DO5(partial_sram0_read_data[5]), .DO6(partial_sram0_read_data[6]), .DO7(partial_sram0_read_data[7]),
    .DO8(partial_sram0_read_data[8]), .DO9(partial_sram0_read_data[9]), .DO10(partial_sram0_read_data[10]), .DO11(partial_sram0_read_data[11]),
    .DO12(partial_sram0_read_data[12]), .DO13(partial_sram0_read_data[13]), .DO14(partial_sram0_read_data[14]), .DO15(partial_sram0_read_data[15]),
    .DO16(partial_sram0_read_data[16]), .DO17(partial_sram0_read_data[17]), .DO18(partial_sram0_read_data[18]), .DO19(partial_sram0_read_data[19]),
    .DO20(partial_sram0_read_data[20]), .DO21(partial_sram0_read_data[21]), .DO22(partial_sram0_read_data[22]), .DO23(partial_sram0_read_data[23]),
    .DO24(partial_sram0_read_data[24]), .DO25(partial_sram0_read_data[25]), .DO26(partial_sram0_read_data[26]), .DO27(partial_sram0_read_data[27]),
    .DO28(partial_sram0_read_data[28]), .DO29(partial_sram0_read_data[29]), .DO30(partial_sram0_read_data[30]), .DO31(partial_sram0_read_data[31])
);

weight_256X32X1BM1 partial_sram1 (
    .CK(clk), .WEB(partial_sram1_web), .OE(1'b1), .CS(1'b1),
    .A0(partial_sram1_addr[0]), .A1(partial_sram1_addr[1]), .A2(partial_sram1_addr[2]), .A3(partial_sram1_addr[3]),
    .A4(partial_sram1_addr[4]), .A5(partial_sram1_addr[5]), .A6(partial_sram1_addr[6]), .A7(partial_sram1_addr[7]),
    .DI0(partial_sram1_input_accum[0]), .DI1(partial_sram1_input_accum[1]), .DI2(partial_sram1_input_accum[2]), .DI3(partial_sram1_input_accum[3]),
    .DI4(partial_sram1_input_accum[4]), .DI5(partial_sram1_input_accum[5]), .DI6(partial_sram1_input_accum[6]), .DI7(partial_sram1_input_accum[7]),
    .DI8(partial_sram1_input_accum[8]), .DI9(partial_sram1_input_accum[9]), .DI10(partial_sram1_input_accum[10]), .DI11(partial_sram1_input_accum[11]),
    .DI12(partial_sram1_input_accum[12]), .DI13(partial_sram1_input_accum[13]), .DI14(partial_sram1_input_accum[14]), .DI15(partial_sram1_input_accum[15]),
    .DI16(partial_sram1_input_accum[16]), .DI17(partial_sram1_input_accum[17]), .DI18(partial_sram1_input_accum[18]), .DI19(partial_sram1_input_accum[19]),
    .DI20(partial_sram1_input_accum[20]), .DI21(partial_sram1_input_accum[21]), .DI22(partial_sram1_input_accum[22]), .DI23(partial_sram1_input_accum[23]),
    .DI24(partial_sram1_input_accum[24]), .DI25(partial_sram1_input_accum[25]), .DI26(partial_sram1_input_accum[26]), .DI27(partial_sram1_input_accum[27]),
    .DI28(partial_sram1_input_accum[28]), .DI29(partial_sram1_input_accum[29]), .DI30(partial_sram1_input_accum[30]), .DI31(partial_sram1_input_accum[31]),
    .DO0(partial_sram1_read_data[0]), .DO1(partial_sram1_read_data[1]), .DO2(partial_sram1_read_data[2]), .DO3(partial_sram1_read_data[3]),
    .DO4(partial_sram1_read_data[4]), .DO5(partial_sram1_read_data[5]), .DO6(partial_sram1_read_data[6]), .DO7(partial_sram1_read_data[7]),
    .DO8(partial_sram1_read_data[8]), .DO9(partial_sram1_read_data[9]), .DO10(partial_sram1_read_data[10]), .DO11(partial_sram1_read_data[11]),
    .DO12(partial_sram1_read_data[12]), .DO13(partial_sram1_read_data[13]), .DO14(partial_sram1_read_data[14]), .DO15(partial_sram1_read_data[15]),
    .DO16(partial_sram1_read_data[16]), .DO17(partial_sram1_read_data[17]), .DO18(partial_sram1_read_data[18]), .DO19(partial_sram1_read_data[19]),
    .DO20(partial_sram1_read_data[20]), .DO21(partial_sram1_read_data[21]), .DO22(partial_sram1_read_data[22]), .DO23(partial_sram1_read_data[23]),
    .DO24(partial_sram1_read_data[24]), .DO25(partial_sram1_read_data[25]), .DO26(partial_sram1_read_data[26]), .DO27(partial_sram1_read_data[27]),
    .DO28(partial_sram1_read_data[28]), .DO29(partial_sram1_read_data[29]), .DO30(partial_sram1_read_data[30]), .DO31(partial_sram1_read_data[31])
);

// interpolation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end
always @(*) begin
    case(state)
        IDLE: begin
            if(conv_write_cnt_down == 4095) begin
                next_state = CALC;
            end
            else begin
                next_state = IDLE;
            end
        end
        CALC:begin
            if(calc_cnt == 19) begin
                next_state = SUB;
            end
            else begin
                next_state = CALC;
            end
        end
        SUB:begin
            if(sub_cnt2 == sub_end_point && sub_cnt == 3) begin
                if(interpolation_iter == 15) begin
                    next_state = IDLE;
                end
                else 
                    next_state = CALC;
            end
            else begin
                next_state = SUB;
            end
        end
        default: next_state = IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_data <= 0;
        prev_data2 <= 0;
        diff <= 0;
        t0 <= 0;
        t1 <= 0;
        t2 <= 0;
        t3 <= 0;
        t_shift_tmp <= 0;
    end
    else begin 
        prev_data <= partial_sram0_read_data_r[7:0];
        prev_data2 <= prev_data;
        diff <= calc_cnt == 18 ? diff : $signed({1'b0, partial_sram0_read_data_r[7:0]}) - $signed({1'b0, prev_data});
        if(mode_reg == 0) begin
            t0 <= $signed({1'b0, prev_data2});
            t1 <= $signed({1'b0, prev_data2});
            t2 <= $signed({1'b0, prev_data2});
            t3 <= $signed({1'b0, prev_data2});
        end
        else begin
            t0 <= $signed({1'b0, prev_data2});
            t1 <= $signed({1'b0, prev_data2}) + diff_shift2;
            t2 <= $signed({1'b0, prev_data2}) + diff_p2;
            t3 <= $signed({1'b0, prev_data2}) + diff_p3;
        end
        t_shift_tmp <= {t0_shift, t1_shift, t2_shift, t3_shift};
    end
end
assign diff_shift2 = diff >>> 2; 
assign diff_p2 = diff_shift2 <<< 1;    
assign diff_p3 = diff_shift2 + diff_p2; 

assign t0_shift = t0_clip >> 3;
assign t1_shift = t1_clip >> 3;
assign t2_shift = t2_clip >> 3;
assign t3_shift = t3_clip >> 3;
assign t0_clip = t0[9] ? 8'd0 : (t0 > 255 ? 8'd255 : t0[7:0]);
assign t1_clip = t1[9] ? 8'd0 : (t1 > 255 ? 8'd255 : t1[7:0]);
assign t2_clip = t2[9] ? 8'd0 : (t2 > 255 ? 8'd255 : t2[7:0]);
assign t3_clip = t3[9] ? 8'd0 : (t3 > 255 ? 8'd255 : t3[7:0]);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        SR_inter_result <= '{default:0};
    end
    else if(calc_cnt >= 5)begin
        SR_inter_result[15] <= {t0_shift, t1_shift, t2_shift, t3_shift};
        SR_inter_result[14:0] <= SR_inter_result[15:1];
    end
    else if(state == SUB && sub_cnt == 2) begin
        if(mode_reg == 2) begin
            if(sub_cnt2[1:0] == 3) begin
                SR_inter_result[15] <= SR_inter_result[0];
                SR_inter_result[14:0] <= SR_inter_result[15:1];
            end
            else begin
                SR_inter_result[15:0] <= SR_inter_result[15:0];
            end
        end
        else begin
            SR_inter_result[15:14] <= SR_inter_result[1:0];
            SR_inter_result[13:0] <= SR_inter_result[15:2];
        end
    end
    else begin 
        SR_inter_result[15:0] <= SR_inter_result[15:0];
    end
end
always @(*) begin
    sub_end_point = mode_reg == 2 ? 63 : 31;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sub_cnt <= 0;
        sub_cnt2 <= 0;
    end
    else if(state == SUB)begin
        sub_cnt <= sub_cnt + 1;
        sub_cnt2 <= sub_cnt == 3 ? sub_cnt2 == sub_end_point ? 0 : sub_cnt2 + 1 : sub_cnt2;
    end
    else begin 
        sub_cnt <= 0;
        sub_cnt2 <= sub_cnt2;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        calc_cnt <= 0;
    end
    else if(state == CALC)begin
        calc_cnt <= calc_cnt + 1;
    end
    else begin 
        calc_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        interpolation_iter <= 0;
    end
    else if(sub_cnt2 == sub_end_point && sub_cnt == 3)begin
        interpolation_iter <= interpolation_iter + 1;
    end
    else if(state == IDLE)begin 
        interpolation_iter <= 0;
    end
    else begin 
        interpolation_iter <= interpolation_iter;
    end
end
always @(*) begin
    case(sub_cnt2[1:0]) 
        2'b00: begin
            SR_inter_result_sel = SR_inter_result[0][19:15];
        end
        2'b01: begin
            SR_inter_result_sel = SR_inter_result[0][14:10];
        end
        2'b10: begin
            SR_inter_result_sel = SR_inter_result[0][9:5];
        end
        2'b11: begin
            SR_inter_result_sel = SR_inter_result[0][4:0];
        end
        default: begin
            SR_inter_result_sel = 0;
        end
    
    endcase
end

always @(*) begin
    if(mode_reg == 2) begin
        sub_res[0] = $signed({1'b0, image_read_data_r[63:56]} )- $signed({4'b0, SR_inter_result_sel});
        sub_res[1] = $signed({1'b0, image_read_data_r[55:48]}) - $signed({4'b0, SR_inter_result_sel});
        sub_res[2] = $signed({1'b0, image_read_data_r[47:40]}) - $signed({4'b0, SR_inter_result_sel});
        sub_res[3] = $signed({1'b0, image_read_data_r[39:32]}) - $signed({4'b0, SR_inter_result_sel});
        sub_res[4] = $signed({1'b0, image_read_data_r[31:24]}) - $signed({4'b0, SR_inter_result_sel});
        sub_res[5] = $signed({1'b0, image_read_data_r[23:16]}) - $signed({4'b0, SR_inter_result_sel});
        sub_res[6] = $signed({1'b0, image_read_data_r[15:8]}) - $signed({4'b0, SR_inter_result_sel});
        sub_res[7] = $signed({1'b0, image_read_data_r[7:0]}) - $signed({4'b0, SR_inter_result_sel});
    end
    else begin
        sub_res[0] = $signed({1'b0, image_read_data_r[63:56]} )- $signed({4'b0, SR_inter_result[0][19:15]});
        sub_res[1] = $signed({1'b0, image_read_data_r[55:48]}) - $signed({4'b0, SR_inter_result[0][14:10]});
        sub_res[2] = $signed({1'b0, image_read_data_r[47:40]}) - $signed({4'b0, SR_inter_result[0][9:5]});
        sub_res[3] = $signed({1'b0, image_read_data_r[39:32]}) - $signed({4'b0, SR_inter_result[0][4:0]});
        sub_res[4] = $signed({1'b0, image_read_data_r[31:24]}) - $signed({4'b0, SR_inter_result[1][19:15]});
        sub_res[5] = $signed({1'b0, image_read_data_r[23:16]}) - $signed({4'b0, SR_inter_result[1][14:10]});
        sub_res[6] = $signed({1'b0, image_read_data_r[15:8]}) - $signed({4'b0, SR_inter_result[1][9:5]});
        sub_res[7] = $signed({1'b0, image_read_data_r[7:0]}) - $signed({4'b0, SR_inter_result[1][4:0]});
    end

    sub_res_clip[0] = sub_res[0][8] ? 0 : sub_res[0][7:0];
    sub_res_clip[1] = sub_res[1][8] ? 0 : sub_res[1][7:0];
    sub_res_clip[2] = sub_res[2][8] ? 0 : sub_res[2][7:0];
    sub_res_clip[3] = sub_res[3][8] ? 0 : sub_res[3][7:0];
    sub_res_clip[4] = sub_res[4][8] ? 0 : sub_res[4][7:0];
    sub_res_clip[5] = sub_res[5][8] ? 0 : sub_res[5][7:0];
    sub_res_clip[6] = sub_res[6][8] ? 0 : sub_res[6][7:0];
    sub_res_clip[7] = sub_res[7][8] ? 0 : sub_res[7][7:0];
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_iter2 <= 0;
    end
    else if(start_conv &&conv_cnt == 4095)begin
        conv_iter2 <= ~conv_iter2;
    end
    else if(curr_tpu_iter == 7) begin
        conv_iter2 <= 0;
    end
    else begin 
        conv_iter2 <= conv_iter2;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_cnt <= 0;
    end
    else if(start_conv) begin
        conv_cnt <= conv_cnt + 1;
    end
    else begin
        conv_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_cnt_down <= 0;
    end
    else if(start_conv_down) begin
        conv_cnt_down <= conv_cnt_down == 280 ? 0 : conv_cnt_down + 1;
    end
    else begin
        conv_cnt_down <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0;i <= 71;i = i + 1) begin
            SR_CONV_weight[i] <= 0;
        end
    end
    else if(read_weight) begin
        SR_CONV_weight[64] <= weight_read_data_r[31:28];
        SR_CONV_weight[65] <= weight_read_data_r[27:24];
        SR_CONV_weight[66] <= weight_read_data_r[23:20];
        SR_CONV_weight[67] <= weight_read_data_r[19:16];
        SR_CONV_weight[68] <= weight_read_data_r[15:12];
        SR_CONV_weight[69] <= weight_read_data_r[11:8];
        SR_CONV_weight[70] <= weight_read_data_r[7:4];
        SR_CONV_weight[71] <= weight_read_data_r[3:0];
        // SR_CONV_weight[63:0] <= SR_CONV_weight[71:8];
        for (i = 0; i <= 63; i = i + 1) begin
            SR_CONV_weight[i] <= SR_CONV_weight[i+8];
        end
    end
    else begin
        // SR_CONV_weight[71:0] <= SR_CONV_weight[71:0];
        for(i = 0;i <= 71;i = i + 1) begin
            SR_CONV_weight[i] <= SR_CONV_weight[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0;i <= 130;i = i + 1) begin
            SR_CONV_data[i] <= 0;
        end
    end
    else if(write_image == 1 && in_valid_reg) begin
        SR_CONV_data[130] <= in_data_reg;
        // SR_CONV_data[129:0] <= SR_CONV_data[130:1];
        for (i = 0; i <= 129; i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i+1];
        end
    end
    else if(refetch_img_data || start_conv) begin
        SR_CONV_data[130] <= refetch_data_shift[63:56];
        // SR_CONV_data[129:0] <= SR_CONV_data[130:1];
        for (i = 0; i <= 129; i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i+1];
        end
    end
    else if(start_conv_down) begin
        case(conv_down_iter[2:0])
            0: SR_CONV_data[130] <= v_data_read_data_r[63:56];
            1: SR_CONV_data[130] <= v_data_read_data_r[55:48];
            2: SR_CONV_data[130] <= v_data_read_data_r[47:40];
            3: SR_CONV_data[130] <= v_data_read_data_r[39:32];
            4: SR_CONV_data[130] <= v_data_read_data_r[31:24];
            5: SR_CONV_data[130] <= v_data_read_data_r[23:16];
            6: SR_CONV_data[130] <= v_data_read_data_r[15:8];
            7: SR_CONV_data[130] <= v_data_read_data_r[7:0];
            default: SR_CONV_data[130] <= 0;
        endcase
        for (i = 115; i <= 129; i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i+1];
        end
        SR_CONV_data[66] <= SR_CONV_data[115];
        for (i = 51; i <= 65; i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i+1];
        end
        SR_CONV_data[2] <= SR_CONV_data[51];
        SR_CONV_data[0] <= SR_CONV_data[1];
        SR_CONV_data[1] <= SR_CONV_data[2];
        for (i = 3; i <= 50; i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i];
        end
        for (i = 67; i <= 114; i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i];
        end
    end
    else begin
        // SR_CONV_data[130:0] <= SR_CONV_data[130:0];
        for(i = 0;i <= 130;i = i + 1) begin
            SR_CONV_data[i] <= SR_CONV_data[i];
        end
    end
end

always @(*) begin
    H0 = SR_CONV_data[64];
    Center = SR_CONV_data[65];
    H1 = SR_CONV_data[66];
    V0 = SR_CONV_data[1];
    V1 = SR_CONV_data[129];
    D00 = SR_CONV_data[0];
    D01 = SR_CONV_data[130];
    D10 = SR_CONV_data[2];
    D11 = SR_CONV_data[128];
end

assign X_is_zero = X_r == 0;
assign Y_is_zero = Y_r == 0;
assign X_is_bound = start_conv_down ? X_r == 15 : X_r == 63;
assign Y_is_bound = start_conv_down ? Y_r == 15 : Y_r == 63;
always @(*) begin
    // Center
    mult_a_sel[4] = Center;
    // H0
    mult_a_sel[3] = X_is_zero ? 0 : H0;
    // H1
    mult_a_sel[5] = X_is_bound ? 0 : H1;
    // V0
    mult_a_sel[1] = Y_is_zero ? 0 : V0;
    // V1
    mult_a_sel[7] = Y_is_bound ? 0 : V1;
    // D00
    mult_a_sel[0] = (X_is_zero || Y_is_zero ) ? 0 : D00;
    // D01
    mult_a_sel[8] = 
                (X_is_bound || Y_is_bound )  ? 0 :  D01;
    // D10
    mult_a_sel[2] = (X_is_bound || Y_is_zero )  ? 0 : D10;
    // D11
    mult_a_sel[6] = (X_is_zero || Y_is_bound ) ? 0 :  D11;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        X_r <= 0;
        Y_r <= 0;
    end 
    else if(start_conv)begin
        X_r <= X_r + 1;
        Y_r <= X_r == 63 ? Y_r + 1 : Y_r;
    end 
    else if(start_conv_down_calc) begin
        if(conv_cnt_down == 280) begin
            X_r <= 0;
            Y_r <= 0;
        end else begin
            X_r <= X_r == 15 ? 0 : X_r + 1;
            Y_r <= X_r == 15 ? (Y_r == 15 ? 0 : Y_r + 1) 
                                    : Y_r;
        end
    end
    else  begin
        X_r <= 0;
        Y_r <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j = 0;j <= 8;j = j + 1) begin
            mult_a[j] <= 0;
        end
    end
     else begin
        for(j = 0;j <= 8;j = j + 1) begin
            mult_a[j] <= mult_a_sel[j];
        end
     end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (k = 0; k <= 8; k = k + 1) begin
            for(j = 0;j <= 7;j = j + 1) begin
                mult_b[j][k] <= 0;
            end
        end
    end
     else begin
        // mult_b[0][8:0] <= SR_CONV_weight[8:0];
        // mult_b[1][8:0] <= SR_CONV_weight[17:9];
        // mult_b[2][8:0] <= SR_CONV_weight[26:18];
        // mult_b[3][8:0] <= SR_CONV_weight[35:27];
        // mult_b[4][8:0] <= SR_CONV_weight[44:36];
        // mult_b[5][8:0] <= SR_CONV_weight[53:45];
        // mult_b[6][8:0] <= SR_CONV_weight[62:54];
        // mult_b[7][8:0] <= SR_CONV_weight[71:63];
        for (k = 0; k <= 8; k = k + 1) begin
            mult_b[0][k] <= SR_CONV_weight[k];
            mult_b[1][k] <= SR_CONV_weight[k+9];
            mult_b[2][k] <= SR_CONV_weight[k+18];
            mult_b[3][k] <= SR_CONV_weight[k+27];
            mult_b[4][k] <= SR_CONV_weight[k+36];
            mult_b[5][k] <= SR_CONV_weight[k+45];
            mult_b[6][k] <= SR_CONV_weight[k+54];
            mult_b[7][k] <= SR_CONV_weight[k+63];
        end
     end
end

generate
    for(jdx = 0;jdx <= 7;jdx = jdx + 1)begin
        for(idx = 0;idx <= 8;idx = idx + 1) begin
            mult_conv mult0(
                .a(mult_a[idx]), 
                .b(mult_b[jdx][idx]),  
                .result(mult_result[jdx][idx]));
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(j = 0;j <= 7;j = j + 1) begin
            for(k = 0;k <= 8;k = k + 1) begin
                mult_result_r[j][k] <= 0;
            end
        end
    end
    else begin
        for(j = 0;j <= 7;j = j + 1) begin
            for(k = 0;k <= 8;k = k + 1) begin
                mult_result_r[j][k] <= mult_result[j][k];
            end
        end
    end
end
always @(*) begin
    case(conv_down_iter[2:0])
        0: three_add1_sel = three_add1[0];
        1: three_add1_sel = three_add1[1];
        2: three_add1_sel = three_add1[2];
        3: three_add1_sel = three_add1[3];
        4: three_add1_sel = three_add1[4];
        5: three_add1_sel = three_add1[5];
        6: three_add1_sel = three_add1[6];
        7: three_add1_sel = three_add1[7];
        default: three_add1_sel = 0;
    endcase
end
always @(*) begin
    if(conv_down_iter == 0) begin
        partial_result_sel = 0;
    end
    else if(conv_partial_sram_sel == 0) begin
        partial_result_sel = partial_sram0_read_data_r;
    end
    else begin
        partial_result_sel = partial_sram1_read_data_r;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(j = 0;j <= 7;j = j + 1) begin
            three_add0[j][0] <= 0;
            three_add0[j][1] <= 0;
            three_add0[j][2] <= 0;
            three_add1[j] <= 0;
            conv_result_shift[j] <= 0;
        end
        accum_result_reg <= 0;
        accum_result_clip <= 0;
    end
    else begin
        for(j = 0;j <= 7;j = j + 1) begin
            three_add0[j][0] <= mult_result_r[j][0] + mult_result_r[j][1] + mult_result_r[j][2];
            three_add0[j][1] <= mult_result_r[j][3] + mult_result_r[j][4] + mult_result_r[j][5];
            three_add0[j][2] <= mult_result_r[j][6] + mult_result_r[j][7] + mult_result_r[j][8];
            three_add1[j] <= three_add0[j][0] + three_add0[j][1] + three_add0[j][2];
            conv_result_shift[j] <= three_add1[j] >>> 6;
        end
        accum_result_reg <= three_add1_sel + partial_result_sel;
        accum_result_clip <= accum_result_reg_shift > 127 ? 8'hFF 
                                                        : (accum_result_reg_shift < -128 ? 8'h00 
                                                            : accum_result_reg_shift + 128);
    end
end

assign accum_result_reg_shift = (accum_result_reg >>> 6);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_stage1_valid <= 0;
        conv_stage2 <= 0;
        conv_stage3 <= 0;
        conv_stage4 <= 0;
        conv_stage5 <= 0;
    end
    else begin
        conv_stage1_valid <= (X_r[1:0] == 2'b0 && Y_r[1:0] == 2'b0 && start_conv) || (start_conv_down_calc);
        conv_stage2 <= conv_stage1_valid;
        conv_stage3 <= conv_stage2;
        conv_stage4 <= conv_stage3;
        conv_stage5 <= conv_stage4;
    end
end

// clip -128 ~ 127
always @(*) begin
    for (j = 0; j <= 7; j = j + 1) begin
        if(conv_result_shift[j] > 127) conv_result_clip[j] = 8'h7F;
        else if(conv_result_shift[j] < -128) conv_result_clip[j] = 8'h80;
        else conv_result_clip[j] = conv_result_shift[j][7:0];
    end
end
// refetch img data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        refetch_img_data <= 0;
    end
    else if(sub_cnt2 == sub_end_point && sub_cnt == 3 && interpolation_iter == 15 && iter != iter_reg) begin
        refetch_img_data <= 1;
    end
    // else if(curr_tpu_iter > 0) begin
    //     refetch_img_data <= 0;
    // end
    else if(conv_cnt == 4037) begin
        refetch_img_data <= 1;
    end
    else if(conv_write_cnt == 4096 || iter > 1 && conv_cnt == 4029) begin
        refetch_img_data <= 0;
    end
    else begin
        refetch_img_data <= refetch_img_data;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        refetch_cnt <= 0;
    end
    else if(refetch_img_data) begin
        refetch_cnt <= refetch_cnt + 1;
    end
    else begin
        refetch_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        refetch_data_shift <= 0;
    end
    else if(refetch_cnt == 2) begin
        refetch_data_shift <= image_read_data_r;
    end
    else begin
        refetch_data_shift <= {refetch_data_shift[55:0], 8'd0};
    end
end
// conv result sram ctrl
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_result_clip_reg <= 0;
    end
    else begin
        conv_result_clip_reg <= {conv_result_clip[0], conv_result_clip[1], conv_result_clip[2], conv_result_clip[3], conv_result_clip[4], conv_result_clip[5], conv_result_clip[6], conv_result_clip[7]};
    end
end
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         conv_result_accum <= 0;
//     end
//     else begin
//         conv_result_accum <= {conv_result_clip[0], conv_result_clip[1], conv_result_clip[2], conv_result_clip[3], conv_result_clip[4], conv_result_clip[5], conv_result_clip[6], conv_result_clip[7]};
//     end
// end
always @(*) begin
    if(curr_tpu_iter == 4) begin
        conv_result_accum =  tpu_result_data_clip_r;
    end
    else begin
        conv_result_accum = conv_result_clip_reg;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_result_web <= 1'b1;
    end
    else if (conv_stage5 && curr_tpu_iter == 0) begin
        conv_result_web <= 1'b0;
    end
    else if (start_write_q && curr_tpu_iter == 4) begin
        conv_result_web <= 1'b0;
    end
    else begin
        conv_result_web <= 1'b1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_write_cnt <= 1'b0;
    end
    else if (conv_stage5 && curr_tpu_iter == 0) begin
        conv_write_cnt <= conv_write_cnt + 12'd8;
    end
    else if(conv_write_cnt == 4096) begin
        conv_write_cnt <= 0;
    end
    else begin
        conv_write_cnt <= conv_write_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_result_addr <= 9'd0;
    end
    else if(tpu_result_cnt == 2 && curr_tpu_iter == 4) begin
        conv_result_addr <= 0;
    end
    // else if(output_check_fetch) begin
    //     if(out_check_cnt == 3'd7) begin
    //         conv_result_addr <= conv_result_addr + 1'b1;
    //     end
    //     else begin
    //         conv_result_addr <= conv_result_addr;
    //     end
    // end
    else if (curr_tpu_iter == 7 || curr_tpu_iter == 2 && tpu_result_cnt == 64) begin
        conv_result_addr <= 0;
    end
    else if (conv_result_web == 0) begin
        if(curr_tpu_iter == 4) begin
            conv_result_addr <= conv_result_addr == qkv_write_end_idx ? qkv_write_start_idx2 : conv_result_addr + 2;
        end
        else begin
            conv_result_addr <= conv_result_addr == 511 ? 0 : conv_result_addr + 2'd2;
        end
    end
    else if(start_conv && conv_cnt == 4095 && conv_iter2 == 0) begin
        conv_result_addr <= 9'd1;
    end
    else if(start_fetch_wire && curr_tpu_iter != 3 && curr_tpu_iter != 4) begin
        conv_result_addr <= fetch_start_idx;
    end
    else if(start_fetch && curr_tpu_iter != 3 && curr_tpu_iter != 4) begin
        conv_result_addr <= conv_result_addr == fetch_end_idx ? fetch_start_idx2 : conv_result_addr + 2;
    end
    // QKV sram 
    
    else if (tpu_data_valid2 && curr_tpu_iter == 4 && tpu_result_cnt == 0) begin
        conv_result_addr <= qkv_write_start_idx;
    end
    else begin
        conv_result_addr <= conv_result_addr;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        conv_result_read_data_r <= 0;
    end
    else begin
        conv_result_read_data_r <= conv_result_read_data;
    end
end
Linear_512X64X1BM1 conv_result_sram (
    .CK(clk), .WEB(conv_result_web), .OE(1'b1), .CS(1'b1),
    .A0(conv_result_addr[0]), .A1(conv_result_addr[1]), .A2(conv_result_addr[2]), .A3(conv_result_addr[3]), .A4(conv_result_addr[4]), .A5(conv_result_addr[5]), .A6(conv_result_addr[6]), .A7(conv_result_addr[7]), .A8(conv_result_addr[8]), 
    .DI0(conv_result_accum[0]),  .DI1(conv_result_accum[1]),  .DI2(conv_result_accum[2]),  .DI3(conv_result_accum[3]),  .DI4(conv_result_accum[4]),  .DI5(conv_result_accum[5]),  .DI6(conv_result_accum[6]),  .DI7(conv_result_accum[7]),
    .DI8(conv_result_accum[8]),  .DI9(conv_result_accum[9]),  .DI10(conv_result_accum[10]), .DI11(conv_result_accum[11]), .DI12(conv_result_accum[12]), .DI13(conv_result_accum[13]), .DI14(conv_result_accum[14]), .DI15(conv_result_accum[15]),
    .DI16(conv_result_accum[16]), .DI17(conv_result_accum[17]), .DI18(conv_result_accum[18]), .DI19(conv_result_accum[19]), .DI20(conv_result_accum[20]), .DI21(conv_result_accum[21]), .DI22(conv_result_accum[22]), .DI23(conv_result_accum[23]),
    .DI24(conv_result_accum[24]), .DI25(conv_result_accum[25]), .DI26(conv_result_accum[26]), .DI27(conv_result_accum[27]), .DI28(conv_result_accum[28]), .DI29(conv_result_accum[29]), .DI30(conv_result_accum[30]), .DI31(conv_result_accum[31]),
    .DI32(conv_result_accum[32]), .DI33(conv_result_accum[33]), .DI34(conv_result_accum[34]), .DI35(conv_result_accum[35]), .DI36(conv_result_accum[36]), .DI37(conv_result_accum[37]), .DI38(conv_result_accum[38]), .DI39(conv_result_accum[39]),
    .DI40(conv_result_accum[40]), .DI41(conv_result_accum[41]), .DI42(conv_result_accum[42]), .DI43(conv_result_accum[43]), .DI44(conv_result_accum[44]), .DI45(conv_result_accum[45]), .DI46(conv_result_accum[46]), .DI47(conv_result_accum[47]),
    .DI48(conv_result_accum[48]), .DI49(conv_result_accum[49]), .DI50(conv_result_accum[50]), .DI51(conv_result_accum[51]), .DI52(conv_result_accum[52]), .DI53(conv_result_accum[53]), .DI54(conv_result_accum[54]), .DI55(conv_result_accum[55]),
    .DI56(conv_result_accum[56]), .DI57(conv_result_accum[57]), .DI58(conv_result_accum[58]), .DI59(conv_result_accum[59]), .DI60(conv_result_accum[60]), .DI61(conv_result_accum[61]), .DI62(conv_result_accum[62]), .DI63(conv_result_accum[63]),
    .DO0(conv_result_read_data[0]),  .DO1(conv_result_read_data[1]),  .DO2(conv_result_read_data[2]),  .DO3(conv_result_read_data[3]),  .DO4(conv_result_read_data[4]),  .DO5(conv_result_read_data[5]),  .DO6(conv_result_read_data[6]),  .DO7(conv_result_read_data[7]),
    .DO8(conv_result_read_data[8]),  .DO9(conv_result_read_data[9]),  .DO10(conv_result_read_data[10]), .DO11(conv_result_read_data[11]), .DO12(conv_result_read_data[12]), .DO13(conv_result_read_data[13]), .DO14(conv_result_read_data[14]), .DO15(conv_result_read_data[15]),
    .DO16(conv_result_read_data[16]), .DO17(conv_result_read_data[17]), .DO18(conv_result_read_data[18]), .DO19(conv_result_read_data[19]), .DO20(conv_result_read_data[20]), .DO21(conv_result_read_data[21]), .DO22(conv_result_read_data[22]), .DO23(conv_result_read_data[23]),
    .DO24(conv_result_read_data[24]), .DO25(conv_result_read_data[25]), .DO26(conv_result_read_data[26]), .DO27(conv_result_read_data[27]), .DO28(conv_result_read_data[28]), .DO29(conv_result_read_data[29]), .DO30(conv_result_read_data[30]), .DO31(conv_result_read_data[31]),
    .DO32(conv_result_read_data[32]), .DO33(conv_result_read_data[33]), .DO34(conv_result_read_data[34]), .DO35(conv_result_read_data[35]), .DO36(conv_result_read_data[36]), .DO37(conv_result_read_data[37]), .DO38(conv_result_read_data[38]), .DO39(conv_result_read_data[39]),
    .DO40(conv_result_read_data[40]), .DO41(conv_result_read_data[41]), .DO42(conv_result_read_data[42]), .DO43(conv_result_read_data[43]), .DO44(conv_result_read_data[44]), .DO45(conv_result_read_data[45]), .DO46(conv_result_read_data[46]), .DO47(conv_result_read_data[47]),
    .DO48(conv_result_read_data[48]), .DO49(conv_result_read_data[49]), .DO50(conv_result_read_data[50]), .DO51(conv_result_read_data[51]), .DO52(conv_result_read_data[52]), .DO53(conv_result_read_data[53]), .DO54(conv_result_read_data[54]), .DO55(conv_result_read_data[55]),
    .DO56(conv_result_read_data[56]), .DO57(conv_result_read_data[57]), .DO58(conv_result_read_data[58]), .DO59(conv_result_read_data[59]), .DO60(conv_result_read_data[60]), .DO61(conv_result_read_data[61]), .DO62(conv_result_read_data[62]), .DO63(conv_result_read_data[63])
);

assign start_fetch_wire = conv_write_cnt == 4096 
            || (tpu_cnt == 27 && ((tpu_result_cnt < 63 && (curr_tpu_iter < 3 || curr_tpu_iter == 5)) || (tpu_result_cnt < 31 && curr_tpu_iter == 3))) 
            || (tpu_result_cnt == 64 && curr_tpu_iter < 3)
            || (tpu_result_cnt == 32 && curr_tpu_iter == 3)
            || (tpu_result_cnt == 2 && curr_tpu_iter == 4)
            || (tpu_cnt == 267 && (tpu_result_cnt < 1 && curr_tpu_iter == 4));
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_fetch <= 0;
    end
    else if(start_fetch_wire) begin
        start_fetch <= 1;
    end
    else if(fetch_cnt == fetch_cnt_end - 1) begin
        start_fetch <= 0;
    end
    else begin
        start_fetch <= start_fetch;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fetch_cnt_end <= 19;
    end
    else if(curr_tpu_iter == 4) begin
        fetch_cnt_end <= 260;
    end
    else if(curr_tpu_iter == 3 || curr_tpu_iter == 5) begin
        fetch_cnt_end <= 19;
    end
    else begin
        fetch_cnt_end <= fetch_cnt_end;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fetch_cnt <= 0;
    end
    else if(start_fetch) begin
        fetch_cnt <= fetch_cnt + 1;
    end
    else begin
        fetch_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fetch_start_idx <= 0;
    end
    else if(tpu_result_cnt == 63 && tpu_data_valid2) begin
        fetch_start_idx <= 0;
    end
    else if(fetch_cnt == fetch_cnt_end && curr_tpu_iter != 3 && curr_tpu_iter != 4) begin
        fetch_start_idx <= tpu_result_cnt == 31 ? 0 : fetch_start_idx + 16;
    end
    else begin
        fetch_start_idx <= fetch_start_idx;
    end
end
assign fetch_start_idx2 = fetch_start_idx + 1;
assign fetch_end_idx = fetch_start_idx + 14;
// assign fetch_end_idx2 = fetch_end_idx + 1;
assign fetch_cnt_m2 = fetch_cnt - 2;
assign fetch_cnt_m3 = fetch_cnt < 3 ? 0 : fetch_cnt - 3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_tpu <= 0;
    end
    else if(fetch_cnt == 1) begin
        start_tpu <= 1;
    end
    else if(tpu_result_cnt == 63 && tpu_data_valid2) begin
        start_tpu <= 0;
    end
    else if(tpu_result_cnt == 31 && tpu_data_valid2 && curr_tpu_iter == 3) begin
        start_tpu <= 0;
    end
    else if(tpu_result_cnt == 1 && tpu_data_valid2 && curr_tpu_iter == 4) begin
        start_tpu <= 0;
    end
    else begin
        start_tpu <= start_tpu;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tpu_cnt <= 0;
    end
    else if(start_tpu) begin
        if(tpu_cnt == tpu_cnt_end)tpu_cnt <= 3;
        else tpu_cnt <= tpu_cnt + 1;
    end
    else begin
        tpu_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tpu_cnt_end <= 33;
    end
    else if(curr_tpu_iter == 4) begin
        tpu_cnt_end <= 273;
    end
    else if(curr_tpu_iter == 3 || curr_tpu_iter == 5) begin
        tpu_cnt_end <= 33;
    end
    else begin
        tpu_cnt_end <= tpu_cnt_end;
    end
end
assign tpu_cnt_end_m1 = tpu_cnt_end - 1;
// Linear transformation, systolic array
assign A_data_sel = curr_tpu_iter == 3 ? q_data_read_data_r : conv_result_read_data_r;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i <= 7;i = i + 1) begin
            for(j = 0;j <= 7;j = j + 1)
            A_buffer[i][j] <= 0;
        end
    end
    else begin
        for(i = 0;i <= 7;i = i + 1) begin
            if(fetch_cnt_m2[2:0] == i && start_fetch && ((fetch_cnt_m2 <= 15 && curr_tpu_iter != 4) || (fetch_cnt_m2 <= 255 && curr_tpu_iter == 4))) begin
                if(curr_tpu_iter == 4) begin
                    A_buffer[i][0] <= {1'b0, qk_data_read_data_r[63:56]};
                    A_buffer[i][1] <= {1'b0, qk_data_read_data_r[55:48]};
                    A_buffer[i][2] <= {1'b0, qk_data_read_data_r[47:40]};
                    A_buffer[i][3] <= {1'b0, qk_data_read_data_r[39:32]};
                    A_buffer[i][4] <= {1'b0, qk_data_read_data_r[31:24]};
                    A_buffer[i][5] <= {1'b0, qk_data_read_data_r[23:16]};
                    A_buffer[i][6] <= {1'b0, qk_data_read_data_r[15:8]};
                    A_buffer[i][7] <= {1'b0, qk_data_read_data_r[7:0]};
                end
                else begin
                    A_buffer[i][0] <= $signed(A_data_sel[63:56]);
                    A_buffer[i][1] <= $signed(A_data_sel[55:48]);
                    A_buffer[i][2] <= $signed(A_data_sel[47:40]);
                    A_buffer[i][3] <= $signed(A_data_sel[39:32]);
                    A_buffer[i][4] <= $signed(A_data_sel[31:24]);
                    A_buffer[i][5] <= $signed(A_data_sel[23:16]);
                    A_buffer[i][6] <= $signed(A_data_sel[15:8]);
                    A_buffer[i][7] <= $signed(A_data_sel[7:0]);
                end
            end
            else begin
                for(j = 0;j <= 6;j = j + 1) begin
                    A_buffer[i][j] <= A_buffer[i][j+1];
                end
                A_buffer[i][7] <= 8'b0;
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(k = 0; k <= 7; k = k + 1) B_buffer[k] <= 0;
        B_buffer_delay1 <= 0;
        for(k = 0; k < 2; k = k + 1) B_buffer_delay2[k] <= 0;
        for(k = 0; k < 3; k = k + 1) B_buffer_delay3[k] <= 0;
        for(k = 0; k < 4; k = k + 1) B_buffer_delay4[k] <= 0;
        for(k = 0; k < 5; k = k + 1) B_buffer_delay5[k] <= 0;
        for(k = 0; k < 6; k = k + 1) B_buffer_delay6[k] <= 0;
        for(k = 0; k < 7; k = k + 1) B_buffer_delay7[k] <= 0;
    end
    else begin
        if(start_fetch) begin
            if(curr_tpu_iter == 4) begin
                B_buffer[0] <= v_data_read_data_r[63:56];
                B_buffer[1] <= v_data_read_data_r[55:48];
                B_buffer[2] <= v_data_read_data_r[47:40];
                B_buffer[3] <= v_data_read_data_r[39:32];
                B_buffer[4] <= v_data_read_data_r[31:24];
                B_buffer[5] <= v_data_read_data_r[23:16];
                B_buffer[6] <= v_data_read_data_r[15:8];
                B_buffer[7] <= v_data_read_data_r[7:0];
            end
            else begin
                B_buffer[0] <= $signed(weight_read_data_r[31:28]);
                B_buffer[1] <= $signed(weight_read_data_r[27:24]);
                B_buffer[2] <= $signed(weight_read_data_r[23:20]);
                B_buffer[3] <= $signed(weight_read_data_r[19:16]);
                B_buffer[4] <= $signed(weight_read_data_r[15:12]);
                B_buffer[5] <= $signed(weight_read_data_r[11:8]);
                B_buffer[6] <= $signed(weight_read_data_r[7:4]);
                B_buffer[7] <= $signed(weight_read_data_r[3:0]);
            end
        end
        else begin
            for(k = 0; k <= 7; k = k + 1) begin
                B_buffer[k] <= 0;
            end
        end

        B_buffer_delay1    <= B_buffer[1];

        B_buffer_delay2[0] <= B_buffer_delay2[1];
        B_buffer_delay2[1] <= B_buffer[2];

        B_buffer_delay3[0] <= B_buffer_delay3[1];
        B_buffer_delay3[1] <= B_buffer_delay3[2];
        B_buffer_delay3[2] <= B_buffer[3];

        B_buffer_delay4[0] <= B_buffer_delay4[1];
        B_buffer_delay4[1] <= B_buffer_delay4[2];
        B_buffer_delay4[2] <= B_buffer_delay4[3];
        B_buffer_delay4[3] <= B_buffer[4];

        B_buffer_delay5[0] <= B_buffer_delay5[1];
        B_buffer_delay5[1] <= B_buffer_delay5[2];
        B_buffer_delay5[2] <= B_buffer_delay5[3];
        B_buffer_delay5[3] <= B_buffer_delay5[4];
        B_buffer_delay5[4] <= B_buffer[5];

        B_buffer_delay6[0] <= B_buffer_delay6[1];
        B_buffer_delay6[1] <= B_buffer_delay6[2];
        B_buffer_delay6[2] <= B_buffer_delay6[3];
        B_buffer_delay6[3] <= B_buffer_delay6[4];
        B_buffer_delay6[4] <= B_buffer_delay6[5];
        B_buffer_delay6[5] <= B_buffer[6];

        B_buffer_delay7[0] <= B_buffer_delay7[1];
        B_buffer_delay7[1] <= B_buffer_delay7[2];
        B_buffer_delay7[2] <= B_buffer_delay7[3];
        B_buffer_delay7[3] <= B_buffer_delay7[4];
        B_buffer_delay7[4] <= B_buffer_delay7[5];
        B_buffer_delay7[5] <= B_buffer_delay7[6];
        B_buffer_delay7[6] <= B_buffer[7];
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i <= 7;i = i + 1) begin
            for(j = 0;j <= 7;j = j + 1)
            B_buffer2[i][j] <= 0;
        end
    end
    else begin
        for(i = 0;i <= 7;i = i + 1) begin
            if(fetch_cnt_m2[2:0] == i && start_fetch && fetch_cnt_m2 <= 15) begin
                B_buffer2[i][0] <= k_data_read_data_r[63:56];
                B_buffer2[i][1] <= k_data_read_data_r[55:48];
                B_buffer2[i][2] <= k_data_read_data_r[47:40];
                B_buffer2[i][3] <= k_data_read_data_r[39:32];
                B_buffer2[i][4] <= k_data_read_data_r[31:24];
                B_buffer2[i][5] <= k_data_read_data_r[23:16];
                B_buffer2[i][6] <= k_data_read_data_r[15:8];
                B_buffer2[i][7] <= k_data_read_data_r[7:0];
            end
            else begin
                for(j = 0;j <= 6;j = j + 1) begin
                    B_buffer2[i][j] <= B_buffer2[i][j+1];
                end
                B_buffer2[i][7] <= 8'b0;
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i <= 7;i = i + 1) begin
            pe_horizontal_data_reg[i] <= 0;
            pe_vertical_data_reg[i] <= 0;
        end
    end
    else begin
        for(i = 0;i <= 7;i = i + 1) begin
            // if(fetch_cnt_m3[2:0] >= i && fetch_cnt >= 2 && fetch_cnt <= 19 && start_fetch)begin
                pe_horizontal_data_reg[i] <= A_buffer[i][0];
            // end
            // else begin
            //     pe_horizontal_data_reg[i] <= 0;
            // end
        end
        if(curr_tpu_iter == 3) begin
            for(i = 0;i <= 7;i = i + 1) begin
                pe_vertical_data_reg[i] <= B_buffer2[i][0];
            end
        end
        else begin
            pe_vertical_data_reg[0] <= B_buffer[0];
            pe_vertical_data_reg[1] <= B_buffer_delay1;
            pe_vertical_data_reg[2] <= B_buffer_delay2[0];
            pe_vertical_data_reg[3] <= B_buffer_delay3[0];
            pe_vertical_data_reg[4] <= B_buffer_delay4[0];
            pe_vertical_data_reg[5] <= B_buffer_delay5[0];
            pe_vertical_data_reg[6] <= B_buffer_delay6[0];
            pe_vertical_data_reg[7] <= B_buffer_delay7[0];
        end
    end
end
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        pe_horizontal_data_i[i*8] = pe_horizontal_data_reg[i];
    end
    for(i = 0;i <= 63;i = i + 8) begin
        for(j = 1;j <= 7;j = j + 1)begin
            pe_horizontal_data_i[i+j] = pe_horizontal_data_o[i+j-1];
        end
    end
end

always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        pe_vertical_data_i[i] = pe_vertical_data_reg[i];
    end
    for(i = 8;i <= 63;i = i + 8) begin
        for(j = 0;j <= 7;j = j + 1)begin
            pe_vertical_data_i[i+j] = pe_vertical_data_o[i+j-8];
        end
    end
end

generate
    for (idx = 0; idx < 64; idx = idx + 1) begin : PE_INSTANCES
        PE pe_inst (
            .clk(clk),
            .rst_n(rst_n),
            .flush_i(tpu_data_valid),
            .vertical_data_i(pe_vertical_data_i[idx]),
            .horizontal_data_i(pe_horizontal_data_i[idx]),
            .vertical_data_o(pe_vertical_data_o[idx]),
            .horizontal_data_o(pe_horizontal_data_o[idx]),
            .result_o(pe_result_o[idx])
        );
    end
endgenerate

// assign tpu_data_valid = tpu_cnt == tpu_cnt_end;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tpu_data_valid2 <= 0;
        tpu_data_valid <= 0;
    end
    else begin
        tpu_data_valid2 <= tpu_data_valid;
        tpu_data_valid <= (tpu_cnt == tpu_cnt_end_m1);
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tpu_result_cnt <= 0;
    end
    else if(start_write_q && q_write_cnt == 7) begin
        tpu_result_cnt <= tpu_result_cnt + 1;
    end
    else if(tpu_result_cnt == 64) begin
        tpu_result_cnt <= 0;
    end
    else if(curr_tpu_iter == 3 && tpu_result_cnt == 32) begin
        tpu_result_cnt <= 0;
    end
    else if(curr_tpu_iter == 4 && tpu_result_cnt == 2) begin
        tpu_result_cnt <= 0;
    end
    else begin
        tpu_result_cnt <= tpu_result_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tpu_result_cnt_L2 <= 0;
    end
    else if(curr_tpu_iter == 3 && tpu_result_cnt == 32) begin
        tpu_result_cnt_L2 <= tpu_result_cnt_L2 + 1;
    end
    else if(curr_tpu_iter == 7) begin
        tpu_result_cnt_L2 <= 0;
    end
    else begin
        tpu_result_cnt_L2 <= tpu_result_cnt_L2;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0;i <= 63;i = i + 1) begin
            tpu_result_data[i] <= 0;
        end
    end
    else if(tpu_data_valid) begin
        for (i = 0; i <= 63; i = i + 1) begin
            tpu_result_data[i] <= pe_result_o[i];
        end
    end
    else begin
        tpu_result_data[55:0] <= tpu_result_data[63:8];
        for(i = 56;i <= 63;i = i + 1) begin
            tpu_result_data[i] <= 0;
        end
    end
end
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         tpu_shift_number <= 4;
//     end
//     else if(curr_tpu_iter == 3) begin
//         tpu_shift_number <= 2;
//     end
//     else if(curr_tpu_iter == 4) begin
//         tpu_shift_number <= 16;
//     end
//     else if(curr_tpu_iter == 5) begin
//         tpu_shift_number <= 4;
//     end
//     else begin
//         tpu_shift_number <= tpu_shift_number;
//     end
// end
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        tpu_result_data_shift2[i] = tpu_result_data[i] >>> 2;
        tpu_result_data_shift4[i] = tpu_result_data[i] >>> 4;
        tpu_result_data_shift16[i] = tpu_result_data[i] >>> 16;
        tpu_result_data_shift6[i] = tpu_result_data[i] >>> 6;
        tpu_result_data_add_sel[i] = 
                curr_tpu_iter == 3 ? tpu_result_data_shift6[i]: tpu_result_data_shift4[i];
        tpu_result_data_add[i] = $signed(tpu_result_data_add_sel[i][7:0]) + 128;
    end
end
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(curr_tpu_iter == 3) begin
            if(tpu_result_data_shift2[i] > 2047) begin
                tpu_result_data_clip[i] = 8'hFF;
            end
            else if(tpu_result_data_shift2[i] < -2048) begin
                tpu_result_data_clip[i] = 8'h00;
            end
            else begin
                tpu_result_data_clip[i] = tpu_result_data_add[i][7:0];
            end
        end
        else if(curr_tpu_iter == 4) begin
            // if(tpu_result_data_shift16[i] > 127) begin
            //     tpu_result_data_clip[i] = 8'h7F;
            // end
            // else if(tpu_result_data_shift16[i] < -128) begin
            //     tpu_result_data_clip[i] = 8'h80;
            // end
            // else begin
                tpu_result_data_clip[i] = tpu_result_data_shift16[i];
            // end
        end
        else if(curr_tpu_iter == 5) begin
            if(tpu_result_data_shift4[i] > 127) begin
                tpu_result_data_clip[i] = 8'hFF;
            end
            else if(tpu_result_data_shift4[i] < -128) begin
                tpu_result_data_clip[i] = 8'h00;
            end
            else begin
                tpu_result_data_clip[i] = tpu_result_data_add[i][7:0];
            end
        end
        else begin
            if(tpu_result_data_shift4[i] > 127) begin
                tpu_result_data_clip[i] = 8'h7F;
            end
            else if(tpu_result_data_shift4[i] < -128) begin
                tpu_result_data_clip[i] = 8'h80;
            end
            else begin
                tpu_result_data_clip[i] = tpu_result_data_shift4[i][7:0];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tpu_result_data_clip_r <= 0;
    end
    else begin
        tpu_result_data_clip_r <= {tpu_result_data_clip[0], tpu_result_data_clip[1], tpu_result_data_clip[2], tpu_result_data_clip[3], tpu_result_data_clip[4], tpu_result_data_clip[5], tpu_result_data_clip[6], tpu_result_data_clip[7]};
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_write_q <= 0;
    end
    else if (tpu_data_valid) begin
        start_write_q <= 1;
    end
    else if(q_write_cnt == 7) begin
        start_write_q <= 0;
    end
    else begin
        start_write_q <= start_write_q;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q_write_cnt <= 0;
    end
    else if (start_write_q) begin
        q_write_cnt <= q_write_cnt + 1;
    end
    else begin
        q_write_cnt <= 0;
    end
end

// Q sram
always @(*) begin
    q_data_accum <= tpu_result_data_clip_r;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q_data_web <= 1'b1;
    end
    else if (start_write_q && curr_tpu_iter == 0) begin
        q_data_web <= 1'b0;
    end
    else begin
        q_data_web <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q_data_addr <= 9'd0;
    end
    // else if(output_check_fetch) begin
    //     if(out_check_cnt == 3'd7) begin
    //         q_data_addr <= q_data_addr + 1'b1;
    //     end
    //     else begin
    //         q_data_addr <= q_data_addr;
    //     end
    // end
    else if(start_fetch_wire && curr_tpu_iter == 3) begin
        q_data_addr <= q_fetch_start_idx;
    end
    else if(start_fetch && curr_tpu_iter == 3) begin
        q_data_addr <= q_data_addr == q_fetch_end_idx ? q_fetch_start_idx2 : q_data_addr + 2;
    end
    else if (q_data_web == 0) begin
        q_data_addr <= q_data_addr == 511 ? 0 : q_data_addr == 510 ? 1 :  q_data_addr + 2'd2;
    end
    else begin
        q_data_addr <= q_data_addr;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q_fetch_start_idx <= 0;
    end
    else if(tpu_result_cnt_L2 == 32) begin
        q_fetch_start_idx <= 0;
    end
    else if(fetch_cnt == fetch_cnt_end && curr_tpu_iter == 3) begin
        q_fetch_start_idx <= tpu_result_cnt == 31 ? q_fetch_start_idx + 16 : q_fetch_start_idx;
    end
    else begin
        q_fetch_start_idx <= q_fetch_start_idx;
    end
end
assign q_fetch_start_idx2 = q_fetch_start_idx + 1;
assign q_fetch_end_idx = q_fetch_start_idx + 14;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        q_data_read_data_r <= 0;
    end
    else begin
        q_data_read_data_r <= q_data_read_data;
    end
end
Linear_512X64X1BM1 Q_sram (
    .CK(clk), .WEB(q_data_web), .OE(1'b1), .CS(1'b1),
    .A0(q_data_addr[0]), .A1(q_data_addr[1]), .A2(q_data_addr[2]), .A3(q_data_addr[3]), .A4(q_data_addr[4]), .A5(q_data_addr[5]), .A6(q_data_addr[6]), .A7(q_data_addr[7]), .A8(q_data_addr[8]), 
    .DI0(q_data_accum[0]),  .DI1(q_data_accum[1]),  .DI2(q_data_accum[2]),  .DI3(q_data_accum[3]),  .DI4(q_data_accum[4]),  .DI5(q_data_accum[5]),  .DI6(q_data_accum[6]),  .DI7(q_data_accum[7]),
    .DI8(q_data_accum[8]),  .DI9(q_data_accum[9]),  .DI10(q_data_accum[10]), .DI11(q_data_accum[11]), .DI12(q_data_accum[12]), .DI13(q_data_accum[13]), .DI14(q_data_accum[14]), .DI15(q_data_accum[15]),
    .DI16(q_data_accum[16]), .DI17(q_data_accum[17]), .DI18(q_data_accum[18]), .DI19(q_data_accum[19]), .DI20(q_data_accum[20]), .DI21(q_data_accum[21]), .DI22(q_data_accum[22]), .DI23(q_data_accum[23]),
    .DI24(q_data_accum[24]), .DI25(q_data_accum[25]), .DI26(q_data_accum[26]), .DI27(q_data_accum[27]), .DI28(q_data_accum[28]), .DI29(q_data_accum[29]), .DI30(q_data_accum[30]), .DI31(q_data_accum[31]),
    .DI32(q_data_accum[32]), .DI33(q_data_accum[33]), .DI34(q_data_accum[34]), .DI35(q_data_accum[35]), .DI36(q_data_accum[36]), .DI37(q_data_accum[37]), .DI38(q_data_accum[38]), .DI39(q_data_accum[39]),
    .DI40(q_data_accum[40]), .DI41(q_data_accum[41]), .DI42(q_data_accum[42]), .DI43(q_data_accum[43]), .DI44(q_data_accum[44]), .DI45(q_data_accum[45]), .DI46(q_data_accum[46]), .DI47(q_data_accum[47]),
    .DI48(q_data_accum[48]), .DI49(q_data_accum[49]), .DI50(q_data_accum[50]), .DI51(q_data_accum[51]), .DI52(q_data_accum[52]), .DI53(q_data_accum[53]), .DI54(q_data_accum[54]), .DI55(q_data_accum[55]),
    .DI56(q_data_accum[56]), .DI57(q_data_accum[57]), .DI58(q_data_accum[58]), .DI59(q_data_accum[59]), .DI60(q_data_accum[60]), .DI61(q_data_accum[61]), .DI62(q_data_accum[62]), .DI63(q_data_accum[63]),
    .DO0(q_data_read_data[0]),  .DO1(q_data_read_data[1]),  .DO2(q_data_read_data[2]),  .DO3(q_data_read_data[3]),  .DO4(q_data_read_data[4]),  .DO5(q_data_read_data[5]),  .DO6(q_data_read_data[6]),  .DO7(q_data_read_data[7]),
    .DO8(q_data_read_data[8]),  .DO9(q_data_read_data[9]),  .DO10(q_data_read_data[10]), .DO11(q_data_read_data[11]), .DO12(q_data_read_data[12]), .DO13(q_data_read_data[13]), .DO14(q_data_read_data[14]), .DO15(q_data_read_data[15]),
    .DO16(q_data_read_data[16]), .DO17(q_data_read_data[17]), .DO18(q_data_read_data[18]), .DO19(q_data_read_data[19]), .DO20(q_data_read_data[20]), .DO21(q_data_read_data[21]), .DO22(q_data_read_data[22]), .DO23(q_data_read_data[23]),
    .DO24(q_data_read_data[24]), .DO25(q_data_read_data[25]), .DO26(q_data_read_data[26]), .DO27(q_data_read_data[27]), .DO28(q_data_read_data[28]), .DO29(q_data_read_data[29]), .DO30(q_data_read_data[30]), .DO31(q_data_read_data[31]),
    .DO32(q_data_read_data[32]), .DO33(q_data_read_data[33]), .DO34(q_data_read_data[34]), .DO35(q_data_read_data[35]), .DO36(q_data_read_data[36]), .DO37(q_data_read_data[37]), .DO38(q_data_read_data[38]), .DO39(q_data_read_data[39]),
    .DO40(q_data_read_data[40]), .DO41(q_data_read_data[41]), .DO42(q_data_read_data[42]), .DO43(q_data_read_data[43]), .DO44(q_data_read_data[44]), .DO45(q_data_read_data[45]), .DO46(q_data_read_data[46]), .DO47(q_data_read_data[47]),
    .DO48(q_data_read_data[48]), .DO49(q_data_read_data[49]), .DO50(q_data_read_data[50]), .DO51(q_data_read_data[51]), .DO52(q_data_read_data[52]), .DO53(q_data_read_data[53]), .DO54(q_data_read_data[54]), .DO55(q_data_read_data[55]),
    .DO56(q_data_read_data[56]), .DO57(q_data_read_data[57]), .DO58(q_data_read_data[58]), .DO59(q_data_read_data[59]), .DO60(q_data_read_data[60]), .DO61(q_data_read_data[61]), .DO62(q_data_read_data[62]), .DO63(q_data_read_data[63])
);
// K sram
always @(*) begin
    k_data_accum <= tpu_result_data_clip_r;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        k_data_web <= 1'b1;
    end
    else if (start_write_q && curr_tpu_iter == 1) begin
        k_data_web <= 1'b0;
    end
    else begin
        k_data_web <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        k_data_addr <= 9'd0;
    end
    // else if(output_check_fetch) begin
    //     if(out_check_cnt == 3'd7) begin
    //         k_data_addr <= k_data_addr + 1'b1;
    //     end
    //     else begin
    //         k_data_addr <= k_data_addr;
    //     end
    // end
    else if(start_fetch_wire && (curr_tpu_iter == 3 || curr_tpu_iter == 2 && tpu_result_cnt == 64)) begin
        k_data_addr <= k_fetch_start_idx;
    end
    else if(start_fetch && curr_tpu_iter == 3) begin
        k_data_addr <= k_data_addr == k_fetch_end_idx ? k_fetch_start_idx2 : k_data_addr + 2;
    end
    else if (k_data_web == 0) begin
        k_data_addr <= k_data_addr == 511 ? 0 : k_data_addr == 510 ? 1 : k_data_addr + 2'd2;
    end
    else begin
        k_data_addr <= k_data_addr;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        k_fetch_start_idx <= 0;
    end
    else if(tpu_result_cnt_L2 == 32) begin
        k_fetch_start_idx <= 0;
    end
    else if(fetch_cnt == fetch_cnt_end && curr_tpu_iter == 3) begin
        k_fetch_start_idx <= k_fetch_start_idx + 16;
    end
    else begin
        k_fetch_start_idx <= k_fetch_start_idx;
    end
end
assign k_fetch_start_idx2 = k_fetch_start_idx + 1;
assign k_fetch_end_idx = k_fetch_start_idx + 14;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        k_data_read_data_r <= 0;
    end
    else begin
        k_data_read_data_r <= k_data_read_data;
    end
end
Linear_512X64X1BM1 K_sram (
    .CK(clk), .WEB(k_data_web), .OE(1'b1), .CS(1'b1),
    .A0(k_data_addr[0]), .A1(k_data_addr[1]), .A2(k_data_addr[2]), .A3(k_data_addr[3]), .A4(k_data_addr[4]), .A5(k_data_addr[5]), .A6(k_data_addr[6]), .A7(k_data_addr[7]), .A8(k_data_addr[8]), 
    .DI0(k_data_accum[0]),   .DI1(k_data_accum[1]),   .DI2(k_data_accum[2]),   .DI3(k_data_accum[3]),   .DI4(k_data_accum[4]),   .DI5(k_data_accum[5]),   .DI6(k_data_accum[6]),   .DI7(k_data_accum[7]),
    .DI8(k_data_accum[8]),   .DI9(k_data_accum[9]),   .DI10(k_data_accum[10]), .DI11(k_data_accum[11]), .DI12(k_data_accum[12]), .DI13(k_data_accum[13]), .DI14(k_data_accum[14]), .DI15(k_data_accum[15]),
    .DI16(k_data_accum[16]), .DI17(k_data_accum[17]), .DI18(k_data_accum[18]), .DI19(k_data_accum[19]), .DI20(k_data_accum[20]), .DI21(k_data_accum[21]), .DI22(k_data_accum[22]), .DI23(k_data_accum[23]),
    .DI24(k_data_accum[24]), .DI25(k_data_accum[25]), .DI26(k_data_accum[26]), .DI27(k_data_accum[27]), .DI28(k_data_accum[28]), .DI29(k_data_accum[29]), .DI30(k_data_accum[30]), .DI31(k_data_accum[31]),
    .DI32(k_data_accum[32]), .DI33(k_data_accum[33]), .DI34(k_data_accum[34]), .DI35(k_data_accum[35]), .DI36(k_data_accum[36]), .DI37(k_data_accum[37]), .DI38(k_data_accum[38]), .DI39(k_data_accum[39]),
    .DI40(k_data_accum[40]), .DI41(k_data_accum[41]), .DI42(k_data_accum[42]), .DI43(k_data_accum[43]), .DI44(k_data_accum[44]), .DI45(k_data_accum[45]), .DI46(k_data_accum[46]), .DI47(k_data_accum[47]),
    .DI48(k_data_accum[48]), .DI49(k_data_accum[49]), .DI50(k_data_accum[50]), .DI51(k_data_accum[51]), .DI52(k_data_accum[52]), .DI53(k_data_accum[53]), .DI54(k_data_accum[54]), .DI55(k_data_accum[55]),
    .DI56(k_data_accum[56]), .DI57(k_data_accum[57]), .DI58(k_data_accum[58]), .DI59(k_data_accum[59]), .DI60(k_data_accum[60]), .DI61(k_data_accum[61]), .DI62(k_data_accum[62]), .DI63(k_data_accum[63]),
    .DO0(k_data_read_data[0]),   .DO1(k_data_read_data[1]),   .DO2(k_data_read_data[2]),   .DO3(k_data_read_data[3]),   .DO4(k_data_read_data[4]),   .DO5(k_data_read_data[5]),   .DO6(k_data_read_data[6]),   .DO7(k_data_read_data[7]),
    .DO8(k_data_read_data[8]),   .DO9(k_data_read_data[9]),   .DO10(k_data_read_data[10]), .DO11(k_data_read_data[11]), .DO12(k_data_read_data[12]), .DO13(k_data_read_data[13]), .DO14(k_data_read_data[14]), .DO15(k_data_read_data[15]),
    .DO16(k_data_read_data[16]), .DO17(k_data_read_data[17]), .DO18(k_data_read_data[18]), .DO19(k_data_read_data[19]), .DO20(k_data_read_data[20]), .DO21(k_data_read_data[21]), .DO22(k_data_read_data[22]), .DO23(k_data_read_data[23]),
    .DO24(k_data_read_data[24]), .DO25(k_data_read_data[25]), .DO26(k_data_read_data[26]), .DO27(k_data_read_data[27]), .DO28(k_data_read_data[28]), .DO29(k_data_read_data[29]), .DO30(k_data_read_data[30]), .DO31(k_data_read_data[31]),
    .DO32(k_data_read_data[32]), .DO33(k_data_read_data[33]), .DO34(k_data_read_data[34]), .DO35(k_data_read_data[35]), .DO36(k_data_read_data[36]), .DO37(k_data_read_data[37]), .DO38(k_data_read_data[38]), .DO39(k_data_read_data[39]),
    .DO40(k_data_read_data[40]), .DO41(k_data_read_data[41]), .DO42(k_data_read_data[42]), .DO43(k_data_read_data[43]), .DO44(k_data_read_data[44]), .DO45(k_data_read_data[45]), .DO46(k_data_read_data[46]), .DO47(k_data_read_data[47]),
    .DO48(k_data_read_data[48]), .DO49(k_data_read_data[49]), .DO50(k_data_read_data[50]), .DO51(k_data_read_data[51]), .DO52(k_data_read_data[52]), .DO53(k_data_read_data[53]), .DO54(k_data_read_data[54]), .DO55(k_data_read_data[55]),
    .DO56(k_data_read_data[56]), .DO57(k_data_read_data[57]), .DO58(k_data_read_data[58]), .DO59(k_data_read_data[59]), .DO60(k_data_read_data[60]), .DO61(k_data_read_data[61]), .DO62(k_data_read_data[62]), .DO63(k_data_read_data[63])
);
// V sram
always @(*) begin
    v_data_accum <= tpu_result_data_clip_r;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        v_data_web <= 1'b1;
    end
    else if (start_write_q && (curr_tpu_iter == 2 || curr_tpu_iter == 5)) begin
        v_data_web <= 1'b0;
    end
    else begin
        v_data_web <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        v_data_addr <= 9'd0;
    end
    // else if(output_check_fetch) begin
    //     if(out_check_cnt == 3'd7) begin
    //         v_data_addr <= v_data_addr + 1'b1;
    //     end
    //     else begin
    //         v_data_addr <= v_data_addr;
    //     end
    // end
    // ffn sram merge
    else if(start_conv_down) begin
        if(conv_cnt_down == 280) begin
            v_data_addr <= conv_down_ch;
        end
        else begin
            v_data_addr <= v_data_addr + 2'd2;
        end
    end
    else if (v_data_web == 0 || (start_fetch && curr_tpu_iter == 4 && fetch_cnt <= 255)) begin
        v_data_addr <= v_data_addr == 511 ? 0 : v_data_addr == 510 ? 1 : v_data_addr + 2'd2;
    end
    else if(curr_tpu_iter == 7) begin
        v_data_addr <= 0;
    end
    else begin
        v_data_addr <= v_data_addr;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        v_data_read_data_r <= 0;
    end
    else begin
        v_data_read_data_r <= v_data_read_data;
    end
end

Linear_512X64X1BM1 V_sram (
    .CK(clk), .WEB(v_data_web), .OE(1'b1), .CS(1'b1),
    .A0(v_data_addr[0]), .A1(v_data_addr[1]), .A2(v_data_addr[2]), .A3(v_data_addr[3]), .A4(v_data_addr[4]), .A5(v_data_addr[5]), .A6(v_data_addr[6]), .A7(v_data_addr[7]), .A8(v_data_addr[8]), 
    .DI0(v_data_accum[0]),   .DI1(v_data_accum[1]),   .DI2(v_data_accum[2]),   .DI3(v_data_accum[3]),   .DI4(v_data_accum[4]),   .DI5(v_data_accum[5]),   .DI6(v_data_accum[6]),   .DI7(v_data_accum[7]),
    .DI8(v_data_accum[8]),   .DI9(v_data_accum[9]),   .DI10(v_data_accum[10]), .DI11(v_data_accum[11]), .DI12(v_data_accum[12]), .DI13(v_data_accum[13]), .DI14(v_data_accum[14]), .DI15(v_data_accum[15]),
    .DI16(v_data_accum[16]), .DI17(v_data_accum[17]), .DI18(v_data_accum[18]), .DI19(v_data_accum[19]), .DI20(v_data_accum[20]), .DI21(v_data_accum[21]), .DI22(v_data_accum[22]), .DI23(v_data_accum[23]),
    .DI24(v_data_accum[24]), .DI25(v_data_accum[25]), .DI26(v_data_accum[26]), .DI27(v_data_accum[27]), .DI28(v_data_accum[28]), .DI29(v_data_accum[29]), .DI30(v_data_accum[30]), .DI31(v_data_accum[31]),
    .DI32(v_data_accum[32]), .DI33(v_data_accum[33]), .DI34(v_data_accum[34]), .DI35(v_data_accum[35]), .DI36(v_data_accum[36]), .DI37(v_data_accum[37]), .DI38(v_data_accum[38]), .DI39(v_data_accum[39]),
    .DI40(v_data_accum[40]), .DI41(v_data_accum[41]), .DI42(v_data_accum[42]), .DI43(v_data_accum[43]), .DI44(v_data_accum[44]), .DI45(v_data_accum[45]), .DI46(v_data_accum[46]), .DI47(v_data_accum[47]),
    .DI48(v_data_accum[48]), .DI49(v_data_accum[49]), .DI50(v_data_accum[50]), .DI51(v_data_accum[51]), .DI52(v_data_accum[52]), .DI53(v_data_accum[53]), .DI54(v_data_accum[54]), .DI55(v_data_accum[55]),
    .DI56(v_data_accum[56]), .DI57(v_data_accum[57]), .DI58(v_data_accum[58]), .DI59(v_data_accum[59]), .DI60(v_data_accum[60]), .DI61(v_data_accum[61]), .DI62(v_data_accum[62]), .DI63(v_data_accum[63]),
    .DO0(v_data_read_data[0]),   .DO1(v_data_read_data[1]),   .DO2(v_data_read_data[2]),   .DO3(v_data_read_data[3]),   .DO4(v_data_read_data[4]),   .DO5(v_data_read_data[5]),   .DO6(v_data_read_data[6]),   .DO7(v_data_read_data[7]),
    .DO8(v_data_read_data[8]),   .DO9(v_data_read_data[9]),   .DO10(v_data_read_data[10]), .DO11(v_data_read_data[11]), .DO12(v_data_read_data[12]), .DO13(v_data_read_data[13]), .DO14(v_data_read_data[14]), .DO15(v_data_read_data[15]),
    .DO16(v_data_read_data[16]), .DO17(v_data_read_data[17]), .DO18(v_data_read_data[18]), .DO19(v_data_read_data[19]), .DO20(v_data_read_data[20]), .DO21(v_data_read_data[21]), .DO22(v_data_read_data[22]), .DO23(v_data_read_data[23]),
    .DO24(v_data_read_data[24]), .DO25(v_data_read_data[25]), .DO26(v_data_read_data[26]), .DO27(v_data_read_data[27]), .DO28(v_data_read_data[28]), .DO29(v_data_read_data[29]), .DO30(v_data_read_data[30]), .DO31(v_data_read_data[31]),
    .DO32(v_data_read_data[32]), .DO33(v_data_read_data[33]), .DO34(v_data_read_data[34]), .DO35(v_data_read_data[35]), .DO36(v_data_read_data[36]), .DO37(v_data_read_data[37]), .DO38(v_data_read_data[38]), .DO39(v_data_read_data[39]),
    .DO40(v_data_read_data[40]), .DO41(v_data_read_data[41]), .DO42(v_data_read_data[42]), .DO43(v_data_read_data[43]), .DO44(v_data_read_data[44]), .DO45(v_data_read_data[45]), .DO46(v_data_read_data[46]), .DO47(v_data_read_data[47]),
    .DO48(v_data_read_data[48]), .DO49(v_data_read_data[49]), .DO50(v_data_read_data[50]), .DO51(v_data_read_data[51]), .DO52(v_data_read_data[52]), .DO53(v_data_read_data[53]), .DO54(v_data_read_data[54]), .DO55(v_data_read_data[55]),
    .DO56(v_data_read_data[56]), .DO57(v_data_read_data[57]), .DO58(v_data_read_data[58]), .DO59(v_data_read_data[59]), .DO60(v_data_read_data[60]), .DO61(v_data_read_data[61]), .DO62(v_data_read_data[62]), .DO63(v_data_read_data[63])
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        curr_tpu_iter <= 0;
    end
    else if(curr_tpu_iter <= 2) begin
        if(tpu_result_cnt == 64) begin
            curr_tpu_iter <= curr_tpu_iter + 1;
        end
    end
    else if(curr_tpu_iter == 3) begin
        if(tpu_result_cnt == 32) begin
            curr_tpu_iter <= 4;
        end
    end
    else if(curr_tpu_iter == 4) begin
        if(tpu_result_cnt == 2) begin
            if(tpu_result_cnt_L2 == 32) curr_tpu_iter <= 5;
            else curr_tpu_iter <= 3;
        end
    end
    else if(curr_tpu_iter == 5) begin
        if(tpu_result_cnt == 64) begin
            curr_tpu_iter <= 6;
        end
    end
    else if(curr_tpu_iter == 6) begin
        if(conv_write_cnt_down == 4095) begin
            curr_tpu_iter <= 7;
        end
    end
    else if(curr_tpu_iter == 7) begin
        if(sub_cnt2 == sub_end_point && sub_cnt == 3 && interpolation_iter == 15)
        curr_tpu_iter <= 0;
        else curr_tpu_iter <= curr_tpu_iter;
    end
    else begin
        curr_tpu_iter <= curr_tpu_iter;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        weight_addr_start_idx <= 18;
    end
    else if(tpu_result_cnt == 63 && tpu_data_valid2 && curr_tpu_iter <= 2) begin
        weight_addr_start_idx <= weight_addr_start_idx + 32;
    end
    else if(curr_tpu_iter == 7)begin
        weight_addr_start_idx <= 18;
    end
    else begin
        weight_addr_start_idx <= weight_addr_start_idx;
    end
end
assign weight_addr_start_idx2 = weight_addr_start_idx + 1;
assign weight_addr_end_idx = weight_addr_start_idx + 13;

// QK sram
always @(*) begin
    qk_data_accum <= tpu_result_data_clip_r;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        qk_data_web <= 1'b1;
    end
    else if (start_write_q && curr_tpu_iter == 3) begin
        qk_data_web <= 1'b0;
    end
    else begin
        qk_data_web <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        qk_data_addr <=8'd0;
    end
    // else if(output_check_fetch) begin
    //     if(out_check_cnt == 3'd7) begin
    //         qk_data_addr <= qk_data_addr + 1'b1;
    //     end
    //     else begin
    //         qk_data_addr <= qk_data_addr;
    //     end
    // end
    else if (start_fetch_wire && curr_tpu_iter == 4) begin
        qk_data_addr <= 0;
    end
    else if ((start_fetch && curr_tpu_iter == 4) || qk_data_web == 0) begin
        qk_data_addr <= qk_data_addr + 1;
    end
    else begin
        qk_data_addr <= qk_data_addr;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        qk_data_read_data_r <= 0;
    end
    else begin
        qk_data_read_data_r <= qk_data_read_data;
    end
end

QK_256X64X1BM1 QK_sram (
    .CK(clk), .WEB(qk_data_web), .OE(1'b1), .CS(1'b1),
    .A0(qk_data_addr[0]), .A1(qk_data_addr[1]), .A2(qk_data_addr[2]), .A3(qk_data_addr[3]), .A4(qk_data_addr[4]), .A5(qk_data_addr[5]), .A6(qk_data_addr[6]), .A7(qk_data_addr[7]), 
    .DI0(qk_data_accum[0]),   .DI1(qk_data_accum[1]),   .DI2(qk_data_accum[2]),   .DI3(qk_data_accum[3]),   .DI4(qk_data_accum[4]),   .DI5(qk_data_accum[5]),   .DI6(qk_data_accum[6]),   .DI7(qk_data_accum[7]),
    .DI8(qk_data_accum[8]),   .DI9(qk_data_accum[9]),   .DI10(qk_data_accum[10]), .DI11(qk_data_accum[11]), .DI12(qk_data_accum[12]), .DI13(qk_data_accum[13]), .DI14(qk_data_accum[14]), .DI15(qk_data_accum[15]),
    .DI16(qk_data_accum[16]), .DI17(qk_data_accum[17]), .DI18(qk_data_accum[18]), .DI19(qk_data_accum[19]), .DI20(qk_data_accum[20]), .DI21(qk_data_accum[21]), .DI22(qk_data_accum[22]), .DI23(qk_data_accum[23]),
    .DI24(qk_data_accum[24]), .DI25(qk_data_accum[25]), .DI26(qk_data_accum[26]), .DI27(qk_data_accum[27]), .DI28(qk_data_accum[28]), .DI29(qk_data_accum[29]), .DI30(qk_data_accum[30]), .DI31(qk_data_accum[31]),
    .DI32(qk_data_accum[32]), .DI33(qk_data_accum[33]), .DI34(qk_data_accum[34]), .DI35(qk_data_accum[35]), .DI36(qk_data_accum[36]), .DI37(qk_data_accum[37]), .DI38(qk_data_accum[38]), .DI39(qk_data_accum[39]),
    .DI40(qk_data_accum[40]), .DI41(qk_data_accum[41]), .DI42(qk_data_accum[42]), .DI43(qk_data_accum[43]), .DI44(qk_data_accum[44]), .DI45(qk_data_accum[45]), .DI46(qk_data_accum[46]), .DI47(qk_data_accum[47]),
    .DI48(qk_data_accum[48]), .DI49(qk_data_accum[49]), .DI50(qk_data_accum[50]), .DI51(qk_data_accum[51]), .DI52(qk_data_accum[52]), .DI53(qk_data_accum[53]), .DI54(qk_data_accum[54]), .DI55(qk_data_accum[55]),
    .DI56(qk_data_accum[56]), .DI57(qk_data_accum[57]), .DI58(qk_data_accum[58]), .DI59(qk_data_accum[59]), .DI60(qk_data_accum[60]), .DI61(qk_data_accum[61]), .DI62(qk_data_accum[62]), .DI63(qk_data_accum[63]),
    .DO0(qk_data_read_data[0]),   .DO1(qk_data_read_data[1]),   .DO2(qk_data_read_data[2]),   .DO3(qk_data_read_data[3]),   .DO4(qk_data_read_data[4]),   .DO5(qk_data_read_data[5]),   .DO6(qk_data_read_data[6]),   .DO7(qk_data_read_data[7]),
    .DO8(qk_data_read_data[8]),   .DO9(qk_data_read_data[9]),   .DO10(qk_data_read_data[10]), .DO11(qk_data_read_data[11]), .DO12(qk_data_read_data[12]), .DO13(qk_data_read_data[13]), .DO14(qk_data_read_data[14]), .DO15(qk_data_read_data[15]),
    .DO16(qk_data_read_data[16]), .DO17(qk_data_read_data[17]), .DO18(qk_data_read_data[18]), .DO19(qk_data_read_data[19]), .DO20(qk_data_read_data[20]), .DO21(qk_data_read_data[21]), .DO22(qk_data_read_data[22]), .DO23(qk_data_read_data[23]),
    .DO24(qk_data_read_data[24]), .DO25(qk_data_read_data[25]), .DO26(qk_data_read_data[26]), .DO27(qk_data_read_data[27]), .DO28(qk_data_read_data[28]), .DO29(qk_data_read_data[29]), .DO30(qk_data_read_data[30]), .DO31(qk_data_read_data[31]),
    .DO32(qk_data_read_data[32]), .DO33(qk_data_read_data[33]), .DO34(qk_data_read_data[34]), .DO35(qk_data_read_data[35]), .DO36(qk_data_read_data[36]), .DO37(qk_data_read_data[37]), .DO38(qk_data_read_data[38]), .DO39(qk_data_read_data[39]),
    .DO40(qk_data_read_data[40]), .DO41(qk_data_read_data[41]), .DO42(qk_data_read_data[42]), .DO43(qk_data_read_data[43]), .DO44(qk_data_read_data[44]), .DO45(qk_data_read_data[45]), .DO46(qk_data_read_data[46]), .DO47(qk_data_read_data[47]),
    .DO48(qk_data_read_data[48]), .DO49(qk_data_read_data[49]), .DO50(qk_data_read_data[50]), .DO51(qk_data_read_data[51]), .DO52(qk_data_read_data[52]), .DO53(qk_data_read_data[53]), .DO54(qk_data_read_data[54]), .DO55(qk_data_read_data[55]),
    .DO56(qk_data_read_data[56]), .DO57(qk_data_read_data[57]), .DO58(qk_data_read_data[58]), .DO59(qk_data_read_data[59]), .DO60(qk_data_read_data[60]), .DO61(qk_data_read_data[61]), .DO62(qk_data_read_data[62]), .DO63(qk_data_read_data[63])
);
// QKV sram
// always @(*) begin
//     qkv_data_accum <= tpu_result_data_clip_r[0];
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         qkv_data_web <= 1'b1;
//     end
//     else if (start_write_q && curr_tpu_iter == 4) begin
//         qkv_data_web <= 1'b0;
//     end
//     else begin
//         qkv_data_web <= 1'b1;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         qkv_data_addr <=9'd0;
//     end
//     else if(tpu_result_cnt == 2 && curr_tpu_iter == 4) begin
//         qkv_data_addr <= 0;
//     end
//     else if(curr_tpu_iter == 7) begin
//         qkv_data_addr <= 0;
//     end
//     // else if(output_check_fetch) begin
//     //     if(out_check_cnt == 3'd7) begin
//     //         qkv_data_addr <= qkv_data_addr + 1'b1;
//     //     end
//     //     else begin
//     //         qkv_data_addr <= qkv_data_addr;
//     //     end
//     // end
//     else if(start_fetch_wire && curr_tpu_iter == 5) begin
//         qkv_data_addr <= fetch_start_idx;
//     end
//     else if(start_fetch && curr_tpu_iter == 5) begin
//         qkv_data_addr <= qkv_data_addr == fetch_end_idx ? fetch_start_idx2 : qkv_data_addr + 2;
//     end
//     else if (tpu_data_valid2 && curr_tpu_iter == 4 && tpu_result_cnt == 0) begin
//         qkv_data_addr <= qkv_write_start_idx;
//     end
//     else if (qkv_data_web == 0) begin
//         qkv_data_addr <= qkv_data_addr == qkv_write_end_idx ? qkv_write_start_idx2 : qkv_data_addr + 2;
//     end
//     else begin
//         qkv_data_addr <= qkv_data_addr;
//     end
// end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        qkv_write_start_idx <= 0;
    end
    else if(tpu_result_cnt == 2 && curr_tpu_iter == 4) begin
        qkv_write_start_idx <= qkv_write_start_idx + 16;
    end
    else begin
        qkv_write_start_idx <= qkv_write_start_idx;
    end
end
assign qkv_write_start_idx2 = qkv_write_start_idx + 1;
assign qkv_write_end_idx = qkv_write_start_idx + 14;
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         qkv_data_read_data_r <= 0;
//     end
//     else begin
//         qkv_data_read_data_r <= qkv_data_read_data;
//     end
// end

// Linear_512X64X1BM1 QKV_sram (
//     .CK(clk), .WEB(qkv_data_web), .OE(1'b1), .CS(1'b1),
//     .A0(qkv_data_addr[0]), .A1(qkv_data_addr[1]), .A2(qkv_data_addr[2]), .A3(qkv_data_addr[3]), .A4(qkv_data_addr[4]), .A5(qkv_data_addr[5]), .A6(qkv_data_addr[6]), .A7(qkv_data_addr[7]), .A8(qkv_data_addr[8]),
//     .DI0(qkv_data_accum[0]),   .DI1(qkv_data_accum[1]),   .DI2(qkv_data_accum[2]),   .DI3(qkv_data_accum[3]),   .DI4(qkv_data_accum[4]),   .DI5(qkv_data_accum[5]),   .DI6(qkv_data_accum[6]),   .DI7(qkv_data_accum[7]),
//     .DI8(qkv_data_accum[8]),   .DI9(qkv_data_accum[9]),   .DI10(qkv_data_accum[10]), .DI11(qkv_data_accum[11]), .DI12(qkv_data_accum[12]), .DI13(qkv_data_accum[13]), .DI14(qkv_data_accum[14]), .DI15(qkv_data_accum[15]),
//     .DI16(qkv_data_accum[16]), .DI17(qkv_data_accum[17]), .DI18(qkv_data_accum[18]), .DI19(qkv_data_accum[19]), .DI20(qkv_data_accum[20]), .DI21(qkv_data_accum[21]), .DI22(qkv_data_accum[22]), .DI23(qkv_data_accum[23]),
//     .DI24(qkv_data_accum[24]), .DI25(qkv_data_accum[25]), .DI26(qkv_data_accum[26]), .DI27(qkv_data_accum[27]), .DI28(qkv_data_accum[28]), .DI29(qkv_data_accum[29]), .DI30(qkv_data_accum[30]), .DI31(qkv_data_accum[31]),
//     .DI32(qkv_data_accum[32]), .DI33(qkv_data_accum[33]), .DI34(qkv_data_accum[34]), .DI35(qkv_data_accum[35]), .DI36(qkv_data_accum[36]), .DI37(qkv_data_accum[37]), .DI38(qkv_data_accum[38]), .DI39(qkv_data_accum[39]),
//     .DI40(qkv_data_accum[40]), .DI41(qkv_data_accum[41]), .DI42(qkv_data_accum[42]), .DI43(qkv_data_accum[43]), .DI44(qkv_data_accum[44]), .DI45(qkv_data_accum[45]), .DI46(qkv_data_accum[46]), .DI47(qkv_data_accum[47]),
//     .DI48(qkv_data_accum[48]), .DI49(qkv_data_accum[49]), .DI50(qkv_data_accum[50]), .DI51(qkv_data_accum[51]), .DI52(qkv_data_accum[52]), .DI53(qkv_data_accum[53]), .DI54(qkv_data_accum[54]), .DI55(qkv_data_accum[55]),
//     .DI56(qkv_data_accum[56]), .DI57(qkv_data_accum[57]), .DI58(qkv_data_accum[58]), .DI59(qkv_data_accum[59]), .DI60(qkv_data_accum[60]), .DI61(qkv_data_accum[61]), .DI62(qkv_data_accum[62]), .DI63(qkv_data_accum[63]),
//     .DO0(qkv_data_read_data[0]),   .DO1(qkv_data_read_data[1]),   .DO2(qkv_data_read_data[2]),   .DO3(qkv_data_read_data[3]),   .DO4(qkv_data_read_data[4]),   .DO5(qkv_data_read_data[5]),   .DO6(qkv_data_read_data[6]),   .DO7(qkv_data_read_data[7]),
//     .DO8(qkv_data_read_data[8]),   .DO9(qkv_data_read_data[9]),   .DO10(qkv_data_read_data[10]), .DO11(qkv_data_read_data[11]), .DO12(qkv_data_read_data[12]), .DO13(qkv_data_read_data[13]), .DO14(qkv_data_read_data[14]), .DO15(qkv_data_read_data[15]),
//     .DO16(qkv_data_read_data[16]), .DO17(qkv_data_read_data[17]), .DO18(qkv_data_read_data[18]), .DO19(qkv_data_read_data[19]), .DO20(qkv_data_read_data[20]), .DO21(qkv_data_read_data[21]), .DO22(qkv_data_read_data[22]), .DO23(qkv_data_read_data[23]),
//     .DO24(qkv_data_read_data[24]), .DO25(qkv_data_read_data[25]), .DO26(qkv_data_read_data[26]), .DO27(qkv_data_read_data[27]), .DO28(qkv_data_read_data[28]), .DO29(qkv_data_read_data[29]), .DO30(qkv_data_read_data[30]), .DO31(qkv_data_read_data[31]),
//     .DO32(qkv_data_read_data[32]), .DO33(qkv_data_read_data[33]), .DO34(qkv_data_read_data[34]), .DO35(qkv_data_read_data[35]), .DO36(qkv_data_read_data[36]), .DO37(qkv_data_read_data[37]), .DO38(qkv_data_read_data[38]), .DO39(qkv_data_read_data[39]),
//     .DO40(qkv_data_read_data[40]), .DO41(qkv_data_read_data[41]), .DO42(qkv_data_read_data[42]), .DO43(qkv_data_read_data[43]), .DO44(qkv_data_read_data[44]), .DO45(qkv_data_read_data[45]), .DO46(qkv_data_read_data[46]), .DO47(qkv_data_read_data[47]),
//     .DO48(qkv_data_read_data[48]), .DO49(qkv_data_read_data[49]), .DO50(qkv_data_read_data[50]), .DO51(qkv_data_read_data[51]), .DO52(qkv_data_read_data[52]), .DO53(qkv_data_read_data[53]), .DO54(qkv_data_read_data[54]), .DO55(qkv_data_read_data[55]),
//     .DO56(qkv_data_read_data[56]), .DO57(qkv_data_read_data[57]), .DO58(qkv_data_read_data[58]), .DO59(qkv_data_read_data[59]), .DO60(qkv_data_read_data[60]), .DO61(qkv_data_read_data[61]), .DO62(qkv_data_read_data[62]), .DO63(qkv_data_read_data[63])
// );
// FFN sram
// always @(*) begin
//     ffn_data_accum <= tpu_result_data_clip_r[0];
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         ffn_data_web <= 1'b1;
//     end
//     else if (start_write_q && curr_tpu_iter == 5) begin
//         ffn_data_web <= 1'b0;
//     end
//     else begin
//         ffn_data_web <= 1'b1;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         ffn_data_addr <= 9'd0;
//     end
//     else if(start_conv_down) begin
//         if(conv_cnt_down == 280) begin
//             ffn_data_addr <= conv_down_ch;
//         end
//         else begin
//             ffn_data_addr <= ffn_data_addr + 2'd2;
//         end
//     end
//     else if (ffn_data_web == 0) begin
//         ffn_data_addr <= ffn_data_addr == 511 ? 0 : ffn_data_addr == 510 ? 1 : ffn_data_addr + 2'd2;
//     end
//     else if(curr_tpu_iter == 7) begin
//         ffn_data_addr <= 0;
//     end
//     else begin
//         ffn_data_addr <= ffn_data_addr;
//     end
// end

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         ffn_data_read_data_r <= 0;
//     end
//     else begin
//         ffn_data_read_data_r <= ffn_data_read_data;
//     end
// end

// Linear_512X64X1BM1 FFN_sram (
//     .CK(clk), .WEB(ffn_data_web), .OE(1'b1), .CS(1'b1),
//     .A0(ffn_data_addr[0]), .A1(ffn_data_addr[1]), .A2(ffn_data_addr[2]), .A3(ffn_data_addr[3]), .A4(ffn_data_addr[4]), .A5(ffn_data_addr[5]), .A6(ffn_data_addr[6]), .A7(ffn_data_addr[7]), .A8(ffn_data_addr[8]), 
//     .DI0(ffn_data_accum[0]),   .DI1(ffn_data_accum[1]),   .DI2(ffn_data_accum[2]),   .DI3(ffn_data_accum[3]),   .DI4(ffn_data_accum[4]),   .DI5(ffn_data_accum[5]),   .DI6(ffn_data_accum[6]),   .DI7(ffn_data_accum[7]),
//     .DI8(ffn_data_accum[8]),   .DI9(ffn_data_accum[9]),   .DI10(ffn_data_accum[10]), .DI11(ffn_data_accum[11]), .DI12(ffn_data_accum[12]), .DI13(ffn_data_accum[13]), .DI14(ffn_data_accum[14]), .DI15(ffn_data_accum[15]),
//     .DI16(ffn_data_accum[16]), .DI17(ffn_data_accum[17]), .DI18(ffn_data_accum[18]), .DI19(ffn_data_accum[19]), .DI20(ffn_data_accum[20]), .DI21(ffn_data_accum[21]), .DI22(ffn_data_accum[22]), .DI23(ffn_data_accum[23]),
//     .DI24(ffn_data_accum[24]), .DI25(ffn_data_accum[25]), .DI26(ffn_data_accum[26]), .DI27(ffn_data_accum[27]), .DI28(ffn_data_accum[28]), .DI29(ffn_data_accum[29]), .DI30(ffn_data_accum[30]), .DI31(ffn_data_accum[31]),
//     .DI32(ffn_data_accum[32]), .DI33(ffn_data_accum[33]), .DI34(ffn_data_accum[34]), .DI35(ffn_data_accum[35]), .DI36(ffn_data_accum[36]), .DI37(ffn_data_accum[37]), .DI38(ffn_data_accum[38]), .DI39(ffn_data_accum[39]),
//     .DI40(ffn_data_accum[40]), .DI41(ffn_data_accum[41]), .DI42(ffn_data_accum[42]), .DI43(ffn_data_accum[43]), .DI44(ffn_data_accum[44]), .DI45(ffn_data_accum[45]), .DI46(ffn_data_accum[46]), .DI47(ffn_data_accum[47]),
//     .DI48(ffn_data_accum[48]), .DI49(ffn_data_accum[49]), .DI50(ffn_data_accum[50]), .DI51(ffn_data_accum[51]), .DI52(ffn_data_accum[52]), .DI53(ffn_data_accum[53]), .DI54(ffn_data_accum[54]), .DI55(ffn_data_accum[55]),
//     .DI56(ffn_data_accum[56]), .DI57(ffn_data_accum[57]), .DI58(ffn_data_accum[58]), .DI59(ffn_data_accum[59]), .DI60(ffn_data_accum[60]), .DI61(ffn_data_accum[61]), .DI62(ffn_data_accum[62]), .DI63(ffn_data_accum[63]),
//     .DO0(ffn_data_read_data[0]),   .DO1(ffn_data_read_data[1]),   .DO2(ffn_data_read_data[2]),   .DO3(ffn_data_read_data[3]),   .DO4(ffn_data_read_data[4]),   .DO5(ffn_data_read_data[5]),   .DO6(ffn_data_read_data[6]),   .DO7(ffn_data_read_data[7]),
//     .DO8(ffn_data_read_data[8]),   .DO9(ffn_data_read_data[9]),   .DO10(ffn_data_read_data[10]), .DO11(ffn_data_read_data[11]), .DO12(ffn_data_read_data[12]), .DO13(ffn_data_read_data[13]), .DO14(ffn_data_read_data[14]), .DO15(ffn_data_read_data[15]),
//     .DO16(ffn_data_read_data[16]), .DO17(ffn_data_read_data[17]), .DO18(ffn_data_read_data[18]), .DO19(ffn_data_read_data[19]), .DO20(ffn_data_read_data[20]), .DO21(ffn_data_read_data[21]), .DO22(ffn_data_read_data[22]), .DO23(ffn_data_read_data[23]),
//     .DO24(ffn_data_read_data[24]), .DO25(ffn_data_read_data[25]), .DO26(ffn_data_read_data[26]), .DO27(ffn_data_read_data[27]), .DO28(ffn_data_read_data[28]), .DO29(ffn_data_read_data[29]), .DO30(ffn_data_read_data[30]), .DO31(ffn_data_read_data[31]),
//     .DO32(ffn_data_read_data[32]), .DO33(ffn_data_read_data[33]), .DO34(ffn_data_read_data[34]), .DO35(ffn_data_read_data[35]), .DO36(ffn_data_read_data[36]), .DO37(ffn_data_read_data[37]), .DO38(ffn_data_read_data[38]), .DO39(ffn_data_read_data[39]),
//     .DO40(ffn_data_read_data[40]), .DO41(ffn_data_read_data[41]), .DO42(ffn_data_read_data[42]), .DO43(ffn_data_read_data[43]), .DO44(ffn_data_read_data[44]), .DO45(ffn_data_read_data[45]), .DO46(ffn_data_read_data[46]), .DO47(ffn_data_read_data[47]),
//     .DO48(ffn_data_read_data[48]), .DO49(ffn_data_read_data[49]), .DO50(ffn_data_read_data[50]), .DO51(ffn_data_read_data[51]), .DO52(ffn_data_read_data[52]), .DO53(ffn_data_read_data[53]), .DO54(ffn_data_read_data[54]), .DO55(ffn_data_read_data[55]),
//     .DO56(ffn_data_read_data[56]), .DO57(ffn_data_read_data[57]), .DO58(ffn_data_read_data[58]), .DO59(ffn_data_read_data[59]), .DO60(ffn_data_read_data[60]), .DO61(ffn_data_read_data[61]), .DO62(ffn_data_read_data[62]), .DO63(ffn_data_read_data[63])
// );
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_check_fetch <= 0;
    end
    else if(sub_cnt2 == sub_end_point && sub_cnt == 3 && interpolation_iter == 15 && iter == iter_reg) begin
        output_check_fetch <= 1;
    end
    else if(output_check_cnt == 4095)begin
        output_check_fetch <= 0;
    end
    else begin
        output_check_fetch <= output_check_fetch;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_check <= 0;
    end
    else if(output_check_cnt == 4095)begin
        output_check <= 0;
    end
    else if(output_check_fetch && out_check_cnt == 2) begin
        output_check <= 1;
    end
    else begin
        output_check <= output_check;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_check_cnt <= 0;
    end
    else if(output_check) begin
        output_check_cnt <= output_check_cnt + 1;
    end
    else begin
        output_check_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_check_cnt <= 0;
    end
    else if(output_check_fetch) begin
        out_check_cnt <= out_check_cnt + 1;
    end
    else begin
        out_check_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_check_data_shift <= 0;
    end
    else if(out_check_cnt == 2) begin
        out_check_data_shift <= image_read_data_r;
    end
    else begin
        out_check_data_shift <= {out_check_data_shift[55:0], 8'd0};
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_valid <= 0;
        o_data <= 0;
    end
    else if(output_check) begin
        o_valid <= 1;
        o_data <= out_check_data_shift[63:56];
    end
    else begin
        o_valid <= 0;
        o_data <= 0;
    end
end

endmodule

module mult_conv(
    input [7:0] a,
    input signed [3:0] b,
    output signed [11:0] result
);
wire signed [8:0] s_a = {1'b0, a};
assign result = $signed({1'b0, a}) * b;

endmodule

module PE(
    input clk,
    input rst_n,
    input       flush_i,
    input signed[7:0] vertical_data_i,
    input signed[8:0] horizontal_data_i,
    output reg [7:0] vertical_data_o,
    output reg [8:0] horizontal_data_o,
    output reg signed[23:0] result_o
);
wire signed [16:0] mult_result;
reg signed [16:0] mult_result_r;
assign mult_result = vertical_data_i * horizontal_data_i;
wire signed [23:0] add_sel;

assign add_sel = flush_i ? 0 : result_o;
always @(posedge clk or negedge rst_n) begin
   if(!rst_n)begin
        vertical_data_o <= 8'b0;
        horizontal_data_o <= 9'b0;
        result_o <= 24'b0;
        mult_result_r <= 17'b0;
     end else begin
        vertical_data_o <= vertical_data_i;
        horizontal_data_o <= horizontal_data_i;
        result_o <= mult_result_r + add_sel; 
        mult_result_r <= mult_result;
    end
end
endmodule
