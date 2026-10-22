module HARVESTER(
    input               clk, 
    input               rst_n,
    input               in_mode_valid,
    input               in_valid,
    input       [1:0]   in_mode,
    input       [1:0]   in_bank,
    input       [5:0]   in_src_row,
    input       [5:0]   in_dst_row,
    input       [63:0]  in_data,
    output reg          out_valid,
    output reg  [63:0]  out_data,
    
    output reg  [31:0]  aw_addr, 
    output reg          aw_valid, 
    input               aw_ready,
    output reg  [63:0]  w_data,  
    output reg          w_valid,  
    input               w_ready,
    input       [1:0]   b_resp,  
    input               b_valid,  
    output reg          b_ready,
    output reg  [31:0]  ar_addr, 
    output reg          ar_valid, 
    input               ar_ready,
    input       [63:0]  r_data,  
    input       [1:0]   r_resp, 
    input wire          r_valid, 
    output reg          r_ready
);

reg [3:0] state, next_state;
localparam  IDLE = 0;
localparam INIT = 1;
localparam READ = 2;
localparam WRITE = 3;
localparam CALC = 4;
localparam SORT = 5;
localparam SORT_READ = 6;
localparam SORT_WRITE = 7;
localparam SORT_L2 = 8;
reg in_valid_reg;
reg in_mode_valid_reg;
reg [1:0] in_mode_reg, in_mode_r;
reg [1:0] in_bank_reg, in_bank_r;
reg [5:0] in_src_row_reg, in_src_row_r;
reg [5:0] in_dst_row_reg, in_dst_row_r;
reg [63:0] in_data_reg;
reg [63:0] in_data_r [6:0];
// calc
reg [1:0] curr_calc_cnt;
reg [63:0] calc_buffer [3:0];
reg [2:0] calc_state, next_calc_state;
localparam CALC_IDLE = 0;
localparam CHECK_STACK = 1;
localparam SEND_LR = 2;
localparam CALCULATE = 3;
localparam CALC_LOAD_ROOT = 4;
localparam CALC_LOAD_ROOT_WAIT = 5;
localparam OUTPUT = 6;
reg [35:0] op_stack [127:0];
reg [64:0] val_stack [127:0];
reg [6:0] op_stack_ptr;
reg [6:0] val_stack_ptr;
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

