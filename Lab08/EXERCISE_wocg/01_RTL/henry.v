// synopsys translate_off
`ifdef RTL
    `include "GATED_OR.v"
`else
    `include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module LAB8_DESIGN(
    clk,
    rst_n,
    in_valid,
    in_data,
    cg_en,
    out_valid,
    out_data
);

input              clk;
input              rst_n;
input              in_valid;
input       [7:0]  in_data;
input              cg_en;
output reg         out_valid;
output reg  [11:0] out_data;

integer i, j;
genvar  gj;

reg [7:0]  A_matrix       [0:3][0:3];
reg [7:0]  B_matrix       [0:3][0:3];
reg [3:0]  F1_matrix      [0:3][0:3];
reg [3:0]  H1_matrix      [0:3][0:3];
reg [3:0]  F2_matrix      [0:3][0:3];
reg [3:0]  H2_matrix      [0:3][0:3];

reg [3:0]  X1_buf         [0:3];     // 4-cell row buffer (was 16-cell 2D)
reg [7:0]  Y1_buf         [0:3];     // 4-cell row buffer (was 16-cell 2D)
reg [7:0]  BX1_buf        [0:3];     // 4-cell row buffer (was 16-cell 12-bit; high 4-bit always 0 → narrow to 8-bit)
reg [11:0] MidB_matrix    [0:3][0:3];
reg [3:0]  X2_buf         [0:3];     // 4-cell row buffer (was 16-cell 2D)

reg [6:0] input_counter;
reg [1:0] mat_row, mat_col;
reg       task_num;

reg       div_active;
reg [1:0] div_row;
reg [1:0] div_col;
reg [1:0] div_row_d;
reg [1:0] div_col_d;
reg       div_active_d;


reg [4:0] out_idx;
reg       out_active;

reg [4:0] next_idx;
reg       next_valid;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)             input_counter <= 0;
    else if (in_valid)      input_counter <= input_counter + 1;
    else                    input_counter <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)                                 task_num <= 0;
    else if (in_valid && input_counter == 0)    task_num <= in_data[0];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mat_row <= 0;  mat_col <= 0;
    end
    else if (in_valid) begin
        if (input_counter == 0  || input_counter == 16 || input_counter == 32 ||
            input_counter == 48 || input_counter == 64 || input_counter == 80) begin
            mat_row <= 0;  mat_col <= 0;
        end
        else begin
            if (mat_col == 3) begin  mat_col <= 0;  mat_row <= mat_row + 1;  end
            else                     mat_col <= mat_col + 1;
        end
    end
    else begin
        mat_row <= 0;  mat_col <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                A_matrix[i][j] <= 8'd0;
    end
    else if (in_valid && input_counter >= 1 && input_counter <= 16)
        A_matrix[mat_row][mat_col] <= in_data;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                B_matrix[i][j] <= 8'd0;
    end
    else if (in_valid && input_counter >= 17 && input_counter <= 32)
        B_matrix[mat_row][mat_col] <= in_data;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                F1_matrix[i][j] <= 4'd0;
    end
    else if (in_valid && input_counter >= 33 && input_counter <= 48)
        F1_matrix[mat_row][mat_col] <= in_data[3:0];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                H1_matrix[i][j] <= 4'd0;
    end
    else if (in_valid && input_counter >= 49 && input_counter <= 64)
        H1_matrix[mat_row][mat_col] <= in_data[3:0];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                F2_matrix[i][j] <= 4'd0;
    end
    else if (in_valid && input_counter >= 65 && input_counter <= 80)
        F2_matrix[mat_row][mat_col] <= in_data[3:0];
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                H2_matrix[i][j] <= 4'd0;
    end
    else if (in_valid && input_counter >= 81 && input_counter <= 96)
        H2_matrix[mat_row][mat_col] <= in_data[3:0];
end

reg [1:0]  macF_step;
reg [1:0]  macF_row;
reg        macF_active;
reg [1:0]  macF_stage;
reg [19:0] macF_acc [0:3];

