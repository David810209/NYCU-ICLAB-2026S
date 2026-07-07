//############################################################################
//      File Name   : DSS.sv  (v5.0 — single shared shift-add mult, 7-input mux)
//############################################################################

module DSS(input clk, INF.DSS_inf inf);
import usertype::*;

//================================================================
// FSM
//================================================================
typedef enum logic [3:0] {
    S_IDLE   = 4'd0,
    S_READ   = 4'd1,
    S_READ1  = 4'd2,
    S_TBL    = 4'd3,
    S_PREP   = 4'd4,
    S_ISSUE_CALC   = 4'd5,
    S_MULT   = 4'd6,
    S_DECIDE = 4'd7,
    S_COMMIT = 4'd8,
    S_WRITE  = 4'd9,
    S_FINISH = 4'd10
} FSM_t;

FSM_t state, next_state;

//================================================================
// input registers
//================================================================
Action       req_action;
Dessert_Type req_dessert;
Order_Mode   req_order_mode;
Date         req_date;
Staff_t      req_staff;
Data_No      req_data_no;
Stock        req_restock [0:4];

logic        data_no_valid_reg;
logic [2:0]  restock_cnt;
logic        input_done;

//================================================================
// DRAM access
//================================================================
logic        read_start;
logic        read_continue;
logic        write_start;
logic        dram_rvalid0;
logic        dram_rvalid;
logic        dram_wvalid;
logic [63:0] dram_rdata0;
logic [63:0] dram_rdata1;
logic [63:0] write_data0;
logic [63:0] write_data1;

//================================================================
// unpacked DRAM
//================================================================
Stock      cur_flour, cur_butter, cur_milk, cur_sugar, cur_fruit;
Month      cur_month;
Day        cur_day;
Sales_t    cur_sales;
Staff_t    cur_staff_dram;
Level_t    cur_level;
Balance_t  cur_balance;

//================================================================
// next-state DRAM fields
//================================================================
Stock      nxt_flour, nxt_butter, nxt_milk, nxt_sugar, nxt_fruit;
Month      nxt_month;
Day        nxt_day;
Sales_t    nxt_sales;
Staff_t    nxt_staff;
Level_t    nxt_level;
Balance_t  nxt_balance;
Stock      added_flour, added_butter, added_milk, added_sugar, added_fruit;
//================================================================
// calculation result regs
//================================================================
Warn_Msg   warn_msg_r;
Warn_Msg   warn_msg_comb;
logic      complete_r;

//================================================================
// table result regs (loaded at S_TBL)
//================================================================
logic [9:0]  price_r;
logic [4:0]  cost_flour_r;
logic [6:0]  cost_butter_r;
logic [5:0]  cost_milk_r;
logic [4:0]  cost_sugar_r;
logic [7:0]  cost_fruit_r;
logic [13:0] hire_fee_r;
logic [15:0] salary_r;
logic [6:0]  threshold_r;

//================================================================
// LUT outputs (comb)
//================================================================
logic [9:0]  price_lut_out;
logic [4:0]  cost_flour_lut_out;
logic [6:0]  cost_butter_lut_out;
logic [5:0]  cost_milk_lut_out;
logic [4:0]  cost_sugar_lut_out;
logic [7:0]  cost_fruit_lut_out;
logic [13:0] hire_fee_lut_out;
logic [15:0] salary_lut_out;
logic [6:0]  threshold_lut_out;
logic [3:0]  cur_lv10;

