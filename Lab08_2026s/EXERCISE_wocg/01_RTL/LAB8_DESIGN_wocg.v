module LAB8_DESIGN(
    // input signals
    clk,
    rst_n,

    in_valid,
    in_data,

    // output signals
    out_valid,
    out_data
);

input              clk;
input              rst_n;

input              in_valid;
input       [7:0]  in_data;

output reg         out_valid;
output reg  [11:0] out_data;

//==================================================================
// Wire / Reg / integer / genvar 
//==================================================================
integer i, j;
genvar  idx;
reg [6:0] input_cnt;
reg task_num;
reg [7:0]  matrix_A  [3:0] [3:0];
reg [7:0]  matrix_B  [3:0] [3:0];
reg [3:0]  matrix_F1 [3:0] [3:0];
reg [3:0]  matrix_H1 [3:0] [3:0];
reg [3:0]  matrix_F2 [3:0] [3:0];
reg [3:0]  matrix_H2 [3:0] [3:0];
wire [3:0]  MAC_a_A_in [3:0];   // narrowed: pre-reduced fdata mod 15
wire [3:0]  MAC_a_B_in [3:0];   // pre-reduced fcoef mod 15
wire [7:0]  MAC_a_prod   [3:0]; // 4x4 -> 8-bit
wire [7:0]  MAC_a_sum    [3:0]; // acc + prod
reg  [3:0]  MAC_a_C_out_r [3:0]; // running mod-15 accumulator (4-bit)
wire [3:0]  MAC_a_mod15      [3:0];
wire [3:0]  MAC_a_mod15_add1 [3:0];
wire [7:0]  MAC_b_A_in [3:0];
wire [3:0]  MAC_b_B_in [3:0];
wire [7:0]  MAC_b_C_out   [3:0];
reg  [7:0]  MAC_b_C_out_r [3:0];
reg [1:0] MM_x, MM_y;
reg       MM_active;
reg [1:0] mac_phase;
// Shared row buffers: X1/X2 reuse matrix_X; Y1/Y2(=bx1) reuse matrix_Y.
// Schedule guarantees X1 consumer (BX1 phase) finishes before X2 overwrites,
// and similarly Y1 before Y2; for task 1, X2/Y2 finish before X1/Y1 overwrite.
reg [3:0]  matrix_X  [3:0];   // X1 then X2 (task0) / X2 then X1 (task1)
reg [7:0]  matrix_Y  [3:0];   // Y1 then Y2 (task0) / Y2 then Y1 (task1)
reg [11:0] matrix_MidB [3:0] [3:0];
reg [4:0] out_cnt;
reg       out_run;
reg       in_valid_d;
wire input_finish;
wire        next_valid;
wire [4:0]  next_cnt;
wire [1:0]  out_x;
wire [1:0]  out_y;
reg       bx1_active;
reg [1:0] bx1_row, bx1_col;
reg       div_active;
reg [1:0] div_row, div_col;
genvar gi, gj;
wire MM_kick_phase00;
wire MM_kick_phase01;
wire MM_kick_phase10;
wire MM_kick_phase11;
wire MM_step_last;
wire MM_phase_F1H1;
wire MM_phase_F2H2;
reg [1:0] MM_x_d, MM_y_d;
reg [1:0] mac_phase_d;
reg       MM_active_d;
wire MM_step_last_d;
reg [3:0] MAC_a_mod15_add1_d  [3:0];
reg [3:0] MAC_a_mod15_add1_dd [3:0];
reg MM_step_last_dd;
reg [1:0] mac_phase_dd;
wire OUTA_use;
wire mult_use;
wire [1:0] mult_sel_y;
wire [1:0] mult_sel_x;
wire [3:0] mult_X;
wire [7:0] mult_AB;
wire [11:0] mult_result;
wire [7:0]  mult_Y;
wire [11:0] mult_xor;
wire bx1_kick;
wire        t1a_xor_we;
wire [1:0]  t1a_xor_y;
wire [11:0] t1a_xor_val [3:0];
reg t1a_xor_we_d;
reg [1:0] t1a_xor_y_d;
wire OUTB_use;
wire div_use;
wire [7:0] div_dividend;
wire [3:0] div_divisor;
wire [7:0]  div_quot8;
wire [11:0] div_quot;
wire div_kick;

//==================================================================
// Design
//==================================================================

