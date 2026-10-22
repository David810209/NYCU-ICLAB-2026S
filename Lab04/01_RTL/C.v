module CDNA(
    // Input Port
    clk,
    rst_n,
    instruction_in_valid,
    image_in_valid,
    weight_in_valid,
    in_data,
    
    // Output Port
    out_valid,
    out_data
);

input         clk;
input         rst_n;
input         instruction_in_valid;
input         image_in_valid;
input         weight_in_valid;
input  [31:0] in_data;

output reg        out_valid;
output reg [31:0] out_data;

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

//Example DW code
//DW_fp_add #(inst_sig_width, inst_exp_width ,inst_ieee_compliance, inst_arch_type, inst_arch, inst_faithful_round) u_add(.a(add_in_a), .b(add_in_b), .z(add_out), .status(add_status), .rnd(rnd));
//Example DW code
reg [31:0] weight_data [15:0] [8:0];
reg [3:0] read_weight_data_row_counter;
reg [7:0] read_weight_data_counter;
reg        weight_input_en [15:0];
reg [31:0] image_data [1:0] [63:0];
reg [6:0] image_read_cnt;
reg [31:0] image0_max, image1_max, image0_min, image1_min;
reg image_input_en;
reg [31:0] in_data_r;
reg pad_type_r ;
reg [1:0] act_type_r;
reg instr_in_valid_r;
reg weight_in_valid_r;
reg image_in_valid_r;

reg start_preprocess;
reg preprocess_issue_ch;
reg preprocess_shift_sel [1:0];
reg preprocess_store_ch;
reg [7:0] preprocess_counter;
// DW_fp_cmp for max
wire [31:0] cmp_for_max_a;
wire cmp_out_max;
// DW_fp_cmp for min
wire [31:0] cmp_for_min_a;
wire cmp_out_min;
// DW_fp_sub for P_cij - minC
wire [31:0] sub_p_minc_a;
wire [31:0] sub_p_minc_b;
wire [31:0] sub_p_minc;
reg [31:0] sub_p_minc_r;
// DW_fp_sub for maxC - minC 
wire [31:0] sub_maxc_minc_a;
wire [31:0] sub_maxc_minc_b;
wire [31:0] sub_maxc_minc;
reg [31:0] sub_maxc_minc_r;
wire [31:0] preprocess_result;
integer i, j, k;
reg [31:0] H0 [1:0];
reg [31:0] H1 [1:0];
reg [31:0] V0 [1:0];
reg [31:0] V1 [1:0];
reg [31:0] D00 [1:0];
reg [31:0] D01 [1:0];
reg [31:0] D10 [1:0];
reg [31:0] D11 [1:0];
reg [31:0] Center [1:0];
reg [31:0] mult_a_sel [1:0] [8:0];
wire X_is_zero, Y_is_zero, X_is_seven, Y_is_seven;
reg [31:0] mult_a [1:0] [8:0];
reg [31:0] mult_b [1:0] [8:0];
wire [31:0] mult_result0 [8:0];
wire [31:0] mult_result1 [8:0];
reg [31:0] mult_result0_r [8:0];
reg [31:0] mult_result1_r [8:0];

wire [31:0] three_add_0 [2:0];
wire [31:0] three_add_1 [2:0];
reg [31:0] three_add_0_r [2:0];
reg [31:0] three_add_1_r [2:0];

wire [31:0] three_add_result2_0;
wire [31:0] three_add_result2_1;
reg [31:0] three_add_result2_0_r;
reg [31:0] three_add_result2_1_r;
wire [31:0] three_add_result3;
reg [2:0] X_r, Y_r;

reg [3:0] weight_sel_ch0, weight_sel_ch1;
reg [6:0] conv_L1_cnt;
reg start_conv_L1;
genvar idx;
// pooling
reg [6:0] pooling_cnt;
reg start_pooling;
reg [31:0] conv_tmp_result[9:0];
wire dw_fp_cmp_for_pooling0;
wire dw_fp_cmp_for_pooling1;
wire dw_fp_cmp_for_pooling2;
reg [1:0] tmp_pooling_idx0;
reg [1:0] tmp_pooling_idx1;
reg [31:0] tmp_pooling_value0;
reg [31:0] tmp_pooling_value1;
wire pooling_cmp_en;
wire pooling_write_en;
reg [5:0] pooling_write_cnt;
// activation function
reg [31:0] pooling_result [1:0] [15:0];
reg [1:0] pooling_result_idx [1:0] [15:0];
reg act_valid_0;
reg [1:0] act_index_0;
reg [31:0] act_value_0;
reg [1:0] act_index_0_2;
reg [31:0] act_value_0_2;
reg act_valid_0_2;
wire [31:0] exp_a_sel_r;
wire [31:0] exp_result;
wire [31:0] mult_for_act;
wire [7:0] exponent_add_1;
reg act_valid_1;
reg [1:0] act_index_1;
reg [31:0] act_value_1;
reg [31:0] act_exp_result_1;
wire cmp_for_leaky_relu;

reg act_valid_2;
reg [1:0] act_index_2;
reg [31:0] act_value_2;
reg [31:0] act_value_2_for_div;
wire [31:0] add_for_act, sub_for_act;

