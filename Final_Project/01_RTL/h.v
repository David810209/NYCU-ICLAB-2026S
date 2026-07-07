//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2026 Spring Midterm Project: Dual-Core CPU 
//   Author                           : Ying-Yu Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : DCCPU.v
//   Module Name : DCCPU.v
//   Release version : V1.0
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
`define INST_OPCODE_FIELD  15:13  
`define INST_RS_FIELD      12:10  
`define INST_RT_FIELD       9: 7  
`define INST_RD_FIELD       6: 4  
`define INST_FUNC_FIELD     3: 1   
`define INST_DONTCARE_BIT   0: 0   
`define INST_RL_FIELD       3: 1   
`define INST_IMM_FIELD      6: 0   
`define INST_ADDR_FIELD    12: 0   
module DCCPU(
// Input
    clk,
    rst_n,
// Output
    stall_1,
    stall_2,
//===== AXI-4 Instruction1 DRAM =====
    arid_m_inf_inst_1,
    araddr_m_inf_inst_1,
    arlen_m_inf_inst_1,
    arsize_m_inf_inst_1,
    arburst_m_inf_inst_1,
    arvalid_m_inf_inst_1,
    arready_m_inf_inst_1,

    rid_m_inf_inst_1,
    rdata_m_inf_inst_1,
    rresp_m_inf_inst_1,
    rlast_m_inf_inst_1,
    rvalid_m_inf_inst_1,
    rready_m_inf_inst_1,
//===== AXI-4 Instruction2 DRAM =====
    arid_m_inf_inst_2,
    araddr_m_inf_inst_2,
    arlen_m_inf_inst_2,
    arsize_m_inf_inst_2,
    arburst_m_inf_inst_2,
    arvalid_m_inf_inst_2,
    arready_m_inf_inst_2,

    rid_m_inf_inst_2,
    rdata_m_inf_inst_2,
    rresp_m_inf_inst_2,
    rlast_m_inf_inst_2,
    rvalid_m_inf_inst_2,
    rready_m_inf_inst_2,
//===== AXI-4 Data DRAM =====
    arid_m_inf_data,
    araddr_m_inf_data,
    arlen_m_inf_data,
    arsize_m_inf_data,
    arburst_m_inf_data,
    arvalid_m_inf_data,
    arready_m_inf_data,

    rid_m_inf_data,
    rdata_m_inf_data,
    rresp_m_inf_data,
    rlast_m_inf_data,
    rvalid_m_inf_data,
    rready_m_inf_data,

    awid_m_inf_data,
    awaddr_m_inf_data,
    awsize_m_inf_data,
    awburst_m_inf_data,
    awlen_m_inf_data,
    awvalid_m_inf_data,
    awready_m_inf_data,
                
    wdata_m_inf_data,
    wlast_m_inf_data,
    wvalid_m_inf_data,
    wready_m_inf_data,

    bid_m_inf_data,
    bresp_m_inf_data,
    bvalid_m_inf_data,
    bready_m_inf_data
);
// Input port
input wire clk, rst_n;
// Output port
output reg  stall_1, stall_2;

parameter ID_WIDTH=4, ADDR_WIDTH=32, DATA_WIDTH=16, BURST_LEN=7;

// AXI Interface wire connecttion for pseudo-DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

//########################################### Instruction1 DRAM
// axi read addr channel 
// src master
output wire [ID_WIDTH-1:0]   arid_m_inf_inst_1; 
output wire [ADDR_WIDTH-1:0] araddr_m_inf_inst_1;
output wire [BURST_LEN-1:0]  arlen_m_inf_inst_1;
output wire [2:0]            arsize_m_inf_inst_1; 
output wire [1:0]            arburst_m_inf_inst_1; 
output wire                  arvalid_m_inf_inst_1;
// src slave
input wire                   arready_m_inf_inst_1;
// ------------------------

// axi read data channel 
// slave
input wire [ID_WIDTH-1:0]   rid_m_inf_inst_1; 
input wire [DATA_WIDTH-1:0] rdata_m_inf_inst_1;
input wire [1:0]            rresp_m_inf_inst_1; 
input wire                  rlast_m_inf_inst_1;
input wire                  rvalid_m_inf_inst_1;
// master
output wire                 rready_m_inf_inst_1;
// -----------------------------

//########################################### Instruction2 DRAM
// axi read addr channel 
// src master
output wire [ID_WIDTH-1:0]   arid_m_inf_inst_2; 
output wire [ADDR_WIDTH-1:0] araddr_m_inf_inst_2;
output wire [BURST_LEN-1:0]  arlen_m_inf_inst_2;
output wire [2:0]            arsize_m_inf_inst_2; 
output wire [1:0]            arburst_m_inf_inst_2; 
output wire                  arvalid_m_inf_inst_2;
// src slave
input wire                   arready_m_inf_inst_2;
// ------------------------

// axi read data channel 
// slave
input wire [ID_WIDTH-1:0]   rid_m_inf_inst_2; 
input wire [DATA_WIDTH-1:0] rdata_m_inf_inst_2;
input wire [1:0]            rresp_m_inf_inst_2; 
input wire                  rlast_m_inf_inst_2;
input wire                  rvalid_m_inf_inst_2;
// master
output wire                 rready_m_inf_inst_2;
// -----------------------------

//########################################### Data DRAM 
// axi write addr channel 
// src master
output wire [ID_WIDTH-1:0]   awid_m_inf_data; 
output wire [ADDR_WIDTH-1:0] awaddr_m_inf_data;
output wire [2:0]            awsize_m_inf_data; 
output wire [1:0]            awburst_m_inf_data; 
output wire [BURST_LEN-1:0]  awlen_m_inf_data;
output wire                  awvalid_m_inf_data;
// src slave
input wire                   awready_m_inf_data;
// -------------------------

// axi write data channel 
// src master
output wire [DATA_WIDTH-1:0] wdata_m_inf_data;
output wire                  wlast_m_inf_data;
output wire                  wvalid_m_inf_data;
// src slave
input wire                   wready_m_inf_data;

// axi write resp channel 
// src slave
input wire  [ID_WIDTH-1:0] bid_m_inf_data; 
input wire  [1:0]          bresp_m_inf_data; 
input wire                 bvalid_m_inf_data;
// src master 
output wire                bready_m_inf_data;
// ------------------------

// axi read addr channel 
// src master
output wire [ID_WIDTH-1:0]   arid_m_inf_data; 
output wire [ADDR_WIDTH-1:0] araddr_m_inf_data;
output wire [BURST_LEN-1:0]  arlen_m_inf_data;
output wire [2:0]            arsize_m_inf_data; 
output wire [1:0]            arburst_m_inf_data; 
output wire                  arvalid_m_inf_data;
// src slave
input wire                   arready_m_inf_data;
// ------------------------

// axi read data channel 
// slave
input wire [ID_WIDTH-1:0]   rid_m_inf_data; 
input wire [DATA_WIDTH-1:0] rdata_m_inf_data;
input wire [1:0]            rresp_m_inf_data; 
input wire                  rlast_m_inf_data;
input wire                  rvalid_m_inf_data;
// master
output wire                 rready_m_inf_data;
// -----------------------------
//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/
reg [15:0] core_1_r0, core_1_r1, core_1_r2, core_1_r3;
reg [15:0] core_1_r4, core_1_r5, core_1_r6, core_1_r7;
reg [15:0] core_2_r0, core_2_r1, core_2_r2, core_2_r3;
reg [15:0] core_2_r4, core_2_r5, core_2_r6, core_2_r7;
// -----------------------------



//==============================================================================
//   AXI Master Submodule Interconnects
//   Three independent AXI masters: inst_1, inst_2, data
//==============================================================================
// Inst DRAM 1 (read-only usage)
// Area note:
// These signals are pure combinational controls for CACHE, so use wire assign
// instead of reg + always@(*) blocks.
wire                   cache_type;
wire                   cache_request;
wire [ADDR_WIDTH-1:0]  cache_address;
wire                   cache_core;
wire [DATA_WIDTH-1:0]  cache_write_data;
wire                   cache_is_write;
wire                   cache_flush;
wire                   cache_valid;
wire [DATA_WIDTH-1:0]  cache_data;
//==============================================================================
// program read_counter declare
//==============================================================================
reg [12:0] pc_c0;
reg [12:0] pc_c1;

reg [15:0] inst_c0;
reg [15:0] inst_c1;
reg [5:0] inst_counter;
// ======================================================
// STATE MACHINE STATE
// ======================================================
localparam FETCH   		= 3'd0;
localparam DECODE  		= 3'd1;
localparam EXECUTE 		= 3'd2;
localparam EXECUTE_2 	= 3'd3;
localparam MEMORY  		= 3'd4;
localparam WRITE   		= 3'd5;
localparam FLUSH   		= 3'd6;
wire exe2write;
wire exe2exe2;
wire exe2MEM;
// ======================================================
// Instruction opcode
// ======================================================
localparam INST_RTYPE    = 3'b000; // ADD, SUB, AND, OR, NAND, NOR, XOR, SLT
localparam INST_MULT     = 3'b001; // MULT
localparam INST_ADDI     = 3'b010; // ADDI
localparam INST_SUBI     = 3'b011; // SUBI
localparam INST_LW       = 3'b100; // LOAD
localparam INST_SW       = 3'b101; // STORE
localparam INST_BRANCH   = 3'b110; // BEQ
localparam INST_JUMP     = 3'b111; // JUMP
// ======================================================
// R-type funct
// ======================================================
localparam FUNC_ADD      = 3'b000;
localparam FUNC_SUB      = 3'b001;
localparam FUNC_AND      = 3'b010;
localparam FUNC_OR       = 3'b011;
localparam FUNC_NAND     = 3'b100;
localparam FUNC_NOR      = 3'b101;
localparam FUNC_XOR      = 3'b110;
localparam FUNC_SLT      = 3'b111;

reg [2:0] state;      			// FSM state
reg [2:0] next_state; 			// Next state for FSM
reg current_fetch_core;
reg current_execute_core;
reg swap_execute_core;
reg [15:0] alu_result_reg;
wire signed [15:0] alu_result;
wire               branch_taken;
wire [2:0]  instruction_OPCODE;
wire [3:0]  instruction_RS;
wire [3:0]  instruction_RT;
wire [3:0]  instruction_RD;
wire [3:0]  instruction_RL;
wire [2:0]  instruction_FUNC;
wire [6:0]  instruction_IMM;
wire [12:0] instruction_ADDR;
reg [15:0] RS;
reg [15:0] RT;
//==============================================================================
// CACHE
//==============================================================================
// Use the already existing RT read mux as store data.
// The original write_data_exe2mem case used default 0 when instruction_RT[3] = 1.
// Keep the same behavior here.
assign cache_write_data = instruction_RT[3] ? 16'd0 : RT;

assign cache_address = (state == FETCH  && current_fetch_core == 1'b0) ? {{(ADDR_WIDTH-13){1'b0}}, pc_c0} :
                       (state == FETCH  && current_fetch_core == 1'b1) ? {{(ADDR_WIDTH-13){1'b0}}, pc_c1} :
                       (state == MEMORY)                               ? {{(ADDR_WIDTH-16){1'b0}}, ((alu_result_reg <<< 1) + 16'h1000)} :
                                                                         {ADDR_WIDTH{1'b0}};

assign cache_request  = (state == MEMORY) || (state == FETCH);
assign cache_core     = (state == FETCH) && current_fetch_core;
assign cache_type     = (state == MEMORY);
assign cache_is_write = (state == MEMORY) && (instruction_OPCODE == INST_SW);
assign cache_flush    = (state == FLUSH);

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        inst_counter <= 0;
    end
    else if(state == WRITE && next_state == FETCH)begin
        inst_counter <= inst_counter + 1;
    end
    else if(state == EXECUTE && current_execute_core == 1 && (instruction_OPCODE == INST_BRANCH || instruction_OPCODE == INST_JUMP))begin
        inst_counter <= inst_counter + 1;
    end
    else if(state == FLUSH && next_state == FETCH)begin
        inst_counter <= 0;
    end
end
//==============================================================================
// program read_counter 
//==============================================================================
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        current_fetch_core <= 0;
    end
    else if(state == FETCH && cache_valid) begin
        current_fetch_core <= ~current_fetch_core;
    end
end

wire exec_fetch_load = (state == FETCH) && (current_fetch_core == 1'b1) && cache_valid;
wire exec_swap_cond  = (cache_data[`INST_OPCODE_FIELD] == 3'b101) 
                    && (inst_c0[`INST_OPCODE_FIELD] == 3'b100);
wire exec_toggle     = (state == EXECUTE && (instruction_OPCODE == INST_BRANCH 
                                          || instruction_OPCODE == INST_JUMP))
                    || (state == WRITE);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)             current_execute_core <= 1'b0;
    else if(exec_fetch_load) current_execute_core <= exec_swap_cond;
    else if(exec_toggle)     current_execute_core <= ~current_execute_core;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        swap_execute_core <= 0;
    end
    else if(state == FETCH && current_fetch_core == 1 && cache_valid)begin
        if(cache_data[`INST_OPCODE_FIELD] == 3'b101 && inst_c0[`INST_OPCODE_FIELD] == 3'b100)begin
            swap_execute_core <= 1;
        end
        else begin
            swap_execute_core <= 0;
        end
    end
