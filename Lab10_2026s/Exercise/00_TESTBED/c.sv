/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2026 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2026)
Author : Chia-Hsin Lee
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module CHECKER(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Type_and_mode;
    Dessert_Type f_type;
    Order_Mode   f_mode;
endclass
Type_and_mode fm_info = new();

always_comb begin
    if (inf.type_valid) fm_info.f_type = inf.D.d_type[0];
    if (inf.mode_valid) fm_info.f_mode = inf.D.d_mode[0];
end

//================================================================
// Coverage
//================================================================

// SPEC1: each Dessert_Type at least 100 times (sampled on type_valid)
covergroup CG_DESSERT_TYPE @(posedge clk iff inf.type_valid);

    option.name         = "SPEC1_DESSERT_TYPE";
    option.per_instance = 1;
    option.at_least     = 100;
    cp_type : coverpoint inf.D.d_type[0] {
        bins b_dtype[] = {[Cookie : Scone]};
    }
endgroup

// SPEC2: each Order_Mode at least 100 times (sampled on mode_valid)
covergroup CG_ORDER_MODE @(posedge clk iff inf.mode_valid);
    option.name         = "SPEC2_ORDER_MODE";
    option.per_instance = 1;
    option.at_least     = 100;
    cp_mode : coverpoint inf.D.d_mode[0] {
        bins b_mode[] = {[Single : Party_Pack]};
    }
endgroup

// SPEC3: cross Dessert_Type x Order_Mode at least 100 times.
//   Sample on mode_valid, using the latched f_type from earlier
//   type_valid pulse.
covergroup CG_TYPE_X_MODE @(posedge clk iff inf.mode_valid);
    option.name         = "SPEC3_TYPE_X_MODE";
    option.per_instance = 1;
    option.at_least     = 100;
    cp_t : coverpoint fm_info.f_type {
        bins b_t[] = {[Cookie : Scone]};
    }
    cp_m : coverpoint inf.D.d_mode[0] {
        bins b_m[] = {[Single : Party_Pack]};
    }
    cx_tm : cross cp_t, cp_m;
endgroup

// SPEC4: each warn_msg at least 40 times (sampled when out_valid is high)
covergroup CG_WARN_MSG @(posedge clk iff inf.out_valid);
    option.name         = "SPEC4_WARN_MSG";
    option.per_instance = 1;
    option.at_least     = 40;
    cp_warn : coverpoint inf.warn_msg {
        bins b_warn[] = {[No_Warn : Staff_Warn]};
    }
endgroup

// SPEC5: action transitions Make_and_Sell..Check_Valid_Date,
//   each transition >= 200 times (sampled on sel_action_valid)
covergroup CG_ACTION_TRANS @(posedge clk iff inf.sel_action_valid);
    option.name         = "SPEC5_ACTION_TRANS";
    option.per_instance = 1;
    option.at_least     = 200;
    cp_act : coverpoint inf.D.d_act[0] {
        bins b_trans[] = ([Make_and_Sell : Check_Valid_Date]
                           => [Make_and_Sell : Check_Valid_Date]);
    }
endgroup

// SPEC6: restock material coverage, auto_bin_max = 128, each bin >= 5.
//   Coverage analysis only on range [0:2047] (signal is 12-bit).
covergroup CG_RESTOCK_VAL @(posedge clk iff inf.restock_valid);
    option.name         = "SPEC6_RESTOCK_VAL";
    option.per_instance = 1;
    option.at_least     = 5;
    cp_stock : coverpoint inf.D.d_stock[0] {
        option.auto_bin_max = 128;
        ignore_bins ig_high = {[12'd2048 : 12'd4095]};
    }
endgroup

// SPEC7: action complete at least 1500 times
covergroup CG_COMPLETE @(posedge clk iff inf.out_valid);
    option.name         = "SPEC7_COMPLETE";
    option.per_instance = 1;
    option.at_least     = 1500;
    cp_done : coverpoint inf.complete {
        bins b_done = {1'b1};
    }
endgroup

CG_DESSERT_TYPE cg1 = new();
CG_ORDER_MODE   cg2 = new();
CG_TYPE_X_MODE  cg3 = new();
CG_WARN_MSG     cg4 = new();
CG_ACTION_TRANS cg5 = new();
CG_RESTOCK_VAL  cg6 = new();
CG_COMPLETE     cg7 = new();

//================================================================
// Assertions
//================================================================

// 7-bit bus of all input valids - used by A5.
wire [6:0] in_valid_bus = { inf.sel_action_valid, inf.type_valid,
                            inf.mode_valid,       inf.date_valid,
                            inf.staff_valid,      inf.data_no_valid,
                            inf.restock_valid };

//----------------------------------------------------------------
// A1. All output signals must be zero after reset.
//----------------------------------------------------------------
property P_RESET_ZERO;
    @(posedge inf.rst_n) 1'b1 |-> @(posedge clk)
        ( !inf.out_valid && !inf.complete && (inf.warn_msg === Warn_Msg'(3'd0))
       && !inf.AR_VALID  && (inf.AR_ADDR === 17'd0) && !inf.R_READY
       && !inf.AW_VALID  && (inf.AW_ADDR === 17'd0)
       && !inf.W_VALID   && (inf.W_DATA  === 64'd0) && !inf.B_READY );
endproperty

//----------------------------------------------------------------
// A2. Latency from the LAST input valid of an operation to
//     out_valid must be < 1000 cycles. Split per action because
//     each one has a different last-input-valid signal.
//----------------------------------------------------------------
property P_LATENCY_MAS;       // Make_and_Sell    -> last : data_no_valid
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Make_and_Sell)
        ##[1:4] inf.type_valid    ##[1:4] inf.mode_valid
        ##[1:4] inf.date_valid    ##[1:4] inf.data_no_valid
        |-> ##[1:999] inf.out_valid;
endproperty

property P_LATENCY_RESTOCK;   // Restock          -> last : 5th restock_valid
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Restock)
        ##[1:4] inf.date_valid    ##[1:4] inf.data_no_valid
        ##[1:4] inf.restock_valid[->5]
        |-> ##[1:999] inf.out_valid;
endproperty

property P_LATENCY_HIRE;      // Hire_Staff       -> last : data_no_valid
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Hire_Staff)
        ##[1:4] inf.staff_valid   ##[1:4] inf.date_valid
        ##[1:4] inf.data_no_valid
        |-> ##[1:999] inf.out_valid;
endproperty

property P_LATENCY_PAY;       // Pay_Day          -> last : data_no_valid
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Pay_Day)
        ##[1:4] inf.date_valid    ##[1:4] inf.data_no_valid
        |-> ##[1:999] inf.out_valid;
endproperty

property P_LATENCY_CHECK;     // Check_Valid_Date -> last : data_no_valid
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Check_Valid_Date)
        ##[1:4] inf.date_valid    ##[1:4] inf.data_no_valid
        |-> ##[1:999] inf.out_valid;
