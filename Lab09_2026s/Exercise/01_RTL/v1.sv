//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//      Date        : 2026/5
//      Version     : v3.0
//      File Name   : DSS.sv
//      Module Name : DSS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module DSS(input clk, INF.DSS_inf inf);
import usertype::*;

//================================================================
// FSM declaration
//================================================================
typedef enum logic [2:0] {
    S_IDLE   = 3'd0,
    S_READ   = 3'd1,
    S_TBL    = 3'd2,
    S_CALC   = 3'd3,
    S_WRITE  = 3'd4,
    S_FINISH = 3'd5
} FSM_t;

FSM_t state, next_state;

//================================================================
// input registers
//================================================================
Action       curr_action;
Dessert_Type curr_dessert;
Order_Mode   curr_order_mode;
Date         curr_date;
Staff_t      curr_staff;
Data_No      curr_data_no;
Stock        curr_restock [0:4];

logic        data_no_valid_reg;
logic [2:0]  restock_cnt;
logic        input_done;

//================================================================
// DRAM access wires
//================================================================
logic        read_start;
logic        write_start;
logic        dram_rvalid;
logic        dram_wvalid;
logic [63:0] dram_rdata0;
logic [63:0] dram_rdata1;
logic [63:0] write_data0;
logic [63:0] write_data1;

//================================================================
// unpacked DRAM data
//================================================================
Stock      cur_flour, cur_butter, cur_milk, cur_sugar, cur_fruit;
Month      cur_month;
Day        cur_day;
Sales_t    cur_sales;
Staff_t    cur_staff_dram;
Level_t    cur_level;
Balance_t  cur_balance;

//================================================================
// next-state DRAM fields (registered)
//================================================================
Stock      nxt_flour, nxt_butter, nxt_milk, nxt_sugar, nxt_fruit;
Month      nxt_month;
Day        nxt_day;
Sales_t    nxt_sales;
Staff_t    nxt_staff;
Level_t    nxt_level;
Balance_t  nxt_balance;

//================================================================
// calculation result registers
//================================================================
Warn_Msg   warn_msg_r;
logic      complete_r;

//================================================================
// table result registers (loaded at S_TBL state)
//================================================================
logic [15:0] price_r;
logic [15:0] cost_flour_r;
logic [15:0] cost_butter_r;
logic [15:0] cost_milk_r;
logic [15:0] cost_sugar_r;
logic [15:0] cost_fruit_r;
logic [15:0] hire_fee_r;
logic [15:0] salary_r;
logic [15:0] threshold_r;

//================================================================
// LUT submodule outputs (combinational)
//================================================================
logic [15:0] price_lut_out;
logic [15:0] cost_flour_lut_out;
logic [15:0] cost_butter_lut_out;
logic [15:0] cost_milk_lut_out;
logic [15:0] cost_sugar_lut_out;
logic [15:0] cost_fruit_lut_out;
logic [15:0] hire_fee_lut_out;
logic [15:0] salary_lut_out;
logic [15:0] threshold_lut_out;
logic [3:0]  cur_lv10;

