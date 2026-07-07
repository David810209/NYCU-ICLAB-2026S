// u_input_output
module CLK_1_MODULE (
	input               clk, 
    input               rst_n,
    input               in_mode_valid,
    input       	    in_mode,
	
    input               in_valid,
    input       [1:0]   in_bank,
    input       [5:0]   in_src_row,

    output reg          out_valid,
    output reg  [63:0]  out_data,

	input out_idle,
	output reg handshake_sready,
	output reg [8:0] handshake_din,
	// You can use the the custom flag ports for your design
	input  flag_handshake_to_clk1,
	output flag_clk1_to_handshake,

	input fifo_empty,
	input [31:0] fifo_rdata,
	output fifo_rinc,
	// You can use the the custom flag ports for your design
	output flag_clk1_to_fifo,
	input flag_fifo_to_clk1

);

reg in_valid_reg;
reg in_mode_valid_reg;
reg       in_mode_reg, in_mode_r;
reg [1:0] in_bank_reg;
reg [1:0] in_bank_r [3:0];
reg [5:0] in_src_row_reg;
reg [5:0] in_src_row_r [3:0];

reg state, next_state;
localparam IDLE = 0;
localparam SEND = 1;
reg [2:0] send_cnt;
reg [2:0] in_cnt;
// read fifo
wire r_fifo_read_handshake;
reg r_fifo_valid2, r_fifo_valid3;
reg [31:0] prev_output;
reg r_fifo_flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid_reg <= 0;
        in_mode_valid_reg <= 0;
        in_mode_reg <= 0;
        in_bank_reg <= 0;
        in_src_row_reg <= 0;
    end else begin
        in_valid_reg <= in_valid;
        in_mode_valid_reg <= in_mode_valid;
        in_mode_reg <= in_mode;
        in_bank_reg <= in_bank;
        in_src_row_reg <= in_src_row;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_mode_r <= 0;
    end else if(in_mode_valid_reg) begin
        in_mode_r <= in_mode_reg;
    end
    else begin
        in_mode_r <= in_mode_r;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_cnt <= 0;
    end else if(in_mode_valid_reg || in_valid_reg) begin
        in_cnt <= in_cnt + 1;
    end
    else begin
        in_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_bank_r <= '{default: 0};
        in_src_row_r <= '{default: 0};
    end else if(in_valid_reg) begin
        in_bank_r[3] <= in_bank_reg;
        in_bank_r[2:0] <= in_bank_r[3:1];
        in_src_row_r[3] <= in_src_row_reg;
        in_src_row_r[2:0] <= in_src_row_r[3:1];
    end
    else if(handshake_sready)begin
        in_bank_r[2:0] <= in_bank_r[3:1];
        in_src_row_r[2:0] <= in_src_row_r[3:1];
        in_bank_r[3] <= 0;
        in_src_row_r[3] <= 0;
    end
    else begin
        in_bank_r <= in_bank_r;
        in_src_row_r <= in_src_row_r;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= 0;
    end 
    else begin
        state <= next_state;
    end
end
always @(*) begin
    case(state)
        IDLE: if(in_valid_reg && in_cnt == 4)
            next_state = SEND;
        else next_state = IDLE;
        SEND: if(send_cnt == 3 && handshake_sready) next_state = IDLE;
                else next_state = SEND;
        default: next_state = IDLE;
    endcase
end

always @(*) begin
    if(state == SEND)begin
        handshake_sready = out_idle;
    end
    else begin
        handshake_sready = 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        handshake_din <= 0;
    end 
    else if(handshake_sready)begin
        handshake_din <= {in_mode_r, in_bank_r[0], in_src_row_r[0]};
    end
    else begin
        handshake_din <= handshake_din;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        send_cnt <= 0;
    end 
    else if(state == SEND)begin
        if(handshake_sready) send_cnt <= send_cnt + 1;
        else send_cnt <= send_cnt;
    end
    else send_cnt <= 0;
end

// read fifo
assign fifo_rinc = !fifo_empty;
assign r_fifo_read_handshake = fifo_rinc;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_fifo_valid2 <= 0;
        r_fifo_valid3 <= 0;
    end else begin
        r_fifo_valid2 <= r_fifo_read_handshake;
        r_fifo_valid3 <= r_fifo_valid2;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        prev_output <= 0;
        r_fifo_flag <= 0;
    end else if(r_fifo_valid3) begin
        prev_output <= fifo_rdata;
        r_fifo_flag <= ~r_fifo_flag;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end else if(r_fifo_valid3 && r_fifo_flag) begin
        out_valid <= 1;
        out_data <= {prev_output, fifo_rdata};
    end
    else begin
        out_valid <= 0;
        out_data <= 0;
    end
end

endmodule

// HARVESTER
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
    // r_resp, 
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

//AR
input    	ar_fifo_full;
output reg  ar_out_valid;
output reg [31:0]    ar_out_data;
input    	ar_flag_fifo_to_wclk;
output    	ar_flag_wclk_to_fifo;

//R
input	r_fifo_empty;
input [31:0]   r_fifo_rdata;
output    r_fifo_rinc;
input    r_flag_fifo_to_rclk;
output    r_flag_rclk_to_fifo;

output   [31:0]  ar_addr;
output           ar_valid; 
output           ar_ready;
output   [63:0]  r_data;  
// input       [1:0]   r_resp; 
output        r_valid; 
output        r_ready;
// cdc signal
reg  ar_out_valid_reg;
reg [31:0]    ar_out_data_reg;
reg out_valid_reg;
reg [31:0] out_data_reg;