assign input_finish = in_valid_d & ~in_valid;
assign next_valid = input_finish | (out_run && out_cnt != 5'd31);
assign next_cnt = input_finish ? 5'd0 :
                         (out_run && out_cnt != 5'd31) ? (out_cnt + 5'd1) : 5'd0;
assign out_x = next_cnt[1:0];
assign out_y = next_cnt[3:2];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)        input_cnt <= 0;
    else if (in_valid) input_cnt <= input_cnt + 1;
    else               input_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)                            task_num <= 0;
    else if (in_valid && input_cnt == 0)   task_num <= in_data[0];
end

generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : gen_in_row
        for (gj = 0; gj < 4; gj = gj + 1) begin : gen_in_col
            // cell (gi,gj) of matrix M is written when
            //   input_cnt == OFFSET + 4*gi + gj
            // OFFSET = 1/17/33/49/65/81 for A/B/F1/H1/F2/H2..
            wire input_A;
            assign input_A  = (input_cnt == 7'd1  + 7'd4*gi + gj[6:0]);
            wire input_B;
            assign input_B  = (input_cnt == 7'd17 + 7'd4*gi + gj[6:0]);
            wire input_F1;
            assign input_F1 = (input_cnt == 7'd33 + 7'd4*gi + gj[6:0]);
            wire input_H1;
            assign input_H1 = (input_cnt == 7'd49 + 7'd4*gi + gj[6:0]);
            wire input_F2;
            assign input_F2 = (input_cnt == 7'd65 + 7'd4*gi + gj[6:0]);
            wire input_H2;
            assign input_H2 = (input_cnt == 7'd81 + 7'd4*gi + gj[6:0]);

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)                       matrix_A [gi][gj] <= 0;
                else if (input_A)   matrix_A [gi][gj] <= in_data;
            end
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)                       matrix_B [gi][gj] <= 0;
                else if (input_B)   matrix_B [gi][gj] <= in_data;
            end
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)                       matrix_F1[gi][gj] <= 0;
                else if (input_F1)  matrix_F1[gi][gj] <= in_data[3:0];
            end
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)                       matrix_H1[gi][gj] <= 0;
                else if (input_H1)  matrix_H1[gi][gj] <= in_data[3:0];
            end
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)                       matrix_F2[gi][gj] <= 0;
                else if (input_F2)  matrix_F2[gi][gj] <= in_data[3:0];
            end
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)                       matrix_H2[gi][gj] <= 0;
                else if (input_H2)  matrix_H2[gi][gj] <= in_data[3:0];
            end
        end
    end
endgenerate

