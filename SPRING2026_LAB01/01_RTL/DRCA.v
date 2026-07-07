module DRCA (
    input [3:0]  drc_sel,
    input [18:0] shape0 ,
    input [18:0] shape1 ,
    input [18:0] shape2 ,
    input [18:0] shape3 ,
    input [18:0] shape4 ,
    input [18:0] shape5 ,
    input [18:0] shape6 ,
    input [18:0] shape7 ,
    input [18:0] shape8 ,
    input [18:0] shape9 ,
    input [18:0] shape10 ,
    input [18:0] shape11 ,
    input [18:0] shape12 ,
    input [18:0] shape13 ,
    input [18:0] shape14 ,
    input [18:0] shape15 ,
    output [4:0] drc_out
);
// wire drc_out;

//**************************************************
// Parameter 
//************************************************** 
integer i, j, k;
genvar gen_i;
//**************************************************
// Reg & Wire 
//**************************************************
reg [2:0] requirement;
wire [2:0] shape_sel;
wire [18:0] shapes [0:15];
reg [15:0] shape_match;
reg [14:0] x_mask [0:15]; 
reg [14:0] y_mask [0:15]; 
reg [14:0] has_val[0:14];

wire [14:0] X_is_end_point [0:15];
reg [4:0] X_drc_result [0:14];
wire [14:0] Y_is_end_point [0:15];
reg [4:0] Y_drc_result [0:14];
wire [44:0] X_accum_result [0:15];
wire [44:0] Y_accum_result [0:15];
wire [7:0] X_LR_val [0:15];
wire [7:0] Y_LR_val [0:15];
wire [4:0] x_sum, y_sum;
//**************************************************
// Design 
//**************************************************

always @(*) begin
    case (drc_sel)
        4'b0000, 4'b0001, 4'b0011, 4'b0100, 4'b0101, 4'b0111:  requirement = 3'd2;
        4'b0010, 4'b0110, 4'b1001, 4'b1011:             requirement = 3'd3;
        4'b1000, 4'b1010, 4'b1101:                  requirement = 3'd4;
        4'b1100:                               requirement = 3'd5;
        default:                             requirement = 3'd0;
    endcase
end

assign shape_sel = (drc_sel >> 1) + 1;

assign shapes[0] = shape0;
assign shapes[1] = shape1;
assign shapes[2] = shape2;
assign shapes[3] = shape3;
assign shapes[4] = shape4;
assign shapes[5] = shape5;
assign shapes[6] = shape6;
assign shapes[7] = shape7;
assign shapes[8] = shape8;
assign shapes[9] = shape9;
assign shapes[10] = shape10;
assign shapes[11] = shape11;
assign shapes[12] = shape12;
assign shapes[13] = shape13;
assign shapes[14] = shape14;
assign shapes[15] = shape15;

always @(*) begin
    for (k = 0; k < 16; k = k + 1) begin
        shape_match[k] = (shapes[k][18:16] == shape_sel);
    end
end

always @(*) begin
    for (k = 0; k < 16; k = k + 1) begin
        for (i = 0; i < 15; i = i + 1) begin
            x_mask[k][i] = (i >= shapes[k][15:12]) && (i < shapes[k][7:4]);
            y_mask[k][i] = (i >= shapes[k][11:8])  && (i < shapes[k][3:0]);
        end
    end
end

always @(*) begin
    for (i = 0; i < 15; i = i + 1) begin
        has_val[i] = 0;
        for (k = 0; k < 16; k = k + 1) begin
            if (shape_match[k] && y_mask[k][i]) begin
                has_val[i] = has_val[i] | x_mask[k];
            end
        end
    end
end

generate
    assign X_is_end_point[0] = 0;
    assign X_accum_result[0] = 0;
    assign X_LR_val[0] = 0;
    for(gen_i = 0; gen_i < 15; gen_i = gen_i + 1) begin
        drc_check u_drc_check_X (
            .has_val_row(has_val[gen_i]),
            .prev_is_end_point(X_is_end_point[gen_i]),
            .requirement(requirement),
            .prev_accum_result(X_accum_result[gen_i]),
            .prev_LR_val(X_LR_val[gen_i]),
            .is_width_check(~drc_sel[0]),
            .is_end_point(X_is_end_point[gen_i+1]),
            .drc_result(X_drc_result[gen_i]),
            .accum_result(X_accum_result[gen_i+1]),
            .LR_val(X_LR_val[gen_i+1])
        );
    end
endgenerate