//================================================================
// scale-by-shift functions: avoid multiplier when scale is 1/4/8
//================================================================
function logic [14:0] scale_stock_15(input logic [11:0] base, input Order_Mode mode);
    case(mode)
        Single:     scale_stock_15 = {3'd0, base};         // x1
        Family_Set: scale_stock_15 = {1'd0, base, 2'd0};   // x4 = << 2
        Party_Pack: scale_stock_15 = {base, 3'd0};         // x8 = << 3
        default:    scale_stock_15 = {3'd0, base};
    endcase
endfunction

function logic [18:0] scale_money_19(input logic [15:0] base, input Order_Mode mode);
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

//================================================================
// helper functions
//================================================================

function logic is_earlier_date(input Date din, input Month old_m, input Day old_d);
    if({4'b0, din.M} < old_m)      is_earlier_date = 1'b1;
    else if({4'b0, din.M} > old_m) is_earlier_date = 1'b0;
    else                            is_earlier_date = ({3'b0, din.D} < old_d);
endfunction

function Stock base_flour(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_flour = 12'd100;
        Bread:      base_flour = 12'd200;
        Fruit_Cake: base_flour = 12'd150;
        Pudding:    base_flour = 12'd0;
        Macaron:    base_flour = 12'd40;
        Pancake:    base_flour = 12'd120;
        Brownie:    base_flour = 12'd80;
        Scone:      base_flour = 12'd150;
        default:    base_flour = 12'd0;
    endcase
endfunction

function Stock base_butter(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_butter = 12'd50;
        Bread:      base_butter = 12'd20;
        Fruit_Cake: base_butter = 12'd80;
        Pudding:    base_butter = 12'd0;
        Macaron:    base_butter = 12'd30;
        Pancake:    base_butter = 12'd30;
        Brownie:    base_butter = 12'd100;
        Scone:      base_butter = 12'd60;
        default:    base_butter = 12'd0;
    endcase
endfunction

function Stock base_milk(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_milk = 12'd0;
        Bread:      base_milk = 12'd50;
        Fruit_Cake: base_milk = 12'd40;
        Pudding:    base_milk = 12'd150;
        Macaron:    base_milk = 12'd0;
        Pancake:    base_milk = 12'd80;
        Brownie:    base_milk = 12'd0;
        Scone:      base_milk = 12'd30;
        default:    base_milk = 12'd0;
    endcase
endfunction

function Stock base_sugar(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_sugar = 12'd30;
        Bread:      base_sugar = 12'd10;
        Fruit_Cake: base_sugar = 12'd60;
        Pudding:    base_sugar = 12'd50;
        Macaron:    base_sugar = 12'd120;
        Pancake:    base_sugar = 12'd20;
        Brownie:    base_sugar = 12'd100;
        Scone:      base_sugar = 12'd20;
        default:    base_sugar = 12'd0;
    endcase
endfunction

function Stock base_fruit(input Dessert_Type dessert);
    case(dessert)
        Cookie:     base_fruit = 12'd0;
        Bread:      base_fruit = 12'd0;
        Fruit_Cake: base_fruit = 12'd100;
        Pudding:    base_fruit = 12'd20;
        Macaron:    base_fruit = 12'd0;
        Pancake:    base_fruit = 12'd40;
        Brownie:    base_fruit = 12'd0;
        Scone:      base_fruit = 12'd10;
        default:    base_fruit = 12'd0;
    endcase
endfunction

//================================================================
// LUT submodule instantiations
//================================================================
PRICE_LUT u_price_lut (
    .dessert (curr_dessert),
    .level   (cur_level),
    .price   (price_lut_out)
);

DIV10_LUT u_div10_lut (
    .level (cur_level),
    .lv10  (cur_lv10)
);

COST_FLOUR_LUT  u_cost_flour_lut  (.lv10(cur_lv10), .cost(cost_flour_lut_out));
COST_BUTTER_LUT u_cost_butter_lut (.lv10(cur_lv10), .cost(cost_butter_lut_out));
COST_MILK_LUT   u_cost_milk_lut   (.lv10(cur_lv10), .cost(cost_milk_lut_out));
COST_SUGAR_LUT  u_cost_sugar_lut  (.lv10(cur_lv10), .cost(cost_sugar_lut_out));
COST_FRUIT_LUT  u_cost_fruit_lut  (.lv10(cur_lv10), .cost(cost_fruit_lut_out));

HIRE_FEE_LUT  u_hire_fee_lut  (.level(cur_level), .lv10(cur_lv10), .fee(hire_fee_lut_out));
SALARY_LUT    u_salary_lut    (.level(cur_level), .lv10(cur_lv10), .salary(salary_lut_out));
THRESHOLD_LUT u_threshold_lut (.lv10(cur_lv10), .threshold(threshold_lut_out));

//================================================================
// pre-computed combinational signals for calculation
//================================================================
// scaled need stock per ingredient (15-bit, via shift)
logic [14:0] need_flour, need_butter, need_milk, need_sugar, need_fruit;
assign need_flour  = scale_stock_15(base_flour(curr_dessert),  curr_order_mode);
assign need_butter = scale_stock_15(base_butter(curr_dessert), curr_order_mode);
assign need_milk   = scale_stock_15(base_milk(curr_dessert),   curr_order_mode);
assign need_sugar  = scale_stock_15(base_sugar(curr_dessert),  curr_order_mode);
assign need_fruit  = scale_stock_15(base_fruit(curr_dessert),  curr_order_mode);

// stock-insufficient flag
logic stock_lack;
assign stock_lack = ({3'b0, cur_flour}  < need_flour ) ||
                    ({3'b0, cur_butter} < need_butter) ||
                    ({3'b0, cur_milk}   < need_milk  ) ||
                    ({3'b0, cur_sugar}  < need_sugar ) ||
                    ({3'b0, cur_fruit}  < need_fruit );

// scaled sell price (19-bit, via shift)
logic [18:0] sell_price;
assign sell_price = scale_money_19(price_r, curr_order_mode);

// scale count (1/4/8) for sales accumulation
logic [3:0] order_cnt;
assign order_cnt = scale_count_4(curr_order_mode);

// new sales (after this transaction), 13-bit to hold 4095+8
logic [12:0] sales_total;
assign sales_total = {1'b0, cur_sales} + {9'b0, order_cnt};

// upgrade flag (sales reached threshold)
//   when level == 100, level stays 100 (sat); sales still accumulate.
//   when level <  100, sales >= threshold => level + 1, sales -= threshold.
logic upgrade_en;
assign upgrade_en = (cur_level < 8'd100) && (sales_total >= {1'b0, threshold_r[11:0]});

// saturated balance add (25-bit tmp)
logic [24:0] balance_add_tmp;
assign balance_add_tmp = {1'b0, cur_balance} + {6'b0, sell_price};

// restock cost (request, 32-bit)
logic [31:0] req_cost;
assign req_cost = {20'b0, curr_restock[0]} * {16'b0, cost_flour_r}  +
                  {20'b0, curr_restock[1]} * {16'b0, cost_butter_r} +
                  {20'b0, curr_restock[2]} * {16'b0, cost_milk_r}   +
                  {20'b0, curr_restock[3]} * {16'b0, cost_sugar_r}  +
                  {20'b0, curr_restock[4]} * {16'b0, cost_fruit_r};

// per-ingredient overflow check and real add amount
logic [12:0] sum_flour_req, sum_butter_req, sum_milk_req, sum_sugar_req, sum_fruit_req;
assign sum_flour_req  = {1'b0, cur_flour}  + {1'b0, curr_restock[0]};
assign sum_butter_req = {1'b0, cur_butter} + {1'b0, curr_restock[1]};
assign sum_milk_req   = {1'b0, cur_milk}   + {1'b0, curr_restock[2]};
assign sum_sugar_req  = {1'b0, cur_sugar}  + {1'b0, curr_restock[3]};
assign sum_fruit_req  = {1'b0, cur_fruit}  + {1'b0, curr_restock[4]};

logic [11:0] real_flour, real_butter, real_milk, real_sugar, real_fruit;
assign real_flour  = (sum_flour_req  > 13'd4095) ? (12'd4095 - cur_flour ) : curr_restock[0];
assign real_butter = (sum_butter_req > 13'd4095) ? (12'd4095 - cur_butter) : curr_restock[1];
assign real_milk   = (sum_milk_req   > 13'd4095) ? (12'd4095 - cur_milk  ) : curr_restock[2];
assign real_sugar  = (sum_sugar_req  > 13'd4095) ? (12'd4095 - cur_sugar ) : curr_restock[3];
assign real_fruit  = (sum_fruit_req  > 13'd4095) ? (12'd4095 - cur_fruit ) : curr_restock[4];

logic stock_overflow;
assign stock_overflow = (sum_flour_req  > 13'd4095) ||
                        (sum_butter_req > 13'd4095) ||
                        (sum_milk_req   > 13'd4095) ||
                        (sum_sugar_req  > 13'd4095) ||
                        (sum_fruit_req  > 13'd4095);

logic [31:0] real_cost;
assign real_cost = {20'b0, real_flour}  * {16'b0, cost_flour_r}  +
                   {20'b0, real_butter} * {16'b0, cost_butter_r} +
                   {20'b0, real_milk}   * {16'b0, cost_milk_r}   +
                   {20'b0, real_sugar}  * {16'b0, cost_sugar_r}  +
                   {20'b0, real_fruit}  * {16'b0, cost_fruit_r};

// hire staff
logic [31:0] req_fee;
assign req_fee = {24'b0, curr_staff} * {16'b0, hire_fee_r};

logic [8:0] sum_staff_req;
assign sum_staff_req = {1'b0, cur_staff_dram} + {1'b0, curr_staff};

logic staff_overflow;
assign staff_overflow = (sum_staff_req > 9'd100);

logic [7:0] real_staff;
assign real_staff = staff_overflow ? (8'd100 - cur_staff_dram) : curr_staff;

logic [31:0] real_fee;
assign real_fee = {24'b0, real_staff} * {16'b0, hire_fee_r};

// pay day
logic [31:0] total_salary;
assign total_salary = {24'b0, cur_staff_dram} * {16'b0, salary_r};

logic balance_lack_salary;
assign balance_lack_salary = ({8'b0, cur_balance} < total_salary);

logic balance_lack_restock;
assign balance_lack_restock = ({8'b0, cur_balance} < real_cost);

logic balance_lack_hire;
assign balance_lack_hire = ({8'b0, cur_balance} < real_fee);

// date check: valid AND not earlier than DRAM date
logic date_ok;
assign date_ok = !is_earlier_date(curr_date, cur_month, cur_day);

//================================================================
// per-action condition wires
//================================================================
// Make and Sell flags
logic ms_date_warn;
logic ms_no_staff_warn;
logic ms_stock_warn;
logic ms_ok;

assign ms_date_warn     = !date_ok;
assign ms_no_staff_warn = date_ok && (cur_staff_dram == 8'd0);
assign ms_stock_warn    = date_ok && (cur_staff_dram != 8'd0) && stock_lack;
assign ms_ok            = date_ok && (cur_staff_dram != 8'd0) && !stock_lack;

// Restock flags
logic rs_date_warn;
logic rs_balance_warn;
logic rs_restock_warn;
logic rs_no_warn;

assign rs_date_warn    = !date_ok;
assign rs_balance_warn = date_ok && balance_lack_restock;
assign rs_restock_warn = date_ok && !balance_lack_restock && stock_overflow;
assign rs_no_warn      = date_ok && !balance_lack_restock && !stock_overflow;

// Hire Staff flags
logic hs_date_warn;
logic hs_balance_warn;
logic hs_staff_warn;
logic hs_no_warn;

assign hs_date_warn    = !date_ok;
assign hs_balance_warn = date_ok && balance_lack_hire;
assign hs_staff_warn   = date_ok && !balance_lack_hire && staff_overflow;
assign hs_no_warn      = date_ok && !balance_lack_hire && !staff_overflow;

// Pay Day flags
logic pd_date_warn;
logic pd_no_staff_warn;
logic pd_balance_warn;
logic pd_no_warn;

assign pd_date_warn     = !date_ok;
assign pd_no_staff_warn = date_ok && (cur_staff_dram == 8'd0);
assign pd_balance_warn  = date_ok && (cur_staff_dram != 8'd0) && balance_lack_salary;
assign pd_no_warn       = date_ok && (cur_staff_dram != 8'd0) && !balance_lack_salary;

// Check Valid Date flag
logic cv_date_warn;
assign cv_date_warn = !date_ok;

//================================================================
// input control
//================================================================
assign input_done = (curr_action == Restock) ? ((restock_cnt == 3'd5) || (inf.restock_valid && (restock_cnt == 3'd4))) :
                                               data_no_valid_reg;
assign read_start  = (state == S_IDLE) && input_done;
assign write_start = (state == S_WRITE);

//================================================================
// FSM state register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) state <= S_IDLE;
    else           state <= next_state;
end

//================================================================
// FSM next-state logic
//================================================================
always_comb begin
    case(state)
        S_IDLE:   next_state = input_done   ? S_READ   : S_IDLE;
        S_READ:   next_state = dram_rvalid  ? S_TBL    : S_READ;
        S_TBL:    next_state = S_CALC;
        S_CALC:   next_state = S_WRITE;
        S_WRITE:  next_state = dram_wvalid  ? S_FINISH : S_WRITE;
        S_FINISH: next_state = S_IDLE;
        default:  next_state = S_IDLE;
    endcase
end

//================================================================
// curr_action register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_action <= Make_and_Sell;
    end
    else if(state == S_FINISH) begin
        curr_action <= Make_and_Sell;
    end
    else if(inf.sel_action_valid) begin
        curr_action <= inf.D.d_act[0];
    end
    else begin
        curr_action <= curr_action;
    end
end

//================================================================
// curr_dessert register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_dessert <= Cookie;
    end
    else if(state == S_FINISH) begin
        curr_dessert <= Cookie;
    end
    else if(inf.type_valid) begin
        curr_dessert <= inf.D.d_type[0];
    end
    else begin
        curr_dessert <= curr_dessert;
    end
end

//================================================================
// curr_order_mode register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_order_mode <= Single;
    end
    else if(state == S_FINISH) begin
        curr_order_mode <= Single;
    end
    else if(inf.mode_valid) begin
        curr_order_mode <= inf.D.d_mode[0];
    end
    else begin
        curr_order_mode <= curr_order_mode;
    end
end

//================================================================
// curr_date register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_date <= '0;
    end
    else if(state == S_FINISH) begin
        curr_date <= '0;
    end
    else if(inf.date_valid) begin
        curr_date <= inf.D.d_date[0];
    end
    else begin
        curr_date <= curr_date;
    end
end

//================================================================
// curr_staff register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_staff <= '0;
    end
    else if(state == S_FINISH) begin
        curr_staff <= '0;
    end
    else if(inf.staff_valid) begin
        curr_staff <= inf.D.d_staff[0];
    end
    else begin
        curr_staff <= curr_staff;
    end
end

//================================================================
// curr_data_no register
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_data_no <= '0;
    end
    else if(state == S_FINISH) begin
        curr_data_no <= '0;
    end
    else if(inf.data_no_valid) begin
        curr_data_no <= inf.D.d_data_no[0];
    end
    else begin
        curr_data_no <= curr_data_no;
    end
end

//================================================================
// data_no_valid_reg
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        data_no_valid_reg <= 1'b0;
    end
    else if(state == S_FINISH) begin
        data_no_valid_reg <= 1'b0;
    end
    else if(inf.data_no_valid) begin
        data_no_valid_reg <= 1'b1;
    end
    else begin
        data_no_valid_reg <= data_no_valid_reg;
    end
end

//================================================================
// restock_cnt and curr_restock
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        restock_cnt <= 3'd0;
    end
    else if(state == S_FINISH) begin
        restock_cnt <= 3'd0;
    end
    else if(inf.restock_valid && (restock_cnt < 3'd5)) begin
        restock_cnt <= restock_cnt + 3'd1;
    end
    else begin
        restock_cnt <= restock_cnt;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        curr_restock[0] <= '0;
        curr_restock[1] <= '0;
        curr_restock[2] <= '0;
        curr_restock[3] <= '0;
        curr_restock[4] <= '0;
    end
    else if(state == S_FINISH) begin
        curr_restock[0] <= '0;
        curr_restock[1] <= '0;
        curr_restock[2] <= '0;
        curr_restock[3] <= '0;
        curr_restock[4] <= '0;
    end
    else if(inf.restock_valid) begin
        case(restock_cnt)
            3'd0:    curr_restock[0] <= inf.D.d_stock[0];
            3'd1:    curr_restock[1] <= inf.D.d_stock[0];
            3'd2:    curr_restock[2] <= inf.D.d_stock[0];
            3'd3:    curr_restock[3] <= inf.D.d_stock[0];
            3'd4:    curr_restock[4] <= inf.D.d_stock[0];
            default: ;
        endcase
    end
    else begin
        curr_restock[0] <= curr_restock[0];
        curr_restock[1] <= curr_restock[1];
        curr_restock[2] <= curr_restock[2];
        curr_restock[3] <= curr_restock[3];
        curr_restock[4] <= curr_restock[4];
    end
end

//================================================================
// unpacked DRAM register (latched at S_READ when dram_rvalid)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        cur_flour      <= 12'd0;
        cur_butter     <= 12'd0;
        cur_milk       <= 12'd0;
        cur_sugar      <= 12'd0;
        cur_fruit      <= 12'd0;
        cur_month      <= 8'd0;
        cur_day        <= 8'd0;
        cur_sales      <= 12'd0;
        cur_staff_dram <= 8'd0;
        cur_level      <= 8'd0;
        cur_balance    <= 24'd0;
    end
    else if((state == S_READ) && dram_rvalid) begin
        cur_flour      <= dram_rdata0[63:52];
        cur_butter     <= dram_rdata0[51:40];
        cur_month      <= dram_rdata0[39:32];
        cur_milk       <= dram_rdata0[31:20];
        cur_sugar      <= dram_rdata0[19:8];
        cur_day        <= dram_rdata0[7:0];
        cur_fruit      <= dram_rdata1[63:52];
        cur_sales      <= dram_rdata1[51:40];
        cur_staff_dram <= dram_rdata1[39:32];
        cur_balance    <= dram_rdata1[31:8];
        cur_level      <= dram_rdata1[7:0];
    end
    else begin
        cur_flour      <= cur_flour;
        cur_butter     <= cur_butter;
        cur_milk       <= cur_milk;
        cur_sugar      <= cur_sugar;
        cur_fruit      <= cur_fruit;
        cur_month      <= cur_month;
        cur_day        <= cur_day;
        cur_sales      <= cur_sales;
        cur_staff_dram <= cur_staff_dram;
        cur_level      <= cur_level;
        cur_balance    <= cur_balance;
    end
end

//================================================================
// table result registers (loaded at S_TBL)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        price_r       <= 16'd0;
        cost_flour_r  <= 16'd0;
        cost_butter_r <= 16'd0;
        cost_milk_r   <= 16'd0;
        cost_sugar_r  <= 16'd0;
        cost_fruit_r  <= 16'd0;
        hire_fee_r    <= 16'd0;
        salary_r      <= 16'd0;
        threshold_r   <= 16'd10;
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
        price_r       <= price_r;
        cost_flour_r  <= cost_flour_r;
        cost_butter_r <= cost_butter_r;
        cost_milk_r   <= cost_milk_r;
        cost_sugar_r  <= cost_sugar_r;
        cost_fruit_r  <= cost_fruit_r;
        hire_fee_r    <= hire_fee_r;
        salary_r      <= salary_r;
        threshold_r   <= threshold_r;
    end
end

//================================================================
// nxt_flour
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_flour <= 12'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: nxt_flour <= ms_ok ? (cur_flour - need_flour[11:0]) : cur_flour;
            Restock:       nxt_flour <= (rs_no_warn || rs_restock_warn) ? (cur_flour + real_flour) : cur_flour;
            default:       nxt_flour <= cur_flour;
        endcase
    end
    else begin
        nxt_flour <= nxt_flour;
    end
end

//================================================================
// nxt_butter
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_butter <= 12'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: nxt_butter <= ms_ok ? (cur_butter - need_butter[11:0]) : cur_butter;
            Restock:       nxt_butter <= (rs_no_warn || rs_restock_warn) ? (cur_butter + real_butter) : cur_butter;
            default:       nxt_butter <= cur_butter;
        endcase
    end
    else begin
        nxt_butter <= nxt_butter;
    end
end

//================================================================
// nxt_milk
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_milk <= 12'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: nxt_milk <= ms_ok ? (cur_milk - need_milk[11:0]) : cur_milk;
            Restock:       nxt_milk <= (rs_no_warn || rs_restock_warn) ? (cur_milk + real_milk) : cur_milk;
            default:       nxt_milk <= cur_milk;
        endcase
    end
    else begin
        nxt_milk <= nxt_milk;
    end
end

//================================================================
// nxt_sugar
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_sugar <= 12'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: nxt_sugar <= ms_ok ? (cur_sugar - need_sugar[11:0]) : cur_sugar;
            Restock:       nxt_sugar <= (rs_no_warn || rs_restock_warn) ? (cur_sugar + real_sugar) : cur_sugar;
            default:       nxt_sugar <= cur_sugar;
        endcase
    end
    else begin
        nxt_sugar <= nxt_sugar;
    end
end

//================================================================
// nxt_fruit
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_fruit <= 12'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: nxt_fruit <= ms_ok ? (cur_fruit - need_fruit[11:0]) : cur_fruit;
            Restock:       nxt_fruit <= (rs_no_warn || rs_restock_warn) ? (cur_fruit + real_fruit) : cur_fruit;
            default:       nxt_fruit <= cur_fruit;
        endcase
    end
    else begin
        nxt_fruit <= nxt_fruit;
    end
end

//================================================================
// nxt_month / nxt_day
// For all 5 actions, when date is not earlier than DRAM date, update.
// Check_Valid_Date updates month/day even when date is earlier (per spec rule 36).
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_month <= 8'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Check_Valid_Date: nxt_month <= {4'b0, curr_date.M};
            default:          nxt_month <= date_ok ? {4'b0, curr_date.M} : cur_month;
        endcase
    end
    else begin
        nxt_month <= nxt_month;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_day <= 8'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Check_Valid_Date: nxt_day <= {3'b0, curr_date.D};
            default:          nxt_day <= date_ok ? {3'b0, curr_date.D} : cur_day;
        endcase
    end
    else begin
        nxt_day <= nxt_day;
    end
end

//================================================================
// nxt_sales (saturated to 4095 max)
//   Make_and_Sell ok:
//     upgrade_en  -> sales_total - threshold (level<100 only)
//     else        -> sat(sales_total) (level==100, or level<100 not yet reached threshold)
//   else          -> cur_sales
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_sales <= 12'd0;
    end
    else if(state == S_CALC) begin
        if(curr_action == Make_and_Sell && ms_ok) begin
            if(upgrade_en) begin
                nxt_sales <= sales_total[11:0] - threshold_r[11:0];
            end
            else begin
                nxt_sales <= (sales_total > 13'd4095) ? 12'd4095 : sales_total[11:0];
            end
        end
        else if(curr_action == Pay_Day && pd_balance_warn)begin
            nxt_sales <= 0;
        end
        else begin
            nxt_sales <= cur_sales;
        end
    end
    else begin
        nxt_sales <= nxt_sales;
    end
end

//================================================================
// nxt_level (saturated to 100 max)
//   Make_and_Sell ok + upgrade_en (which already requires level<100): level + 1
//   Pay_Day balance_warn: max(0, level-10)
//   else: cur_level (already <= 100)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_level <= 8'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: begin
                if(ms_ok && upgrade_en) nxt_level <= cur_level + 8'd1;  // upgrade_en already ensures cur_level<100
                else                    nxt_level <= cur_level;
            end
            Pay_Day: begin
                if(pd_balance_warn) nxt_level <= (cur_level < 8'd10) ? 8'd0 : (cur_level - 8'd10);
                else                nxt_level <= cur_level;
            end
            default: nxt_level <= cur_level;
        endcase
    end
    else begin
        nxt_level <= nxt_level;
    end
end

//================================================================
// nxt_staff (capped at 100)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_staff <= 8'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Hire_Staff: begin
                if(hs_no_warn || hs_staff_warn) nxt_staff <= cur_staff_dram + real_staff;
                else                            nxt_staff <= cur_staff_dram;
            end
            Pay_Day: begin
                if(pd_balance_warn) begin
                    if(cur_staff_dram <= 8'd1) nxt_staff <= 8'd1;
                    else                       nxt_staff <= cur_staff_dram >> 1;
                end
                else begin
                    nxt_staff <= cur_staff_dram;
                end
            end
            default: nxt_staff <= cur_staff_dram;
        endcase
    end
    else begin
        nxt_staff <= nxt_staff;
    end
end

//================================================================
// nxt_balance (saturated to 24'hFFFFFF max)
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        nxt_balance <= 24'd0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: begin
                if(ms_ok) nxt_balance <= balance_add_tmp[24] ? 24'hFFFFFF : balance_add_tmp[23:0];
                else      nxt_balance <= cur_balance;
            end
            Restock: begin
                if(rs_no_warn || rs_restock_warn) nxt_balance <= cur_balance - real_cost[23:0];
                else                              nxt_balance <= cur_balance;
            end
            Hire_Staff: begin
                if(hs_no_warn || hs_staff_warn) nxt_balance <= cur_balance - real_fee[23:0];
                else                            nxt_balance <= cur_balance;
            end
            Pay_Day: begin
                if(pd_no_warn) nxt_balance <= cur_balance - total_salary[23:0];
                else           nxt_balance <= cur_balance;
            end
            default: nxt_balance <= cur_balance;
        endcase
    end
    else begin
        nxt_balance <= nxt_balance;
    end
end

//================================================================
// warn_msg_r
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        warn_msg_r <= No_Warn;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell: begin
                if      (ms_date_warn)     warn_msg_r <= Date_Warn;
                else if (ms_no_staff_warn) warn_msg_r <= No_Staff_Warn;
                else if (ms_stock_warn)    warn_msg_r <= Stock_Warn;
                else                       warn_msg_r <= No_Warn;
            end
            Restock: begin
                if      (rs_date_warn)    warn_msg_r <= Date_Warn;
                else if (rs_balance_warn) warn_msg_r <= Balance_Warn;
                else if (rs_restock_warn) warn_msg_r <= Restock_Warn;
                else                      warn_msg_r <= No_Warn;
            end
            Hire_Staff: begin
                if      (hs_date_warn)    warn_msg_r <= Date_Warn;
                else if (hs_balance_warn) warn_msg_r <= Balance_Warn;
                else if (hs_staff_warn)   warn_msg_r <= Staff_Warn;
                else                      warn_msg_r <= No_Warn;
            end
            Pay_Day: begin
                if      (pd_date_warn)     warn_msg_r <= Date_Warn;
                else if (pd_no_staff_warn) warn_msg_r <= No_Staff_Warn;
                else if (pd_balance_warn)  warn_msg_r <= Balance_Warn;
                else                       warn_msg_r <= No_Warn;
            end
            Check_Valid_Date: begin
                if (cv_date_warn) warn_msg_r <= Date_Warn;
                else              warn_msg_r <= No_Warn;
            end
            default: warn_msg_r <= No_Warn;
        endcase
    end
    else begin
        warn_msg_r <= warn_msg_r;
    end
end

//================================================================
// complete_r
//================================================================
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        complete_r <= 1'b0;
    end
    else if(state == S_CALC) begin
        case(curr_action)
            Make_and_Sell:    complete_r <= ms_ok;
            Restock:          complete_r <= rs_no_warn;
            Hire_Staff:       complete_r <= hs_no_warn;
            Pay_Day:          complete_r <= pd_no_warn;
            Check_Valid_Date: complete_r <= !cv_date_warn;
            default:          complete_r <= 1'b0;
        endcase
    end
    else begin
        complete_r <= complete_r;
    end
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
        inf.out_valid <= 1'b0;
        inf.warn_msg  <= No_Warn;
        inf.complete  <= 1'b0;
    end
    else if(state == S_FINISH) begin
        inf.out_valid <= 1'b1;
        inf.warn_msg  <= warn_msg_r;
        inf.complete  <= complete_r;
    end
    else begin
        inf.out_valid <= 1'b0;
        inf.warn_msg  <= No_Warn;
        inf.complete  <= 1'b0;
    end
end

//================================================================
// DRAM access submodules
//================================================================
Read_DRAM u_read_dram (
    .clk          (clk),
    .in_valid     (read_start),
    .shop_data_no (curr_data_no),
    .out_data0    (dram_rdata0),
    .out_data1    (dram_rdata1),
    .out_valid    (dram_rvalid),
    .inf          (inf)
);

Write_DRAM u_write_dram (
    .clk          (clk),
    .in_valid     (write_start),
    .out_valid    (dram_wvalid),
    .shop_data_no (curr_data_no),
    .in_data0     (write_data0),
    .in_data1     (write_data1),
    .inf          (inf)
);

endmodule


//================================================================
// Read DRAM
//================================================================
module Read_DRAM
(
    clk,
    in_valid,
    shop_data_no,
    out_data0,
    out_data1,
    out_valid,
    inf
);
import usertype::*;

input  logic        clk;
input  logic        in_valid;
input  Data_No      shop_data_no;
output logic [63:0] out_data0;
output logic [63:0] out_data1;
output logic        out_valid;
INF.DSS_inf         inf;

typedef enum logic [2:0] {
    R_IDLE  = 3'd0,
    R_REQ0  = 3'd1,
    R_WAIT0 = 3'd2,
    R_REQ1  = 3'd3,
    R_WAIT1 = 3'd4,
    R_DONE  = 3'd5
} FSM_R;

FSM_R state, next_state;
logic [16:0] base_addr;

assign base_addr = 17'h10000 + ({9'd0, shop_data_no[6:0]} << 4);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) state <= R_IDLE;
    else           state <= next_state;
end

always_comb begin
    case(state)
        R_IDLE:  next_state = in_valid     ? R_REQ0  : R_IDLE;
        R_REQ0:  next_state = inf.AR_READY ? R_WAIT0 : R_REQ0;
        R_WAIT0: next_state = inf.R_VALID  ? R_REQ1  : R_WAIT0;
        R_REQ1:  next_state = inf.AR_READY ? R_WAIT1 : R_REQ1;
        R_WAIT1: next_state = inf.R_VALID  ? R_DONE  : R_WAIT1;
        R_DONE:  next_state = R_IDLE;
        default: next_state = R_IDLE;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AR_VALID <= 1'b0;
        inf.AR_ADDR  <= 17'd0;
    end
    else if(state == R_REQ0) begin
        inf.AR_VALID <= 1'b1;
        inf.AR_ADDR  <= base_addr;
    end
    else if(state == R_REQ1) begin
        inf.AR_VALID <= 1'b1;
        inf.AR_ADDR  <= base_addr + 17'd8;
    end
    else begin
        inf.AR_VALID <= 1'b0;
        inf.AR_ADDR  <= 17'd0;
    end
end

assign inf.R_READY = (state == R_WAIT0) || (state == R_WAIT1);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        out_data0 <= 64'd0;
    end
    else if((state == R_WAIT0) && inf.R_VALID) begin
        out_data0 <= inf.R_DATA;
    end
    else begin
        out_data0 <= out_data0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        out_data1 <= 64'd0;
    end
    else if((state == R_WAIT1) && inf.R_VALID) begin
        out_data1 <= inf.R_DATA;
    end
    else begin
        out_data1 <= out_data1;
    end
end

assign out_valid = (state == R_DONE);

endmodule


//================================================================
// Write DRAM
//================================================================
module Write_DRAM
(
    clk, in_valid, out_valid,
    shop_data_no,
    in_data0,
    in_data1,
    inf
);

input                clk, in_valid;
input        [7:0]   shop_data_no;
input        [63:0]  in_data0;
input        [63:0]  in_data1;
output logic         out_valid;
INF.DSS_inf inf;

typedef enum logic [2:0] {
    W_IDLE   = 3'd0,
    W_WRITE0 = 3'd1,
    W_WAIT0  = 3'd2,
    W_WRITE1 = 3'd3,
    W_WAIT1  = 3'd4,
    W_DONE   = 3'd5
} FSM_W;

FSM_W state, next_state;

logic [16:0] base_addr_r;
logic [63:0] data0_r;
logic [63:0] data1_r;

logic aw_done;
logic w_done;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) state <= W_IDLE;
    else           state <= next_state;
end

always_comb begin
    case(state)
        W_IDLE:   next_state = in_valid              ? W_WRITE0 : W_IDLE;
        W_WRITE0: next_state = (aw_done && w_done)   ? W_WAIT0  : W_WRITE0;
        W_WAIT0:  next_state = inf.B_VALID           ? W_WRITE1 : W_WAIT0;
        W_WRITE1: next_state = (aw_done && w_done)   ? W_WAIT1  : W_WRITE1;
        W_WAIT1:  next_state = inf.B_VALID           ? W_DONE   : W_WAIT1;
        W_DONE:   next_state = W_IDLE;
        default:  next_state = W_IDLE;
    endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        base_addr_r <= 17'd0;
        data0_r     <= 64'd0;
        data1_r     <= 64'd0;
    end
    else if(in_valid && (state == W_IDLE)) begin
        base_addr_r <= 17'h10000 + ({9'd0, shop_data_no[6:0]} << 4);
        data0_r     <= in_data0;
        data1_r     <= in_data1;
    end
    else begin
        base_addr_r <= base_addr_r;
        data0_r     <= data0_r;
        data1_r     <= data1_r;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        aw_done <= 1'b0;
    end
    else if((state == W_WRITE0) || (state == W_WRITE1)) begin
        if(inf.AW_VALID && inf.AW_READY) aw_done <= 1'b1;
        else                             aw_done <= aw_done;
    end
    else begin
        aw_done <= 1'b0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        w_done <= 1'b0;
    end
    else if((state == W_WRITE0) || (state == W_WRITE1)) begin
        if(inf.W_VALID && inf.W_READY) w_done <= 1'b1;
        else                           w_done <= w_done;
    end
    else begin
        w_done <= 1'b0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AW_VALID <= 1'b0;
    end
    else if((state == W_WRITE0) || (state == W_WRITE1)) begin
        if(aw_done) inf.AW_VALID <= 1'b0;
        else        inf.AW_VALID <= 1'b1;
    end
    else begin
        inf.AW_VALID <= 1'b0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.AW_ADDR <= 17'd0;
    end
    else if(state == W_WRITE0) begin
        inf.AW_ADDR <= base_addr_r;
    end
    else if(state == W_WRITE1) begin
        inf.AW_ADDR <= base_addr_r + 17'd8;
    end
    else begin
        inf.AW_ADDR <= 17'd0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.W_VALID <= 1'b0;
    end
    else if((state == W_WRITE0) || (state == W_WRITE1)) begin
        if(w_done) inf.W_VALID <= 1'b0;
        else       inf.W_VALID <= 1'b1;
    end
    else begin
        inf.W_VALID <= 1'b0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.W_DATA <= 64'd0;
    end
    else if(state == W_WRITE0) begin
        inf.W_DATA <= data0_r;
    end
    else if(state == W_WRITE1) begin
        inf.W_DATA <= data1_r;
    end
    else begin
        inf.W_DATA <= 64'd0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        inf.B_READY <= 1'b0;
    end
    else if((state == W_WAIT0) || (state == W_WAIT1)) begin
        inf.B_READY <= 1'b1;
    end
    else begin
        inf.B_READY <= 1'b0;
    end
end

assign out_valid = (state == W_DONE);
endmodule


//================================================================
// LUT submodules
//================================================================

// Divide-by-10 of level (0-100): 11-entry LUT (lv10 = level / 10)
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


// Cost LUTs (11 entries, indexed by lv10)
//   cost = floor(base * (10 + lv10) / 10)
module COST_FLOUR_LUT(
    input  logic [3:0]  lv10,
    output logic [15:0] cost
);
    always_comb begin
        case(lv10)
            4'd0:    cost = 16'd15;
            4'd1:    cost = 16'd16;
            4'd2:    cost = 16'd18;
            4'd3:    cost = 16'd19;
            4'd4:    cost = 16'd21;
            4'd5:    cost = 16'd22;
            4'd6:    cost = 16'd24;
            4'd7:    cost = 16'd25;
            4'd8:    cost = 16'd27;
            4'd9:    cost = 16'd28;
            4'd10:   cost = 16'd30;
            default: cost = 16'd15;
        endcase
    end
endmodule

module COST_BUTTER_LUT(
    input  logic [3:0]  lv10,
    output logic [15:0] cost
);
    always_comb begin
        case(lv10)
            4'd0:    cost = 16'd60;
            4'd1:    cost = 16'd66;
            4'd2:    cost = 16'd72;
            4'd3:    cost = 16'd78;
            4'd4:    cost = 16'd84;
            4'd5:    cost = 16'd90;
            4'd6:    cost = 16'd96;
            4'd7:    cost = 16'd102;
            4'd8:    cost = 16'd108;
            4'd9:    cost = 16'd114;
            4'd10:   cost = 16'd120;
            default: cost = 16'd60;
        endcase
    end
endmodule

module COST_MILK_LUT(
    input  logic [3:0]  lv10,
    output logic [15:0] cost
);
    always_comb begin
        case(lv10)
            4'd0:    cost = 16'd25;
            4'd1:    cost = 16'd27;
            4'd2:    cost = 16'd30;
            4'd3:    cost = 16'd32;
            4'd4:    cost = 16'd35;
            4'd5:    cost = 16'd37;
            4'd6:    cost = 16'd40;
            4'd7:    cost = 16'd42;
            4'd8:    cost = 16'd45;
            4'd9:    cost = 16'd47;
            4'd10:   cost = 16'd50;
            default: cost = 16'd25;
        endcase
    end
endmodule

module COST_SUGAR_LUT(
    input  logic [3:0]  lv10,
    output logic [15:0] cost
);
    always_comb begin
        case(lv10)
            4'd0:    cost = 16'd10;
            4'd1:    cost = 16'd11;
            4'd2:    cost = 16'd12;
            4'd3:    cost = 16'd13;
            4'd4:    cost = 16'd14;
            4'd5:    cost = 16'd15;
            4'd6:    cost = 16'd16;
            4'd7:    cost = 16'd17;
            4'd8:    cost = 16'd18;
            4'd9:    cost = 16'd19;
            4'd10:   cost = 16'd20;
            default: cost = 16'd10;
        endcase
    end
endmodule

module COST_FRUIT_LUT(
    input  logic [3:0]  lv10,
    output logic [15:0] cost
);
    always_comb begin
        case(lv10)
            4'd0:    cost = 16'd80;
            4'd1:    cost = 16'd88;
            4'd2:    cost = 16'd96;
            4'd3:    cost = 16'd104;
            4'd4:    cost = 16'd112;
            4'd5:    cost = 16'd120;
            4'd6:    cost = 16'd128;
            4'd7:    cost = 16'd136;
            4'd8:    cost = 16'd144;
            4'd9:    cost = 16'd152;
            4'd10:   cost = 16'd160;
            default: cost = 16'd80;
        endcase
    end
endmodule


// Hire fee LUT: 2000 + level*100 + lv10*200
module HIRE_FEE_LUT(
    input  logic [7:0]  level,
    input  logic [3:0]  lv10,
    output logic [15:0] fee
);
    logic [15:0] level_x100;
    logic [15:0] lv10_x200;
    always_comb begin
        // level * 100 = level*64 + level*32 + level*4 = (level<<6) + (level<<5) + (level<<2)
        level_x100 = ({8'b0, level} << 6) + ({8'b0, level} << 5) + ({8'b0, level} << 2);
        // lv10 * 200 via LUT (11 entries)
        case(lv10)
            4'd0:    lv10_x200 = 16'd0;
            4'd1:    lv10_x200 = 16'd200;
            4'd2:    lv10_x200 = 16'd400;
            4'd3:    lv10_x200 = 16'd600;
            4'd4:    lv10_x200 = 16'd800;
            4'd5:    lv10_x200 = 16'd1000;
            4'd6:    lv10_x200 = 16'd1200;
            4'd7:    lv10_x200 = 16'd1400;
            4'd8:    lv10_x200 = 16'd1600;
            4'd9:    lv10_x200 = 16'd1800;
            4'd10:   lv10_x200 = 16'd2000;
            default: lv10_x200 = 16'd0;
        endcase
        fee = 16'd2000 + level_x100 + lv10_x200;
    end
endmodule


// Salary LUT: 20000 + level*200 + lv10*1000
module SALARY_LUT(
    input  logic [7:0]  level,
    input  logic [3:0]  lv10,
    output logic [15:0] salary
);
    logic [15:0] level_x200;
    logic [15:0] lv10_x1000;
    always_comb begin
        // level * 200 = level*128 + level*64 + level*8 = (level<<7) + (level<<6) + (level<<3)
        level_x200 = ({8'b0, level} << 7) + ({8'b0, level} << 6) + ({8'b0, level} << 3);
        case(lv10)
            4'd0:    lv10_x1000 = 16'd0;
            4'd1:    lv10_x1000 = 16'd1000;
            4'd2:    lv10_x1000 = 16'd2000;
            4'd3:    lv10_x1000 = 16'd3000;
            4'd4:    lv10_x1000 = 16'd4000;
            4'd5:    lv10_x1000 = 16'd5000;
            4'd6:    lv10_x1000 = 16'd6000;
            4'd7:    lv10_x1000 = 16'd7000;
            4'd8:    lv10_x1000 = 16'd8000;
            4'd9:    lv10_x1000 = 16'd9000;
            4'd10:   lv10_x1000 = 16'd10000;
            default: lv10_x1000 = 16'd0;
        endcase
        salary = 16'd20000 + level_x200 + lv10_x1000;
    end
endmodule


// Threshold LUT: max(10, lv10*10)
module THRESHOLD_LUT(
    input  logic [3:0]  lv10,
    output logic [15:0] threshold
);
    always_comb begin
        case(lv10)
            4'd0:    threshold = 16'd10;
            4'd1:    threshold = 16'd10;
            4'd2:    threshold = 16'd20;
            4'd3:    threshold = 16'd30;
            4'd4:    threshold = 16'd40;
            4'd5:    threshold = 16'd50;
            4'd6:    threshold = 16'd60;
            4'd7:    threshold = 16'd70;
            4'd8:    threshold = 16'd80;
            4'd9:    threshold = 16'd90;
            4'd10:   threshold = 16'd100;
            default: threshold = 16'd10;
        endcase
    end
endmodule


// Price LUT: floor(base_price * (10 + lv10) / 10) + floor(level^2 / 200)
//   Indexed by dessert (3-bit) and level (8-bit, 0-100).
//   Implementation: compute base_price * (10+lv10) / 10 and add level^2 / 200.
module PRICE_LUT(
    input  logic [2:0]  dessert,
    input  logic [7:0]  level,
    output logic [15:0] price
);
    import usertype::*;
    logic [15:0] base_price;
    logic [3:0]  lv10;
    logic [15:0] mul_part;    // base_price * (10 + lv10) / 10
    logic [15:0] sq_part;     // level^2 / 200
    logic [15:0] level_sq;    // level^2 (max 100*100 = 10000)

    // dessert -> base price
    always_comb begin
        case(Dessert_Type'(dessert))
            Cookie:     base_price = 16'd120;
            Bread:      base_price = 16'd100;
            Fruit_Cake: base_price = 16'd400;
            Pudding:    base_price = 16'd180;
            Macaron:    base_price = 16'd250;
            Pancake:    base_price = 16'd200;
            Brownie:    base_price = 16'd280;
            Scone:      base_price = 16'd160;
            default:    base_price = 16'd120;
        endcase
    end

    // level / 10
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

    // base * (10+lv10) / 10
    // (10+lv10) ranges 10..20.  base * 10 >> base + base*9 ; etc.
    // We just use a multiplier here -- only one multiplier in the price path,
    // tolerable since this LUT is only computed once per transaction (S_TBL).
    always_comb begin
        mul_part = (base_price * ({12'd0, lv10} + 16'd10)) / 16'd10;
    end

    // level^2 / 200
    always_comb begin
        level_sq = {8'b0, level} * {8'b0, level};
        sq_part  = level_sq / 16'd200;
    end

    assign price = mul_part + sq_part;
endmodule