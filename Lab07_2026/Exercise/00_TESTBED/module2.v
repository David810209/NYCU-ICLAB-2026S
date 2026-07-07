module CLK_2_MODULE (
    clk,
    rst_n,
    
    //INPUT
    busy,
    in_valid,
    in_data,
    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    //OUTPUT
    out_fifo_full,
    out_valid,
    out_data,
    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    //AR
    ar_fifo_full,
    ar_out_valid,
    ar_out_data,
    ar_flag_fifo_to_wclk,
    ar_flag_wclk_to_fifo,

    //R
    r_fifo_empty,
    r_fifo_rdata,
    r_fifo_rinc,
    r_flag_fifo_to_rclk,
    r_flag_rclk_to_fifo,

    ar_addr, 
    ar_valid, 
    ar_ready,
    r_data,  
    r_valid, 
    r_ready
);
input clk;
input rst_n;

output  busy;
input in_valid;
input [8:0] in_data;
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input out_fifo_full;
output reg out_valid;
output reg [31:0] out_data;
input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

input           ar_fifo_full;
output reg      ar_out_valid;
output reg [31:0]  ar_out_data;
input           ar_flag_fifo_to_wclk;
output          ar_flag_wclk_to_fifo;

input           r_fifo_empty;
input [31:0]    r_fifo_rdata;
output          r_fifo_rinc;
input           r_flag_fifo_to_rclk;
output          r_flag_rclk_to_fifo;

output [31:0]   ar_addr;
output          ar_valid; 
output          ar_ready;
output [63:0]   r_data;  
output          r_valid; 
output          r_ready;



// ============================================================
// FSM
// ============================================================
reg [4:0] state, next_state;
localparam IDLE                 = 5'd0;
localparam INIT                 = 5'd1;
localparam LOAD_ROOT       = 5'd2;
localparam CHECK_ROOT            = 5'd3;
localparam CHECK_STACK          = 5'd4;
localparam SEND_L               = 5'd5;
localparam WAIT_L               = 5'd6;
localparam SEND_R               = 5'd7;
localparam WAIT_R               = 5'd8;
localparam CALCULATE            = 5'd9;
localparam OUTPUT               = 5'd10;
localparam GAUSS                = 5'd11;
localparam GAUSS_FETCH_DRAM1    = 5'd12;
localparam GAUSS_FETCH_DRAM2    = 5'd13;
localparam GAUSS_FETCH_DRAM3    = 5'd14;
localparam GAUSS_FETCH_DRAM4    = 5'd15;
localparam GAUSS_DIV            = 5'd16;
// --- Target tag: 0 = average, 1 = sigma ---
localparam DIV_TGT_AVG   = 1'b0;
localparam DIV_TGT_SIGMA = 1'b1;
// ============================================================
// input register  declare
// =============================================================
reg [1:0] input_counter;
reg [8:0] in_data_reg [3:0];

// calc
reg [1:0]  calc_mode_tree_counter;
reg        calc_output_second_valid;




// GAUSS
reg [9:0] gauss_fetch_counter;
reg [9:0] gauss_receive_counter;
reg [1:0] gauss_iteration_counter;
reg [41:0] gauss_add_total;
reg [10:0] gauss_valid_total;
// --- Divider state ---
reg  [72:0] div_quotient;
reg  [72:0] div_remainder;
reg  [72:0] div_dividend_sr;
reg  [6:0]  div_count;
reg         div_busy;
reg         div_done;
reg         div_target;
reg [63:0] valueStack       [7:0];
reg        value_left_right [0:7];
reg [3:0]  stackpointer;
reg [35:0] arithmeticStack [12:0];
// AXI double-request helpers
reg calc_fetch_data_counter, calc_read_data_counter;
reg [31:0] calc_first_data;


// this is the internal siganl which is used to help me to all operation
wire [31:0] ar_addr_internal;
wire ar_valid_internal;
wire ar_ready_internal;
wire r_valid_internal;
wire r_ready_internal;