// sorting
reg [3:0] sort_state, next_sort_state;
reg [63:0] sort_buffer [255:0];
reg [7:0] sort_cnt;
reg [1:0] L1_sort_cnt;
localparam SORT_IDLE = 0;
localparam SORTING = 1;
localparam READ_R0 = 2;
localparam CMP = 3;
localparam SORT_ISSUE_WRITE = 4;
localparam SORT_WAIT_WRITE = 5;
localparam SORT_SORT_DONE = 6;
localparam ISSUE_READ_R0 = 7;
localparam WAIT_DATA = 8;
reg [4:0] b_req_cnt [3:0];
wire [1:0] b0123_cmp;
reg [7:0] cmp_cnt;
reg [63:0] b0_buffer [15:0];
reg [63:0] b1_buffer [15:0];
reg [63:0] b2_buffer [15:0];
reg [63:0] b3_buffer [15:0];
wire [63:0] b0_buffer_head, b1_buffer_head, b2_buffer_head, b3_buffer_head;
wire [31:0] b0_buffer_head_value, b1_buffer_head_value, b2_buffer_head_value, b3_buffer_head_value;
reg [3:0] fetch_cnt [3:0];
reg [3:0] sort_r_issue_cnt;
reg [3:0] sort_r_receive_cnt;
reg [2:0] issue_r0_cnt, receive_b0_cnt;
reg [1:0] next_fetch_bank;
reg [7:0] next_fetch_col;
reg [7:0] b_next_fetch_col [3:0];
reg [1:0] receive_r0_cnt;
reg [1:0] bank_in_sel;
reg bank_legal_empty [3:0];
reg  bank_empty;
reg [1:0] empty_bank;
wire b01_cmp, b23_cmp;
wire [30:0] min0, min1;
wire [1:0] min0_bank, min1_bank;
// AXI
// ar
reg [8:0] ar_addr_cnt;
reg [7:0] r_receive_cnt;
// aw
reg [7:0] aw_addr_cnt, w_receive_cnt;
reg [2:0] aw_valid_pending;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_valid_reg <= 0;
        in_mode_valid_reg <= 0;
        in_mode_reg <= 0;
        in_bank_reg <= 0;
        in_src_row_reg <= 0;
        in_dst_row_reg <= 0;
        in_data_reg <= 0;
    end else begin
        in_valid_reg <= in_valid;
        in_mode_valid_reg <= in_mode_valid;
        in_mode_reg <= in_mode;
        in_bank_reg <= in_bank;
        in_src_row_reg <= in_src_row;
        in_dst_row_reg <= in_dst_row;
        in_data_reg <= in_data;
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
        in_bank_r <= 0;
        in_src_row_r <= 0;
        in_dst_row_r <= 0;
    end else if(in_valid_reg) begin
        in_bank_r <= in_bank_reg;
        in_src_row_r <= in_src_row_reg;
        in_dst_row_r <= in_dst_row_reg;
    end
    else begin
        in_bank_r <= in_bank_r;
        in_src_row_r <= in_src_row_r;
        in_dst_row_r <= in_dst_row_r;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_data_r [6:0] <= '{default: 0};
    end else  begin
        in_data_r[0] <= in_valid_reg ? in_data_reg :
                    sort_buffer[0];
        in_data_r [6:1] <= in_data_r [5:0];
    end