wire [31:0] div_for_act;
wire [31:0] act_result_data_sel;
// conv ctrl
reg start_conv_L2;
reg [2:0] curr_conv_layer;
wire curr_L0_3_layer;
wire curr_L1_2_layer;
reg [31:0] pooling2_result [1:0] [3:0];
reg [1:0] pooling2_result_idx [1:0] [3:0];
// unpooling
reg start_unpooling;
reg [4:0] unpooling_cnt;
reg [31:0] pooling3_result [1:0] [15:0];
reg L3_write_en;
reg L4_write_en;
// test preprocess result
reg start_output;
reg [7:0] output_counter;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_data_r <= 0;
        instr_in_valid_r <= 0;
        weight_in_valid_r <= 0;
        image_in_valid_r <= 0;
    end
    else begin
        in_data_r <= in_data;
        instr_in_valid_r <= instruction_in_valid;
        weight_in_valid_r <= weight_in_valid;
        image_in_valid_r <= image_in_valid;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_type_r <= 0;
        pad_type_r <= 0;
    end
    else if(instr_in_valid_r) begin
        act_type_r <= in_data_r[1:0];
        pad_type_r <= in_data_r[2];
    end
    else begin
        act_type_r <= act_type_r;
        pad_type_r <= pad_type_r;
    end
end
always @(*) begin
    for(i = 0;i < 16;i = i + 1) begin
        weight_input_en[i] = read_weight_data_counter == i;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            weight_data[i] <= '{default: 0};
        end
    end
    else if(weight_in_valid_r) begin
        for(i = 0; i < 16; i = i + 1) begin
            if(weight_input_en[i]) begin
                weight_data[i][8] <= in_data_r;
                weight_data[i][7:0] <= weight_data[i][8:1];
            end
            else begin
                weight_data[i] <= weight_data[i];
            end
        end
    end
    else begin
        for(i = 0; i < 16; i = i + 1) begin
            weight_data[i] <= weight_data[i];
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_weight_data_counter <= 0;
        read_weight_data_row_counter <= 0;
    end
    else if(weight_in_valid_r) begin
        read_weight_data_row_counter <= read_weight_data_row_counter == 8 ? 0 : read_weight_data_row_counter + 1;
        read_weight_data_counter <= read_weight_data_row_counter == 8 ? 
                                read_weight_data_row_counter == 15 ? 0 : read_weight_data_counter + 1 : read_weight_data_counter;
    end
    else if(instr_in_valid_r) begin
        read_weight_data_counter <= 0;
        read_weight_data_row_counter <= 0;
    end
    else begin
        read_weight_data_counter <= read_weight_data_counter;
        read_weight_data_row_counter <= read_weight_data_row_counter;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_input_en <= 0;
    end else begin
        image_input_en <= image_read_cnt >= 63;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_read_cnt <= 0;
    end
    else if(image_in_valid_r) begin
        image_read_cnt <= image_read_cnt + 1;
    end
    else begin
        image_read_cnt <= image_read_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            image_data[i] <= '{default: 0};
        end
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            if((image_in_valid_r && image_input_en == i) || (start_preprocess && preprocess_shift_sel[i]) || start_conv_L1) begin
                image_data[i][63] <= image_in_valid_r && image_input_en == i ? in_data_r : 
                                        start_preprocess ? preprocess_result : image_data[i][0];
                image_data[i][62:0] <= image_data[i][63:1];
            end
            else if(act_valid_2 && curr_conv_layer == 2 && i == pooling_write_cnt[4])begin
                case (pooling_result_idx[i][0])
                    2'b00:begin
                        image_data[i][54] <= act_result_data_sel;
                        image_data[i][55] <= 0;
                        image_data[i][62] <= 0;
                        image_data[i][63] <= 0;
                    end
                    2'b01:begin
                        image_data[i][54] <= 0;
                        image_data[i][55] <= act_result_data_sel;
                        image_data[i][62] <= 0;
                        image_data[i][63] <= 0;
                    end
                    2'b10:begin
                        image_data[i][54] <= 0;
                        image_data[i][55] <= 0;
                        image_data[i][62] <= act_result_data_sel;
                        image_data[i][63] <= 0;
                    end
                    2'b11:begin
                        image_data[i][54] <= 0;
                        image_data[i][55] <= 0;
                        image_data[i][62] <= 0;
                        image_data[i][63] <= act_result_data_sel;
                    end
                    default:begin
                        image_data[i][54] <= 0;
                        image_data[i][55] <= 0;
                        image_data[i][62] <= 0;
                        image_data[i][63] <= 0;
                    end
                endcase
                for(k = 0;k <= 56;k = k + 8) begin
                    for(j = 0;j <= 4;j = j + 2)begin
                        image_data[i][k + j] <= image_data[i][k + j+2];
                        image_data[i][k + j+1] <= image_data[i][k + j+2+1];
                    end
                end
                image_data[i][7:6] <= image_data[i][17:16];
                image_data[i][15:14] <= image_data[i][25:24];

                image_data[i][23:22] <= image_data[i][33:32];
                image_data[i][31:30] <= image_data[i][41:40];

                image_data[i][39:38] <= image_data[i][49:48];
                image_data[i][47:46] <= image_data[i][57:56];
            end
            else begin
                image_data[i] <= image_data[i];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image0_max <= 32'hC2FE0000;  // -127 in IEEE 754
        image1_max <= 32'hC2FE0000;     // -127 in IEEE 754
        image0_min <= 32'h43000000; // 128 in IEEE 754
        image1_min <= 32'h43000000; // 128 in IEEE 754
    end
    else if(image_in_valid_r) begin
        if(image_input_en) begin
            image1_max <= cmp_out_max ? in_data_r : image1_max;
            image1_min <= cmp_out_min ? in_data_r : image1_min;
            image0_max <= image0_max;
            image0_min <= image0_min;
        end
        else begin
            image0_max <= cmp_out_max ? in_data_r : image0_max;
            image0_min <= cmp_out_min ? in_data_r : image0_min;
            image1_max <= image1_max;
            image1_min <= image1_min;
        end
    end
    else if(instr_in_valid_r) begin
        image0_max <= 32'hC2FE0000;  // -127 in IEEE 754
        image1_max <= 32'hC2FE0000;     // -127 in IEEE 754
        image0_min <= 32'h43000000; // 128 in IEEE 754
        image1_min <= 32'h43000000; // 128 in IEEE 754
    end
    else begin
        image0_max <= image0_max;
        image1_max <= image1_max;
        image0_min <= image0_min;
        image1_min <= image1_min;
    end
