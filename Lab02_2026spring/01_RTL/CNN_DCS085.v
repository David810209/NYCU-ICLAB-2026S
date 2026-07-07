module CNN(
    input                       clk,
    input                       rst_n,
    input                       in_valid,
    input                       mode,
    input       signed  [7:0]   in_data_ch1,
    input       signed  [7:0]   in_data_ch2,
    input       signed  [7:0]   kernel_ch1,
    input       signed  [7:0]   kernel_ch2,
    input       signed  [7:0]   weight,
    output reg                  out_valid,
    output reg  signed  [19:0]  out_data
);

//==================================================================
// parameter & integer
//==================================================================

parameter M2AC_pipeline = 7;
parameter OUTPUT_CYCLE  = 85 + 2 * M2AC_pipeline;
parameter OUTPUT_MODE   = 80 + M2AC_pipeline;
parameter DATA_RESET    = M2AC_pipeline;

//==================================================================
// Regs
//==================================================================

// counter & buffer_valid & buffer_input
reg [7:0] counter, counter_d;

reg buffer_mode_valid;
reg buffer_weight_valid;
reg buffer_kernel_valid;

reg buffer_mode;
reg signed [7:0] buffer_weight;
reg signed [7:0] buffer_kernel_ch1;
reg signed [7:0] buffer_kernel_ch2;

// mode
reg op_mode;

// ch1 & ch2 in_data
reg signed [7:0] ch1_in_datas   [19:0];
reg signed [7:0] ch2_in_datas   [19:0];
reg signed [7:0] ch1_in_datas_d [19:0];
reg signed [7:0] ch2_in_datas_d [19:0];

// kernal datas & rotation
reg signed [7:0] ch1_kernel_datas   [8:0];
reg signed [7:0] ch2_kernel_datas   [8:0];
reg signed [7:0] ch1_kernel_datas_d [8:0];
reg signed [7:0] ch2_kernel_datas_d [8:0];

// weight datas & rotation
reg [7:0] weight_datas   [3:0] [7:0];
reg [7:0] weight_datas_d [3:0] [7:0];
reg weight_rotate;

wire weight_rotate_d;

// M2ACs
reg m_reset_d;
reg signed [7:0] m_a1_d [3:0];
reg signed [7:0] m_a2_d [3:0];
reg signed [7:0] m_b1_d; // shared multiplier
reg signed [7:0] m_b2_d; // shared multiplier

wire signed [19:0] m_cout [3:0];
wire m_cout_valid;

// M2ACs state + control
reg [3:0] m_state, m_state_d;

// ReLU/Abs + Quantization
reg [7:0] cout_op_quants   [3:0];
reg [7:0] cout_op_quants_d [3:0];

reg c_data_valid_p1;

// Compare 1
reg [7:0] larger_pair1;
reg [7:0] larger_pair2;

wire [7:0] larger_pair1_d;
wire [7:0] larger_pair2_d;

reg c_data_valid_p2;

// Compare 2 & features
reg [7:0] max_quad1, max_quad1_d;
reg [7:0] max_quad2, max_quad2_d;
reg feature_push;
reg feature_push_d;
reg [7:0] features   [7:0];
reg [7:0] features_d [7:0];
reg [4:0] data_complete, data_complete_d; 

// output control
reg out_valid_d;
reg signed [19:0] out_data_d;
reg [2:0] out_state, out_state_d;
reg total_reset;

//==================================================================
// Wires
//==================================================================

//==================================================================
// Design
//==================================================================


//
// counter & buffer valid & buffer input
//

always @(*) begin

    counter_d = counter + 1;

    if ((counter == 0) && !in_valid) counter_d = 0;
    if (out_valid) counter_d = 0;
end

wire buffer_mode_valid_d   = in_valid && (counter < 1);
wire buffer_weight_valid_d = in_valid && (counter < 32);
wire buffer_kernel_valid_d = in_valid && (counter < 9);

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        counter       <= 0;

        buffer_mode_valid   <= 0;
        buffer_weight_valid <= 0;
        buffer_kernel_valid <= 0;
        
        buffer_mode         <= 0;
        buffer_weight       <= 0;
        buffer_kernel_ch1   <= 0;
        buffer_kernel_ch2   <= 0;
    end
    else begin
        counter       <= counter_d;

        buffer_mode_valid   <= buffer_mode_valid_d;
        buffer_weight_valid <= buffer_weight_valid_d;
        buffer_kernel_valid <= buffer_kernel_valid_d;
        
        buffer_mode         <= mode;
        buffer_weight       <= weight;
        buffer_kernel_ch1   <= kernel_ch1;
        buffer_kernel_ch2   <= kernel_ch2;
    end
end

// Count to three counter
reg [1:0] counter_three, counter_three_d;

always @(*) begin
    case (counter_three)
        2'd0: counter_three_d = 0;
        2'd1: counter_three_d = 2;
        2'd2: counter_three_d = 3;
        2'd3: counter_three_d = 1;
    endcase
    if (counter_three == 0 && in_valid) counter_three_d = 1;
    if (total_reset) counter_three_d = 0;
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        counter_three <= 0;
    end
    else begin
        counter_three <= counter_three_d;
    end
end


// Counter control signals

wire output_begin = (counter == OUTPUT_CYCLE);
assign total_reset = (counter == 10) || ((out_valid == 1) && (out_valid_d == 0));

assign m_reset_d = (total_reset || (counter == 10) ||
                    (counter == 19) || (counter == 28) || (counter == 37) || (counter == 46) ||
                    (counter == 55) || (counter == 64) || (counter == 73) || (counter == 82));


reg m_active;
reg m_trigger;
reg m_output;

wire m_active_d = (counter == 11 || counter == 47);
wire m_trigger_d = (counter_three == 3);
wire m_output_d = (counter == OUTPUT_MODE);

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        m_active  <= 0;
        m_trigger <= 0;
        m_output  <= 0;
    end
    else begin
        m_active  <= m_active_d;
        m_trigger <= m_trigger_d;
        m_output  <= m_output_d;
    end
end

//
// mode
//

wire op_mode_d = buffer_mode_valid? buffer_mode : op_mode;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        op_mode <= 0;
    end
    else begin
        op_mode <= op_mode_d;
    end
end

//
// ch1 & ch2 in_data
//

always @(*) begin
    ch1_in_datas_d[19:1] = ch1_in_datas[18:0];
    ch2_in_datas_d[19:1] = ch2_in_datas[18:0];

    ch1_in_datas_d[0] = in_valid? in_data_ch1 : 0;
    ch2_in_datas_d[0] = in_valid? in_data_ch2 : 0;
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        ch1_in_datas[19:0] <= {default: 0};
        ch2_in_datas[19:0] <= {default: 0};
    end
    else begin
        ch1_in_datas[19:0] <= ch1_in_datas_d[19:0];
        ch2_in_datas[19:0] <= ch2_in_datas_d[19:0];
    end
end

//
// kernal datas & rotation
//

always @(*) begin
    /*
    if (buffer_kernel_valid) begin 
        // push in
        ch1_kernel_datas_d[8:1] = ch1_kernel_datas[7:0];
        ch2_kernel_datas_d[8:1] = ch2_kernel_datas[7:0];
        ch1_kernel_datas_d[0] = buffer_kernel_ch1;
        ch2_kernel_datas_d[0] = buffer_kernel_ch2;
    end
    else begin
        // rotate (by transpose order)
        // 8 7 6    5 4 3
        // 5 4 3 -> 2 1 0
        // 2 1 0    7 6 8

        ch1_kernel_datas_d[8:0] = {ch1_kernel_datas[5], ch1_kernel_datas[4], ch1_kernel_datas[3],
                                   ch1_kernel_datas[2], ch1_kernel_datas[1], ch1_kernel_datas[0],
                                   ch1_kernel_datas[7], ch1_kernel_datas[6], ch1_kernel_datas[8]};
                                   
        ch2_kernel_datas_d[8:0] = {ch2_kernel_datas[5], ch2_kernel_datas[4], ch2_kernel_datas[3],
                                   ch2_kernel_datas[2], ch2_kernel_datas[1], ch2_kernel_datas[0],
                                   ch2_kernel_datas[7], ch2_kernel_datas[6], ch2_kernel_datas[8]};
    end
    */

    ch1_kernel_datas_d[8:1] = ch1_kernel_datas[7:0];
    ch2_kernel_datas_d[8:1] = ch2_kernel_datas[7:0];
    
    if (buffer_kernel_valid) begin 
        // push in
        ch1_kernel_datas_d[0] = buffer_kernel_ch1;
        ch2_kernel_datas_d[0] = buffer_kernel_ch2;
    end
    else begin
        // rotate
        ch1_kernel_datas_d[0] = ch1_kernel_datas[8];
        ch2_kernel_datas_d[0] = ch2_kernel_datas[8];
    end

end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        ch1_kernel_datas[8:0] <= {default: 0};
        ch2_kernel_datas[8:0] <= {default: 0};
    end
    else begin
        ch1_kernel_datas[8:0] <= ch1_kernel_datas_d[8:0];
        ch2_kernel_datas[8:0] <= ch2_kernel_datas_d[8:0];
    end
end

//
// weight
//

assign weight_rotate_d = (m_state_d == 12) || (m_state_d == 13) || (m_state_d == 14) || (m_state_d == 15);

always @(*) begin
    
    weight_datas_d[3][7:0] = weight_datas[3][7:0];
    weight_datas_d[2][7:0] = weight_datas[2][7:0];
    weight_datas_d[1][7:0] = weight_datas[1][7:0];
    weight_datas_d[0][7:0] = weight_datas[0][7:0];

    if (buffer_weight_valid) begin
        weight_datas_d[3][7:1] = weight_datas[3][6:0];
        weight_datas_d[2][7:1] = weight_datas[2][6:0];
        weight_datas_d[1][7:1] = weight_datas[1][6:0];
        weight_datas_d[0][7:1] = weight_datas[0][6:0];

        weight_datas_d[3][0] = weight_datas[2][7];
        weight_datas_d[2][0] = weight_datas[1][7];
        weight_datas_d[1][0] = weight_datas[0][7];
        weight_datas_d[0][0] = buffer_weight;
    end

    if (weight_rotate) begin
        weight_datas_d[3][7:2] = weight_datas[3][5:0];
        weight_datas_d[2][7:2] = weight_datas[2][5:0];
        weight_datas_d[1][7:2] = weight_datas[1][5:0];
        weight_datas_d[0][7:2] = weight_datas[0][5:0];

        weight_datas_d[3][1:0] = weight_datas[3][7:6];
        weight_datas_d[2][1:0] = weight_datas[2][7:6];
        weight_datas_d[1][1:0] = weight_datas[1][7:6];
        weight_datas_d[0][1:0] = weight_datas[0][7:6];
    end

end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        weight_datas        <= {default: 0};
        weight_rotate       <= 0;
    end
    else begin
        weight_datas        <= weight_datas_d;
        weight_rotate       <= weight_rotate_d;
    end
end

//
// M2ACs
//

wire [3:0] m_cout_pre_reset;
assign m_cout_valid = m_cout_pre_reset[0]; // m_cout_pre_reset[0~3] should be the same

M2AC m2acs [3:0] (
    // Input
    .clk(clk),
    .rst_n(rst_n),
    .reset_d(m_reset_d),
    .a1_d(m_a1_d),
    .b1_d(m_b1_d),
    .a2_d(m_a2_d),
    .b2_d(m_b2_d),
    // Output
    .cout_pre_reset(m_cout_pre_reset),
    .cout(m_cout)
);


//
// M2ACs
//

always @(*) begin

    m_state_d = m_state;
    case (m_state)
        0: begin 
            if (m_active) m_state_d = 1;
            if (m_output) m_state_d = 12;
        end
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10:
            if (m_trigger) m_state_d = m_state + 1;
        11:
            if (m_trigger) m_state_d = 0;
        12, 13, 14, 15:
            m_state_d = m_state + 1;
    endcase

    if (total_reset) m_state_d = 0;

end

always @(*) begin
    m_a1_d[3:0] = {default: 0};
    case (m_state)
        // From data
                  9:    m_a1_d[3:0] = {ch1_in_datas[18],   ch1_in_datas[17],   ch1_in_datas[16],   ch1_in_datas[15]};
              6, 10:    m_a1_d[3:0] = {ch1_in_datas[15],   ch1_in_datas[14],   ch1_in_datas[13],   ch1_in_datas[12]};
           3, 7, 11:    m_a1_d[3:0] = {ch1_in_datas[12],   ch1_in_datas[11],   ch1_in_datas[10],   ch1_in_datas[9]};
        0, 4, 8:        m_a1_d[3:0] = {ch1_in_datas[9],    ch1_in_datas[8],    ch1_in_datas[7],    ch1_in_datas[6]};
        1, 5:           m_a1_d[3:0] = {ch1_in_datas[6],    ch1_in_datas[5],    ch1_in_datas[4],    ch1_in_datas[3]};
        2:              m_a1_d[3:0] = {ch1_in_datas[3],    ch1_in_datas[2],    ch1_in_datas[1],    ch1_in_datas[0]};
        // From weight
        12, 13, 14, 15: m_a1_d[3:0] = {weight_datas[3][7], weight_datas[2][7], weight_datas[1][7], weight_datas[0][7]};
    endcase
end

