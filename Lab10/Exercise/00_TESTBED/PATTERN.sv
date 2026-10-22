`include "Usertype.sv"
`define CYCLE_TIME 20.0

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter simulation_cycle = `CYCLE_TIME;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];
integer PATNUM = 10000;
parameter DRAM_BASE_ADDR    = 17'h10000;
parameter DATA_NUM          = 128;
parameter BYTES_PER_SHOP    = 16;
parameter DRAM_END_ADDR     = 17'h107FF;

integer total_lat, lat;
integer i, i_pat;
string msg;

//================================================================
// wire & registers 
//================================================================

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

//================================================================
// initial
//================================================================
initial begin
    $readmemh(DRAM_p_r, golden_DRAM);

    reset_signal_task;
    for(i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        @(negedge clk);

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
    #simulation_cycle;
    inf.rst_n = 1'b0;
    repeat(3) #simulation_cycle;
    inf.rst_n = 1'b1;
end endtask

task input_task;
    integer local_pat;
    integer combo_id;
    integer repeat_id;
    integer type_id;
    integer mode_id;
    integer trans_pat;
    integer trans_pos;
    integer restock_bin;
    integer restock_hit;
    logic [11:0] restock_cov_value;
begin
    repeat($urandom_range(0, 3)) @(negedge clk);

    local_pat = i_pat;

    // ============================================================
    // Phase 0: 1500 No_Warn + complete
    // data_no = 0, Check_Valid_Date, date = 1/2
    // ============================================================
    if(local_pat < 1500) begin
        given_action  = Check_Valid_Date;
        given_data_no = 8'd0;
        given_date.M  = 4'd1;
        given_date.D  = 5'd2;
    end

    // ============================================================
    // Phase 1: 40 Date_Warn
    // ============================================================
    else if(local_pat < 1540) begin
        given_action  = Check_Valid_Date;
        given_data_no = local_pat - 1500;
        given_date.M  = 4'd1;
        given_date.D  = 5'd1;
    end

    // ============================================================
    // Phase 2: 40 No_Staff_Warn
    // ============================================================
    else if(local_pat < 1580) begin
        given_action  = Pay_Day;
        given_data_no = 8'd0;
        given_date.M  = 4'd1;
        given_date.D  = 5'd2;
    end

    // ============================================================
    // Phase 3: 40 Stock_Warn
    // ============================================================
    else if(local_pat < 1620) begin
        repeat_id     = local_pat - 1580;
        given_action  = Make_and_Sell;
        given_data_no = 8'd1;
        given_date.M  = 4'd1;
        given_date.D  = 5'd2;

        given_type = Dessert_Type'(repeat_id % 8);

        case((repeat_id / 8) % 3)
            0: given_mode = Single;
            1: given_mode = Family_Set;
            2: given_mode = Party_Pack;
            default: given_mode = Single;
        endcase
    end

    // ============================================================
    // Phase 4: 40 Balance_Warn
    // ============================================================
    else if(local_pat < 1660) begin
        given_action  = Pay_Day;
        given_data_no = 8'd1;
        given_date.M  = 4'd1;
        given_date.D  = 5'd2;
    end

    // ============================================================
    // Phase 5: 40 Restock_Warn
    // ============================================================
    else if(local_pat < 1700) begin
        given_action  = Restock;
        given_data_no = 8'd2;
        given_date.M  = 4'd1;
        given_date.D  = 5'd2;

        given_restock[0] = 12'd2047;
        given_restock[1] = 12'd2047;
        given_restock[2] = 12'd2047;
        given_restock[3] = 12'd2047;
        given_restock[4] = 12'd2047;
    end

    // ============================================================
    // Phase 6: 40 Staff_Warn
    // ============================================================
    else if(local_pat < 1740) begin
        given_action  = Hire_Staff;
        given_data_no = 8'd2;
        given_date.M  = 4'd1;
        given_date.D  = 5'd2;
        given_staff   = 8'd30;
    end

    // ============================================================
    // Phase 7: 2400 patterns for Dessert_Type x Order_Mode
    //   type/mode fixed for coverage; date/data_no random
    // ============================================================
    else if(local_pat < 4140) begin
        combo_id  = (local_pat - 1740) / 100;
        type_id   = combo_id / 3;
        mode_id   = combo_id % 3;

        given_action  = Make_and_Sell;
        given_data_no = $urandom_range(0, 127);
        rand_legal_date(given_date);
        given_type    = Dessert_Type'(type_id[2:0]);

        case(mode_id)
            0: given_mode = Single;
            1: given_mode = Family_Set;
            2: given_mode = Party_Pack;
            default: given_mode = Single;
        endcase
    end

    // ============================================================
    // Phase 8: action transition coverage
    //   action fixed (de Bruijn); date/data_no/type/mode/
    //   staff/restock all random
    // ============================================================
    else if(local_pat < 9141) begin
        trans_pat = local_pat - 4140;
        trans_pos = trans_pat % 25;

        case(trans_pos)
             0: given_action = Action'(3'd0);
             1: given_action = Action'(3'd0);
             2: given_action = Action'(3'd1);
             3: given_action = Action'(3'd0);
             4: given_action = Action'(3'd2);
             5: given_action = Action'(3'd0);
             6: given_action = Action'(3'd3);
             7: given_action = Action'(3'd0);
             8: given_action = Action'(3'd4);
             9: given_action = Action'(3'd1);
            10: given_action = Action'(3'd1);
            11: given_action = Action'(3'd2);
            12: given_action = Action'(3'd1);
            13: given_action = Action'(3'd3);
            14: given_action = Action'(3'd1);
            15: given_action = Action'(3'd4);
            16: given_action = Action'(3'd2);
            17: given_action = Action'(3'd2);
            18: given_action = Action'(3'd3);
            19: given_action = Action'(3'd2);
            20: given_action = Action'(3'd4);
            21: given_action = Action'(3'd3);
            22: given_action = Action'(3'd3);
            23: given_action = Action'(3'd4);
            24: given_action = Action'(3'd4);
            default: given_action = Action'(3'd0);
        endcase

        given_data_no = $urandom_range(0, 127);
        rand_legal_date(given_date);
        given_type    = Dessert_Type'($urandom_range(0, 7));
        rand_legal_mode(given_mode);
        given_staff   = $urandom_range(1, 30);       // spec rule 28: 1~30

        given_restock[0] = $urandom_range(0, 2047);  // spec rule 20: 0~2047
        given_restock[1] = $urandom_range(0, 2047);
        given_restock[2] = $urandom_range(0, 2047);
        given_restock[3] = $urandom_range(0, 2047);
        given_restock[4] = $urandom_range(0, 2047);
    end

    // ============================================================
    // Phase 9: 640 Restock patterns for SPEC6 (128 bins x 5)
    //   restock value fixed for coverage; date/data_no random
    // ============================================================
    else if(local_pat < 9781) begin
        repeat_id = local_pat - 9141;

        restock_bin = repeat_id / 5;
        restock_hit = repeat_id % 5;
        restock_cov_value = restock_bin * 16 + restock_hit;

        given_action  = Restock;
        given_data_no = $urandom_range(0, 127);
        rand_legal_date(given_date);

        given_restock[0] = restock_cov_value;
        given_restock[1] = restock_cov_value;
        given_restock[2] = restock_cov_value;
        given_restock[3] = restock_cov_value;
        given_restock[4] = restock_cov_value;
    end

    // ============================================================
    // Remaining patterns: fully random
    // ============================================================
    else begin
        given_action  = Action'($urandom_range(0, 4));
        given_data_no = $urandom_range(0, 127);
        rand_legal_date(given_date);
        given_type    = Dessert_Type'($urandom_range(0, 7));
        rand_legal_mode(given_mode);
        given_staff   = $urandom_range(1, 30);       // spec rule 28: 1~30
        given_restock[0] = $urandom_range(0, 2047);  // spec rule 20: 0~2047
        given_restock[1] = $urandom_range(0, 2047);
        given_restock[2] = $urandom_range(0, 2047);
        given_restock[3] = $urandom_range(0, 2047);
        given_restock[4] = $urandom_range(0, 2047);
    end

    // ============================================================
    // Drive action
    // ============================================================
    give_action;

    // ============================================================
    // Drive inputs according to action
    // ============================================================
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

// Generate a random legal calendar date
task rand_legal_date;
    output Date d;
    integer max_day;
begin
    d.M = $urandom_range(1, 12);
    case(d.M)
        4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: max_day = 31;
        4'd4, 4'd6, 4'd9, 4'd11:                    max_day = 30;
        4'd2:                                        max_day = 28;
        default:                                     max_day = 28;
    endcase
    d.D = $urandom_range(1, max_day);
end endtask

// Generate a random legal Order_Mode (Single=2'b00, Family_Set=2'b10, Party_Pack=2'b11)
task rand_legal_mode;
    output Order_Mode m;
    integer r;
begin
    r = $urandom_range(0, 2);
    case(r)
        0: m = Single;
        1: m = Family_Set;
        2: m = Party_Pack;
        default: m = Single;
    endcase
end endtask

task give_action; begin
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0] = given_action;
    @(negedge clk);
    inf.sel_action_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_type; begin
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.type_valid = 1'b1;
    inf.D.d_type[0] = given_type;
    @(negedge clk);
    inf.type_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_mode; begin
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.mode_valid = 1'b1;
    inf.D.d_mode[0] = given_mode;
    @(negedge clk);
    inf.mode_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_date; begin
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.date_valid = 1'b1;
    inf.D.d_date[0] = given_date;
    @(negedge clk);
    inf.date_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_data_no; begin
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.data_no_valid = 1'b1;
    inf.D.d_data_no[0] = given_data_no;
    @(negedge clk);
    inf.data_no_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_staff; begin
    repeat($urandom_range(0, 3)) @(negedge clk);
    inf.staff_valid = 1'b1;
    inf.D.d_staff[0] = given_staff;
    @(negedge clk);
    inf.staff_valid = 1'b0;
    inf.D = 'bx;
end endtask

task give_restock; begin
    for(int j = 0; j < 5; j = j + 1) begin
        repeat($urandom_range(0, 3)) @(negedge clk);
        inf.restock_valid = 1'b1;
        inf.D.d_stock[0] = given_restock[j];
        @(negedge clk);
        inf.restock_valid = 1'b0;
        inf.D = 'bx;
    end
end endtask

//================================================================
// answer check
//   Protocol-level checks (latency bound, out_valid overlap,
//   one-cycle pulse, reset zero, ...) are handled by Checker.sv
//   via SystemVerilog assertions, so this task only verifies the
//   functional answer.
//================================================================
task wait_out_valid_task; begin
    lat = 0;
    while(inf.out_valid !== 1'b1) begin
        lat = lat + 1;
        @(negedge clk);
    end
    total_lat = total_lat + lat;
end endtask

task check_ans_task; begin
    unpack_golden_dram;
    calculate_golden_answer;
    if(inf.warn_msg !== golden_warn_msg || inf.complete !== golden_complete) begin
        // $display("------------------------------------------------------------------------");
        // $display("FAIL at PATTERN NO.%0d", i_pat);
        // $display("Action       : %s", get_action_name(given_action));
        // $display("Data No.     : %0d", given_data_no);
        // $display("Today        : %02d/%02d", given_date.M, given_date.D);
        // $display("Golden warn  : %s, complete = %b", get_warn_name(golden_warn_msg), golden_complete);
        // $display("Your warn    : %s, complete = %b", get_warn_name(inf.warn_msg), inf.complete);
        // $display("Old data     : F=%0d B=%0d M=%0d S=%0d Fr=%0d Date=%02d/%02d Sales=%0d Staff=%0d Bal=%0d Level=%0d",
        //          flour, butter, milk, sugar, fruit, action_month, action_day, sales, staff, balance, level);
        // $display("Golden data  : F=%0d B=%0d M=%0d S=%0d Fr=%0d Date=%02d/%02d Sales=%0d Staff=%0d Bal=%0d Level=%0d",
        //          flour_n, butter_n, milk_n, sugar_n, fruit_n, action_month_n, action_day_n, sales_n, staff_n, balance_n, level_n);
        // $display("------------------------------------------------------------------------");
        YOU_FAIL_task;
    end

    pack_golden_dram;

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
            4'd4, 4'd6, 4'd9, 4'd11:                    is_valid_date = (date_in.D <= 30);
            4'd2:                                       is_valid_date = (date_in.D <= 28);
            default:                                    is_valid_date = 1'b0;
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

task YOU_FAIL_task; begin
    $display("Wrong Answer");
    $finish;
end endtask

task YOU_PASS_task; begin
    $display(" Congratulations ");
    // $display(" Execution cycles = %5d cycles ", total_lat);
    $finish;
end endtask

endprogram