end
assign cmp_for_max_a = pooling_cmp_en? conv_tmp_result[0] :
image_input_en ? image1_max : image0_max;
wire [31:0] cmp_for_max_b = pooling_cmp_en ? conv_tmp_result[1] : in_data_r;
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
u_cmp_for_max(
    .a(cmp_for_max_a), 
    .b(cmp_for_max_b), 
    .altb(cmp_out_max));
assign cmp_for_min_a = pooling_write_en ? tmp_pooling_value1 : 
pooling_cmp_en ? conv_tmp_result[9] : 
image_input_en ? image1_min : image0_min;

wire [31:0] cmp_for_min_b = pooling_write_en ? tmp_pooling_value0 : 
pooling_cmp_en ? conv_tmp_result[8] : in_data_r;
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
u_cmp_for_min(
    .a(cmp_for_min_a), 
    .b(cmp_for_min_b), 
    .agtb(cmp_out_min));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_preprocess <= 0;
    end else if(image_read_cnt == 63)begin
        start_preprocess <= 1;
    end
    else if(preprocess_counter == 128) begin
        start_preprocess <= 0;
    end
    else begin
        start_preprocess <= start_preprocess;
    end
end
always @(*) begin
    preprocess_shift_sel[0] = preprocess_counter <= 64;
    preprocess_shift_sel[1] = preprocess_counter >= 64;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        preprocess_counter <= 0;
        preprocess_issue_ch <= 0;
    end else if(start_preprocess)begin
        preprocess_counter <= preprocess_counter + 1;
        if(preprocess_counter == 63) begin
            preprocess_issue_ch <= 1;
        end
        else begin
            preprocess_issue_ch <= preprocess_issue_ch;
        end
    end
    else  begin
        preprocess_counter <= 0;
        preprocess_issue_ch <= 0;
    end