generate
    assign Y_is_end_point[0] = 0;
    assign Y_LR_val[0] = 0;
    assign Y_accum_result[0] = 0;
    for(gen_i = 0; gen_i < 15; gen_i = gen_i + 1) begin
        drc_check u_drc_check_Y (
            .has_val_row({has_val[14][gen_i], has_val[13][gen_i], has_val[12][gen_i], has_val[11][gen_i], has_val[10][gen_i], has_val[9][gen_i], has_val[8][gen_i], has_val[7][gen_i], has_val[6][gen_i], has_val[5][gen_i], has_val[4][gen_i], has_val[3][gen_i], has_val[2][gen_i], has_val[1][gen_i], has_val[0][gen_i]}),
            .prev_is_end_point(Y_is_end_point[gen_i]),
            .requirement(requirement),
            .prev_LR_val(Y_LR_val[gen_i]),
            .prev_accum_result(Y_accum_result[gen_i]),
            .is_width_check(~drc_sel[0]),
            .is_end_point(Y_is_end_point[gen_i+1]),
            .drc_result(Y_drc_result[gen_i]),
            .accum_result(Y_accum_result[gen_i+1]),
            .LR_val(Y_LR_val[gen_i+1])
        );
    end
endgenerate

assign x_sum =
    ((X_drc_result[0]  + X_drc_result[1])  + (X_drc_result[2]  + X_drc_result[3])) +
    ((X_drc_result[4]  + X_drc_result[5])  + (X_drc_result[6]  + X_drc_result[7])) +
    ((X_drc_result[8]  + X_drc_result[9])  + (X_drc_result[10] + X_drc_result[11])) +
    ((X_drc_result[12] + X_drc_result[13]) +  X_drc_result[14]);

assign y_sum =
    ((Y_drc_result[0]  + Y_drc_result[1])  + (Y_drc_result[2]  + Y_drc_result[3])) +
    ((Y_drc_result[4]  + Y_drc_result[5])  + (Y_drc_result[6]  + Y_drc_result[7])) +
    ((Y_drc_result[8]  + Y_drc_result[9])  + (Y_drc_result[10] + Y_drc_result[11])) +
    ((Y_drc_result[12] + Y_drc_result[13]) +  Y_drc_result[14]);

assign drc_out = x_sum + y_sum;
endmodule

module drc_check (
    input [14:0] has_val_row,
    input [14:0] prev_is_end_point,
    input [2:0] requirement,
    input [44:0] prev_accum_result,
    input       is_width_check,
    input [7:0] prev_LR_val,
    output     [14:0] is_end_point,
    output     [4:0] drc_result,
    output     [44:0] accum_result,
    output [7:0] LR_val
);
wire [7:0] is_end_point_l, is_end_point_r;
wire [3:0] drc_result_l, drc_result_r;
wire [23:0] accum_result_l, accum_result_r;
wire [3:0] L_last_val, R_last_val;
wire L_last_has_val, R_last_has_val;
wire [2:0] L_val, R_val;
wire [3:0] LR_sum, prev_LR_sum;
reg  mid_violation;
wire [2:0] prev_L_val, prev_R_val;
wire prev_L_has_val, prev_R_has_val;
width_check u_width_check_left (
            .has_val_row(has_val_row[7:0]),
            .prev_is_end_point(prev_is_end_point[7:0]),
            .requirement(requirement),
            .prev_accum_result(prev_accum_result[23:0]),
            .is_width_check(is_width_check),
            .is_end_point(is_end_point_l),
            .drc_result(drc_result_l),
            .accum_result(accum_result_l),
            .last_val(L_last_val)
        );