reg       in_mode_r;
reg [1:0] in_bank_r [3:0];
reg [5:0] in_src_row_r [3:0];
reg [1:0] input_cnt;
reg [1:0] state, next_state;
localparam  IDLE = 0;
localparam INIT = 1;
localparam CALC = 2;
localparam GAUSS = 3;
// calc
reg [1:0] curr_calc_cnt;
reg [63:0] calc_buffer;
reg calc_result_valid;
reg [2:0] calc_state, next_calc_state;
localparam CALC_IDLE = 0;
localparam CHECK_STACK = 1;
localparam SEND_LR = 2;
localparam CALCULATE = 3;
localparam CALC_LOAD_ROOT = 4;
localparam CALC_LOAD_ROOT_WAIT = 5;
localparam OUTPUT = 6;
reg [35:0] op_stack [12:0];
reg [64:0] val_stack [7:0];
reg [3:0] op_stack_ptr;
wire stack_top_mark;
wire [1:0] stack_top_op;
reg [1:0] stack_top_op_r;
wire [15:0] stack_top_l_val, stack_top_r_val;
reg [15:0] stack_top_r_val_reg;
reg stack_top_right_mark_r;
wire stack_top_right_mark;
wire val_stack_l_flag;
reg l_ar_handshake, r_ar_handshake;
reg l_rvalid_reg;
// reg l_is_value;
reg signed [63:0] calc_result, calc_result_r;
wire signed  [63:0] signed_l_val, signed_r_val;
reg signed  [63:0] signed_l_val_r, signed_r_val_r;
wire [5:0] r_shift_amt;
reg [1:0] calc_cnt;
reg [2:0] output_cnt;
// gauss
reg [2:0] gauss_state, next_gauss_state;
localparam GAUSS_IDLE = 0;
localparam ISSUE_READ = 1;
localparam READ = 2;
localparam GUASS_WAIT_OUTPUT = 3;
localparam GUASS_OUTPUT_LAST = 4;
localparam  DIV = 5;
localparam  WAIT_SQUARE = 6;
// ar
reg [1:0] gauss_stage;
reg [9:0] ar_addr_cnt;
reg [8:0] r_receive_cnt;
reg [4:0] gauss_read_cnt;
reg [10:0] valid_cnt;
reg [10:0] diff_square_sum_cnt;
reg  [40:0] sum;
reg  [31:0] mean;
reg  signed [31:0] diff;
reg diff_valid;
reg diff_square_valid;
wire filter;
reg [8:0] r_receive_cnt_r, r_receive_cnt_r_r;
reg is_last_r, is_last_r_r;
reg  signed [63:0] diff_square;
reg  [72:0] diff_square_sum;
reg  [62:0] variance;
reg [63:0] origin_data0, origin_data1;
reg output_one_more;
wire  [30:0] value;
wire div_done;
wire div_mode;
wire [72:0] div_quotient;
// read fifo 
// AXI
// ar
// process stupid double request address
reg ar_req_flag, r_resp_flag;
reg ar_delay_flag;
reg [31:0] r_last_data;
wire r_fifo_read_handshake;
reg r_fifo_valid2, r_fifo_valid3;
reg [11:0] out_cnt;
reg [11:0] out_cnt2;
// for pattern check
reg dummy_r_valid;
reg [63:0] dummy_r_data;
wire real_ar_ready;
wire real_ar_valid;
wire [31:0] real_ar_addr;
assign r_fifo_read_handshake = r_fifo_rinc;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_fifo_valid2 <= 0;
        r_fifo_valid3 <= 0;
        dummy_r_valid <= 0;
    end else begin
        r_fifo_valid2 <= r_fifo_read_handshake;
        r_fifo_valid3 <= r_fifo_valid2;
        dummy_r_valid <= (r_fifo_valid3 && r_resp_flag);
    end
end
// for pattern check
assign ar_addr = real_ar_valid && real_ar_ready ? real_ar_addr : 0;
assign ar_valid = real_ar_valid && real_ar_ready;
assign ar_ready = real_ar_valid && real_ar_ready;

assign real_ar_addr = ar_out_data;
assign real_ar_valid = ar_out_valid; 
assign real_ar_ready = ar_fifo_full ? 0 : 1;

assign r_data = r_valid == 0 ? 0 : r_fifo_valid3 && r_resp_flag ? {r_last_data, r_fifo_rdata} : dummy_r_data;
assign r_valid = (r_fifo_valid3 && r_resp_flag) || dummy_r_valid;
assign r_ready = 1;
assign r_fifo_rinc = !r_fifo_empty;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dummy_r_data <= 0;
    end else if(r_fifo_valid3 && r_resp_flag) begin
        dummy_r_data <= {r_last_data, r_fifo_rdata};
    end
    else begin
        dummy_r_data <= dummy_r_data;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_bank_r <= '{default: 0};
        in_src_row_r <= '{default: 0};
        in_mode_r <= 0;
    end else if(in_valid) begin
        in_mode_r <= in_data[8];
        in_bank_r[3] <= in_data[7:6];
        in_src_row_r[3] <= in_data[5:0];
        in_bank_r[2:0] <= in_bank_r[3:1];
        in_src_row_r[2:0] <= in_src_row_r[3:1];
    end
    else if((calc_state == CALC_LOAD_ROOT && real_ar_ready && ar_req_flag) || gauss_state == ISSUE_READ)begin
        in_mode_r <= in_mode_r;
        in_bank_r[2:0] <= in_bank_r[3:1];
        in_src_row_r[2:0] <= in_src_row_r[3:1];
        in_bank_r[3] <= in_bank_r[0];
        in_src_row_r[3] <= in_src_row_r[0];
    end
    else begin
        in_mode_r <= in_mode_r;
        in_bank_r <= in_bank_r;
        in_src_row_r <= in_src_row_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_req_flag <= 0;
    end else if(real_ar_ready && real_ar_valid) begin
        ar_req_flag <= ~ar_req_flag;
    end
    else begin
        ar_req_flag <= ar_req_flag;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_resp_flag <= 0;
    end else if(r_fifo_valid3) begin
        r_resp_flag <= ~r_resp_flag;
    end
    else begin
        r_resp_flag <= r_resp_flag;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_last_data <= 0;
    end else if(r_fifo_valid3) begin
        r_last_data <= r_fifo_rdata;
    end
    else begin
        r_last_data <= r_last_data;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        input_cnt <= 0;
    end else if(in_valid) begin
        input_cnt <= input_cnt + 1;
    end
    else begin
        input_cnt <= input_cnt;
    end