always @(*) begin
    case (m_state)
        // From data
                  9:    m_a2_d[3:0] = {ch2_in_datas[18],   ch2_in_datas[17],   ch2_in_datas[16],   ch2_in_datas[15]};
              6, 10:    m_a2_d[3:0] = {ch2_in_datas[15],   ch2_in_datas[14],   ch2_in_datas[13],   ch2_in_datas[12]};
           3, 7, 11:    m_a2_d[3:0] = {ch2_in_datas[12],   ch2_in_datas[11],   ch2_in_datas[10],   ch2_in_datas[9]};
        0, 4, 8:        m_a2_d[3:0] = {ch2_in_datas[9],    ch2_in_datas[8],    ch2_in_datas[7],    ch2_in_datas[6]};
        1, 5:           m_a2_d[3:0] = {ch2_in_datas[6],    ch2_in_datas[5],    ch2_in_datas[4],    ch2_in_datas[3]};
        2:              m_a2_d[3:0] = {ch2_in_datas[3],    ch2_in_datas[2],    ch2_in_datas[1],    ch2_in_datas[0]};
        // From weight
        12, 13, 14, 15: m_a2_d[3:0] = {weight_datas[3][6], weight_datas[2][6], weight_datas[1][6], weight_datas[0][6]};
    endcase
end

always @(*) begin
    case (m_state)
        // From kernel
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11: m_b1_d = ch1_kernel_datas[8];
        // From feature
        12:                                   m_b1_d = features[6];
        13:                                   m_b1_d = features[4];
        14:                                   m_b1_d = features[2];
        15:                                   m_b1_d = features[0];
    endcase
end

always @(*) begin
    case (m_state)
        // From kernel
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11: m_b2_d = ch2_kernel_datas[8];
        // From feature
        12:                                   m_b2_d = features[7];
        13:                                   m_b2_d = features[5];
        14:                                   m_b2_d = features[3];
        15:                                   m_b2_d = features[1];
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        m_state <= 0;
    end
    else begin
        m_state <= m_state_d;
    end
end

//
// ReLU/Abs + Quantization
//

always @(*) begin
    cout_op_quants_d[3:0] = {default: 0};
    if (m_cout_valid) begin
        if (!op_mode) begin // ReLU
            cout_op_quants_d[3] = (m_cout[3] >= 0)? (m_cout[3] >> 9) : 0;
            cout_op_quants_d[2] = (m_cout[2] >= 0)? (m_cout[2] >> 9) : 0;
            cout_op_quants_d[1] = (m_cout[1] >= 0)? (m_cout[1] >> 9) : 0;
            cout_op_quants_d[0] = (m_cout[0] >= 0)? (m_cout[0] >> 9) : 0;
        end
        else begin // Abs
            cout_op_quants_d[3] = (m_cout[3] >= 0)? (m_cout[3] >> 9) : ((-m_cout[3]) >> 9);
            cout_op_quants_d[2] = (m_cout[2] >= 0)? (m_cout[2] >> 9) : ((-m_cout[2]) >> 9);
            cout_op_quants_d[1] = (m_cout[1] >= 0)? (m_cout[1] >> 9) : ((-m_cout[1]) >> 9);
            cout_op_quants_d[0] = (m_cout[0] >= 0)? (m_cout[0] >> 9) : ((-m_cout[0]) >> 9);
        end

        if (cout_op_quants_d[3] >= 128) cout_op_quants_d[3] = 127;
        if (cout_op_quants_d[2] >= 128) cout_op_quants_d[2] = 127;
        if (cout_op_quants_d[1] >= 128) cout_op_quants_d[1] = 127;
        if (cout_op_quants_d[0] >= 128) cout_op_quants_d[0] = 127;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cout_op_quants[3:0] <= {default: 0};
        c_data_valid_p1     <= 0;
    end
    else begin
        cout_op_quants[3:0] <= cout_op_quants_d[3:0];
        c_data_valid_p1     <= m_cout_valid;
    end
end

//
// Compare 1
//

assign larger_pair1_d = (cout_op_quants[0] > cout_op_quants[1])? cout_op_quants[0] : cout_op_quants[1];
assign larger_pair2_d = (cout_op_quants[2] > cout_op_quants[3])? cout_op_quants[2] : cout_op_quants[3];

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        larger_pair1    <= 0;
        larger_pair2    <= 0;
        c_data_valid_p2 <= 0;
    end
    else begin
        larger_pair1    <= larger_pair1_d;
        larger_pair2    <= larger_pair2_d;
        c_data_valid_p2 <= c_data_valid_p1;
    end
end

//
// Compare 2
//

always @(*) begin

    data_complete_d = data_complete;
    if (c_data_valid_p1) data_complete_d = data_complete + 1;
    if (counter == DATA_RESET) data_complete_d = 0;

    feature_push_d = 0;
    if ((data_complete == 1 || data_complete == 3 || data_complete == 5 || data_complete == 7) && (c_data_valid_p2))
        feature_push_d = 1;

    max_quad1_d = (larger_pair1 > max_quad1)? larger_pair1 : max_quad1;
    max_quad2_d = (larger_pair2 > max_quad2)? larger_pair2 : max_quad2;

    // feature[7:2] are FFs, feature[1:0] are signals
    features_d[7:0] = features[7:0];
    if (feature_push) begin
        features_d[7:4] = features[5:2];
        features_d[3:2] = {max_quad1, max_quad2};
        max_quad1_d = 0;
        max_quad2_d = 0;
    end
    features[1:0] = {max_quad1, max_quad2};

end 

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        max_quad1     <= 0;
        max_quad2     <= 0;
        data_complete <= 0;
        feature_push  <= 0;
        features[7:2] <= {default: 0};
    end
    else begin
        max_quad1     <= max_quad1_d;
        max_quad2     <= max_quad2_d;
        data_complete <= data_complete_d;
        feature_push  <= feature_push_d;
        features[7:2] <= features_d[7:2];
    end
end

//
// output control
//

always @(*) begin

    out_state_d = 0;
    case (out_state)
        0: if (output_begin) out_state_d = 1;
        1: out_state_d = 2;
        2: out_state_d = 3;
        3: out_state_d = 4;
        4: out_state_d = 0;
    endcase
    
    out_valid_d = 0;
    if (out_state != 0) out_valid_d = 1;

    out_data_d = 0;
    case (out_state)
        1: out_data_d = m_cout[3];
        2: out_data_d = m_cout[2];
        3: out_data_d = m_cout[1];
        4: out_data_d = m_cout[0];
    endcase
    
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
        out_data  <= 0;
        out_state <= 0;
    end
    else begin
        out_valid <= out_valid_d;
        out_data  <= out_data_d;
        out_state <= out_state_d;
    end
end


endmodule


//==================================================================
//========================== Description ===========================
//
//  Name = M2AC_pipe7
//
//  Config:
//      Multiplier bits   = 8
//      Cumulator bits    = 20
//      Stage cut portion = [0.12, 0.22, 0.27, 0.33, 0.4, 0.44, 1.0]
//
//  Delay model:
//      booth = 4.0
//      fa_c  = 3.0
//      fa_s  = 4.5
//      ha_c  = 1.0
//      ha_s  = 2.5
//      and   = 1.0
//
//  Author: Wesley Wang (111511100)
//
//==================================================================

module M2AC (
    // Input
    input              clk,
    input              rst_n,
    input              reset_d,
    input signed [7:0] a1_d,
    input signed [7:0] b1_d,
    input signed [7:0] a2_d,
    input signed [7:0] b2_d,
    // Output
    output               cout_pre_reset,
    output signed [19:0] cout
);

//==================================================================
// Input
//==================================================================
reg signed [7:0] a1, b1, a2, b2;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        a1 <= 0;
        a2 <= 0;
        b1 <= 0;
        b2 <= 0;
    end
    else begin
        a1 <= a1_d;
        a2 <= a2_d;
        b1 <= b1_d;
        b2 <= b2_d;
    end
end

//==================================================================
// Signals (Generated)
//==================================================================
reg [8:0] booth_outs [1:0] [4:0];

reg [1:0] add_outs_s_0, add_outs_c_0;
reg [1:0] add_outs_s_1, add_outs_c_1;
reg [3:0] add_outs_s_2, add_outs_c_2;
reg [3:0] add_outs_s_3, add_outs_c_3;
reg [5:0] add_outs_s_4, add_outs_c_4;
reg [5:0] add_outs_s_5, add_outs_c_5;
reg [7:0] add_outs_s_6, add_outs_c_6;
reg [7:0] add_outs_s_7, add_outs_c_7;
reg [9:0] add_outs_s_8, add_outs_c_8;
reg [9:0] add_outs_s_9, add_outs_c_9;
reg [9:0] add_outs_s_10, add_outs_c_10;
reg [9:0] add_outs_s_11, add_outs_c_11;
reg [7:0] add_outs_s_12, add_outs_c_12;
reg [6:0] add_outs_s_13, add_outs_c_13;
reg [4:0] add_outs_s_14, add_outs_c_14;
reg [4:0] add_outs_s_15, add_outs_c_15;