//================================================================
// scale-by-shift functions
//================================================================
function logic [10:0] scale_stock_11(input logic [7:0] base, input Order_Mode mode);
    case(mode)
        Single:     scale_stock_11 = {3'd0, base};
        Family_Set: scale_stock_11 = {1'd0, base, 2'd0};
        Party_Pack: scale_stock_11 = {base, 3'd0};
        default:    scale_stock_11 = {3'd0, base};
    endcase
endfunction

function logic [12:0] scale_money_19(input logic [9:0] base, input Order_Mode mode);
    case(mode)
        Single:     scale_money_19 = {3'd0, base};
        Family_Set: scale_money_19 = {1'd0, base, 2'd0};
        Party_Pack: scale_money_19 = {base, 3'd0};
        default:    scale_money_19 = {3'd0, base};
    endcase
endfunction

function logic [3:0] scale_count_4(input Order_Mode mode);
    case(mode)
        Single:     scale_count_4 = 4'd1;
        Family_Set: scale_count_4 = 4'd4;
        Party_Pack: scale_count_4 = 4'd8;
        default:    scale_count_4 = 4'd1;
    endcase
endfunction

function logic is_earlier_date(input Date din, input Month old_m, input Day old_d);
    if({4'b0, din.M} < old_m)      is_earlier_date = 1'b1;
    else if({4'b0, din.M} > old_m) is_earlier_date = 1'b0;
    else                            is_earlier_date = ({3'b0, din.D} < old_d);
endfunction

function logic [7:0] base_flour(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_flour = 8'd100;
        Bread:      base_flour = 8'd200;
        Fruit_Cake: base_flour = 8'd150;
        Pudding:    base_flour = 8'd0;
        Macaron:    base_flour = 8'd40;
        Pancake:    base_flour = 8'd120;
        Brownie:    base_flour = 8'd80;
        Scone:      base_flour = 8'd150;
        default:    base_flour = 8'd0;
    endcase
endfunction

function logic [7:0] base_butter(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_butter = 8'd50;
        Bread:      base_butter = 8'd20;
        Fruit_Cake: base_butter = 8'd80;
        Pudding:    base_butter = 8'd0;
        Macaron:    base_butter = 8'd30;
        Pancake:    base_butter = 8'd30;
        Brownie:    base_butter = 8'd100;
        Scone:      base_butter = 8'd60;
        default:    base_butter = 8'd0;
    endcase
endfunction

function logic [7:0] base_milk(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_milk = 8'd0;
        Bread:      base_milk = 8'd50;
        Fruit_Cake: base_milk = 8'd40;
        Pudding:    base_milk = 8'd150;
        Macaron:    base_milk = 8'd0;
        Pancake:    base_milk = 8'd80;
        Brownie:    base_milk = 8'd0;
        Scone:      base_milk = 8'd30;
        default:    base_milk = 8'd0;
    endcase
endfunction

function logic [7:0] base_sugar(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_sugar = 8'd30;
        Bread:      base_sugar = 8'd10;
        Fruit_Cake: base_sugar = 8'd60;
        Pudding:    base_sugar = 8'd50;
        Macaron:    base_sugar = 8'd120;
        Pancake:    base_sugar = 8'd20;
        Brownie:    base_sugar = 8'd100;
        Scone:      base_sugar = 8'd20;
        default:    base_sugar = 8'd0;
    endcase
endfunction

function logic [7:0] base_fruit(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_fruit = 8'd0;
        Bread:      base_fruit = 8'd0;
        Fruit_Cake: base_fruit = 8'd100;
        Pudding:    base_fruit = 8'd20;
        Macaron:    base_fruit = 8'd0;
        Pancake:    base_fruit = 8'd40;
        Brownie:    base_fruit = 8'd0;
        Scone:      base_fruit = 8'd10;
        default:    base_fruit = 8'd0;
    endcase
endfunction

//================================================================
// LUT instantiations
//================================================================
PRICE_LUT u_price_lut (.dessert(req_dessert), .level(cur_level), .price(price_lut_out));
DIV10_LUT u_div10_lut (.level(cur_level), .lv10(cur_lv10));
COST_FLOUR_LUT  u_cost_flour_lut  (.lv10(cur_lv10), .cost(cost_flour_lut_out));
COST_BUTTER_LUT u_cost_butter_lut (.lv10(cur_lv10), .cost(cost_butter_lut_out));
COST_MILK_LUT   u_cost_milk_lut   (.lv10(cur_lv10), .cost(cost_milk_lut_out));
COST_SUGAR_LUT  u_cost_sugar_lut  (.lv10(cur_lv10), .cost(cost_sugar_lut_out));
COST_FRUIT_LUT  u_cost_fruit_lut  (.lv10(cur_lv10), .cost(cost_fruit_lut_out));
HIRE_FEE_LUT  u_hire_fee_lut  (.level(cur_level), .fee(hire_fee_lut_out));
SALARY_LUT    u_salary_lut    (.level(cur_level), .salary(salary_lut_out));
THRESHOLD_LUT u_threshold_lut (.lv10(cur_lv10), .threshold(threshold_lut_out));
//================================================================
// pre-computed combinational signals (suffix _c)
//================================================================
logic [10:0] need_flour_c, need_butter_c, need_milk_c, need_sugar_c, need_fruit_c;
assign need_flour_c  = scale_stock_11(base_flour(req_dessert),  req_order_mode);
assign need_butter_c = scale_stock_11(base_butter(req_dessert), req_order_mode);
assign need_milk_c   = scale_stock_11(base_milk(req_dessert),   req_order_mode);
assign need_sugar_c  = scale_stock_11(base_sugar(req_dessert),  req_order_mode);
assign need_fruit_c  = scale_stock_11(base_fruit(req_dessert),  req_order_mode);

logic stock_lack_c;
assign stock_lack_c = (cur_flour  < {1'b0, need_flour_c} ) ||
                      (cur_butter < {1'b0, need_butter_c}) ||
                      (cur_milk   < {1'b0, need_milk_c  }) ||
                      (cur_sugar  < {1'b0, need_sugar_c }) ||
                      (cur_fruit  < {1'b0, need_fruit_c });

logic [12:0] sell_price_c;
logic [12:0] sell_price_r;
assign sell_price_c = scale_money_19(price_r, req_order_mode);

logic [3:0] order_cnt_c;
assign order_cnt_c = scale_count_4(req_order_mode);

logic [12:0] sales_total_c;
assign sales_total_c = {1'b0, cur_sales} + {9'b0, order_cnt_c};

logic upgrade_en_c;
assign upgrade_en_c = (cur_level < 8'd100) && (sales_total_c >= {6'b0, threshold_r});

logic [24:0] balance_add_tmp_c;
assign balance_add_tmp_c = {1'b0, cur_balance} + {12'b0, sell_price_r};

logic [12:0] sum_flour_req_c, sum_butter_req_c, sum_milk_req_c, sum_sugar_req_c, sum_fruit_req_c;
assign sum_flour_req_c  = {1'b0, cur_flour}  + {1'b0, req_restock[0]};
assign sum_butter_req_c = {1'b0, cur_butter} + {1'b0, req_restock[1]};
assign sum_milk_req_c   = {1'b0, cur_milk}   + {1'b0, req_restock[2]};
assign sum_sugar_req_c  = {1'b0, cur_sugar}  + {1'b0, req_restock[3]};
assign sum_fruit_req_c  = {1'b0, cur_fruit}  + {1'b0, req_restock[4]};

logic [10:0] real_flour_c, real_butter_c, real_milk_c, real_sugar_c, real_fruit_c;
assign real_flour_c  = sum_flour_req_c[12]  ? (11'd2047 - cur_flour[10:0] ) : req_restock[0][10:0];
assign real_butter_c = sum_butter_req_c[12] ? (11'd2047 - cur_butter[10:0]) : req_restock[1][10:0];
assign real_milk_c   = sum_milk_req_c[12]   ? (11'd2047 - cur_milk[10:0]  ) : req_restock[2][10:0];
assign real_sugar_c  = sum_sugar_req_c[12]  ? (11'd2047 - cur_sugar[10:0] ) : req_restock[3][10:0];
assign real_fruit_c  = sum_fruit_req_c[12]  ? (11'd2047 - cur_fruit[10:0] ) : req_restock[4][10:0];

logic stock_overflow_c;
assign stock_overflow_c = sum_flour_req_c[12] || sum_butter_req_c[12] ||
                          sum_milk_req_c[12]  || sum_sugar_req_c[12]  || sum_fruit_req_c[12];

logic [8:0] sum_staff_req_c;
assign sum_staff_req_c = {1'b0, cur_staff_dram} + {1'b0, req_staff};

logic staff_overflow_c;
assign staff_overflow_c = (sum_staff_req_c > 9'd100);

logic [7:0] real_staff_c;
assign real_staff_c = staff_overflow_c ? (8'd100 - cur_staff_dram) : req_staff;

logic date_ok_c;
assign date_ok_c = !is_earlier_date(req_date, cur_month, cur_day);

//================================================================
// Registered versions (latched in S_PREP)
//================================================================
logic [10:0] need_flour, need_butter, need_milk, need_sugar, need_fruit;
logic        stock_lack;
logic [12:0] sales_total;
logic        upgrade_en;
logic [24:0] balance_add_tmp;
logic [10:0] real_flour, real_butter, real_milk, real_sugar, real_fruit;
logic        stock_overflow;
logic        staff_overflow;
logic [7:0]  real_staff;
logic        date_ok;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        upgrade_en <= 1'b0;
        sell_price_r <= 13'd0;
    end
    else if(state == S_PREP) begin
        upgrade_en     <= upgrade_en_c;//
        sell_price_r <= sell_price_c;
    end
    else begin
        sell_price_r <= sell_price_r;
        upgrade_en     <= upgrade_en;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        balance_add_tmp <= 25'd0;
    end
    else if(state == S_DECIDE) begin
        balance_add_tmp <= balance_add_tmp_c;//
    end
    else begin
        balance_add_tmp <= balance_add_tmp;
    end
end

logic early_date_ok;
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        need_flour     <= 11'd0;
        need_butter    <= 11'd0;
        need_milk      <= 11'd0;
        need_sugar     <= 11'd0;
        need_fruit     <= 11'd0;
        stock_lack     <= 1'b0;
        sales_total    <= 13'd0;
        real_flour     <= 11'd0;
        real_butter    <= 11'd0;
        real_milk      <= 11'd0;
        real_sugar     <= 11'd0;
        real_fruit     <= 11'd0;
        stock_overflow <= 1'b0;
        staff_overflow <= 1'b0;
        real_staff     <= 8'd0;
        date_ok        <= 1'b0;
    end
    else if(state == S_TBL) begin
        need_flour     <= need_flour_c;
        need_butter    <= need_butter_c;
        need_milk      <= need_milk_c;
        need_sugar     <= need_sugar_c;
        need_fruit     <= need_fruit_c;
        stock_lack     <= stock_lack_c;
        sales_total    <= sales_total_c;
        real_flour     <= real_flour_c;
        real_butter    <= real_butter_c;
        real_milk      <= real_milk_c;
        real_sugar     <= real_sugar_c;
        real_fruit     <= real_fruit_c;
        stock_overflow <= stock_overflow_c;
        staff_overflow <= staff_overflow_c;
        real_staff     <= real_staff_c;
        date_ok        <= date_ok_c;
    end
    else if((state == S_READ) && dram_rvalid0) begin
        // Early-decide path: latch date_ok from rdata0 (cur_month/cur_day
        // registers update on the same edge so we read rdata0 directly).
        date_ok <= early_date_ok;
    end
    else begin
        need_flour     <= need_flour;
        need_butter    <= need_butter;
        need_milk      <= need_milk;
        need_sugar     <= need_sugar;
        need_fruit     <= need_fruit;
        stock_lack     <= stock_lack;
        sales_total    <= sales_total;
        real_flour     <= real_flour;
        real_butter    <= real_butter;
        real_milk      <= real_milk;
        real_sugar     <= real_sugar;
        real_fruit     <= real_fruit;
        stock_overflow <= stock_overflow;
        staff_overflow <= staff_overflow;
        real_staff     <= real_staff;
        date_ok        <= date_ok;
    end
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        added_flour     <= 12'd0;
        added_butter    <= 12'd0;
        added_milk      <= 12'd0;
        added_sugar     <= 12'd0;
        added_fruit     <= 12'd0;
    end
    else if(state == S_PREP) begin
        if(req_action == Restock) begin
            added_flour <= cur_flour + real_flour;
            added_butter <= cur_butter + real_butter;
            added_milk <= cur_milk + real_milk;
            added_sugar <= cur_sugar + real_sugar;
            added_fruit <= cur_fruit + real_fruit;
        end
        else begin
            added_flour     <= cur_flour  - {1'b0, need_flour};;
            added_butter    <= cur_butter - {1'b0, need_butter};
            added_milk      <= cur_milk   - {1'b0, need_milk};
            added_sugar     <= cur_sugar  - {1'b0, need_sugar};
            added_fruit     <= cur_fruit  - {1'b0, need_fruit};
        end
    end
    else begin
        added_flour     <= added_flour;
        added_butter    <= added_butter;
        added_milk      <= added_milk;
        added_sugar     <= added_sugar;
        added_fruit     <= added_fruit;
    end
end
//================================================================
// SHARED SHIFT-ADD MULTIPLIER
//================================================================
logic [2:0]  mult_step;
logic [3:0]  mult_cycle_n;
logic [15:0] mult_a;
logic [10:0] mult_b;
logic        mult_en;
logic        mult_done;
logic [22:0] mult_result;

mult_16bit_u u_mult (
    .clk      (clk),
    .rst_n    (inf.rst_n),
    .mult_en  (mult_en),
    .cycle_n  (mult_cycle_n),
    .A        (mult_a),
    .B        (mult_b),
    .result   (mult_result),
    .mult_done(mult_done)
);

logic [2:0] step_start;
always_comb begin
    case(req_action)
        Restock:    begin step_start = 3'd0;  end
        Hire_Staff: begin step_start = 3'd5;  end
        Pay_Day:    begin step_start = 3'd6;  end
        default:    begin step_start = 3'd0;  end
    endcase
end

always_comb begin
    case(mult_step)
        3'd0: begin mult_a = real_flour;  mult_b = cost_flour_r ;   mult_cycle_n = 4'd3; end
        3'd1: begin mult_a = real_butter; mult_b = cost_butter_r ;  mult_cycle_n = 4'd5; end
        3'd2: begin mult_a = real_milk;   mult_b = cost_milk_r ;    mult_cycle_n = 4'd4; end
        3'd3: begin mult_a = real_sugar;  mult_b = cost_sugar_r ;   mult_cycle_n = 4'd3; end
        3'd4: begin mult_a = real_fruit;  mult_b = cost_fruit_r ;   mult_cycle_n = 4'd6; end
        3'd5: begin mult_a = hire_fee_r;    mult_b = {3'b0, real_staff};   mult_cycle_n = 4'd3;  end
        3'd6: begin mult_a = salary_r;      mult_b = {3'b0, cur_staff_dram}; mult_cycle_n = 4'd5;  end
        default: begin mult_a = 16'd0; mult_b = 11'd0; mult_cycle_n = 4'd11; end
    endcase
end

logic all_mult_done;
assign all_mult_done = mult_done && (mult_step >= 4);

//================================================================
// mult_step register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        mult_step <= 3'd0;
    end
    else if(state == S_FINISH) begin
        mult_step <= 3'd0;
    end
    else if(state == S_PREP) begin
        mult_step <= step_start;
    end
    else if((state == S_MULT) && mult_done) begin
        mult_step <= mult_step + 3'd1;
    end
    else begin
        mult_step <= mult_step;
    end
end

assign mult_en = (state == S_ISSUE_CALC);

//================================================================
// real_cost / real_fee / total_salary registers
//================================================================
logic [19:0] real_cost;
logic [18:0] real_fee;
logic [22:0] total_salary;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        real_cost <= 20'd0;
    end
    else if(state == S_FINISH) begin
        real_cost <= 20'd0;
    end
    else if((state == S_MULT) && mult_done) begin
        real_cost <= real_cost + mult_result[19:0];
    end
    else begin
        real_cost <= real_cost;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        real_fee <= 19'd0;
    end
    else if(state == S_FINISH) begin
        real_fee <= 19'd0;
    end
    else if((state == S_MULT) && mult_done) begin
        real_fee <= mult_result[18:0];
    end
    else begin
        real_fee <= real_fee;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        total_salary <= 23'd0;
    end
    else if(state == S_FINISH) begin
        total_salary <= 23'd0;
    end
    else if((state == S_MULT) && mult_done) begin
        total_salary <= mult_result;
    end
    else begin
        total_salary <= total_salary;
    end
end

//================================================================
// balance lack flags
//================================================================
logic balance_lack_salary;
logic balance_lack_restock;
logic balance_lack_hire;
assign balance_lack_salary  = (cur_balance < {1'b0, total_salary});
assign balance_lack_restock = (cur_balance < {4'b0, real_cost});
assign balance_lack_hire    = (cur_balance < {5'b0, real_fee});

//================================================================
// per-action condition wires
//================================================================
logic ms_no_staff_warn_c, ms_stock_warn_c, ms_ok_c;
assign ms_no_staff_warn_c = date_ok && (cur_staff_dram == 8'd0);
assign ms_stock_warn_c    = date_ok && (cur_staff_dram != 8'd0) && stock_lack;
assign ms_ok_c            = date_ok && (cur_staff_dram != 8'd0) && !stock_lack;

logic rs_balance_warn_c, rs_restock_warn_c, rs_no_warn_c;
assign rs_balance_warn_c = date_ok && balance_lack_restock;
assign rs_restock_warn_c = date_ok && !balance_lack_restock && stock_overflow;
assign rs_no_warn_c      = date_ok && !balance_lack_restock && !stock_overflow;

logic hs_balance_warn_c, hs_staff_warn_c, hs_no_warn_c;
assign hs_balance_warn_c = date_ok && balance_lack_hire;
assign hs_staff_warn_c   = date_ok && !balance_lack_hire && staff_overflow;
assign hs_no_warn_c      = date_ok && !balance_lack_hire && !staff_overflow;

logic pd_no_staff_warn_c, pd_balance_warn_c, pd_no_warn_c;
assign pd_no_staff_warn_c = date_ok && (cur_staff_dram == 8'd0);
assign pd_balance_warn_c  = date_ok && (cur_staff_dram != 8'd0) && balance_lack_salary;
assign pd_no_warn_c       = date_ok && (cur_staff_dram != 8'd0) && !balance_lack_salary;


logic ms_no_staff_warn, ms_stock_warn, ms_ok;
logic rs_balance_warn, rs_restock_warn, rs_no_warn;
logic hs_balance_warn, hs_staff_warn, hs_no_warn;
logic pd_no_staff_warn, pd_balance_warn, pd_no_warn;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        ms_no_staff_warn <= 1'b0;
        ms_stock_warn    <= 1'b0;
        ms_ok            <= 1'b0;
    end
    else if(state == S_PREP) begin
        ms_no_staff_warn <= ms_no_staff_warn_c;
        ms_stock_warn    <= ms_stock_warn_c;
        ms_ok            <= ms_ok_c;
    end
    else begin
        ms_no_staff_warn <= ms_no_staff_warn;
        ms_stock_warn    <= ms_stock_warn;
        ms_ok            <= ms_ok;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        rs_balance_warn <= 1'b0;
        rs_restock_warn <= 1'b0;
        rs_no_warn      <= 1'b0;
        hs_balance_warn <= 1'b0;
        hs_staff_warn   <= 1'b0;
        hs_no_warn      <= 1'b0;
        pd_no_staff_warn <= 1'b0;
        pd_balance_warn  <= 1'b0;
        pd_no_warn       <= 1'b0;
    end
    else if(state == S_DECIDE) begin
        rs_balance_warn  <= rs_balance_warn_c;
        rs_restock_warn  <= rs_restock_warn_c;
        rs_no_warn       <= rs_no_warn_c;
        hs_balance_warn  <= hs_balance_warn_c;
        hs_staff_warn    <= hs_staff_warn_c;
        hs_no_warn       <= hs_no_warn_c;
        pd_no_staff_warn <= pd_no_staff_warn_c;
        pd_balance_warn  <= pd_balance_warn_c;
        pd_no_warn       <= pd_no_warn_c;
    end
    else begin
        rs_balance_warn  <= rs_balance_warn;
        rs_restock_warn  <= rs_restock_warn;
        rs_no_warn       <= rs_no_warn;
        hs_balance_warn  <= hs_balance_warn;
        hs_staff_warn    <= hs_staff_warn;
        hs_no_warn       <= hs_no_warn;
        pd_no_staff_warn <= pd_no_staff_warn;
        pd_balance_warn  <= pd_balance_warn;
        pd_no_warn       <= pd_no_warn;
    end
end

//================================================================
// input control
//================================================================
assign input_done = (req_action == Restock) ? ((restock_cnt == 3'd5) || (inf.restock_valid && (restock_cnt == 3'd4))) :
                                               data_no_valid_reg;
assign read_start    = (state == S_IDLE) && input_done;
assign read_continue = (state == S_READ1);
assign write_start   = (state == S_WRITE);

//================================================================
// FSM state register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) state <= S_IDLE;
    else           state <= next_state;
end

// early-decide flags: comb signals valid the cycle dram_rvalid0 pulses.
// Use rdata0 directly because cur_month/cur_day registers update on the
// same edge so their Q is still old.
logic [7:0] rdata0_month;
logic [7:0] rdata0_day;
assign rdata0_month = dram_rdata0[39:32];
assign rdata0_day   = dram_rdata0[7:0];

logic early_skip_cvd;
logic early_date_warn;
assign early_date_ok    = !is_earlier_date(req_date, rdata0_month, rdata0_day);
assign early_skip_cvd   = (req_action == Check_Valid_Date);
assign early_date_warn  = !early_date_ok && (req_action != Check_Valid_Date);

//================================================================
// FSM next-state
//================================================================
always_comb begin
    next_state = state;
    case(state)
        S_IDLE:   next_state = input_done   ? S_READ   : S_IDLE;
        S_READ:   begin
            if(dram_rvalid0) begin
                if(early_skip_cvd)        next_state = S_COMMIT;
                else if(early_date_warn)  next_state = S_FINISH;
                else                      next_state = S_READ1;
            end
            else next_state = S_READ;
        end
        S_READ1:  next_state = dram_rvalid  ? S_TBL    : S_READ1;
        S_TBL:    next_state = S_PREP;
        S_PREP:   begin
            if(req_action == Make_and_Sell) next_state = S_DECIDE;
            else next_state = S_ISSUE_CALC;
        end 
        S_ISSUE_CALC: begin
                next_state = S_MULT;
        end
        S_MULT: begin
            if(mult_done)begin
                if(all_mult_done) next_state = S_DECIDE;
                else next_state = S_ISSUE_CALC;
            end
            else next_state =  S_MULT;
        end
        S_DECIDE: next_state = S_COMMIT;
        S_COMMIT: begin
            next_state = S_WRITE;
        end
        S_WRITE:  next_state = dram_wvalid  ? S_FINISH : S_WRITE;
        S_FINISH: next_state = S_IDLE;
        default:  next_state = S_IDLE;
    endcase
end

logic commit_calc;
assign commit_calc = (state == S_COMMIT);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)             req_action <= Make_and_Sell;
    else if(state == S_FINISH) req_action <= Make_and_Sell;
    else if(inf.sel_action_valid) req_action <= inf.D.d_act[0];
    else                       req_action <= req_action;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)             req_dessert <= Cookie;
    else if(state == S_FINISH) req_dessert <= Cookie;
    else if(inf.type_valid)    req_dessert <= inf.D.d_type[0];
    else                       req_dessert <= req_dessert;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)             req_order_mode <= Single;
    else if(state == S_FINISH) req_order_mode <= Single;
    else if(inf.mode_valid)    req_order_mode <= inf.D.d_mode[0];
    else                       req_order_mode <= req_order_mode;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)             req_date <= '0;
    else if(state == S_FINISH) req_date <= '0;
    else if(inf.date_valid)    req_date <= inf.D.d_date[0];
    else                       req_date <= req_date;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)             req_staff <= '0;
    else if(state == S_FINISH) req_staff <= '0;
    else if(inf.staff_valid)   req_staff <= inf.D.d_staff[0];
    else                       req_staff <= req_staff;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)              req_data_no <= '0;
    else if(state == S_FINISH)  req_data_no <= '0;
    else if(inf.data_no_valid)  req_data_no <= inf.D.d_data_no[0];
    else                        req_data_no <= req_data_no;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)              data_no_valid_reg <= 1'b0;
    else if(state == S_FINISH)  data_no_valid_reg <= 1'b0;
    else if(inf.data_no_valid)  data_no_valid_reg <= 1'b1;
    else                        data_no_valid_reg <= data_no_valid_reg;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)              restock_cnt <= 3'd0;
    else if(state == S_FINISH)  restock_cnt <= 3'd0;
    else if(inf.restock_valid && restock_cnt < 3'd5) restock_cnt <= restock_cnt + 3'd1;
    else                        restock_cnt <= restock_cnt;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        req_restock[0] <= '0; req_restock[1] <= '0; req_restock[2] <= '0;
        req_restock[3] <= '0; req_restock[4] <= '0;
    end
    else if(state == S_FINISH) begin
        req_restock[0] <= '0; req_restock[1] <= '0; req_restock[2] <= '0;
        req_restock[3] <= '0; req_restock[4] <= '0;
    end
    else if(inf.restock_valid) begin
        case(restock_cnt)
            3'd0:    req_restock[0] <= inf.D.d_stock[0];
            3'd1:    req_restock[1] <= inf.D.d_stock[0];
            3'd2:    req_restock[2] <= inf.D.d_stock[0];
            3'd3:    req_restock[3] <= inf.D.d_stock[0];
            3'd4:    req_restock[4] <= inf.D.d_stock[0];
            default: ;
        endcase
    end
    else begin
        req_restock[0] <= req_restock[0]; req_restock[1] <= req_restock[1];
        req_restock[2] <= req_restock[2]; req_restock[3] <= req_restock[3];
        req_restock[4] <= req_restock[4];
    end
end

//================================================================
// unpacked DRAM register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        cur_flour      <= 12'd0; cur_butter <= 12'd0; cur_milk <= 12'd0;
        cur_sugar      <= 12'd0; cur_fruit  <= 12'd0;
        cur_month      <= 8'd0;  cur_day    <= 8'd0;
        cur_sales      <= 12'd0; cur_staff_dram <= 8'd0; cur_level <= 8'd0;
        cur_balance    <= 24'd0;
    end
    else begin
        if((state == S_READ) && dram_rvalid0) begin
            cur_flour      <= dram_rdata0[63:52];
            cur_butter     <= dram_rdata0[51:40];
            cur_month      <= dram_rdata0[39:32];
            cur_milk       <= dram_rdata0[31:20];
            cur_sugar      <= dram_rdata0[19:8];
            cur_day        <= dram_rdata0[7:0];
        end
        if((state == S_READ1) && dram_rvalid) begin
            cur_fruit      <= dram_rdata1[63:52];
            cur_sales      <= dram_rdata1[51:40];
            cur_staff_dram <= dram_rdata1[39:32];
            cur_balance    <= dram_rdata1[31:8];
            cur_level      <= dram_rdata1[7:0];
        end
    end
end

//================================================================
// table result regs (loaded at S_TBL)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        price_r <= 10'd0; cost_flour_r <= 5'd0; cost_butter_r <= 7'd0;
        cost_milk_r <= 6'd0; cost_sugar_r <= 5'd0; cost_fruit_r <= 8'd0;
        hire_fee_r <= 14'd0; salary_r <= 16'd0; threshold_r <= 7'd10;
    end
    else if(state == S_TBL) begin
        price_r       <= price_lut_out;
        cost_flour_r  <= cost_flour_lut_out;
        cost_butter_r <= cost_butter_lut_out;
        cost_milk_r   <= cost_milk_lut_out;
        cost_sugar_r  <= cost_sugar_lut_out;
        cost_fruit_r  <= cost_fruit_lut_out;
        hire_fee_r    <= hire_fee_lut_out;
        salary_r      <= salary_lut_out;
        threshold_r   <= threshold_lut_out;
    end
    else begin
        price_r <= price_r; cost_flour_r <= cost_flour_r; cost_butter_r <= cost_butter_r;
        cost_milk_r <= cost_milk_r; cost_sugar_r <= cost_sugar_r; cost_fruit_r <= cost_fruit_r;
        hire_fee_r <= hire_fee_r; salary_r <= salary_r; threshold_r <= threshold_r;
    end
end

//================================================================
// nxt_flour / nxt_butter / nxt_milk / nxt_sugar / nxt_fruit
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_flour  <= 12'd0;
        nxt_butter <= 12'd0;
        nxt_milk   <= 12'd0;
        nxt_sugar  <= 12'd0;
        nxt_fruit  <= 12'd0;
    end
    else if(commit_calc) begin
        if(req_action == Make_and_Sell && ms_ok) begin
                nxt_flour  <= added_flour;
                nxt_butter <= added_butter;
                nxt_milk   <= added_milk;
                nxt_sugar  <= added_sugar;
                nxt_fruit  <= added_fruit;
        end
        else if(req_action == Restock && (rs_no_warn || rs_restock_warn)) begin
                nxt_flour  <= added_flour;
                nxt_butter <= added_butter;
                nxt_milk   <= added_milk;
                nxt_sugar  <= added_sugar;
                nxt_fruit  <= added_fruit;
        end
        else begin
            nxt_flour  <= cur_flour;
            nxt_butter <= cur_butter;
            nxt_milk   <= cur_milk;
            nxt_sugar  <= cur_sugar;
            nxt_fruit  <= cur_fruit;
        end
    end
    else begin
        nxt_flour  <= nxt_flour;
        nxt_butter <= nxt_butter;
        nxt_milk   <= nxt_milk;
        nxt_sugar  <= nxt_sugar;
        nxt_fruit  <= nxt_fruit;
    end
end

//================================================================
// nxt_month / nxt_day
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        nxt_month <= 8'd0;
    else if(commit_calc) begin
        case(req_action)
            Check_Valid_Date: nxt_month <= {4'b0, req_date.M};
            default:          nxt_month <= date_ok ? {4'b0, req_date.M} : cur_month;
        endcase
    end
    else                  nxt_month <= nxt_month;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        nxt_day <= 8'd0;
    else if(commit_calc) begin
        case(req_action)
            Check_Valid_Date: nxt_day <= {3'b0, req_date.D};
            default:          nxt_day <= date_ok ? {3'b0, req_date.D} : cur_day;
        endcase
    end
    else                  nxt_day <= nxt_day;
end

//================================================================
// nxt_sales (sat 4095)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        nxt_sales <= 12'd0;
    else if(commit_calc) begin
        if(req_action == Make_and_Sell && ms_ok) begin
            if(upgrade_en) nxt_sales <= sales_total[11:0] - {5'b0, threshold_r};
            else           nxt_sales <= (sales_total > 13'd4095) ? 12'd4095 : sales_total[11:0];
        end
        else if(req_action == Pay_Day && pd_balance_warn) begin
            nxt_sales <= 12'd0;
        end
        else begin
            nxt_sales <= cur_sales;
        end
    end
    else                  nxt_sales <= nxt_sales;
end

//================================================================
// nxt_level (sat 100)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        nxt_level <= 8'd0;
    else if(commit_calc) begin
        case(req_action)
            Make_and_Sell: nxt_level <= (ms_ok && upgrade_en) ? cur_level + 8'd1 : cur_level;
            Pay_Day: begin
                if(pd_balance_warn) nxt_level <= (cur_level < 8'd10) ? 8'd0 : (cur_level - 8'd10);
                else                nxt_level <= cur_level;
            end
            default: nxt_level <= cur_level;
        endcase
    end
    else                  nxt_level <= nxt_level;
end

//================================================================
// nxt_staff
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        nxt_staff <= 8'd0;
    else if(commit_calc) begin
        case(req_action)
            Hire_Staff: begin
                if(hs_no_warn || hs_staff_warn) nxt_staff <= cur_staff_dram + real_staff;
                else                            nxt_staff <= cur_staff_dram;
            end
            Pay_Day: begin
                if(pd_balance_warn) begin
                    if(cur_staff_dram <= 8'd1) nxt_staff <= 8'd1;
                    else                       nxt_staff <= cur_staff_dram >> 1;
                end
                else nxt_staff <= cur_staff_dram;
            end
            default: nxt_staff <= cur_staff_dram;
        endcase
    end
    else                  nxt_staff <= nxt_staff;
end

//================================================================
// nxt_balance (sat 24'hFFFFFF)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        nxt_balance <= 24'd0;
    else if(commit_calc) begin
        case(req_action)
            Make_and_Sell: begin
                if(ms_ok) nxt_balance <= balance_add_tmp[24] ? 24'hFFFFFF : balance_add_tmp[23:0];
                else      nxt_balance <= cur_balance;
            end
            Restock: begin
                if(rs_no_warn || rs_restock_warn) nxt_balance <= cur_balance - {4'b0, real_cost};
                else                              nxt_balance <= cur_balance;
            end
            Hire_Staff: begin
                if(hs_no_warn || hs_staff_warn) nxt_balance <= cur_balance - {5'b0, real_fee};
                else                            nxt_balance <= cur_balance;
            end
            Pay_Day: begin
                if(pd_no_warn) nxt_balance <= cur_balance - {1'b0, total_salary};
                else           nxt_balance <= cur_balance;
            end
            default: nxt_balance <= cur_balance;
        endcase
    end
    else                  nxt_balance <= nxt_balance;
end

//================================================================
// warn_msg_comb / warn_msg_r
//================================================================
always_comb begin
    if(!date_ok) warn_msg_comb = Date_Warn;
    else begin
        case(req_action)
        Make_and_Sell: begin
            if (ms_no_staff_warn) warn_msg_comb = No_Staff_Warn;
            else if (ms_stock_warn)    warn_msg_comb = Stock_Warn;
            else                       warn_msg_comb = No_Warn;
        end
        Restock: begin
            if (rs_balance_warn) warn_msg_comb = Balance_Warn;
            else if (rs_restock_warn) warn_msg_comb = Restock_Warn;
            else                      warn_msg_comb = No_Warn;
        end
        Hire_Staff: begin
            if (hs_balance_warn) warn_msg_comb = Balance_Warn;
            else if (hs_staff_warn)   warn_msg_comb = Staff_Warn;
            else                      warn_msg_comb = No_Warn;
        end
        Pay_Day: begin
            if (pd_no_staff_warn) warn_msg_comb = No_Staff_Warn;
            else if (pd_balance_warn)  warn_msg_comb = Balance_Warn;
            else                       warn_msg_comb = No_Warn;
        end
        default:          warn_msg_comb = No_Warn;
    endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)         warn_msg_r <= No_Warn;
    else if(commit_calc || state == S_PREP && !date_ok)   warn_msg_r <= warn_msg_comb;
    else if((state == S_READ) && dram_rvalid0 && early_date_warn) warn_msg_r <= Date_Warn;
    else                   warn_msg_r <= warn_msg_r;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)        complete_r <= 1'b0;
    else if(state == S_PREP && !date_ok) complete_r <= 1'b0;
    else if((state == S_READ) && dram_rvalid0 && early_date_warn) complete_r <= 1'b0;
    else if(commit_calc) begin
        case(req_action)
            Make_and_Sell:    complete_r <= ms_ok;
            Restock:          complete_r <= rs_no_warn;
            Hire_Staff:       complete_r <= hs_no_warn;
            Pay_Day:          complete_r <= pd_no_warn;
            Check_Valid_Date: complete_r <= date_ok;
            default:          complete_r <= 1'b0;
        endcase
    end
    else                  complete_r <= complete_r;
end

//================================================================
// pack write data
//================================================================
assign write_data0 = {nxt_flour, nxt_butter, 4'd0, nxt_month[3:0], nxt_milk, nxt_sugar, 3'd0, nxt_day[4:0]};
assign write_data1 = {nxt_fruit, nxt_sales, nxt_staff, nxt_balance, nxt_level};

//================================================================
// output
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.out_valid <= 1'b0; inf.warn_msg <= No_Warn; inf.complete <= 1'b0;
    end
    else if(state == S_FINISH) begin
        inf.out_valid <= 1'b1; inf.warn_msg <= warn_msg_r; inf.complete <= complete_r;
    end
    else begin
        inf.out_valid <= 1'b0; inf.warn_msg <= No_Warn; inf.complete <= 1'b0;
    end
end
// write once
logic only_write_date_c;
logic only_write_date;

assign only_write_date_c =
       (req_action == Check_Valid_Date) ||
       ((req_action == Make_and_Sell) && (ms_no_staff_warn || ms_stock_warn)) ||
       ((req_action == Restock)       && rs_balance_warn) ||
       ((req_action == Hire_Staff)    && hs_balance_warn) ||
       ((req_action == Pay_Day)       && pd_no_staff_warn);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        only_write_date <= 1'b0;
    end
    else if(state == S_COMMIT) begin
        only_write_date <= only_write_date_c;
    end
    else if(state == S_FINISH) begin
        only_write_date <= 1'b0;
    end
    else begin
        only_write_date <= only_write_date;
    end
end
//================================================================
// DRAM access submodules
//================================================================
// in_abort tells Read_DRAM "no second read needed" so it leaves R_DONE0.
//   - CVD path: state goes S_READ -> S_COMMIT, so abort at S_COMMIT
//   - date_warn path: state goes S_READ -> S_FINISH, so abort at S_FINISH
logic read_abort;
assign read_abort = (state == S_COMMIT) || (state == S_FINISH);

Read_DRAM u_read_dram (
    .clk(clk), .in_valid(read_start), .in_continue(read_continue), .in_abort(read_abort),
    .shop_data_no(req_data_no),
    .out_data0(dram_rdata0), .out_data1(dram_rdata1),
    .out_valid0(dram_rvalid0), .out_valid(dram_rvalid),
    .inf(inf)
);

Write_DRAM u_write_dram (
    .clk(clk), .in_valid(write_start), .out_valid(dram_wvalid),
    .shop_data_no(req_data_no), .in_data0(write_data0), .in_data1(write_data1), .only_write_date(only_write_date), .inf(inf)
);

endmodule


//================================================================
// 16x11 unsigned shift-add multiplier with configurable cycle count
//   cycle_n latched at mult_en, mult_done pulses at shift_cnt == cycle_n - 1
//================================================================
module mult_16bit_u(
    input              clk,
    input              rst_n,
    input              mult_en,
    input  [3:0]       cycle_n,
    input  [15:0]      A,
    input  [10:0]      B,
    output [22:0]      result,
    output reg      mult_done
);
    reg [3:0]  shift_cnt;
    reg        start_mult;
    reg [3:0]  cycle_n_r;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)        start_mult <= 1'b0;
        else if(mult_en)  start_mult <= 1'b1;
        else if(mult_done) start_mult <= 1'b0;
        else              start_mult <= start_mult;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)        shift_cnt <= 4'd0;
        else if(mult_en)  shift_cnt <= 4'd0;
        else if(start_mult) shift_cnt <= shift_cnt + 4'd1;
        else              shift_cnt <= 4'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)       cycle_n_r <= 4'd11;
        else if(mult_en) cycle_n_r <= cycle_n;
        else             cycle_n_r <= cycle_n_r;
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)        mult_done <= 1'b0;
        else mult_done <= (shift_cnt == cycle_n_r);
    end
    reg [22:0] shifted_A;
    reg [10:0] shift_B;
    reg [22:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shifted_A <= 23'd0; shift_B <= 11'd0; acc <= 23'd0;
        end
        else if(mult_en) begin
            shifted_A <= {7'b0, A} << 1;
            shift_B   <= {1'b0, B[10:1]};
            acc       <= B[0] ? {7'b0, A} : 23'd0;
        end
        else begin
            shifted_A <= shifted_A << 1;
            acc       <= shift_B[0] ? acc + shifted_A : acc;
            shift_B   <= {1'b0, shift_B[10:1]};
        end
    end

    assign result = acc;
endmodule
//================================================================
// Read_DRAM
//   - in_valid    : kick off first read
//   - in_continue : top says "do second read" (sampled at R_DONE0)
//   - in_abort    : top says "no second read needed" -> back to R_IDLE
//   - out_valid0  : pulses while first beat (rdata0) is captured & holding
//   - out_valid   : pulses one cycle when second beat (rdata1) is captured
//================================================================
module Read_DRAM
(
    clk,
    in_valid,
    in_continue,
    in_abort,
    shop_data_no,
    out_data0,
    out_data1,
    out_valid0,
    out_valid,
    inf
);
import usertype::*;

input  logic        clk;
input  logic        in_valid;
input  logic        in_continue;
input  logic        in_abort;
input  Data_No      shop_data_no;
output logic [63:0] out_data0;
output logic [63:0] out_data1;
output logic        out_valid0;
output logic        out_valid;
INF.DSS_inf         inf;

typedef enum logic [2:0] {
    R_IDLE   = 3'd0,
    R_REQ0   = 3'd1,
    R_WAIT0  = 3'd2,
    R_DONE0  = 3'd3,    // hold here until in_continue or in_abort
    R_REQ1   = 3'd4,
    R_WAIT1  = 3'd5,
    R_DONE   = 3'd6
} FSM_R;

FSM_R state, next_state;

logic [16:0] base_addr;
logic [16:0] base_addr_p8;
assign base_addr    = {1'b1, 5'd0, shop_data_no[6:0], 4'd0};
assign base_addr_p8 = {1'b1, 5'd0, shop_data_no[6:0], 4'd8};

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) state <= R_IDLE;
    else           state <= next_state;
end

always_comb begin
    case(state)
        R_IDLE:  next_state = in_valid                  ? R_REQ0   : R_IDLE;
        R_REQ0:  next_state = inf.AR_READY              ? R_WAIT0  : R_REQ0;
        R_WAIT0: next_state = inf.R_VALID               ? R_DONE0  : R_WAIT0;
        R_DONE0: begin
            if(in_continue)   next_state = R_REQ1;
            else if(in_abort) next_state = R_IDLE;
            else              next_state = R_DONE0;
        end
        R_REQ1:  next_state = inf.AR_READY              ? R_WAIT1  : R_REQ1;
        R_WAIT1: next_state = inf.R_VALID               ? R_DONE   : R_WAIT1;
        R_DONE:  next_state = R_IDLE;
        default: next_state = R_IDLE;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AR_VALID <= 1'b0;
        inf.AR_ADDR  <= 17'd0;
    end
    else if(state == R_IDLE && in_valid) begin
        inf.AR_VALID <= 1'b1;
        inf.AR_ADDR  <= base_addr;
    end
    else if(state == R_REQ0 && inf.AR_READY) begin
        inf.AR_VALID <= 1'b0;
        inf.AR_ADDR  <= 17'd0;
    end
    else if(state == R_DONE0 && in_continue) begin
        inf.AR_VALID <= 1'b1;
        inf.AR_ADDR  <= base_addr_p8;
    end
    else if(state == R_REQ1 && inf.AR_READY) begin
        inf.AR_VALID <= 1'b0;
        inf.AR_ADDR  <= 17'd0;
    end
    else begin
        inf.AR_VALID <= inf.AR_VALID;
        inf.AR_ADDR  <= inf.AR_ADDR;
    end
end

assign inf.R_READY = (state == R_WAIT0) || (state == R_WAIT1) ||
                     (state == R_REQ0)  || (state == R_REQ1);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)                                  out_data0 <= 64'd0;
    else if((state == R_WAIT0) && inf.R_VALID)      out_data0 <= inf.R_DATA;
    else                                             out_data0 <= out_data0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)                                  out_data1 <= 64'd0;
    else if((state == R_WAIT1) && inf.R_VALID)      out_data1 <= inf.R_DATA;
    else                                             out_data1 <= out_data1;
end

assign out_valid0 = (state == R_DONE0);
assign out_valid  = (state == R_DONE);

endmodule


//================================================================
// Write_DRAM
//================================================================
module Write_DRAM
(
    clk,
    in_valid,
    out_valid,
    shop_data_no,
    in_data0,
    in_data1,
    only_write_date,
    inf
);

input               clk, in_valid;
input        [7:0]  shop_data_no;
input        [63:0] in_data0;
input        [63:0] in_data1;
input               only_write_date;
output logic        out_valid;
INF.DSS_inf         inf;

typedef enum logic [1:0] {
    W_IDLE   = 2'd0,
    W_WRITE0 = 2'd1,
    W_WAIT0  = 2'd2
} FSM_W;

FSM_W state, next_state;

// base addresses as 17-bit wire concat
logic [16:0] base_addr_w;
logic [16:0] base_addr_w_p8;

assign base_addr_w    = {1'b1, 5'd0, shop_data_no[6:0], 4'd0};
assign base_addr_w_p8 = {1'b1, 5'd0, shop_data_no[6:0], 4'd8};

// transaction mode
logic only_write_date_r;

// 0: first beat, 1: second beat
logic aw_beat;
logic w_beat;
logic b_beat;

// channel done flags
logic aw_done;
logic w_done;
logic b_done;

// handshake wires
logic aw_hs;
logic w_hs;
logic b_hs;
logic final_b_hs;

assign aw_hs = inf.AW_VALID && inf.AW_READY;
assign w_hs  = inf.W_VALID  && inf.W_READY;
assign b_hs  = inf.B_READY  && inf.B_VALID;

// final B means:
// date-only: first B is final
// normal write: second B is final
assign final_b_hs = b_hs && (only_write_date_r || b_beat);

//============================================================
// FSM
//============================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) state <= W_IDLE;
    else           state <= next_state;
end

always_comb begin
    case(state)
        W_IDLE: begin
            next_state = in_valid ? W_WRITE0 : W_IDLE;
        end

        W_WRITE0: begin
            next_state = (aw_done && w_done) ? W_WAIT0 : W_WRITE0;
        end

        W_WAIT0: begin
            next_state = (b_done || final_b_hs) ? W_IDLE : W_WAIT0;
        end

        default: begin
            next_state = W_IDLE;
        end
    endcase
end

//============================================================
// latch transaction mode
//============================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        only_write_date_r <= 1'b0;
    end
    else if(state == W_IDLE && in_valid) begin
        only_write_date_r <= only_write_date;
    end
    else if(state == W_IDLE) begin
        only_write_date_r <= 1'b0;
    end
end

//============================================================
// AW channel
//============================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AW_VALID <= 1'b0;
        inf.AW_ADDR  <= 17'd0;
        aw_beat      <= 1'b0;
        aw_done      <= 1'b0;
    end
    else if(state == W_IDLE) begin
        aw_beat <= 1'b0;
        aw_done <= 1'b0;

        if(in_valid) begin
            inf.AW_VALID <= 1'b1;
            inf.AW_ADDR  <= base_addr_w;
        end
        else begin
            inf.AW_VALID <= 1'b0;
            inf.AW_ADDR  <= 17'd0;
        end
    end
    else if(state == W_WRITE0 && aw_hs) begin
        if(only_write_date_r || aw_beat) begin
            inf.AW_VALID <= 1'b0;
            inf.AW_ADDR  <= 17'd0;
            aw_done      <= 1'b1;
        end
        else begin
            inf.AW_VALID <= 1'b1;
            inf.AW_ADDR  <= base_addr_w_p8;
            aw_beat      <= 1'b1;
        end
    end
end

//============================================================
// W channel
//============================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.W_VALID <= 1'b0;
        inf.W_DATA  <= 64'd0;
        w_beat      <= 1'b0;
        w_done      <= 1'b0;
    end
    else if(state == W_IDLE) begin
        w_beat <= 1'b0;
        w_done <= 1'b0;

        if(in_valid) begin
            inf.W_VALID <= 1'b1;
            inf.W_DATA  <= in_data0;
        end
        else begin
            inf.W_VALID <= 1'b0;
            inf.W_DATA  <= 64'd0;
        end
    end
    else if(state == W_WRITE0 && w_hs) begin
        if(only_write_date_r || w_beat) begin
            inf.W_VALID <= 1'b0;
            inf.W_DATA  <= 64'd0;
            w_done      <= 1'b1;
        end
        else begin
            inf.W_VALID <= 1'b1;
            inf.W_DATA  <= in_data1;
            w_beat      <= 1'b1;
        end
    end
end

//============================================================
// B channel
//============================================================
assign inf.B_READY = (state == W_WRITE0) || (state == W_WAIT0);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        b_beat <= 1'b0;
        b_done <= 1'b0;
    end
    else if(state == W_IDLE) begin
        b_beat <= 1'b0;
        b_done <= 1'b0;
    end
    else if(b_hs) begin
        if(only_write_date_r || b_beat) begin
            b_done <= 1'b1;
        end
        else begin
            b_beat <= 1'b1;
        end
    end
end

assign out_valid = (state == W_WAIT0) && (b_done || final_b_hs);

endmodule

//================================================================
// LUT submodules (unchanged from previous version)
//================================================================

module DIV10_LUT(
    input  logic [7:0] level,
    output logic [3:0] lv10
);
    always_comb begin
        if      (level >= 8'd100) lv10 = 4'd10;
        else if (level >= 8'd90 ) lv10 = 4'd9;
        else if (level >= 8'd80 ) lv10 = 4'd8;
        else if (level >= 8'd70 ) lv10 = 4'd7;
        else if (level >= 8'd60 ) lv10 = 4'd6;
        else if (level >= 8'd50 ) lv10 = 4'd5;
        else if (level >= 8'd40 ) lv10 = 4'd4;
        else if (level >= 8'd30 ) lv10 = 4'd3;
        else if (level >= 8'd20 ) lv10 = 4'd2;
        else if (level >= 8'd10 ) lv10 = 4'd1;
        else                      lv10 = 4'd0;
    end
endmodule

module COST_FLOUR_LUT(
    input  logic [3:0]  lv10,
    output logic [4:0] cost
);
    always_comb case(lv10)
        4'd0:    cost = 5'd15;  4'd1:    cost = 5'd16;
        4'd2:    cost = 5'd18;  4'd3:    cost = 5'd19;
        4'd4:    cost = 5'd21;  4'd5:    cost = 5'd22;
        4'd6:    cost = 5'd24;  4'd7:    cost = 5'd25;
        4'd8:    cost = 5'd27;  4'd9:    cost = 5'd28;
        4'd10:   cost = 5'd30;  default: cost = 5'd15;
    endcase
endmodule

module COST_BUTTER_LUT(
    input  logic [3:0]  lv10,
    output logic [6:0] cost
);
    always_comb case(lv10)
        4'd0:    cost = 7'd60;   4'd1:    cost = 7'd66;
        4'd2:    cost = 7'd72;   4'd3:    cost = 7'd78;
        4'd4:    cost = 7'd84;   4'd5:    cost = 7'd90;
        4'd6:    cost = 7'd96;   4'd7:    cost = 7'd102;
        4'd8:    cost = 7'd108;  4'd9:    cost = 7'd114;
        4'd10:   cost = 7'd120;  default: cost = 7'd60;
    endcase
endmodule

module COST_MILK_LUT(
    input  logic [3:0]  lv10,
    output logic [5:0] cost
);
    always_comb case(lv10)
        4'd0:    cost = 6'd25;  4'd1:    cost = 6'd27;
        4'd2:    cost = 6'd30;  4'd3:    cost = 6'd32;
        4'd4:    cost = 6'd35;  4'd5:    cost = 6'd37;
        4'd6:    cost = 6'd40;  4'd7:    cost = 6'd42;
        4'd8:    cost = 6'd45;  4'd9:    cost = 6'd47;
        4'd10:   cost = 6'd50;  default: cost = 6'd25;
    endcase
endmodule

module COST_SUGAR_LUT(
    input  logic [3:0]  lv10,
    output logic [4:0] cost
);
    always_comb case(lv10)
        4'd0:    cost = 5'd10;  4'd1:    cost = 5'd11;
        4'd2:    cost = 5'd12;  4'd3:    cost = 5'd13;
        4'd4:    cost = 5'd14;  4'd5:    cost = 5'd15;
        4'd6:    cost = 5'd16;  4'd7:    cost = 5'd17;
        4'd8:    cost = 5'd18;  4'd9:    cost = 5'd19;
        4'd10:   cost = 5'd20;  default: cost = 5'd10;
    endcase
endmodule

module COST_FRUIT_LUT(
    input  logic [3:0]  lv10,
    output logic [7:0] cost
);
    always_comb case(lv10)
        4'd0:    cost = 8'd80;   4'd1:    cost = 8'd88;
        4'd2:    cost = 8'd96;   4'd3:    cost = 8'd104;
        4'd4:    cost = 8'd112;  4'd5:    cost = 8'd120;
        4'd6:    cost = 8'd128;  4'd7:    cost = 8'd136;
        4'd8:    cost = 8'd144;  4'd9:    cost = 8'd152;
        4'd10:   cost = 8'd160;  default: cost = 8'd80;
    endcase
endmodule

module THRESHOLD_LUT(
    input  logic [3:0]  lv10,
    output logic [6:0] threshold
);
    always_comb case(lv10)
        4'd0:    threshold = 7'd10;   4'd1:    threshold = 7'd10;
        4'd2:    threshold = 7'd20;   4'd3:    threshold = 7'd30;
        4'd4:    threshold = 7'd40;   4'd5:    threshold = 7'd50;
        4'd6:    threshold = 7'd60;   4'd7:    threshold = 7'd70;
        4'd8:    threshold = 7'd80;   4'd9:    threshold = 7'd90;
        4'd10:   threshold = 7'd100;  default: threshold = 7'd10;
    endcase
endmodule

//================================================================
// Direct lookup-table modules
//================================================================

module PRICE_LUT(
    input  logic [2:0] dessert,
    input  logic [7:0] level,
    output logic [9:0] price
);
    import usertype::*;

    always_comb begin
        case(Dessert_Type'(dessert))
            Cookie: begin
                case(level)
                    8'd0  : price = 10'd120;
                    8'd1  : price = 10'd120;
                    8'd2  : price = 10'd120;
                    8'd3  : price = 10'd120;
                    8'd4  : price = 10'd120;
                    8'd5  : price = 10'd120;
                    8'd6  : price = 10'd120;
                    8'd7  : price = 10'd120;
                    8'd8  : price = 10'd120;
                    8'd9  : price = 10'd120;
                    8'd10 : price = 10'd132;
                    8'd11 : price = 10'd132;
                    8'd12 : price = 10'd132;
                    8'd13 : price = 10'd132;
                    8'd14 : price = 10'd132;
                    8'd15 : price = 10'd133;
                    8'd16 : price = 10'd133;
                    8'd17 : price = 10'd133;
                    8'd18 : price = 10'd133;
                    8'd19 : price = 10'd133;
                    8'd20 : price = 10'd146;
                    8'd21 : price = 10'd146;
                    8'd22 : price = 10'd146;
                    8'd23 : price = 10'd146;
                    8'd24 : price = 10'd146;
                    8'd25 : price = 10'd147;
                    8'd26 : price = 10'd147;
                    8'd27 : price = 10'd147;
                    8'd28 : price = 10'd147;
                    8'd29 : price = 10'd148;
                    8'd30 : price = 10'd160;
                    8'd31 : price = 10'd160;
                    8'd32 : price = 10'd161;
                    8'd33 : price = 10'd161;
                    8'd34 : price = 10'd161;
                    8'd35 : price = 10'd162;
                    8'd36 : price = 10'd162;
                    8'd37 : price = 10'd162;
                    8'd38 : price = 10'd163;
                    8'd39 : price = 10'd163;
                    8'd40 : price = 10'd176;
                    8'd41 : price = 10'd176;
                    8'd42 : price = 10'd176;
                    8'd43 : price = 10'd177;
                    8'd44 : price = 10'd177;
                    8'd45 : price = 10'd178;
                    8'd46 : price = 10'd178;
                    8'd47 : price = 10'd179;
                    8'd48 : price = 10'd179;
                    8'd49 : price = 10'd180;
                    8'd50 : price = 10'd192;
                    8'd51 : price = 10'd193;
                    8'd52 : price = 10'd193;
                    8'd53 : price = 10'd194;
                    8'd54 : price = 10'd194;
                    8'd55 : price = 10'd195;
                    8'd56 : price = 10'd195;
                    8'd57 : price = 10'd196;
                    8'd58 : price = 10'd196;
                    8'd59 : price = 10'd197;
                    8'd60 : price = 10'd210;
                    8'd61 : price = 10'd210;
                    8'd62 : price = 10'd211;
                    8'd63 : price = 10'd211;
                    8'd64 : price = 10'd212;
                    8'd65 : price = 10'd213;
                    8'd66 : price = 10'd213;
                    8'd67 : price = 10'd214;
                    8'd68 : price = 10'd215;
                    8'd69 : price = 10'd215;
                    8'd70 : price = 10'd228;
                    8'd71 : price = 10'd229;
                    8'd72 : price = 10'd229;
                    8'd73 : price = 10'd230;
                    8'd74 : price = 10'd231;
                    8'd75 : price = 10'd232;
                    8'd76 : price = 10'd232;
                    8'd77 : price = 10'd233;
                    8'd78 : price = 10'd234;
                    8'd79 : price = 10'd235;
                    8'd80 : price = 10'd248;
                    8'd81 : price = 10'd248;
                    8'd82 : price = 10'd249;
                    8'd83 : price = 10'd250;
                    8'd84 : price = 10'd251;
                    8'd85 : price = 10'd252;
                    8'd86 : price = 10'd252;
                    8'd87 : price = 10'd253;
                    8'd88 : price = 10'd254;
                    8'd89 : price = 10'd255;
                    8'd90 : price = 10'd268;
                    8'd91 : price = 10'd269;
                    8'd92 : price = 10'd270;
                    8'd93 : price = 10'd271;
                    8'd94 : price = 10'd272;
                    8'd95 : price = 10'd273;
                    8'd96 : price = 10'd274;
                    8'd97 : price = 10'd275;
                    8'd98 : price = 10'd276;
                    8'd99 : price = 10'd277;
                    8'd100: price = 10'd290;
                    default: price = 10'd120;
                endcase
            end
            Bread: begin
                case(level)
                    8'd0  : price = 10'd100;
                    8'd1  : price = 10'd100;
                    8'd2  : price = 10'd100;
                    8'd3  : price = 10'd100;
                    8'd4  : price = 10'd100;
                    8'd5  : price = 10'd100;
                    8'd6  : price = 10'd100;
                    8'd7  : price = 10'd100;
                    8'd8  : price = 10'd100;
                    8'd9  : price = 10'd100;
                    8'd10 : price = 10'd110;
                    8'd11 : price = 10'd110;
                    8'd12 : price = 10'd110;
                    8'd13 : price = 10'd110;
                    8'd14 : price = 10'd110;
                    8'd15 : price = 10'd111;
                    8'd16 : price = 10'd111;
                    8'd17 : price = 10'd111;
                    8'd18 : price = 10'd111;
                    8'd19 : price = 10'd111;
                    8'd20 : price = 10'd122;
                    8'd21 : price = 10'd122;
                    8'd22 : price = 10'd122;
                    8'd23 : price = 10'd122;
                    8'd24 : price = 10'd122;
                    8'd25 : price = 10'd123;
                    8'd26 : price = 10'd123;
                    8'd27 : price = 10'd123;
                    8'd28 : price = 10'd123;
                    8'd29 : price = 10'd124;
                    8'd30 : price = 10'd134;
                    8'd31 : price = 10'd134;
                    8'd32 : price = 10'd135;
                    8'd33 : price = 10'd135;
                    8'd34 : price = 10'd135;
                    8'd35 : price = 10'd136;
                    8'd36 : price = 10'd136;
                    8'd37 : price = 10'd136;
                    8'd38 : price = 10'd137;
                    8'd39 : price = 10'd137;
                    8'd40 : price = 10'd148;
                    8'd41 : price = 10'd148;
                    8'd42 : price = 10'd148;
                    8'd43 : price = 10'd149;
                    8'd44 : price = 10'd149;
                    8'd45 : price = 10'd150;
                    8'd46 : price = 10'd150;
                    8'd47 : price = 10'd151;
                    8'd48 : price = 10'd151;
                    8'd49 : price = 10'd152;
                    8'd50 : price = 10'd162;
                    8'd51 : price = 10'd163;
                    8'd52 : price = 10'd163;
                    8'd53 : price = 10'd164;
                    8'd54 : price = 10'd164;
                    8'd55 : price = 10'd165;
                    8'd56 : price = 10'd165;
                    8'd57 : price = 10'd166;
                    8'd58 : price = 10'd166;
                    8'd59 : price = 10'd167;
                    8'd60 : price = 10'd178;
                    8'd61 : price = 10'd178;
                    8'd62 : price = 10'd179;
                    8'd63 : price = 10'd179;
                    8'd64 : price = 10'd180;
                    8'd65 : price = 10'd181;
                    8'd66 : price = 10'd181;
                    8'd67 : price = 10'd182;
                    8'd68 : price = 10'd183;
                    8'd69 : price = 10'd183;
                    8'd70 : price = 10'd194;
                    8'd71 : price = 10'd195;
                    8'd72 : price = 10'd195;
                    8'd73 : price = 10'd196;
                    8'd74 : price = 10'd197;
                    8'd75 : price = 10'd198;
                    8'd76 : price = 10'd198;
                    8'd77 : price = 10'd199;
                    8'd78 : price = 10'd200;
                    8'd79 : price = 10'd201;
                    8'd80 : price = 10'd212;
                    8'd81 : price = 10'd212;
                    8'd82 : price = 10'd213;
                    8'd83 : price = 10'd214;
                    8'd84 : price = 10'd215;
                    8'd85 : price = 10'd216;
                    8'd86 : price = 10'd216;
                    8'd87 : price = 10'd217;
                    8'd88 : price = 10'd218;
                    8'd89 : price = 10'd219;
                    8'd90 : price = 10'd230;
                    8'd91 : price = 10'd231;
                    8'd92 : price = 10'd232;
                    8'd93 : price = 10'd233;
                    8'd94 : price = 10'd234;
                    8'd95 : price = 10'd235;
                    8'd96 : price = 10'd236;
                    8'd97 : price = 10'd237;
                    8'd98 : price = 10'd238;
                    8'd99 : price = 10'd239;
                    8'd100: price = 10'd250;
                    default: price = 10'd100;
                endcase
            end
            Fruit_Cake: begin
                case(level)
                    8'd0  : price = 10'd400;
                    8'd1  : price = 10'd400;
                    8'd2  : price = 10'd400;
                    8'd3  : price = 10'd400;
                    8'd4  : price = 10'd400;
                    8'd5  : price = 10'd400;
                    8'd6  : price = 10'd400;
                    8'd7  : price = 10'd400;
                    8'd8  : price = 10'd400;
                    8'd9  : price = 10'd400;
                    8'd10 : price = 10'd440;
                    8'd11 : price = 10'd440;
                    8'd12 : price = 10'd440;
                    8'd13 : price = 10'd440;
                    8'd14 : price = 10'd440;
                    8'd15 : price = 10'd441;
                    8'd16 : price = 10'd441;
                    8'd17 : price = 10'd441;
                    8'd18 : price = 10'd441;
                    8'd19 : price = 10'd441;
                    8'd20 : price = 10'd482;
                    8'd21 : price = 10'd482;
                    8'd22 : price = 10'd482;
                    8'd23 : price = 10'd482;
                    8'd24 : price = 10'd482;
                    8'd25 : price = 10'd483;
                    8'd26 : price = 10'd483;
                    8'd27 : price = 10'd483;
                    8'd28 : price = 10'd483;
                    8'd29 : price = 10'd484;
                    8'd30 : price = 10'd524;
                    8'd31 : price = 10'd524;
                    8'd32 : price = 10'd525;
                    8'd33 : price = 10'd525;
                    8'd34 : price = 10'd525;
                    8'd35 : price = 10'd526;
                    8'd36 : price = 10'd526;
                    8'd37 : price = 10'd526;
                    8'd38 : price = 10'd527;
                    8'd39 : price = 10'd527;
                    8'd40 : price = 10'd568;
                    8'd41 : price = 10'd568;
                    8'd42 : price = 10'd568;
                    8'd43 : price = 10'd569;
                    8'd44 : price = 10'd569;
                    8'd45 : price = 10'd570;
                    8'd46 : price = 10'd570;
                    8'd47 : price = 10'd571;
                    8'd48 : price = 10'd571;
                    8'd49 : price = 10'd572;
                    8'd50 : price = 10'd612;
                    8'd51 : price = 10'd613;
                    8'd52 : price = 10'd613;
                    8'd53 : price = 10'd614;
                    8'd54 : price = 10'd614;
                    8'd55 : price = 10'd615;
                    8'd56 : price = 10'd615;
                    8'd57 : price = 10'd616;
                    8'd58 : price = 10'd616;
                    8'd59 : price = 10'd617;
                    8'd60 : price = 10'd658;
                    8'd61 : price = 10'd658;
                    8'd62 : price = 10'd659;
                    8'd63 : price = 10'd659;
                    8'd64 : price = 10'd660;
                    8'd65 : price = 10'd661;
                    8'd66 : price = 10'd661;
                    8'd67 : price = 10'd662;
                    8'd68 : price = 10'd663;
                    8'd69 : price = 10'd663;
                    8'd70 : price = 10'd704;
                    8'd71 : price = 10'd705;
                    8'd72 : price = 10'd705;
                    8'd73 : price = 10'd706;
                    8'd74 : price = 10'd707;
                    8'd75 : price = 10'd708;
                    8'd76 : price = 10'd708;
                    8'd77 : price = 10'd709;
                    8'd78 : price = 10'd710;
                    8'd79 : price = 10'd711;
                    8'd80 : price = 10'd752;
                    8'd81 : price = 10'd752;
                    8'd82 : price = 10'd753;
                    8'd83 : price = 10'd754;
                    8'd84 : price = 10'd755;
                    8'd85 : price = 10'd756;
                    8'd86 : price = 10'd756;
                    8'd87 : price = 10'd757;
                    8'd88 : price = 10'd758;
                    8'd89 : price = 10'd759;
                    8'd90 : price = 10'd800;
                    8'd91 : price = 10'd801;
                    8'd92 : price = 10'd802;
                    8'd93 : price = 10'd803;
                    8'd94 : price = 10'd804;
                    8'd95 : price = 10'd805;
                    8'd96 : price = 10'd806;
                    8'd97 : price = 10'd807;
                    8'd98 : price = 10'd808;
                    8'd99 : price = 10'd809;
                    8'd100: price = 10'd850;
                    default: price = 10'd400;
                endcase
            end
            Pudding: begin
                case(level)
                    8'd0  : price = 10'd180;
                    8'd1  : price = 10'd180;
                    8'd2  : price = 10'd180;
                    8'd3  : price = 10'd180;
                    8'd4  : price = 10'd180;
                    8'd5  : price = 10'd180;
                    8'd6  : price = 10'd180;
                    8'd7  : price = 10'd180;
                    8'd8  : price = 10'd180;
                    8'd9  : price = 10'd180;
                    8'd10 : price = 10'd198;
                    8'd11 : price = 10'd198;
                    8'd12 : price = 10'd198;
                    8'd13 : price = 10'd198;
                    8'd14 : price = 10'd198;
                    8'd15 : price = 10'd199;
                    8'd16 : price = 10'd199;
                    8'd17 : price = 10'd199;
                    8'd18 : price = 10'd199;
                    8'd19 : price = 10'd199;
                    8'd20 : price = 10'd218;
                    8'd21 : price = 10'd218;
                    8'd22 : price = 10'd218;
                    8'd23 : price = 10'd218;
                    8'd24 : price = 10'd218;
                    8'd25 : price = 10'd219;
                    8'd26 : price = 10'd219;
                    8'd27 : price = 10'd219;
                    8'd28 : price = 10'd219;
                    8'd29 : price = 10'd220;
                    8'd30 : price = 10'd238;
                    8'd31 : price = 10'd238;
                    8'd32 : price = 10'd239;
                    8'd33 : price = 10'd239;
                    8'd34 : price = 10'd239;
                    8'd35 : price = 10'd240;
                    8'd36 : price = 10'd240;
                    8'd37 : price = 10'd240;
                    8'd38 : price = 10'd241;
                    8'd39 : price = 10'd241;
                    8'd40 : price = 10'd260;
                    8'd41 : price = 10'd260;
                    8'd42 : price = 10'd260;
                    8'd43 : price = 10'd261;
                    8'd44 : price = 10'd261;
                    8'd45 : price = 10'd262;
                    8'd46 : price = 10'd262;
                    8'd47 : price = 10'd263;
                    8'd48 : price = 10'd263;
                    8'd49 : price = 10'd264;
                    8'd50 : price = 10'd282;
                    8'd51 : price = 10'd283;
                    8'd52 : price = 10'd283;
                    8'd53 : price = 10'd284;
                    8'd54 : price = 10'd284;
                    8'd55 : price = 10'd285;
                    8'd56 : price = 10'd285;
                    8'd57 : price = 10'd286;
                    8'd58 : price = 10'd286;
                    8'd59 : price = 10'd287;
                    8'd60 : price = 10'd306;
                    8'd61 : price = 10'd306;
                    8'd62 : price = 10'd307;
                    8'd63 : price = 10'd307;
                    8'd64 : price = 10'd308;
                    8'd65 : price = 10'd309;
                    8'd66 : price = 10'd309;
                    8'd67 : price = 10'd310;
                    8'd68 : price = 10'd311;
                    8'd69 : price = 10'd311;
                    8'd70 : price = 10'd330;
                    8'd71 : price = 10'd331;
                    8'd72 : price = 10'd331;
                    8'd73 : price = 10'd332;
                    8'd74 : price = 10'd333;
                    8'd75 : price = 10'd334;
                    8'd76 : price = 10'd334;
                    8'd77 : price = 10'd335;
                    8'd78 : price = 10'd336;
                    8'd79 : price = 10'd337;
                    8'd80 : price = 10'd356;
                    8'd81 : price = 10'd356;
                    8'd82 : price = 10'd357;
                    8'd83 : price = 10'd358;
                    8'd84 : price = 10'd359;
                    8'd85 : price = 10'd360;
                    8'd86 : price = 10'd360;
                    8'd87 : price = 10'd361;
                    8'd88 : price = 10'd362;
                    8'd89 : price = 10'd363;
                    8'd90 : price = 10'd382;
                    8'd91 : price = 10'd383;
                    8'd92 : price = 10'd384;
                    8'd93 : price = 10'd385;
                    8'd94 : price = 10'd386;
                    8'd95 : price = 10'd387;
                    8'd96 : price = 10'd388;
                    8'd97 : price = 10'd389;
                    8'd98 : price = 10'd390;
                    8'd99 : price = 10'd391;
                    8'd100: price = 10'd410;
                    default: price = 10'd180;
                endcase
            end
            Macaron: begin
                case(level)
                    8'd0  : price = 10'd250;
                    8'd1  : price = 10'd250;
                    8'd2  : price = 10'd250;
                    8'd3  : price = 10'd250;
                    8'd4  : price = 10'd250;
                    8'd5  : price = 10'd250;
                    8'd6  : price = 10'd250;
                    8'd7  : price = 10'd250;
                    8'd8  : price = 10'd250;
                    8'd9  : price = 10'd250;
                    8'd10 : price = 10'd275;
                    8'd11 : price = 10'd275;
                    8'd12 : price = 10'd275;
                    8'd13 : price = 10'd275;
                    8'd14 : price = 10'd275;
                    8'd15 : price = 10'd276;
                    8'd16 : price = 10'd276;
                    8'd17 : price = 10'd276;
                    8'd18 : price = 10'd276;
                    8'd19 : price = 10'd276;
                    8'd20 : price = 10'd302;
                    8'd21 : price = 10'd302;
                    8'd22 : price = 10'd302;
                    8'd23 : price = 10'd302;
                    8'd24 : price = 10'd302;
                    8'd25 : price = 10'd303;
                    8'd26 : price = 10'd303;
                    8'd27 : price = 10'd303;
                    8'd28 : price = 10'd303;
                    8'd29 : price = 10'd304;
                    8'd30 : price = 10'd329;
                    8'd31 : price = 10'd329;
                    8'd32 : price = 10'd330;
                    8'd33 : price = 10'd330;
                    8'd34 : price = 10'd330;
                    8'd35 : price = 10'd331;
                    8'd36 : price = 10'd331;
                    8'd37 : price = 10'd331;
                    8'd38 : price = 10'd332;
                    8'd39 : price = 10'd332;
                    8'd40 : price = 10'd358;
                    8'd41 : price = 10'd358;
                    8'd42 : price = 10'd358;
                    8'd43 : price = 10'd359;
                    8'd44 : price = 10'd359;
                    8'd45 : price = 10'd360;
                    8'd46 : price = 10'd360;
                    8'd47 : price = 10'd361;
                    8'd48 : price = 10'd361;
                    8'd49 : price = 10'd362;
                    8'd50 : price = 10'd387;
                    8'd51 : price = 10'd388;
                    8'd52 : price = 10'd388;
                    8'd53 : price = 10'd389;
                    8'd54 : price = 10'd389;
                    8'd55 : price = 10'd390;
                    8'd56 : price = 10'd390;
                    8'd57 : price = 10'd391;
                    8'd58 : price = 10'd391;
                    8'd59 : price = 10'd392;
                    8'd60 : price = 10'd418;
                    8'd61 : price = 10'd418;
                    8'd62 : price = 10'd419;
                    8'd63 : price = 10'd419;
                    8'd64 : price = 10'd420;
                    8'd65 : price = 10'd421;
                    8'd66 : price = 10'd421;
                    8'd67 : price = 10'd422;
                    8'd68 : price = 10'd423;
                    8'd69 : price = 10'd423;
                    8'd70 : price = 10'd449;
                    8'd71 : price = 10'd450;
                    8'd72 : price = 10'd450;
                    8'd73 : price = 10'd451;
                    8'd74 : price = 10'd452;
                    8'd75 : price = 10'd453;
                    8'd76 : price = 10'd453;
                    8'd77 : price = 10'd454;
                    8'd78 : price = 10'd455;
                    8'd79 : price = 10'd456;
                    8'd80 : price = 10'd482;
                    8'd81 : price = 10'd482;
                    8'd82 : price = 10'd483;
                    8'd83 : price = 10'd484;
                    8'd84 : price = 10'd485;
                    8'd85 : price = 10'd486;
                    8'd86 : price = 10'd486;
                    8'd87 : price = 10'd487;
                    8'd88 : price = 10'd488;
                    8'd89 : price = 10'd489;
                    8'd90 : price = 10'd515;
                    8'd91 : price = 10'd516;
                    8'd92 : price = 10'd517;
                    8'd93 : price = 10'd518;
                    8'd94 : price = 10'd519;
                    8'd95 : price = 10'd520;
                    8'd96 : price = 10'd521;
                    8'd97 : price = 10'd522;
                    8'd98 : price = 10'd523;
                    8'd99 : price = 10'd524;
                    8'd100: price = 10'd550;
                    default: price = 10'd250;
                endcase
            end
            Pancake: begin
                case(level)
                    8'd0  : price = 10'd200;
                    8'd1  : price = 10'd200;
                    8'd2  : price = 10'd200;
                    8'd3  : price = 10'd200;
                    8'd4  : price = 10'd200;
                    8'd5  : price = 10'd200;
                    8'd6  : price = 10'd200;
                    8'd7  : price = 10'd200;
                    8'd8  : price = 10'd200;
                    8'd9  : price = 10'd200;
                    8'd10 : price = 10'd220;
                    8'd11 : price = 10'd220;
                    8'd12 : price = 10'd220;
                    8'd13 : price = 10'd220;
                    8'd14 : price = 10'd220;
                    8'd15 : price = 10'd221;
                    8'd16 : price = 10'd221;
                    8'd17 : price = 10'd221;
                    8'd18 : price = 10'd221;
                    8'd19 : price = 10'd221;
                    8'd20 : price = 10'd242;
                    8'd21 : price = 10'd242;
                    8'd22 : price = 10'd242;
                    8'd23 : price = 10'd242;
                    8'd24 : price = 10'd242;
                    8'd25 : price = 10'd243;
                    8'd26 : price = 10'd243;
                    8'd27 : price = 10'd243;
                    8'd28 : price = 10'd243;
                    8'd29 : price = 10'd244;
                    8'd30 : price = 10'd264;
                    8'd31 : price = 10'd264;
                    8'd32 : price = 10'd265;
                    8'd33 : price = 10'd265;
                    8'd34 : price = 10'd265;
                    8'd35 : price = 10'd266;
                    8'd36 : price = 10'd266;
                    8'd37 : price = 10'd266;
                    8'd38 : price = 10'd267;
                    8'd39 : price = 10'd267;
                    8'd40 : price = 10'd288;
                    8'd41 : price = 10'd288;
                    8'd42 : price = 10'd288;
                    8'd43 : price = 10'd289;
                    8'd44 : price = 10'd289;
                    8'd45 : price = 10'd290;
                    8'd46 : price = 10'd290;
                    8'd47 : price = 10'd291;
                    8'd48 : price = 10'd291;
                    8'd49 : price = 10'd292;
                    8'd50 : price = 10'd312;
                    8'd51 : price = 10'd313;
                    8'd52 : price = 10'd313;
                    8'd53 : price = 10'd314;
                    8'd54 : price = 10'd314;
                    8'd55 : price = 10'd315;
                    8'd56 : price = 10'd315;
                    8'd57 : price = 10'd316;
                    8'd58 : price = 10'd316;
                    8'd59 : price = 10'd317;
                    8'd60 : price = 10'd338;
                    8'd61 : price = 10'd338;
                    8'd62 : price = 10'd339;
                    8'd63 : price = 10'd339;
                    8'd64 : price = 10'd340;
                    8'd65 : price = 10'd341;
                    8'd66 : price = 10'd341;
                    8'd67 : price = 10'd342;
                    8'd68 : price = 10'd343;
                    8'd69 : price = 10'd343;
                    8'd70 : price = 10'd364;
                    8'd71 : price = 10'd365;
                    8'd72 : price = 10'd365;
                    8'd73 : price = 10'd366;
                    8'd74 : price = 10'd367;
                    8'd75 : price = 10'd368;
                    8'd76 : price = 10'd368;
                    8'd77 : price = 10'd369;
                    8'd78 : price = 10'd370;
                    8'd79 : price = 10'd371;
                    8'd80 : price = 10'd392;
                    8'd81 : price = 10'd392;
                    8'd82 : price = 10'd393;
                    8'd83 : price = 10'd394;
                    8'd84 : price = 10'd395;
                    8'd85 : price = 10'd396;
                    8'd86 : price = 10'd396;
                    8'd87 : price = 10'd397;
                    8'd88 : price = 10'd398;
                    8'd89 : price = 10'd399;
                    8'd90 : price = 10'd420;
                    8'd91 : price = 10'd421;
                    8'd92 : price = 10'd422;
                    8'd93 : price = 10'd423;
                    8'd94 : price = 10'd424;
                    8'd95 : price = 10'd425;
                    8'd96 : price = 10'd426;
                    8'd97 : price = 10'd427;
                    8'd98 : price = 10'd428;
                    8'd99 : price = 10'd429;
                    8'd100: price = 10'd450;
                    default: price = 10'd200;
                endcase
            end
            Brownie: begin
                case(level)
                    8'd0  : price = 10'd280;
                    8'd1  : price = 10'd280;
                    8'd2  : price = 10'd280;
                    8'd3  : price = 10'd280;
                    8'd4  : price = 10'd280;
                    8'd5  : price = 10'd280;
                    8'd6  : price = 10'd280;
                    8'd7  : price = 10'd280;
                    8'd8  : price = 10'd280;
                    8'd9  : price = 10'd280;
                    8'd10 : price = 10'd308;
                    8'd11 : price = 10'd308;
                    8'd12 : price = 10'd308;
                    8'd13 : price = 10'd308;
                    8'd14 : price = 10'd308;
                    8'd15 : price = 10'd309;
                    8'd16 : price = 10'd309;
                    8'd17 : price = 10'd309;
                    8'd18 : price = 10'd309;
                    8'd19 : price = 10'd309;
                    8'd20 : price = 10'd338;
                    8'd21 : price = 10'd338;
                    8'd22 : price = 10'd338;
                    8'd23 : price = 10'd338;
                    8'd24 : price = 10'd338;
                    8'd25 : price = 10'd339;
                    8'd26 : price = 10'd339;
                    8'd27 : price = 10'd339;
                    8'd28 : price = 10'd339;
                    8'd29 : price = 10'd340;
                    8'd30 : price = 10'd368;
                    8'd31 : price = 10'd368;
                    8'd32 : price = 10'd369;
                    8'd33 : price = 10'd369;
                    8'd34 : price = 10'd369;
                    8'd35 : price = 10'd370;
                    8'd36 : price = 10'd370;
                    8'd37 : price = 10'd370;
                    8'd38 : price = 10'd371;
                    8'd39 : price = 10'd371;
                    8'd40 : price = 10'd400;
                    8'd41 : price = 10'd400;
                    8'd42 : price = 10'd400;
                    8'd43 : price = 10'd401;
                    8'd44 : price = 10'd401;
                    8'd45 : price = 10'd402;
                    8'd46 : price = 10'd402;
                    8'd47 : price = 10'd403;
                    8'd48 : price = 10'd403;
                    8'd49 : price = 10'd404;
                    8'd50 : price = 10'd432;
                    8'd51 : price = 10'd433;
                    8'd52 : price = 10'd433;
                    8'd53 : price = 10'd434;
                    8'd54 : price = 10'd434;
                    8'd55 : price = 10'd435;
                    8'd56 : price = 10'd435;
                    8'd57 : price = 10'd436;
                    8'd58 : price = 10'd436;
                    8'd59 : price = 10'd437;
                    8'd60 : price = 10'd466;
                    8'd61 : price = 10'd466;
                    8'd62 : price = 10'd467;
                    8'd63 : price = 10'd467;
                    8'd64 : price = 10'd468;
                    8'd65 : price = 10'd469;
                    8'd66 : price = 10'd469;
                    8'd67 : price = 10'd470;
                    8'd68 : price = 10'd471;
                    8'd69 : price = 10'd471;
                    8'd70 : price = 10'd500;
                    8'd71 : price = 10'd501;
                    8'd72 : price = 10'd501;
                    8'd73 : price = 10'd502;
                    8'd74 : price = 10'd503;
                    8'd75 : price = 10'd504;
                    8'd76 : price = 10'd504;
                    8'd77 : price = 10'd505;
                    8'd78 : price = 10'd506;
                    8'd79 : price = 10'd507;
                    8'd80 : price = 10'd536;
                    8'd81 : price = 10'd536;
                    8'd82 : price = 10'd537;
                    8'd83 : price = 10'd538;
                    8'd84 : price = 10'd539;
                    8'd85 : price = 10'd540;
                    8'd86 : price = 10'd540;
                    8'd87 : price = 10'd541;
                    8'd88 : price = 10'd542;
                    8'd89 : price = 10'd543;
                    8'd90 : price = 10'd572;
                    8'd91 : price = 10'd573;
                    8'd92 : price = 10'd574;
                    8'd93 : price = 10'd575;
                    8'd94 : price = 10'd576;
                    8'd95 : price = 10'd577;
                    8'd96 : price = 10'd578;
                    8'd97 : price = 10'd579;
                    8'd98 : price = 10'd580;
                    8'd99 : price = 10'd581;
                    8'd100: price = 10'd610;
                    default: price = 10'd280;
                endcase
            end
            Scone: begin
                case(level)
                    8'd0  : price = 10'd160;
                    8'd1  : price = 10'd160;
                    8'd2  : price = 10'd160;
                    8'd3  : price = 10'd160;
                    8'd4  : price = 10'd160;
                    8'd5  : price = 10'd160;
                    8'd6  : price = 10'd160;
                    8'd7  : price = 10'd160;
                    8'd8  : price = 10'd160;
                    8'd9  : price = 10'd160;
                    8'd10 : price = 10'd176;
                    8'd11 : price = 10'd176;
                    8'd12 : price = 10'd176;
                    8'd13 : price = 10'd176;
                    8'd14 : price = 10'd176;
                    8'd15 : price = 10'd177;
                    8'd16 : price = 10'd177;
                    8'd17 : price = 10'd177;
                    8'd18 : price = 10'd177;
                    8'd19 : price = 10'd177;
                    8'd20 : price = 10'd194;
                    8'd21 : price = 10'd194;
                    8'd22 : price = 10'd194;
                    8'd23 : price = 10'd194;
                    8'd24 : price = 10'd194;
                    8'd25 : price = 10'd195;
                    8'd26 : price = 10'd195;
                    8'd27 : price = 10'd195;
                    8'd28 : price = 10'd195;
                    8'd29 : price = 10'd196;
                    8'd30 : price = 10'd212;
                    8'd31 : price = 10'd212;
                    8'd32 : price = 10'd213;
                    8'd33 : price = 10'd213;
                    8'd34 : price = 10'd213;
                    8'd35 : price = 10'd214;
                    8'd36 : price = 10'd214;
                    8'd37 : price = 10'd214;
                    8'd38 : price = 10'd215;
                    8'd39 : price = 10'd215;
                    8'd40 : price = 10'd232;
                    8'd41 : price = 10'd232;
                    8'd42 : price = 10'd232;
                    8'd43 : price = 10'd233;
                    8'd44 : price = 10'd233;
                    8'd45 : price = 10'd234;
                    8'd46 : price = 10'd234;
                    8'd47 : price = 10'd235;
                    8'd48 : price = 10'd235;
                    8'd49 : price = 10'd236;
                    8'd50 : price = 10'd252;
                    8'd51 : price = 10'd253;
                    8'd52 : price = 10'd253;
                    8'd53 : price = 10'd254;
                    8'd54 : price = 10'd254;
                    8'd55 : price = 10'd255;
                    8'd56 : price = 10'd255;
                    8'd57 : price = 10'd256;
                    8'd58 : price = 10'd256;
                    8'd59 : price = 10'd257;
                    8'd60 : price = 10'd274;
                    8'd61 : price = 10'd274;
                    8'd62 : price = 10'd275;
                    8'd63 : price = 10'd275;
                    8'd64 : price = 10'd276;
                    8'd65 : price = 10'd277;
                    8'd66 : price = 10'd277;
                    8'd67 : price = 10'd278;
                    8'd68 : price = 10'd279;
                    8'd69 : price = 10'd279;
                    8'd70 : price = 10'd296;
                    8'd71 : price = 10'd297;
                    8'd72 : price = 10'd297;
                    8'd73 : price = 10'd298;
                    8'd74 : price = 10'd299;
                    8'd75 : price = 10'd300;
                    8'd76 : price = 10'd300;
                    8'd77 : price = 10'd301;
                    8'd78 : price = 10'd302;
                    8'd79 : price = 10'd303;
                    8'd80 : price = 10'd320;
                    8'd81 : price = 10'd320;
                    8'd82 : price = 10'd321;
                    8'd83 : price = 10'd322;
                    8'd84 : price = 10'd323;
                    8'd85 : price = 10'd324;
                    8'd86 : price = 10'd324;
                    8'd87 : price = 10'd325;
                    8'd88 : price = 10'd326;
                    8'd89 : price = 10'd327;
                    8'd90 : price = 10'd344;
                    8'd91 : price = 10'd345;
                    8'd92 : price = 10'd346;
                    8'd93 : price = 10'd347;
                    8'd94 : price = 10'd348;
                    8'd95 : price = 10'd349;
                    8'd96 : price = 10'd350;
                    8'd97 : price = 10'd351;
                    8'd98 : price = 10'd352;
                    8'd99 : price = 10'd353;
                    8'd100: price = 10'd370;
                    default: price = 10'd160;
                endcase
            end
            default: begin
                case(level)
                    8'd0  : price = 10'd120;
                    8'd1  : price = 10'd120;
                    8'd2  : price = 10'd120;
                    8'd3  : price = 10'd120;
                    8'd4  : price = 10'd120;
                    8'd5  : price = 10'd120;
                    8'd6  : price = 10'd120;
                    8'd7  : price = 10'd120;
                    8'd8  : price = 10'd120;
                    8'd9  : price = 10'd120;
                    8'd10 : price = 10'd132;
                    8'd11 : price = 10'd132;
                    8'd12 : price = 10'd132;
                    8'd13 : price = 10'd132;
                    8'd14 : price = 10'd132;
                    8'd15 : price = 10'd133;
                    8'd16 : price = 10'd133;
                    8'd17 : price = 10'd133;
                    8'd18 : price = 10'd133;
                    8'd19 : price = 10'd133;
                    8'd20 : price = 10'd146;
                    8'd21 : price = 10'd146;
                    8'd22 : price = 10'd146;
                    8'd23 : price = 10'd146;
                    8'd24 : price = 10'd146;
                    8'd25 : price = 10'd147;
                    8'd26 : price = 10'd147;
                    8'd27 : price = 10'd147;
                    8'd28 : price = 10'd147;
                    8'd29 : price = 10'd148;
                    8'd30 : price = 10'd160;
                    8'd31 : price = 10'd160;
                    8'd32 : price = 10'd161;
                    8'd33 : price = 10'd161;
                    8'd34 : price = 10'd161;
                    8'd35 : price = 10'd162;
                    8'd36 : price = 10'd162;
                    8'd37 : price = 10'd162;
                    8'd38 : price = 10'd163;
                    8'd39 : price = 10'd163;
                    8'd40 : price = 10'd176;
                    8'd41 : price = 10'd176;
                    8'd42 : price = 10'd176;
                    8'd43 : price = 10'd177;
                    8'd44 : price = 10'd177;
                    8'd45 : price = 10'd178;
                    8'd46 : price = 10'd178;
                    8'd47 : price = 10'd179;
                    8'd48 : price = 10'd179;
                    8'd49 : price = 10'd180;
                    8'd50 : price = 10'd192;
                    8'd51 : price = 10'd193;
                    8'd52 : price = 10'd193;
                    8'd53 : price = 10'd194;
                    8'd54 : price = 10'd194;
                    8'd55 : price = 10'd195;
                    8'd56 : price = 10'd195;
                    8'd57 : price = 10'd196;
                    8'd58 : price = 10'd196;
                    8'd59 : price = 10'd197;
                    8'd60 : price = 10'd210;
                    8'd61 : price = 10'd210;
                    8'd62 : price = 10'd211;
                    8'd63 : price = 10'd211;
                    8'd64 : price = 10'd212;
                    8'd65 : price = 10'd213;
                    8'd66 : price = 10'd213;
                    8'd67 : price = 10'd214;
                    8'd68 : price = 10'd215;
                    8'd69 : price = 10'd215;
                    8'd70 : price = 10'd228;
                    8'd71 : price = 10'd229;
                    8'd72 : price = 10'd229;
                    8'd73 : price = 10'd230;
                    8'd74 : price = 10'd231;
                    8'd75 : price = 10'd232;
                    8'd76 : price = 10'd232;
                    8'd77 : price = 10'd233;
                    8'd78 : price = 10'd234;
                    8'd79 : price = 10'd235;
                    8'd80 : price = 10'd248;
                    8'd81 : price = 10'd248;
                    8'd82 : price = 10'd249;
                    8'd83 : price = 10'd250;
                    8'd84 : price = 10'd251;
                    8'd85 : price = 10'd252;
                    8'd86 : price = 10'd252;
                    8'd87 : price = 10'd253;
                    8'd88 : price = 10'd254;
                    8'd89 : price = 10'd255;
                    8'd90 : price = 10'd268;
                    8'd91 : price = 10'd269;
                    8'd92 : price = 10'd270;
                    8'd93 : price = 10'd271;
                    8'd94 : price = 10'd272;
                    8'd95 : price = 10'd273;
                    8'd96 : price = 10'd274;
                    8'd97 : price = 10'd275;
                    8'd98 : price = 10'd276;
                    8'd99 : price = 10'd277;
                    8'd100: price = 10'd290;
                    default: price = 10'd120;
                endcase
            end
        endcase
    end
endmodule

module HIRE_FEE_LUT(
    input  logic [7:0]  level,
    output logic [13:0] fee
);
    always_comb begin
        case(level)
            8'd0  : fee = 14'd2000;
            8'd1  : fee = 14'd2100;
            8'd2  : fee = 14'd2200;
            8'd3  : fee = 14'd2300;
            8'd4  : fee = 14'd2400;
            8'd5  : fee = 14'd2500;
            8'd6  : fee = 14'd2600;
            8'd7  : fee = 14'd2700;
            8'd8  : fee = 14'd2800;
            8'd9  : fee = 14'd2900;
            8'd10 : fee = 14'd3200;
            8'd11 : fee = 14'd3300;
            8'd12 : fee = 14'd3400;
            8'd13 : fee = 14'd3500;
            8'd14 : fee = 14'd3600;
            8'd15 : fee = 14'd3700;
            8'd16 : fee = 14'd3800;
            8'd17 : fee = 14'd3900;
            8'd18 : fee = 14'd4000;
            8'd19 : fee = 14'd4100;
            8'd20 : fee = 14'd4400;
            8'd21 : fee = 14'd4500;
            8'd22 : fee = 14'd4600;
            8'd23 : fee = 14'd4700;
            8'd24 : fee = 14'd4800;
            8'd25 : fee = 14'd4900;
            8'd26 : fee = 14'd5000;
            8'd27 : fee = 14'd5100;
            8'd28 : fee = 14'd5200;
            8'd29 : fee = 14'd5300;
            8'd30 : fee = 14'd5600;
            8'd31 : fee = 14'd5700;
            8'd32 : fee = 14'd5800;
            8'd33 : fee = 14'd5900;
            8'd34 : fee = 14'd6000;
            8'd35 : fee = 14'd6100;
            8'd36 : fee = 14'd6200;
            8'd37 : fee = 14'd6300;
            8'd38 : fee = 14'd6400;
            8'd39 : fee = 14'd6500;
            8'd40 : fee = 14'd6800;
            8'd41 : fee = 14'd6900;
            8'd42 : fee = 14'd7000;
            8'd43 : fee = 14'd7100;
            8'd44 : fee = 14'd7200;
            8'd45 : fee = 14'd7300;
            8'd46 : fee = 14'd7400;
            8'd47 : fee = 14'd7500;
            8'd48 : fee = 14'd7600;
            8'd49 : fee = 14'd7700;
            8'd50 : fee = 14'd8000;
            8'd51 : fee = 14'd8100;
            8'd52 : fee = 14'd8200;
            8'd53 : fee = 14'd8300;
            8'd54 : fee = 14'd8400;
            8'd55 : fee = 14'd8500;
            8'd56 : fee = 14'd8600;
            8'd57 : fee = 14'd8700;
            8'd58 : fee = 14'd8800;
            8'd59 : fee = 14'd8900;
            8'd60 : fee = 14'd9200;
            8'd61 : fee = 14'd9300;
            8'd62 : fee = 14'd9400;
            8'd63 : fee = 14'd9500;
            8'd64 : fee = 14'd9600;
            8'd65 : fee = 14'd9700;
            8'd66 : fee = 14'd9800;
            8'd67 : fee = 14'd9900;
            8'd68 : fee = 14'd10000;
            8'd69 : fee = 14'd10100;
            8'd70 : fee = 14'd10400;
            8'd71 : fee = 14'd10500;
            8'd72 : fee = 14'd10600;
            8'd73 : fee = 14'd10700;
            8'd74 : fee = 14'd10800;
            8'd75 : fee = 14'd10900;
            8'd76 : fee = 14'd11000;
            8'd77 : fee = 14'd11100;
            8'd78 : fee = 14'd11200;
            8'd79 : fee = 14'd11300;
            8'd80 : fee = 14'd11600;
            8'd81 : fee = 14'd11700;
            8'd82 : fee = 14'd11800;
            8'd83 : fee = 14'd11900;
            8'd84 : fee = 14'd12000;
            8'd85 : fee = 14'd12100;
            8'd86 : fee = 14'd12200;
            8'd87 : fee = 14'd12300;
            8'd88 : fee = 14'd12400;
            8'd89 : fee = 14'd12500;
            8'd90 : fee = 14'd12800;
            8'd91 : fee = 14'd12900;
            8'd92 : fee = 14'd13000;
            8'd93 : fee = 14'd13100;
            8'd94 : fee = 14'd13200;
            8'd95 : fee = 14'd13300;
            8'd96 : fee = 14'd13400;
            8'd97 : fee = 14'd13500;
            8'd98 : fee = 14'd13600;
            8'd99 : fee = 14'd13700;
            8'd100: fee = 14'd14000;
            default: fee = 14'd2000;
        endcase
    end
endmodule

module SALARY_LUT(
    input  logic [7:0]  level,
    output logic [15:0] salary
);
    always_comb begin
        case(level)
            8'd0  : salary = 16'd20000;
            8'd1  : salary = 16'd20200;
            8'd2  : salary = 16'd20400;
            8'd3  : salary = 16'd20600;
            8'd4  : salary = 16'd20800;
            8'd5  : salary = 16'd21000;
            8'd6  : salary = 16'd21200;
            8'd7  : salary = 16'd21400;
            8'd8  : salary = 16'd21600;
            8'd9  : salary = 16'd21800;
            8'd10 : salary = 16'd23000;
            8'd11 : salary = 16'd23200;
            8'd12 : salary = 16'd23400;
            8'd13 : salary = 16'd23600;
            8'd14 : salary = 16'd23800;
            8'd15 : salary = 16'd24000;
            8'd16 : salary = 16'd24200;
            8'd17 : salary = 16'd24400;
            8'd18 : salary = 16'd24600;
            8'd19 : salary = 16'd24800;
            8'd20 : salary = 16'd26000;
            8'd21 : salary = 16'd26200;
            8'd22 : salary = 16'd26400;
            8'd23 : salary = 16'd26600;
            8'd24 : salary = 16'd26800;
            8'd25 : salary = 16'd27000;
            8'd26 : salary = 16'd27200;
            8'd27 : salary = 16'd27400;
            8'd28 : salary = 16'd27600;
            8'd29 : salary = 16'd27800;
            8'd30 : salary = 16'd29000;
            8'd31 : salary = 16'd29200;
            8'd32 : salary = 16'd29400;
            8'd33 : salary = 16'd29600;
            8'd34 : salary = 16'd29800;
            8'd35 : salary = 16'd30000;
            8'd36 : salary = 16'd30200;
            8'd37 : salary = 16'd30400;
            8'd38 : salary = 16'd30600;
            8'd39 : salary = 16'd30800;
            8'd40 : salary = 16'd32000;
            8'd41 : salary = 16'd32200;
            8'd42 : salary = 16'd32400;
            8'd43 : salary = 16'd32600;
            8'd44 : salary = 16'd32800;
            8'd45 : salary = 16'd33000;
            8'd46 : salary = 16'd33200;
            8'd47 : salary = 16'd33400;
            8'd48 : salary = 16'd33600;
            8'd49 : salary = 16'd33800;
            8'd50 : salary = 16'd35000;
            8'd51 : salary = 16'd35200;
            8'd52 : salary = 16'd35400;
            8'd53 : salary = 16'd35600;
            8'd54 : salary = 16'd35800;
            8'd55 : salary = 16'd36000;
            8'd56 : salary = 16'd36200;
            8'd57 : salary = 16'd36400;
            8'd58 : salary = 16'd36600;
            8'd59 : salary = 16'd36800;
            8'd60 : salary = 16'd38000;
            8'd61 : salary = 16'd38200;
            8'd62 : salary = 16'd38400;
            8'd63 : salary = 16'd38600;
            8'd64 : salary = 16'd38800;
            8'd65 : salary = 16'd39000;
            8'd66 : salary = 16'd39200;
            8'd67 : salary = 16'd39400;
            8'd68 : salary = 16'd39600;
            8'd69 : salary = 16'd39800;
            8'd70 : salary = 16'd41000;
            8'd71 : salary = 16'd41200;
            8'd72 : salary = 16'd41400;
            8'd73 : salary = 16'd41600;
            8'd74 : salary = 16'd41800;
            8'd75 : salary = 16'd42000;
            8'd76 : salary = 16'd42200;
            8'd77 : salary = 16'd42400;
            8'd78 : salary = 16'd42600;
            8'd79 : salary = 16'd42800;
            8'd80 : salary = 16'd44000;
            8'd81 : salary = 16'd44200;
            8'd82 : salary = 16'd44400;
            8'd83 : salary = 16'd44600;
            8'd84 : salary = 16'd44800;
            8'd85 : salary = 16'd45000;
            8'd86 : salary = 16'd45200;
            8'd87 : salary = 16'd45400;
            8'd88 : salary = 16'd45600;
            8'd89 : salary = 16'd45800;
            8'd90 : salary = 16'd47000;
            8'd91 : salary = 16'd47200;
            8'd92 : salary = 16'd47400;
            8'd93 : salary = 16'd47600;
            8'd94 : salary = 16'd47800;
            8'd95 : salary = 16'd48000;
            8'd96 : salary = 16'd48200;
            8'd97 : salary = 16'd48400;
            8'd98 : salary = 16'd48600;
            8'd99 : salary = 16'd48800;
            8'd100: salary = 16'd50000;
            default: salary = 16'd20000;
        endcase
    end
endmodule