end

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
            if(in_mode_valid_reg) begin
                next_state = INIT;
            end else begin
                next_state = IDLE;
            end
        end
        INIT: begin
            if(in_mode_r == 2'd0) begin
                next_state = READ;
            end 
            else if(in_mode_r == 2'd1) begin
                next_state = WRITE;
            end 
            else if(in_mode_r == 2'd2) begin
                next_state = CALC;
            end  
            else  begin
                next_state = SORT_READ;
            end 
        end
        READ: begin
            if(r_receive_cnt == 255) begin
                if(in_mode_r == 3) begin
                    next_state = SORT;
                end
                else begin
                    next_state = IDLE;
                end
            end else begin
                next_state = READ;
            end
        end
        WRITE: begin
            if(w_receive_cnt == 255) begin
                if(in_mode_r == 3) begin
                    if(sort_state == SORT_WAIT_WRITE) begin
                        next_state = SORT_L2;
                    end
                    else if(L1_sort_cnt == 3) begin
                        next_state = SORT_L2;
                    end else begin
                        next_state = SORT_READ;
                    end
                end
                else begin
                    next_state = IDLE;
                end
            end else begin
                next_state = WRITE;
            end
        end
        CALC: begin
            if(calc_state == OUTPUT) begin
                next_state = IDLE;
            end else begin
                next_state = CALC;
            end
        end
        SORT_READ:begin
            next_state = READ;
        end
        SORT: begin
            if(sort_cnt == 255)begin
                next_state = SORT_WRITE;
            end else begin
                next_state = SORT;
            end
        end
        SORT_WRITE: begin
            next_state = WRITE;
        end
        SORT_L2: begin
            if(sort_state == SORT_SORT_DONE) begin
                next_state = IDLE;
            end 
            else if(sort_state == SORT_ISSUE_WRITE) begin
                next_state = WRITE;
            end
            else begin
                next_state = SORT_L2;
            end
        end
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
            if(state == INIT && in_mode_r == 2'd2) begin
                next_calc_state = CALC_LOAD_ROOT;
            end
            else begin
                next_calc_state = CALC_IDLE;
            end
        end
        CALC_LOAD_ROOT: begin
            if(ar_ready) begin
                next_calc_state = CALC_LOAD_ROOT_WAIT;
            end else begin
                next_calc_state = CALC_LOAD_ROOT;
            end
        end
        CALC_LOAD_ROOT_WAIT: begin
            if(r_valid) begin
                if(r_data[63] == 0) begin
                    if(curr_calc_cnt == 3) begin
                        next_calc_state = OUTPUT;
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
                    next_calc_state = OUTPUT;
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
            if(l_rvalid_reg && r_valid) begin
                // if(l_is_value && r_data[63]) begin
                //     next_calc_state = CALCULATE;
                // end
                // else begin
                    next_calc_state = CHECK_STACK;
                // end
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
        OUTPUT: begin
            if(output_cnt == 3) begin
                next_calc_state = IDLE;
            end else begin
                next_calc_state = OUTPUT;
            end
        end
        default: next_calc_state = CALC_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        op_stack [127:0] <= '{default: 0};
        op_stack_ptr <= 0;
    end else if((calc_state == CALC_LOAD_ROOT_WAIT ||calc_state == SEND_LR) && r_valid && r_data[63]) begin
        op_stack[0] <= {l_rvalid_reg, 1'b0, r_data[33:0]};
        op_stack[127:1] <= op_stack[126:0];
        op_stack_ptr <= op_stack_ptr + 1;
    end 
    // else if(calc_state == SEND_LR && next_calc_state == CALCULATE) begin
    //     op_stack_ptr <= op_stack_ptr - 1;
    //     op_stack[126:0] <= op_stack[127:1];
    //     op_stack[127] <= 0;
    // end
    else if(calc_state == CHECK_STACK && op_stack_ptr != 0)begin
        if(stack_top_mark) begin
            op_stack_ptr <= op_stack_ptr - 1;
            op_stack[126:0] <= op_stack[127:1];
            op_stack[127] <= 0;
        end
        else begin
            op_stack_ptr <= op_stack_ptr;
            op_stack[0] <= {op_stack[0][35],1'b1, op_stack[0][33:0]};
            op_stack[127:1] <= op_stack[127:1];
        end
    end
    else begin
        op_stack_ptr <= op_stack_ptr;
        op_stack[127:0] <= op_stack[127:0];
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
        if(ar_valid && ar_ready) begin
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
        if(r_valid) begin
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
        val_stack [127:0] <= '{default: 0};
        val_stack_ptr <= 0;
    end else if(calc_state == SEND_LR && r_valid && r_data[63] == 0) begin
        val_stack[0] <= {l_rvalid_reg, {33{r_data[62]}}, r_data[62:32]};
        val_stack[127:1] <= val_stack[126:0];
        val_stack_ptr <= val_stack_ptr + 1;
    end else if((calc_state == CALCULATE && calc_cnt == 1) || (calc_state == CHECK_STACK && op_stack_ptr == 0)) begin
        val_stack_ptr <= val_stack_ptr - 1;
        val_stack[0] <= {stack_top_right_mark_r, calc_result_r};
        val_stack[126:1] <= val_stack[127:2];
        val_stack[127] <= 0;
    end
    else begin
        val_stack [127:0] <= val_stack [127:0];
        val_stack_ptr <= val_stack_ptr;
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
        calc_buffer [3:0] <= '{default: 0};
    end 
    else if(calc_state == CHECK_STACK && op_stack_ptr == 0) begin
        curr_calc_cnt <= curr_calc_cnt + 1;
        calc_buffer[3] <= val_stack[0];
        calc_buffer[2:0] <= calc_buffer[3:1];
    end
    else if(calc_state == CALC_LOAD_ROOT_WAIT && r_valid && r_data[63] == 0) begin
        curr_calc_cnt <= curr_calc_cnt + 1;
        calc_buffer[3] <={{33{r_data[62]}}, r_data[62:32]};
        calc_buffer[2:0] <= calc_buffer[3:1];
    end
    else begin
        curr_calc_cnt <= curr_calc_cnt;
        calc_buffer [3:0] <= calc_buffer [3:0];
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

// sorting
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sort_state <= 0;
    end else begin
        sort_state <= next_sort_state;
    end
end

always @(*) begin
    case (sort_state)
        SORT_IDLE: begin
            if(state == SORT_L2) begin
                next_sort_state = ISSUE_READ_R0;
            end
            else if(in_mode_r == 3 && state == READ && r_receive_cnt == 255) begin
                next_sort_state = SORTING;
            end  
            else begin
                next_sort_state = SORT_IDLE;
            end
        end
        SORTING: begin
            if(sort_cnt == 255) begin
                next_sort_state = SORT_IDLE;
            end else begin
                next_sort_state = SORTING;
            end
        end
        ISSUE_READ_R0: begin
            next_sort_state = READ_R0;
        end
        READ_R0: begin
            if(sort_r_issue_cnt == 14) begin
                if(issue_r0_cnt[2] == 0) begin
                    next_sort_state = ISSUE_READ_R0;
                end
                else next_sort_state = WAIT_DATA;
            end 
            else begin
                next_sort_state = READ_R0;
            end
        end
        WAIT_DATA:begin
            if(sort_r_receive_cnt == 15) begin
                next_sort_state = CMP;
            end
            else begin
                next_sort_state = WAIT_DATA;
            end
        end
        CMP: begin
            if(cmp_cnt == 255) begin
                next_sort_state = SORT_ISSUE_WRITE;
            end
            else if(bank_empty) begin
                next_sort_state = ISSUE_READ_R0;
            end
            else begin
                next_sort_state = CMP;
            end
        end
        SORT_ISSUE_WRITE: begin
            next_sort_state = SORT_WAIT_WRITE;
        end
        SORT_WAIT_WRITE: begin
            if(w_receive_cnt == 255) begin
                if(L1_sort_cnt == 3) begin
                    next_sort_state = SORT_SORT_DONE;
                end 
                else begin
                     if(bank_empty) begin
                        next_sort_state = ISSUE_READ_R0;
                    end
                    else next_sort_state = CMP;
                end
            end else begin
                next_sort_state = SORT_WAIT_WRITE;
            end
        end
        SORT_SORT_DONE: begin
            next_sort_state = SORT_IDLE;
        end
        default: next_sort_state = SORT_IDLE;
endcase
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sort_cnt <= 0;
    end
    else if(sort_state == SORTING) begin
        sort_cnt <= sort_cnt + 1;
    end
    else begin
        sort_cnt <= 0;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sort_buffer [255:0] <= '{default: 0};
    end
    else if(state == READ && r_valid && in_mode_r == 3 && sort_state != READ_R0) begin
        sort_buffer[255] <= r_data;
        sort_buffer[254:0] <= sort_buffer[255:1];
    end
    else if((state == SORT_WRITE || (state == WRITE && in_mode_r == 3))
    || (sort_state == SORT_ISSUE_WRITE || sort_state == SORT_WAIT_WRITE)) begin
        sort_buffer[255] <= 0;
        sort_buffer[254:0] <= sort_buffer[255:1];
    end
    else if(sort_state == SORTING) begin
        if(sort_cnt[0] == 0) begin
            sort_buffer[0] <= sort_buffer[0];
            for(integer i = 1; i < 255;i = i + 2) begin
                if(sort_buffer[i][62:32] > sort_buffer[i+1][62:32]) begin
                    {sort_buffer[i], sort_buffer[i+1]} <= {sort_buffer[i+1], sort_buffer[i]};
                end
                else begin
                    sort_buffer[i] <= sort_buffer[i];
                    sort_buffer[i+1] <= sort_buffer[i+1];
                end
            end
        end
        else begin
            for(integer i = 0; i < 255;i = i + 2) begin
                if(sort_buffer[i][62:32] > sort_buffer[i+1][62:32]) begin
                    {sort_buffer[i], sort_buffer[i+1]} <= {sort_buffer[i+1], sort_buffer[i]};
                end
                else begin
                    sort_buffer[i] <= sort_buffer[i];
                    sort_buffer[i+1] <= sort_buffer[i+1];
                end
            end
        end
    end

    else if(sort_state == CMP) begin
        sort_buffer[255] <= b0123_cmp == 0 ? b0_buffer_head :
                            b0123_cmp == 1 ? b1_buffer_head :
                            b0123_cmp == 2 ? b2_buffer_head : b3_buffer_head;
        sort_buffer[254:0] <= sort_buffer[255:1];
    end
    else begin
        sort_buffer [255:0] <= sort_buffer [255:0];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        L1_sort_cnt <= 0;
    end 
    else if(state == WRITE && w_receive_cnt == 255 && in_mode_r == 3) begin
        L1_sort_cnt <= L1_sort_cnt + 1;
    end
    else if(state == IDLE) begin
        L1_sort_cnt <= 0;
    end
    else begin
        L1_sort_cnt <= L1_sort_cnt;
    end
end
wire [63:0] sort_buffer_tail;
wire [30:0] sort_buffer_tail_value, aw_data_value;
assign sort_buffer_tail = sort_buffer[255];
assign sort_buffer_tail_value = sort_buffer_tail[62:32];
// assign aw_data_value = w_data[62:32];
// b1 > b0 or b0 is empty.
assign b01_cmp = (b0_buffer_head_value > b1_buffer_head_value);
// b3 > b2 or b2 is empty.
assign b23_cmp = (b2_buffer_head_value > b3_buffer_head_value) ;
assign min0 = b01_cmp ? b1_buffer_head_value : b0_buffer_head_value;
assign min1 = b23_cmp ? b3_buffer_head_value : b2_buffer_head_value;
assign min0_bank = b01_cmp ? 1 : 0;
assign min1_bank = b23_cmp ? 3 : 2;
// min1 < min0 or min0 bank is empty.
assign b0123_cmp = (min0 > min1 || b_req_cnt[min0_bank][4]) ? min1_bank : min0_bank;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b_req_cnt [3:0] <= '{default: 0};
    end
    else if(sort_state == CMP) begin
        for(integer i = 0;i <= 3;i = i + 1) begin
            if(i == b0123_cmp) begin
                b_req_cnt[i] <= b_req_cnt[i] + 1;
            end
            else begin
                b_req_cnt[i] <= b_req_cnt[i];
            end
        end
    end
    else if(sort_state == ISSUE_READ_R0) begin
        begin
            for(integer i = 0;i <= 3;i = i + 1) begin
                if(i == next_fetch_bank && b_req_cnt[i][4]) begin
                    b_req_cnt[i] <= 0;
                end
                else begin
                    b_req_cnt[i] <= b_req_cnt[i];
                end
            end
        end
    end
    else if(sort_state == SORT_IDLE) begin
        for(integer i = 0;i <= 3;i = i + 1) begin
            b_req_cnt[i] <= 0;
        end
    end
    else begin
        for(integer i = 0;i <= 3;i = i + 1) begin
            b_req_cnt[i] <= b_req_cnt[i];
        end
    end
end
always @(*) begin
    for(integer i = 0;i <= 3;i = i + 1) begin
        bank_legal_empty[i] = ((b_req_cnt[i] == 15 && b0123_cmp == i && sort_state == CMP) || b_req_cnt[i][4]) && fetch_cnt[i] < 15;
    end
end
assign bank_empty = (bank_legal_empty[0]) || (bank_legal_empty[1]) || (bank_legal_empty[2]) || (bank_legal_empty[3]);
assign empty_bank = (bank_legal_empty[0]) ? 0 :
                    (bank_legal_empty[1]) ? 1 :
                    (bank_legal_empty[2]) ? 2 : 3;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fetch_cnt [3:0] <= '{default: 0};
    end
    else if(sort_state == ISSUE_READ_R0) begin
        begin
            for(integer i = 0;i <= 3;i = i + 1) begin
                if(i == next_fetch_bank && issue_r0_cnt[2]) begin
                    fetch_cnt[i] <= fetch_cnt[i] + 1;
                end
                else begin
                    fetch_cnt[i] <= fetch_cnt[i];
                end
            end
        end
    end
    else if(sort_state == SORT_IDLE) begin
        for(integer i = 0;i <= 3;i = i + 1) begin
            fetch_cnt[i] <= 0;
        end
    end
    else begin
        for(integer i = 0;i <= 3;i = i + 1) begin
            fetch_cnt[i] <= fetch_cnt[i];
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cmp_cnt <= 0;
    end
    else if(sort_state == CMP) begin
        cmp_cnt <= cmp_cnt + 1;
    end
    else if(sort_state == SORT_IDLE) begin
        cmp_cnt <= 0;
    end
    else begin
        cmp_cnt <= cmp_cnt;
    end
end


always @(*) begin
    if(receive_b0_cnt[2])begin
        bank_in_sel = next_fetch_bank;
    end
    else begin
        bank_in_sel = receive_r0_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b0_buffer[15:0] <= '{default: 0};
    end else if(((state == SORT_L2)&& r_valid && (bank_in_sel == 0))
    || (sort_state == CMP && b0123_cmp == 0))begin
        b0_buffer[15] <= r_data;
        b0_buffer[14:0] <= b0_buffer[15:1];
    end 
    else begin
        b0_buffer[15:0] <= b0_buffer[15:0];
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b1_buffer[15:0] <= '{default: 0};
    end else if(((state == SORT_L2) && r_valid && (bank_in_sel == 1))
    || (sort_state == CMP && b0123_cmp == 1))begin
        b1_buffer[15] <= r_data;
        b1_buffer[14:0] <= b1_buffer[15:1];
    end 
    else begin
        b1_buffer[15:0] <= b1_buffer[15:0];
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b2_buffer[15:0] <= '{default: 0};
    end else if(((state == SORT_L2) && r_valid && (bank_in_sel == 2))
    || (sort_state == CMP && b0123_cmp == 2))begin
        b2_buffer[15] <= r_data;
        b2_buffer[14:0] <= b2_buffer[15:1];
    end 
    else begin
        b2_buffer[15:0] <= b2_buffer[15:0];
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b3_buffer[15:0] <= '{default: 0};
    end else if(((state == SORT_L2) && r_valid && (bank_in_sel == 3))
    || (sort_state == CMP && b0123_cmp == 3))begin
        b3_buffer[15] <= r_data;
        b3_buffer[14:0] <= b3_buffer[15:1];
    end 
    else begin
        b3_buffer[15:0] <= b3_buffer[15:0];
    end
end
assign b0_buffer_head = b0_buffer[0];
assign b1_buffer_head = b1_buffer[0];
assign b2_buffer_head = b2_buffer[0];
assign b3_buffer_head = b3_buffer[0];
assign b0_buffer_head_value = b_req_cnt[0][4] ? 32'hFFFFFFFF : b0_buffer_head[62:32];
assign b1_buffer_head_value = b_req_cnt[1][4] ? 32'hFFFFFFFF : b1_buffer_head[62:32];
assign b2_buffer_head_value = b_req_cnt[2][4] ? 32'hFFFFFFFF : b2_buffer_head[62:32];
assign b3_buffer_head_value = b_req_cnt[3][4] ? 32'hFFFFFFFF : b3_buffer_head[62:32];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        next_fetch_bank <= 0;
        next_fetch_col <= 0;
    end 
    else if(issue_r0_cnt[2] == 0) begin
        next_fetch_bank <= issue_r0_cnt[1:0];
        next_fetch_col <= b_next_fetch_col[issue_r0_cnt[1:0]];
    end
    else if((sort_state == CMP || sort_state == SORT_WAIT_WRITE) && bank_empty) begin
        next_fetch_bank <= empty_bank;
        next_fetch_col <= b_next_fetch_col[empty_bank];
    end
    else if(sort_state == IDLE) begin
        next_fetch_bank <= 0;
        next_fetch_col <= 0;
    end
    else  begin
        next_fetch_bank <= next_fetch_bank;
        next_fetch_col <= next_fetch_col;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b_next_fetch_col [3:0] <= '{default: 0};
    end 
    else if(sort_state == ISSUE_READ_R0) begin
        b_next_fetch_col[next_fetch_bank] <= b_next_fetch_col[next_fetch_bank] + 16;
    end
    else if(sort_state == IDLE) begin
        b_next_fetch_col [3:0] <= '{default: 0};
    end
    else  begin
        b_next_fetch_col [3:0] <= b_next_fetch_col [3:0];
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        issue_r0_cnt <= 0;
    end 
    else if(sort_state == ISSUE_READ_R0 && ~issue_r0_cnt[2]) begin
        issue_r0_cnt <= issue_r0_cnt + 1;
    end
    else if(sort_state == SORT_IDLE) begin
        issue_r0_cnt <= 0;
    end
    else  begin
        issue_r0_cnt <= issue_r0_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        receive_b0_cnt <= 0;
    end 
    else if(sort_r_receive_cnt == 15 && ~receive_b0_cnt[2]) begin
        receive_b0_cnt <= receive_b0_cnt + 1;
    end
    else if(sort_state == SORT_IDLE) begin
        receive_b0_cnt <= 0;
    end
    else  begin
        receive_b0_cnt <= receive_b0_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        receive_r0_cnt <= 0;
    end 
    else if(sort_r_receive_cnt == 15) begin
        receive_r0_cnt <= receive_r0_cnt + 1;
    end
    else if(sort_state == SORT_IDLE) begin
        receive_r0_cnt <= 0;
    end
    else  begin
        receive_r0_cnt <= receive_r0_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sort_r_issue_cnt <= 0;
    end 
    else if(sort_state == READ_R0) begin
        if(ar_valid & ar_ready)
            sort_r_issue_cnt <= sort_r_issue_cnt + 1;
        else sort_r_issue_cnt <= sort_r_issue_cnt;
    end
    else  begin
        sort_r_issue_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sort_r_receive_cnt <= 0;
    end 
    else if((state == SORT_L2) && r_valid) begin
        sort_r_receive_cnt <= sort_r_receive_cnt + 1;
    end
    else  begin
        sort_r_receive_cnt <= 0;
    end
end
// AXI

// ar
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_addr_cnt <= 0;
    end 
    else if(state == READ && ar_valid && ar_ready) begin
        ar_addr_cnt <= ar_addr_cnt + 1;
    end
    else if(state != READ) begin
        ar_addr_cnt <= 0;
    end
    else begin
        ar_addr_cnt <= ar_addr_cnt;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_receive_cnt <= 0;
    end 
    else if(state == READ && r_valid & r_ready) begin
        r_receive_cnt <= r_receive_cnt + 1;
    end
    else  begin
        r_receive_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_addr <= 0;
        ar_valid <= 0;
    end else if(state == INIT && in_mode_r == 0) begin
        ar_addr <= {in_bank_reg, in_src_row_reg, 8'b0};
        ar_valid <= 1;
    end
    else if(state == SORT_READ) begin
        ar_addr <= {L1_sort_cnt[1:0], in_src_row_r, 8'b0};
        ar_valid <= 1;
    end
    else if(calc_state == CALC_LOAD_ROOT) begin
        ar_addr <= {curr_calc_cnt, in_src_row_r, 8'b0};
        ar_valid <= 1;
    end
    else if((state == READ && ar_addr_cnt < 255) || (sort_state == READ_R0)) begin
        ar_addr <= ar_ready ? ar_addr + 1 : ar_addr;
        ar_valid <= 1;
    end
    else if(calc_state == CHECK_STACK && stack_top_mark == 0 && op_stack_ptr != 0) begin
        ar_addr <= stack_top_l_val;
        ar_valid <= 1;
    end
    else if(calc_state == SEND_LR && !(l_ar_handshake && (ar_ready || r_ar_handshake))) begin
        ar_addr <= (l_ar_handshake || ar_ready) ? stack_top_r_val_reg : ar_addr;
        ar_valid <= 1;
    end
    else if(sort_state == ISSUE_READ_R0) begin
        ar_addr <= {next_fetch_bank, 6'd63, next_fetch_col};
        ar_valid <= 1;
    end
    else begin
        ar_addr <= 0;
        ar_valid <= 0;
    end
end
// r channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_ready <= 0;
    end else begin
        r_ready <= 1;
    end
end

// aw w channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        aw_addr <= 0;
        aw_valid <= 0;
        w_data <= 0;
        w_valid <= 0;
    end else if(state == INIT && in_mode_r == 1) begin
        aw_addr <= {in_bank_reg, in_dst_row_reg, 8'b0};
        aw_valid <= 1;
        w_data <= in_data_reg;
        w_valid <= 1;
    end
    else if(state == SORT_WRITE) begin
        aw_addr <= {L1_sort_cnt, 6'd63, 8'b0};
        aw_valid <= 1;
        w_data <= sort_buffer[0];
        w_valid <= 1;
    end
    else if(sort_state == SORT_ISSUE_WRITE) begin
        aw_addr <= {L1_sort_cnt, in_dst_row_r, 8'b0};
        aw_valid <= 1;
        w_data <= sort_buffer[0];
        w_valid <= 1;
    end
    else if(state == WRITE && aw_addr_cnt < 255) begin
        aw_addr <= aw_ready ? aw_addr + 1 : aw_addr;
        aw_valid <= 1;
        w_data <= aw_ready ? in_data_r[aw_valid_pending-1] : in_data_r[aw_valid_pending];
        w_valid <= 1;
    end
    else begin
        aw_addr <= 0;
        aw_valid <= 0;
        w_data <= 0;
        w_valid <= 0;
    end
end
 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        aw_addr_cnt <= 0;
    end 
    else if(state == WRITE && aw_valid && aw_ready) begin
        aw_addr_cnt <= aw_addr_cnt == 255 ? aw_addr_cnt : aw_addr_cnt + 1;
    end
    else if(state != WRITE) begin
        aw_addr_cnt <= 0;
    end
    else begin
        aw_addr_cnt <= aw_addr_cnt;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w_receive_cnt <= 0;
    end 
    else if(state == WRITE && b_valid) begin
        w_receive_cnt <= w_receive_cnt + 1;
    end
    else  begin
        w_receive_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        aw_valid_pending <= 0;
    end 
    else if(state == WRITE && aw_valid && !aw_ready) begin
        aw_valid_pending <= aw_valid_pending + 1;
    end
    else if(state != WRITE) begin
        aw_valid_pending <= 0;
    end
    else begin
        aw_valid_pending <= aw_valid_pending;
    end
end

// b response channel

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    b_ready <= 0;
    end else begin
    b_ready <= 1;
    end
end

// out data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end else if(state == READ && r_valid && in_mode_r == 0) begin
        out_valid <= 1;
        out_data <= r_data;
    end 
    else if((state == WRITE && w_receive_cnt == 255 && in_mode_r != 3) || (sort_state == SORT_SORT_DONE)) begin
        out_valid <= 1;
        out_data <= 0;
    end
    else if(calc_state == OUTPUT) begin
        out_valid <= 1;
        out_data <= calc_buffer[output_cnt];
    end
    else begin
        out_valid <= 0;
        out_data <= 0;
    end
end

endmodule