wire p1_add_outs_s_0_ind_1, p1_add_outs_c_0_ind_1, p1_add_outs_s_1_ind_0, p1_add_outs_c_1_ind_0, p1_add_outs_s_1_ind_1, p1_add_outs_c_1_ind_1, p1_add_outs_s_2_ind_2, p1_add_outs_c_2_ind_2, p1_add_outs_s_2_ind_3, p1_add_outs_c_2_ind_3, p1_add_outs_s_3_ind_1, p1_add_outs_c_3_ind_1, p1_add_outs_s_3_ind_2, p1_add_outs_c_3_ind_2, p2_add_outs_s_3_ind_3, p2_add_outs_c_3_ind_3, p1_add_outs_s_4_ind_2, p1_add_outs_c_4_ind_2, p1_add_outs_s_4_ind_3, p1_add_outs_c_4_ind_3, p2_add_outs_s_4_ind_4, p2_add_outs_c_4_ind_4, p2_add_outs_s_4_ind_5, p2_add_outs_c_4_ind_5, p1_add_outs_s_5_ind_2, p1_add_outs_c_5_ind_2, p1_add_outs_s_5_ind_3, p1_add_outs_c_5_ind_3, p2_add_outs_s_5_ind_4, p2_add_outs_c_5_ind_4, p2_add_outs_s_5_ind_5, p2_add_outs_c_5_ind_5, p1_add_outs_s_6_ind_3, p1_add_outs_c_6_ind_3, p1_add_outs_s_6_ind_4, p1_add_outs_c_6_ind_4, p1_add_outs_s_6_ind_5, p1_add_outs_c_6_ind_5, p3_add_outs_s_6_ind_6, p3_add_outs_c_6_ind_6, p3_add_outs_s_6_ind_7, p3_add_outs_c_6_ind_7, p1_add_outs_s_7_ind_2, p1_add_outs_c_7_ind_2, p1_add_outs_s_7_ind_3, p1_add_outs_c_7_ind_3, p1_add_outs_s_7_ind_4, p1_add_outs_c_7_ind_4, p2_add_outs_s_7_ind_5, p2_add_outs_c_7_ind_5, p3_add_outs_s_7_ind_6, p3_add_outs_c_7_ind_6, p3_add_outs_s_7_ind_7, p3_add_outs_c_7_ind_7, p1_add_outs_s_8_ind_4, p1_add_outs_c_8_ind_4, p1_add_outs_s_8_ind_5, p1_add_outs_c_8_ind_5, p1_add_outs_s_8_ind_6, p1_add_outs_c_8_ind_6, p2_add_outs_s_8_ind_7, p2_add_outs_c_8_ind_7, p4_add_outs_s_8_ind_8, p4_add_outs_c_8_ind_8, p4_add_outs_s_8_ind_9, p4_add_outs_c_8_ind_9, p1_add_outs_s_9_ind_3, p1_add_outs_c_9_ind_3, p1_add_outs_s_9_ind_4, p1_add_outs_c_9_ind_4, p1_add_outs_s_9_ind_5, p1_add_outs_c_9_ind_5, p1_add_outs_s_9_ind_6, p1_add_outs_c_9_ind_6, p2_add_outs_s_9_ind_7, p2_add_outs_c_9_ind_7, p4_add_outs_s_9_ind_8, p4_add_outs_c_9_ind_8, p4_add_outs_s_9_ind_9, p4_add_outs_c_9_ind_9, p1_add_outs_s_10_ind_3, p1_add_outs_c_10_ind_3, p1_add_outs_s_10_ind_4, p1_add_outs_c_10_ind_4, p1_add_outs_s_10_ind_5, p1_add_outs_c_10_ind_5, p2_add_outs_s_10_ind_6, p2_add_outs_c_10_ind_6, p3_add_outs_s_10_ind_7, p3_add_outs_c_10_ind_7, p4_add_outs_s_10_ind_8, p4_add_outs_c_10_ind_8, p4_add_outs_s_10_ind_9, p4_add_outs_c_10_ind_9, p1_add_outs_s_11_ind_3, p1_add_outs_c_11_ind_3, p1_add_outs_s_11_ind_4, p1_add_outs_c_11_ind_4, p1_add_outs_s_11_ind_5, p1_add_outs_c_11_ind_5, p2_add_outs_s_11_ind_6, p2_add_outs_c_11_ind_6, p3_add_outs_s_11_ind_7, p3_add_outs_c_11_ind_7, p5_add_outs_s_11_ind_8, p5_add_outs_c_11_ind_8, p5_add_outs_s_11_ind_9, p5_add_outs_c_11_ind_9, p1_add_outs_s_12_ind_2, p1_add_outs_c_12_ind_2, p1_add_outs_s_12_ind_3, p1_add_outs_c_12_ind_3, p2_add_outs_s_12_ind_4, p2_add_outs_c_12_ind_4, p3_add_outs_s_12_ind_5, p3_add_outs_c_12_ind_5, p5_add_outs_s_12_ind_6, p5_add_outs_c_12_ind_6, p5_add_outs_s_12_ind_7, p5_add_outs_c_12_ind_7, p1_add_outs_s_13_ind_2, p1_add_outs_c_13_ind_2, p1_add_outs_s_13_ind_3, p1_add_outs_c_13_ind_3, p2_add_outs_s_13_ind_4, p2_add_outs_c_13_ind_4, p4_add_outs_s_13_ind_5, p4_add_outs_c_13_ind_5, p5_add_outs_s_13_ind_6, p5_add_outs_c_13_ind_6, p1_add_outs_s_14_ind_1, p1_add_outs_c_14_ind_1, p1_add_outs_s_14_ind_2, p1_add_outs_c_14_ind_2, p3_add_outs_s_14_ind_3, p3_add_outs_c_14_ind_3, p6_add_outs_s_14_ind_4, p6_add_outs_c_14_ind_4, p1_add_outs_s_15_ind_1, p1_add_outs_c_15_ind_1, p1_add_outs_s_15_ind_2, p1_add_outs_c_15_ind_2, p3_add_outs_s_15_ind_3, p3_add_outs_c_15_ind_3, p6_add_outs_s_15_ind_4, p6_add_outs_c_15_ind_4, c_in_0, p1_c_add_out_s_0, p1_c_add_out_c_0, p1_c_in_1, p2_c_add_out_s_1, p2_c_add_out_c_1, p1_c_in_2, p2_c_add_out_s_2, p2_c_add_out_c_2, p1_c_in_3, p2_c_add_out_s_3, p2_c_add_out_c_3, p1_c_in_4, p2_c_add_out_s_4, p2_c_add_out_c_4, p1_c_in_5, p2_c_add_out_s_5, p2_c_add_out_c_5, p2_c_in_6, p3_c_add_out_s_6, p3_c_add_out_c_6, p2_c_in_7, p3_c_add_out_s_7, p3_c_add_out_c_7, p3_c_in_8, p4_c_add_out_s_8, p4_c_add_out_c_8, p3_c_in_9, p4_c_add_out_s_9, p4_c_add_out_c_9, p3_c_in_10, p4_c_add_out_s_10, p4_c_add_out_c_10, p4_c_in_11, p5_c_add_out_s_11, p5_c_add_out_c_11, p4_c_in_12, p5_c_add_out_s_12, p5_c_add_out_c_12, p4_c_in_13, p5_c_add_out_s_13, p5_c_add_out_c_13, p5_c_in_14, p6_c_add_out_s_14, p6_c_add_out_c_14, p5_c_in_15, p6_c_add_out_s_15, p6_c_add_out_c_15, p6_c_in_16, p6_c_add_out_s_16, p6_c_add_out_c_16, p6_c_in_17, p6_c_add_out_s_17, p6_c_add_out_c_17, p6_c_in_18, p6_c_add_out_s_18, p6_c_add_out_c_18, p6_c_in_19, p6_c_add_out_s_19, p6_c_add_out_c_19, p1_reset, p2_reset, p3_reset, p4_reset, p5_reset, p6_reset, p7_reset, p2_c_add_out_s_0, p3_c_add_out_s_0, p4_c_add_out_s_0, p5_c_add_out_s_0, p6_c_add_out_s_0, p7_c_add_out_s_0, p3_c_add_out_s_1, p4_c_add_out_s_1, p5_c_add_out_s_1, p6_c_add_out_s_1, p7_c_add_out_s_1, p3_c_add_out_s_2, p4_c_add_out_s_2, p5_c_add_out_s_2, p6_c_add_out_s_2, p7_c_add_out_s_2, p3_c_add_out_s_3, p4_c_add_out_s_3, p5_c_add_out_s_3, p6_c_add_out_s_3, p7_c_add_out_s_3, p3_c_add_out_s_4, p4_c_add_out_s_4, p5_c_add_out_s_4, p6_c_add_out_s_4, p7_c_add_out_s_4, p3_c_add_out_s_5, p4_c_add_out_s_5, p5_c_add_out_s_5, p6_c_add_out_s_5, p7_c_add_out_s_5, p4_c_add_out_s_6, p5_c_add_out_s_6, p6_c_add_out_s_6, p7_c_add_out_s_6, p4_c_add_out_s_7, p5_c_add_out_s_7, p6_c_add_out_s_7, p7_c_add_out_s_7, p5_c_add_out_s_8, p6_c_add_out_s_8, p7_c_add_out_s_8, p5_c_add_out_s_9, p6_c_add_out_s_9, p7_c_add_out_s_9, p5_c_add_out_s_10, p6_c_add_out_s_10, p7_c_add_out_s_10, p6_c_add_out_s_11, p7_c_add_out_s_11, p6_c_add_out_s_12, p7_c_add_out_s_12, p6_c_add_out_s_13, p7_c_add_out_s_13, p7_c_add_out_s_14, p7_c_add_out_s_15, p7_c_add_out_s_16, p7_c_add_out_s_17, p7_c_add_out_s_18, p7_c_add_out_s_19, p1_c_in_0, p1_add_outs_s_15_ind_0, p1__invbooth_outs_ind_1_ind_3_ind_8_, p1__invbooth_outs_ind_0_ind_3_ind_8_, p1_add_outs_c_14_ind_0, p1_add_outs_s_0_ind_0, p1_booth_outs_ind_1_ind_0_ind_0, p1_add_outs_s_3_ind_0, p1_add_outs_s_2_ind_1, p1_add_outs_s_2_ind_0, p1_booth_outs_ind_1_ind_0_ind_1, p1_booth_outs_ind_0_ind_0_ind_1, p1_add_outs_c_0_ind_0, p1_add_outs_s_5_ind_1, p1_add_outs_s_4_ind_1, p1_add_outs_s_4_ind_0, p1_add_outs_c_2_ind_0, p1_booth_outs_ind_1_ind_1_ind_1, p1_add_outs_c_2_ind_1, p1_booth_outs_ind_1_ind_2_ind_0, p1_booth_outs_ind_1_ind_1_ind_2, p1_add_outs_c_3_ind_0, p1_add_outs_c_4_ind_1, p1_add_outs_c_4_ind_0, p1_add_outs_s_5_ind_0, p1_add_outs_s_7_ind_1, p1_add_outs_s_6_ind_1, p1_add_outs_s_6_ind_0, p1_add_outs_s_6_ind_2, p1_add_outs_c_5_ind_0, p1_booth_outs_ind_1_ind_3_ind_0, p1_add_outs_c_5_ind_1, p1_booth_outs_ind_1_ind_3_ind_1, p1_booth_outs_ind_1_ind_2_ind_3, p1_add_outs_c_6_ind_0, p1_add_outs_c_6_ind_2, p1_add_outs_c_6_ind_1, p1_add_outs_s_7_ind_0, p1_add_outs_s_8_ind_2, p1_add_outs_s_8_ind_1, p1_add_outs_s_8_ind_3, p1_add_outs_s_9_ind_2, p1_add_outs_s_9_ind_1, p1_add_outs_c_7_ind_1, p1_add_outs_c_7_ind_0, p1_add_outs_s_8_ind_0, p1_add_outs_s_11_ind_2, p1_add_outs_s_10_ind_0, p1_add_outs_c_9_ind_2, p1_add_outs_s_10_ind_1, p1_add_outs_c_9_ind_0, p1_booth_outs_ind_1_ind_4_ind_2, p1_add_outs_c_9_ind_1, p1_add_outs_s_10_ind_2, p1_add_outs_c_8_ind_3, p1_add_outs_c_8_ind_2, p1_add_outs_s_9_ind_0, p1_add_outs_c_8_ind_0, p1_booth_outs_ind_1_ind_4_ind_1, p1_add_outs_c_8_ind_1, p1_add_outs_s_11_ind_0, p1_add_outs_c_10_ind_2, p1_add_outs_s_11_ind_1, p1_add_outs_s_13_ind_1, p1_add_outs_s_13_ind_0, p1_add_outs_c_11_ind_1, p1_add_outs_c_11_ind_0, p1_add_outs_c_11_ind_2, p1_add_outs_s_12_ind_1, p1_add_outs_s_12_ind_0, p1_add_outs_c_10_ind_0, p1__invbooth_outs_ind_1_ind_1_ind_8_, p1_add_outs_c_10_ind_1, p1_add_outs_s_14_ind_0, p1_add_outs_c_13_ind_0, p1_booth_outs_ind_1_ind_4_ind_6, p1_add_outs_c_13_ind_1, p1_add_outs_c_12_ind_0, p1__invbooth_outs_ind_1_ind_2_ind_8_, p1_add_outs_c_12_ind_1, p2_c_in_5, p2_c_in_4, p2_c_in_3, p2_c_in_2, p2_add_outs_s_2_ind_3, p2_c_in_1, p2_c_add_out_c_0, p2_add_outs_s_1_ind_1, p2_add_outs_s_15_ind_2, p2_add_outs_c_14_ind_2, p2_add_outs_s_3_ind_2, p2_add_outs_c_2_ind_3, p2_add_outs_s_7_ind_4, p2_add_outs_s_6_ind_5, p2_add_outs_c_5_ind_3, p2_add_outs_s_5_ind_3, p2_add_outs_s_5_ind_2, p2_add_outs_s_4_ind_3, p2_add_outs_s_4_ind_2, p2_add_outs_c_3_ind_2, p2_add_outs_s_7_ind_3, p2_add_outs_s_7_ind_2, p2_add_outs_c_6_ind_5, p2_add_outs_c_7_ind_4, p2_add_outs_s_8_ind_5, p2_add_outs_s_8_ind_6, p2_add_outs_s_9_ind_5, p2_add_outs_c_8_ind_6, p2_add_outs_s_9_ind_6, p2_add_outs_s_10_ind_5, p2_add_outs_c_9_ind_6, p2_add_outs_s_11_ind_5, p2_add_outs_s_10_ind_4, p2_add_outs_s_10_ind_3, p2_add_outs_c_9_ind_5, p2_add_outs_s_12_ind_3, p2_add_outs_s_12_ind_2, p2_add_outs_c_11_ind_4, p2_add_outs_c_11_ind_5, p2_add_outs_s_11_ind_4, p2_add_outs_s_11_ind_3, p2_add_outs_c_10_ind_5, p2_add_outs_s_14_ind_2, p2_add_outs_c_13_ind_3, p2_add_outs_c_12_ind_3, p2_add_outs_s_13_ind_2, p2_add_outs_s_13_ind_3, p3_c_in_7, p3_c_in_6, p3_c_add_out_c_5, p3_add_outs_s_15_ind_2, p3_add_outs_c_14_ind_2, p3_add_outs_c_5_ind_5, p3_add_outs_c_9_ind_7, p3_add_outs_s_9_ind_7, p3_add_outs_c_8_ind_7, p3_add_outs_s_8_ind_7, p3_add_outs_c_7_ind_5, p3_add_outs_s_7_ind_5, p3_add_outs_s_7_ind_4, p3_add_outs_s_6_ind_5, p3_add_outs_c_5_ind_3, p3_add_outs_c_5_ind_4, p3_add_outs_s_10_ind_5, p3_add_outs_c_9_ind_6, p3_add_outs_s_10_ind_6, p3_add_outs_c_10_ind_6, p3_add_outs_s_11_ind_5, p3_add_outs_s_11_ind_6, p3_add_outs_s_13_ind_4, p3_add_outs_c_12_ind_4, p3_add_outs_c_11_ind_6, p3_add_outs_s_12_ind_3, p3_add_outs_s_12_ind_4, p3_add_outs_s_14_ind_2, p3_add_outs_c_13_ind_3, p3_add_outs_c_13_ind_4, p4_c_in_10, p4_c_in_9, p4_c_in_8, p4_c_add_out_c_7, p4_add_outs_s_15_ind_3, p4_add_outs_s_14_ind_3, p4_add_outs_c_7_ind_7, p4_add_outs_s_12_ind_5, p4_add_outs_c_11_ind_7, p4_add_outs_s_11_ind_7, p4_add_outs_c_10_ind_7, p4_add_outs_s_10_ind_7, p4_add_outs_c_9_ind_7, p4_add_outs_s_9_ind_7, p4_add_outs_c_8_ind_7, p4_add_outs_s_8_ind_7, p4_add_outs_c_7_ind_5, p4_add_outs_c_7_ind_6, p4_add_outs_s_13_ind_4, p4_add_outs_c_12_ind_4, p4_add_outs_c_12_ind_5, p5_c_in_13, p5_c_in_12, p5_c_in_11, p5_c_add_out_c_10, p5_add_outs_s_15_ind_3, p5_add_outs_c_13_ind_5, p5_add_outs_s_14_ind_3, p5_add_outs_s_13_ind_5, p5_add_outs_c_10_ind_9, p5_add_outs_s_12_ind_5, p5_add_outs_c_11_ind_7, p5_add_outs_s_11_ind_7, p5_add_outs_c_10_ind_7, p5_add_outs_c_10_ind_8, p6_c_in_15, p6_c_in_14, p6_c_add_out_c_13, p6_add_outs_s_15_ind_3, p6_add_outs_c_13_ind_5, p6_add_outs_s_14_ind_3, p6_add_outs_c_13_ind_6;