end
assign sub_p_minc_a = act_valid_1 ? act_exp_result_1 :
preprocess_issue_ch ?  image_data[1][0] : image_data[0][0];
assign sub_p_minc_b = act_valid_1 ? 32'hBF800000 :
preprocess_issue_ch ? image1_min : image0_min;
DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
u_sub_for_p_minc(
    .a(sub_p_minc_a), 
    .b(sub_p_minc_b), 
    .z(sub_p_minc),
    .rnd(3'b0));
assign sub_maxc_minc_a =act_valid_1 ? act_exp_result_1 :
 preprocess_issue_ch ? image1_max : image0_max;
assign sub_maxc_minc_b = act_valid_1 ? 32'h3F800000 : sub_p_minc_b;
DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
u_sub_for_maxc_minc(
    .a(sub_maxc_minc_a), 
    .b(sub_maxc_minc_b), 
    .z(sub_maxc_minc),
    .rnd(3'b0));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sub_p_minc_r <= 0;
        sub_maxc_minc_r <= 0;
    end else begin
        sub_p_minc_r <= sub_p_minc;
        sub_maxc_minc_r <= sub_maxc_minc;
    end
end
DW_fp_div #(inst_sig_width, inst_exp_width ,inst_ieee_compliance,inst_faithful_round) 
u_div_for_preprocess(
    .a(sub_p_minc_r), 
    .b(sub_maxc_minc_r), 
    .z(preprocess_result),
    .rnd(3'b0));
// CONV L1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_conv_L1 <= 0;
    end 
    else if(preprocess_counter == 129)begin
        start_conv_L1 <= 1;
    end 
    else if(pooling_write_cnt == 32 && curr_conv_layer == 2) begin
        start_conv_L1 <= 1;
    end
    else if(conv_L1_cnt == 127) begin
        start_conv_L1 <= 0;
    end
    else  begin
        start_conv_L1 <= start_conv_L1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        curr_conv_layer <= 0;
    end 
    else if((curr_conv_layer == 0 || curr_conv_layer == 2) && pooling_write_cnt == 32) begin
        curr_conv_layer <= curr_conv_layer + 1;
    end
    else if(curr_conv_layer == 1 && pooling_write_cnt == 8) begin
        curr_conv_layer <= curr_conv_layer + 1;
    end
    else if(instr_in_valid_r) begin
        curr_conv_layer <= 0;
    end
    else  begin
        curr_conv_layer <= curr_conv_layer;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_conv_L2 <= 0;
    end 
    else if(curr_conv_layer == 0 && pooling_write_cnt == 32)begin
        start_conv_L2 <= 1;
    end 
    else if(curr_conv_layer == 2 && unpooling_cnt == 3)begin
        start_conv_L2 <= 1;
    end 
    else if(conv_L1_cnt == 31) begin
        start_conv_L2 <= 0;
    end
    else  begin
        start_conv_L2 <= start_conv_L2;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        conv_L1_cnt <= 0;
    end 
    else if(start_conv_L1 || start_conv_L2)begin
        conv_L1_cnt <= conv_L1_cnt + 1;
    end 
    else  begin
        conv_L1_cnt <= 0;
    end
end
assign curr_L0_3_layer = curr_conv_layer[0] == curr_conv_layer[1];
assign curr_L1_2_layer = ~curr_L0_3_layer;
always @(*) begin
    for(i = 0;i <= 1;i = i + 1) begin
        if(curr_L0_3_layer) begin
            H0[i] = image_data[i][63];
            Center[i] = image_data[i][0];
            H1[i] = image_data[i][1];
            V0[i] = image_data[i][56];
            V1[i] = image_data[i][8];
            D00[i] = image_data[i][55];
            D01[i] = image_data[i][9];
            D10[i] = image_data[i][57];
            D11[i] = image_data[i][7];
        end else begin
            H0[i] = pooling_result[i][15];
            Center[i] = pooling_result[i][0];
            H1[i] = pooling_result[i][1];
            V0[i] = pooling_result[i][12];
            V1[i] = pooling_result[i][4];
            D00[i] = pooling_result[i][11];
            D01[i] = pooling_result[i][5];
            D10[i] = pooling_result[i][13];
            D11[i] = pooling_result[i][3];
        end
    end
end
assign X_is_zero = X_r == 0;
assign Y_is_zero = Y_r == 0;
assign X_is_seven = curr_L0_3_layer ? X_r == 7 : X_r == 3;
assign Y_is_seven = curr_L0_3_layer ? Y_r == 7 : Y_r == 3;
always @(*) begin
    for(i = 0;i <= 1;i = i + 1) begin
        // Center
        mult_a_sel[i][4] = Center[i];
        // H0
        mult_a_sel[i][3] = X_is_zero ? pad_type_r == 0 ? 0 : Center[i] 
                                            : H0[i];
        // H1
        mult_a_sel[i][5] = X_is_seven ?pad_type_r == 0 ? 0 : Center[i] : H1[i];
        // V0
        mult_a_sel[i][1] = Y_is_zero ? pad_type_r == 0 ? 0 : Center[i] : V0[i];
        // V1
        mult_a_sel[i][7] = Y_is_seven ? pad_type_r == 0 ? 0 : Center[i] : V1[i];
        // D00
        mult_a_sel[i][0] = (X_is_zero || Y_is_zero ) && pad_type_r == 0 ? 0 :
                          X_is_zero && Y_is_zero ? Center[i] : 
                                X_is_zero ? V0[i] :
                                Y_is_zero ? H0[i] :
                                D00[i];
        // D01
        mult_a_sel[i][8] = 
                    (X_is_seven || Y_is_seven ) && pad_type_r == 0 ? 0 :
                    X_is_seven && Y_is_seven ? Center[i] : 
                    X_is_seven ? V1[i] :
                    Y_is_seven ? H1[i] :
                    D01[i];
        // D10
        mult_a_sel[i][2] = 
                        (X_is_seven || Y_is_zero ) && pad_type_r == 0 ? 0 :
                    X_is_seven && Y_is_zero ? Center[i] : 
                    X_is_seven ? V0[i] :
                    Y_is_zero ? H1[i] :
                    D10[i];
        // D11
        mult_a_sel[i][6] = 
                    (X_is_zero || Y_is_seven ) && pad_type_r == 0 ? 0 :
                    X_is_zero && Y_is_seven ? Center[i] : 
                    X_is_zero ? V1[i] :
                    Y_is_seven ? H0[i] :
                    D11[i];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        X_r <= 0;
        Y_r <= 0;
    end 
    else if(start_conv_L1)begin
        X_r <= X_r + 1;
        Y_r <= X_r == 7 ? Y_r + 1 : Y_r;
    end 
    else if(start_conv_L2)begin
        X_r <= X_r == 3 ? 0 : X_r + 1;
        Y_r <= X_r == 3 ? Y_r == 3 ? 0 : Y_r + 1 : Y_r;
    end 
    else  begin
        X_r <= 0;
        Y_r <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mult_a <= '{default: 0};
    end
     else begin
        for(i = 0;i <= 1;i = i + 1) begin
            for(j = 0;j <= 8;j = j + 1) begin
                mult_a[i][j] <= mult_a_sel[i][j];
            end
        end
     end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mult_b <= '{default: 0};
    end
     else begin
        for(j = 0;j <= 8;j = j + 1) begin
            mult_b[0][j] <= weight_data[weight_sel_ch0][j];
            mult_b[1][j] <= weight_data[weight_sel_ch1][j];
        end
     end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        weight_sel_ch0 <= 0;
        weight_sel_ch1 <= 1;
    end 
    else if(((conv_L1_cnt == 63 || conv_L1_cnt == 127) && curr_L0_3_layer) || ((conv_L1_cnt == 15 || conv_L1_cnt == 31) && curr_L1_2_layer))begin
        weight_sel_ch0 <= weight_sel_ch0 + 2;
        weight_sel_ch1 <= weight_sel_ch1 + 2;
    end 
    else if(instr_in_valid_r) begin
        weight_sel_ch0 <= 0;
        weight_sel_ch1 <= 1;
    end
    else  begin
        weight_sel_ch0 <= weight_sel_ch0;
        weight_sel_ch1 <= weight_sel_ch1;
    end
end
generate
    for(idx = 0;idx <= 8;idx++) begin
        DW_fp_mult #(23, 8 ,0)
        u_mult0(
            .a(mult_a[0][idx]), 
            .b(mult_b[0][idx]),  
            .z(mult_result0[idx]),
            .rnd(3'b0));
        DW_fp_mult #(23, 8 ,0)
        u_mult1(
            .a(mult_a[1][idx]), 
            .b(mult_b[1][idx]), 
            .z(mult_result1[idx]),
            .rnd(3'b0));
    end
endgenerate
// generate
//     for(idx = 0;idx <= 8;idx++) begin
//         DW_fp_mult #(23, 8 ,0)
//         u_mult0(
//             .a(mult_a[0][idx]), 
//             .b(mult_b[0][idx]),  
//             .z(mult_result0[idx]),
//             .rnd(3'b0));
//         DW_fp_mult #(23, 8 ,0)
//         u_mult1(
//             .a(mult_a[1][idx]), 
//             .b(mult_b[1][idx]), 
//             .z(mult_result1[idx]),
//             .rnd(3'b0));
//     end
// endgenerate
generate
    for(idx = 0;idx <= 2;idx = idx + 1) begin
        DW_fp_sum3 #(23, 8 ,0, 0)
            u_sum3_0(
                .a(mult_result0_r[idx]), 
                .b(mult_result0_r[idx+3]), 
                .c(mult_result0_r[idx+6]), 
                .z(three_add_0[idx]),
                .rnd(3'b0));
        DW_fp_sum3 #(23, 8 ,0, 0)
            u_sum3_1(
                .a(mult_result1_r[idx]), 
                .b(mult_result1_r[idx+3]), 
                .c(mult_result1_r[idx+6]), 
                .z(three_add_1[idx]),
                .rnd(3'b0));
    end
endgenerate
DW_fp_sum3 #(23, 8 ,0, 0)
u_sum3_2(
    .a(three_add_0_r[0]), 
    .b(three_add_0_r[1]), 
    .c(three_add_0_r[2]), 
    .z(three_add_result2_0),
    .rnd(3'b0));

DW_fp_sum3 #(23, 8 ,0, 0)
u_sum3_3(
    .a(three_add_1_r[0]), 
    .b(three_add_1_r[1]), 
    .c(three_add_1_r[2]), 
    .z(three_add_result2_1),
    .rnd(3'b0));

DW_fp_add #(23, 8 ,0)
u_add_for_three_add_result3(
    .a(three_add_result2_0_r), 
    .b(three_add_result2_1_r), 
    .z(three_add_result3),
    .rnd(3'b0));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mult_result0_r <= '{default: 0};
        mult_result1_r <= '{default: 0};
        three_add_0_r <= '{default: 0};
        three_add_1_r <= '{default: 0};
        three_add_result2_0_r <= 0;
        three_add_result2_1_r <= 0;
    end 
    else  begin
        for(j = 0;j <= 8;j = j + 1) begin
            mult_result0_r [j] <= mult_result0[j];
            mult_result1_r [j] <= mult_result1[j];
        end
        for(j = 0;j <= 2;j = j + 1) begin
            three_add_0_r[j] <= three_add_0[j];
            three_add_1_r[j] <= three_add_1[j];
        end
        three_add_result2_0_r <= three_add_result2_0;
        three_add_result2_1_r <= three_add_result2_1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_pooling <= 0;
    end 
    else if(conv_L1_cnt == 3 && curr_conv_layer < 2)begin
        start_pooling <= 1;
    end 
    else if(pooling_write_cnt == 31 && curr_conv_layer == 0) 
    begin
        start_pooling <= 0;
    end
    else if(pooling_write_cnt == 7 && curr_conv_layer == 1) 
    begin
        start_pooling <= 0;
    end
    else  begin
        start_pooling <= start_pooling;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pooling_cnt <= 0;
    end 
    else if(start_pooling)begin
        if(curr_conv_layer == 1)
        pooling_cnt <= pooling_cnt == 9 ? 2 : pooling_cnt + 1;
        else 
        pooling_cnt <= pooling_cnt == 17 ? 2 : pooling_cnt + 1;
    end 
    else  begin
        pooling_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        conv_tmp_result <= '{default: 0};
    end 
    else if(start_pooling) begin
        if(curr_conv_layer == 1) begin
            conv_tmp_result[9] <= three_add_result3;
            conv_tmp_result[8:6] <= conv_tmp_result[9:7];
            conv_tmp_result[0] <= conv_tmp_result[1];
            conv_tmp_result[1] <= conv_tmp_result[6];
            conv_tmp_result[5:2] <= conv_tmp_result[5:2];
        end
        else begin
            conv_tmp_result[9] <= three_add_result3;
            conv_tmp_result[8:0] <= conv_tmp_result[9:1];
        end
    end
end

// DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
// u_cmp_for_pooling0(
//     .a(conv_tmp_result[0]), 
//     .b(conv_tmp_result[1]), 
//     .altb(dw_fp_cmp_for_pooling0));

// wire [31:0] pooling1_a_sel = pooling_write_en ? tmp_pooling_value0 : conv_tmp_result[8];
// wire [31:0] pooling1_b_sel = pooling_write_en ? tmp_pooling_value1 : conv_tmp_result[9];
// DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance)
// u_cmp_for_pooling1(
//     .a(pooling1_a_sel), 
//     .b(pooling1_b_sel), 
//     .altb(dw_fp_cmp_for_pooling1));
assign pooling_cmp_en = curr_conv_layer == 0 ? pooling_cnt >= 10 && ~pooling_cnt[0]
                                                : pooling_cnt >= 6 && ~pooling_cnt[0];      
assign pooling_write_en = curr_conv_layer == 0 ? pooling_cnt >= 10 && pooling_cnt[0]
                                                : pooling_cnt >= 6 && pooling_cnt[0];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tmp_pooling_value0 <= 0;
        tmp_pooling_value1 <= 0;
        tmp_pooling_idx0 <= 0;
        tmp_pooling_idx1 <= 0;
    end
    else if(pooling_cmp_en) begin
        tmp_pooling_value0 <= cmp_out_max ? conv_tmp_result[1] : conv_tmp_result[0];
        tmp_pooling_value1 <= cmp_out_min ? conv_tmp_result[9] : conv_tmp_result[8];
        tmp_pooling_idx0 <= cmp_out_max ? 1 : 0;
        tmp_pooling_idx1 <= cmp_out_min ? 3: 2;
    end
    else begin
        tmp_pooling_value0 <= tmp_pooling_value0;
        tmp_pooling_value1 <= tmp_pooling_value1;
        tmp_pooling_idx0 <= tmp_pooling_idx0;
        tmp_pooling_idx1 <= tmp_pooling_idx1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        L3_write_en <= 0;
    end 
    else if(curr_conv_layer == 2 && conv_L1_cnt >= 3)begin
        L3_write_en <= 1;
    end 
    else if(pooling_write_cnt == 27) begin
        L3_write_en <= 0;
    end
    else  begin
        L3_write_en <= L3_write_en;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        L4_write_en <= 0;
    end 
    else if(curr_conv_layer == 3 && conv_L1_cnt >= 3)begin
        L4_write_en <= 1;
    end 
    else if(output_counter == 122) begin
        L4_write_en <= 0;
    end
    else  begin
        L4_write_en <= L4_write_en;
    end
end
// DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance) 
// u_cmp_for_pooling2(
//     .a(tmp_pooling_value0), 
//     .b(tmp_pooling_value1), 
//     .altb(dw_fp_cmp_for_pooling2));
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_index_0 <= 0;
        act_valid_0 <= 0;
        act_value_0 <= 0;
    end
    else if(pooling_write_en) begin
        if(cmp_out_min) begin
            act_index_0 <= tmp_pooling_idx1;
            act_value_0 <= tmp_pooling_value1;
        end
        else begin
            act_index_0 <= tmp_pooling_idx0;
            act_value_0 <= tmp_pooling_value0;
        end
        act_valid_0 <= 1;
    end
    else if(L3_write_en || L4_write_en) begin
        act_index_0 <= 0;
        act_value_0 <= three_add_result3;
        act_valid_0 <= 1;
    end
    else begin
        act_index_0 <= 0;
        act_value_0 <= 0;
        act_valid_0 <= 0;
    end
end
DW_fp_mult #(23,8,0)
u_mult_for_activation(
    .a(act_value_0), 
    .b(32'h3E000000), 
    .z(mult_for_act),
    .rnd(3'b0));
DW_fp_cmp #(inst_sig_width, inst_exp_width ,inst_ieee_compliance)
u_cmp_for_leaky_relu(
    .a(act_value_0), 
    .b(32'h82000000),
    .agtb(cmp_for_leaky_relu));
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_value_0_2 <= 0;
        act_index_0_2 <= 0;
        act_valid_0_2 <= 0;
    end
    else if(act_valid_0) begin
        if(act_type_r == 0) begin
            act_value_0_2 <= {~act_value_0[31], act_value_0[30:0]};
        end
        else if(act_type_r == 1) begin
            act_value_0_2 <= {act_value_0[31], exponent_add_1, act_value_0[22:0]};
        end
        else if(act_type_r == 2) begin
            act_value_0_2 <= act_value_0[31] ? 0 : act_value_0;
        end
        // leaky relu
        else begin
            act_value_0_2 <= act_value_0[31] == 0 ? act_value_0 : cmp_for_leaky_relu ?  32'h0 : mult_for_act; 
        end
        act_index_0_2 <= act_index_0;
        act_valid_0_2 <= 1;
    end
    else begin
        act_value_0_2 <= 0;
        act_index_0_2 <= 0;
        act_valid_0_2 <= 0;
    end
end
assign exponent_add_1 = act_value_0[30:23] + 1;
DW_fp_exp #(23,8,0,1)
u_exp_for_activation(
    .a(act_value_0_2), 
    .z(exp_result));
// 3E000000: 0.125 
// 0x82000000: -2^(-123)
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_index_1 <= 0;
        act_value_1 <= 0;
        act_valid_1 <= 0;
        act_exp_result_1 <= 0;
    end
    else if(act_valid_0_2) begin
        act_exp_result_1 <= exp_result;
        act_value_1 <= act_value_0_2;
        act_index_1 <= act_index_0_2;
        act_valid_1 <= 1;
    end
    else begin
        act_exp_result_1 <= 0;
        act_index_1 <= 0;
        act_value_1 <= 0;
        act_valid_1 <= 0;
    end
end

// DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance)
// u_sub_for_act0(
//     .a(act_exp_result_1), 
//     .b(32'hBF800000), 
//     .z(add_for_act),
//     .rnd(3'b0));
// DW_fp_sub #(inst_sig_width, inst_exp_width ,inst_ieee_compliance)
// u_sub_for_act(
//     .a(act_exp_result_1), 
//     .b(32'h3F800000), 
//     .z(sub_for_act),
//     .rnd(3'b0));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_index_2 <= 0;
        act_value_2 <= 0;
        act_valid_2 <= 0;
        act_value_2_for_div <= 0;
    end
    else if(act_valid_1) begin
        if(act_type_r == 0) begin
            act_value_2 <= sub_p_minc;
            act_value_2_for_div <= 32'h3F800000;
        end
        else if(act_type_r == 1) begin
            act_value_2 <= sub_p_minc;
            act_value_2_for_div <= sub_maxc_minc;
        end
        // leaky relu
        else begin
            act_value_2 <= act_value_1;
            act_value_2_for_div <= act_value_1;
        end
        act_index_2 <= act_index_1;
        act_valid_2 <= 1;
    end
    else begin
        act_index_2 <= 0;
        act_value_2 <= 0;
        act_valid_2 <= 0;
        act_value_2_for_div <= 0;
    end
end

DW_fp_div #(inst_sig_width, inst_exp_width ,inst_ieee_compliance,inst_faithful_round)
u_div_for_act(
    .a(act_value_2_for_div), 
    .b(act_value_2), 
    .z(div_for_act),
    .rnd(3'b0));
assign act_result_data_sel = act_type_r < 2 ? div_for_act : act_value_2;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            pooling_result[i] <= '{default: 0};
        end
    end
    else if(act_valid_2 && curr_conv_layer == 0) begin
        for(i = 0; i < 2; i = i + 1) begin
            if(i == pooling_write_cnt[4]) begin
                pooling_result[i][15] <= act_result_data_sel;
                pooling_result[i][14:0]<= pooling_result[i][15:1];
            end
            else begin
                pooling_result[i] <= pooling_result[i];
            end
        end
    end
    else if(start_conv_L2) begin
        for(i = 0; i < 2; i = i + 1) begin
                pooling_result[i][14:0] <= pooling_result[i][15:1];
                pooling_result[i][15] <= pooling_result[i][0];
        end
    end
    else if(start_unpooling) begin
        for(i = 0; i < 2; i = i + 1) begin
            case (pooling2_result_idx[i][0])
                2'b00:begin
                    pooling_result[i][10] <= pooling2_result[i][0];
                    pooling_result[i][11] <= 0;
                    pooling_result[i][14] <= 0;
                    pooling_result[i][15] <= 0;
                end
                2'b01:begin
                        pooling_result[i][10] <= 0;
                        pooling_result[i][11] <= pooling2_result[i][0];
                        pooling_result[i][14] <= 0;
                        pooling_result[i][15] <= 0;
                    end
                2'b10:begin
                        pooling_result[i][10] <= 0;
                        pooling_result[i][11] <= 0;
                        pooling_result[i][14] <= pooling2_result[i][0];
                        pooling_result[i][15] <= 0;
                    end
                2'b11:begin
                        pooling_result[i][10] <= 0;
                        pooling_result[i][11] <= 0;
                        pooling_result[i][14] <= 0;
                        pooling_result[i][15] <= pooling2_result[i][0];
                    end
                default:begin
                        pooling_result[i][10] <= 0;
                        pooling_result[i][11] <= 0;
                        pooling_result[i][14] <= 0;
                        pooling_result[i][15] <= 0;
                    end
            endcase
            pooling_result[i][9:8] <= pooling_result[i][11:10];
            pooling_result[i][13:12] <= pooling_result[i][15:14];

            pooling_result[i][3:2] <= pooling_result[i][9:8];
            pooling_result[i][7:6] <= pooling_result[i][13:12];

            pooling_result[i][1:0] <= pooling_result[i][3:2];
            pooling_result[i][5:4] <= pooling_result[i][7:6];
        end
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            pooling_result[i] <= pooling_result[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            pooling_result_idx[i] <= '{default: 0};
        end
    end
    else if(act_valid_2 && curr_conv_layer == 0) begin
        for(i = 0; i < 2; i = i + 1) begin
            if(i == pooling_write_cnt[4]) begin
                pooling_result_idx[i][15] <= act_index_2;
                pooling_result_idx[i][14:0] <= pooling_result_idx[i][15:1];
            end
            else begin
                pooling_result_idx[i] <= pooling_result_idx[i];
            end
        end
    end
    else if(act_valid_2 && curr_conv_layer == 2)begin
        for(i = 0; i < 2; i = i + 1) begin
            pooling_result_idx[i][15] <= pooling_result_idx[i][0];
            pooling_result_idx[i][14:0] <= pooling_result_idx[i][15:1];
        end
    end
    else begin 
        for(i = 0; i < 2; i = i + 1) begin
            pooling_result_idx[i] <= pooling_result_idx[i];
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 2; i = i + 1) begin
            pooling2_result[i] <= '{default: 0};
            pooling2_result_idx[i] <= '{default: 0};
        end
    end
    else if(act_valid_2 && curr_conv_layer == 1) begin
        for(i = 0; i < 2; i = i + 1) begin
            if(i == pooling_write_cnt[2]) begin
                pooling2_result[i][3] <= act_result_data_sel;
                pooling2_result[i][2:0] <= pooling2_result[i][3:1];
                pooling2_result_idx[i][3] <= act_index_2;
                pooling2_result_idx[i][2:0] <= pooling2_result_idx[i][3:1];
            end
            else begin
                pooling2_result_idx[i] <= pooling2_result_idx[i];
                pooling2_result[i] <= pooling2_result[i];
            end
        end
    end
    else if(start_unpooling) begin
        for(i = 0; i < 2; i = i + 1) begin
                pooling2_result[i][2:0] <= pooling2_result[i][3:1];
                pooling2_result[i][3] <= pooling2_result[i][0];
                pooling2_result_idx[i][2:0] <= pooling2_result_idx[i][3:1];
                pooling2_result_idx[i][3] <= pooling2_result_idx[i][0];
            end 
    end
    else begin
        for(i = 0; i < 2; i = i + 1) begin
            pooling2_result_idx[i] <= pooling2_result_idx[i];
            pooling2_result[i] <= pooling2_result[i];
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pooling_write_cnt <= 0;
    end 
    else if(((curr_conv_layer == 0 || curr_conv_layer == 2) && pooling_write_cnt == 32) || (curr_conv_layer == 1 && pooling_write_cnt == 8)) begin
        pooling_write_cnt <= 0;
    end
    else if(act_valid_2)begin
        pooling_write_cnt <=  pooling_write_cnt + 1;
    end 
    else  begin
        pooling_write_cnt <= pooling_write_cnt;
    end
end
// unpooling
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_unpooling <= 0;
    end 
    else if(curr_conv_layer == 1 && pooling_write_cnt == 8) begin
        start_unpooling <= 1;
    end
    else if(unpooling_cnt == 3)begin
        start_unpooling <=  0;
    end 
    else  begin
        start_unpooling <= start_unpooling;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        unpooling_cnt <= 0;
    end 
    else if(start_unpooling)begin
        unpooling_cnt <= unpooling_cnt + 1;
    end 
    else  begin
        unpooling_cnt <= 0;
    end
end
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         for(i = 0; i < 2; i = i + 1) begin
//             pooling3_result[i] <= '{default: 0};
//         end
//     end
//     else if(act_valid_2 && curr_conv_layer == 2) begin
//         for(i = 0; i < 2; i = i + 1) begin
//             if(i == pooling_write_cnt[4]) begin
//                 pooling3_result[i][15] <= act_result_data_sel;
//                 pooling3_result[i][14:0]<= pooling3_result[i][15:1];
//             end
//             else begin
//                 pooling3_result[i] <= pooling3_result[i];
//             end
//         end
//     end
//     else if(start_output) begin
//         for(i = 0; i < 2; i = i + 1) begin
//                 pooling3_result[i][14:0] <= pooling3_result[i][15:1];
//                 pooling3_result[i][15] <= pooling3_result[i][0];
//         end
//     end
//     else begin
//         for(i = 0; i < 2; i = i + 1) begin
//             pooling3_result[i] <= pooling3_result[i];
//         end
//     end
// end
// test preprocess result
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start_output <= 0;
    end 
    else if(act_valid_2 && curr_conv_layer == 3)begin
        start_output <= 1;
    end 
    else if(output_counter == 127) begin
        start_output <= 0;
    end
    else  begin
        start_output <= start_output;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_counter <= 0;
    end 
    else if(start_output)begin
        output_counter <= output_counter + 1;
    end 
    else  begin
        output_counter <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end 
     else if(act_valid_2 && curr_conv_layer == 3)begin
        out_valid <= 1;
        out_data <= act_result_data_sel;
     end
    else begin
        out_valid <= 0;
        out_data <= 0;
    end
end
endmodule