assign MM_kick_phase00 = (input_cnt == 53) && (task_num == 1'b0);
assign MM_kick_phase01 = (input_cnt == 92) && (task_num == 1'b0);
assign MM_kick_phase10 = (input_cnt == 84) && (task_num == 1'b1);
assign MM_kick_phase11 = (task_num == 1'b1) && out_run && (out_cnt == 5'd10);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MM_active <= 0;
        mac_phase <= 0;
    end
    else if (MM_kick_phase00) begin
        MM_active <= 1;  mac_phase <= 2'b00;
    end
    else if (MM_kick_phase01) begin
        MM_active <= 1;  mac_phase <= 2'b01;
    end
    else if (MM_kick_phase10) begin
        MM_active <= 1;  mac_phase <= 2'b10;
    end
    else if (MM_kick_phase11) begin
        MM_active <= 1;  mac_phase <= 2'b11;
    end
    else if (MM_active && MM_x == 2'd3 && MM_y == 2'd3) begin
        MM_active <= 0;  mac_phase <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin 
        MM_x      <= 0;
        MM_y      <= 0;
    end
    else if (MM_active) begin
        MM_x <= MM_x + 1;
        MM_y <= MM_x == 2'd3 ? (MM_y + 1) : MM_y;
    end
end

assign MM_step_last = MM_active && (MM_x == 2'd3);
assign MM_phase_F1H1 = (mac_phase == 2'b00) || (mac_phase == 2'b11);
assign MM_phase_F2H2 = (mac_phase == 2'b01) || (mac_phase == 2'b10);

generate
    for (idx = 0; idx < 4; idx = idx + 1) begin : gen_mac_a_op
        wire [11:0] fdata_raw;
        wire [3:0]  fdata_mod15;
        wire [3:0]  fcoef_raw;
        wire [3:0]  fcoef_mod15;

        assign fdata_raw =
            ~MM_active                ? 12'd0 :
            (mac_phase == 2'b00)      ? {4'd0, matrix_A   [MM_x][idx]} :
            (mac_phase == 2'b01)      ?        matrix_MidB[MM_x][idx]  :
            (mac_phase == 2'b10)      ? {4'd0, matrix_B   [MM_x][idx]} :
                                               matrix_MidB[MM_x][idx];
        // 12-bit -> 4-bit mod 15 nibble fold
        mod15_12 u_fdata_mod15 (.acc(fdata_raw), .mod15_12b(fdata_mod15));

        assign fcoef_raw =
            ~MM_active   ? 4'd0 :
            MM_phase_F1H1 ? matrix_F1[MM_y][MM_x] :
                            matrix_F2[MM_y][MM_x];
        // 4-bit value 15 == 0 (mod 15)
        assign fcoef_mod15 = (fcoef_raw == 4'd15) ? 4'd0 : fcoef_raw;

        assign MAC_a_A_in[idx] = fdata_mod15;
        assign MAC_a_B_in[idx] = fcoef_mod15;
    end
endgenerate

generate
    for (idx = 0; idx < 4; idx = idx + 1) begin : gen_mac_b_op
        assign MAC_b_A_in[idx] =
            ~MM_active                ? 8'd0 :
            (mac_phase == 2'b00)      ? matrix_A   [MM_x][idx]        :
            (mac_phase == 2'b01)      ? matrix_MidB[MM_x][idx][7:0]   :
            (mac_phase == 2'b10)      ? matrix_B   [MM_x][idx]        :
                                        matrix_MidB[MM_x][idx][7:0];
        assign MAC_b_B_in[idx] =
            ~MM_active   ? 4'd0 :
            MM_phase_F1H1 ? matrix_H1[MM_y][MM_x] :
                            matrix_H2[MM_y][MM_x];
    end
endgenerate

generate
    for (idx = 0; idx < 4; idx = idx + 1) begin : gen_mac
        MAC_4_4 MAC_a (
            .A    (MAC_a_A_in[idx]),
            .B    (MAC_a_B_in[idx]),
            .C_in (MAC_a_C_out_r[idx]),
            .prod (MAC_a_prod[idx]),
            .sum  (MAC_a_sum [idx])
        );
        MAC_8_4_mod256 MAC_b (
            .A    (MAC_b_A_in[idx]),
            .B    (MAC_b_B_in[idx]),
            .C_in (MAC_b_C_out_r[idx]),
            .C_out(MAC_b_C_out[idx])
        );
        mod15_8 mod15_a (
            .acc      (MAC_a_sum[idx]),
            .mod15_8b (MAC_a_mod15[idx])
        );
        assign MAC_a_mod15_add1[idx] = MAC_a_mod15[idx] + 4'd1;
    end
endgenerate

generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : gen_mac_acc

        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)               MAC_a_C_out_r[gi] <= 0;
            else if (MM_active) begin
                if (MM_x == 2'd3)     MAC_a_C_out_r[gi] <= 0;
                else                  MAC_a_C_out_r[gi] <= MAC_a_mod15[gi];
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)               MAC_b_C_out_r[gi] <= 0;
            else if (MM_active) begin
                if (MM_x == 2'd3)     MAC_b_C_out_r[gi] <= 0;
                else                  MAC_b_C_out_r[gi] <= MAC_b_C_out[gi];
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MM_x_d <= 0; MM_y_d <= 0; mac_phase_d <= 0; MM_active_d <= 0;
    end
    else begin
        MM_x_d      <= MM_x;
        MM_y_d      <= MM_y;
        mac_phase_d <= mac_phase;
        MM_active_d <= MM_active;
    end
end
assign MM_step_last_d = MM_active_d && (MM_x_d == 2'd3);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) for (j=0;j<4;j=j+1) begin
        MAC_a_mod15_add1_d [j] <= 0;
        MAC_a_mod15_add1_dd[j] <= 0;
    end
    else for (j=0;j<4;j=j+1) begin
        MAC_a_mod15_add1_d [j] <= MAC_a_mod15_add1[j];
        MAC_a_mod15_add1_dd[j] <= MAC_a_mod15_add1_d[j];
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MM_step_last_dd <= 0; mac_phase_dd <= 0;
    end
    else begin
        MM_step_last_dd <= MM_step_last_d;
        mac_phase_dd    <= mac_phase_d;
    end
end

// matrix_X - shared row buffer for X1 and X2.
// Phase 00 (task0 X1) / 01 (task0 X2) / 11 (task1 X1) write immediately.
// Phase 10 (task1 X2) writes with 2-cycle delay so divider can finish
// reading row r at col 3 before row r+1 overwrites.
wire X_we_now   = MM_step_last && ((mac_phase == 2'b00) || (mac_phase == 2'b01) || (mac_phase == 2'b11));
wire X_we_p10_d = MM_step_last_dd && (mac_phase_dd == 2'b10);
wire X_we       = X_we_now | X_we_p10_d;
generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : gen_X_cg
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)               matrix_X[gi] <= 0;
            else if (X_we_now)        matrix_X[gi] <= MAC_a_mod15_add1[gi];
            else if (X_we_p10_d)      matrix_X[gi] <= MAC_a_mod15_add1_dd[gi];
        end
    end
endgenerate

// matrix_Y - shared row buffer for Y1 and Y2.
wire Y_we = MM_step_last;
generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : gen_Y_cg
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n)         matrix_Y[gi] <= 0;
            else if (Y_we)      matrix_Y[gi] <= MAC_b_C_out[gi];
        end
    end
endgenerate

assign OUTA_use = next_valid && (next_cnt < 5'd16) && (task_num == 1'b0);
assign mult_use = bx1_active | OUTA_use;

assign mult_sel_y = bx1_active ? bx1_row : out_y;
assign mult_sel_x = bx1_active ? bx1_col : out_x;

assign mult_X = ~mult_use   ? 4'd0 :
                     bx1_active ? matrix_X[mult_sel_x]
                                : matrix_X[mult_sel_x];
assign mult_AB = ~mult_use   ? 8'd0 :
                      bx1_active ? matrix_B[mult_sel_y][mult_sel_x]
                                 : matrix_A[mult_sel_y][mult_sel_x];
assign mult_result = mult_X * mult_AB;
assign mult_Y = ~mult_use   ? 8'd0 :
                      bx1_active ? matrix_Y[mult_sel_x]
                                 : matrix_Y  [mult_sel_x];
assign mult_xor = mult_result ^ {4'd0, mult_Y};

assign bx1_kick = (task_num == 1'b0) && MM_active && (mac_phase == 2'b00) &&
                MM_step_last && (MM_y == 2'd0) && !bx1_active;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bx1_active <= 0; 
    end
    else if (bx1_kick) begin
        bx1_active <= 1; 
    end
    else if (bx1_col == 2'd3 && bx1_row == 2'd3) begin
            bx1_active <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bx1_row <= 0; bx1_col <= 0;
    end
    else if (bx1_active) begin
        bx1_col <= bx1_col + 1;
        bx1_row <= bx1_col == 2'd3 ? (bx1_row + 1) : bx1_row;
    end
end

assign t1a_xor_we = MM_step_last_d && (mac_phase_d == 2'b10);
assign t1a_xor_y = MM_y_d;

generate
    for (idx = 0; idx < 4; idx = idx + 1) begin : gen_t1a_xor
        assign t1a_xor_val[idx] = ~t1a_xor_we ? 12'd0 :
                                  ({4'd0, matrix_A[t1a_xor_y][idx]}
                                ^ {4'd0, matrix_Y [idx]});
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        t1a_xor_we_d <= 0; t1a_xor_y_d <= 0;
    end
    else begin
        t1a_xor_we_d <= t1a_xor_we;
        t1a_xor_y_d  <= t1a_xor_y;
    end
end

assign OUTB_use = next_valid && (next_cnt >= 5'd16) && (task_num == 1'b1);
assign div_use = div_active | OUTB_use;

assign div_dividend = ~div_use   ? 8'd0 :
                           div_active ? matrix_MidB[div_row][div_col][7:0]
                                      : (matrix_B[out_y][out_x] ^ matrix_Y[out_x]);
assign div_divisor = ~div_use   ? 4'd0 :
                           div_active ? matrix_X[div_col]
                                      : matrix_X[out_x];

UDIV_8_4 u_div (
    .dividend (div_dividend),
    .divisor  (div_divisor),
    .quotient (div_quot8)
);
assign div_quot = {4'd0, div_quot8};

assign div_kick = (task_num == 1'b1) && t1a_xor_we_d && (t1a_xor_y_d == 2'd0) && !div_active;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_active <= 0;
    end
    else if (div_kick) begin
        div_active <= 1;
    end
    else if (div_col == 2'd3 && div_row == 2'd3) begin
        div_active <= 0; 
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_row <= 0; div_col <= 0;
    end
    else if (div_active) begin
        div_col <= div_col + 1;
        div_row <= div_col == 2'd3 ? (div_row + 1) : div_row;
    end
end

generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : gen_MidB_row
        for (gj = 0; gj < 4; gj = gj + 1) begin : gen_MidB_col
            wire bx1_hit;
            assign bx1_hit = bx1_active & (bx1_row    == gi) & (bx1_col == gj);
            wire t1a_hit;
            assign t1a_hit = t1a_xor_we & (t1a_xor_y  == gi);
            wire div_hit;
            assign div_hit = div_active & (div_row    == gi) & (div_col == gj);
            wire MidB_we_cell;
            assign MidB_we_cell = bx1_hit | t1a_hit | div_hit;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)            matrix_MidB[gi][gj] <= 0;
                else if (bx1_hit)      matrix_MidB[gi][gj] <= mult_xor;
                else if (t1a_hit)      matrix_MidB[gi][gj] <= t1a_xor_val[gj];
                else if (div_hit)      matrix_MidB[gi][gj] <= div_quot;
            end
        end
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) in_valid_d <= 0;
    else        in_valid_d <= in_valid;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_run <= 0; out_cnt <= 0;
    end
    else if (input_finish) begin
        out_run <= 1; out_cnt <= 0;
    end
    else if (out_run) begin
        if (out_cnt == 5'd31) begin
            out_run <= 0; out_cnt <= 0;
        end
        else out_cnt <= out_cnt + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0; out_data <= 0;
    end
    else if(next_valid)begin
        out_valid <= 1;
        if (next_cnt < 5'd16) begin
            if (task_num == 1'b0) out_data <= mult_xor;
            else                  out_data <= matrix_MidB[out_y][out_x];
        end
        else begin
            if (task_num == 1'b0) out_data <= matrix_MidB[out_y][out_x];
            else                  out_data <= div_quot;
        end
    end
    else begin
        out_valid <= 0; out_data <= 0;
    end
end

endmodule

module MAC_4_4 (
    input  [3:0] A,
    input  [3:0] B,
    input  [3:0] C_in,
    output [7:0] prod,
    output [7:0] sum
);
    assign prod = A * B;
    assign sum  = prod + {4'd0, C_in};
endmodule

module MAC_8_4_mod256 (
    input  [7:0]  A,
    input  [3:0]  B,
    input  [7:0]  C_in,
    output [7:0]  C_out
);
    assign C_out = A * B + C_in;
endmodule

// mod 15 of an 8-bit value (used after MAC_4_4 sum, max 14*14+14=210<256)
module mod15_8 (acc, mod15_8b);
    input  [7:0] acc;
    output [3:0] mod15_8b;
    wire [4:0] sum1;
    wire [4:0] red1, red2;
    assign sum1 = {1'b0, acc[3:0]} + {1'b0, acc[7:4]};
    assign red1 = (sum1 >= 5'd15) ? (sum1 - 5'd15) : sum1;
    assign red2 = (red1 >= 5'd15) ? (red1 - 5'd15) : red1;
    assign mod15_8b = red2[3:0];
endmodule

// mod 15 of a 12-bit value (nibble fold; reduces matrix_MidB to 4-bit)
module mod15_12 (acc, mod15_12b);
    input  [11:0] acc;
    output [3:0]  mod15_12b;
    wire [5:0] sum1;
    wire [4:0] fold;
    wire [4:0] red;
    assign sum1 = {2'd0, acc[3:0]} + {2'd0, acc[7:4]} + {2'd0, acc[11:8]};
    assign fold = {1'b0, sum1[3:0]} + {3'd0, sum1[5:4]};
    assign red  = (fold >= 5'd15) ? (fold - 5'd15) : fold;
    assign mod15_12b = red[3:0];
endmodule

module UDIV_8_4 (
    input  [7:0] dividend,
    input  [3:0] divisor,
    output [7:0] quotient
);
    assign quotient = (divisor == 0) ? 8'd0 : (dividend / divisor);
endmodule