//==================================================================
// Submodules (Generated)
//==================================================================
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_1_0 ( .x_tuple({a1[1], a1[0],  1'b0}), .y(b1), .booth_out(booth_outs[0][0]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_1_1 ( .x_tuple({a1[3], a1[2], a1[1]}), .y(b1), .booth_out(booth_outs[0][1]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_1_2 ( .x_tuple({a1[5], a1[4], a1[3]}), .y(b1), .booth_out(booth_outs[0][2]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_1_3 ( .x_tuple({a1[7], a1[6], a1[5]}), .y(b1), .booth_out(booth_outs[0][3]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_1_4 ( .x_tuple({a1[7], a1[7], a1[7]}), .y(b1), .booth_out(booth_outs[0][4]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_2_0 ( .x_tuple({a2[1], a2[0],  1'b0}), .y(b2), .booth_out(booth_outs[1][0]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_2_1 ( .x_tuple({a2[3], a2[2], a2[1]}), .y(b2), .booth_out(booth_outs[1][1]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_2_2 ( .x_tuple({a2[5], a2[4], a2[3]}), .y(b2), .booth_out(booth_outs[1][2]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_2_3 ( .x_tuple({a2[7], a2[6], a2[5]}), .y(b2), .booth_out(booth_outs[1][3]) );
Booth_Encoder_Selector #(.BUS_WIDTH(8)) Booth_2_4 ( .x_tuple({a2[7], a2[7], a2[7]}), .y(b2), .booth_out(booth_outs[1][4]) );
FA Normal_Adder_0_0 ( .x(a2[1]), .y(a1[1]), .z(booth_outs[0][0][0]), .s(add_outs_s_0[0]), .c(add_outs_c_0[0]) );
HA Normal_Adder_0_1 ( .x(p1_add_outs_s_0_ind_0), .y(p1_booth_outs_ind_1_ind_0_ind_0), .s(p1_add_outs_s_0_ind_1), .c(p1_add_outs_c_0_ind_1) );
FA Normal_Adder_1_0 ( .x(p1_booth_outs_ind_1_ind_0_ind_1), .y(p1_booth_outs_ind_0_ind_0_ind_1), .z(p1_add_outs_c_0_ind_0), .s(p1_add_outs_s_1_ind_0), .c(p1_add_outs_c_1_ind_0) );
HA Normal_Adder_1_1 ( .x(p1_add_outs_s_1_ind_0), .y(p1_add_outs_c_0_ind_1), .s(p1_add_outs_s_1_ind_1), .c(p1_add_outs_c_1_ind_1) );
FA Normal_Adder_2_0 ( .x(a2[3]), .y(a1[3]), .z(booth_outs[0][0][2]), .s(add_outs_s_2[0]), .c(add_outs_c_2[0]) );
FA Normal_Adder_2_1 ( .x(booth_outs[1][0][2]), .y(booth_outs[0][1][0]), .z(booth_outs[1][1][0]), .s(add_outs_s_2[1]), .c(add_outs_c_2[1]) );
FA Normal_Adder_2_2 ( .x(p1_add_outs_s_2_ind_1), .y(p1_add_outs_s_2_ind_0), .z(p1_add_outs_c_1_ind_0), .s(p1_add_outs_s_2_ind_2), .c(p1_add_outs_c_2_ind_2) );
HA Normal_Adder_2_3 ( .x(p1_add_outs_s_2_ind_2), .y(p1_add_outs_c_1_ind_1), .s(p1_add_outs_s_2_ind_3), .c(p1_add_outs_c_2_ind_3) );
FA Normal_Adder_3_0 ( .x(booth_outs[0][1][1]), .y(booth_outs[0][0][3]), .z(booth_outs[1][0][3]), .s(add_outs_s_3[0]), .c(add_outs_c_3[0]) );
FA Normal_Adder_3_1 ( .x(p1_add_outs_c_2_ind_0), .y(p1_booth_outs_ind_1_ind_1_ind_1), .z(p1_add_outs_c_2_ind_1), .s(p1_add_outs_s_3_ind_1), .c(p1_add_outs_c_3_ind_1) );
FA Normal_Adder_3_2 ( .x(p1_add_outs_s_3_ind_1), .y(p1_add_outs_s_3_ind_0), .z(p1_add_outs_c_2_ind_2), .s(p1_add_outs_s_3_ind_2), .c(p1_add_outs_c_3_ind_2) );
HA Normal_Adder_3_3 ( .x(p2_add_outs_s_3_ind_2), .y(p2_add_outs_c_2_ind_3), .s(p2_add_outs_s_3_ind_3), .c(p2_add_outs_c_3_ind_3) );
FA Normal_Adder_4_0 ( .x(a2[5]), .y(a1[5]), .z(booth_outs[0][0][4]), .s(add_outs_s_4[0]), .c(add_outs_c_4[0]) );
FA Normal_Adder_4_1 ( .x(booth_outs[0][2][0]), .y(booth_outs[0][1][2]), .z(booth_outs[1][0][4]), .s(add_outs_s_4[1]), .c(add_outs_c_4[1]) );
FA Normal_Adder_4_2 ( .x(p1_booth_outs_ind_1_ind_2_ind_0), .y(p1_booth_outs_ind_1_ind_1_ind_2), .z(p1_add_outs_c_3_ind_0), .s(p1_add_outs_s_4_ind_2), .c(p1_add_outs_c_4_ind_2) );
FA Normal_Adder_4_3 ( .x(p1_add_outs_s_4_ind_1), .y(p1_add_outs_s_4_ind_0), .z(p1_add_outs_c_3_ind_1), .s(p1_add_outs_s_4_ind_3), .c(p1_add_outs_c_4_ind_3) );
FA Normal_Adder_4_4 ( .x(p2_add_outs_s_4_ind_3), .y(p2_add_outs_s_4_ind_2), .z(p2_add_outs_c_3_ind_2), .s(p2_add_outs_s_4_ind_4), .c(p2_add_outs_c_4_ind_4) );
HA Normal_Adder_4_5 ( .x(p2_add_outs_s_4_ind_4), .y(p2_add_outs_c_3_ind_3), .s(p2_add_outs_s_4_ind_5), .c(p2_add_outs_c_4_ind_5) );
FA Normal_Adder_5_0 ( .x(booth_outs[0][1][3]), .y(booth_outs[0][0][5]), .z(booth_outs[0][2][1]), .s(add_outs_s_5[0]), .c(add_outs_c_5[0]) );
FA Normal_Adder_5_1 ( .x(booth_outs[1][1][3]), .y(booth_outs[1][0][5]), .z(booth_outs[1][2][1]), .s(add_outs_s_5[1]), .c(add_outs_c_5[1]) );
FA Normal_Adder_5_2 ( .x(p1_add_outs_c_4_ind_1), .y(p1_add_outs_c_4_ind_0), .z(p1_add_outs_s_5_ind_0), .s(p1_add_outs_s_5_ind_2), .c(p1_add_outs_c_5_ind_2) );
FA Normal_Adder_5_3 ( .x(p1_add_outs_c_4_ind_2), .y(p1_add_outs_s_5_ind_1), .z(p1_add_outs_c_4_ind_3), .s(p1_add_outs_s_5_ind_3), .c(p1_add_outs_c_5_ind_3) );
FA Normal_Adder_5_4 ( .x(p2_add_outs_s_5_ind_3), .y(p2_add_outs_s_5_ind_2), .z(p2_add_outs_c_4_ind_4), .s(p2_add_outs_s_5_ind_4), .c(p2_add_outs_c_5_ind_4) );
HA Normal_Adder_5_5 ( .x(p2_add_outs_s_5_ind_4), .y(p2_add_outs_c_4_ind_5), .s(p2_add_outs_s_5_ind_5), .c(p2_add_outs_c_5_ind_5) );
FA Normal_Adder_6_0 ( .x(a2[7]), .y(a1[7]), .z(booth_outs[0][0][6]), .s(add_outs_s_6[0]), .c(add_outs_c_6[0]) );
FA Normal_Adder_6_1 ( .x(booth_outs[0][2][2]), .y(booth_outs[0][1][4]), .z(booth_outs[0][3][0]), .s(add_outs_s_6[1]), .c(add_outs_c_6[1]) );
FA Normal_Adder_6_2 ( .x(booth_outs[1][1][4]), .y(booth_outs[1][0][6]), .z(booth_outs[1][2][2]), .s(add_outs_s_6[2]), .c(add_outs_c_6[2]) );
FA Normal_Adder_6_3 ( .x(p1_add_outs_c_5_ind_0), .y(p1_booth_outs_ind_1_ind_3_ind_0), .z(p1_add_outs_c_5_ind_1), .s(p1_add_outs_s_6_ind_3), .c(p1_add_outs_c_6_ind_3) );
FA Normal_Adder_6_4 ( .x(p1_add_outs_s_6_ind_1), .y(p1_add_outs_s_6_ind_0), .z(p1_add_outs_s_6_ind_2), .s(p1_add_outs_s_6_ind_4), .c(p1_add_outs_c_6_ind_4) );
FA Normal_Adder_6_5 ( .x(p1_add_outs_s_6_ind_3), .y(p1_add_outs_c_5_ind_2), .z(p1_add_outs_s_6_ind_4), .s(p1_add_outs_s_6_ind_5), .c(p1_add_outs_c_6_ind_5) );
FA Normal_Adder_6_6 ( .x(p3_add_outs_s_6_ind_5), .y(p3_add_outs_c_5_ind_3), .z(p3_add_outs_c_5_ind_4), .s(p3_add_outs_s_6_ind_6), .c(p3_add_outs_c_6_ind_6) );
HA Normal_Adder_6_7 ( .x(p3_add_outs_s_6_ind_6), .y(p3_add_outs_c_5_ind_5), .s(p3_add_outs_s_6_ind_7), .c(p3_add_outs_c_6_ind_7) );
FA Normal_Adder_7_0 ( .x(booth_outs[0][1][5]), .y(booth_outs[0][0][7]), .z(booth_outs[0][2][3]), .s(add_outs_s_7[0]), .c(add_outs_c_7[0]) );
FA Normal_Adder_7_1 ( .x(booth_outs[1][0][7]), .y(booth_outs[0][3][1]), .z(booth_outs[1][1][5]), .s(add_outs_s_7[1]), .c(add_outs_c_7[1]) );
FA Normal_Adder_7_2 ( .x(p1_booth_outs_ind_1_ind_3_ind_1), .y(p1_booth_outs_ind_1_ind_2_ind_3), .z(p1_add_outs_c_6_ind_0), .s(p1_add_outs_s_7_ind_2), .c(p1_add_outs_c_7_ind_2) );
FA Normal_Adder_7_3 ( .x(p1_add_outs_c_6_ind_2), .y(p1_add_outs_c_6_ind_1), .z(p1_add_outs_s_7_ind_0), .s(p1_add_outs_s_7_ind_3), .c(p1_add_outs_c_7_ind_3) );
FA Normal_Adder_7_4 ( .x(p1_add_outs_c_6_ind_3), .y(p1_add_outs_s_7_ind_1), .z(p1_add_outs_c_6_ind_4), .s(p1_add_outs_s_7_ind_4), .c(p1_add_outs_c_7_ind_4) );
FA Normal_Adder_7_5 ( .x(p2_add_outs_s_7_ind_3), .y(p2_add_outs_s_7_ind_2), .z(p2_add_outs_c_6_ind_5), .s(p2_add_outs_s_7_ind_5), .c(p2_add_outs_c_7_ind_5) );
FA Normal_Adder_7_6 ( .x(p3_add_outs_s_7_ind_5), .y(p3_add_outs_s_7_ind_4), .z(p3_add_outs_c_6_ind_6), .s(p3_add_outs_s_7_ind_6), .c(p3_add_outs_c_7_ind_6) );
HA Normal_Adder_7_7 ( .x(p3_add_outs_s_7_ind_6), .y(p3_add_outs_c_6_ind_7), .s(p3_add_outs_s_7_ind_7), .c(p3_add_outs_c_7_ind_7) );
FA Normal_Adder_8_0 ( .x(a2[7]), .y(a1[7]), .z(booth_outs[0][0][8]), .s(add_outs_s_8[0]), .c(add_outs_c_8[0]) );
FA Normal_Adder_8_1 ( .x(booth_outs[0][2][4]), .y(booth_outs[0][1][6]), .z(booth_outs[0][3][2]), .s(add_outs_s_8[1]), .c(add_outs_c_8[1]) );
FA Normal_Adder_8_2 ( .x(booth_outs[1][0][8]), .y(booth_outs[0][4][0]), .z(booth_outs[1][1][6]), .s(add_outs_s_8[2]), .c(add_outs_c_8[2]) );
FA Normal_Adder_8_3 ( .x(booth_outs[1][3][2]), .y(booth_outs[1][2][4]), .z(booth_outs[1][4][0]), .s(add_outs_s_8[3]), .c(add_outs_c_8[3]) );
FA Normal_Adder_8_4 ( .x(p1_add_outs_c_7_ind_1), .y(p1_add_outs_c_7_ind_0), .z(p1_add_outs_s_8_ind_0), .s(p1_add_outs_s_8_ind_4), .c(p1_add_outs_c_8_ind_4) );
FA Normal_Adder_8_5 ( .x(p1_add_outs_s_8_ind_2), .y(p1_add_outs_s_8_ind_1), .z(p1_add_outs_s_8_ind_3), .s(p1_add_outs_s_8_ind_5), .c(p1_add_outs_c_8_ind_5) );
FA Normal_Adder_8_6 ( .x(p1_add_outs_c_7_ind_3), .y(p1_add_outs_c_7_ind_2), .z(p1_add_outs_s_8_ind_4), .s(p1_add_outs_s_8_ind_6), .c(p1_add_outs_c_8_ind_6) );
FA Normal_Adder_8_7 ( .x(p2_add_outs_c_7_ind_4), .y(p2_add_outs_s_8_ind_5), .z(p2_add_outs_s_8_ind_6), .s(p2_add_outs_s_8_ind_7), .c(p2_add_outs_c_8_ind_7) );
FA Normal_Adder_8_8 ( .x(p4_add_outs_s_8_ind_7), .y(p4_add_outs_c_7_ind_5), .z(p4_add_outs_c_7_ind_6), .s(p4_add_outs_s_8_ind_8), .c(p4_add_outs_c_8_ind_8) );
HA Normal_Adder_8_9 ( .x(p4_add_outs_s_8_ind_8), .y(p4_add_outs_c_7_ind_7), .s(p4_add_outs_s_8_ind_9), .c(p4_add_outs_c_8_ind_9) );
FA Normal_Adder_9_0 ( .x(booth_outs[0][1][7]), .y(booth_outs[0][0][8]), .z(booth_outs[0][2][5]), .s(add_outs_s_9[0]), .c(add_outs_c_9[0]) );
FA Normal_Adder_9_1 ( .x(booth_outs[0][4][1]), .y(booth_outs[0][3][3]), .z(booth_outs[1][0][8]), .s(add_outs_s_9[1]), .c(add_outs_c_9[1]) );
FA Normal_Adder_9_2 ( .x(booth_outs[1][2][5]), .y(booth_outs[1][1][7]), .z(booth_outs[1][3][3]), .s(add_outs_s_9[2]), .c(add_outs_c_9[2]) );
FA Normal_Adder_9_3 ( .x(p1_add_outs_c_8_ind_0), .y(p1_booth_outs_ind_1_ind_4_ind_1), .z(p1_add_outs_c_8_ind_1), .s(p1_add_outs_s_9_ind_3), .c(p1_add_outs_c_9_ind_3) );
FA Normal_Adder_9_4 ( .x(p1_add_outs_c_8_ind_3), .y(p1_add_outs_c_8_ind_2), .z(p1_add_outs_s_9_ind_0), .s(p1_add_outs_s_9_ind_4), .c(p1_add_outs_c_9_ind_4) );
FA Normal_Adder_9_5 ( .x(p1_add_outs_s_9_ind_2), .y(p1_add_outs_s_9_ind_1), .z(p1_add_outs_c_8_ind_4), .s(p1_add_outs_s_9_ind_5), .c(p1_add_outs_c_9_ind_5) );
FA Normal_Adder_9_6 ( .x(p1_add_outs_s_9_ind_3), .y(p1_add_outs_c_8_ind_5), .z(p1_add_outs_s_9_ind_4), .s(p1_add_outs_s_9_ind_6), .c(p1_add_outs_c_9_ind_6) );
FA Normal_Adder_9_7 ( .x(p2_add_outs_s_9_ind_5), .y(p2_add_outs_c_8_ind_6), .z(p2_add_outs_s_9_ind_6), .s(p2_add_outs_s_9_ind_7), .c(p2_add_outs_c_9_ind_7) );
FA Normal_Adder_9_8 ( .x(p4_add_outs_s_9_ind_7), .y(p4_add_outs_c_8_ind_7), .z(p4_add_outs_c_8_ind_8), .s(p4_add_outs_s_9_ind_8), .c(p4_add_outs_c_9_ind_8) );
HA Normal_Adder_9_9 ( .x(p4_add_outs_s_9_ind_8), .y(p4_add_outs_c_8_ind_9), .s(p4_add_outs_s_9_ind_9), .c(p4_add_outs_c_9_ind_9) );
FA Normal_Adder_10_0 ( .x(booth_outs[0][1][8]), .y(booth_outs[0][0][8]), .z(booth_outs[0][2][6]), .s(add_outs_s_10[0]), .c(add_outs_c_10[0]) );
FA Normal_Adder_10_1 ( .x(booth_outs[0][4][2]), .y(booth_outs[0][3][4]), .z(booth_outs[1][0][8]), .s(add_outs_s_10[1]), .c(add_outs_c_10[1]) );
FA Normal_Adder_10_2 ( .x(booth_outs[1][2][6]), .y(booth_outs[1][1][8]), .z(booth_outs[1][3][4]), .s(add_outs_s_10[2]), .c(add_outs_c_10[2]) );
FA Normal_Adder_10_3 ( .x(p1_add_outs_c_9_ind_0), .y(p1_booth_outs_ind_1_ind_4_ind_2), .z(p1_add_outs_c_9_ind_1), .s(p1_add_outs_s_10_ind_3), .c(p1_add_outs_c_10_ind_3) );
FA Normal_Adder_10_4 ( .x(p1_add_outs_s_10_ind_0), .y(p1_add_outs_c_9_ind_2), .z(p1_add_outs_s_10_ind_1), .s(p1_add_outs_s_10_ind_4), .c(p1_add_outs_c_10_ind_4) );
FA Normal_Adder_10_5 ( .x(p1_add_outs_c_9_ind_3), .y(p1_add_outs_s_10_ind_2), .z(p1_add_outs_c_9_ind_4), .s(p1_add_outs_s_10_ind_5), .c(p1_add_outs_c_10_ind_5) );
FA Normal_Adder_10_6 ( .x(p2_add_outs_s_10_ind_4), .y(p2_add_outs_s_10_ind_3), .z(p2_add_outs_c_9_ind_5), .s(p2_add_outs_s_10_ind_6), .c(p2_add_outs_c_10_ind_6) );
FA Normal_Adder_10_7 ( .x(p3_add_outs_s_10_ind_5), .y(p3_add_outs_c_9_ind_6), .z(p3_add_outs_s_10_ind_6), .s(p3_add_outs_s_10_ind_7), .c(p3_add_outs_c_10_ind_7) );
FA Normal_Adder_10_8 ( .x(p4_add_outs_s_10_ind_7), .y(p4_add_outs_c_9_ind_7), .z(p4_add_outs_c_9_ind_8), .s(p4_add_outs_s_10_ind_8), .c(p4_add_outs_c_10_ind_8) );
HA Normal_Adder_10_9 ( .x(p4_add_outs_s_10_ind_8), .y(p4_add_outs_c_9_ind_9), .s(p4_add_outs_s_10_ind_9), .c(p4_add_outs_c_10_ind_9) );
FA Normal_Adder_11_0 ( .x(booth_outs[0][3][5]), .y(booth_outs[0][2][7]), .z(booth_outs[0][4][3]), .s(add_outs_s_11[0]), .c(add_outs_c_11[0]) );
FA Normal_Adder_11_1 ( .x(booth_outs[1][3][5]), .y(booth_outs[1][2][7]), .z(booth_outs[1][4][3]), .s(add_outs_s_11[1]), .c(add_outs_c_11[1]) );
FA Normal_Adder_11_2 ( .x({!booth_outs[0][1][8]}), .y({!booth_outs[0][0][8]}), .z({!booth_outs[1][0][8]}), .s(add_outs_s_11[2]), .c(add_outs_c_11[2]) );
FA Normal_Adder_11_3 ( .x(p1_add_outs_c_10_ind_0), .y(p1__invbooth_outs_ind_1_ind_1_ind_8_), .z(p1_add_outs_c_10_ind_1), .s(p1_add_outs_s_11_ind_3), .c(p1_add_outs_c_11_ind_3) );
FA Normal_Adder_11_4 ( .x(p1_add_outs_s_11_ind_0), .y(p1_add_outs_c_10_ind_2), .z(p1_add_outs_s_11_ind_1), .s(p1_add_outs_s_11_ind_4), .c(p1_add_outs_c_11_ind_4) );
FA Normal_Adder_11_5 ( .x(p1_add_outs_c_10_ind_3), .y(p1_add_outs_s_11_ind_2), .z(p1_add_outs_c_10_ind_4), .s(p1_add_outs_s_11_ind_5), .c(p1_add_outs_c_11_ind_5) );
FA Normal_Adder_11_6 ( .x(p2_add_outs_s_11_ind_4), .y(p2_add_outs_s_11_ind_3), .z(p2_add_outs_c_10_ind_5), .s(p2_add_outs_s_11_ind_6), .c(p2_add_outs_c_11_ind_6) );
FA Normal_Adder_11_7 ( .x(p3_add_outs_c_10_ind_6), .y(p3_add_outs_s_11_ind_5), .z(p3_add_outs_s_11_ind_6), .s(p3_add_outs_s_11_ind_7), .c(p3_add_outs_c_11_ind_7) );
FA Normal_Adder_11_8 ( .x(p5_add_outs_s_11_ind_7), .y(p5_add_outs_c_10_ind_7), .z(p5_add_outs_c_10_ind_8), .s(p5_add_outs_s_11_ind_8), .c(p5_add_outs_c_11_ind_8) );
HA Normal_Adder_11_9 ( .x(p5_add_outs_s_11_ind_8), .y(p5_add_outs_c_10_ind_9), .s(p5_add_outs_s_11_ind_9), .c(p5_add_outs_c_11_ind_9) );
FA Normal_Adder_12_0 ( .x(booth_outs[0][3][6]), .y(booth_outs[0][2][8]), .z(booth_outs[0][4][4]), .s(add_outs_s_12[0]), .c(add_outs_c_12[0]) );
FA Normal_Adder_12_1 ( .x(booth_outs[1][3][6]), .y(booth_outs[1][2][8]), .z(booth_outs[1][4][4]), .s(add_outs_s_12[1]), .c(add_outs_c_12[1]) );
FA Normal_Adder_12_2 ( .x(p1_add_outs_c_11_ind_1), .y(p1_add_outs_c_11_ind_0), .z(p1_add_outs_c_11_ind_2), .s(p1_add_outs_s_12_ind_2), .c(p1_add_outs_c_12_ind_2) );
FA Normal_Adder_12_3 ( .x(p1_add_outs_s_12_ind_1), .y(p1_add_outs_s_12_ind_0), .z(p1_add_outs_c_11_ind_3), .s(p1_add_outs_s_12_ind_3), .c(p1_add_outs_c_12_ind_3) );
FA Normal_Adder_12_4 ( .x(p2_add_outs_s_12_ind_2), .y(p2_add_outs_c_11_ind_4), .z(p2_add_outs_c_11_ind_5), .s(p2_add_outs_s_12_ind_4), .c(p2_add_outs_c_12_ind_4) );
FA Normal_Adder_12_5 ( .x(p3_add_outs_c_11_ind_6), .y(p3_add_outs_s_12_ind_3), .z(p3_add_outs_s_12_ind_4), .s(p3_add_outs_s_12_ind_5), .c(p3_add_outs_c_12_ind_5) );
FA Normal_Adder_12_6 ( .x(p5_add_outs_s_12_ind_5), .y(p5_add_outs_c_11_ind_7), .z(p5_add_outs_c_11_ind_8), .s(p5_add_outs_s_12_ind_6), .c(p5_add_outs_c_12_ind_6) );
HA Normal_Adder_12_7 ( .x(p5_add_outs_s_12_ind_6), .y(p5_add_outs_c_11_ind_9), .s(p5_add_outs_s_12_ind_7), .c(p5_add_outs_c_12_ind_7) );
FA Normal_Adder_13_0 ( .x(booth_outs[0][3][7]), .y({1'b1}), .z(booth_outs[0][4][5]), .s(add_outs_s_13[0]), .c(add_outs_c_13[0]) );
FA Normal_Adder_13_1 ( .x(booth_outs[1][4][5]), .y(booth_outs[1][3][7]), .z({!booth_outs[0][2][8]}), .s(add_outs_s_13[1]), .c(add_outs_c_13[1]) );
FA Normal_Adder_13_2 ( .x(p1_add_outs_c_12_ind_0), .y(p1__invbooth_outs_ind_1_ind_2_ind_8_), .z(p1_add_outs_c_12_ind_1), .s(p1_add_outs_s_13_ind_2), .c(p1_add_outs_c_13_ind_2) );
FA Normal_Adder_13_3 ( .x(p1_add_outs_s_13_ind_1), .y(p1_add_outs_s_13_ind_0), .z(p1_add_outs_c_12_ind_2), .s(p1_add_outs_s_13_ind_3), .c(p1_add_outs_c_13_ind_3) );
FA Normal_Adder_13_4 ( .x(p2_add_outs_c_12_ind_3), .y(p2_add_outs_s_13_ind_2), .z(p2_add_outs_s_13_ind_3), .s(p2_add_outs_s_13_ind_4), .c(p2_add_outs_c_13_ind_4) );
FA Normal_Adder_13_5 ( .x(p4_add_outs_s_13_ind_4), .y(p4_add_outs_c_12_ind_4), .z(p4_add_outs_c_12_ind_5), .s(p4_add_outs_s_13_ind_5), .c(p4_add_outs_c_13_ind_5) );
FA Normal_Adder_13_6 ( .x(p5_add_outs_c_12_ind_6), .y(p5_add_outs_s_13_ind_5), .z(p5_add_outs_c_12_ind_7), .s(p5_add_outs_s_13_ind_6), .c(p5_add_outs_c_13_ind_6) );
FA Normal_Adder_14_0 ( .x(booth_outs[0][4][6]), .y(booth_outs[0][3][8]), .z(booth_outs[1][3][8]), .s(add_outs_s_14[0]), .c(add_outs_c_14[0]) );
FA Normal_Adder_14_1 ( .x(p1_add_outs_c_13_ind_0), .y(p1_booth_outs_ind_1_ind_4_ind_6), .z(p1_add_outs_c_13_ind_1), .s(p1_add_outs_s_14_ind_1), .c(p1_add_outs_c_14_ind_1) );
FA Normal_Adder_14_2 ( .x(p1_add_outs_c_13_ind_2), .y(p1_add_outs_s_14_ind_0), .z(p1_add_outs_s_14_ind_1), .s(p1_add_outs_s_14_ind_2), .c(p1_add_outs_c_14_ind_2) );
FA Normal_Adder_14_3 ( .x(p3_add_outs_s_14_ind_2), .y(p3_add_outs_c_13_ind_3), .z(p3_add_outs_c_13_ind_4), .s(p3_add_outs_s_14_ind_3), .c(p3_add_outs_c_14_ind_3) );
FA Normal_Adder_14_4 ( .x(p6_add_outs_c_13_ind_5), .y(p6_add_outs_s_14_ind_3), .z(p6_add_outs_c_13_ind_6), .s(p6_add_outs_s_14_ind_4), .c(p6_add_outs_c_14_ind_4) );
FA Normal_Adder_15_0 ( .x(booth_outs[0][4][7]), .y({1'b1}), .z(booth_outs[1][4][7]), .s(add_outs_s_15[0]), .c(add_outs_c_15[0]) );
FA Normal_Adder_15_1 ( .x(p1__invbooth_outs_ind_1_ind_3_ind_8_), .y(p1__invbooth_outs_ind_0_ind_3_ind_8_), .z(p1_add_outs_c_14_ind_0), .s(p1_add_outs_s_15_ind_1), .c(p1_add_outs_c_15_ind_1) );
FA Normal_Adder_15_2 ( .x(p1_add_outs_c_14_ind_1), .y(p1_add_outs_s_15_ind_0), .z(p1_add_outs_s_15_ind_1), .s(p1_add_outs_s_15_ind_2), .c(p1_add_outs_c_15_ind_2) );
FA Normal_Adder_15_3 ( .x(p3_add_outs_s_15_ind_2), .y(p3_add_outs_c_14_ind_2), .z(p3_add_outs_c_14_ind_3), .s(p3_add_outs_s_15_ind_3), .c(p3_add_outs_c_15_ind_3) );
HA Normal_Adder_15_4 ( .x(p6_add_outs_c_14_ind_4), .y(p6_add_outs_s_15_ind_3), .s(p6_add_outs_s_15_ind_4), .c(p6_add_outs_c_15_ind_4) );
Reset_Gate Reset_Gate_0 ( .in(p1_c_add_out_s_0), .reset(p1_reset), .out(c_in_0) );
HA Carry_Adder_0 ( .x(p1_c_in_0), .y(p1_add_outs_s_0_ind_1), .s(p1_c_add_out_s_0), .c(p1_c_add_out_c_0) );
Reset_Gate Reset_Gate_1 ( .in(p2_c_add_out_s_1), .reset(p2_reset), .out(p1_c_in_1) );
FA Carry_Adder_1 ( .x(p2_c_in_1), .y(p2_c_add_out_c_0), .z(p2_add_outs_s_1_ind_1), .s(p2_c_add_out_s_1), .c(p2_c_add_out_c_1) );
Reset_Gate Reset_Gate_2 ( .in(p2_c_add_out_s_2), .reset(p2_reset), .out(p1_c_in_2) );
FA Carry_Adder_2 ( .x(p2_c_in_2), .y(p2_add_outs_s_2_ind_3), .z(p2_c_add_out_c_1), .s(p2_c_add_out_s_2), .c(p2_c_add_out_c_2) );
Reset_Gate Reset_Gate_3 ( .in(p2_c_add_out_s_3), .reset(p2_reset), .out(p1_c_in_3) );
FA Carry_Adder_3 ( .x(p2_c_in_3), .y(p2_add_outs_s_3_ind_3), .z(p2_c_add_out_c_2), .s(p2_c_add_out_s_3), .c(p2_c_add_out_c_3) );
Reset_Gate Reset_Gate_4 ( .in(p2_c_add_out_s_4), .reset(p2_reset), .out(p1_c_in_4) );
FA Carry_Adder_4 ( .x(p2_c_in_4), .y(p2_add_outs_s_4_ind_5), .z(p2_c_add_out_c_3), .s(p2_c_add_out_s_4), .c(p2_c_add_out_c_4) );
Reset_Gate Reset_Gate_5 ( .in(p2_c_add_out_s_5), .reset(p2_reset), .out(p1_c_in_5) );
FA Carry_Adder_5 ( .x(p2_c_in_5), .y(p2_add_outs_s_5_ind_5), .z(p2_c_add_out_c_4), .s(p2_c_add_out_s_5), .c(p2_c_add_out_c_5) );
Reset_Gate Reset_Gate_6 ( .in(p3_c_add_out_s_6), .reset(p3_reset), .out(p2_c_in_6) );
FA Carry_Adder_6 ( .x(p3_c_in_6), .y(p3_add_outs_s_6_ind_7), .z(p3_c_add_out_c_5), .s(p3_c_add_out_s_6), .c(p3_c_add_out_c_6) );
Reset_Gate Reset_Gate_7 ( .in(p3_c_add_out_s_7), .reset(p3_reset), .out(p2_c_in_7) );
FA Carry_Adder_7 ( .x(p3_c_in_7), .y(p3_add_outs_s_7_ind_7), .z(p3_c_add_out_c_6), .s(p3_c_add_out_s_7), .c(p3_c_add_out_c_7) );
Reset_Gate Reset_Gate_8 ( .in(p4_c_add_out_s_8), .reset(p4_reset), .out(p3_c_in_8) );
FA Carry_Adder_8 ( .x(p4_c_in_8), .y(p4_add_outs_s_8_ind_9), .z(p4_c_add_out_c_7), .s(p4_c_add_out_s_8), .c(p4_c_add_out_c_8) );
Reset_Gate Reset_Gate_9 ( .in(p4_c_add_out_s_9), .reset(p4_reset), .out(p3_c_in_9) );
FA Carry_Adder_9 ( .x(p4_c_in_9), .y(p4_add_outs_s_9_ind_9), .z(p4_c_add_out_c_8), .s(p4_c_add_out_s_9), .c(p4_c_add_out_c_9) );
Reset_Gate Reset_Gate_10 ( .in(p4_c_add_out_s_10), .reset(p4_reset), .out(p3_c_in_10) );
FA Carry_Adder_10 ( .x(p4_c_in_10), .y(p4_add_outs_s_10_ind_9), .z(p4_c_add_out_c_9), .s(p4_c_add_out_s_10), .c(p4_c_add_out_c_10) );
Reset_Gate Reset_Gate_11 ( .in(p5_c_add_out_s_11), .reset(p5_reset), .out(p4_c_in_11) );
FA Carry_Adder_11 ( .x(p5_c_in_11), .y(p5_add_outs_s_11_ind_9), .z(p5_c_add_out_c_10), .s(p5_c_add_out_s_11), .c(p5_c_add_out_c_11) );
Reset_Gate Reset_Gate_12 ( .in(p5_c_add_out_s_12), .reset(p5_reset), .out(p4_c_in_12) );
FA Carry_Adder_12 ( .x(p5_c_in_12), .y(p5_add_outs_s_12_ind_7), .z(p5_c_add_out_c_11), .s(p5_c_add_out_s_12), .c(p5_c_add_out_c_12) );
Reset_Gate Reset_Gate_13 ( .in(p5_c_add_out_s_13), .reset(p5_reset), .out(p4_c_in_13) );
FA Carry_Adder_13 ( .x(p5_c_in_13), .y(p5_add_outs_s_13_ind_6), .z(p5_c_add_out_c_12), .s(p5_c_add_out_s_13), .c(p5_c_add_out_c_13) );
Reset_Gate Reset_Gate_14 ( .in(p6_c_add_out_s_14), .reset(p6_reset), .out(p5_c_in_14) );
FA Carry_Adder_14 ( .x(p6_c_in_14), .y(p6_add_outs_s_14_ind_4), .z(p6_c_add_out_c_13), .s(p6_c_add_out_s_14), .c(p6_c_add_out_c_14) );
Reset_Gate Reset_Gate_15 ( .in(p6_c_add_out_s_15), .reset(p6_reset), .out(p5_c_in_15) );
FA Carry_Adder_15 ( .x(p6_c_in_15), .y(p6_add_outs_s_15_ind_4), .z(p6_c_add_out_c_14), .s(p6_c_add_out_s_15), .c(p6_c_add_out_c_15) );
Reset_Gate Reset_Gate_16 ( .in(p7_c_add_out_s_16), .reset(p7_reset), .out(p6_c_in_16) );
FA Carry_Adder_16 ( .x(p6_c_in_16), .y(p6_add_outs_s_15_ind_4), .z(p6_c_add_out_c_15), .s(p6_c_add_out_s_16), .c(p6_c_add_out_c_16) );
Reset_Gate Reset_Gate_17 ( .in(p7_c_add_out_s_17), .reset(p7_reset), .out(p6_c_in_17) );
FA Carry_Adder_17 ( .x(p6_c_in_17), .y(p6_add_outs_s_15_ind_4), .z(p6_c_add_out_c_16), .s(p6_c_add_out_s_17), .c(p6_c_add_out_c_17) );
Reset_Gate Reset_Gate_18 ( .in(p7_c_add_out_s_18), .reset(p7_reset), .out(p6_c_in_18) );
FA Carry_Adder_18 ( .x(p6_c_in_18), .y(p6_add_outs_s_15_ind_4), .z(p6_c_add_out_c_17), .s(p6_c_add_out_s_18), .c(p6_c_add_out_c_18) );
Reset_Gate Reset_Gate_19 ( .in(p7_c_add_out_s_19), .reset(p7_reset), .out(p6_c_in_19) );
FA Carry_Adder_19 ( .x(p6_c_in_19), .y(p6_add_outs_s_15_ind_4), .z(p6_c_add_out_c_18), .s(p6_c_add_out_s_19), .c(p6_c_add_out_c_19) );
DFF DFF_0 ( .clk(clk), .rst_n(rst_n), .d(reset_d), .q(p1_reset) );
DFF DFF_1 ( .clk(clk), .rst_n(rst_n), .d(p1_reset), .q(p2_reset) );
DFF DFF_2 ( .clk(clk), .rst_n(rst_n), .d(p2_reset), .q(p3_reset) );
DFF DFF_3 ( .clk(clk), .rst_n(rst_n), .d(p3_reset), .q(p4_reset) );
DFF DFF_4 ( .clk(clk), .rst_n(rst_n), .d(p4_reset), .q(p5_reset) );
DFF DFF_5 ( .clk(clk), .rst_n(rst_n), .d(p5_reset), .q(p6_reset) );
DFF DFF_6 ( .clk(clk), .rst_n(rst_n), .d(p6_reset), .q(p7_reset) );
DFF DFF_7 ( .clk(clk), .rst_n(rst_n), .d(p1_c_add_out_s_0), .q(p2_c_add_out_s_0) );
DFF DFF_8 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_s_0), .q(p3_c_add_out_s_0) );
DFF DFF_9 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_0), .q(p4_c_add_out_s_0) );
DFF DFF_10 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_0), .q(p5_c_add_out_s_0) );
DFF DFF_11 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_0), .q(p6_c_add_out_s_0) );
DFF DFF_12 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_0), .q(p7_c_add_out_s_0) );
DFF DFF_13 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_s_1), .q(p3_c_add_out_s_1) );
DFF DFF_14 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_1), .q(p4_c_add_out_s_1) );
DFF DFF_15 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_1), .q(p5_c_add_out_s_1) );
DFF DFF_16 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_1), .q(p6_c_add_out_s_1) );
DFF DFF_17 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_1), .q(p7_c_add_out_s_1) );
DFF DFF_18 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_s_2), .q(p3_c_add_out_s_2) );
DFF DFF_19 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_2), .q(p4_c_add_out_s_2) );
DFF DFF_20 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_2), .q(p5_c_add_out_s_2) );
DFF DFF_21 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_2), .q(p6_c_add_out_s_2) );
DFF DFF_22 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_2), .q(p7_c_add_out_s_2) );
DFF DFF_23 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_s_3), .q(p3_c_add_out_s_3) );
DFF DFF_24 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_3), .q(p4_c_add_out_s_3) );
DFF DFF_25 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_3), .q(p5_c_add_out_s_3) );
DFF DFF_26 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_3), .q(p6_c_add_out_s_3) );
DFF DFF_27 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_3), .q(p7_c_add_out_s_3) );
DFF DFF_28 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_s_4), .q(p3_c_add_out_s_4) );
DFF DFF_29 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_4), .q(p4_c_add_out_s_4) );
DFF DFF_30 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_4), .q(p5_c_add_out_s_4) );
DFF DFF_31 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_4), .q(p6_c_add_out_s_4) );
DFF DFF_32 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_4), .q(p7_c_add_out_s_4) );
DFF DFF_33 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_s_5), .q(p3_c_add_out_s_5) );
DFF DFF_34 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_5), .q(p4_c_add_out_s_5) );
DFF DFF_35 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_5), .q(p5_c_add_out_s_5) );
DFF DFF_36 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_5), .q(p6_c_add_out_s_5) );
DFF DFF_37 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_5), .q(p7_c_add_out_s_5) );
DFF DFF_38 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_6), .q(p4_c_add_out_s_6) );
DFF DFF_39 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_6), .q(p5_c_add_out_s_6) );
DFF DFF_40 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_6), .q(p6_c_add_out_s_6) );
DFF DFF_41 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_6), .q(p7_c_add_out_s_6) );
DFF DFF_42 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_s_7), .q(p4_c_add_out_s_7) );
DFF DFF_43 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_7), .q(p5_c_add_out_s_7) );
DFF DFF_44 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_7), .q(p6_c_add_out_s_7) );
DFF DFF_45 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_7), .q(p7_c_add_out_s_7) );
DFF DFF_46 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_8), .q(p5_c_add_out_s_8) );
DFF DFF_47 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_8), .q(p6_c_add_out_s_8) );
DFF DFF_48 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_8), .q(p7_c_add_out_s_8) );
DFF DFF_49 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_9), .q(p5_c_add_out_s_9) );
DFF DFF_50 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_9), .q(p6_c_add_out_s_9) );
DFF DFF_51 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_9), .q(p7_c_add_out_s_9) );
DFF DFF_52 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_s_10), .q(p5_c_add_out_s_10) );
DFF DFF_53 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_10), .q(p6_c_add_out_s_10) );
DFF DFF_54 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_10), .q(p7_c_add_out_s_10) );
DFF DFF_55 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_11), .q(p6_c_add_out_s_11) );
DFF DFF_56 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_11), .q(p7_c_add_out_s_11) );
DFF DFF_57 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_12), .q(p6_c_add_out_s_12) );
DFF DFF_58 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_12), .q(p7_c_add_out_s_12) );
DFF DFF_59 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_s_13), .q(p6_c_add_out_s_13) );
DFF DFF_60 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_13), .q(p7_c_add_out_s_13) );
DFF DFF_61 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_14), .q(p7_c_add_out_s_14) );
DFF DFF_62 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_15), .q(p7_c_add_out_s_15) );
DFF DFF_63 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_16), .q(p7_c_add_out_s_16) );
DFF DFF_64 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_17), .q(p7_c_add_out_s_17) );
DFF DFF_65 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_18), .q(p7_c_add_out_s_18) );
DFF DFF_66 ( .clk(clk), .rst_n(rst_n), .d(p6_c_add_out_s_19), .q(p7_c_add_out_s_19) );
DFF DFF_67 ( .clk(clk), .rst_n(rst_n), .d(c_in_0), .q(p1_c_in_0) );
DFF DFF_68 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_15[0]), .q(p1_add_outs_s_15_ind_0) );
DFF DFF_69 ( .clk(clk), .rst_n(rst_n), .d({!booth_outs[1][3][8]}), .q(p1__invbooth_outs_ind_1_ind_3_ind_8_) );
DFF DFF_70 ( .clk(clk), .rst_n(rst_n), .d({!booth_outs[0][3][8]}), .q(p1__invbooth_outs_ind_0_ind_3_ind_8_) );
DFF DFF_71 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_14[0]), .q(p1_add_outs_c_14_ind_0) );
DFF DFF_72 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_0[0]), .q(p1_add_outs_s_0_ind_0) );
DFF DFF_73 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][0][0]), .q(p1_booth_outs_ind_1_ind_0_ind_0) );
DFF DFF_74 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_3[0]), .q(p1_add_outs_s_3_ind_0) );
DFF DFF_75 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_2[1]), .q(p1_add_outs_s_2_ind_1) );
DFF DFF_76 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_2[0]), .q(p1_add_outs_s_2_ind_0) );
DFF DFF_77 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][0][1]), .q(p1_booth_outs_ind_1_ind_0_ind_1) );
DFF DFF_78 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[0][0][1]), .q(p1_booth_outs_ind_0_ind_0_ind_1) );
DFF DFF_79 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_0[0]), .q(p1_add_outs_c_0_ind_0) );
DFF DFF_80 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_5[1]), .q(p1_add_outs_s_5_ind_1) );
DFF DFF_81 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_4[1]), .q(p1_add_outs_s_4_ind_1) );
DFF DFF_82 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_4[0]), .q(p1_add_outs_s_4_ind_0) );
DFF DFF_83 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_2[0]), .q(p1_add_outs_c_2_ind_0) );
DFF DFF_84 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][1][1]), .q(p1_booth_outs_ind_1_ind_1_ind_1) );
DFF DFF_85 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_2[1]), .q(p1_add_outs_c_2_ind_1) );
DFF DFF_86 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][2][0]), .q(p1_booth_outs_ind_1_ind_2_ind_0) );
DFF DFF_87 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][1][2]), .q(p1_booth_outs_ind_1_ind_1_ind_2) );
DFF DFF_88 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_3[0]), .q(p1_add_outs_c_3_ind_0) );
DFF DFF_89 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_4[1]), .q(p1_add_outs_c_4_ind_1) );
DFF DFF_90 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_4[0]), .q(p1_add_outs_c_4_ind_0) );
DFF DFF_91 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_5[0]), .q(p1_add_outs_s_5_ind_0) );
DFF DFF_92 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_7[1]), .q(p1_add_outs_s_7_ind_1) );
DFF DFF_93 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_6[1]), .q(p1_add_outs_s_6_ind_1) );
DFF DFF_94 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_6[0]), .q(p1_add_outs_s_6_ind_0) );
DFF DFF_95 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_6[2]), .q(p1_add_outs_s_6_ind_2) );
DFF DFF_96 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_5[0]), .q(p1_add_outs_c_5_ind_0) );
DFF DFF_97 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][3][0]), .q(p1_booth_outs_ind_1_ind_3_ind_0) );
DFF DFF_98 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_5[1]), .q(p1_add_outs_c_5_ind_1) );
DFF DFF_99 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][3][1]), .q(p1_booth_outs_ind_1_ind_3_ind_1) );
DFF DFF_100 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][2][3]), .q(p1_booth_outs_ind_1_ind_2_ind_3) );
DFF DFF_101 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_6[0]), .q(p1_add_outs_c_6_ind_0) );
DFF DFF_102 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_6[2]), .q(p1_add_outs_c_6_ind_2) );
DFF DFF_103 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_6[1]), .q(p1_add_outs_c_6_ind_1) );
DFF DFF_104 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_7[0]), .q(p1_add_outs_s_7_ind_0) );
DFF DFF_105 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_8[2]), .q(p1_add_outs_s_8_ind_2) );
DFF DFF_106 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_8[1]), .q(p1_add_outs_s_8_ind_1) );
DFF DFF_107 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_8[3]), .q(p1_add_outs_s_8_ind_3) );
DFF DFF_108 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_9[2]), .q(p1_add_outs_s_9_ind_2) );
DFF DFF_109 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_9[1]), .q(p1_add_outs_s_9_ind_1) );
DFF DFF_110 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_7[1]), .q(p1_add_outs_c_7_ind_1) );
DFF DFF_111 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_7[0]), .q(p1_add_outs_c_7_ind_0) );
DFF DFF_112 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_8[0]), .q(p1_add_outs_s_8_ind_0) );
DFF DFF_113 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_11[2]), .q(p1_add_outs_s_11_ind_2) );
DFF DFF_114 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_10[0]), .q(p1_add_outs_s_10_ind_0) );
DFF DFF_115 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_9[2]), .q(p1_add_outs_c_9_ind_2) );
DFF DFF_116 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_10[1]), .q(p1_add_outs_s_10_ind_1) );
DFF DFF_117 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_9[0]), .q(p1_add_outs_c_9_ind_0) );
DFF DFF_118 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][4][2]), .q(p1_booth_outs_ind_1_ind_4_ind_2) );
DFF DFF_119 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_9[1]), .q(p1_add_outs_c_9_ind_1) );
DFF DFF_120 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_10[2]), .q(p1_add_outs_s_10_ind_2) );
DFF DFF_121 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_8[3]), .q(p1_add_outs_c_8_ind_3) );
DFF DFF_122 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_8[2]), .q(p1_add_outs_c_8_ind_2) );
DFF DFF_123 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_9[0]), .q(p1_add_outs_s_9_ind_0) );
DFF DFF_124 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_8[0]), .q(p1_add_outs_c_8_ind_0) );
DFF DFF_125 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][4][1]), .q(p1_booth_outs_ind_1_ind_4_ind_1) );
DFF DFF_126 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_8[1]), .q(p1_add_outs_c_8_ind_1) );
DFF DFF_127 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_11[0]), .q(p1_add_outs_s_11_ind_0) );
DFF DFF_128 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_10[2]), .q(p1_add_outs_c_10_ind_2) );
DFF DFF_129 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_11[1]), .q(p1_add_outs_s_11_ind_1) );
DFF DFF_130 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_13[1]), .q(p1_add_outs_s_13_ind_1) );
DFF DFF_131 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_13[0]), .q(p1_add_outs_s_13_ind_0) );
DFF DFF_132 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_11[1]), .q(p1_add_outs_c_11_ind_1) );
DFF DFF_133 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_11[0]), .q(p1_add_outs_c_11_ind_0) );
DFF DFF_134 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_11[2]), .q(p1_add_outs_c_11_ind_2) );
DFF DFF_135 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_12[1]), .q(p1_add_outs_s_12_ind_1) );
DFF DFF_136 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_12[0]), .q(p1_add_outs_s_12_ind_0) );
DFF DFF_137 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_10[0]), .q(p1_add_outs_c_10_ind_0) );
DFF DFF_138 ( .clk(clk), .rst_n(rst_n), .d({!booth_outs[1][1][8]}), .q(p1__invbooth_outs_ind_1_ind_1_ind_8_) );
DFF DFF_139 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_10[1]), .q(p1_add_outs_c_10_ind_1) );
DFF DFF_140 ( .clk(clk), .rst_n(rst_n), .d(add_outs_s_14[0]), .q(p1_add_outs_s_14_ind_0) );
DFF DFF_141 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_13[0]), .q(p1_add_outs_c_13_ind_0) );
DFF DFF_142 ( .clk(clk), .rst_n(rst_n), .d(booth_outs[1][4][6]), .q(p1_booth_outs_ind_1_ind_4_ind_6) );
DFF DFF_143 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_13[1]), .q(p1_add_outs_c_13_ind_1) );
DFF DFF_144 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_12[0]), .q(p1_add_outs_c_12_ind_0) );
DFF DFF_145 ( .clk(clk), .rst_n(rst_n), .d({!booth_outs[1][2][8]}), .q(p1__invbooth_outs_ind_1_ind_2_ind_8_) );
DFF DFF_146 ( .clk(clk), .rst_n(rst_n), .d(add_outs_c_12[1]), .q(p1_add_outs_c_12_ind_1) );
DFF DFF_147 ( .clk(clk), .rst_n(rst_n), .d(p1_c_in_5), .q(p2_c_in_5) );
DFF DFF_148 ( .clk(clk), .rst_n(rst_n), .d(p1_c_in_4), .q(p2_c_in_4) );
DFF DFF_149 ( .clk(clk), .rst_n(rst_n), .d(p1_c_in_3), .q(p2_c_in_3) );
DFF DFF_150 ( .clk(clk), .rst_n(rst_n), .d(p1_c_in_2), .q(p2_c_in_2) );
DFF DFF_151 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_2_ind_3), .q(p2_add_outs_s_2_ind_3) );
DFF DFF_152 ( .clk(clk), .rst_n(rst_n), .d(p1_c_in_1), .q(p2_c_in_1) );
DFF DFF_153 ( .clk(clk), .rst_n(rst_n), .d(p1_c_add_out_c_0), .q(p2_c_add_out_c_0) );
DFF DFF_154 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_1_ind_1), .q(p2_add_outs_s_1_ind_1) );
DFF DFF_155 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_15_ind_2), .q(p2_add_outs_s_15_ind_2) );
DFF DFF_156 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_14_ind_2), .q(p2_add_outs_c_14_ind_2) );
DFF DFF_157 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_3_ind_2), .q(p2_add_outs_s_3_ind_2) );
DFF DFF_158 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_2_ind_3), .q(p2_add_outs_c_2_ind_3) );
DFF DFF_159 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_7_ind_4), .q(p2_add_outs_s_7_ind_4) );
DFF DFF_160 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_6_ind_5), .q(p2_add_outs_s_6_ind_5) );
DFF DFF_161 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_5_ind_3), .q(p2_add_outs_c_5_ind_3) );
DFF DFF_162 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_5_ind_3), .q(p2_add_outs_s_5_ind_3) );
DFF DFF_163 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_5_ind_2), .q(p2_add_outs_s_5_ind_2) );
DFF DFF_164 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_4_ind_3), .q(p2_add_outs_s_4_ind_3) );
DFF DFF_165 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_4_ind_2), .q(p2_add_outs_s_4_ind_2) );
DFF DFF_166 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_3_ind_2), .q(p2_add_outs_c_3_ind_2) );
DFF DFF_167 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_7_ind_3), .q(p2_add_outs_s_7_ind_3) );
DFF DFF_168 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_7_ind_2), .q(p2_add_outs_s_7_ind_2) );
DFF DFF_169 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_6_ind_5), .q(p2_add_outs_c_6_ind_5) );
DFF DFF_170 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_7_ind_4), .q(p2_add_outs_c_7_ind_4) );
DFF DFF_171 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_8_ind_5), .q(p2_add_outs_s_8_ind_5) );
DFF DFF_172 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_8_ind_6), .q(p2_add_outs_s_8_ind_6) );
DFF DFF_173 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_9_ind_5), .q(p2_add_outs_s_9_ind_5) );
DFF DFF_174 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_8_ind_6), .q(p2_add_outs_c_8_ind_6) );
DFF DFF_175 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_9_ind_6), .q(p2_add_outs_s_9_ind_6) );
DFF DFF_176 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_10_ind_5), .q(p2_add_outs_s_10_ind_5) );
DFF DFF_177 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_9_ind_6), .q(p2_add_outs_c_9_ind_6) );
DFF DFF_178 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_11_ind_5), .q(p2_add_outs_s_11_ind_5) );
DFF DFF_179 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_10_ind_4), .q(p2_add_outs_s_10_ind_4) );
DFF DFF_180 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_10_ind_3), .q(p2_add_outs_s_10_ind_3) );
DFF DFF_181 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_9_ind_5), .q(p2_add_outs_c_9_ind_5) );
DFF DFF_182 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_12_ind_3), .q(p2_add_outs_s_12_ind_3) );
DFF DFF_183 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_12_ind_2), .q(p2_add_outs_s_12_ind_2) );
DFF DFF_184 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_11_ind_4), .q(p2_add_outs_c_11_ind_4) );
DFF DFF_185 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_11_ind_5), .q(p2_add_outs_c_11_ind_5) );
DFF DFF_186 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_11_ind_4), .q(p2_add_outs_s_11_ind_4) );
DFF DFF_187 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_11_ind_3), .q(p2_add_outs_s_11_ind_3) );
DFF DFF_188 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_10_ind_5), .q(p2_add_outs_c_10_ind_5) );
DFF DFF_189 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_14_ind_2), .q(p2_add_outs_s_14_ind_2) );
DFF DFF_190 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_13_ind_3), .q(p2_add_outs_c_13_ind_3) );
DFF DFF_191 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_c_12_ind_3), .q(p2_add_outs_c_12_ind_3) );
DFF DFF_192 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_13_ind_2), .q(p2_add_outs_s_13_ind_2) );
DFF DFF_193 ( .clk(clk), .rst_n(rst_n), .d(p1_add_outs_s_13_ind_3), .q(p2_add_outs_s_13_ind_3) );
DFF DFF_194 ( .clk(clk), .rst_n(rst_n), .d(p2_c_in_7), .q(p3_c_in_7) );
DFF DFF_195 ( .clk(clk), .rst_n(rst_n), .d(p2_c_in_6), .q(p3_c_in_6) );
DFF DFF_196 ( .clk(clk), .rst_n(rst_n), .d(p2_c_add_out_c_5), .q(p3_c_add_out_c_5) );
DFF DFF_197 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_15_ind_2), .q(p3_add_outs_s_15_ind_2) );
DFF DFF_198 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_14_ind_2), .q(p3_add_outs_c_14_ind_2) );
DFF DFF_199 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_5_ind_5), .q(p3_add_outs_c_5_ind_5) );
DFF DFF_200 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_9_ind_7), .q(p3_add_outs_c_9_ind_7) );
DFF DFF_201 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_9_ind_7), .q(p3_add_outs_s_9_ind_7) );
DFF DFF_202 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_8_ind_7), .q(p3_add_outs_c_8_ind_7) );
DFF DFF_203 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_8_ind_7), .q(p3_add_outs_s_8_ind_7) );
DFF DFF_204 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_7_ind_5), .q(p3_add_outs_c_7_ind_5) );
DFF DFF_205 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_7_ind_5), .q(p3_add_outs_s_7_ind_5) );
DFF DFF_206 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_7_ind_4), .q(p3_add_outs_s_7_ind_4) );
DFF DFF_207 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_6_ind_5), .q(p3_add_outs_s_6_ind_5) );
DFF DFF_208 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_5_ind_3), .q(p3_add_outs_c_5_ind_3) );
DFF DFF_209 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_5_ind_4), .q(p3_add_outs_c_5_ind_4) );
DFF DFF_210 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_10_ind_5), .q(p3_add_outs_s_10_ind_5) );
DFF DFF_211 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_9_ind_6), .q(p3_add_outs_c_9_ind_6) );
DFF DFF_212 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_10_ind_6), .q(p3_add_outs_s_10_ind_6) );
DFF DFF_213 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_10_ind_6), .q(p3_add_outs_c_10_ind_6) );
DFF DFF_214 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_11_ind_5), .q(p3_add_outs_s_11_ind_5) );
DFF DFF_215 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_11_ind_6), .q(p3_add_outs_s_11_ind_6) );
DFF DFF_216 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_13_ind_4), .q(p3_add_outs_s_13_ind_4) );
DFF DFF_217 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_12_ind_4), .q(p3_add_outs_c_12_ind_4) );
DFF DFF_218 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_11_ind_6), .q(p3_add_outs_c_11_ind_6) );
DFF DFF_219 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_12_ind_3), .q(p3_add_outs_s_12_ind_3) );
DFF DFF_220 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_12_ind_4), .q(p3_add_outs_s_12_ind_4) );
DFF DFF_221 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_s_14_ind_2), .q(p3_add_outs_s_14_ind_2) );
DFF DFF_222 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_13_ind_3), .q(p3_add_outs_c_13_ind_3) );
DFF DFF_223 ( .clk(clk), .rst_n(rst_n), .d(p2_add_outs_c_13_ind_4), .q(p3_add_outs_c_13_ind_4) );
DFF DFF_224 ( .clk(clk), .rst_n(rst_n), .d(p3_c_in_10), .q(p4_c_in_10) );
DFF DFF_225 ( .clk(clk), .rst_n(rst_n), .d(p3_c_in_9), .q(p4_c_in_9) );
DFF DFF_226 ( .clk(clk), .rst_n(rst_n), .d(p3_c_in_8), .q(p4_c_in_8) );
DFF DFF_227 ( .clk(clk), .rst_n(rst_n), .d(p3_c_add_out_c_7), .q(p4_c_add_out_c_7) );
DFF DFF_228 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_15_ind_3), .q(p4_add_outs_s_15_ind_3) );
DFF DFF_229 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_14_ind_3), .q(p4_add_outs_s_14_ind_3) );
DFF DFF_230 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_7_ind_7), .q(p4_add_outs_c_7_ind_7) );
DFF DFF_231 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_12_ind_5), .q(p4_add_outs_s_12_ind_5) );
DFF DFF_232 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_11_ind_7), .q(p4_add_outs_c_11_ind_7) );
DFF DFF_233 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_11_ind_7), .q(p4_add_outs_s_11_ind_7) );
DFF DFF_234 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_10_ind_7), .q(p4_add_outs_c_10_ind_7) );
DFF DFF_235 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_10_ind_7), .q(p4_add_outs_s_10_ind_7) );
DFF DFF_236 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_9_ind_7), .q(p4_add_outs_c_9_ind_7) );
DFF DFF_237 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_9_ind_7), .q(p4_add_outs_s_9_ind_7) );
DFF DFF_238 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_8_ind_7), .q(p4_add_outs_c_8_ind_7) );
DFF DFF_239 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_8_ind_7), .q(p4_add_outs_s_8_ind_7) );
DFF DFF_240 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_7_ind_5), .q(p4_add_outs_c_7_ind_5) );
DFF DFF_241 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_7_ind_6), .q(p4_add_outs_c_7_ind_6) );
DFF DFF_242 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_s_13_ind_4), .q(p4_add_outs_s_13_ind_4) );
DFF DFF_243 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_12_ind_4), .q(p4_add_outs_c_12_ind_4) );
DFF DFF_244 ( .clk(clk), .rst_n(rst_n), .d(p3_add_outs_c_12_ind_5), .q(p4_add_outs_c_12_ind_5) );
DFF DFF_245 ( .clk(clk), .rst_n(rst_n), .d(p4_c_in_13), .q(p5_c_in_13) );
DFF DFF_246 ( .clk(clk), .rst_n(rst_n), .d(p4_c_in_12), .q(p5_c_in_12) );
DFF DFF_247 ( .clk(clk), .rst_n(rst_n), .d(p4_c_in_11), .q(p5_c_in_11) );
DFF DFF_248 ( .clk(clk), .rst_n(rst_n), .d(p4_c_add_out_c_10), .q(p5_c_add_out_c_10) );
DFF DFF_249 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_s_15_ind_3), .q(p5_add_outs_s_15_ind_3) );
DFF DFF_250 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_c_13_ind_5), .q(p5_add_outs_c_13_ind_5) );
DFF DFF_251 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_s_14_ind_3), .q(p5_add_outs_s_14_ind_3) );
DFF DFF_252 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_s_13_ind_5), .q(p5_add_outs_s_13_ind_5) );
DFF DFF_253 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_c_10_ind_9), .q(p5_add_outs_c_10_ind_9) );
DFF DFF_254 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_s_12_ind_5), .q(p5_add_outs_s_12_ind_5) );
DFF DFF_255 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_c_11_ind_7), .q(p5_add_outs_c_11_ind_7) );
DFF DFF_256 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_s_11_ind_7), .q(p5_add_outs_s_11_ind_7) );
DFF DFF_257 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_c_10_ind_7), .q(p5_add_outs_c_10_ind_7) );
DFF DFF_258 ( .clk(clk), .rst_n(rst_n), .d(p4_add_outs_c_10_ind_8), .q(p5_add_outs_c_10_ind_8) );
DFF DFF_259 ( .clk(clk), .rst_n(rst_n), .d(p5_c_in_15), .q(p6_c_in_15) );
DFF DFF_260 ( .clk(clk), .rst_n(rst_n), .d(p5_c_in_14), .q(p6_c_in_14) );
DFF DFF_261 ( .clk(clk), .rst_n(rst_n), .d(p5_c_add_out_c_13), .q(p6_c_add_out_c_13) );
DFF DFF_262 ( .clk(clk), .rst_n(rst_n), .d(p5_add_outs_s_15_ind_3), .q(p6_add_outs_s_15_ind_3) );
DFF DFF_263 ( .clk(clk), .rst_n(rst_n), .d(p5_add_outs_c_13_ind_5), .q(p6_add_outs_c_13_ind_5) );
DFF DFF_264 ( .clk(clk), .rst_n(rst_n), .d(p5_add_outs_s_14_ind_3), .q(p6_add_outs_s_14_ind_3) );
DFF DFF_265 ( .clk(clk), .rst_n(rst_n), .d(p5_add_outs_c_13_ind_6), .q(p6_add_outs_c_13_ind_6) );