endproperty

//----------------------------------------------------------------
// A3. complete=1 => warn_msg == No_Warn
//----------------------------------------------------------------
property P_COMPLETE_NO_WARN;
    @(negedge clk) (inf.out_valid && inf.complete)
        |-> (inf.warn_msg === No_Warn);
endproperty

//----------------------------------------------------------------
// A4. Each subsequent input valid arrives 1-4 cycles after the
//     previous one. Split per action.
//----------------------------------------------------------------
property P_GAP_MAS;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Make_and_Sell)
        |-> ##[1:4] inf.type_valid
            ##[1:4] inf.mode_valid
            ##[1:4] inf.date_valid
            ##[1:4] inf.data_no_valid;
endproperty

property P_GAP_RESTOCK;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Restock)
        |-> ##[1:4] inf.date_valid
            ##[1:4] inf.data_no_valid
            ##[1:4] inf.restock_valid
            ##[1:4] inf.restock_valid
            ##[1:4] inf.restock_valid
            ##[1:4] inf.restock_valid
            ##[1:4] inf.restock_valid;
endproperty

property P_GAP_HIRE;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Hire_Staff)
        |-> ##[1:4] inf.staff_valid
            ##[1:4] inf.date_valid
            ##[1:4] inf.data_no_valid;
endproperty

