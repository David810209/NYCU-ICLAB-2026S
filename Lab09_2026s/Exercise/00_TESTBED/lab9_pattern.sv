`include "Usertype.sv"
`define CYCLE_TIME 2.9

// Set this macro to 1 if you want PATTERN to compare the whole DRAM image.
`define CHECK_DRAM 0
// Set this macro to 1 if you want PATTERN to print detailed input and output information for each pattern.
`define DISPLAY_INFO 0
// set random seed
`ifndef RANDOM_SEED
`define RANDOM_SEED 69
`endif
// set pattern number
`define PATTERN_NUM 10000
// set valid date ratio (0-10)
// The give_date task will generate a valid non-earlier date with the probability of VALID_DATE_RATIO/10,
// and generate an earlier date (which will result in DATE_WARN) with the probability of (10-VALID_DATE_RATIO)/10. 
// Setting a higher VALID_DATE_RATIO can help test the normal flow more, 
// while setting a lower VALID_DATE_RATIO can help test the exception handling more.
// DEFAULT=8: approximately 80% valid dates and 20% warning dates (DATE_WARN).
`ifndef VALID_DATE_RATIO
`define VALID_DATE_RATIO 8
`endif

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r          = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE         = 1000;
parameter CYCLE  = `CYCLE_TIME;
parameter PATNUM            = `PATTERN_NUM;
parameter DRAM_BASE_ADDR    = 17'h10000;
parameter DATA_NUM          = 128;
parameter BYTES_PER_SHOP    = 16;
parameter DRAM_END_ADDR     = 17'h107FF;

integer seed = `RANDOM_SEED;
integer total_lat, lat;
integer i, i_pat;
string msg;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [DRAM_END_ADDR:DRAM_BASE_ADDR];

Action       given_action;
Dessert_Type given_type;
Order_Mode   given_mode;
Date         given_date;
logic [7:0]  given_data_no;
logic [7:0]  given_staff;
logic [11:0] given_restock [0:4];

Warn_Msg golden_warn_msg;
logic    golden_complete;

logic [11:0] flour, butter, milk, sugar, fruit;
logic [7:0]  action_month, action_day;
logic [11:0] sales;
logic [7:0]  staff, level;
logic [23:0] balance;

logic [11:0] flour_n, butter_n, milk_n, sugar_n, fruit_n;
logic [7:0]  action_month_n, action_day_n;
logic [11:0] sales_n;
logic [7:0]  staff_n, level_n;
logic [23:0] balance_n;
integer date_warn_cnt, complete_cnt;
//================================================================
// class random
//================================================================
class random_act;
    randc logic [2:0] act_id;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        act_id inside {[0:4]};
    }
endclass

class random_dessert;
    randc logic [2:0] dessert_type;
    randc logic [1:0] order_mode;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        dessert_type inside {[0:7]};
        order_mode inside {2'd0, 2'd2, 2'd3};
    }
endclass

class random_date;
    randc Date date;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        date.M inside {[1:12]};
        (date.M == 1 || date.M == 3 || date.M == 5 || date.M == 7 || date.M == 8 || date.M == 10 || date.M == 12) -> date.D inside {[1:31]};
        (date.M == 4 || date.M == 6 || date.M == 9 || date.M == 11) -> date.D inside {[1:30]};
        (date.M == 2) -> date.D inside {[1:28]};
    }
endclass

class random_bad_date;
    randc Date date;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        date.M inside {[0:15]};
        date.D inside {[0:31]};
    }
endclass

class random_data_no;
    randc logic [7:0] data_no;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        data_no inside {[0:127]};
    }
endclass

class random_staff;
    randc logic [7:0] staff_num;
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        staff_num inside {[1:30]};
    }
endclass

class random_stock;
    randc logic [11:0] stock_num [5];
    function new(int seed);
        this.srandom(seed);
    endfunction
    constraint limit {
        foreach(stock_num[i]) stock_num[i] inside {[0:2047]};
    }
endclass

random_act     r_action;
random_dessert r_dessert;
random_date    r_date;
random_bad_date r_bad_date;
random_data_no r_data_no;
random_staff   r_staff;
random_stock   r_stock;

//================================================================
// initial
//================================================================
initial begin
    r_action   = random_act::new(seed);
    r_dessert  = random_dessert::new(seed + 17);
    r_date     = random_date::new(seed + 31);
    r_bad_date = random_bad_date::new(seed + 53);
    r_data_no  = random_data_no::new(seed + 71);
    r_staff    = random_staff::new(seed + 97);
    r_stock    = random_stock::new(seed + 113);

    generate_dram_dat;
    $readmemh(DRAM_p_r, golden_DRAM);
    $readmemh(DRAM_p_r, TESTBED.dram_r.DRAM);

    reset_signal_task;
    date_warn_cnt = 0;
    complete_cnt = 0;
    for(i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        check_one_cycle_task;
        
        // if((i_pat % 1000) == 0) begin
            $display("PASS PATTERN NO.%5d, latency = %4d, action = %s", i_pat, lat, get_action_name(given_action));
        // end
    end

    YOU_PASS_task;
end

//================================================================
// input tasks
//================================================================
task reset_signal_task; begin
    inf.rst_n            = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.type_valid       = 1'b0;
    inf.mode_valid       = 1'b0;
    inf.date_valid       = 1'b0;
    inf.staff_valid      = 1'b0;
    inf.data_no_valid    = 1'b0;
    inf.restock_valid    = 1'b0;
    inf.D                = 'bx;

    total_lat = 0;
    #CYCLE;
    inf.rst_n = 1'b0;
    repeat(3) #CYCLE;

    if(inf.out_valid !== 1'b0 || inf.complete !== 1'b0 || inf.warn_msg !== Warn_Msg'(3'd0) ||
       inf.AR_VALID !== 1'b0 || inf.AR_ADDR !== 17'b0 || inf.R_READY !== 1'b0 ||
       inf.AW_VALID !== 1'b0 || inf.AW_ADDR !== 17'b0 || inf.W_VALID !== 1'b0 || inf.W_DATA !== 64'b0 || inf.B_READY !== 1'b0) begin
        MAIN_FAIL_task("MAIN-1: output signals should be zero after reset.");
            end

    inf.rst_n = 1'b1;
end endtask

task input_task; begin
    repeat($urandom_range(1, 4)) @(negedge clk);
    give_action;

    repeat($urandom_range(1, 4)) @(negedge clk);
    i = r_data_no.randomize();
    given_data_no = r_data_no.data_no;
    case(given_action)
        Action'(3'd0): begin
            give_type;
            give_mode;
            give_date;
            give_data_no;
        end
        Action'(3'd1): begin
            give_date;
            give_data_no;
            give_restock;
        end
        Action'(3'd2): begin
            give_staff;
            give_date;
            give_data_no;
        end
        Action'(3'd3): begin
            give_date;
            give_data_no;
        end
        Action'(3'd4): begin
            give_date;
            give_data_no;
        end
        default: begin
            give_date;
            give_data_no;
        end
    endcase
    