//==================================================================
// Output
//==================================================================
assign cout = {p7_c_add_out_s_19, p7_c_add_out_s_18, p7_c_add_out_s_17, p7_c_add_out_s_16, p7_c_add_out_s_15, p7_c_add_out_s_14, p7_c_add_out_s_13, p7_c_add_out_s_12, p7_c_add_out_s_11, p7_c_add_out_s_10, p7_c_add_out_s_9, p7_c_add_out_s_8, p7_c_add_out_s_7, p7_c_add_out_s_6, p7_c_add_out_s_5, p7_c_add_out_s_4, p7_c_add_out_s_3, p7_c_add_out_s_2, p7_c_add_out_s_1, p7_c_add_out_s_0};
assign cout_pre_reset = p7_reset;

endmodule

//=========================== Submodules ===========================//

module Booth_Encoder_Selector #(parameter BUS_WIDTH)  (
    input [2:0] x_tuple,
    input signed [BUS_WIDTH - 1 : 0] y,
    output reg signed [BUS_WIDTH : 0] booth_out
);

// Encoder
wire single = x_tuple[1] ^ x_tuple[0];
wire double = (x_tuple == 3'b011) || (x_tuple == 3'b100);
wire neg    = x_tuple[2];

// Selector
reg signed [BUS_WIDTH : 0] val;
always @(*) begin
    val = 0;
    if (single) val = y;
    if (double) val = y << 1;

    booth_out = val;
    if (neg) booth_out = ~val;
