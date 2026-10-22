//synopsys translate_off
`include "SORT_IP.v"
//synopsys translate_on

module HT(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_weight, 
	out_mode,
    // Output signals
    out_valid, 
	out_code
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid, out_mode;
input [2:0] in_weight;

output reg out_valid, out_code;

// ===============================================================
// Reg & Wire Declaration
// ===============================================================
reg in_w_greater [6:0];
reg [2:0] weight [7:0];
reg [2:0] sorted_weight [7:0];
reg [7:0] alpha [7:0];
reg [7:0] sorted_alpha [7:0];
reg [7:0] curr_input_alpha;
reg [7:0] curr_input_alpha_c;
integer  i,j,k;
// reg [2:0] end_flag_r [7:0];
// 14
reg [3:0] merged_weight0;
reg [7:0] merged_alpha0;
reg [3:0] weight0 [6:0];
reg [7:0] alpha0 [6:0];
reg [3:0] sorted_weight0 [6:0];
reg [7:0] sorted_alpha0 [6:0];
reg merge_w0_greater [5:0];
reg [1:0] code0 [7:0];
// 21
reg [4:0] merged_weight1;
reg [7:0] merged_alpha1;
reg [4:0] weight1 [5:0];
reg [7:0] alpha1 [5:0];
reg merge_w1_greater [4:0];
reg [2:0] code1 [7:0];
// 28
reg [4:0] merged_weight2;
reg [7:0] merged_alpha2;
reg [4:0] weight2 [4:0];
reg [7:0] alpha2 [4:0];
reg merge_w2_greater [3:0];
reg [3:0] code2 [7:0];
// 35
reg [5:0] merged_weight3;
reg [7:0] merged_alpha3;
reg [5:0] weight3 [3:0];
reg [7:0] alpha3 [3:0];
reg merge_w3_greater [2:0];
reg [4:0] code3 [7:0];
 // 42
reg [5:0] merged_weight4;
reg [7:0] merged_alpha4;
reg [5:0] weight4 [2:0];
reg [7:0] alpha4 [2:0];
reg merge_w4_greater [1:0];
reg [5:0] code4 [7:0];
// 49
reg [5:0] merged_weight5;
reg [7:0] merged_alpha5;
reg [5:0] weight5 [1:0];
reg [7:0] alpha5 [1:0];
reg merge_w5_greater;
reg [6:0] code5 [7:0];

//
reg [7:0] code6 [7:0];
reg [7:0] code_output_reg [7:0];
wire is_end [7:0];
wire [2:0] curr_alpha, next_alpha;
reg [2:0] curr_idx [4:0];
reg mode_reg;
reg [2:0] cnt, next_cnt;
// reg [2:0] out_cnt;
// 4 5 6 7 3
// 4 2 5 0 1
// localparam I = 1; // 4
// localparam L = 2; // 5
// localparam O = 3; // 6
// localparam V = 4; // 7
// localparam E = 5; // 3
// localparam C = 6; // 2
// localparam A = 7; // 0
// localparam B = 8; // 1
assign is_end[0] = code_output_reg[0][6:0] == 7'b1000000;
assign is_end[1] = code_output_reg[1][6:0] == 7'b1000000;
assign is_end[2] = code_output_reg[2][6:0] == 7'b1000000;
assign is_end[3] = code_output_reg[3][6:0] == 7'b1000000;
assign is_end[4] = code_output_reg[4][6:0] == 7'b1000000;
assign is_end[5] = code_output_reg[5][6:0] == 7'b1000000;
assign is_end[6] = code_output_reg[6][6:0] == 7'b1000000;
assign is_end[7] = code_output_reg[7][6:0] == 7'b1000000;

always @(*) begin
    if(mode_reg) begin
        curr_idx[0] = 4;
        curr_idx[1] = 2;
        curr_idx[2] = 5;
        curr_idx[3] = 0;
        curr_idx[4] = 1;
    end
    else begin
        curr_idx[0] = 4;
        curr_idx[1] = 5;
        curr_idx[2] = 6;
        curr_idx[3] = 7;
        curr_idx[4] = 3;
    end
end
assign curr_alpha = curr_idx[cnt-2];
assign next_alpha = curr_idx[cnt-1];
// ===============================================================
// Design
// ===============================================================
always @(*) begin
    case(cnt) 
        0: curr_input_alpha_c = in_valid ? curr_input_alpha << 1 : 1;
        1: curr_input_alpha_c = curr_input_alpha << 1;
        default: curr_input_alpha_c = 0;
    endcase
end
always @(posedge clk) begin
    curr_input_alpha <= curr_input_alpha_c;
end
wire [3:0]  out_char0, out_char1;
SORT_IP #(2) sort_ip (
    .IN_character({ 4'd0,              4'd1          }), 
    .IN_weight   ({ 2'b0, sorted_weight[0], 2'b0, in_weight }), 
    .OUT_character({ out_char1, out_char0 })
);
always @(*) begin
    in_w_greater[0] = out_char1 || !(|sorted_alpha[0]) ? 1 : 0;
    // in_w_greater[0] = (in_weight > sorted_weight[0]) || !(|sorted_alpha[0]) ? 1 : 0;
    for(i = 1;i <= 6;i = i + 1) begin
        in_w_greater[i] = (in_weight > sorted_weight[i] || !(|sorted_alpha[i])) ? 1 : 0;
    end
end

always @(*) begin
    if(in_valid) begin
        if(in_w_greater[3]) begin
            if(in_w_greater[1]) begin
                if(in_w_greater[0])begin
                    weight[0] = in_weight;
                    
                    weight[7:1] = sorted_weight[6:0];
                    alpha[0] = curr_input_alpha;
                    alpha[7:1] = sorted_alpha[6:0];
                end
                else begin
                    weight[1] = in_weight;
                    weight[7:2] = sorted_weight[6:1];
                    weight[0] = sorted_weight[0];

                    alpha[1] = curr_input_alpha;
                    alpha[7:2] = sorted_alpha[6:1];
                    alpha[0] = sorted_alpha[0];
                end
            end
            else begin
                if(in_w_greater[2])begin
                    weight[2] = in_weight;
                    weight[1:0] = sorted_weight[1:0];
                    weight[7:3] = sorted_weight[6:2];

                    alpha[2] = curr_input_alpha;
                    alpha[1:0] = sorted_alpha[1:0];
                    alpha[7:3] = sorted_alpha[6:2];
                end
                else begin
                    weight[3] = in_weight;
                    weight[7:4] = sorted_weight[6:3];
                    weight[2:0] = sorted_weight[2:0];

                    alpha[3] = curr_input_alpha;
                    alpha[7:4] = sorted_alpha[6:3];
                    alpha[2:0] = sorted_alpha[2:0];
                end
            end
        end
        else begin
            if(in_w_greater[5]) begin
                if(in_w_greater[4])begin
                    weight[4] = in_weight;
                    weight[7:5] = sorted_weight[6:4];
                    weight[3:0] = sorted_weight[3:0];

                    alpha[4] = curr_input_alpha;
                    alpha[7:5] = sorted_alpha[6:4];
                    alpha[3:0] = sorted_alpha[3:0];
                end
                else begin
                    weight[5] = in_weight;
                    weight[7:6] = sorted_weight[6:5];
                    weight[4:0] = sorted_weight[4:0];

                    alpha[5] = curr_input_alpha;
                    alpha[7:6] = sorted_alpha[6:5];
                    alpha[4:0] = sorted_alpha[4:0];
                end
            end
            else begin
                if(in_w_greater[6])begin
                    weight[6] = in_weight;
                    weight[7] = sorted_weight[6];
                    weight[5:0] = sorted_weight[5:0];

                    alpha[6] = curr_input_alpha;
                    alpha[7] = sorted_alpha[6];
                    alpha[5:0] = sorted_alpha[5:0];
                end
                else begin
                    weight[7] = in_weight;
                    weight[6:0] = sorted_weight[6:0];

                    alpha[7] = curr_input_alpha;
                    alpha[6:0] = sorted_alpha[6:0];
                end
            end
        end
    end
    else begin
        for(i = 0;i <= 7;i = i + 1) begin
            weight[i] = 0;
            alpha[i] = 0;
        end
    end
end

always @(posedge clk) begin
        sorted_weight[7:0] <= weight[7:0];
        sorted_alpha[7:0] <= alpha[7:0];
end

// merge 0
always @(*) begin
    merged_weight0 = weight[6] + weight[7];
    merged_alpha0 = alpha[6] | alpha[7];
end
always @(*) begin
    for(i = 0;i <= 5;i = i + 1) begin
        merge_w0_greater[i] = (merged_weight0 > weight[i]) ? 1 : 0;
    end
end

always @(*) begin
    if(merge_w0_greater[3]) begin
        if(merge_w0_greater[1]) begin
            if(merge_w0_greater[0]) begin
                weight0[0] = merged_weight0;
                alpha0[0]  = merged_alpha0;
                for(i = 1; i <= 6; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i-1]};
                    alpha0[i]  = alpha[i-1];
                end
            end
            else begin
                weight0[1] = merged_weight0;
                alpha0[1]  = merged_alpha0;
                weight0[0] = {1'b0, weight[0]};
                alpha0[0]  = alpha[0];
                for(i = 2; i <= 6; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i-1]};
                    alpha0[i]  = alpha[i-1];
                end
            end
        end
        else begin
            if(merge_w0_greater[2]) begin
                weight0[2] = merged_weight0;
                alpha0[2]  = merged_alpha0;
                for(i = 0; i <= 1; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i]};
                    alpha0[i]  = alpha[i];
                end
                for(i = 3; i <= 6; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i-1]};
                    alpha0[i]  = alpha[i-1];
                end
            end
            else begin
                weight0[3] = merged_weight0;
                alpha0[3]  = merged_alpha0;
                for(i = 0; i <= 2; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i]};
                    alpha0[i]  = alpha[i];
                end
                for(i = 4; i <= 6; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i-1]};
                    alpha0[i]  = alpha[i-1];
                end
            end
        end
    end
    else begin
        if(merge_w0_greater[5]) begin
            if(merge_w0_greater[4]) begin
                weight0[4] = merged_weight0;
                alpha0[4]  = merged_alpha0;
                for(i = 0; i <= 3; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i]};
                    alpha0[i]  = alpha[i];
                end
                for(i = 5; i <= 6; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i-1]};
                    alpha0[i]  = alpha[i-1];
                end
            end
            else begin
                weight0[5] = merged_weight0;
                alpha0[5]  = merged_alpha0;
                for(i = 0; i <= 4; i = i + 1) begin
                    weight0[i] = {1'b0, weight[i]};
                    alpha0[i]  = alpha[i];
                end
                weight0[6] = {1'b0, weight[5]};
                alpha0[6]  = alpha[5];
            end
        end
        else begin
            weight0[6] = merged_weight0;
            alpha0[6]  = merged_alpha0;
            for(i = 0; i <= 5; i = i + 1) begin
                weight0[i] = {1'b0, weight[i]};
                alpha0[i]  = alpha[i];
            end
        end
    end
end
always @(posedge clk) begin
        sorted_weight0[6:0] <= weight0[6:0];
        sorted_alpha0[6:0] <= alpha0[6:0];
end
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         end_flag_r <= '{default:0};
//     end
//     else begin
//         for(i = 0;i <= 7;i = i + 1) begin
//             if(merged_alpha0[i]) begin
//                 end_flag_r[i] <= 1;
//             end
//             else begin
//                 end_flag_r[i] <= 0;
//             end
//         end
//     end
// end
always @(posedge clk) begin
        for(i = 0;i <= 7;i = i + 1) begin
            if(alpha[6][i]) begin
                code0[i] <= 2'b01;
            end
            else 
            if(alpha[7][i]) begin
                code0[i] <= 2'b11;
            end
            else begin
                code0[i] <= 2'b10;
            end
        end
end

// merge 1
always @(*) begin
    merged_weight1 = sorted_weight0[5] + sorted_weight0[6];
    merged_alpha1 = sorted_alpha0[5] | sorted_alpha0[6];
end
always @(*) begin
    for(i = 0;i <= 4;i = i + 1) begin
        merge_w1_greater[i] = (merged_weight1 > sorted_weight0[i]) ? 1 : 0;
    end
end
always @(*) begin
    if(merge_w1_greater[2]) begin
        if(merge_w1_greater[0]) begin
            weight1[0] = merged_weight1; 
            alpha1[0]  = merged_alpha1;
            for(i = 1; i <= 5; i = i + 1) begin
                weight1[i] = {1'b0, sorted_weight0[i-1]};
                alpha1[i]  = sorted_alpha0[i-1];
            end
        end else begin
            if(merge_w1_greater[1]) begin
                weight1[1] = merged_weight1;
                alpha1[1]  = merged_alpha1;
                weight1[0] = {1'b0, sorted_weight0[0]};
                alpha1[0]  = sorted_alpha0[0];
                for(i = 2; i <= 5; i = i + 1) begin
                    weight1[i] = {1'b0, sorted_weight0[i-1]};
                    alpha1[i]  = sorted_alpha0[i-1];
                end
            end else begin
                weight1[2] = merged_weight1;
                alpha1[2]  = merged_alpha1;
                for(i = 0; i <= 1; i = i + 1) begin
                    weight1[i] = {1'b0, sorted_weight0[i]};
                    alpha1[i]  = sorted_alpha0[i];
                end
                for(i = 3; i <= 5; i = i + 1) begin
                    weight1[i] = {1'b0, sorted_weight0[i-1]};
                    alpha1[i]  = sorted_alpha0[i-1];
                end
            end
        end
    end
    else begin
        if(merge_w1_greater[3]) begin
            weight1[3] = merged_weight1;
            alpha1[3]  = merged_alpha1;
            for(i = 0; i <= 2; i = i + 1) begin
                weight1[i] = {1'b0, sorted_weight0[i]};
                alpha1[i]  = sorted_alpha0[i];
            end
            for(i = 4; i <= 5; i = i + 1) begin
                weight1[i] = {1'b0, sorted_weight0[i-1]};
                alpha1[i]  = sorted_alpha0[i-1];
            end
        end else begin
            if(merge_w1_greater[4]) begin
                weight1[4] = merged_weight1;
                alpha1[4]  = merged_alpha1;
                for(i = 0; i <= 3; i = i + 1) begin
                    weight1[i] = {1'b0, sorted_weight0[i]};
                    alpha1[i]  = sorted_alpha0[i];
                end
                weight1[5] = {1'b0, sorted_weight0[4]};
                alpha1[5]  = sorted_alpha0[4];
            end else begin
                weight1[5] = merged_weight1;
                alpha1[5]  = merged_alpha1;
                for(i = 0; i <= 4; i = i + 1) begin
                    weight1[i] = {1'b0, sorted_weight0[i]};
                    alpha1[i]  = sorted_alpha0[i];
                end
            end
        end
    end
end

// always @(*) begin
//     for(i = 0;i <= 7;i = i + 1) begin
//         if(merged_alpha1[i]) begin
//             end_flag_1[i] = end_flag_r[i] + 1;
//         end
//         else begin
//             end_flag_1[i] = end_flag_r[i];
//         end
//     end
// end
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(sorted_alpha0[5][i]) begin
            code1[i] = {1'b0, code0[i]};
        end
        else 
        if(sorted_alpha0[6][i]) begin
            code1[i] = {1'b1, code0[i]};
        end
        else begin
            code1[i] = {code0[i], 1'b0};
        end
    end
end

// merge 2
always @(*) begin
    merged_weight2 = weight1[5] + weight1[4];
    merged_alpha2 = alpha1[5] | alpha1[4];
end
 
always @(*) begin
    for(i = 0;i <= 3;i = i + 1) begin
        merge_w2_greater[i] = (merged_weight2 > weight1[i]) ? 1 : 0;
    end
end
 
always @(*) begin
    if(merge_w2_greater[2]) begin
        if(merge_w2_greater[0]) begin
        weight2[0] = merged_weight2;
        weight2[4:1] = weight1[3:0];
        alpha2[0] = merged_alpha2;
        alpha2[4:1] = alpha1[3:0];
        end else if(merge_w2_greater[1]) begin
            weight2[1] = merged_weight2;
            weight2[0] = weight1[0];
            weight2[4:2] = weight1[3:1];
            alpha2[1] = merged_alpha2;
            alpha2[0] = alpha1[0];
            alpha2[4:2] = alpha1[3:1];
        end 
        else begin
            weight2[2] = merged_weight2;
            weight2[1:0] = weight1[1:0];
            weight2[4:3] = weight1[3:2];
            alpha2[2] = merged_alpha2;
            alpha2[1:0] = alpha1[1:0];
            alpha2[4:3] = alpha1[3:2];
        end
    end
    else begin
        if(merge_w2_greater[3]) begin
            weight2[3] = merged_weight2;
            weight2[2:0] = weight1[2:0];
            weight2[4] = weight1[3];
            alpha2[3] = merged_alpha2;
            alpha2[2:0] = alpha1[2:0];
            alpha2[4] = alpha1[3];
        end else begin
            weight2[4] = merged_weight2;
            weight2[3:0] = weight1[3:0];
            alpha2[4] = merged_alpha2;
            alpha2[3:0] = alpha1[3:0];
        end
    end
end
 
// always @(*) begin
//     for(i = 0;i <= 7;i = i + 1) begin
//         if(merged_alpha2[i]) begin
//             end_flag_2[i] = end_flag_1[i] + 1;
//         end
//         else begin
//             end_flag_2[i] = end_flag_1[i];
//         end
//     end
// end
 
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(alpha1[4][i]) begin
            code2[i] = {1'b0, code1[i]};
        end
        else 
        if(alpha1[5][i]) begin
            code2[i] = {1'b1, code1[i]};
        end
        else begin
            code2[i] = {code1[i],1'b0};
        end
    end
end
 
// ==================== MERGE 3 ====================
always @(*) begin
    merged_weight3 = weight2[4] + weight2[3];
    merged_alpha3 = alpha2[4] | alpha2[3];
end
 
always @(*) begin
    for(i = 0;i <= 2;i = i + 1) begin
        merge_w3_greater[i] = (merged_weight3 > weight2[i]) ? 1 : 0;
    end
end
 
always @(*) begin
    if(merge_w3_greater[2]) begin
        if(merge_w3_greater[0]) begin
            weight3[0] = merged_weight3; 
            alpha3[0]  = merged_alpha3;
            for(i = 1; i <= 3; i = i + 1) begin
                weight3[i] = {1'b0, weight2[i-1]};
                alpha3[i]  = alpha2[i-1];
            end
        end else begin
            if(merge_w3_greater[1]) begin
                weight3[1] = merged_weight3;
                alpha3[1]  = merged_alpha3;
                
                weight3[0] = {1'b0, weight2[0]};
                alpha3[0]  = alpha2[0];
                
                for(i = 2; i <= 3; i = i + 1) begin
                    weight3[i] = {1'b0, weight2[i-1]};
                    alpha3[i]  = alpha2[i-1];
                end
            end else begin
                weight3[2] = merged_weight3;
                alpha3[2]  = merged_alpha3;
                
                for(i = 0; i <= 1; i = i + 1) begin
                    weight3[i] = {1'b0, weight2[i]};
                    alpha3[i]  = alpha2[i];
                end
                
                weight3[3] = {1'b0, weight2[2]};
                alpha3[3]  = alpha2[2];
            end
        end
    end
    else begin
        weight3[3] = merged_weight3;
        alpha3[3]  = merged_alpha3;
        
        for(i = 0; i <= 2; i = i + 1) begin
            weight3[i] = {1'b0, weight2[i]};
            alpha3[i]  = alpha2[i];
        end
    end
end

// always @(*) begin
//     for(i = 0;i <= 7;i = i + 1) begin
//         if(merged_alpha3[i]) begin
//             end_flag_3[i] = end_flag_2[i] + 1;
//         end
//         else begin
//             end_flag_3[i] = end_flag_2[i];
//         end
//     end
// end
 
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(alpha2[3][i]) begin
            code3[i] = {1'b0, code2[i]};
        end
        else 
        if(alpha2[4][i]) begin
            code3[i] = {1'b1, code2[i]};
        end
        else begin
            code3[i] = {code2[i],1'b0};
        end
    end
end

always @(*) begin
    merged_weight4 = weight3[3] + weight3[2];
    merged_alpha4 = alpha3[3] | alpha3[2];
end
 
always @(*) begin
    for(i = 0;i <= 1;i = i + 1) begin
        merge_w4_greater[i] = (merged_weight4 > weight3[i]) ? 1 : 0;
    end
end
 
always @(*) begin
  if(merge_w4_greater[1]) begin
    if(merge_w4_greater[0]) begin
      weight4[0] = merged_weight4;
      weight4[2:1] = weight3[1:0];
      alpha4[0] = merged_alpha4;
      alpha4[2:1] = alpha3[1:0];
    end else begin
      weight4[1] = merged_weight4;
      weight4[0] = weight3[0];
      weight4[2] = weight3[1];
      alpha4[1] = merged_alpha4;
      alpha4[0] = alpha3[0];
      alpha4[2] = alpha3[1];
    end
  end else begin
    weight4[2] = merged_weight4;
    weight4[1:0] = weight3[1:0];
    alpha4[2] = merged_alpha4;
    alpha4[1:0] = alpha3[1:0];
  end
end
 
// always @(*) begin
//     for(i = 0;i <= 7;i = i + 1) begin
//         if(merged_alpha4[i]) begin
//             end_flag_4[i] = end_flag_3[i] + 1;
//         end
//         else begin
//             end_flag_4[i] = end_flag_3[i];
//         end
//     end
// end
 
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(alpha3[2][i]) begin
            code4[i] = {1'b0, code3[i]};
        end
        else 
        if(alpha3[3][i]) begin
            code4[i] = {1'b1, code3[i]};
        end
        else begin
            code4[i] = {code3[i],1'b0};
        end
    end
end
 
// ==================== MERGE 5 ====================
always @(*) begin
    merged_weight5 = weight4[2] + weight4[1];
    merged_alpha5 = alpha4[2] | alpha4[1];
end
 
always @(*) begin
    merge_w5_greater = (merged_weight5 > weight4[0]) ? 1 : 0;
end
 
always @(*) begin
  if(merge_w5_greater) begin
    weight5[0] = merged_weight5;
    weight5[1] = weight4[0];
    alpha5[0] = merged_alpha5;
    alpha5[1] = alpha4[0];
  end else begin
    weight5[1] = merged_weight5;
    weight5[0] = weight4[0];
    alpha5[1] = merged_alpha5;
    alpha5[0] = alpha4[0];
  end
end
 
// always @(*) begin
//     for(i = 0;i <= 7;i = i + 1) begin
//         if(merged_alpha5[i]) begin
//             end_flag_5[i] = end_flag_4[i] + 1;
//         end
//         else begin
//             end_flag_5[i] = end_flag_4[i];
//         end
//     end
// end
 
always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(alpha4[1][i]) begin
            code5[i] = {1'b0, code4[i]};
        end
        else 
        if(alpha4[2][i]) begin
            code5[i] = {1'b1, code4[i]};
        end
        else begin
            code5[i] = {code4[i],1'b0};
        end
    end
end

// always @(*) begin
//     for(i = 0;i <= 7;i = i + 1) begin
//         if(alpha5[0][i] || alpha5[1][i]) begin
//             end_flag_6[i] = end_flag_5[i] + 1;
//         end
//         else begin
//             end_flag_6[i] = end_flag_5[i];
//         end
//     end
// end

always @(*) begin
    for(i = 0;i <= 7;i = i + 1) begin
        if(alpha5[0][i]) begin
            code6[i] = {1'b0, code5[i]};
        end
        else 
        if(alpha5[1][i]) begin
            code6[i] = {1'b1, code5[i]};
        end
        else begin
            code6[i] = {code5[i],1'b0};
        end
    end
end
always @(posedge clk) begin
    if(curr_input_alpha == 0 && cnt == 1) begin
        for(i = 0;i <= 7;i = i + 1) begin
            code_output_reg[i] <= code6[i];
        end
    end
    else begin
        for(i = 0;i <= 7;i = i + 1) begin
            if(curr_alpha == i) begin
                code_output_reg[i] <= code_output_reg[i] << 1;
            end
            else begin
                code_output_reg[i] <= code_output_reg[i];
            end
        end
    end
end
always @(*) begin
    case(cnt) 
        0: next_cnt = in_valid ? 1 : 0;
        1: next_cnt = curr_input_alpha == 0 ? 2 : 1;
        2,3,4,5,6: next_cnt = is_end[curr_alpha] ? cnt == 6 ? 0 : cnt + 1 : cnt;
        default: next_cnt = 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 0;
    end
    else begin
        cnt <= next_cnt;
    end
end
always @(posedge clk) begin
    if(in_valid && cnt == 0) begin
        mode_reg <= out_mode;
    end
    else begin
        mode_reg <= mode_reg;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_code <= 0;
        out_valid <= 0;
    end
    else if(cnt == 1) begin
        out_valid <= curr_input_alpha == 0;
        out_code <= curr_input_alpha == 0 ? code6[4][7] : 0;
    end
    else if(cnt > 1) begin
        if(is_end[curr_alpha]) begin
            if(cnt == 6) begin
                out_code <= 0;
                out_valid <= 0;
            end
            else begin
                out_code <= code_output_reg[next_alpha][7];
                out_valid <= 1;
            end
        end
        else begin
            out_code <= code_output_reg[curr_alpha][6];
            out_valid <= 1;
        end
    end
    else begin
        out_code <= 0;
        out_valid <= 0;
    end
end

endmodule