wire finish_one_read = (r_valid_internal && calc_read_data_counter == 1);
wire is_last_root    = (calc_mode_tree_counter == 3);


reg [1:0] fifo_read_valid;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        fifo_read_valid <= 2'b00;
    else
        fifo_read_valid <= {fifo_read_valid[0], r_fifo_rinc};
end

reg ar_ready_reg;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        ar_ready_reg <= 0;
    end
    else begin
        ar_ready_reg <= 1;
    end
end

assign ar_addr       = (calc_fetch_data_counter == 1) ? ar_addr_internal : 0;
assign ar_valid      = (calc_fetch_data_counter == 1) ? ar_valid_internal : 0;
assign ar_ready      = (calc_fetch_data_counter == 1) ? ar_ready_internal : 0;
assign r_data        = (calc_read_data_counter  == 1 && r_valid_internal) ? {calc_first_data, r_fifo_rdata} : 0;
assign r_valid       = (calc_read_data_counter  == 1 && r_valid_internal) ? r_valid_internal : 0;
assign r_ready       = (state != IDLE);
assign r_fifo_rinc   = !r_fifo_empty;


// this is the internal siganl which is used to help me to all operation
assign ar_addr_internal  = ar_out_data;
assign ar_valid_internal = ar_out_valid;
assign ar_ready_internal = ar_fifo_full ? 1'b0 : ar_ready_reg;
assign r_valid_internal  = fifo_read_valid[1];
assign r_ready_internal  = (state != IDLE);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_data_reg <= '{default: 0};
    end
    else if(in_valid) begin
        in_data_reg[3] <= in_data[8:0];
        for(integer i = 0; i <= 2; i = i + 1)
            in_data_reg[i] <= in_data_reg[i+1];
    end
    else if(state == LOAD_ROOT  && calc_fetch_data_counter == 1 && ar_ready_internal) begin
        for(integer i = 0; i <= 2; i = i + 1)
            in_data_reg[i] <= in_data_reg[i+1];
        in_data_reg[3] <= 9'b0;
    end
end

wire ar_handshake = ar_valid_internal && ar_ready_internal;
wire r_handshake  = r_valid_internal  && r_ready_internal;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)            calc_fetch_data_counter <= 0;
    else if(ar_handshake) calc_fetch_data_counter <= calc_fetch_data_counter + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)           calc_read_data_counter <= 0;
    else if(r_handshake) calc_read_data_counter <= calc_read_data_counter + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)           calc_first_data <= 0;
    else if(r_handshake) calc_first_data <= r_fifo_rdata;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)        input_counter <= 0;
    else if(in_valid) input_counter <= input_counter + 1;
end

// ============================================================
// busy / FSM
// ============================================================
wire   is_idle = (state == IDLE) || (state == INIT);
assign busy  = ~is_idle;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else       state <= next_state;
end