wire [19:0] macF_prod     [0:3];
wire [19:0] macF_acc_next [0:3];
wire [3:0] macF_mod15_0;
wire [3:0] macF_mod15_1;
wire [3:0] macF_mod15_2;
wire [3:0] macF_mod15_3;

mod15 u_macF_mod15_0 (.acc(macF_acc_next[0][17:0]), .mod15_18b(macF_mod15_0));
mod15 u_macF_mod15_1 (.acc(macF_acc_next[1][17:0]), .mod15_18b(macF_mod15_1));
mod15 u_macF_mod15_2 (.acc(macF_acc_next[2][17:0]), .mod15_18b(macF_mod15_2));
mod15 u_macF_mod15_3 (.acc(macF_acc_next[3][17:0]), .mod15_18b(macF_mod15_3));

reg [1:0]  macH_step;
reg [1:0]  macH_row;
reg        macH_active;
reg [1:0]  macH_stage;
reg [19:0] macH_acc [0:3];

wire [19:0] macH_prod     [0:3];
wire [19:0] macH_acc_next [0:3];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        macF_active <= 1'b0;
        macF_step   <= 2'd0;
        macF_row    <= 2'd0;
        macF_stage  <= 2'd0;
    end
    else if (in_valid && input_counter == 53 && task_num == 1'b0) begin
        macF_active <= 1'b1;
        macF_step   <= 2'd0;
        macF_row    <= 2'd0;
        macF_stage  <= 2'b00;
    end
    else if (in_valid && input_counter == 92 && task_num == 1'b0) begin
        macF_active <= 1'b1;
        macF_step   <= 2'd0;
        macF_row    <= 2'd0;
        macF_stage  <= 2'b01;
    end
    else if (in_valid && input_counter == 85 && task_num == 1'b1) begin
        macF_active <= 1'b1;
        macF_step   <= 2'd0;
        macF_row    <= 2'd0;
        macF_stage  <= 2'b10;
    end
    else if (task_num == 1'b1 && out_active && out_idx == 5'd10) begin
        macF_active <= 1'b1;
        macF_step   <= 2'd0;
        macF_row    <= 2'd0;
        macF_stage  <= 2'b11;
    end
    else if (macF_active) begin
        if (macF_step == 2'd3) begin
            if (macF_row == 2'd3) begin
                macF_active <= 1'b0;
                macF_row    <= 2'd0;
                macF_step   <= 2'd0;
            end
            else begin
                macF_row  <= macF_row + 2'd1;
                macF_step <= 2'd0;
            end
        end
        else begin
            macF_step <= macF_step + 2'd1;
        end
    end
end

generate
    for (gj = 0; gj < 4; gj = gj + 1) begin: macF_prod_gen
        wire [3:0]  fcoef;
        wire [11:0] fdat;
        // Operand isolation: when macF_active=0, pin operands to 0 so the
        // 4 multipliers + acc-next adders don't toggle with unrelated F/A/B/MidB
        // register changes (data gating, saves dynamic power).
        assign fcoef = ~macF_active            ? 4'd0 :
                       (macF_stage == 2'b00)   ? F1_matrix[macF_row][macF_step] :
                       (macF_stage == 2'b01)   ? F2_matrix[macF_row][macF_step] :
                       (macF_stage == 2'b10)   ? F2_matrix[macF_row][macF_step] :
                                                 F1_matrix[macF_row][macF_step];
        assign fdat  = ~macF_active            ? 12'd0 :
                       (macF_stage == 2'b00)   ? {4'd0, A_matrix[macF_step][gj]} :
                       (macF_stage == 2'b01)   ?       MidB_matrix[macF_step][gj] :
                       (macF_stage == 2'b10)   ? {4'd0, B_matrix[macF_step][gj]} :
                                                       MidB_matrix[macF_step][gj];
        assign macF_prod[gj] = fcoef * fdat;
    end
endgenerate

assign macF_acc_next[0] = (macF_step == 2'd0) ? macF_prod[0] : macF_acc[0] + macF_prod[0];
assign macF_acc_next[1] = (macF_step == 2'd0) ? macF_prod[1] : macF_acc[1] + macF_prod[1];
assign macF_acc_next[2] = (macF_step == 2'd0) ? macF_prod[2] : macF_acc[2] + macF_prod[2];
assign macF_acc_next[3] = (macF_step == 2'd0) ? macF_prod[3] : macF_acc[3] + macF_prod[3];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 4; j = j + 1) begin
            macF_acc[j] <= 20'd0;
        end
    end
    else if (macF_active) begin
        for (j = 0; j < 4; j = j + 1) begin
            macF_acc[j] <= macF_acc_next[j];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        X1_buf[0] <= 4'd0;
        X1_buf[1] <= 4'd0;
        X1_buf[2] <= 4'd0;
        X1_buf[3] <= 4'd0;
    end
    else if (macF_active && macF_step == 2'd3 &&
             (macF_stage == 2'b00 || macF_stage == 2'b11)) begin
        X1_buf[0] <= macF_mod15_0 + 4'd1;
        X1_buf[1] <= macF_mod15_1 + 4'd1;
        X1_buf[2] <= macF_mod15_2 + 4'd1;
        X1_buf[3] <= macF_mod15_3 + 4'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        X2_buf[0] <= 4'd0;
        X2_buf[1] <= 4'd0;
        X2_buf[2] <= 4'd0;
        X2_buf[3] <= 4'd0;
    end
    else if (macF_active && macF_step == 2'd3 &&
             (macF_stage == 2'b01 || macF_stage == 2'b10)) begin
        X2_buf[0] <= macF_mod15_0 + 4'd1;
        X2_buf[1] <= macF_mod15_1 + 4'd1;
        X2_buf[2] <= macF_mod15_2 + 4'd1;
        X2_buf[3] <= macF_mod15_3 + 4'd1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        macH_active <= 1'b0;
        macH_step   <= 2'd0;
        macH_row    <= 2'd0;
        macH_stage  <= 2'd0;
    end
    else if (in_valid && input_counter == 53 && task_num == 1'b0) begin
        macH_active <= 1'b1;
        macH_step   <= 2'd0;
        macH_row    <= 2'd0;
        macH_stage  <= 2'b00;
    end
    else if (in_valid && input_counter == 92 && task_num == 1'b0) begin
        macH_active <= 1'b1;
        macH_step   <= 2'd0;
        macH_row    <= 2'd0;
        macH_stage  <= 2'b01;
    end
    else if (in_valid && input_counter == 84 && task_num == 1'b1) begin
        macH_active <= 1'b1;
        macH_step   <= 2'd0;
        macH_row    <= 2'd0;
        macH_stage  <= 2'b10;
    end
    else if (task_num == 1'b1 && out_active && out_idx == 5'd10) begin
        macH_active <= 1'b1;
        macH_step   <= 2'd0;
        macH_row    <= 2'd0;
        macH_stage  <= 2'b11;
    end
    else if (macH_active) begin
        if (macH_step == 2'd3) begin
            if (macH_row == 2'd3) begin
                macH_active <= 1'b0;
                macH_row    <= 2'd0;
                macH_step   <= 2'd0;
            end
            else begin
                macH_row  <= macH_row + 2'd1;
                macH_step <= 2'd0;
            end
        end
        else begin
            macH_step <= macH_step + 2'd1;
        end
    end
end

generate
    for (gj = 0; gj < 4; gj = gj + 1) begin: macH_prod_gen
        wire [3:0]  hcoef;
        wire [11:0] hdat;
        // Operand isolation: pin to 0 when macH_active=0 (saves dynamic power).
        assign hcoef = ~macH_active            ? 4'd0 :
                       (macH_stage == 2'b00)   ? H1_matrix[macH_row][macH_step] :
                       (macH_stage == 2'b01)   ? H2_matrix[macH_row][macH_step] :
                       (macH_stage == 2'b10)   ? H2_matrix[macH_row][macH_step] :
                                                 H1_matrix[macH_row][macH_step];
        assign hdat  = ~macH_active            ? 12'd0 :
                       (macH_stage == 2'b00)   ? {4'd0, A_matrix[macH_step][gj]} :
                       (macH_stage == 2'b01)   ?       MidB_matrix[macH_step][gj] :
                       (macH_stage == 2'b10)   ? {4'd0, B_matrix[macH_step][gj]} :
                                                       MidB_matrix[macH_step][gj];
        assign macH_prod[gj] = hcoef * hdat;
    end
endgenerate

assign macH_acc_next[0] = (macH_step == 2'd0) ? macH_prod[0] : macH_acc[0] + macH_prod[0];
assign macH_acc_next[1] = (macH_step == 2'd0) ? macH_prod[1] : macH_acc[1] + macH_prod[1];
assign macH_acc_next[2] = (macH_step == 2'd0) ? macH_prod[2] : macH_acc[2] + macH_prod[2];
assign macH_acc_next[3] = (macH_step == 2'd0) ? macH_prod[3] : macH_acc[3] + macH_prod[3];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (j = 0; j < 4; j = j + 1) begin
            macH_acc[j] <= 20'd0;
        end
    end
    else if (macH_active) begin
        for (j = 0; j < 4; j = j + 1) begin
            macH_acc[j] <= macH_acc_next[j];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Y1_buf[0] <= 8'd0;
        Y1_buf[1] <= 8'd0;
        Y1_buf[2] <= 8'd0;
        Y1_buf[3] <= 8'd0;
    end
    else if (macH_active && macH_step == 2'd3 &&
             (macH_stage == 2'b00 || macH_stage == 2'b11)) begin
        Y1_buf[0] <= macH_acc_next[0][7:0];
        Y1_buf[1] <= macH_acc_next[1][7:0];
        Y1_buf[2] <= macH_acc_next[2][7:0];
        Y1_buf[3] <= macH_acc_next[3][7:0];
    end
end

reg [1:0] macF_step_d;
reg [1:0] macF_row_d;
reg [1:0] macF_stage_d;
reg       macF_active_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        macF_step_d <= 0;  macF_row_d <= 0;
        macF_stage_d <= 0; macF_active_d <= 0;
    end
    else begin
        macF_step_d   <= macF_step;
        macF_row_d    <= macF_row;
        macF_stage_d  <= macF_stage;
        macF_active_d <= macF_active;
    end
end
wire macF_step3_d = macF_active_d && (macF_step_d == 2'd3);

reg [1:0] macH_step_d;
reg [1:0] macH_row_d;
reg [1:0] macH_stage_d;
reg       macH_active_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        macH_step_d <= 0;  macH_row_d <= 0;
        macH_stage_d <= 0; macH_active_d <= 0;
    end
    else begin
        macH_step_d   <= macH_step;
        macH_row_d    <= macH_row;
        macH_stage_d  <= macH_stage;
        macH_active_d <= macH_active;
    end
end
wire macH_step3_d = macH_active_d && (macH_step_d == 2'd3);

reg       mul_active;
reg [1:0] mul_row;
reg [1:0] mul_col;

wire [1:0]  out_r;
wire [1:0]  out_c;

// Multiplier — used by:
//   task=0 mul phase 0 (mul_active): X1_buf · B → fused XOR with Y1 → MidB
//   task=0 OUT_A output: X2_buf · A → fused XOR with BX1(Y2) → out_data
// Otherwise idle: operands forced to 0 to prevent toggling on unrelated
// register changes (data gating).
wire mul_use_outa = next_valid && (next_idx < 5'd16) && (task_num == 1'b0);
wire mul_in_use   = mul_active | mul_use_outa;

wire [1:0]  mul_sel_row  = mul_active ? mul_row : out_r;
wire [1:0]  mul_sel_col  = mul_active ? mul_col : out_c;
wire [3:0]  mul_a_x      = ~mul_in_use ? 4'd0 :
                           mul_active  ? X1_buf [mul_sel_col]
                                       : X2_buf [mul_sel_col];
wire [7:0]  mul_b_v      = ~mul_in_use ? 8'd0 :
                           mul_active  ? B_matrix [mul_sel_row][mul_sel_col]
                                       : A_matrix [mul_sel_row][mul_sel_col];
wire [11:0] mul_prod     = mul_a_x * mul_b_v;
wire [7:0]  mul_y_v      = ~mul_in_use ? 8'd0 :
                           mul_active  ? Y1_buf  [mul_sel_col]
                                       : BX1_buf [mul_sel_col];
wire [11:0] mul_xor      = mul_prod ^ {4'd0, mul_y_v};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mul_active   <= 1'b0;
        mul_row      <= 2'd0;
        mul_col      <= 2'd0;
    end
    else begin
        if (task_num == 1'b0 && macH_active && macH_stage == 2'b00 &&
            macH_step == 2'd3 && macH_row == 2'd0 && !mul_active) begin
            mul_active <= 1'b1;
            mul_row    <= 2'd0;
            mul_col    <= 2'd0;
        end
        else if (mul_active) begin
            if (mul_col == 2'd3) begin
                if (mul_row == 2'd3) begin
                    mul_active <= 1'b0;
                    mul_row    <= 2'd0;
                    mul_col    <= 2'd0;
                end
                else begin
                    mul_row <= mul_row + 2'd1;
                    mul_col <= 2'd0;
                end
            end
            else begin
                mul_col <= mul_col + 2'd1;
            end
        end
    end
end

wire xor_t1a = macH_step3_d && macH_stage_d == 2'b10;

wire [1:0]  xor_row = macH_row_d;

wire [11:0] xor_y [0:3];

// xor_y operand isolation: result only used when xor_t1a=1 (writing MidB
// for task=1). When xor_t1a=0, drive 0 so the 4 XOR lanes don't toggle on
// A/BX1 register changes.
generate
    for (gj = 0; gj < 4; gj = gj + 1) begin: xor_lane_gen
        assign xor_y[gj] = ~xor_t1a ? 12'd0 :
                           ({4'd0, A_matrix[xor_row][gj]}
                          ^ {4'd0, BX1_buf[gj]});
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        BX1_buf[0] <= 8'd0;
        BX1_buf[1] <= 8'd0;
        BX1_buf[2] <= 8'd0;
        BX1_buf[3] <= 8'd0;
    end
    else if (macH_active && macH_step == 2'd3 &&
             (macH_stage == 2'b01 || macH_stage == 2'b10)) begin
        BX1_buf[0] <= macH_acc_next[0][7:0];
        BX1_buf[1] <= macH_acc_next[1][7:0];
        BX1_buf[2] <= macH_acc_next[2][7:0];
        BX1_buf[3] <= macH_acc_next[3][7:0];
    end
end

// Divider — narrowed to 8-bit/4-bit → 8-bit.
//   task=1 div phase 0: num = MidB[div_row][div_col][7:0] (xor_t1a wrote
//     A^Y2 = 8-bit; high 4-bit always 0), den = X2_buf[div_col]
//   task=1 OUT_B output: num = B[out_r][out_c] ^ Y1_buf[out_c] (8-bit),
//     den = X1_buf[out_c]
//   Otherwise (idle): operands forced to 0 → divider doesn't toggle on
//   unrelated register changes (data gating).
wire div_use_outb = next_valid && (next_idx >= 5'd16) && (task_num == 1'b1);
wire div_in_use   = div_active | div_use_outb;

wire [7:0] div_num_in    = ~div_in_use ? 8'd0 :
                            div_active ? MidB_matrix[div_row][div_col][7:0]
                                       : (B_matrix[out_r][out_c] ^ Y1_buf[out_c]);
wire [3:0] div_den_in    = ~div_in_use ? 4'd0 :
                            div_active ? X2_buf[div_col]
                                       : X1_buf[out_c];
wire [7:0] div_quot_8    = div_num_in / {4'd0, div_den_in};
wire [11:0] div_quot     = {4'd0, div_quot_8};

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1)
            for (j = 0; j < 4; j = j + 1)
                MidB_matrix[i][j] <= 12'd0;
    end
    else begin
        if (mul_active)
            MidB_matrix[mul_row][mul_col] <= mul_xor;

        if (xor_t1a) begin
            MidB_matrix[xor_row][0] <= xor_y[0];
            MidB_matrix[xor_row][1] <= xor_y[1];
            MidB_matrix[xor_row][2] <= xor_y[2];
            MidB_matrix[xor_row][3] <= xor_y[3];
        end

        if (div_active)
            MidB_matrix[div_row][div_col] <= div_quot;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_active   <= 1'b0;
        div_row      <= 2'd0;
        div_col      <= 2'd0;
        div_active_d <= 1'b0;
        div_row_d    <= 2'd0;
        div_col_d    <= 2'd0;
    end
    else begin
        div_active_d <= div_active;
        div_row_d    <= div_row;
        div_col_d    <= div_col;

        if (task_num == 1'b1 && macH_step3_d && macH_stage_d == 2'b10 &&
            macH_row_d == 2'd0 && !div_active) begin
            div_active <= 1'b1;
            div_row    <= 2'd0;
            div_col    <= 2'd0;
        end
        else if (div_active) begin
            if (div_col == 2'd3) begin
                if (div_row == 2'd3) begin
                    div_active <= 1'b0;
                    div_row    <= 2'd0;
                    div_col    <= 2'd0;
                end
                else begin
                    div_row <= div_row + 2'd1;
                    div_col <= 2'd0;
                end
            end
            else begin
                div_col <= div_col + 2'd1;
            end
        end
    end
end

reg in_valid_d;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)  in_valid_d <= 0;
    else         in_valid_d <= in_valid;
end
wire input_finish = in_valid_d & ~in_valid;

always @(*) begin
    if (input_finish) begin
        next_idx   = 5'd0;
        next_valid = 1'b1;
    end
    else if (out_active && out_idx != 5'd31) begin
        next_idx   = out_idx + 1;
        next_valid = 1'b1;
    end
    else begin
        next_idx   = 5'd0;
        next_valid = 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_active <= 0;
        out_idx    <= 0;
    end
    else if (input_finish) begin
        out_active <= 1;
        out_idx    <= 0;
    end
    else if (out_active) begin
        if (out_idx == 5'd31) begin
            out_active <= 0;
            out_idx    <= 0;
        end
        else begin
            out_idx <= out_idx + 1;
        end
    end
end

assign out_r                = next_idx[3:2];
assign out_c                = next_idx[1:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
        out_data  <= 12'd0;
    end
    else begin
        out_valid <= next_valid;
        if (next_valid) begin
            if (next_idx < 5'd16) begin
                if (task_num == 1'b0)
                    out_data <= mul_xor;
                else
                    out_data <= MidB_matrix[next_idx[3:2]][next_idx[1:0]];
            end
            else begin
                if (task_num == 1'b0)
                    out_data <= MidB_matrix[next_idx[3:2]][next_idx[1:0]];
                else
                    out_data <= div_quot;
            end
        end
        else begin
            out_data <= 12'd0;
        end
    end
end

endmodule

module mod15(acc, mod15_18b);
    input  [17:0] acc;
    output [3:0]  mod15_18b;

    wire [5:0] sum1;
    wire [4:0] sum2;
    wire [4:0] sum3;

    assign sum1 = acc[3:0] + acc[7:4] + acc[11:8] + acc[15:12] + {4'b0, acc[17:16]};
    assign sum2 = sum1[3:0] + {1'b0, sum1[5:4]};
    assign sum3 = (sum2 >= 5'd15) ? (sum2 - 5'd15) : sum2;

    assign mod15_18b = sum3[3:0];
endmodule