end

endmodule

module HA (input x, input y, output s, output c);
    assign s = x ^ y;
    assign c = x && y;
endmodule

module FA (input x, input y, input z, output s, output c);
    assign s = x ^ y ^ z;
    assign c = (x && y) || (y && z) || (z && x);
endmodule

module DFF (input clk, input rst_n, input d, output reg q);
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) q <= 0;
        else        q <= d;
    end
endmodule

module Reset_Gate (input in, input reset, output out);
    //assign out = reset? 0 : in;
    assign out = (!reset) && in; //Why EDA is this faster?
endmodule

//==================================================================
//============================= Report =============================
//
//  Combinational data:
//      Max Delay         = 72.5
//      Path to           = c_add_out_s_19
//
//  Sub-Modules List:
//      Booth           : 10
//      FA              : 110
//      HA              : 15
//      Reset_Gate      : 20
//      DFF             : 266
//
//  Stage 1
//      Time require   = 8.7
//      Retiming Count = 112
//      DFFs Count     = 82
//  Stage 2
//      Time require   = 15.95
//      Retiming Count = 68
//      DFFs Count     = 49
//  Stage 3
//      Time require   = 19.58
//      Retiming Count = 49
//      DFFs Count     = 37
//  Stage 4
//      Time require   = 23.93
//      Retiming Count = 35
//      DFFs Count     = 30
//  Stage 5
//      Time require   = 29.0
//      Retiming Count = 22
//      DFFs Count     = 26
//  Stage 6
//      Time require   = 31.9
//      Retiming Count = 12
//      DFFs Count     = 22
//  Output
//      DFFs Count     = 20
//  
//==================================================================


//
// area    = 221004.61 = (comb) 101134.15 + (seq) 119870.45
// latency = 101 cycle / pattern
// clock   = 2.2 ns
//