always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid)  next_state = INIT;
            else          next_state = IDLE;
        end
        INIT: begin
            if(input_counter == 3 && in_valid && in_data_reg[3][8] == 1'b0)
                next_state = LOAD_ROOT;
            else if(input_counter == 3 && in_valid && in_data_reg[3][8] == 1'b1)
                next_state = GAUSS_FETCH_DRAM1;
            else
                next_state = INIT;
        end
        LOAD_ROOT: begin
            if(ar_ready_internal && calc_fetch_data_counter) next_state = CHECK_ROOT;
            else                                    next_state = LOAD_ROOT;
        end
        CHECK_ROOT: begin
            if      (!finish_one_read)     next_state = CHECK_ROOT;
            else if (calc_first_data[31])  next_state = CHECK_STACK;
            else if (is_last_root)         next_state = IDLE;
            else                           next_state = LOAD_ROOT;
        end
        CHECK_STACK: begin
            if      (stackpointer == 0 && is_last_root) next_state = IDLE;
            else if (stackpointer == 0)                 next_state = LOAD_ROOT;
            else if (arithmeticStack[0][34])                        next_state = CALCULATE;
            else                                        next_state = SEND_L;
        end
        SEND_L: begin
            if(ar_valid_internal && ar_ready_internal && !calc_fetch_data_counter) next_state = SEND_R;
            else                                                 next_state = SEND_L;
        end
        SEND_R: begin
            if(ar_valid_internal && ar_ready_internal && !calc_fetch_data_counter) next_state = WAIT_L;
            else                                                 next_state = SEND_R;
        end
        WAIT_L: begin
            if(finish_one_read) next_state = WAIT_R;
            else                next_state = WAIT_L;
        end
        WAIT_R: begin
            if(finish_one_read) next_state = CHECK_STACK;
            else                next_state = WAIT_R;
        end
        CALCULATE: begin
            next_state = CHECK_STACK;
        end
        GAUSS_FETCH_DRAM1:begin
            if(gauss_receive_counter == 255 && r_valid_internal && r_ready_internal && finish_one_read) next_state = GAUSS_FETCH_DRAM2; 
            else next_state = GAUSS_FETCH_DRAM1;
        end
        GAUSS_FETCH_DRAM2:begin
            if(gauss_receive_counter == 255 && r_valid_internal && r_ready_internal && finish_one_read) next_state = GAUSS_FETCH_DRAM3;
            else next_state = GAUSS_FETCH_DRAM2;
        end
        GAUSS_FETCH_DRAM3:begin
            if(gauss_receive_counter == 255 && r_valid_internal && r_ready_internal && finish_one_read) next_state = GAUSS_FETCH_DRAM4;
            else next_state = GAUSS_FETCH_DRAM3;
        end
        GAUSS_FETCH_DRAM4:begin
            if(gauss_receive_counter == 255 && r_valid_internal && r_ready_internal && finish_one_read)begin
                if(gauss_iteration_counter == 2)begin
                    next_state  = IDLE;
                end
                else begin
                    next_state = GAUSS_DIV;
                end
            end 
            else next_state = GAUSS_FETCH_DRAM4;
        end
        GAUSS_DIV:begin
            if(div_done)begin
                next_state = GAUSS_FETCH_DRAM1;
            end
            else begin
                next_state = GAUSS_DIV;
            end
        end
        default: next_state = IDLE;
    endcase
end

// ============================================================
// GAUSS
// ============================================================
wire start_calculate_total  = gauss_iteration_counter == 0 && (state == GAUSS_FETCH_DRAM1 || state == GAUSS_FETCH_DRAM2 || state == GAUSS_FETCH_DRAM3 || state == GAUSS_FETCH_DRAM4);
wire start_calculate_sigma  = gauss_iteration_counter == 1 && (state == GAUSS_FETCH_DRAM1 || state == GAUSS_FETCH_DRAM2 || state == GAUSS_FETCH_DRAM3 || state == GAUSS_FETCH_DRAM4);
wire start_calculate_output = gauss_iteration_counter == 2 && (state == GAUSS_FETCH_DRAM1 || state == GAUSS_FETCH_DRAM2 || state == GAUSS_FETCH_DRAM3 || state == GAUSS_FETCH_DRAM4);

reg  [31:0] gauss_output_data;
reg         gauss_output_valid;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gauss_iteration_counter <= 0;
    end
    else if(state == IDLE)begin
        gauss_iteration_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM4 && r_valid_internal && r_ready_internal && finish_one_read && gauss_receive_counter == 255)begin
        gauss_iteration_counter <= gauss_iteration_counter + 1;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gauss_add_total <= 0;
        gauss_valid_total <= 0;
    end
    else if(state == IDLE)begin
        gauss_add_total <= 0;
        gauss_valid_total <= 0;
    end
    else if (start_calculate_total && r_valid_internal && calc_read_data_counter == 0 && r_fifo_rdata[31] == 0)begin
        gauss_add_total <= gauss_add_total + r_fifo_rdata[30:0];
        gauss_valid_total <= gauss_valid_total + 1;
    end
end

reg [31:0] gauss_average;
reg [72:0] gauss_sigma_total;
reg [72:0] gauss_sigma;

//==============================================================================
// Shared Sequential Restoring Divider (73-bit / 11-bit)
//   - 第一次觸發：算 mean   = gauss_add_total   / gauss_valid_total
//   - 第二次觸發：算 sigma² = gauss_sigma_total / gauss_valid_total
//   兩次觸發在時間上不重疊（iteration_counter == 0 vs 1），可共用同一份硬體
//==============================================================================
// --- Inputs (multiplexed) ---
reg  [72:0] div_dividend;
wire [10:0] div_divisor = gauss_valid_total;   // 兩次都一樣

// --- Start triggers ---
wire div_start_avg   = (state == GAUSS_FETCH_DRAM4)
                    && (gauss_iteration_counter == 0)
                    && (next_state == GAUSS_DIV);

wire div_start_sigma = (state == GAUSS_FETCH_DRAM4)
                    && (gauss_iteration_counter == 1)
                    && (next_state == GAUSS_DIV);

wire div_start = div_start_avg || div_start_sigma;

// --- Datapath ---
wire [72:0] trial_rem = {div_remainder[71:0], div_dividend_sr[72]};
wire        q_bit     = (trial_rem >= {62'b0, div_divisor});
wire [72:0] next_rem  = q_bit ? (trial_rem - {62'b0, div_divisor}) : trial_rem;

//------------------------------------------------------------------------------
// Restoring divider FSM
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        div_quotient    <= 73'b0;
        div_remainder   <= 73'b0;
        div_dividend_sr <= 73'b0;
        div_count       <= 7'b0;
        div_busy        <= 1'b0;
        div_done        <= 1'b0;
        div_target      <= DIV_TGT_AVG;
        div_dividend    <= 73'b0;
    end
    else if (div_start && !div_busy) begin
        // Load: 根據是哪一次觸發，選擇 dividend 和 target
        div_quotient    <= 73'b0;
        div_remainder   <= 73'b0;
        div_dividend_sr <= div_start_avg ? {32'b0, gauss_add_total}     // 41-bit pad to 73
                                         : gauss_sigma_total;            // 73-bit
        div_dividend    <= div_start_avg ? {32'b0, gauss_add_total}
                                         : gauss_sigma_total;
        div_target      <= div_start_avg ? DIV_TGT_AVG : DIV_TGT_SIGMA;
        div_count       <= 7'd73;
        div_busy        <= 1'b1;
        div_done        <= 1'b0;
    end
    else if (div_busy) begin
        if (div_count == 0) begin
            div_busy <= 1'b0;
            div_done <= 1'b1;
        end
        else begin
            div_remainder   <= next_rem;
            div_quotient    <= {div_quotient[71:0], q_bit};
            div_dividend_sr <= {div_dividend_sr[71:0], 1'b0};
            div_count       <= div_count - 1;
        end
    end
    else begin
        div_done <= 1'b0;
    end
end

//------------------------------------------------------------------------------
// Write-back: 根據 div_target 決定寫到 gauss_average 還是 gauss_sigma
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gauss_average <= 0;
        gauss_sigma   <= 0;
    end
    else if (state == IDLE) begin
        gauss_average <= 0;
        gauss_sigma   <= 0;
    end
    else if (div_done) begin
        if (div_target == DIV_TGT_AVG)
            gauss_average <= div_quotient[30:0];   // 31-bit
        else
            gauss_sigma   <= div_quotient[61:0];   // σ² 最多 62-bit
    end
end



always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gauss_sigma_total <= 0;
    end
    else if(state == IDLE)begin
        gauss_sigma_total <= 0;
    end
    else if(start_calculate_sigma && r_valid_internal && calc_read_data_counter == 0 && r_fifo_rdata[31] == 0)begin
        if(gauss_average > r_fifo_rdata[30:0])begin
            gauss_sigma_total <= gauss_sigma_total + (gauss_average - r_fifo_rdata[30:0]) * (gauss_average - r_fifo_rdata[30:0]);
        end
        else begin
            gauss_sigma_total <= gauss_sigma_total + (r_fifo_rdata[30:0] - gauss_average) * (r_fifo_rdata[30:0] - gauss_average);
        end
    end
end

wire signed [31:0] gauss_diff    = $signed({1'b0, r_fifo_rdata[30:0]}) - $signed({1'b0, gauss_average});
wire        [61:0] gauss_diff_sq = gauss_diff * gauss_diff;
wire valid_input0 = start_calculate_output && r_valid_internal && (calc_read_data_counter == 0) && (r_fifo_rdata[31] == 1'b0);
wire valid_input1 = start_calculate_output && r_valid_internal && (calc_read_data_counter == 1);
wire pass_filter = (gauss_diff_sq <= gauss_sigma);
wire gauss_last_data = (gauss_receive_counter == 255 && state == GAUSS_FETCH_DRAM4) && start_calculate_output && r_valid_internal && (calc_read_data_counter == 0);
reg remember_valid_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gauss_output_data  <= 0;
        gauss_output_valid <= 1'b0;
        remember_valid_reg <= 0;
    end
    else if(state == IDLE)begin
        gauss_output_data  <= 0;
        gauss_output_valid <= 1'b0;
        remember_valid_reg <= 0;
    end
    else if ((valid_input0 && pass_filter) || gauss_last_data) begin
        gauss_output_data  <= r_fifo_rdata;
        gauss_output_valid <= 1'b1;
        remember_valid_reg <= 1;
    end
    else if(valid_input1 && remember_valid_reg)begin
        gauss_output_valid <= 1;
        gauss_output_data  <= r_fifo_rdata;
        remember_valid_reg <= 0;
    end
    else begin
        gauss_output_data  <= 0;
        gauss_output_valid <= 1'b0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        gauss_fetch_counter <= 0;
    end
    else if(state == IDLE)begin
        gauss_fetch_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM1 && ar_valid_internal && ar_ready_internal && calc_fetch_data_counter) begin
        gauss_fetch_counter <= gauss_fetch_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM2 && ar_valid_internal && ar_ready_internal && calc_fetch_data_counter) begin
        gauss_fetch_counter <= gauss_fetch_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM3 && ar_valid_internal && ar_ready_internal && calc_fetch_data_counter) begin
        gauss_fetch_counter <= gauss_fetch_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM4 && ar_valid_internal && ar_ready_internal && calc_fetch_data_counter) begin
        gauss_fetch_counter <= gauss_fetch_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM1 && next_state == GAUSS_FETCH_DRAM2)begin
        gauss_fetch_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM2 && next_state == GAUSS_FETCH_DRAM3)begin
        gauss_fetch_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM3 && next_state == GAUSS_FETCH_DRAM4)begin
        gauss_fetch_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM4 && (next_state == GAUSS_DIV || next_state == IDLE))begin
        gauss_fetch_counter <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        gauss_receive_counter <= 0;
    end
    else if(state == IDLE)begin
        gauss_receive_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM1 && next_state == GAUSS_FETCH_DRAM2)begin
        gauss_receive_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM2 && next_state == GAUSS_FETCH_DRAM3)begin
        gauss_receive_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM3 && next_state == GAUSS_FETCH_DRAM4)begin
        gauss_receive_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM4 && (next_state == GAUSS_DIV || next_state == IDLE))begin
        gauss_receive_counter <= 0;
    end
    else if(state == GAUSS_FETCH_DRAM1 && r_valid_internal && r_ready_internal && finish_one_read)begin
        gauss_receive_counter <= gauss_receive_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM2 && r_valid_internal && r_ready_internal && finish_one_read)begin
        gauss_receive_counter <= gauss_receive_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM3 && r_valid_internal && r_ready_internal && finish_one_read)begin
        gauss_receive_counter <= gauss_receive_counter + 1;
    end
    else if(state == GAUSS_FETCH_DRAM4 && r_valid_internal && r_ready_internal && finish_one_read)begin
        gauss_receive_counter <= gauss_receive_counter + 1;
    end