end

assign busy = !(state == IDLE || state == INIT);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always @(*) begin
    case (state)
        IDLE: begin
            if(in_valid) begin
                next_state = INIT;
            end 
            else begin
                next_state = IDLE;
            end
        end
        INIT: begin
            if(input_cnt == 3 && in_valid) begin
                if(in_mode_r == 1'b0) begin
                    next_state = CALC;
                end
                else begin
                    next_state = GAUSS;
                end
            end
            else next_state = INIT;
        end
        CALC: begin
            if(calc_state == CALC_IDLE) begin
                next_state = IDLE;
            end else begin
                next_state = CALC;
            end
        end
        GAUSS: next_state = gauss_state == GUASS_WAIT_OUTPUT ? IDLE : GAUSS;
        default: next_state = IDLE;
    endcase
end

// CALC
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        calc_state <= CALC_IDLE;
    end else begin
        calc_state <= next_calc_state;
    end
end

always @(*) begin
    case (calc_state)
        CALC_IDLE: begin
            if(state == INIT && next_state == CALC) begin
                next_calc_state = CALC_LOAD_ROOT;
            end
            else begin
                next_calc_state = CALC_IDLE;
            end
        end
        CALC_LOAD_ROOT: begin
            if(real_ar_ready && ar_req_flag) begin
                next_calc_state = CALC_LOAD_ROOT_WAIT;
            end else begin
                next_calc_state = CALC_LOAD_ROOT;
            end
        end
        CALC_LOAD_ROOT_WAIT: begin
            if(r_fifo_valid3 && r_resp_flag) begin
                if(r_last_data[31] == 0) begin
                    if(curr_calc_cnt == 3) begin
                        next_calc_state = CALC_IDLE;
                    end else begin
                        next_calc_state = CALC_LOAD_ROOT;
                    end
                end
                else begin
                    next_calc_state = CHECK_STACK;
                end
            end else begin
                next_calc_state = CALC_LOAD_ROOT_WAIT;
            end
        end
        CHECK_STACK: begin
            if(op_stack_ptr == 0) begin
                if(curr_calc_cnt == 3) begin
                    next_calc_state = CALC_IDLE;
                end else begin
                    next_calc_state = CALC_LOAD_ROOT;
                end
            end
            else if(stack_top_mark) begin
                next_calc_state = CALCULATE;
            end else begin
                next_calc_state = SEND_LR;
            end
        end
        SEND_LR: begin
            if(l_rvalid_reg && r_fifo_valid3 && r_resp_flag) begin
                next_calc_state = CHECK_STACK;
            end
            else begin
                next_calc_state = SEND_LR;
            end
        end
        CALCULATE: begin
            if(calc_cnt == 1) begin
                next_calc_state = CHECK_STACK;
            end else begin
                next_calc_state = CALCULATE;
            end
        end
        default: next_calc_state = CALC_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_stack [12:0] <= '{default: 0};
        op_stack_ptr <= 0;
    end else if((calc_state == CALC_LOAD_ROOT_WAIT ||calc_state == SEND_LR) && r_fifo_valid3 && r_resp_flag && r_last_data[31]) begin
        op_stack[0] <= {l_rvalid_reg, 1'b0, r_last_data[1:0], r_fifo_rdata};
        op_stack[12:1] <= op_stack[11:0];
        op_stack_ptr <= op_stack_ptr + 1;
    end 
    else if(calc_state == CHECK_STACK && op_stack_ptr != 0)begin
        if(stack_top_mark) begin
            op_stack_ptr <= op_stack_ptr - 1;
            op_stack[11:0] <= op_stack[12:1];
            op_stack[12] <= 0;
        end
        else begin
            op_stack_ptr <= op_stack_ptr;
            op_stack[0] <= {op_stack[0][35],1'b1, op_stack[0][33:0]};
            op_stack[12:1] <= op_stack[12:1];
        end
    end
    else begin
        op_stack_ptr <= op_stack_ptr;
        op_stack[12:0] <= op_stack[12:0];
    end
end
assign stack_top_right_mark = op_stack[0][35];
assign stack_top_mark = op_stack[0][34];
assign stack_top_op = op_stack[0][33:32];
assign stack_top_l_val = op_stack[0][31:16];
assign stack_top_r_val = op_stack[0][15:0];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        stack_top_op_r <= 0;
        stack_top_r_val_reg <= 0;
        stack_top_right_mark_r <= 0;
    end else if(calc_state == CHECK_STACK) begin
        stack_top_op_r <= stack_top_op;
        stack_top_r_val_reg <= stack_top_r_val;
        stack_top_right_mark_r <= stack_top_right_mark;
    end else begin
        stack_top_op_r <= stack_top_op_r;
        stack_top_r_val_reg <= stack_top_r_val_reg;
        stack_top_right_mark_r <= stack_top_right_mark_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        calc_result_r <= 0;
        signed_l_val_r <= 0;
        signed_r_val_r <= 0;
    end
    else begin
        calc_result_r <= calc_result;
        if(val_stack_l_flag) begin
            signed_l_val_r <= signed_r_val;
            signed_r_val_r <= signed_l_val;
        end
        else begin
            signed_l_val_r <= signed_l_val;
            signed_r_val_r <= signed_r_val;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        l_ar_handshake <= 0;
        r_ar_handshake <= 0;
    end
    else if(calc_state == SEND_LR) begin
        if(real_ar_valid && real_ar_ready && ar_req_flag) begin
            l_ar_handshake <= 1;
            r_ar_handshake <= l_ar_handshake ? 1 : 0;
        end 
        else begin
            l_ar_handshake <= l_ar_handshake;
            r_ar_handshake <= r_ar_handshake;
        end
    end
    else begin
        l_ar_handshake <= 0;
        r_ar_handshake <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        l_rvalid_reg <= 0;
        // l_is_value <= 0;
    end
    else if(calc_state == SEND_LR) begin
        if(r_fifo_valid3 && r_resp_flag) begin
            l_rvalid_reg <= 1;
            // l_is_value <= r_data[63];
        end 
        else begin
            l_rvalid_reg <= l_rvalid_reg;
            // l_is_value <= l_is_value;
        end
    end
    else begin
        l_rvalid_reg <= 0;
        // l_is_value <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        val_stack [7:0] <= '{default: 0};
    end else if(calc_state == SEND_LR && r_fifo_valid3  && r_resp_flag && r_last_data[31] == 0) begin
        val_stack[0] <= {l_rvalid_reg, {33{r_last_data[30]}}, r_last_data[30:0]};
        val_stack[7:1] <= val_stack[6:0];
    end else if((calc_state == CALCULATE && calc_cnt == 1) || (calc_state == CHECK_STACK && op_stack_ptr == 0)) begin
        val_stack[0] <= {stack_top_right_mark_r, calc_result_r};
        val_stack[6:1] <= val_stack[7:2];
        val_stack[7] <= 0;
    end
    else begin
        val_stack [7:0] <= val_stack [7:0];
    end
end
assign val_stack_l_flag = val_stack[1][64];
assign signed_l_val = val_stack[1][63:0];
assign signed_r_val = val_stack[0][63:0];

assign r_shift_amt = signed_r_val_r[5:0];
always @(*) begin
    case (stack_top_op_r)
        2'b00: calc_result = signed_l_val_r + signed_r_val_r;
        2'b01: calc_result = signed_l_val_r - signed_r_val_r;
        2'b10: calc_result = signed_l_val_r * signed_r_val_r;
        2'b11: calc_result = signed_l_val_r >>> r_shift_amt;
        default: calc_result = 0;
endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        calc_cnt <= 0;
    end 
    else if(calc_state == CALCULATE) begin
        calc_cnt <= calc_cnt + 1;
    end
    else begin
        calc_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        curr_calc_cnt <= 0;
        calc_buffer <= 0;
        calc_result_valid <= 0;
    end 
    else if(calc_state == CHECK_STACK && op_stack_ptr == 0) begin
        curr_calc_cnt <= curr_calc_cnt + 1;
        calc_buffer <= val_stack[0][63:0];
        calc_result_valid <= 1;
    end
    else if(calc_state == CALC_LOAD_ROOT_WAIT && r_fifo_valid3 && r_resp_flag && r_last_data[31] == 0) begin
        curr_calc_cnt <= curr_calc_cnt + 1;
        calc_buffer <= {{33{r_last_data[30]}}, r_last_data[30:0]};
        calc_result_valid <= 1;
    end
    else begin
        calc_result_valid <= 0;
        curr_calc_cnt <= curr_calc_cnt;
        calc_buffer <= calc_buffer;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_cnt <= 0;
    end 
    else if(calc_state == OUTPUT) begin
        output_cnt <= output_cnt + 1;
    end
    else begin
        output_cnt <= 0;
    end
end
// GAUSS mode
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gauss_state <= GAUSS_IDLE;
    end else begin
        gauss_state <= next_gauss_state;
    end
end

always @(*) begin
    case (gauss_state)
        GAUSS_IDLE: begin
            if(state == GAUSS) begin
                next_gauss_state = ISSUE_READ;
            end 
            else begin
                next_gauss_state = GAUSS_IDLE;
            end
        end
        ISSUE_READ: begin
            next_gauss_state = READ;
        end
        READ: begin
            if(r_receive_cnt == 511 && r_fifo_valid3 & r_ready && r_resp_flag) begin
                if(gauss_read_cnt == 11) next_gauss_state = GUASS_WAIT_OUTPUT;
                else if(gauss_read_cnt == 3) next_gauss_state = DIV;
                    else if(gauss_read_cnt == 7) next_gauss_state = WAIT_SQUARE;
                else next_gauss_state = ISSUE_READ;
            end else begin
                next_gauss_state = READ;
            end
        end
        WAIT_SQUARE:begin
            if(diff_square_sum_cnt == valid_cnt)begin
                next_gauss_state = DIV;
            end
            else begin
                next_gauss_state = WAIT_SQUARE;
            end
        end
        DIV:begin
            if(div_done) next_gauss_state = ISSUE_READ;
            else next_gauss_state = DIV;
        end
        GUASS_WAIT_OUTPUT:begin
            next_gauss_state = GAUSS_IDLE;
        end
        default: next_gauss_state = GAUSS_IDLE;
    endcase
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gauss_stage <= 0;
    end 
    else if(div_done) begin
        gauss_stage <= gauss_stage + 1;
    end
    else if(state == INIT)begin
        gauss_stage <= 0;
    end
    else  begin
        gauss_stage <= gauss_stage;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        gauss_read_cnt <= 0;
    end 
    else if(gauss_state == READ && r_fifo_valid3 & r_ready && r_receive_cnt == 511 && r_resp_flag) begin
        gauss_read_cnt <= gauss_read_cnt + 1;
    end
    else if(gauss_state == IDLE)begin
         gauss_read_cnt <= 0;
    end
    else  begin
        gauss_read_cnt <= gauss_read_cnt;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        diff_square_sum_cnt <= 0;
    end 
    else if(diff_square_valid)begin
        diff_square_sum_cnt <= diff_square_sum_cnt + 1;
    end
    else if(gauss_state == GAUSS_IDLE)begin
        diff_square_sum_cnt <= 0;
    end 
    else begin
        diff_square_sum_cnt <= diff_square_sum_cnt;
    end
end

assign value = r_last_data[30:0];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        valid_cnt <= 0;
        sum <= 0;
    end 
    else if(gauss_stage == 0)begin
        if(gauss_state == READ && r_fifo_valid3 & r_ready && r_resp_flag && r_last_data[31] == 0) begin
            valid_cnt <= valid_cnt + 1;
            sum <= sum + value;
        end
        else begin
            valid_cnt <= valid_cnt;
            sum <= sum;
        end
    end
    else if(gauss_state == GAUSS_IDLE)begin
        valid_cnt <= 0;
        sum <= 0;
    end 
    else begin
        valid_cnt <= valid_cnt;
        sum <= sum;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_receive_cnt_r <= 0;
    end 
    else if(gauss_stage == 1 || gauss_stage == 2)begin
        if(gauss_state == READ && r_fifo_valid3 & r_ready && r_resp_flag) begin
            r_receive_cnt_r <= r_receive_cnt;
        end
        else begin
            r_receive_cnt_r <= r_receive_cnt_r;
        end
    end
    else begin
        r_receive_cnt_r <= r_receive_cnt_r;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        diff <= 0;
        diff_valid <= 0;
        origin_data0 <= 0;
        is_last_r <= 0;
    end 
    else if(gauss_stage == 1 || gauss_stage == 2)begin
        if(gauss_state == READ && r_fifo_valid3 & r_ready && r_resp_flag && (r_last_data[31] == 0 || (r_receive_cnt == 511 && gauss_read_cnt == 11))) begin
            diff <= $signed({1'b0, value}) - $signed({1'b0, mean});
            origin_data0 <= {r_last_data, r_fifo_rdata};
            diff_valid <= 1;
            is_last_r <= (r_receive_cnt == 511 && gauss_read_cnt == 11);
        end
        else begin
            diff <= diff;
            diff_valid <= 0;
            origin_data0 <= origin_data0;
            is_last_r <= 0;
        end
    end
    else begin
        diff <= diff;
        diff_valid <= 0;
        origin_data0 <= origin_data0;
        is_last_r <= is_last_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mean <= 0;
        variance <= 0;
        diff_square <= 0;
        diff_square_valid <= 0;
        origin_data1 <= 0;
        r_receive_cnt_r_r <= 0;
        is_last_r_r <= 0;
    end 
    else  begin
        mean <= div_done && div_mode == 1 ? div_quotient[30:0] : mean;
        variance <= div_done && div_mode == 0 ? div_quotient[62:0] : variance;
        diff_square <= diff * diff;
        diff_square_valid <= diff_valid;
        origin_data1 <= origin_data0;
        r_receive_cnt_r_r <= r_receive_cnt_r;
        is_last_r_r <= is_last_r;
    end
end
assign div_mode = gauss_read_cnt  < 7 ? 1:0;
divider u_divider(
    .clk(clk),
    .rst_n(rst_n),
    .div_start(gauss_state == DIV && (div_done == 0)),
    .div_mode(div_mode),
    .gauss_add_total(sum),
    .gauss_sigma_total(diff_square_sum),
    .valid_cnt(valid_cnt),
    .div_quotient(div_quotient),
    .div_done(div_done)
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        diff_square_sum <= 0;
    end 
    else if(diff_square_valid) begin
       diff_square_sum <= diff_square_sum + diff_square;
    end
    else if(gauss_state == GAUSS_IDLE)begin
        diff_square_sum <= 0;
    end
    else begin
        diff_square_sum <= diff_square_sum;
    end
end

assign filter = diff_square <= variance || is_last_r_r;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        output_one_more <= 0;
    end 
    else if(diff_square_valid && filter && gauss_stage == 2) begin
        output_one_more <= 1;
    end
    else  begin
        output_one_more <= 0;
    end
end
// AXI

// ar
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_addr_cnt <= 0;
    end 
    else if(gauss_state == READ) begin
        if(real_ar_valid && real_ar_ready) ar_addr_cnt <= ar_addr_cnt + 1;
        else ar_addr_cnt <= ar_addr_cnt;
    end
    else begin
        ar_addr_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_delay_flag <= 0;
    end 
    else if(real_ar_valid && real_ar_ready) ar_delay_flag <= 1;
    else  begin
        ar_delay_flag <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_receive_cnt <= 0;
    end 
    else if(gauss_state == READ) begin
        if(r_fifo_valid3 && r_ready) r_receive_cnt <= r_receive_cnt + 1; 
        else r_receive_cnt <= r_receive_cnt;
    end
    else  begin
        r_receive_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_out_data_reg <= 0;
        ar_out_valid_reg <= 0;
    end 
    else if((calc_state == CALC_LOAD_ROOT && ar_req_flag == 0)
                || (gauss_state == ISSUE_READ)) begin
        ar_out_data_reg <= {in_bank_r[0], in_src_row_r[0], 8'b0};
        ar_out_valid_reg <= 1;
    end
    else if(gauss_state == READ && ar_addr_cnt <= 511 && !(ar_addr_cnt == 511 && real_ar_valid && real_ar_ready && ar_req_flag))begin
        if(gauss_read_cnt >= 8) begin
            ar_out_valid_reg <= ar_delay_flag == 1 ? 0 : 1;
        end
        else  ar_out_valid_reg <= 1;
        if(real_ar_ready && real_ar_valid && ar_req_flag) ar_out_data_reg <= ar_out_data_reg + 1;
        else ar_out_data_reg <= ar_out_data_reg;
    end
    else if(calc_state == CHECK_STACK && stack_top_mark == 0 && op_stack_ptr != 0) begin
        ar_out_data_reg <= stack_top_l_val;
        ar_out_valid_reg <= 1;
    end
    else if(calc_state == SEND_LR && !(l_ar_handshake && ((real_ar_ready && ar_req_flag) || r_ar_handshake))) begin
        ar_out_data_reg <= (l_ar_handshake || (real_ar_ready && ar_req_flag)) ? stack_top_r_val_reg : real_ar_addr;
        ar_out_valid_reg <= 1;
    end
    else begin
        ar_out_data_reg <= 0;
        ar_out_valid_reg <= 0;
    end
end
always @(*)begin
    ar_out_data = ar_fifo_full ? 0 : ar_out_data_reg;
    ar_out_valid = ar_fifo_full ? 0 : ar_out_valid_reg;
end

// out data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid_reg <= 0;
        out_data_reg <= 0;
    end 
    else if(calc_state == CHECK_STACK && op_stack_ptr == 0) begin
        out_valid_reg <= 1;
        out_data_reg <= val_stack[0][63:32];
    end
    else if(calc_state == CALC_LOAD_ROOT_WAIT && r_fifo_valid3 && r_resp_flag && r_last_data[31] == 0) begin
        out_valid_reg <= 1;
        out_data_reg <= {32{r_last_data[30]}};
    end
    else if(calc_result_valid)begin
        out_valid_reg <= 1;
        out_data_reg <= calc_buffer[31:0];
    end
    else if(diff_square_valid && filter && gauss_stage == 2)begin
        out_valid_reg <= 1;
        out_data_reg <= origin_data1[63:32];
    end
    else if(output_one_more)begin
        out_valid_reg <= 1;
        out_data_reg <= origin_data1[31:0];
    end
    else begin
        out_valid_reg <= 0;
        out_data_reg <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_cnt <= 0;
    end 
    else if(out_valid_reg)begin
        out_cnt <= out_cnt + 1;
    end
    else if(in_valid)begin
        out_cnt <= 0;
    end
    else begin
        out_cnt <= out_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_cnt2 <= 0;
    end 
    else if(out_valid)begin
        out_cnt2 <= out_cnt2 + 1;
    end
    else if(in_valid)begin
        out_cnt2 <= 0;
    end
    else begin
        out_cnt2 <= out_cnt2;
    end
end
always @(*)begin
    if(out_fifo_full)begin
        out_valid = 0;
        out_data = 0;
    end
    else begin
        out_valid = out_valid_reg;
        out_data = out_data_reg;
    end
end
endmodule
module divider (
    input               clk,
    input               rst_n,

    input               div_start,
    input               div_mode,        // 1: mean (sum/N), 0: variance (sumSq/N)

    input  signed [40:0] gauss_add_total,
    input  signed [72:0] gauss_sigma_total,
    input         [10:0] valid_cnt,

    output reg                 div_done,
    output reg signed  [72:0]  div_quotient
);

localparam TGT_MEAN = 1'b0;
localparam TGT_VAR  = 1'b1;

reg  [72:0] rem_r;
reg  [72:0] dividend_sr_r;
reg  [6:0]  iter_cnt_r;
reg         busy_r;
reg         target_r;

// --- Datapath (combinational) ---
wire [10:0] divisor   = valid_cnt;
wire [72:0] trial_rem = {rem_r[71:0], dividend_sr_r[72]};
wire        q_bit     = (trial_rem >= {62'b0, divisor});
wire [72:0] next_rem  = q_bit ? (trial_rem - {62'b0, divisor}) : trial_rem;

// --- Control: busy / done / iter_cnt ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy_r     <= 1'b0;
        div_done   <= 1'b0;
        iter_cnt_r <= 7'b0;
    end
    else if (div_start && !busy_r) begin
        busy_r     <= 1'b1;
        div_done   <= 1'b0;
        iter_cnt_r <= 7'd73;
    end
    else if (busy_r && iter_cnt_r == 0) begin
        busy_r     <= 1'b0;
        div_done   <= 1'b1;
        iter_cnt_r <= iter_cnt_r;
    end
    else if (busy_r) begin
        busy_r     <= busy_r;
        div_done   <= div_done;
        iter_cnt_r <= iter_cnt_r - 1;
    end
    else begin
        busy_r     <= busy_r;
        div_done   <= 1'b0;
        iter_cnt_r <= iter_cnt_r;
    end
end

// --- Datapath: dividend_sr / rem / quotient ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dividend_sr_r <= 73'b0;
        rem_r         <= 73'b0;
        div_quotient  <= 73'b0;
    end
    else if (div_start && !busy_r) begin
        dividend_sr_r <= div_mode ? {32'b0, gauss_add_total}
                                  : gauss_sigma_total;
        rem_r         <= 73'b0;
        div_quotient  <= 73'b0;
    end
    else if (busy_r && iter_cnt_r != 0) begin
        dividend_sr_r <= {dividend_sr_r[71:0], 1'b0};
        rem_r         <= next_rem;
        div_quotient  <= {div_quotient[71:0], q_bit};
    end
    else begin
        dividend_sr_r <= dividend_sr_r;
        rem_r         <= rem_r;
        div_quotient  <= div_quotient;
    end
end

// --- Configuration tag ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        target_r <= TGT_MEAN;
    end
    else if (div_start && !busy_r) begin
        target_r <= div_mode ? TGT_MEAN : TGT_VAR;
    end
    else begin
        target_r <= target_r;
    end
end

endmodule
// DRAM_CTRL
module CLK_3_MODULE (
    clk,
    rst_n,
    
    r_fifo_full,
    r_out_valid,
    r_out_data,

	ar_fifo_empty,
    ar_fifo_rdata,
    ar_fifo_rinc,

    ar_flag_fifo_to_rclk,
    ar_flag_rclk_to_fifo,

	r_flag_fifo_to_wclk,
    r_flag_wclk_to_fifo,

	ar_addr, 
    ar_valid, 
    ar_ready,
    r_data,  
    // r_resp, 
    r_valid, 
    r_ready,

	dram_cmd,  // {CS_n, RAS_n, CAS_n, WE_n}
    dram_ba,
    dram_addr,
    dram_wdata,
    dram_rdata,
    dram_valid
);
input 			clk;
input 			rst_n;

input  		ar_fifo_empty;
output  		ar_fifo_rinc;
input [31:0] 	ar_fifo_rdata;

input 			r_fifo_full;
output reg 		r_out_valid;
output reg [31:0] r_out_data;
// You can use the the custom flag ports for your design
input  			ar_flag_fifo_to_rclk,r_flag_fifo_to_wclk;
output 			ar_flag_rclk_to_fifo,r_flag_wclk_to_fifo;


output [31:0] ar_addr;
output        ar_valid;
output    ar_ready;
output reg[63:0] r_data;
output  reg      r_valid;
output reg    r_ready;

output reg  [3:0]  dram_cmd;  // {CS_n, RAS_n, CAS_n, WE_n}
output reg  [1:0]  dram_ba;
output reg  [10:0] dram_addr;
output reg  [63:0] dram_wdata;
input [63:0] dram_rdata;
input        dram_valid;
// cdc singal

reg 		r_out_valid_reg;
reg [31:0] r_out_data_reg;

reg [1:0] last_bank;
reg [5:0] last_row [0:3];
reg activated [0:3];
reg [1:0] precharge_cnt;
reg [1:0] act_cnt;
reg [1:0] state, next_state;
localparam  IDLE = 0;
localparam  ACT = 1;
localparam PRECHARGE =2; 
localparam INIT = 3;
reg [15:0] addr_fifo [7:0];
reg [2:0] r_ptr, w_ptr;
wire addr_fifo_full;
wire addr_fifo_empty;
wire raddr_r_en;
wire access_the_same_row [0:3];
wire [1:0] bank_sel;
wire [5:0] row_sel;
wire [1:0] addr_reg_bank;
wire [5:0] addr_reg_row;
wire [7:0] addr_reg_col;
reg r_resp_flag;

reg [1:0] read_fifo_cnt;
reg [1:0] read_fifo_cnt2;
reg r_fifo_valid2, r_fifo_valid3;
reg [31:0] read_fifo_buffer [1:0];
wire ar_handshake;
wire [31:0] ar_addr_sel;
wire real_ar_valid;
wire real_ar_ready;
// for pattern check
reg dummy_r_valid;
reg [63:0] dummy_r_data;

// assign r_data = r_valid == 0 ? 0 :  (dram_valid && r_resp_flag) ? dram_rdata : dummy_r_data;
// assign r_valid = (dram_valid && r_resp_flag) || dummy_r_valid ;
// assign r_ready = (dram_valid && r_resp_flag) || dummy_r_valid ;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_data <= 0;
        r_valid <= 0;
        r_ready <= 0;
    end 
    else begin
        r_data <= (dram_valid && r_resp_flag) || dummy_r_valid ? ((dram_valid && r_resp_flag) ? dram_rdata : dummy_r_data) : 0;
        r_valid <= (dram_valid && r_resp_flag) || dummy_r_valid ;
        r_ready <= (dram_valid && r_resp_flag) || dummy_r_valid ;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dummy_r_valid <= 0;
    end 
    else if(dram_valid && r_resp_flag) begin
        dummy_r_valid <= 1;
    end
    else begin
        dummy_r_valid <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dummy_r_data <= 0;
    end 
    else if(dram_valid) begin
        dummy_r_data <= dram_rdata;
    end
    else begin
        dummy_r_data <= 0;
    end
end
// read fifo
assign ar_handshake = real_ar_ready && real_ar_valid;
assign ar_fifo_rinc = (read_fifo_cnt < 2 || ar_handshake) && !ar_fifo_empty;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_fifo_valid2 <= 0;
        r_fifo_valid3 <= 0;
    end else begin
        r_fifo_valid2 <= ar_fifo_rinc;
        r_fifo_valid3 <= r_fifo_valid2;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_fifo_cnt <= 0;
    end 
    else if(ar_fifo_rinc) begin
        if(ar_handshake)read_fifo_cnt <= read_fifo_cnt;
        else read_fifo_cnt <= read_fifo_cnt + 1;
    end
    else if(ar_handshake) read_fifo_cnt <= read_fifo_cnt - 1;
    else read_fifo_cnt <= read_fifo_cnt;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_fifo_buffer <= '{default: 0};
    end 
    else if(r_fifo_valid3) begin
        read_fifo_buffer[1] <= ar_fifo_rdata;
        read_fifo_buffer[0] <= read_fifo_buffer[1];
    end
    else begin
        read_fifo_buffer <= read_fifo_buffer;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_fifo_cnt2 <= 0;
    end 
    else if(r_fifo_valid3) begin
        if(ar_handshake) read_fifo_cnt2 <= read_fifo_cnt2;
        else read_fifo_cnt2 <= read_fifo_cnt2 + 1;
    end
    else if(ar_handshake) read_fifo_cnt2 <= read_fifo_cnt2 - 1;
    else read_fifo_cnt2 <= read_fifo_cnt2;
end

assign ar_valid = ar_handshake;
assign ar_ready = ar_handshake;
assign real_ar_valid = read_fifo_cnt2 > 0 || r_fifo_valid3;
assign ar_addr = ar_handshake ? ar_addr_sel : 0;
assign ar_addr_sel = read_fifo_cnt2 == 1 ? read_fifo_buffer[1] 
                    : read_fifo_cnt2 == 2 ? read_fifo_buffer[0] 
                    : r_fifo_valid3 ? ar_fifo_rdata : 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_fifo <= '{default:0};
        w_ptr <= 0;
    end 
    else if(ar_handshake)begin
        addr_fifo[w_ptr] <= ar_addr_sel;
        w_ptr <= w_ptr + 1;
    end
    else begin
        addr_fifo <= addr_fifo;
        w_ptr <= w_ptr;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_ptr <= 0;
    end 
    else if(raddr_r_en)begin
        r_ptr <= r_ptr + 1;
    end
    else begin
        r_ptr <= r_ptr;
    end
end
assign addr_fifo_empty = r_ptr == w_ptr;
assign addr_fifo_full = w_ptr + 1 == r_ptr || (w_ptr == 7 && r_ptr == 0);
// AXI
assign real_ar_ready = ~(state == INIT || addr_fifo_full);

assign addr_reg_bank = addr_fifo[r_ptr][15:14];
assign addr_reg_row = addr_fifo[r_ptr][13:8];
assign addr_reg_col = addr_fifo[r_ptr][7:0];
assign bank_sel = addr_reg_bank;
assign row_sel = addr_reg_row;
assign raddr_r_en = state == IDLE && activated[addr_reg_bank] && last_row[addr_reg_bank] == addr_reg_row && !addr_fifo_empty;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT;
    end else begin
        state <= next_state;
    end
end
always @(*) begin
    case (state)
        INIT: begin
            next_state = IDLE;
        end
        IDLE: begin
            if(!addr_fifo_empty) begin
                if(raddr_r_en) next_state = IDLE;
                else next_state = PRECHARGE;
            end
            else begin
                next_state = IDLE;
            end
        end
        PRECHARGE: begin
            if(precharge_cnt == 3) begin
                next_state = ACT;
            end
            else begin
                next_state = PRECHARGE;
            end
        end
        ACT: begin
            if(act_cnt == 1) begin
                next_state = IDLE;
            end
            else begin
                next_state = ACT;
            end
        end
        default: next_state = IDLE;
    endcase
end

// r resp
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_resp_flag <= 0;
    end 
    else if(dram_valid) begin
        r_resp_flag <= ~r_resp_flag;
    end
    else begin
        r_resp_flag <= r_resp_flag;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_out_valid_reg <= 0;
        r_out_data_reg <= 0;
    end 
    else if(dram_valid) begin
        r_out_valid_reg <= 1;
        r_out_data_reg <= r_resp_flag ? dram_rdata[31:0] : dram_rdata[63:32];
    end
    else begin
        r_out_valid_reg <= 0;
        r_out_data_reg <= 0;
    end
end

always @(*) begin
    if(r_fifo_full) begin
        r_out_valid = 0;
        r_out_data = 0;
    end 
    else begin
        r_out_valid = r_out_valid_reg;
        r_out_data = r_out_data_reg;
    end
end

// DRAM CTRL

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_cnt <= 0;
    end
    else if(state == ACT) begin
        act_cnt <= act_cnt + 1;
    end
    else begin
        act_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        precharge_cnt <= 0;
    end
    else if(state == PRECHARGE) begin
        precharge_cnt <= precharge_cnt + 1;
    end
    else begin
        precharge_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        activated[0]   <= 0;
        activated[1]   <= 0;
        activated[2]   <= 0;
        activated[3]   <= 0;
    end
    else if(state == ACT) begin
        for(integer i = 0; i < 4; i = i + 1) begin
            if(i == bank_sel) begin
                activated[i] <= 1;
            end
            else activated[i] <= activated[i];
        end
    end
    else if(state == PRECHARGE) begin
        for(integer i = 0; i < 4; i = i + 1) begin
            if(i == bank_sel) begin
                activated[i] <= 1;
            end
            else activated[i] <= activated[i];
        end
    end
    else begin
        activated[0] <= activated[0];
        activated[1] <= activated[1];
        activated[2] <= activated[2];
        activated[3] <= activated[3];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        last_bank <= 0;
        last_row[0] <= 0;
        last_row[1] <= 0;
        last_row[2] <= 0;
        last_row[3] <= 0;
    end
    else if(state == ACT) begin
        last_bank <= bank_sel;
        for(integer i = 0; i < 4; i = i + 1) begin
            if(i == bank_sel) begin
                last_row[i] <= row_sel;
            end
            else last_row[i] <= last_row[i];
        end
    end
    else begin
        last_row[0] <= last_row[0];
        last_row[1] <= last_row[1];
        last_row[2] <= last_row[2];
        last_row[3] <= last_row[3];
        last_bank <= last_bank;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dram_cmd <= 4'b0111; // NOP
        dram_ba <= 0;
        dram_addr <= 0;
        dram_wdata <= 0;
    end
    // ACT
    else if(state == PRECHARGE && precharge_cnt == 3) begin
        dram_cmd <= 4'b0011;
        dram_ba <= addr_reg_bank;
        dram_addr <= addr_reg_row;
        dram_wdata <= 0;
    end
    // READ
    else if(raddr_r_en) begin
        dram_cmd <= 4'b0101;
        dram_ba <= addr_reg_bank;
        dram_addr <= addr_reg_col;
        dram_wdata <= 0;
    end
    // PRECHARGE
    else if(state != PRECHARGE && next_state == PRECHARGE) begin
        dram_cmd <= 4'b0010;
        dram_ba <= addr_reg_bank;
        dram_addr <= 0;
        dram_wdata <= 0;
    end
    else begin
        dram_cmd <= 4'b0111; // NOP
        dram_ba <= 0;
        dram_addr <= 0;
        dram_wdata <= 0;
    end
end

endmodule









