end endtask

task give_action; begin
    i = r_action.randomize();
    given_action = Action'(r_action.act_id);
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0] = given_action;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_type; begin
    i = r_dessert.randomize();
    given_type = Dessert_Type'(r_dessert.dessert_type);
    given_mode = Order_Mode'(r_dessert.order_mode);
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.type_valid = 1'b1;
    inf.D.d_type[0] = given_type;
    @(negedge clk);
    inf.type_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_mode; begin
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.mode_valid = 1'b1;
    inf.D.d_mode[0] = given_mode;
    @(negedge clk);
    inf.mode_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_date;
    logic [16:0] base;
    logic [63:0] data0;
    logic [7:0]  old_month;
    logic [7:0]  old_day;
    integer max_day;
    integer date_mode;
begin
    base = get_shop_addr(given_data_no);
    data0 = read_64_from_golden(base);

    old_month = data0[39:32];
    old_day   = data0[7:0];

    // 0~7: generate non-earlier date
    // 8~9: try to generate earlier date
    date_mode = $urandom_range(9, 0);

    if(date_mode < `VALID_DATE_RATIO) begin
        given_date.M = $urandom_range(12, old_month[3:0]);

        if(given_date.M == old_month[3:0]) begin
            max_day = get_month_max_day(given_date.M);
            given_date.D = $urandom_range(max_day, old_day[4:0]);
        end
        else begin
            given_date.D = $urandom_range(get_month_max_day(given_date.M), 1);
        end
    end
    else begin
        if(old_month > 1) begin
            given_date.M = $urandom_range(old_month[3:0] - 1, 1);
            given_date.D = $urandom_range(get_month_max_day(given_date.M), 1);
        end
        else if(old_day > 1) begin
            given_date.M = old_month[3:0];
            given_date.D = $urandom_range(old_day[4:0] - 1, 1);
        end
        else begin
            // old date is already 01/01, impossible to generate an earlier legal date.
            // Fall back to a valid non-earlier date.
            given_date.M = old_month[3:0];
            given_date.D = old_day[4:0];
        end
    end

    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.date_valid = 1'b1;
    inf.D.d_date[0] = given_date;

    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_data_no; begin
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.data_no_valid = 1'b1;
    inf.D.d_data_no[0] = given_data_no;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_staff; begin
    i = r_staff.randomize();
    given_staff = r_staff.staff_num;
    repeat($urandom_range(1, 4)) @(negedge clk);
    inf.staff_valid = 1'b1;
    inf.D.d_staff[0] = given_staff;
    @(negedge clk);
    inf.staff_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_restock; begin
    i = r_stock.randomize();
    for(int j = 0; j < 5; j = j + 1) begin
        given_restock[j] = r_stock.stock_num[j];
        repeat($urandom_range(1, 4)) @(negedge clk);
        inf.restock_valid = 1'b1;
        inf.D.d_stock[0] = given_restock[j];
        @(negedge clk);
        inf.restock_valid = 1'b0;
        inf.D = 'bx;
    end
end endtask

//================================================================
// answer check
//================================================================
task wait_out_valid_task; begin
    lat = 0;
    while(inf.out_valid !== 1'b1) begin
        if(inf.sel_action_valid || inf.type_valid || inf.mode_valid || inf.date_valid || inf.staff_valid || inf.data_no_valid || inf.restock_valid) begin
            // input valid is allowed while waiting, but out_valid must still be low here
            if(inf.out_valid === 1'b1) begin
                $sformat(msg, "MAIN-3: out_valid overlaps with input valid signals at pattern %0d.", i_pat);
MAIN_FAIL_task(msg);
            end
        end
        lat = lat + 1;
        if(lat >= MAX_CYCLE) begin
            $sformat(msg, "MAIN-2: latency exceeds %0d cycles at pattern %0d.", MAX_CYCLE, i_pat);
MAIN_FAIL_task(msg);
        end
        @(negedge clk);
    end
    total_lat = total_lat + lat;
end endtask

task check_ans_task; begin
    unpack_golden_dram;
    calculate_golden_answer;
    if(`DISPLAY_INFO) display_input_task;
    if(inf.warn_msg !== golden_warn_msg || inf.complete !== golden_complete) begin
        $display("------------------------------------------------------------------------");
        $display("FAIL at PATTERN NO.%0d", i_pat);
        $display("Action       : %s", get_action_name(given_action));
        $display("Data No.     : %0d", given_data_no);
        $display("Today        : %02d/%02d", given_date.M, given_date.D);
        $display("Golden warn  : %s, complete = %b", get_warn_name(golden_warn_msg), golden_complete);
        $display("Your warn    : %s, complete = %b", get_warn_name(inf.warn_msg), inf.complete);
        $display("Old data     : F=%0d B=%0d M=%0d S=%0d Fr=%0d Date=%02d/%02d Sales=%0d Staff=%0d Bal=%0d Level=%0d",
                 flour, butter, milk, sugar, fruit, action_month, action_day, sales, staff, balance, level);
        $display("Golden data  : F=%0d B=%0d M=%0d S=%0d Fr=%0d Date=%02d/%02d Sales=%0d Staff=%0d Bal=%0d Level=%0d",
                 flour_n, butter_n, milk_n, sugar_n, fruit_n, action_month_n, action_day_n, sales_n, staff_n, balance_n, level_n);
        $display("------------------------------------------------------------------------");
        YOU_FAIL_task;
    end

    pack_golden_dram;

    if(`CHECK_DRAM) begin
        check_dram_value;
    end
end endtask

task check_one_cycle_task; begin
    if(inf.out_valid && (inf.sel_action_valid || inf.type_valid || inf.mode_valid || inf.date_valid || inf.staff_valid || inf.data_no_valid || inf.restock_valid)) begin
        $sformat(msg, "MAIN-3: out_valid cannot overlap with input valid signals at pattern %0d.", i_pat);
MAIN_FAIL_task(msg);
    end

    @(negedge clk);
    if(inf.out_valid !== 1'b0 || inf.complete !== 1'b0) begin
        MAIN_FAIL_task("MAIN-3: out_valid and complete should be high for exactly one cycle.");
    end
end endtask

//================================================================
// golden model
//================================================================
task calculate_golden_answer; begin
    flour_n        = flour;
    butter_n       = butter;
    milk_n         = milk;
    sugar_n        = sugar;
    fruit_n        = fruit;
    action_month_n = action_month;
    action_day_n   = action_day;
    sales_n        = sales;
    staff_n        = staff;
    balance_n      = balance;
    level_n        = level;
    golden_warn_msg = Warn_Msg'(3'd0);
    golden_complete = 1'b1;

    case(given_action)
        Action'(3'd0): make_and_sell_task;
        Action'(3'd1): restock_task;
        Action'(3'd2): hire_staff_task;
        Action'(3'd3): pay_day_task;
        Action'(3'd4): check_valid_date_task;
        default: begin
            golden_warn_msg = Warn_Msg'(3'd0);
            golden_complete = 1'b1;
        end
    endcase

    golden_complete = (golden_warn_msg == Warn_Msg'(3'd0));
    
    if(get_warn_name(golden_warn_msg) === "Date_Warn") date_warn_cnt+=1;
    if(golden_complete === 1)complete_cnt += 1;
end endtask

task apply_date_check;
    output logic date_ok;
begin
    date_ok = 1'b0;
    if(!is_valid_date(given_date)) begin
        golden_warn_msg = Warn_Msg'(3'd1);
    end
    else if(is_earlier_than_old_date(given_date, action_month, action_day)) begin
        golden_warn_msg = Warn_Msg'(3'd1);
    end
    else begin
        date_ok = 1'b1;
        action_month_n = {4'b0, given_date.M};
        action_day_n   = {3'b0, given_date.D};
    end
end endtask

task make_and_sell_task;
    logic date_ok;
    logic [3:0] scale;
    logic [11:0] need_flour, need_butter, need_milk, need_sugar, need_fruit;
    logic [15:0] new_sales;
    logic [15:0] threshold;
    logic [23:0] price_total;
begin
    apply_date_check(date_ok);
    if(!date_ok) return;

    if(staff == 0) begin
        golden_warn_msg = Warn_Msg'(3'd2);
        return;
    end

    scale = get_order_scale(given_mode);
    need_flour  = get_base_flour(given_type)  * scale;
    need_butter = get_base_butter(given_type) * scale;
    need_milk   = get_base_milk(given_type)   * scale;
    need_sugar  = get_base_sugar(given_type)  * scale;
    need_fruit  = get_base_fruit(given_type)  * scale;

    if(flour < need_flour || butter < need_butter || milk < need_milk || sugar < need_sugar || fruit < need_fruit) begin
        golden_warn_msg = Warn_Msg'(3'd3);
        return;
    end

    flour_n  = flour  - need_flour;
    butter_n = butter - need_butter;
    milk_n   = milk   - need_milk;
    sugar_n  = sugar  - need_sugar;
    fruit_n  = fruit  - need_fruit;

    price_total = get_dessert_price(given_type, level) * scale;
    balance_n   = sat_add_24(balance, price_total);

    new_sales = sales + scale;
    threshold = get_level_threshold(level);

    if(level == 8'd100) begin
        level_n = 8'd100;
        sales_n = (new_sales > 4095) ? 12'd4095 : new_sales[11:0];
    end
    else if(new_sales >= threshold) begin
        level_n = level + 8'd1;
        sales_n = new_sales - threshold;
    end
    else begin
        level_n = level;
        sales_n = new_sales[11:0];
    end
end endtask

task restock_task;
    logic date_ok;
    logic [31:0] actual_cost;
    logic [11:0] add_real [0:4];
    logic overflow_flag;
begin
    apply_date_check(date_ok);
    if(!date_ok) return;
    overflow_flag = 1'b0;
    add_real[0] = get_actual_add(flour,  given_restock[0]);
    add_real[1] = get_actual_add(butter, given_restock[1]);
    add_real[2] = get_actual_add(milk,   given_restock[2]);
    add_real[3] = get_actual_add(sugar,  given_restock[3]);
    add_real[4] = get_actual_add(fruit,  given_restock[4]);

    if(flour  + given_restock[0] > 4095) overflow_flag = 1'b1;
    if(butter + given_restock[1] > 4095) overflow_flag = 1'b1;
    if(milk   + given_restock[2] > 4095) overflow_flag = 1'b1;
    if(sugar  + given_restock[3] > 4095) overflow_flag = 1'b1;
    if(fruit  + given_restock[4] > 4095) overflow_flag = 1'b1;
    actual_cost = add_real[0] * get_restock_cost(0, level) +
                  add_real[1] * get_restock_cost(1, level) +
                  add_real[2] * get_restock_cost(2, level) +
                  add_real[3] * get_restock_cost(3, level) +
                  add_real[4] * get_restock_cost(4, level);
    if(balance < actual_cost) begin
        golden_warn_msg = Warn_Msg'(3'd4);
        return;
    end
    
    flour_n  = flour  + add_real[0];
    butter_n = butter + add_real[1];
    milk_n   = milk   + add_real[2];
    sugar_n  = sugar  + add_real[3];
    fruit_n  = fruit  + add_real[4];
    balance_n = balance - actual_cost[23:0];

    if(overflow_flag) golden_warn_msg = Warn_Msg'(3'd5);
end endtask

task hire_staff_task;
    logic date_ok;
    logic [31:0] actual_fee;
    logic [7:0] add_staff;
begin
    apply_date_check(date_ok);
    if(!date_ok) return;

    add_staff = ((staff + given_staff) > 100) ? (100 - staff) : given_staff;
    actual_fee = add_staff * get_hire_fee(level);
    if(balance < actual_fee) begin
        golden_warn_msg = Warn_Msg'(3'd4);
        return;
    end
    staff_n = staff + add_staff;
    balance_n = balance - actual_fee[23:0];

    if((staff + given_staff) > 100) begin
        golden_warn_msg = Warn_Msg'(3'd6);
    end
end endtask

task pay_day_task;
    logic date_ok;
    logic [31:0] total_salary;
begin
    apply_date_check(date_ok);
    if(!date_ok) return;

    if(staff == 0) begin
        golden_warn_msg = Warn_Msg'(3'd2);
        return;
    end

    total_salary = staff * get_salary(level);
    if(balance < total_salary) begin
        golden_warn_msg = Warn_Msg'(3'd4);
        level_n = (level < 10) ? 8'd0 : (level - 8'd10);
        staff_n = (staff >> 1);
        if(staff_n == 0) staff_n = 1;
        sales_n = 0;
        return;
    end

    balance_n = balance - total_salary[23:0];
end endtask

task check_valid_date_task; begin
    if(!is_valid_date(given_date)) begin
        golden_warn_msg = Warn_Msg'(3'd1);
    end
    else if(is_earlier_than_old_date(given_date, action_month, action_day)) begin
        golden_warn_msg = Warn_Msg'(3'd1);
    end
    else begin
        golden_warn_msg = Warn_Msg'(3'd0);
    end

    action_month_n = {4'b0, given_date.M};
    action_day_n   = {3'b0, given_date.D};
end endtask

//================================================================
// DRAM data generation
//================================================================
task generate_dram_dat;
    integer fd;
    integer no;
    integer base;
    logic [11:0] gen_flour, gen_butter, gen_milk, gen_sugar, gen_fruit;
    logic [7:0]  gen_month, gen_day;
    logic [11:0] gen_sales;
    logic [7:0]  gen_staff, gen_level;
    logic [23:0] gen_balance;
    logic [63:0] gen_data0, gen_data1;
integer gen_sales_max;
begin
    fd = $fopen(DRAM_p_r, "w");
    if(fd == 0) begin
        $display("Cannot open %s to generate dram.dat", DRAM_p_r);
        YOU_FAIL_task;
    end

    for(no = 0; no < DATA_NUM; no = no + 1) begin
        base = DRAM_BASE_ADDR + no * BYTES_PER_SHOP;

        gen_flour   = $urandom_range(4095, 0);
        gen_butter  = $urandom_range(4095, 0);
        gen_milk    = $urandom_range(4095, 0);
        gen_sugar   = $urandom_range(4095, 0);
        gen_fruit   = $urandom_range(4095, 0);
        // gen_month   = $urandom_range(12, 1);
        gen_month = 1;
        gen_day     = $urandom_range(get_month_max_day(gen_month), 1);
        gen_staff   = $urandom_range(100, 0);
        gen_level   = $urandom_range(100, 0);
        gen_sales_max = get_level_threshold(gen_level) - 1;
        gen_sales   = $urandom_range(gen_sales_max, 0);
        gen_balance = $urandom_range(16777215, 0);
                
        gen_data0 = {gen_flour, gen_butter, gen_month, gen_milk, gen_sugar, gen_day};
        gen_data1 = {gen_fruit, gen_sales, gen_staff, gen_balance, gen_level};

        // The DRAM file is byte-addressed and little-endian.
        // One data_no has 16 bytes: word0 at base/base+4, word1 at base+8/base+12.
        $fdisplay(fd, "// NO%0d:", no);
        $fdisplay(fd, "@%05h", base[16:0]);
        $fdisplay(fd, "%02h %02h %02h %02h", gen_data0[7:0],   gen_data0[15:8],  gen_data0[23:16],  gen_data0[31:24]);
        $fdisplay(fd, "@%05h", base + 4);
        $fdisplay(fd, "%02h %02h %02h %02h", gen_data0[39:32], gen_data0[47:40], gen_data0[55:48], gen_data0[63:56]);
        $fdisplay(fd, "@%05h", base + 8);
        $fdisplay(fd, "%02h %02h %02h %02h", gen_data1[7:0],   gen_data1[15:8],  gen_data1[23:16],  gen_data1[31:24]);
        $fdisplay(fd, "@%05h", base + 12);
        $fdisplay(fd, "%02h %02h %02h %02h", gen_data1[39:32], gen_data1[47:40], gen_data1[55:48], gen_data1[63:56]);
    end

    $fclose(fd);
end endtask

function integer get_month_max_day(input logic [7:0] month_in);
    case(month_in)
        1, 3, 5, 7, 8, 10, 12: get_month_max_day = 31;
        4, 6, 9, 11:           get_month_max_day = 30;
        2:                     get_month_max_day = 28;
        default:               get_month_max_day = 28;
    endcase
endfunction

//================================================================
// DRAM pack / unpack
//================================================================
task unpack_golden_dram;
    logic [16:0] base;
    logic [63:0] data0, data1;
begin
    base  = get_shop_addr(given_data_no);
    data0 = read_64_from_golden(base);
    data1 = read_64_from_golden(base + 17'd8);

    flour        = data0[63:52];
    butter       = data0[51:40];
    action_month = data0[39:32];
    milk         = data0[31:20];
    sugar        = data0[19:8];
    action_day   = data0[7:0];

    fruit        = data1[63:52];
    sales        = data1[51:40];
    staff        = data1[39:32];
    balance      = data1[31:8];
    level        = data1[7:0];
end endtask

task pack_golden_dram;
    logic [16:0] base;
    logic [63:0] data0, data1;
begin
    base  = get_shop_addr(given_data_no);
    data0 = {flour_n, butter_n, action_month_n, milk_n, sugar_n, action_day_n};
    data1 = {fruit_n, sales_n, staff_n, balance_n, level_n};
    write_64_to_golden(base, data0);
    write_64_to_golden(base + 17'd8, data1);
end endtask

task check_dram_value;
    integer no;
    logic [16:0] base;
    logic [63:0] golden_data0, golden_data1;
    logic [63:0] dram_data0, dram_data1;

    logic [11:0] g_flour, g_butter, g_milk, g_sugar, g_fruit;
    logic [7:0]  g_month, g_day;
    logic [11:0] g_sales;
    logic [7:0]  g_staff, g_level;
    logic [23:0] g_balance;

    logic [11:0] d_flour, d_butter, d_milk, d_sugar, d_fruit;
    logic [7:0]  d_month, d_day;
    logic [11:0] d_sales;
    logic [7:0]  d_staff, d_level;
    logic [23:0] d_balance;
begin
    for(no = 0; no < DATA_NUM; no = no + 1) begin
        base = get_shop_addr(no[7:0]);

        golden_data0 = {
            golden_DRAM[base+7], golden_DRAM[base+6],
            golden_DRAM[base+5], golden_DRAM[base+4],
            golden_DRAM[base+3], golden_DRAM[base+2],
            golden_DRAM[base+1], golden_DRAM[base+0]
        };

        golden_data1 = {
            golden_DRAM[base+15], golden_DRAM[base+14],
            golden_DRAM[base+13], golden_DRAM[base+12],
            golden_DRAM[base+11], golden_DRAM[base+10],
            golden_DRAM[base+9],  golden_DRAM[base+8]
        };

        dram_data0 = {
            TESTBED.dram_r.DRAM[base+7], TESTBED.dram_r.DRAM[base+6],
            TESTBED.dram_r.DRAM[base+5], TESTBED.dram_r.DRAM[base+4],
            TESTBED.dram_r.DRAM[base+3], TESTBED.dram_r.DRAM[base+2],
            TESTBED.dram_r.DRAM[base+1], TESTBED.dram_r.DRAM[base+0]
        };

        dram_data1 = {
            TESTBED.dram_r.DRAM[base+15], TESTBED.dram_r.DRAM[base+14],
            TESTBED.dram_r.DRAM[base+13], TESTBED.dram_r.DRAM[base+12],
            TESTBED.dram_r.DRAM[base+11], TESTBED.dram_r.DRAM[base+10],
            TESTBED.dram_r.DRAM[base+9],  TESTBED.dram_r.DRAM[base+8]
        };

        g_flour   = golden_data0[63:52];
        g_butter  = golden_data0[51:40];
        g_month   = golden_data0[39:32];
        g_milk    = golden_data0[31:20];
        g_sugar   = golden_data0[19:8];
        g_day     = golden_data0[7:0];

        g_fruit   = golden_data1[63:52];
        g_sales   = golden_data1[51:40];
        g_staff   = golden_data1[39:32];
        g_balance = golden_data1[31:8];
        g_level   = golden_data1[7:0];

        d_flour   = dram_data0[63:52];
        d_butter  = dram_data0[51:40];
        d_month   = dram_data0[39:32];
        d_milk    = dram_data0[31:20];
        d_sugar   = dram_data0[19:8];
        d_day     = dram_data0[7:0];

        d_fruit   = dram_data1[63:52];
        d_sales   = dram_data1[51:40];
        d_staff   = dram_data1[39:32];
        d_balance = dram_data1[31:8];
        d_level   = dram_data1[7:0];

        if(g_flour !== d_flour) begin
            DRAM_FIELD_FAIL_task(no, base, "Flour", g_month, g_day, g_flour, d_flour);
        end
        else if(g_butter !== d_butter) begin
            DRAM_FIELD_FAIL_task(no, base, "Butter", g_month, g_day, g_butter, d_butter);
        end
        else if(g_month !== d_month) begin
            DRAM_FIELD_FAIL_task(no, base, "Month", g_month, g_day, g_month, d_month);
        end
        else if(g_milk !== d_milk) begin
            DRAM_FIELD_FAIL_task(no, base, "Milk", g_month, g_day, g_milk, d_milk);
        end
        else if(g_sugar !== d_sugar) begin
            DRAM_FIELD_FAIL_task(no, base, "Sugar", g_month, g_day, g_sugar, d_sugar);
        end
        else if(g_day !== d_day) begin
            DRAM_FIELD_FAIL_task(no, base, "Day", g_month, g_day, g_day, d_day);
        end
        else if(g_fruit !== d_fruit) begin
            DRAM_FIELD_FAIL_task(no, base + 17'd8, "Fruit", g_month, g_day, g_fruit, d_fruit);
        end
        else if(g_sales !== d_sales) begin
            DRAM_FIELD_FAIL_task(no, base + 17'd8, "Sales", g_month, g_day, g_sales, d_sales);
        end
        else if(g_staff !== d_staff) begin
            DRAM_FIELD_FAIL_task(no, base + 17'd8, "Staff", g_month, g_day, g_staff, d_staff);
        end
        else if(g_balance !== d_balance) begin
            DRAM_FIELD_FAIL_task(no, base + 17'd8, "Balance", g_month, g_day, g_balance, d_balance);
        end
        else if(g_level !== d_level) begin
            DRAM_FIELD_FAIL_task(no, base + 17'd8, "Level", g_month, g_day, g_level, d_level);
        end
        else begin
            // this data_no is correct
        end
    end
end endtask

//================================================================
// helper functions
//================================================================
function logic [16:0] get_shop_addr(input logic [7:0] data_no);
    get_shop_addr = DRAM_BASE_ADDR + ({9'b0, data_no[6:0]} << 4);
endfunction

function logic [63:0] read_64_from_golden(input logic [16:0] addr);
    read_64_from_golden = {golden_DRAM[addr+7], golden_DRAM[addr+6], golden_DRAM[addr+5], golden_DRAM[addr+4],
                           golden_DRAM[addr+3], golden_DRAM[addr+2], golden_DRAM[addr+1], golden_DRAM[addr+0]};
endfunction

task write_64_to_golden;
    input logic [16:0] addr;
    input logic [63:0] data;
begin
    golden_DRAM[addr+0] = data[7:0];
    golden_DRAM[addr+1] = data[15:8];
    golden_DRAM[addr+2] = data[23:16];
    golden_DRAM[addr+3] = data[31:24];
    golden_DRAM[addr+4] = data[39:32];
    golden_DRAM[addr+5] = data[47:40];
    golden_DRAM[addr+6] = data[55:48];
    golden_DRAM[addr+7] = data[63:56];
end endtask

function logic is_valid_date(input Date date_in);
    if(date_in.M < 1 || date_in.M > 12 || date_in.D < 1) begin
        is_valid_date = 1'b0;
    end
    else begin
        case(date_in.M)
            4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: is_valid_date = (date_in.D <= 31);
            4'd4, 4'd6, 4'd9, 4'd11:                       is_valid_date = (date_in.D <= 30);
            4'd2:                                            is_valid_date = (date_in.D <= 28);
            default:                                         is_valid_date = 1'b0;
        endcase
    end
endfunction

function logic is_earlier_than_old_date(input Date today, input logic [7:0] old_m, input logic [7:0] old_d);
    if(today.M < old_m[3:0])      is_earlier_than_old_date = 1'b1;
    else if(today.M > old_m[3:0]) is_earlier_than_old_date = 1'b0;
    else                          is_earlier_than_old_date = (today.D < old_d[4:0]);
endfunction

function logic [3:0] get_order_scale(input Order_Mode mode_in);
    case(mode_in)
        Order_Mode'(2'd0): get_order_scale = 4'd1;
        Order_Mode'(2'd2): get_order_scale = 4'd4;
        Order_Mode'(2'd3): get_order_scale = 4'd8;
        default:           get_order_scale = 4'd1;
    endcase
endfunction

function logic [11:0] get_base_flour(input Dessert_Type type_in);
    case(type_in)
        Dessert_Type'(3'd0): get_base_flour = 12'd100;
        Dessert_Type'(3'd1): get_base_flour = 12'd200;
        Dessert_Type'(3'd2): get_base_flour = 12'd150;
        Dessert_Type'(3'd3): get_base_flour = 12'd0;
        Dessert_Type'(3'd4): get_base_flour = 12'd40;
        Dessert_Type'(3'd5): get_base_flour = 12'd120;
        Dessert_Type'(3'd6): get_base_flour = 12'd80;
        Dessert_Type'(3'd7): get_base_flour = 12'd150;
        default:             get_base_flour = 12'd0;
    endcase
endfunction

function logic [11:0] get_base_butter(input Dessert_Type type_in);
    case(type_in)
        Dessert_Type'(3'd0): get_base_butter = 12'd50;
        Dessert_Type'(3'd1): get_base_butter = 12'd20;
        Dessert_Type'(3'd2): get_base_butter = 12'd80;
        Dessert_Type'(3'd3): get_base_butter = 12'd0;
        Dessert_Type'(3'd4): get_base_butter = 12'd30;
        Dessert_Type'(3'd5): get_base_butter = 12'd30;
        Dessert_Type'(3'd6): get_base_butter = 12'd100;
        Dessert_Type'(3'd7): get_base_butter = 12'd60;
        default:             get_base_butter = 12'd0;
    endcase
endfunction

function logic [11:0] get_base_milk(input Dessert_Type type_in);
    case(type_in)
        Dessert_Type'(3'd0): get_base_milk = 12'd0;
        Dessert_Type'(3'd1): get_base_milk = 12'd50;
        Dessert_Type'(3'd2): get_base_milk = 12'd40;
        Dessert_Type'(3'd3): get_base_milk = 12'd150;
        Dessert_Type'(3'd4): get_base_milk = 12'd0;
        Dessert_Type'(3'd5): get_base_milk = 12'd80;
        Dessert_Type'(3'd6): get_base_milk = 12'd0;
        Dessert_Type'(3'd7): get_base_milk = 12'd30;
        default:             get_base_milk = 12'd0;
    endcase
endfunction

function logic [11:0] get_base_sugar(input Dessert_Type type_in);
    case(type_in)
        Dessert_Type'(3'd0): get_base_sugar = 12'd30;
        Dessert_Type'(3'd1): get_base_sugar = 12'd10;
        Dessert_Type'(3'd2): get_base_sugar = 12'd60;
        Dessert_Type'(3'd3): get_base_sugar = 12'd50;
        Dessert_Type'(3'd4): get_base_sugar = 12'd120;
        Dessert_Type'(3'd5): get_base_sugar = 12'd20;
        Dessert_Type'(3'd6): get_base_sugar = 12'd100;
        Dessert_Type'(3'd7): get_base_sugar = 12'd20;
        default:             get_base_sugar = 12'd0;
    endcase
endfunction

function logic [11:0] get_base_fruit(input Dessert_Type type_in);
    case(type_in)
        Dessert_Type'(3'd0): get_base_fruit = 12'd0;
        Dessert_Type'(3'd1): get_base_fruit = 12'd0;
        Dessert_Type'(3'd2): get_base_fruit = 12'd100;
        Dessert_Type'(3'd3): get_base_fruit = 12'd20;
        Dessert_Type'(3'd4): get_base_fruit = 12'd0;
        Dessert_Type'(3'd5): get_base_fruit = 12'd40;
        Dessert_Type'(3'd6): get_base_fruit = 12'd0;
        Dessert_Type'(3'd7): get_base_fruit = 12'd10;
        default:             get_base_fruit = 12'd0;
    endcase
endfunction

function logic [15:0] get_base_price(input Dessert_Type type_in);
    case(type_in)
        Dessert_Type'(3'd0): get_base_price = 16'd120;
        Dessert_Type'(3'd1): get_base_price = 16'd100;
        Dessert_Type'(3'd2): get_base_price = 16'd400;
        Dessert_Type'(3'd3): get_base_price = 16'd180;
        Dessert_Type'(3'd4): get_base_price = 16'd250;
        Dessert_Type'(3'd5): get_base_price = 16'd200;
        Dessert_Type'(3'd6): get_base_price = 16'd280;
        Dessert_Type'(3'd7): get_base_price = 16'd160;
        default:             get_base_price = 16'd0;
    endcase
endfunction

function logic [3:0] div10_level(input logic [7:0] lv);
    if      (lv >= 8'd100) div10_level = 4'd10;
    else if (lv >= 8'd90 ) div10_level = 4'd9;
    else if (lv >= 8'd80 ) div10_level = 4'd8;
    else if (lv >= 8'd70 ) div10_level = 4'd7;
    else if (lv >= 8'd60 ) div10_level = 4'd6;
    else if (lv >= 8'd50 ) div10_level = 4'd5;
    else if (lv >= 8'd40 ) div10_level = 4'd4;
    else if (lv >= 8'd30 ) div10_level = 4'd3;
    else if (lv >= 8'd20 ) div10_level = 4'd2;
    else if (lv >= 8'd10 ) div10_level = 4'd1;
    else                   div10_level = 4'd0;
endfunction

function logic [15:0] get_dessert_price(input Dessert_Type type_in, input logic [7:0] lv);
    logic [15:0] base_price;
    logic [3:0]  lv10;
    begin
        base_price = get_base_price(type_in);
        lv10 = div10_level(lv);
        get_dessert_price = (base_price * (10 + lv10)) / 10 + ((lv * lv) / 200);
    end
endfunction

function logic [15:0] get_restock_cost(input integer item, input logic [7:0] lv);
    logic [15:0] base_cost;
    logic [3:0] lv10;
    begin
        case(item)
            0: base_cost = 16'd15;
            1: base_cost = 16'd60;
            2: base_cost = 16'd25;
            3: base_cost = 16'd10;
            4: base_cost = 16'd80;
            default: base_cost = 16'd0;
        endcase
        lv10 = div10_level(lv);
        get_restock_cost = (base_cost * (10 + lv10)) / 10;
    end
endfunction

function logic [31:0] get_hire_fee(input logic [7:0] lv);
    get_hire_fee = 2000 + lv * 100 + div10_level(lv) * 200;
endfunction

function logic [31:0] get_salary(input logic [7:0] lv);
    get_salary = 20000 + lv * 200 + div10_level(lv) * 1000;
endfunction

function logic [15:0] get_level_threshold(input logic [7:0] lv);
    logic [3:0] lv10;
    begin
        lv10 = div10_level(lv);
        if(lv10 == 0) get_level_threshold = 16'd10;
        else          get_level_threshold = 10 * lv10;
    end
endfunction

function logic [11:0] get_actual_add(input logic [11:0] cur_stock, input logic [11:0] req_stock);
    if(cur_stock + req_stock > 4095) get_actual_add = 4095 - cur_stock;
    else                             get_actual_add = req_stock;
endfunction

function logic [23:0] sat_add_24(input logic [23:0] a, input logic [23:0] b);
    logic [24:0] tmp;
    begin
        tmp = a + b;
        sat_add_24 = (tmp > 24'hFFFFFF) ? 24'hFFFFFF : tmp[23:0];
    end
endfunction

function string get_action_name(input Action action_in);
    case(action_in)
        Action'(3'd0): get_action_name = "Make_and_Sell";
        Action'(3'd1): get_action_name = "Restock";
        Action'(3'd2): get_action_name = "Hire_Staff";
        Action'(3'd3): get_action_name = "Pay_Day";
        Action'(3'd4): get_action_name = "Check_Valid_Date";
        default:       get_action_name = "Unknown";
    endcase
endfunction

function string get_warn_name(input Warn_Msg warn_in);
    case(warn_in)
        Warn_Msg'(3'd0): get_warn_name = "No_Warn";
        Warn_Msg'(3'd1): get_warn_name = "Date_Warn";
        Warn_Msg'(3'd2): get_warn_name = "No_Staff_Warn";
        Warn_Msg'(3'd3): get_warn_name = "Stock_Warn";
        Warn_Msg'(3'd4): get_warn_name = "Balance_Warn";
        Warn_Msg'(3'd5): get_warn_name = "Restock_Warn";
        Warn_Msg'(3'd6): get_warn_name = "Staff_Warn";
        default:         get_warn_name = "Unknown";
    endcase
endfunction

//================================================================
// helper tasks
//================================================================
function string get_dessert_name(input Dessert_Type type_in);
    case(type_in)
        Cookie:     get_dessert_name = "Cookie";
        Bread:      get_dessert_name = "Bread";
        Fruit_Cake: get_dessert_name = "Fruit_Cake";
        Pudding:    get_dessert_name = "Pudding";
        Macaron:    get_dessert_name = "Macaron";
        Pancake:    get_dessert_name = "Pancake";
        Brownie:    get_dessert_name = "Brownie";
        Scone:      get_dessert_name = "Scone";
        default:    get_dessert_name = "Unknown";
    endcase
endfunction

function string get_mode_name(input Order_Mode mode_in);
    case(mode_in)
        Single:     get_mode_name = "Single";
        Family_Set: get_mode_name = "Family_Set";
        Party_Pack: get_mode_name = "Party_Pack";
        default:    get_mode_name = "Unknown";
    endcase
endfunction
task display_input_task; begin
    $display("====================================================================");
    $display(" PATTERN NO.%0d", i_pat);
    $display(" Action       : %s", get_action_name(given_action));
    $display(" Data No.     : %0d", given_data_no);
    $display(" Date         : %02d/%02d", given_date.M, given_date.D);

    case(given_action)
        Make_and_Sell: begin
            $display(" Dessert Type : %s", get_dessert_name(given_type));
            $display(" Order Mode   : %s", get_mode_name(given_mode));
        end

        Restock: begin
            $display(" Restock      : Flour=%0d, Butter=%0d, Milk=%0d, Sugar=%0d, Fruit=%0d",
                     given_restock[0], given_restock[1], given_restock[2],
                     given_restock[3], given_restock[4]);
        end

        Hire_Staff: begin
            $display(" Hire Staff   : %0d", given_staff);
        end

        Pay_Day: begin
            $display(" Pay Day      : selected shop only");
        end

        Check_Valid_Date: begin
            $display(" Check Date   : selected shop only");
        end

        default: begin
            $display(" Unknown action");
        end
    endcase
    $display("Warn: %s", get_warn_name(golden_warn_msg));
    $display("Complete: %d", golden_complete);
    $display("====================================================================");
end endtask
task DRAM_FIELD_FAIL_task;
    input integer data_no;
    input logic [16:0] addr;
    input string field_name;
    input logic [7:0] month;
    input logic [7:0] day;
    input logic [31:0] golden_value;
    input logic [31:0] dram_value;
begin
    $display("*************************************************************************");
    $display("*                           DRAM VALUE MISMATCH                         *");
    $display("*************************************************************************");
    $display("* PATTERN NO.  : %0d", i_pat);
    $display("* Action       : %s", get_action_name(given_action));
    $display("* Data No.     : %0d", data_no);
    $display("* Stored Date  : %02d/%02d", month, day);
    $display("* Field        : %s", field_name);
    $display("* Base Addr    : %05h", get_shop_addr(data_no[7:0]));
    $display("* Related Addr : %05h", addr);
    $display("* Golden Value : %0d / hex %h", golden_value, golden_value);
    $display("* DRAM Value   : %0d / hex %h", dram_value, dram_value);
    $display("*************************************************************************");

    $sformat(msg, "MAIN-5: DRAM mismatch at data_no %0d, field %s", data_no, field_name);
    MAIN_FAIL_task(msg);
end endtask
task MAIN_FAIL_task;
    input string fail_msg;
begin
    $display("*************************************************************************");
    $display("*                           MAIN SPEC FAIL at pat no.%d          *", i_pat);
    $display("*************************************************************************");
    $display("* %s", fail_msg);
    $display("*************************************************************************");
    YOU_FAIL_task;
end endtask

task YOU_FAIL_task; begin
    $display("*************************************************************************");
    $display("*                              FAIL!                                    *");
    $display("*************************************************************************");
    $finish;
end endtask

task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %8d cycles                     *", total_lat);
    $display("*                Cycles per action = %f cycles                     *", (total_lat*1.0)/PATNUM);
    $display("*                Your clock period     = %.1f ns                        *", CYCLE);
    $display("*                Total Latency         = %.1f ns                        *", total_lat * CYCLE);
    $display("*date warn cnt = %d, complete cnt = %d*", date_warn_cnt,complete_cnt);
    $display("*************************************************************************");
    
    $finish;
end endtask

endprogram