end

// ============================================================
// arithmeticStack  (pop 時機改為 CALCULATE 當拍)
// ============================================================
wire is_wait_lr        = (state == WAIT_L) || (state == WAIT_R);
wire is_load_root      = (state == CHECK_ROOT) || (state == WAIT_L);  // 註: arith push 用的
wire stack_clear       = (state == LOAD_ROOT);

wire push_operator     = finish_one_read &&  calc_first_data[31];   // bit31=1 → 運算子
wire push_operand      = finish_one_read && !calc_first_data[31];   // bit31=0 → 數值

// arithmeticStack push 動作:CHECK_ROOT/WAIT_L (左) 或 WAIT_R (右)
wire arith_push_left   = (is_load_root)         && push_operator;
wire arith_push_right  = (state == WAIT_R)      && push_operator;
wire arith_push        = arith_push_left || arith_push_right;

// valueStack / value_left_right push 動作 (兩者完全同步)
wire value_push_input  = is_wait_lr && push_operand;   // 從 input 拿運算元
wire value_push_calc   = (state == CALCULATE);          // 從計算結果 push
wire value_pop_unused  = 1'b0;                          // 沒有單純 pop 的情況

// CHECK_STACK 把 top 的 mark bit 設起來
wire arith_mark_top    = (state == CHECK_STACK) && (stackpointer != 0);

