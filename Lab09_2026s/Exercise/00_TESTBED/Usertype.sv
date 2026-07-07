/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2026 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : Usertype.sv
Module Name : usertype
Release version : v1.0 (Release Date: April-2025)
Author : Chia-Hsin Lee
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic  [2:0] { Make_and_Sell	 = 3'h0,
                            Restock          = 3'h1,
							Hire_Staff       = 3'h2,
                            Pay_Day          = 3'h3,
							Check_Valid_Date = 3'h4
							} Action;

typedef enum logic  [2:0] { No_Warn       = 3'b000, 
                            Date_Warn     = 3'b001, 
                            No_Staff_Warn = 3'b010,
							Stock_Warn    = 3'b011,
                            Balance_Warn  = 3'b100,
                            Restock_Warn  = 3'b101,
                            Staff_Warn    = 3'b110
                            } Warn_Msg;

typedef enum logic  [2:0] { Cookie     = 3'h0,
                            Bread      = 3'h1,
                            Fruit_Cake = 3'h2,
                            Pudding    = 3'h3,
                            Macaron    = 3'h4,
                            Pancake    = 3'h5,
                            Brownie    = 3'h6,
                            Scone      = 3'h7
                            } Dessert_Type;

typedef enum logic  [1:0] { Single	   = 2'b00,
                            Family_Set = 2'b10,
							Party_Pack = 2'b11
                            } Order_Mode;

typedef logic [11:0] Stock;
typedef logic [11:0] Sales_t;
typedef logic [7:0]  Staff_t;
typedef logic [7:0]  Level_t;
typedef logic [23:0] Balance_t;
typedef logic [3:0]  Month;
typedef logic [4:0]  Day;
typedef logic [7:0]  Data_No;

typedef struct packed {
    Month M;
    Day D;
} Date;

typedef struct packed {
    Stock Flour;
    Stock Butter;
    Stock Milk;
    Stock Sugar;
    Stock Fruit;
    Sales_t Sales;
    Staff_t Staff;
    Level_t Level;
    Balance_t Balance;
    Month M;
    Day D;
} Data_Dir;

typedef struct packed {
    Dessert_Type Type;
    Order_Mode Mode;
} Order_Info;

typedef union packed{ 
    Action [23:0] d_act; // 3
    Dessert_Type [23:0] d_type; // 3
    Order_Mode [35:0] d_mode; // 2
    Staff_t [8:0] d_staff; // 8
    Date [7:0] d_date; // 9
    Data_No [8:0] d_data_no; // 8
    Stock [5:0] d_stock;  // 12
} Data;

//################################################## Don't revise the code above

//#################################
// Type your user define type here
//#################################



//################################################## Don't revise the code below
endpackage

import usertype::*; //import usertype into $unit

`endif