end

wire [12:0] pc_cur  = current_execute_core ? pc_c1 : pc_c0;
// Sign-extend 7-bit immediate to 13 bits
wire [12:0] imm_sext = {{6{instruction_IMM[6]}}, instruction_IMM};

wire [12:0] pc_next = branch_taken                       ? (pc_cur + 13'd2 + (imm_sext <<< 1))
                    : (instruction_OPCODE == INST_JUMP)  ? instruction_ADDR
                    :                                      (pc_cur + 13'd2);

wire pc_update = (state == EXECUTE) && (pc_cur != 13'h1ffe);

wire pc_c0_clk_en = (state == MEMORY || state == EXECUTE || state == DECODE || state == EXECUTE_2);
wire pc_c1_clk_en = (state == MEMORY || state == EXECUTE || state == DECODE || state == EXECUTE_2);

wire pc_c0_gclk = clk & pc_c0_clk_en;
wire pc_c1_gclk = clk & pc_c1_clk_en;


always @(posedge pc_c0_gclk or negedge rst_n) begin
    if(!rst_n) pc_c0 <= 13'd0;
    else if(pc_update && current_execute_core == 1'b0) pc_c0 <= pc_next;
end

always @(posedge pc_c1_gclk or negedge rst_n) begin
    if(!rst_n) pc_c1 <= 13'd0;
    else if(pc_update && current_execute_core == 1'b1) pc_c1 <= pc_next;
end

//==============================================================================
// FETCH
//============================================================================== 

// ===================================================
// inst_c0 clock gating
// ===================================================
wire inst_c0_clk_en;
wire inst_c0_gclk;

assign inst_c0_clk_en = (state == FETCH) && cache_valid && (current_fetch_core == 1'b0);
assign inst_c0_gclk   = clk & inst_c0_clk_en;

always @(posedge inst_c0_gclk or negedge rst_n) begin
    if(!rst_n) begin
        inst_c0 <= 16'd0;
    end
    else begin
        inst_c0 <= cache_data;
    end
end

// ===================================================
// inst_c1 clock gating
// ===================================================
wire inst_c1_clk_en;
wire inst_c1_gclk;

assign inst_c1_clk_en = (state == FETCH) && cache_valid && (current_fetch_core == 1'b1);
assign inst_c1_gclk   = clk & inst_c1_clk_en;

always @(posedge inst_c1_gclk or negedge rst_n) begin
    if(!rst_n) begin
        inst_c1 <= 16'd0;
    end
    else begin
        inst_c1 <= cache_data;
    end
end

//==============================================================================
// DECODE
//============================================================================== 

wire [15:0] decode_instruction = current_execute_core == 0 ? inst_c0 : inst_c1;

assign instruction_OPCODE = decode_instruction[`INST_OPCODE_FIELD];
assign instruction_RS     = decode_instruction[`INST_RS_FIELD];
assign instruction_RT     = decode_instruction[`INST_RT_FIELD];
assign instruction_RD     = decode_instruction[`INST_RD_FIELD];
assign instruction_RL     = decode_instruction[`INST_RL_FIELD];
assign instruction_FUNC   = decode_instruction[`INST_FUNC_FIELD];
assign instruction_IMM    = decode_instruction[`INST_IMM_FIELD];
assign instruction_ADDR   = decode_instruction[`INST_ADDR_FIELD];

always @(*) begin
    if(current_execute_core == 0) begin
        case(instruction_RS[2:0])
            3'd0: RS = core_1_r0;
            3'd1: RS = core_1_r1;
            3'd2: RS = core_1_r2;
            3'd3: RS = core_1_r3;
            3'd4: RS = core_1_r4;
            3'd5: RS = core_1_r5;
            3'd6: RS = core_1_r6;
            3'd7: RS = core_1_r7;
        endcase
    end
    else begin
        case(instruction_RS[2:0])
            3'd0: RS = core_2_r0;
            3'd1: RS = core_2_r1;
            3'd2: RS = core_2_r2;
            3'd3: RS = core_2_r3;
            3'd4: RS = core_2_r4;
            3'd5: RS = core_2_r5;
            3'd6: RS = core_2_r6;
            3'd7: RS = core_2_r7;
        endcase
    end
end

always @(*) begin
    if(current_execute_core == 0) begin
        case(instruction_RT[2:0])
            3'd0: RT = core_1_r0;
            3'd1: RT = core_1_r1;
            3'd2: RT = core_1_r2;
            3'd3: RT = core_1_r3;
            3'd4: RT = core_1_r4;
            3'd5: RT = core_1_r5;
            3'd6: RT = core_1_r6;
            3'd7: RT = core_1_r7;
        endcase
    end
    else begin
        case(instruction_RT[2:0])
            3'd0: RT = core_2_r0;
            3'd1: RT = core_2_r1;
            3'd2: RT = core_2_r2;
            3'd3: RT = core_2_r3;
            3'd4: RT = core_2_r4;
            3'd5: RT = core_2_r5;
            3'd6: RT = core_2_r6;
            3'd7: RT = core_2_r7;
        endcase
    end
end

//==============================================================================
// DECODE to EXECUTE
//============================================================================== 
// These are combinational operands, not real pipeline registers.
// Keep the same operand selection behavior but avoid reg + always@(*) logic.
wire [15:0] imm_ext;
wire        use_rt_operand;
wire [15:0] operand1_w;
wire [15:0] operand2_w;

assign imm_ext = {{9{instruction_IMM[6]}}, instruction_IMM};

assign use_rt_operand = (instruction_OPCODE == INST_RTYPE)  ||
                        (instruction_OPCODE == INST_MULT)   ||
                        (instruction_OPCODE == INST_BRANCH);

assign operand1_w = RS;
assign operand2_w = use_rt_operand ? RT : imm_ext;

//==============================================================================
// EXECUTE
//============================================================================== 

ALU u_alu (
    .instruction_OPCODE (instruction_OPCODE),
    .instruction_FUNC   (instruction_FUNC),
    .operand1           (operand1_w),
    .operand2           (operand2_w),
    .alu_result         (alu_result),
    .branch_taken       (branch_taken)
);

wire signed [31:0] mult_result;
wire mult_done;
wire mult_start = (instruction_OPCODE == INST_MULT) && state == EXECUTE;
// wire branch_taken;
mult_16bit u_mult (
    .clk          (clk),
    .rst_n        (rst_n),
    .mult_en      (mult_start),
    .A            (operand1_w),
    .B            (operand2_w),
    .result       (mult_result),
    .mult_done    (mult_done)
);

//==============================================================================
// EXECUTE to MEMORY
//==============================================================================


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        alu_result_reg <= 0;
    end
    else if(state == EXECUTE && exe2MEM)begin
        alu_result_reg <= alu_result;
    end
end

// Store data is provided by cache_write_data = instruction_RT[3] ? 0 : RT above.

//==============================================================================
// EXECUTE to WRITEBACK
//==============================================================================
// reg [15:0] alu_result_reg;
reg [15:0] write_target1_data_wb;
reg [2:0]  write_target1_reg_wb;
reg        write_target1_valid_wb;
reg [15:0] write_target2_data_wb;
reg [2:0]  write_target2_reg_wb;
reg        write_target2_valid_wb;

// ===================================================
// write target WB clock gating
// ===================================================
wire wb_reg_clk_en;
wire wb_reg_gclk;

assign wb_reg_clk_en =
    (state == EXECUTE && exe2write) ||
    (state == EXECUTE_2 && mult_done) ||
    (state == MEMORY && cache_valid && instruction_OPCODE == INST_LW) ||
    (state == WRITE && (write_target1_valid_wb || write_target2_valid_wb));

assign wb_reg_gclk = clk & wb_reg_clk_en;

always @(posedge wb_reg_gclk or negedge rst_n) begin
    if(!rst_n) begin
        write_target1_data_wb  <= 16'd0;
        write_target1_valid_wb <= 1'b0;
        write_target2_data_wb  <= 16'd0;
        write_target2_valid_wb <= 1'b0;
    end
    else if(state == EXECUTE && exe2write) begin
        write_target1_data_wb  <= alu_result;
        write_target1_valid_wb <= 1'b1;
        write_target2_data_wb  <= 16'd0;
        write_target2_valid_wb <= 1'b0;
    end
    else if(state == EXECUTE_2 && mult_done) begin
        write_target1_data_wb  <= mult_result[31:16];
        write_target1_valid_wb <= 1'b1;
        write_target2_data_wb  <= mult_result[15:0];
        write_target2_valid_wb <= 1'b1;
    end
    else if(state == MEMORY && cache_valid && instruction_OPCODE == INST_LW) begin
        write_target1_data_wb  <= cache_data;
        write_target1_valid_wb <= 1'b1;
    end
    else if(state == WRITE) begin
        write_target1_valid_wb <= 1'b0;
        write_target2_valid_wb <= 1'b0;
    end
end

//==============================================================================
// WRITEBACK
//==============================================================================
wire [2:0] wb1_target = (instruction_OPCODE == INST_RTYPE ||
                         instruction_OPCODE == INST_MULT)  ? instruction_RD[2:0] :
                                                             instruction_RT[2:0];  // ADDI/SUBI/LW
wire [2:0] wb2_target = instruction_RL[2:0];  // MULT only

// Share target decoding to reduce duplicated 3-bit comparators in every register.
// Priority is unchanged: target1 has higher priority than target2.
wire [7:0] wb1_dec;
wire [7:0] wb2_dec;

assign wb1_dec = write_target1_valid_wb ? (8'b0000_0001 << wb1_target) : 8'b0000_0000;
assign wb2_dec = write_target2_valid_wb ? (8'b0000_0001 << wb2_target) : 8'b0000_0000;

// ======================================================
// core write enable
// ======================================================
wire core_1_write_en;
wire core_2_write_en;

assign core_1_write_en = (state == WRITE) && (current_execute_core == 1'b0);
assign core_2_write_en = (state == WRITE) && (current_execute_core == 1'b1);

// ======================================================
// clock enable
// ======================================================
wire core_1_r0_clk_en = core_1_write_en && (wb1_dec[0] || wb2_dec[0]);
wire core_1_r1_clk_en = core_1_write_en && (wb1_dec[1] || wb2_dec[1]);
wire core_1_r2_clk_en = core_1_write_en && (wb1_dec[2] || wb2_dec[2]);
wire core_1_r3_clk_en = core_1_write_en && (wb1_dec[3] || wb2_dec[3]);
wire core_1_r4_clk_en = core_1_write_en && (wb1_dec[4] || wb2_dec[4]);
wire core_1_r5_clk_en = core_1_write_en && (wb1_dec[5] || wb2_dec[5]);
wire core_1_r6_clk_en = core_1_write_en && (wb1_dec[6] || wb2_dec[6]);
wire core_1_r7_clk_en = core_1_write_en && (wb1_dec[7] || wb2_dec[7]);

wire core_2_r0_clk_en = core_2_write_en && (wb1_dec[0] || wb2_dec[0]);
wire core_2_r1_clk_en = core_2_write_en && (wb1_dec[1] || wb2_dec[1]);
wire core_2_r2_clk_en = core_2_write_en && (wb1_dec[2] || wb2_dec[2]);
wire core_2_r3_clk_en = core_2_write_en && (wb1_dec[3] || wb2_dec[3]);
wire core_2_r4_clk_en = core_2_write_en && (wb1_dec[4] || wb2_dec[4]);
wire core_2_r5_clk_en = core_2_write_en && (wb1_dec[5] || wb2_dec[5]);
wire core_2_r6_clk_en = core_2_write_en && (wb1_dec[6] || wb2_dec[6]);
wire core_2_r7_clk_en = core_2_write_en && (wb1_dec[7] || wb2_dec[7]);

// ======================================================
// gated clock, no latch
// ======================================================
wire core_1_r0_gclk = clk & core_1_r0_clk_en;
wire core_1_r1_gclk = clk & core_1_r1_clk_en;
wire core_1_r2_gclk = clk & core_1_r2_clk_en;
wire core_1_r3_gclk = clk & core_1_r3_clk_en;
wire core_1_r4_gclk = clk & core_1_r4_clk_en;
wire core_1_r5_gclk = clk & core_1_r5_clk_en;
wire core_1_r6_gclk = clk & core_1_r6_clk_en;
wire core_1_r7_gclk = clk & core_1_r7_clk_en;

wire core_2_r0_gclk = clk & core_2_r0_clk_en;
wire core_2_r1_gclk = clk & core_2_r1_clk_en;
wire core_2_r2_gclk = clk & core_2_r2_clk_en;
wire core_2_r3_gclk = clk & core_2_r3_clk_en;
wire core_2_r4_gclk = clk & core_2_r4_clk_en;
wire core_2_r5_gclk = clk & core_2_r5_clk_en;
wire core_2_r6_gclk = clk & core_2_r6_clk_en;
wire core_2_r7_gclk = clk & core_2_r7_clk_en;

// ======================================================
// core_1 registers
// ======================================================
always @(posedge core_1_r0_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r0 <= 16'd0;
    end
    else begin
        if(wb1_dec[0])
            core_1_r0 <= write_target1_data_wb;
        else if(wb2_dec[0])
            core_1_r0 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r1_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r1 <= 16'd0;
    end
    else begin
        if(wb1_dec[1])
            core_1_r1 <= write_target1_data_wb;
        else if(wb2_dec[1])
            core_1_r1 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r2_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r2 <= 16'd0;
    end
    else begin
        if(wb1_dec[2])
            core_1_r2 <= write_target1_data_wb;
        else if(wb2_dec[2])
            core_1_r2 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r3_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r3 <= 16'd0;
    end
    else begin
        if(wb1_dec[3])
            core_1_r3 <= write_target1_data_wb;
        else if(wb2_dec[3])
            core_1_r3 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r4_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r4 <= 16'd0;
    end
    else begin
        if(wb1_dec[4])
            core_1_r4 <= write_target1_data_wb;
        else if(wb2_dec[4])
            core_1_r4 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r5_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r5 <= 16'd0;
    end
    else begin
        if(wb1_dec[5])
            core_1_r5 <= write_target1_data_wb;
        else if(wb2_dec[5])
            core_1_r5 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r6_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r6 <= 16'd0;
    end
    else begin
        if(wb1_dec[6])
            core_1_r6 <= write_target1_data_wb;
        else if(wb2_dec[6])
            core_1_r6 <= write_target2_data_wb;
    end
end

always @(posedge core_1_r7_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_1_r7 <= 16'd0;
    end
    else begin
        if(wb1_dec[7])
            core_1_r7 <= write_target1_data_wb;
        else if(wb2_dec[7])
            core_1_r7 <= write_target2_data_wb;
    end
end

// ======================================================
// core_2 registers
// ======================================================
always @(posedge core_2_r0_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r0 <= 16'd0;
    end
    else begin
        if(wb1_dec[0])
            core_2_r0 <= write_target1_data_wb;
        else if(wb2_dec[0])
            core_2_r0 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r1_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r1 <= 16'd0;
    end
    else begin
        if(wb1_dec[1])
            core_2_r1 <= write_target1_data_wb;
        else if(wb2_dec[1])
            core_2_r1 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r2_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r2 <= 16'd0;
    end
    else begin
        if(wb1_dec[2])
            core_2_r2 <= write_target1_data_wb;
        else if(wb2_dec[2])
            core_2_r2 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r3_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r3 <= 16'd0;
    end
    else begin
        if(wb1_dec[3])
            core_2_r3 <= write_target1_data_wb;
        else if(wb2_dec[3])
            core_2_r3 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r4_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r4 <= 16'd0;
    end
    else begin
        if(wb1_dec[4])
            core_2_r4 <= write_target1_data_wb;
        else if(wb2_dec[4])
            core_2_r4 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r5_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r5 <= 16'd0;
    end
    else begin
        if(wb1_dec[5])
            core_2_r5 <= write_target1_data_wb;
        else if(wb2_dec[5])
            core_2_r5 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r6_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r6 <= 16'd0;
    end
    else begin
        if(wb1_dec[6])
            core_2_r6 <= write_target1_data_wb;
        else if(wb2_dec[6])
            core_2_r6 <= write_target2_data_wb;
    end
end

always @(posedge core_2_r7_gclk or negedge rst_n) begin
    if(!rst_n) begin
        core_2_r7 <= 16'd0;
    end
    else begin
        if(wb1_dec[7])
            core_2_r7 <= write_target1_data_wb;
        else if(wb2_dec[7])
            core_2_r7 <= write_target2_data_wb;
    end
end

//==============================================================================
// STALL LOGIC
//==============================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        stall_1 <= 1;
        stall_2 <= 1;
    end
    else if(state == WRITE && next_state == FETCH)begin
        stall_1 <= 0;
        stall_2 <= 0;
    end
    else if(state == FLUSH && cache_valid)begin
        stall_1 <= 0;
        stall_2 <= 0;
    end
    else if(state == EXECUTE && next_state == FETCH)begin
        stall_1 <= 0;
        stall_2 <= 0;
    end
    else begin
        stall_1 <= 1;
        stall_2 <= 1;
    end
end

//==============================================================================
// FSM
//==============================================================================
assign exe2write = (instruction_OPCODE == INST_RTYPE) || (instruction_OPCODE == INST_ADDI) || (instruction_OPCODE == INST_SUBI);
assign exe2exe2  = instruction_OPCODE == INST_MULT;
assign exe2MEM   = instruction_OPCODE == INST_LW || instruction_OPCODE == INST_SW;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
    	state <= FETCH; // Reset to FETCH state
  	end else begin
    	state <= next_state; // Transition to next state
  	end
end

always @(*) begin
    next_state = FETCH;
    case(state)
        FETCH:begin
            if(cache_valid && current_fetch_core == 1) begin
                next_state = DECODE;
            end
            else if(cache_valid && current_fetch_core == 0)begin
                next_state = FETCH;
            end
            else begin
                next_state = FETCH;
            end
        end
        DECODE:begin
            next_state = EXECUTE;
        end
        EXECUTE:begin
            if(exe2write)     next_state = WRITE;
            else if(exe2exe2) next_state = EXECUTE_2;
            else if(exe2MEM)  next_state = MEMORY;
            else if(instruction_OPCODE == INST_BRANCH || instruction_OPCODE == INST_JUMP) begin
                if(current_execute_core == 0) next_state = DECODE;
                else if(current_execute_core == 1 ) begin
                    if(inst_counter == 49 || pc_c0 == 32'h1ffe)begin
                        next_state = FLUSH;
                    end
                    else begin
                        next_state = FETCH;
                    end
                end
            end
        end
        EXECUTE_2:begin
            if(mult_done) next_state = WRITE;
            else next_state = EXECUTE_2;
        end
        MEMORY:begin
            if(cache_valid) next_state = WRITE;
            else next_state = MEMORY;
        end
        WRITE:begin
            if(current_execute_core == 0 && swap_execute_core == 0)begin
                next_state = DECODE;
            end
            else if(current_execute_core == 1 && swap_execute_core == 1)begin
                next_state = DECODE;
            end 
            else if(current_execute_core == 0 && swap_execute_core == 1)begin
                if(inst_counter == 49 || pc_c0 == 32'h1ffe)begin
                    next_state = FLUSH;
                end
                else begin           
                    next_state = FETCH;
                end
            end
            else if(current_execute_core == 1 && swap_execute_core == 0)begin
                if(inst_counter == 49 || pc_c0 == 32'h1ffe)begin
                    next_state = FLUSH;
                end
                else begin           
                    next_state = FETCH;
                end
            end
        end
        FLUSH:begin
            if(cache_valid) begin
                next_state = FETCH;
            end
            else next_state = FLUSH;
        end
        // default:   next_state = FETCH;
    endcase
end



// ---- Instantiate AXI master for Inst DRAM 1 ----
// ---- Instantiate AXI master for Inst DRAM 1 / 2 ----
CACHE #(
    .ID_WIDTH   (ID_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .BURST_LEN  (BURST_LEN)
) u_axi_inst_1 (
    .clk   (clk),
    .rst_n (rst_n),

    // CPU-side
    .request     (cache_request),
    .address     (cache_address),
    .request_type(cache_type), 
    .core        (cache_core),
    .is_write    (cache_is_write),
    .write_data  (cache_write_data),
    .flush       (cache_flush),
    .out_data    (cache_data),
    .out_valid   (cache_valid),

    //================ i1 ================
    // AXI read addr
    .arid_m_inf_i1    (arid_m_inf_inst_1),
    .araddr_m_inf_i1  (araddr_m_inf_inst_1),
    .arlen_m_inf_i1   (arlen_m_inf_inst_1),
    .arsize_m_inf_i1  (arsize_m_inf_inst_1),
    .arburst_m_inf_i1 (arburst_m_inf_inst_1),
    .arvalid_m_inf_i1 (arvalid_m_inf_inst_1),
    .arready_m_inf_i1 (arready_m_inf_inst_1),

    // AXI read data
    .rid_m_inf_i1     (rid_m_inf_inst_1),
    .rdata_m_inf_i1   (rdata_m_inf_inst_1),
    .rresp_m_inf_i1   (rresp_m_inf_inst_1),
    .rlast_m_inf_i1   (rlast_m_inf_inst_1),
    .rvalid_m_inf_i1  (rvalid_m_inf_inst_1),
    .rready_m_inf_i1  (rready_m_inf_inst_1),

    //================ i2 ================
    // AXI read addr
    .arid_m_inf_i2    (arid_m_inf_inst_2),
    .araddr_m_inf_i2  (araddr_m_inf_inst_2),
    .arlen_m_inf_i2   (arlen_m_inf_inst_2),
    .arsize_m_inf_i2  (arsize_m_inf_inst_2),
    .arburst_m_inf_i2 (arburst_m_inf_inst_2),
    .arvalid_m_inf_i2 (arvalid_m_inf_inst_2),
    .arready_m_inf_i2 (arready_m_inf_inst_2),

    // AXI read data
    .rid_m_inf_i2     (rid_m_inf_inst_2),
    .rdata_m_inf_i2   (rdata_m_inf_inst_2),
    .rresp_m_inf_i2   (rresp_m_inf_inst_2),
    .rlast_m_inf_i2   (rlast_m_inf_inst_2),
    .rvalid_m_inf_i2  (rvalid_m_inf_inst_2),
    .rready_m_inf_i2  (rready_m_inf_inst_2),

    //================ Data ================
    // AXI write addr
    .awid_m_inf_data    (awid_m_inf_data),
    .awaddr_m_inf_data  (awaddr_m_inf_data),
    .awsize_m_inf_data  (awsize_m_inf_data),
    .awburst_m_inf_data (awburst_m_inf_data),
    .awlen_m_inf_data   (awlen_m_inf_data),
    .awvalid_m_inf_data (awvalid_m_inf_data),
    .awready_m_inf_data (awready_m_inf_data),

    // AXI write data
    .wdata_m_inf_data   (wdata_m_inf_data),
    .wlast_m_inf_data   (wlast_m_inf_data),
    .wvalid_m_inf_data  (wvalid_m_inf_data),
    .wready_m_inf_data  (wready_m_inf_data),

    // AXI write resp
    .bid_m_inf_data     (bid_m_inf_data),
    .bresp_m_inf_data   (bresp_m_inf_data),
    .bvalid_m_inf_data  (bvalid_m_inf_data),
    .bready_m_inf_data  (bready_m_inf_data),

    // AXI read addr
    .arid_m_inf_data    (arid_m_inf_data),
    .araddr_m_inf_data  (araddr_m_inf_data),
    .arlen_m_inf_data   (arlen_m_inf_data),
    .arsize_m_inf_data  (arsize_m_inf_data),
    .arburst_m_inf_data (arburst_m_inf_data),
    .arvalid_m_inf_data (arvalid_m_inf_data),
    .arready_m_inf_data (arready_m_inf_data),

    // AXI read data
    .rid_m_inf_data     (rid_m_inf_data),
    .rdata_m_inf_data   (rdata_m_inf_data),
    .rresp_m_inf_data   (rresp_m_inf_data),
    .rlast_m_inf_data   (rlast_m_inf_data),
    .rvalid_m_inf_data  (rvalid_m_inf_data),
    .rready_m_inf_data  (rready_m_inf_data)
);



endmodule



module ALU (
    // Inputs
    input              [2:0]   instruction_OPCODE,
    input              [2:0]   instruction_FUNC,
    input  signed      [15:0]  operand1,
    input  signed      [15:0]  operand2,

    // Outputs
    output      signed [15:0]  alu_result,
    output                     branch_taken
);

    localparam INST_RTYPE  = 3'b000;
    localparam INST_ADDI   = 3'b010;
    localparam INST_SUBI   = 3'b011;
    localparam INST_LW     = 3'b100;
    localparam INST_SW     = 3'b101;
    localparam INST_BRANCH = 3'b110;
    localparam INST_JUMP   = 3'b111;

    localparam FUNC_ADD  = 3'b000;
    localparam FUNC_SUB  = 3'b001;
    localparam FUNC_AND  = 3'b010;
    localparam FUNC_OR   = 3'b011;
    localparam FUNC_NAND = 3'b100;
    localparam FUNC_NOR  = 3'b101;
    localparam FUNC_XOR  = 3'b110;
    localparam FUNC_SLT  = 3'b111;

    //----------------------------------------------------------------
    // Decide whether the single add/sub unit does subtract or add.
    // Subtract is needed by: R-type SUB, R-type SLT, SUBI, BRANCH (eq check).
    // All other arithmetic/memory ops use add.
    //----------------------------------------------------------------
    wire is_rtype  = (instruction_OPCODE == INST_RTYPE);
    wire is_sub_r  = is_rtype && (instruction_FUNC == FUNC_SUB);
    wire is_slt_r  = is_rtype && (instruction_FUNC == FUNC_SLT);
    wire is_subi   = (instruction_OPCODE == INST_SUBI);
    wire is_branch = (instruction_OPCODE == INST_BRANCH);

    wire do_sub = is_sub_r | is_slt_r | is_subi | is_branch;

    //----------------------------------------------------------------
    // Shared add/sub: result = operand1 + (operand2 ^ {16{do_sub}}) + do_sub
    // One 16-bit adder covers ADD, SUB, ADDI, SUBI, LW, SW, SLT, BRANCH.
    //----------------------------------------------------------------
    wire signed [15:0] b_xor   = operand2 ^ {16{do_sub}};
    wire signed [15:0] add_out = operand1 + b_xor + {15'd0, do_sub};

    //----------------------------------------------------------------
    // SLT: operand1 < operand2 (signed).
    //   For signed compare, the correct sign of (a-b) accounting for
    //   overflow is: result_sign XOR overflow.
    //   overflow = (a[15] ^ b[15]) & (a[15] ^ sum[15])
    //   signed_lt = sum[15] ^ overflow
    //             = a[15] ^ b[15] ^ ((a[15] ^ b[15]) & (a[15] ^ sum[15]))
    //   Simpler: signed_lt = (a[15] == b[15]) ? sum[15] : a[15];
    //----------------------------------------------------------------
    wire signed_lt = (operand1[15] == operand2[15]) ? add_out[15]
                                                    : operand1[15];

    //----------------------------------------------------------------
    // Shared logic unit: one AND, one OR, one XOR. NAND/NOR just invert.
    //----------------------------------------------------------------
    wire [15:0] and_out = operand1 & operand2;
    wire [15:0] or_out  = operand1 | operand2;
    wire [15:0] xor_out = operand1 ^ operand2;

    //----------------------------------------------------------------
    // R-type result mux (driven by FUNC when OPCODE == RTYPE)
    //----------------------------------------------------------------
    reg [15:0] rtype_result;
    always @(*) begin
        case (instruction_FUNC)
            FUNC_ADD:  rtype_result = add_out;
            FUNC_SUB:  rtype_result = add_out;
            FUNC_AND:  rtype_result = and_out;
            FUNC_OR:   rtype_result = or_out;
            FUNC_NAND: rtype_result = ~and_out;
            FUNC_NOR:  rtype_result = ~or_out;
            FUNC_XOR:  rtype_result = xor_out;
            FUNC_SLT:  rtype_result = {15'd0, signed_lt};
            default:   rtype_result = 16'd0;
        endcase
    end

    //----------------------------------------------------------------
    // Top-level result mux driven by OPCODE.
    //   All arithmetic opcodes forward add_out.
    //   R-type picks from the rtype_result mux.
    //   BRANCH / JUMP don't produce a meaningful alu_result.
    //----------------------------------------------------------------
    reg [15:0] result_r;
    always @(*) begin
        case (instruction_OPCODE)
            INST_RTYPE:  result_r = rtype_result;
            INST_ADDI,
            INST_SUBI,
            INST_LW,
            INST_SW:     result_r = add_out;
            default:     result_r = 16'd0;
        endcase
    end

    assign alu_result = result_r;

    //----------------------------------------------------------------
    // branch_taken: true when operand1 == operand2 AND opcode is BRANCH.
    //   Reuse sub result: equal means (a - b) == 0.
    //----------------------------------------------------------------
    assign branch_taken = is_branch & (add_out == 16'd0);

endmodule

module mult_16bit(
    input                    clk,
    input                    rst_n,
    input                    mult_en,
    input  signed [15:0]     A,
    input  signed [15:0]     B,
    output signed [31:0]     result,
    output                   mult_done
);

    reg busy;
    reg [2:0] shift_cnt;

    reg signed [33:0] acc;
    reg signed [33:0] shifted_A;
    reg signed [17:0] booth_B;

    reg signed [31:0] result_r;
    reg done_r;

    reg signed [33:0] addend;
    reg               sub_op;

    wire signed [33:0] addend_mod;
    wire signed [33:0] acc_next;

    wire start_mult;
    wire mult_seq_en;

    assign start_mult = mult_en && !busy;


    assign mult_seq_en = start_mult || busy || done_r;

    //==================================================
    // Booth encoding
    //==================================================
    always @(*) begin
        addend = 34'sd0;
        sub_op = 1'b0;

        case (booth_B[2:0])
            3'b000,
            3'b111: begin
                addend = 34'sd0;
                sub_op = 1'b0;
            end

            3'b001,
            3'b010: begin
                addend = shifted_A;
                sub_op = 1'b0;
            end

            3'b011: begin
                addend = shifted_A <<< 1;
                sub_op = 1'b0;
            end

            3'b100: begin
                addend = shifted_A <<< 1;
                sub_op = 1'b1;
            end

            3'b101,
            3'b110: begin
                addend = shifted_A;
                sub_op = 1'b1;
            end

            default: begin
                addend = 34'sd0;
                sub_op = 1'b0;
            end
        endcase
    end

    assign addend_mod = sub_op ? ~addend : addend;
    assign acc_next   = acc + addend_mod + {{33{1'b0}}, sub_op};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy      <= 1'b0;
            shift_cnt <= 3'd0;
            acc       <= 34'sd0;
            shifted_A <= 34'sd0;
            booth_B   <= 18'sd0;
            result_r  <= 32'sd0;
            done_r    <= 1'b0;
        end
        else if (mult_seq_en) begin
            done_r <= 1'b0;

            if (start_mult) begin
                busy      <= 1'b1;
                shift_cnt <= 3'd0;
                acc       <= 34'sd0;
                shifted_A <= {{18{A[15]}}, A};
                booth_B   <= {B[15], B, 1'b0};
            end
            else if (busy) begin
                acc       <= acc_next;
                shifted_A <= shifted_A <<< 2;
                booth_B   <= {{2{booth_B[17]}}, booth_B[17:2]};

                if (shift_cnt == 3'd7) begin
                    busy     <= 1'b0;
                    done_r   <= 1'b1;
                    result_r <= acc_next[31:0];
                end
                else begin
                    shift_cnt <= shift_cnt + 3'd1;
                end
            end
        end
    end

    assign result    = result_r;
    assign mult_done = done_r;

endmodule



module CACHE #(
    parameter ID_WIDTH   = 4,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 16,
    parameter BURST_LEN  = 7
)(
    // Global
    input  wire                    clk,
    input  wire                    rst_n,

    // ======== CPU-side simplified handshake ========
    input  wire                    request,
    input  wire [ADDR_WIDTH-1:0]   address,
    input  wire                    request_type,
    input  wire                    core,
    input  wire                    is_write,
    input  wire [DATA_WIDTH-1:0]   write_data,
    input  wire                    flush,
    output reg  [DATA_WIDTH-1:0]   out_data,
    output reg                     out_valid,

    // ======== AXI-4 I$ core0 (i1) ========
    output wire [ID_WIDTH-1:0]     arid_m_inf_i1,
    output reg  [ADDR_WIDTH-1:0]   araddr_m_inf_i1,
    output wire [BURST_LEN-1:0]    arlen_m_inf_i1,
    output wire [2:0]              arsize_m_inf_i1,
    output wire [1:0]              arburst_m_inf_i1,
    output reg                     arvalid_m_inf_i1,
    input  wire                    arready_m_inf_i1,
    input  wire [ID_WIDTH-1:0]     rid_m_inf_i1,
    input  wire [DATA_WIDTH-1:0]   rdata_m_inf_i1,
    input  wire [1:0]              rresp_m_inf_i1,
    input  wire                    rlast_m_inf_i1,
    input  wire                    rvalid_m_inf_i1,
    output reg                     rready_m_inf_i1,

    // ======== AXI-4 I$ core1 (i2) ========
    output wire [ID_WIDTH-1:0]     arid_m_inf_i2,
    output reg  [ADDR_WIDTH-1:0]   araddr_m_inf_i2,
    output wire [BURST_LEN-1:0]    arlen_m_inf_i2,
    output wire [2:0]              arsize_m_inf_i2,
    output wire [1:0]              arburst_m_inf_i2,
    output reg                     arvalid_m_inf_i2,
    input  wire                    arready_m_inf_i2,
    input  wire [ID_WIDTH-1:0]     rid_m_inf_i2,
    input  wire [DATA_WIDTH-1:0]   rdata_m_inf_i2,
    input  wire [1:0]              rresp_m_inf_i2,
    input  wire                    rlast_m_inf_i2,
    input  wire                    rvalid_m_inf_i2,
    output reg                     rready_m_inf_i2,

    // ======== AXI-4 D$ write ========
    output wire [ID_WIDTH-1:0]     awid_m_inf_data,
    output reg  [ADDR_WIDTH-1:0]   awaddr_m_inf_data,
    output wire [2:0]              awsize_m_inf_data,
    output wire [1:0]              awburst_m_inf_data,
    output reg  [BURST_LEN-1:0]    awlen_m_inf_data,
    output reg                     awvalid_m_inf_data,
    input  wire                    awready_m_inf_data,
    output reg  [DATA_WIDTH-1:0]   wdata_m_inf_data,
    output reg                     wlast_m_inf_data,
    output reg                     wvalid_m_inf_data,
    input  wire                    wready_m_inf_data,
    input  wire [ID_WIDTH-1:0]     bid_m_inf_data,
    input  wire [1:0]              bresp_m_inf_data,
    input  wire                    bvalid_m_inf_data,
    output reg                     bready_m_inf_data,

    // ======== AXI-4 D$ read ========
    output wire [ID_WIDTH-1:0]     arid_m_inf_data,
    output reg  [ADDR_WIDTH-1:0]   araddr_m_inf_data,
    output wire [BURST_LEN-1:0]    arlen_m_inf_data,
    output wire [2:0]              arsize_m_inf_data,
    output wire [1:0]              arburst_m_inf_data,
    output reg                     arvalid_m_inf_data,
    input  wire                    arready_m_inf_data,
    input  wire [ID_WIDTH-1:0]     rid_m_inf_data,
    input  wire [DATA_WIDTH-1:0]   rdata_m_inf_data,
    input  wire [1:0]              rresp_m_inf_data,
    input  wire                    rlast_m_inf_data,
    input  wire                    rvalid_m_inf_data,
    output reg                     rready_m_inf_data
);
// ===================================================
// Constant AXI fields
// ===================================================

// I$ core0 AR
assign arid_m_inf_i1    = {ID_WIDTH{1'b0}};
assign arlen_m_inf_i1   = 7'd63;
assign arsize_m_inf_i1  = 3'd1;
assign arburst_m_inf_i1 = 2'd1;

// I$ core1 AR
assign arid_m_inf_i2    = {ID_WIDTH{1'b0}};
assign arlen_m_inf_i2   = 7'd63;
assign arsize_m_inf_i2  = 3'd1;
assign arburst_m_inf_i2 = 2'd1;

// D$ AR
assign arid_m_inf_data    = {ID_WIDTH{1'b0}};
assign arlen_m_inf_data   = 7'd127;
assign arsize_m_inf_data  = 3'd1;
assign arburst_m_inf_data = 2'd1;

// D$ AW
assign awid_m_inf_data    = {ID_WIDTH{1'b0}};
assign awsize_m_inf_data  = 3'd1;
assign awburst_m_inf_data = 2'd1;

// ===================================================
// Internal address / tag width
// ===================================================
localparam INT_ADDR_W = 14;
localparam ITAG_W     = INT_ADDR_W - 7;   // 7, I-cache: 64 words = address[6:1] index
localparam DTAG_W     = INT_ADDR_W - 9;   // 5, D-cache: 128 words/block = address[7:1] index

wire [INT_ADDR_W-1:0] addr_int = address[INT_ADDR_W-1:0];
wire [6:0] icache_word_index = {1'b0, addr_int[6:1]};
wire [6:0] dcache_word_index = addr_int[7:1];
wire [6:0] active_word_index = request_type ? dcache_word_index : icache_word_index;

// ===================================================
// FSM States
// ===================================================
localparam IDLE         = 4'd0;
localparam WAIT_AWREADY = 4'd1;
localparam WAIT_SRAM    = 4'd2;
localparam WAIT_WLAST   = 4'd3;
localparam WAIT_BVALID  = 4'd4;
localparam WAIT_ARREADY = 4'd5;
localparam WAIT_RLAST   = 4'd6;
localparam READ_CACHE   = 4'd7;
localparam WRITE_CACHE  = 4'd8;
localparam OUTPUT       = 4'd9;

reg [3:0] cache_state, cache_next_state;

// ===================================================
// Internal regs
// ===================================================
reg [6:0]            cache_counter;
reg [DATA_WIDTH-1:0] out_data_reg;

// Area optimization:
// The FSM only accepts one AXI read source at a time, so three sets of
// rdata/rvalid/rlast registers are merged into one active set.
reg [DATA_WIDTH-1:0] active_rdata_reg;
reg                  active_rvalid_reg;
reg                  active_rlast_reg;

// I$ tag/valid
reg [ITAG_W-1:0] icache_tag_i1;
reg              icache_valid_i1;
reg [ITAG_W-1:0] icache_tag_i2;
reg              icache_valid_i2;

// D$ tag/valid/dirty
reg [DTAG_W-1:0] dcache_tag_0, dcache_tag_1;
reg              dcache_valid_0, dcache_valid_1;
reg              dcache_dirty_0, dcache_dirty_1;

// Per-block dirty range trackers
reg [6:0] write_min_0, write_max_0;
reg [6:0] write_min_1, write_max_1;
reg [6:0] burst_len;

// Flush bookkeeping
reg flush_busy;
reg flush_which;

// Writeback way selector for miss-writeback
reg wb_way;

// Write buffer
reg [DATA_WIDTH-1:0] buffer [0:2];
reg [1:0]            wait_cnt;

// SRAM interface
reg  [8:0]  sram_address;
reg  [15:0] sram_data_in;
wire [15:0] sram_data_out;
reg         sram_WEB;
reg         sram_OE;
reg         sram_CS;
wire [6:0]  write_index;

// Set to 1 if the SRAM macro mode table requires OE=1 during write.
// For lower power, keep it 0 so the output driver is off during write.
localparam SRAM_OE_ON_WRITE = 1'b0;

// ===================================================
// Hit / Miss
// ===================================================
wire icache_hit_c0 = icache_valid_i1 && (icache_tag_i1 == addr_int[13:7]);
wire icache_hit_c1 = icache_valid_i2 && (icache_tag_i2 == addr_int[13:7]);
wire icache_miss   = request && (request_type == 1'b0) &&
                     ((core == 1'b0 && !icache_hit_c0) ||
                      (core == 1'b1 && !icache_hit_c1));

wire dcache_hit_0 = (addr_int[8] == 1'b0) && dcache_valid_0 && (dcache_tag_0 == addr_int[13:9]);
wire dcache_hit_1 = (addr_int[8] == 1'b1) && dcache_valid_1 && (dcache_tag_1 == addr_int[13:9]);
wire dcache_miss  = request && (request_type == 1'b1) && !dcache_hit_0 && !dcache_hit_1;

wire need_wb_on_miss = (addr_int[8] == 1'b0) ? (dcache_valid_0 && dcache_dirty_0)
                                             : (dcache_valid_1 && dcache_dirty_1);

wire any_dirty = (dcache_valid_0 && dcache_dirty_0) || (dcache_valid_1 && dcache_dirty_1);

// ===================================================
// Writeback range selection
// ===================================================
wire              wb_way_bit = flush_busy ? flush_which : wb_way;
wire [DTAG_W-1:0] wb_tag     = wb_way_bit ? dcache_tag_1 : dcache_tag_0;
wire [6:0]        wb_min     = wb_way_bit ? write_min_1  : write_min_0;
wire [6:0]        wb_max     = wb_way_bit ? write_max_1  : write_max_0;

// ===================================================
// Active AXI read source mux
// ===================================================
wire [DATA_WIDTH-1:0] active_rdata =
    (request_type == 1'b0 && core == 1'b0) ? rdata_m_inf_i1 :
    (request_type == 1'b0 && core == 1'b1) ? rdata_m_inf_i2 :
                                             rdata_m_inf_data;

wire active_rvalid =
    (request_type == 1'b0 && core == 1'b0) ? rvalid_m_inf_i1 :
    (request_type == 1'b0 && core == 1'b1) ? rvalid_m_inf_i2 :
                                             rvalid_m_inf_data;

wire active_rlast =
    (request_type == 1'b0 && core == 1'b0) ? rlast_m_inf_i1 :
    (request_type == 1'b0 && core == 1'b1) ? rlast_m_inf_i2 :
                                             rlast_m_inf_data;

// ===================================================
// AXI-4 Read Address Channel base address
// ===================================================
wire [INT_ADDR_W-1:0] icache_refill_base_int = {addr_int[13:7], 7'd0};
wire [INT_ADDR_W-1:0] dcache_refill_base_int = {addr_int[13:8], 8'd0};
wire [ADDR_WIDTH-1:0] icache_refill_base     = {{(ADDR_WIDTH-INT_ADDR_W){1'b0}}, icache_refill_base_int};
wire [ADDR_WIDTH-1:0] dcache_refill_base     = {{(ADDR_WIDTH-INT_ADDR_W){1'b0}}, dcache_refill_base_int};

// ===================================================
// AXI-4 Write Address Channel base address
// ===================================================
wire [INT_ADDR_W-1:0] wb_addr_int = {wb_tag, wb_way_bit, wb_min, 1'b0};
wire [ADDR_WIDTH-1:0] wb_addr_ext = {{(ADDR_WIDTH-INT_ADDR_W){1'b0}}, wb_addr_int};

// ===================================================
// Sequential output helpers
// ===================================================
wire wdata_fire = (cache_state == WAIT_WLAST) && wvalid_m_inf_data && wready_m_inf_data;

wire [6:0] cache_counter_for_wout =
    wdata_fire ? (cache_counter + 7'd1) : cache_counter;

wire [DATA_WIDTH-1:0] buffer0_for_wout =
    wdata_fire ? buffer[1] : buffer[0];

wire [DATA_WIDTH-1:0] buffer2_for_wout =
    wdata_fire ? sram_data_out : buffer[2];

wire [DATA_WIDTH-1:0] wdata_next =
    (cache_counter_for_wout[6:1] != 6'd0) ? buffer2_for_wout : buffer0_for_wout;

wire [DATA_WIDTH-1:0] out_data_next =
    (cache_state == WAIT_RLAST && active_rvalid_reg && cache_counter == active_word_index) ? active_rdata_reg :
    (cache_state == READ_CACHE)                                                           ? sram_data_out :
                                                                                             out_data_reg;

// ===================================================
// I$ core0 read address channel
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_m_inf_i1  <= {ADDR_WIDTH{1'b0}};
        arvalid_m_inf_i1 <= 1'b0;
    end
    else begin
        araddr_m_inf_i1  <= icache_refill_base;
        arvalid_m_inf_i1 <= (cache_next_state == WAIT_ARREADY) &&
                             (request_type == 1'b0) &&
                             (core == 1'b0);
    end
end

// ===================================================
// I$ core1 read address channel
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_m_inf_i2  <= {ADDR_WIDTH{1'b0}};
        arvalid_m_inf_i2 <= 1'b0;
    end
    else begin
        araddr_m_inf_i2  <= icache_refill_base;
        arvalid_m_inf_i2 <= (cache_next_state == WAIT_ARREADY) &&
                             (request_type == 1'b0) &&
                             (core == 1'b1);
    end
end

// ===================================================
// D$ read address channel
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_m_inf_data  <= {ADDR_WIDTH{1'b0}};
        arvalid_m_inf_data <= 1'b0;
    end
    else begin
        araddr_m_inf_data  <= dcache_refill_base;
        arvalid_m_inf_data <= (cache_next_state == WAIT_ARREADY) &&
                               (request_type == 1'b1);
    end
end

// ===================================================
// I$ core0 read data ready
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rready_m_inf_i1 <= 1'b0;
    end
    else begin
        rready_m_inf_i1 <= (cache_next_state == WAIT_RLAST) &&
                            (request_type == 1'b0) &&
                            (core == 1'b0);
    end
end

// ===================================================
// I$ core1 read data ready
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rready_m_inf_i2 <= 1'b0;
    end
    else begin
        rready_m_inf_i2 <= (cache_next_state == WAIT_RLAST) &&
                            (request_type == 1'b0) &&
                            (core == 1'b1);
    end
end

// ===================================================
// D$ read data ready
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rready_m_inf_data <= 1'b0;
    end
    else begin
        rready_m_inf_data <= (cache_next_state == WAIT_RLAST) &&
                              (request_type == 1'b1);
    end
end

// ===================================================
// D$ write address channel
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awaddr_m_inf_data  <= {ADDR_WIDTH{1'b0}};
        awlen_m_inf_data   <= {BURST_LEN{1'b0}};
        awvalid_m_inf_data <= 1'b0;
    end
    else begin
        awaddr_m_inf_data  <= wb_addr_ext;
        awlen_m_inf_data   <= burst_len;
        awvalid_m_inf_data <= (cache_next_state == WAIT_AWREADY);
    end
end

// ===================================================
// D$ write data channel
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wdata_m_inf_data  <= {DATA_WIDTH{1'b0}};
        wlast_m_inf_data  <= 1'b0;
        wvalid_m_inf_data <= 1'b0;
    end
    else begin
        wdata_m_inf_data  <= wdata_next;
        wlast_m_inf_data  <= (cache_next_state == WAIT_WLAST) &&
                              (cache_counter_for_wout == burst_len);
        wvalid_m_inf_data <= (cache_next_state == WAIT_WLAST);
    end
end

// ===================================================
// D$ write response channel
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bready_m_inf_data <= 1'b0;
    end
    else begin
        bready_m_inf_data <= (cache_next_state == WAIT_BVALID);
    end
end

// ===================================================
// CPU-side out_data
// ===================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data <= {DATA_WIDTH{1'b0}};
    end
    else begin
        out_data <= out_data_next;
    end
end

// ===================================================
// CPU-side out_valid
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
    end
    else begin
        out_valid <= (cache_next_state == OUTPUT);
    end
end

// ===================================================
// cache_counter
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cache_counter <= 7'd0;
    end
    else if (cache_state == WAIT_RLAST && active_rvalid_reg) begin
        cache_counter <= cache_counter + 7'd1;
    end
    else if (cache_state == WAIT_WLAST && wvalid_m_inf_data && wready_m_inf_data) begin
        cache_counter <= cache_counter + 7'd1;
    end
    else begin
        cache_counter <= 7'd0;
    end
end

// ===================================================
// burst_len
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        burst_len <= 7'd0;
    end
    else if (cache_state == IDLE && flush && any_dirty) begin
        burst_len <= (dcache_valid_0 && dcache_dirty_0) ? (write_max_0 - write_min_0)
                                                        : (write_max_1 - write_min_1);
    end
    else if (cache_state == IDLE && request && request_type == 1'b1 &&
             dcache_miss && need_wb_on_miss && !flush) begin
        burst_len <= (addr_int[8] == 1'b0) ? (write_max_0 - write_min_0)
                                           : (write_max_1 - write_min_1);
    end
    else if (cache_state == WAIT_BVALID && bvalid_m_inf_data && flush_busy &&
             flush_which == 1'b0 && dcache_valid_1 && dcache_dirty_1) begin
        burst_len <= write_max_1 - write_min_1;
    end
end

// ===================================================
// Registered active AXI read data / valid / last
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_rdata_reg  <= {DATA_WIDTH{1'b0}};
        active_rvalid_reg <= 1'b0;
        active_rlast_reg  <= 1'b0;
    end
    else if (cache_state == WAIT_RLAST) begin
        if (active_rvalid) begin
            active_rdata_reg <= active_rdata;
        end
        active_rvalid_reg <= active_rvalid;
        active_rlast_reg  <= active_rlast;
    end
    else begin
        active_rvalid_reg <= 1'b0;
        active_rlast_reg  <= 1'b0;
    end
end

// ===================================================
// I$ tag / valid
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        icache_tag_i1   <= {ITAG_W{1'b0}};
        icache_valid_i1 <= 1'b0;
    end
    else if (cache_state == WAIT_ARREADY && request_type == 1'b0 && core == 1'b0) begin
        icache_tag_i1   <= addr_int[13:7];
        icache_valid_i1 <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        icache_tag_i2   <= {ITAG_W{1'b0}};
        icache_valid_i2 <= 1'b0;
    end
    else if (cache_state == WAIT_ARREADY && request_type == 1'b0 && core == 1'b1) begin
        icache_tag_i2   <= addr_int[13:7];
        icache_valid_i2 <= 1'b1;
    end
end

// ===================================================
// D$ tag / valid
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dcache_tag_0   <= {DTAG_W{1'b0}};
        dcache_valid_0 <= 1'b0;
    end
    else if (cache_state == WAIT_ARREADY && request_type == 1'b1 && addr_int[8] == 1'b0) begin
        dcache_tag_0   <= addr_int[13:9];
        dcache_valid_0 <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dcache_tag_1   <= {DTAG_W{1'b0}};
        dcache_valid_1 <= 1'b0;
    end
    else if (cache_state == WAIT_ARREADY && request_type == 1'b1 && addr_int[8] == 1'b1) begin
        dcache_tag_1   <= addr_int[13:9];
        dcache_valid_1 <= 1'b1;
    end
end

// ===================================================
// D$ dirty bits
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dcache_dirty_0 <= 1'b0;
    end
    else if (cache_state == WRITE_CACHE && dcache_hit_0) begin
        dcache_dirty_0 <= 1'b1;
    end
    else if (cache_state == WAIT_BVALID && bvalid_m_inf_data && wb_way_bit == 1'b0) begin
        dcache_dirty_0 <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dcache_dirty_1 <= 1'b0;
    end
    else if (cache_state == WRITE_CACHE && dcache_hit_1) begin
        dcache_dirty_1 <= 1'b1;
    end
    else if (cache_state == WAIT_BVALID && bvalid_m_inf_data && wb_way_bit == 1'b1) begin
        dcache_dirty_1 <= 1'b0;
    end
end

// ===================================================
// Per-block min/max dirty index
// ===================================================

wire write_range_0_update;
wire write_range_0_clear;
wire write_range_0_clk_en;
wire write_range_0_gclk;

wire write_range_1_update;
wire write_range_1_clear;
wire write_range_1_clk_en;
wire write_range_1_gclk;

assign write_range_0_update = (cache_state == WRITE_CACHE) && dcache_hit_0;
assign write_range_0_clear  = (cache_state == WAIT_BVALID) && bvalid_m_inf_data && (wb_way_bit == 1'b0);
assign write_range_0_clk_en = write_range_0_update || write_range_0_clear;
assign write_range_0_gclk   = clk & write_range_0_clk_en;

assign write_range_1_update = (cache_state == WRITE_CACHE) && dcache_hit_1;
assign write_range_1_clear  = (cache_state == WAIT_BVALID) && bvalid_m_inf_data && (wb_way_bit == 1'b1);
assign write_range_1_clk_en = write_range_1_update || write_range_1_clear;
assign write_range_1_gclk   = clk & write_range_1_clk_en;


always @(posedge write_range_0_gclk or negedge rst_n) begin
    if (!rst_n) begin
        write_min_0 <= 7'd127;
        write_max_0 <= 7'd0;
    end
    else if (write_range_0_update) begin
        if (addr_int[7:1] < write_min_0)
            write_min_0 <= addr_int[7:1];

        if (addr_int[7:1] > write_max_0)
            write_max_0 <= addr_int[7:1];
    end
    else if (write_range_0_clear) begin
        write_min_0 <= 7'd127;
        write_max_0 <= 7'd0;
    end
end


always @(posedge write_range_1_gclk or negedge rst_n) begin
    if (!rst_n) begin
        write_min_1 <= 7'd127;
        write_max_1 <= 7'd0;
    end
    else if (write_range_1_update) begin
        if (addr_int[7:1] < write_min_1)
            write_min_1 <= addr_int[7:1];

        if (addr_int[7:1] > write_max_1)
            write_max_1 <= addr_int[7:1];
    end
    else if (write_range_1_clear) begin
        write_min_1 <= 7'd127;
        write_max_1 <= 7'd0;
    end
end

// ===================================================
// wb_way for miss-writeback
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wb_way <= 1'b0;
    end
    else if (cache_state == IDLE && request && request_type == 1'b1 &&
             dcache_miss && need_wb_on_miss && !flush) begin
        wb_way <= addr_int[8];
    end
end

// ===================================================
// Flush bookkeeping
//   Area optimization: flush_done_0/1 are removed.
//   The second block only needs to be flushed when block0 was just flushed
//   and block1 is still dirty.
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        flush_busy  <= 1'b0;
        flush_which <= 1'b0;
    end
    else if (cache_state == IDLE && flush && any_dirty) begin
        flush_busy  <= 1'b1;
        flush_which <= (dcache_valid_0 && dcache_dirty_0) ? 1'b0 : 1'b1;
    end
    else if (cache_state == WAIT_BVALID && bvalid_m_inf_data && flush_busy) begin
        if (flush_which == 1'b0 && dcache_valid_1 && dcache_dirty_1) begin
            flush_which <= 1'b1;
        end
        else begin
            flush_busy <= 1'b0;
        end
    end
end

// ===================================================
// wait_cnt
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wait_cnt <= 2'd0;
    end
    else if (cache_state == WAIT_SRAM) begin
        wait_cnt <= wait_cnt + 2'd1;
    end
    else begin
        wait_cnt <= 2'd0;
    end
end

// ===================================================
// Write buffer pipeline
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buffer[0] <= 16'd0;
        buffer[1] <= 16'd0;
        buffer[2] <= 16'd0;
    end
    else if (cache_state == WAIT_AWREADY) begin
        buffer[0] <= sram_data_out;
    end
    else if (cache_state == WAIT_SRAM) begin
        buffer[2] <= sram_data_out;
        buffer[1] <= buffer[2];
    end
    else if (cache_state == WAIT_WLAST && wready_m_inf_data) begin
        buffer[2] <= sram_data_out;
        buffer[0] <= buffer[1];
    end
end


// ===================================================
// write_index
// ===================================================
assign write_index = (cache_state == WAIT_AWREADY) ? (wb_min + cache_counter) :
                     (cache_state == WAIT_SRAM)    ? (wb_min + cache_counter + 7'd1 + {5'd0, wait_cnt}) :
                                                     (wb_min + cache_counter + 7'd2);

// ===================================================
// FSM
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) cache_state <= IDLE;
    else        cache_state <= cache_next_state;
end

always @(*) begin
    cache_next_state = cache_state;
    case (cache_state)
        IDLE: begin
            if (flush && any_dirty) begin
                cache_next_state = WAIT_AWREADY;
            end
            else if (flush && !any_dirty) begin
                cache_next_state = OUTPUT;
            end
            else if (request && request_type == 1'b0 && !icache_miss) begin
                cache_next_state = READ_CACHE;
            end
            else if (request && request_type == 1'b0 && icache_miss) begin
                cache_next_state = WAIT_ARREADY;
            end
            else if (request && request_type == 1'b1 && !dcache_miss && !is_write) begin
                cache_next_state = READ_CACHE;
            end
            else if (request && request_type == 1'b1 && !dcache_miss && is_write) begin
                cache_next_state = WRITE_CACHE;
            end
            else if (request && request_type == 1'b1 && dcache_miss && need_wb_on_miss) begin
                cache_next_state = WAIT_AWREADY;
            end
            else if (request && request_type == 1'b1 && dcache_miss && !need_wb_on_miss) begin
                cache_next_state = WAIT_ARREADY;
            end
            else begin
                cache_next_state = IDLE;
            end
        end

        WAIT_AWREADY: begin
            if (awvalid_m_inf_data && awready_m_inf_data) cache_next_state = WAIT_SRAM;
            else                    cache_next_state = WAIT_AWREADY;
        end

        WAIT_SRAM: begin
            if (wait_cnt == 2'd2) cache_next_state = WAIT_WLAST;
            else                  cache_next_state = WAIT_SRAM;
        end

        WAIT_WLAST: begin
            if (wvalid_m_inf_data && wlast_m_inf_data && wready_m_inf_data) cache_next_state = WAIT_BVALID;
            else                                       cache_next_state = WAIT_WLAST;
        end

        WAIT_BVALID: begin
            if (bvalid_m_inf_data) begin
                if (flush_busy) begin
                    if (flush_which == 1'b0 && dcache_valid_1 && dcache_dirty_1)
                        cache_next_state = WAIT_AWREADY;
                    else
                        cache_next_state = OUTPUT;
                end
                else begin
                    cache_next_state = WAIT_ARREADY;
                end
            end
            else begin
                cache_next_state = WAIT_BVALID;
            end
        end

        WAIT_ARREADY: begin
            if (arvalid_m_inf_i1 && arready_m_inf_i1)                         cache_next_state = WAIT_RLAST;
            else if (arvalid_m_inf_i2 && arready_m_inf_i2)                    cache_next_state = WAIT_RLAST;
            else if (arvalid_m_inf_data && arready_m_inf_data)                cache_next_state = WAIT_RLAST;
            else                                                               cache_next_state = WAIT_ARREADY;
        end

        WAIT_RLAST: begin
            if (active_rlast_reg) begin
                if (request_type == 1'b1)
                    cache_next_state = is_write ? WRITE_CACHE : OUTPUT;
                else
                    cache_next_state = OUTPUT;
            end
            else begin
                cache_next_state = WAIT_RLAST;
            end
        end

        READ_CACHE:  cache_next_state = OUTPUT;
        WRITE_CACHE: cache_next_state = OUTPUT;
        OUTPUT:      cache_next_state = IDLE;
        default:     cache_next_state = IDLE;
    endcase
end

// ===================================================
// out_data_reg
// ===================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_data_reg <= 16'd0;
    end
    else begin
        out_data_reg <= out_data_next;
    end
end

// ===================================================
// SRAM address mux
//   Layout for SUMA180_384X16X1BM1:
//     0..63    : icache core 0
//     64..127  : icache core 1
//     128..255 : dcache block 0
//     256..383 : dcache block 1
// ===================================================
always @(*) begin
    sram_address = 9'd0;

    if (cache_state == WAIT_AWREADY ||
        cache_state == WAIT_SRAM    ||
        cache_state == WAIT_WLAST) begin
        sram_address = wb_way_bit ? {2'b10, write_index} : {2'b01, write_index};
    end
    else if (cache_state == WAIT_RLAST && request_type == 1'b0 && core == 1'b0) begin
        sram_address = {3'b000, cache_counter[5:0]};
    end
    else if (cache_state == WAIT_RLAST && request_type == 1'b0 && core == 1'b1) begin
        sram_address = {3'b001, cache_counter[5:0]};
    end
    else if (cache_state == WAIT_RLAST && request_type == 1'b1) begin
        sram_address = addr_int[8] ? {2'b10, cache_counter} : {2'b01, cache_counter};
    end
    else if (cache_state == IDLE && request && request_type == 1'b0 && core == 1'b0) begin
        sram_address = {3'b000, addr_int[6:1]};
    end
    else if (cache_state == IDLE && request && request_type == 1'b0 && core == 1'b1) begin
        sram_address = {3'b001, addr_int[6:1]};
    end
    else if (cache_state == IDLE && request && request_type == 1'b1) begin
        sram_address = addr_int[8] ? {2'b10, addr_int[7:1]} : {2'b01, addr_int[7:1]};
    end
    else if (cache_state == READ_CACHE && request_type == 1'b0 && core == 1'b0) begin
        // Keep the same hit-read address while SRAM output is used.
        sram_address = {3'b000, addr_int[6:1]};
    end
    else if (cache_state == READ_CACHE && request_type == 1'b0 && core == 1'b1) begin
        // Keep the same hit-read address while SRAM output is used.
        sram_address = {3'b001, addr_int[6:1]};
    end
    else if (cache_state == READ_CACHE && request_type == 1'b1) begin
        // Keep the same hit-read address while SRAM output is used.
        sram_address = addr_int[8] ? {2'b10, addr_int[7:1]} : {2'b01, addr_int[7:1]};
    end
    else if (cache_state == WRITE_CACHE) begin
        sram_address = addr_int[8] ? {2'b10, addr_int[7:1]} : {2'b01, addr_int[7:1]};
    end
end

// ===================================================
// SRAM data_in
// ===================================================
always @(*) begin
    if (cache_state == WAIT_RLAST)       sram_data_in = active_rdata_reg;
    else if (cache_state == WRITE_CACHE) sram_data_in = write_data;
    else                                 sram_data_in = 16'd0;
end

// ===================================================
// SRAM WEB / OE / CS control, low-power safe version
//
// Read  : CS=1, WEB=1, OE=1
// Write : CS=1, WEB=0, OE=0 by default
// Idle  : CS=0, WEB=1, OE=0
//
// Notes:
//   1. Keep WAIT_AWREADY / WAIT_SRAM / WAIT_WLAST as read access.
//      This is conservative and avoids breaking the original writeback timing.
//   2. The main low-power change is that OE is not enabled during write,
//      so the SRAM output driver does not toggle when writing.
//   3. READ_CACHE address is held to the requested address instead of
//      falling back to 0 while CS/OE are active.
// ===================================================
wire sram_read_access =
    // dirty block writeback reads
    (cache_state == WAIT_AWREADY) ||
    (cache_state == WAIT_SRAM)    ||
    (cache_state == WAIT_WLAST && wvalid_m_inf_data && wready_m_inf_data)   ||

    // cache hit read: enable one cycle earlier in IDLE so SRAM can see address
    (cache_state == IDLE && request &&
        ((request_type == 1'b0 && !icache_miss) ||
         (request_type == 1'b1 && !dcache_miss && !is_write))) ||

    // output cycle for cache hit read
    (cache_state == READ_CACHE);

wire sram_write_access =
    // AXI refill writes into SRAM
    (cache_state == WAIT_RLAST && active_rvalid_reg) ||

    // CPU D-cache write hit / write-after-refill
    (cache_state == WRITE_CACHE);

always @(*) begin
    sram_CS  = sram_read_access | sram_write_access;
    sram_WEB = sram_write_access ? 1'b0 : 1'b1;

    // Lower power: keep OE off during write unless the memory model requires it.
    sram_OE  = 1;
end

SRAM_384 u_SRAM (
    .clk      (clk),
    .address  (sram_address),
    .data_in  (sram_data_in),
    .WEB      (sram_WEB),
    .OE       (sram_OE),
    .CS       (sram_CS),
    .data_out (sram_data_out)
);

endmodule


module SRAM_384(
    input         clk,
    input  [8:0] address,
    input  [15:0] data_in,
    input         WEB,
    input         OE,
    input         CS,
    output [15:0] data_out
);

SUMA180_384X16X1BM1 u_SRAM_384x16 (
    .A0(address[0]),       .A1(address[1]),
    .A2(address[2]),       .A3(address[3]),
    .A4(address[4]),       .A5(address[5]),
    .A6(address[6]),       .A7(address[7]),
    .A8(address[8]),

    .DO0(data_out[0]),     .DO1(data_out[1]),
    .DO2(data_out[2]),     .DO3(data_out[3]),
    .DO4(data_out[4]),     .DO5(data_out[5]),
    .DO6(data_out[6]),     .DO7(data_out[7]),
    .DO8(data_out[8]),     .DO9(data_out[9]),
    .DO10(data_out[10]),   .DO11(data_out[11]),
    .DO12(data_out[12]),   .DO13(data_out[13]),
    .DO14(data_out[14]),   .DO15(data_out[15]),

    .DI0(data_in[0]),      .DI1(data_in[1]),
    .DI2(data_in[2]),      .DI3(data_in[3]),
    .DI4(data_in[4]),      .DI5(data_in[5]),
    .DI6(data_in[6]),      .DI7(data_in[7]),
    .DI8(data_in[8]),      .DI9(data_in[9]),
    .DI10(data_in[10]),    .DI11(data_in[11]),
    .DI12(data_in[12]),    .DI13(data_in[13]),
    .DI14(data_in[14]),    .DI15(data_in[15]),

    .CK(clk),
    .WEB(WEB),
    .OE(OE),
    .CS(CS)
);

endmodule