// CALCULATE: arithmeticStack pop 一個
wire arith_pop         = (state == CALCULATE);

// ============================================================
// arithmeticStack
// ============================================================
// ============================================================
// arithmeticStack 的 next-value wire (用於 push / pop shift)
// ============================================================
wire [35:0] arith_push_top = {arith_push_right, 1'b0, calc_first_data[1:0], r_fifo_rdata};

always @(posedge clk or negedge rst_n) begin
    integer i;
    if(!rst_n) begin
        arithmeticStack <= '{default: 0};
        stackpointer    <= 0;
    end
    else if(stack_clear) begin
        arithmeticStack <= '{default: 0};
        stackpointer    <= 0;
    end
    else if(arith_push) begin
        arithmeticStack[0] <= arith_push_top;
        for(i = 1; i <= 12; i = i + 1)
            arithmeticStack[i] <= arithmeticStack[i-1];
        stackpointer <= stackpointer + 1;
    end
    else if(arith_mark_top) begin
        arithmeticStack[0][34] <= 1'b1;
    end
    else if(arith_pop) begin
        for(i = 0; i <= 11; i = i + 1)
            arithmeticStack[i] <= arithmeticStack[i+1];
        arithmeticStack[12] <= 0;
        stackpointer <= stackpointer - 1;
    end
end

// ============================================================
// valueStack
// ============================================================

wire signed [63:0] calc_left_value ;
wire signed [63:0] calc_right_value;

assign calc_left_value  = value_left_right[6]  ? valueStack[0][63:0] : valueStack[1][63:0];
assign calc_right_value = value_left_right[6] ? valueStack[1][63:0] : valueStack[0][63:0];


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        valueStack <= '{default: 0};
    end
    else if(stack_clear) begin
        valueStack <= '{default: 0};
    end
    else if(value_push_input) begin
        valueStack[0] <= {{33{calc_first_data[30]}}, calc_first_data[30:0]};
        for(integer i = 1; i <= 7; i = i + 1)
            valueStack[i] <= valueStack[i-1];
    end
    else if(value_push_calc) begin
        if      (arithmeticStack[0][33:32] == 2'b00) valueStack[0] <= $signed(calc_left_value) +   $signed(calc_right_value);
        else if (arithmeticStack[0][33:32] == 2'b01) valueStack[0] <= $signed(calc_left_value) -   $signed(calc_right_value);
        else if (arithmeticStack[0][33:32] == 2'b10) valueStack[0] <= $signed(calc_left_value) *   $signed(calc_right_value);
        else                                         valueStack[0] <= $signed(calc_left_value) >>> calc_right_value[5:0];
        for(integer i = 1; i <= 6; i = i + 1) valueStack[i] <= valueStack[i+1];
        valueStack[7] <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(integer i = 0; i < 8; i = i + 1) value_left_right[i] <= 1'b0;
    end
    else if(stack_clear) begin
        for(integer i = 0; i < 8; i = i + 1) value_left_right[i] <= 1'b0;
    end
    else if(value_push_input) begin
        value_left_right[7] <= (state == WAIT_R);
        for(integer i = 0; i < 7; i = i + 1) value_left_right[i] <= value_left_right[i+1];
    end
    else if(value_push_calc) begin
        value_left_right[7] <= arithmeticStack[0][35];
        for(integer i = 1; i < 7; i = i + 1) value_left_right[i] <= value_left_right[i-1];
        value_left_right[0] <= 1'b0;
    end
end



// ============================================================
// AR output
// ============================================================
reg [31:0] ar_out_data_reg;
reg ar_out_valid_reg;

always@(*)begin
    if(!ar_fifo_full)begin
        ar_out_data  = ar_out_data_reg;
        ar_out_valid = ar_out_valid_reg; 
    end
    else begin
        ar_out_data  = 0;
        ar_out_valid = 0; 
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_out_data_reg  <= 0;
        ar_out_valid_reg <= 0;
    end 
    else begin
        if(state == LOAD_ROOT && calc_fetch_data_counter == 0) begin
            ar_out_data_reg  <= {in_data_reg[0][7:0], 8'b0};
            ar_out_valid_reg <= 1;
        end
        else if(state == CHECK_STACK && arithmeticStack[0][34] == 0 && stackpointer != 0) begin
            ar_out_data_reg  <= arithmeticStack[0][31:16];
            ar_out_valid_reg <= 1;
        end
        else if(state == SEND_L) begin
            ar_out_data_reg  <= arithmeticStack[0][31:16];
            ar_out_valid_reg <= 1;
        end
        else if(state == SEND_R) begin
            ar_out_data_reg  <= arithmeticStack[0][15:0];
            ar_out_valid_reg <= 1;
        end
        // gauss fetch else address
        else if(state == GAUSS_FETCH_DRAM1 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter < 255)begin
            ar_out_valid_reg <= 1;
            ar_out_data_reg  <= ar_out_data_reg + 1;
        end
        else if(state == GAUSS_FETCH_DRAM2 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter < 255)begin
            ar_out_valid_reg <= 1;
            ar_out_data_reg  <= ar_out_data_reg + 1;
        end
        else if(state == GAUSS_FETCH_DRAM3 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter < 255)begin
            ar_out_valid_reg <= 1;
            ar_out_data_reg  <= ar_out_data_reg + 1;
        end
        else if(state == GAUSS_FETCH_DRAM4 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter < 255)begin
            ar_out_valid_reg <= 1;
            ar_out_data_reg  <= ar_out_data_reg + 1;
        end
        // gauss fetch first address
        else if(state == GAUSS_FETCH_DRAM1 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter == 255)begin
            ar_out_data_reg  <= 0;
            ar_out_valid_reg <= 0;
        end
        else if(state == GAUSS_FETCH_DRAM2 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter == 255)begin
            ar_out_data_reg  <= 0;
            ar_out_valid_reg <= 0;
        end
        else if(state == GAUSS_FETCH_DRAM3 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter == 255)begin
            ar_out_data_reg  <= 0;
            ar_out_valid_reg <= 0;
        end
        else if(state == GAUSS_FETCH_DRAM4 && calc_fetch_data_counter && ar_fifo_full == 0 && gauss_fetch_counter == 255)begin
            ar_out_data_reg  <= 0;
            ar_out_valid_reg <= 0;
        end
        // gauss fetch first address
        else if(state == GAUSS_FETCH_DRAM1 && gauss_fetch_counter == 0)begin
            ar_out_data_reg  <= {in_data_reg[0][7:0], 8'b0};
            ar_out_valid_reg <= 1;
        end
        else if(state == GAUSS_FETCH_DRAM2 && gauss_fetch_counter == 0)begin
            ar_out_data_reg  <= {in_data_reg[1][7:0], 8'b0};
            ar_out_valid_reg <= 1;
        end
        else if(state == GAUSS_FETCH_DRAM3 && gauss_fetch_counter == 0)begin
            ar_out_data_reg  <= {in_data_reg[2][7:0], 8'b0};
            ar_out_valid_reg <= 1;
        end
        else if(state == GAUSS_FETCH_DRAM4 && gauss_fetch_counter == 0)begin
            ar_out_data_reg  <= {in_data_reg[3][7:0], 8'b0};
            ar_out_valid_reg <= 1;
        end
        // gauss wait valid
        else if((state == GAUSS_FETCH_DRAM1 || state == GAUSS_FETCH_DRAM2 || state == GAUSS_FETCH_DRAM3 || state == GAUSS_FETCH_DRAM4) && gauss_fetch_counter <= 255)begin
            ar_out_valid_reg <= 1;
            ar_out_data_reg  <= ar_out_data_reg;
        end
        else begin
            ar_out_data_reg  <= 0;
            ar_out_valid_reg <= 0;
        end
    end
end

reg [31:0] calc_buffer;

wire trigger_stack = (state == CHECK_STACK) && (stackpointer == 0);
wire trigger_root  = (state == CHECK_ROOT) && finish_one_read && !calc_first_data[31];
wire trigger       = trigger_stack || trigger_root;
wire [31:0] calc_next_buffer = trigger_stack  ? valueStack[0][31:0] : {calc_first_data[30], calc_first_data[30:0]};

reg out_valid_reg;
reg [31:0] out_data_reg;
// ============================================================
// calc_mode_tree_counter
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        calc_mode_tree_counter <= 0;
    else if(trigger)
        calc_mode_tree_counter <= calc_mode_tree_counter + 1;
end

// ============================================================
// calc_buffer
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        calc_buffer <= 0;
    else if(trigger)
        calc_buffer <= calc_next_buffer;
end

// ============================================================
// calc_output_second_valid
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        calc_output_second_valid <= 0;
    else if(trigger)
        calc_output_second_valid <= 1;
    else
        calc_output_second_valid <= 0;
end

// ============================================================
// out_valid_reg
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid_reg <= 0;
    else if(trigger_stack)
        out_valid_reg <= 1;
    else if(trigger_root)
        out_valid_reg <= 1;
    else if(calc_output_second_valid)
        out_valid_reg <= 1;
    else if(gauss_output_valid)
        out_valid_reg <= 1;
    else
        out_valid_reg <= 0;
end

// ============================================================
// out_data_reg
// ============================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_data_reg <= 0;
    else if(trigger_stack)
        out_data_reg <= valueStack[0][63:32];
    else if(trigger_root)
        out_data_reg <= {32{calc_first_data[31]}};
    else if(calc_output_second_valid)
        out_data_reg <= calc_buffer;
    else if(gauss_output_valid)
        out_data_reg <= gauss_output_data;
    else
        out_data_reg <= 0;
end

always@(*)begin
    if(!out_fifo_full)begin
        out_valid = out_valid_reg;
        out_data  = out_data_reg;
    end
    else begin
        out_valid = 0;
        out_data  = 0;
    end
end
endmodule