width_check u_width_check_right (
            .has_val_row({has_val_row[8], has_val_row[9],has_val_row[10],has_val_row[11],has_val_row[12],has_val_row[13],has_val_row[14], 1'b0}),
            .prev_is_end_point({prev_is_end_point[14:8], 1'b0}),
            .requirement(requirement),
            .prev_accum_result({prev_accum_result[44:24], 3'b0}),
            .is_width_check(is_width_check),
            .is_end_point(is_end_point_r),
            .drc_result(drc_result_r),
            .accum_result(accum_result_r),
            .last_val(R_last_val)
        );
assign is_end_point = {is_end_point_r[7:1],is_end_point_l};
assign accum_result = {accum_result_r[23:3], accum_result_l};

assign prev_L_val = prev_LR_val[6:4];
assign prev_R_val = prev_LR_val[2:0];
assign prev_L_has_val = prev_LR_val[7];
assign prev_R_has_val = prev_LR_val[3];
assign L_val = L_last_val[2:0];
assign R_val = R_last_val[2:0];
assign L_last_has_val = L_last_val[3];
assign R_last_has_val = R_last_val[3];
assign LR_sum = L_val + R_val;
assign prev_LR_sum = prev_L_val + prev_R_val;
always @(*) begin
    mid_violation = 0;
    if(LR_sum > 0 && LR_sum < requirement) begin
        if(is_width_check || ((L_val > 0 && R_val > 0) || (L_val > 0 && R_last_has_val) || (R_val > 0 && L_last_has_val))) begin
            if(prev_LR_sum == 0 || prev_LR_sum >= requirement) begin
                mid_violation = 1;
            end
            else if(L_val != prev_L_val || R_val != prev_R_val) begin
                mid_violation = 1;
            end
            else if(!is_width_check && ((prev_L_val > 0 && prev_R_val == 0 && !prev_R_has_val) || (prev_R_val > 0 && prev_L_val == 0 && !prev_L_has_val))) begin
                mid_violation = 1;
            end
            else begin
                mid_violation = 0;
            end
        end
    end
    else begin
        mid_violation = 0;
    end
end

assign drc_result = drc_result_l + drc_result_r + mid_violation;
assign LR_val = {L_last_val, R_last_val};
endmodule

module width_check (
    input [7:0] has_val_row,
    input [7:0] prev_is_end_point,
    input [2:0] requirement,
    input [23:0] prev_accum_result,
    input       is_width_check,
    output reg [7:0] is_end_point,
    output reg [3:0] drc_result,
    output     [23:0] accum_result,
    output     [3:0] last_val
);
reg [2:0] accum_cnt_row [0:7];
reg  [2:0] prev_accum_cnt_row [0:7];
reg  [7:0] tmp_drc_result;
integer i;
assign last_val = {has_val_row[7], accum_cnt_row[7]};
always @(*) begin
    prev_accum_cnt_row[0] = prev_accum_result[2:0];
    prev_accum_cnt_row[1] = prev_accum_result[5:3];
    prev_accum_cnt_row[2] = prev_accum_result[8:6];
    prev_accum_cnt_row[3] = prev_accum_result[11:9];
    prev_accum_cnt_row[4] = prev_accum_result[14:12];
    prev_accum_cnt_row[5] = prev_accum_result[17:15];
    prev_accum_cnt_row[6] = prev_accum_result[20:18];
    prev_accum_cnt_row[7] = prev_accum_result[23:21];
end

always @(*) begin
    accum_cnt_row[0] = 0;
    is_end_point[0] = 0;
    tmp_drc_result[0] = 0;
    if(is_width_check == 1 && has_val_row[0] == 1) begin
        accum_cnt_row[0] = 1;
        if(has_val_row[1] == 0) begin
            is_end_point[0] = 1;
            if(prev_is_end_point[0] == 0) begin 
                tmp_drc_result[0] = 1;
            end
            else begin
                tmp_drc_result[0] = 0;
            end
        end
        else begin
            is_end_point[0] = 0;
            tmp_drc_result[0] = 0;
        end
    end
    else begin
        accum_cnt_row[0] = 0;
        is_end_point[0] = 0;
        tmp_drc_result[0] = 0;
    end
end

always @(*) begin
    for(i = 1; i <= 7; i = i + 1) begin
        accum_cnt_row[i] = 0;
        is_end_point[i] = 0;
        tmp_drc_result[i] = 0;
    end
    for(i = 1; i <= 7; i = i + 1) begin
        if(has_val_row[i] == is_width_check && (is_width_check == 1 || (has_val_row[i-1] == 1 || accum_cnt_row[i-1] > 0))) begin
            accum_cnt_row[i] = accum_cnt_row[i - 1] + 1;
            if(accum_cnt_row[i] == 7) accum_cnt_row[i] = 6;
            if(i < 7 && has_val_row[i+1] != is_width_check) begin
                if(accum_cnt_row[i] < requirement) begin
                    is_end_point[i] = 1;
                    if((prev_is_end_point[i] == 0) || (prev_accum_cnt_row[i] != accum_cnt_row[i])) begin
                        tmp_drc_result[i] = 1; 
                    end
                    else  begin
                        tmp_drc_result[i] = 0;
                    end
                end 
                else begin
                    is_end_point[i] = 0;
                    tmp_drc_result[i] = 0;
                end
            end
            else begin
                is_end_point[i] = 0;
                tmp_drc_result[i] = 0;
            end
        end
        else begin
            accum_cnt_row[i] = 0;
            is_end_point[i] = 0;
            tmp_drc_result[i] = 0;
        end
    end
end

always @(*) begin
    drc_result =  tmp_drc_result[0] + tmp_drc_result[1] + tmp_drc_result[2] + tmp_drc_result[3] 
                + tmp_drc_result[4] + tmp_drc_result[5] + tmp_drc_result[6] + tmp_drc_result[7] ;
end

assign accum_result = {accum_cnt_row[7], accum_cnt_row[6], accum_cnt_row[5], accum_cnt_row[4], accum_cnt_row[3],
                       accum_cnt_row[2], accum_cnt_row[1], accum_cnt_row[0]};
endmodule