property P_GAP_PAY;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Pay_Day)
        |-> ##[1:4] inf.date_valid
            ##[1:4] inf.data_no_valid;
endproperty

property P_GAP_CHECK;
    @(posedge clk) (inf.sel_action_valid && inf.D.d_act[0] == Check_Valid_Date)
        |-> ##[1:4] inf.date_valid
            ##[1:4] inf.data_no_valid;
endproperty

//----------------------------------------------------------------
// A5. Input valids are mutually exclusive.
//----------------------------------------------------------------
property P_INVALID_ONEHOT;
    @(posedge clk) $onehot0(in_valid_bus);
endproperty

//----------------------------------------------------------------
// A6. out_valid stays high for exactly one cycle.
//----------------------------------------------------------------
property P_OUT_VALID_ONE;
    @(negedge clk) (inf.out_valid )|=> !inf.out_valid;
endproperty

//----------------------------------------------------------------
// A7. Next operation (sel_action_valid) 1-4 cycles after
//     out_valid falls.
//----------------------------------------------------------------
property P_NEXT_OP;
    @(negedge clk) inf.out_valid |=> ##[1:4] inf.sel_action_valid;
endproperty

//----------------------------------------------------------------
// A8. Real-calendar date when date_valid is high.
//----------------------------------------------------------------
function automatic logic legal_date(input logic [3:0] m, input logic [4:0] d);
    logic ok;
    ok = 1'b0;
    if (d == 5'd0) ok = 1'b0;
    else begin
        case (m)
            4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: ok = (d <= 5'd31);
            4'd4, 4'd6, 4'd9, 4'd11:                    ok = (d <= 5'd30);
            4'd2:                                       ok = (d <= 5'd28);
            default:                                    ok = 1'b0;
        endcase
    end
    return ok;
endfunction

property P_DATE_CALENDAR;
    @(posedge clk) inf.date_valid
        |-> legal_date(inf.D.d_date[0].M, inf.D.d_date[0].D);
endproperty

//----------------------------------------------------------------
// A9. AR_VALID and AW_VALID never both high.
//----------------------------------------------------------------
property P_AR_AW_EXCL;
    @(posedge clk) !(inf.AR_VALID && inf.AW_VALID);
endproperty

//----------------------------------------------------------------
// Unified failure reporter
//----------------------------------------------------------------
task automatic fail_assert(input int id);
    $display("\033[0;31m  Assertion %0d is violated  \033[0m", id);
    $fatal;
endtask

A1_reset_zero  : assert property (P_RESET_ZERO)      else fail_assert(1);
A2_lat_mas     : assert property (P_LATENCY_MAS)     else fail_assert(2);
A2_lat_restock : assert property (P_LATENCY_RESTOCK) else fail_assert(2);
A2_lat_hire    : assert property (P_LATENCY_HIRE)    else fail_assert(2);
A2_lat_pay     : assert property (P_LATENCY_PAY)     else fail_assert(2);
A2_lat_check   : assert property (P_LATENCY_CHECK)   else fail_assert(2);
A3_complete    : assert property (P_COMPLETE_NO_WARN)else fail_assert(3);
A4_gap_mas     : assert property (P_GAP_MAS)         else fail_assert(4);
A4_gap_restock : assert property (P_GAP_RESTOCK)     else fail_assert(4);
A4_gap_hire    : assert property (P_GAP_HIRE)        else fail_assert(4);
A4_gap_pay     : assert property (P_GAP_PAY)         else fail_assert(4);
A4_gap_check   : assert property (P_GAP_CHECK)       else fail_assert(4);
A5_onehot0     : assert property (P_INVALID_ONEHOT)  else fail_assert(5);
A6_outv_one    : assert property (P_OUT_VALID_ONE)   else fail_assert(6);
A7_next_op     : assert property (P_NEXT_OP)         else fail_assert(7);
A8_calendar    : assert property (P_DATE_CALENDAR)   else fail_assert(8);
A9_ar_aw_excl  : assert property (P_AR_AW_EXCL)      else fail_assert(9);

endmodule