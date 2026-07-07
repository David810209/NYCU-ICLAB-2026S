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

    awid_m_inf_inst_1,
    awaddr_m_inf_inst_1,
    awsize_m_inf_inst_1,
    awburst_m_inf_inst_1,
    awlen_m_inf_inst_1,
    awvalid_m_inf_inst_1,
    awready_m_inf_inst_1,
                
    wdata_m_inf_inst_1,
    wlast_m_inf_inst_1,
    wvalid_m_inf_inst_1,
    wready_m_inf_inst_1,

    bid_m_inf_inst_1,
    bresp_m_inf_inst_1,
    bvalid_m_inf_inst_1,
    bready_m_inf_inst_1,
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

    awid_m_inf_inst_2,
    awaddr_m_inf_inst_2,
    awsize_m_inf_inst_2,
    awburst_m_inf_inst_2,
    awlen_m_inf_inst_2,
    awvalid_m_inf_inst_2,
    awready_m_inf_inst_2,
                
    wdata_m_inf_inst_2,
    wlast_m_inf_inst_2,
    wvalid_m_inf_inst_2,
    wready_m_inf_inst_2,

    bid_m_inf_inst_2,
    bresp_m_inf_inst_2,
    bvalid_m_inf_inst_2,
    bready_m_inf_inst_2,  
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
// axi write addr channel 
// src master
output wire [ID_WIDTH-1:0]   awid_m_inf_inst_1; 
output wire [ADDR_WIDTH-1:0] awaddr_m_inf_inst_1;
output wire [2:0]            awsize_m_inf_inst_1; 
output wire [1:0]            awburst_m_inf_inst_1; 
output wire [BURST_LEN-1:0]  awlen_m_inf_inst_1;
output wire                  awvalid_m_inf_inst_1;
// src slave
input wire                   awready_m_inf_inst_1;
// -------------------------

// axi write data channel 
// src master
output wire [DATA_WIDTH-1:0] wdata_m_inf_inst_1;
output wire                  wlast_m_inf_inst_1;
output wire                  wvalid_m_inf_inst_1;
// src slave
input wire                   wready_m_inf_inst_1;

// axi write resp channel 
// src slave
input wire  [ID_WIDTH-1:0] bid_m_inf_inst_1; 
input wire  [1:0]          bresp_m_inf_inst_1; 
input wire                 bvalid_m_inf_inst_1;
// src master 
output wire                bready_m_inf_inst_1;
// ------------------------

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
// axi write addr channel 
// src master
output wire [ID_WIDTH-1:0]   awid_m_inf_inst_2; 
output wire [ADDR_WIDTH-1:0] awaddr_m_inf_inst_2;
output wire [2:0]            awsize_m_inf_inst_2; 
output wire [1:0]            awburst_m_inf_inst_2; 
output wire [BURST_LEN-1:0]  awlen_m_inf_inst_2;
output wire                  awvalid_m_inf_inst_2;
// src slave
input wire                   awready_m_inf_inst_2;
// -------------------------

// axi write data channel 
// src master
output wire [DATA_WIDTH-1:0] wdata_m_inf_inst_2;
output wire                  wlast_m_inf_inst_2;
output wire                  wvalid_m_inf_inst_2;
// src slave
input wire                   wready_m_inf_inst_2;

// axi write resp channel 
// src slave
input wire  [ID_WIDTH-1:0] bid_m_inf_inst_2; 
input wire  [1:0]          bresp_m_inf_inst_2; 
input wire                 bvalid_m_inf_inst_2;
// src master 
output wire                bready_m_inf_inst_2;
// ------------------------

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
    // core
    wire [2:0] dec_rs_addr;
    wire [2:0] dec_rt_addr;
    reg [15:0] dec_rs_data;
    reg [15:0] dec_rt_data;
    wire is_wb;
    wire [2:0] dec_wb_addr_r;
    wire [2:0] rl_addr;
    wire rf_write;
    wire rf_rl_write;
    wire [15:0] rf_wdata;
    wire [15:0] rf_rl_wdata;
    wire current_core;
    // =====================================================
    // AXI instruction read wires: Core1 -> DCCPU ports
    // =====================================================
    wire                  arvalid_inst_1;
    wire [ADDR_WIDTH-1:0] araddr_inst_1;
    wire                  rready_inst_1;
    
    // AXI instruction read wires: Core2 -> DCCPU ports
    wire                  arvalid_inst_2;
    wire [ADDR_WIDTH-1:0] araddr_inst_2;
    wire                  rready_inst_2;

//###########################################
//
// Wrtie down your design below
//
//##################################################

    // =====================================================
    // AXI write channels: tie-off to 0 (not implemented yet)
    // =====================================================
    // Inst1 write
    assign awid_m_inf_inst_1    = 0;
    assign awaddr_m_inf_inst_1  = 0;
    assign awsize_m_inf_inst_1  = 3'b001;
    assign awburst_m_inf_inst_1 = 2'b01;
    assign awlen_m_inf_inst_1   = 0;
    assign awvalid_m_inf_inst_1 = 0;
    assign wdata_m_inf_inst_1   = 0;
    assign wlast_m_inf_inst_1   = 0;
    assign wvalid_m_inf_inst_1  = 0;
    assign bready_m_inf_inst_1  = 0;
    
    // Inst2 write
    assign awid_m_inf_inst_2    = 0;
    assign awaddr_m_inf_inst_2  = 0;
    assign awsize_m_inf_inst_2  = 0;
    assign awburst_m_inf_inst_2 = 0;
    assign awlen_m_inf_inst_2   = 0;
    assign awvalid_m_inf_inst_2 = 0;
    assign wdata_m_inf_inst_2   = 0;
    assign wlast_m_inf_inst_2   = 0;
    assign wvalid_m_inf_inst_2  = 0;
    assign bready_m_inf_inst_2  = 0;
    
    // Data write
    assign awid_m_inf_data    = 0;
    assign awaddr_m_inf_data  = dec_rs_data[15:0];
    assign awsize_m_inf_data  = 0;
    assign awburst_m_inf_data = 0;
    assign awlen_m_inf_data   = 0;
    assign awvalid_m_inf_data = 0;
    assign wdata_m_inf_data   = dec_rs_data[15:0];
    assign wlast_m_inf_data   = 0;
    assign wvalid_m_inf_data  = 0;
    assign bready_m_inf_data  = 0;
    
    // Data read (not implemented yet)
    assign arid_m_inf_data    = 0;
    assign araddr_m_inf_data  = 0;
    assign arlen_m_inf_data   = 0;
    assign arsize_m_inf_data  = 0;
    assign arburst_m_inf_data = 0;
    assign arvalid_m_inf_data = 0;
    assign rready_m_inf_data  = 0;
    
    // =====================================================
    // AXI read channels: constant fields (as spec)
    // =====================================================
    assign arid_m_inf_inst_1    = 0;
    assign arlen_m_inf_inst_1   = 7'b1111111;
    assign arsize_m_inf_inst_1  = 3'b001;
    assign arburst_m_inf_inst_1 = 2'b01;
    
    assign arid_m_inf_inst_2    = 0;
    assign arlen_m_inf_inst_2   = 7'b1111111;
    assign arsize_m_inf_inst_2  = 3'b001;
    assign arburst_m_inf_inst_2 = 2'b01;
    
    // =====================================================
    // AXI read channels: dynamic signals from each Core's Fetch
    // =====================================================
    assign arvalid_m_inf_inst_1 = arvalid_inst_1;
    assign araddr_m_inf_inst_1  = araddr_inst_1;
    assign rready_m_inf_inst_1  = rready_inst_1;
    
    assign arvalid_m_inf_inst_2 = arvalid_inst_2;
    assign araddr_m_inf_inst_2  = araddr_inst_2;
    assign rready_m_inf_inst_2  = rready_inst_2;
    
    // core
    Core core_1(
        .clk(clk),
        .rst_n(rst_n),
        .is_wb(is_wb),
        .current_core(current_core),
        .rs_addr(dec_rs_addr),
        .rt_addr(dec_rt_addr),
        .rs_data(dec_rs_data),
        .rt_data(dec_rt_data),
        .dec_wb_addr_r(dec_wb_addr_r),
        .rl_addr(rl_addr),
        .rf_write(rf_write),
        .rf_rl_write(rf_rl_write),
        .rf_wdata(rf_wdata),
        .rf_rl_wdata(rf_rl_wdata),
        // AXI inst read
        .arvalid_m_inf_inst(arvalid_inst_1),
        .araddr_m_inf_inst(araddr_inst_1),
        .arready_m_inf_inst(arready_m_inf_inst_1),
        .rvalid_m_inf_inst(rvalid_m_inf_inst_1),
        .rlast_m_inf_inst(rlast_m_inf_inst_1),
        .rdata_m_inf_inst(rdata_m_inf_inst_1),
        .rready_m_inf_inst(rready_inst_1),
        // AXI inst read (core 2)
        .arvalid_m_inf_inst2(arvalid_inst_2),
        .araddr_m_inf_inst2(araddr_inst_2),
        .arready_m_inf_inst2(arready_m_inf_inst_2),
        .rvalid_m_inf_inst2(rvalid_m_inf_inst_2),
        .rlast_m_inf_inst2(rlast_m_inf_inst_2),
        .rdata_m_inf_inst2(rdata_m_inf_inst_2),
        .rready_m_inf_inst2(rready_inst_2)
    );
    
    // reg file - core 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            core_1_r0 <= 16'd0;
            core_1_r1 <= 16'd0;
            core_1_r2 <= 16'd0;
            core_1_r3 <= 16'd0;
            core_1_r4 <= 16'd0;
            core_1_r5 <= 16'd0;
            core_1_r6 <= 16'd0;
            core_1_r7 <= 16'd0;
            core_2_r0 <= 0; core_2_r1 <= 0; core_2_r2 <= 0; core_2_r3 <= 0;
            core_2_r4 <= 0; core_2_r5 <= 0; core_2_r6 <= 0; core_2_r7 <= 0;
        end else begin
            if(current_core == 0) begin
                 if (rf_write) begin
                    case (dec_wb_addr_r)
                        3'd0: core_1_r0 <= rf_wdata;
                        3'd1: core_1_r1 <= rf_wdata;
                        3'd2: core_1_r2 <= rf_wdata;
                        3'd3: core_1_r3 <= rf_wdata;
                        3'd4: core_1_r4 <= rf_wdata;
                        3'd5: core_1_r5 <= rf_wdata;
                        3'd6: core_1_r6 <= rf_wdata;
                        3'd7: core_1_r7 <= rf_wdata;
                    endcase
                end
    
                if (rf_rl_write) begin
                    case (rl_addr)
                        3'd0: core_1_r0 <= rf_rl_wdata;
                        3'd1: core_1_r1 <= rf_rl_wdata;
                        3'd2: core_1_r2 <= rf_rl_wdata;
                        3'd3: core_1_r3 <= rf_rl_wdata;
                        3'd4: core_1_r4 <= rf_rl_wdata;
                        3'd5: core_1_r5 <= rf_rl_wdata;
                        3'd6: core_1_r6 <= rf_rl_wdata;
                        3'd7: core_1_r7 <= rf_rl_wdata;
                    endcase
                end
            end
            else begin
                if (rf_write) begin
                    case (dec_wb_addr_r)
                        3'd0: core_2_r0 <= rf_wdata;
                        3'd1: core_2_r1 <= rf_wdata;
                        3'd2: core_2_r2 <= rf_wdata;
                        3'd3: core_2_r3 <= rf_wdata;
                        3'd4: core_2_r4 <= rf_wdata;
                        3'd5: core_2_r5 <= rf_wdata;
                        3'd6: core_2_r6 <= rf_wdata;
                        3'd7: core_2_r7 <= rf_wdata;
                    endcase
                end
        
                if (rf_rl_write) begin
                    case (rl_addr)
                        3'd0: core_2_r0 <= rf_rl_wdata;
                        3'd1: core_2_r1 <= rf_rl_wdata;
                        3'd2: core_2_r2 <= rf_rl_wdata;
                        3'd3: core_2_r3 <= rf_rl_wdata;
                        3'd4: core_2_r4 <= rf_rl_wdata;
                        3'd5: core_2_r5 <= rf_rl_wdata;
                        3'd6: core_2_r6 <= rf_rl_wdata;
                        3'd7: core_2_r7 <= rf_rl_wdata;
                    endcase
                end
            end
        end
    end
    
    // reg file read - core 1 (rs and rt)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_rs_data <= 0;
            dec_rt_data <= 0;
        end
        else begin
            if(current_core == 0) begin
                case (dec_rs_addr)
                    3'b000: dec_rs_data <= core_1_r0;
                    3'b001: dec_rs_data <= core_1_r1;
                    3'b010: dec_rs_data <= core_1_r2;
                    3'b011: dec_rs_data <= core_1_r3;
                    3'b100: dec_rs_data <= core_1_r4;
                    3'b101: dec_rs_data <= core_1_r5;
                    3'b110: dec_rs_data <= core_1_r6;
                    3'b111: dec_rs_data <= core_1_r7;
                endcase
                // FIX: add rt read (was missing in original)
                case (dec_rt_addr)
                    3'b000: dec_rt_data <= core_1_r0;
                    3'b001: dec_rt_data <= core_1_r1;
                    3'b010: dec_rt_data <= core_1_r2;
                    3'b011: dec_rt_data <= core_1_r3;
                    3'b100: dec_rt_data <= core_1_r4;
                    3'b101: dec_rt_data <= core_1_r5;
                    3'b110: dec_rt_data <= core_1_r6;
                    3'b111: dec_rt_data <= core_1_r7;
                endcase
            end
            else begin
                case (dec_rs_addr)
                    3'b000: dec_rs_data <= core_2_r0;
                    3'b001: dec_rs_data <= core_2_r1;
                    3'b010: dec_rs_data <= core_2_r2;
                    3'b011: dec_rs_data <= core_2_r3;
                    3'b100: dec_rs_data <= core_2_r4;
                    3'b101: dec_rs_data <= core_2_r5;
                    3'b110: dec_rs_data <= core_2_r6;
                    3'b111: dec_rs_data <= core_2_r7;
                endcase
                case (dec_rt_addr)
                    3'b000: dec_rt_data <= core_2_r0;
                    3'b001: dec_rt_data <= core_2_r1;
                    3'b010: dec_rt_data <= core_2_r2;
                    3'b011: dec_rt_data <= core_2_r3;
                    3'b100: dec_rt_data <= core_2_r4;
                    3'b101: dec_rt_data <= core_2_r5;
                    3'b110: dec_rt_data <= core_2_r6;
                    3'b111: dec_rt_data <= core_2_r7;
                endcase
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            stall_1 <= 0;
            stall_2 <= 0;
        end
        else begin
            stall_1 <= is_wb ? 0 : 1;
            stall_2 <= is_wb ? 0 : 1;
        end
    end
    endmodule
    
    // =====================================================================
    // Core module
    // =====================================================================
    module Core(
        input clk,
        input rst_n,
        output is_wb,
        output [2:0] rs_addr,
        output [2:0] rt_addr,
        output reg current_core,
        input  [15:0] rs_data,
        input  [15:0] rt_data,
    
        output reg [2:0] dec_wb_addr_r,
        output [2:0] rl_addr,
        output       rf_write,
        output       rf_rl_write,
        output [15:0] rf_wdata,
        output [15:0] rf_rl_wdata,
    
        // AXI read addr channel (inst)
        output                  arvalid_m_inf_inst,
        output [31:0]           araddr_m_inf_inst,
        input                   arready_m_inf_inst,
        // AXI read data channel (inst)
        input                   rlast_m_inf_inst,
        input                   rvalid_m_inf_inst,
        input  [15:0]           rdata_m_inf_inst,
        output                  rready_m_inf_inst
        ,
        // AXI read addr channel (inst) core 2
        output                  arvalid_m_inf_inst2,
        output [31:0]           araddr_m_inf_inst2,
        input                   arready_m_inf_inst2,
        // AXI read data channel (inst)
        input                   rlast_m_inf_inst2,
        input                   rvalid_m_inf_inst2,
        input  [15:0]           rdata_m_inf_inst2,
        output                  rready_m_inf_inst2
    );
    // FSM
    reg [2:0] state, next_state;
    localparam IF  = 3'd0;
    localparam ID  = 3'd1;
    localparam EXE = 3'd2;
    localparam EXE2= 3'd3;
    localparam WB  = 3'd4;
    
    // PC
    reg [12:0] pc;
    reg [12:0] pc_2;
    
    // icache signal
    wire instr_valid;
    wire [15:0] if_instr;
    wire instr_valid_2;
    wire [15:0] if_instr_2;
    reg instr_valid_r;
    reg instr_valid_2_r;
    reg [15:0] if_instr_r;
    reg [15:0] if_instr_2_r;
    wire [15:0] if_instr_sel;
    // decode
    wire [2:0] opcode;
    wire [2:0] opcode2;
    wire [2:0] alu_op;
    wire [6:0] imm;
    wire [12:0] jump_target;
    reg [2:0] dec_wb_rl_addr_r;
    wire [2:0] rd_addr;
    wire is_R, is_mult, is_I, is_Load, is_Store, is_Branch, is_Jump, is_ADDI, is_SUBI;
    wire core2_is_Load, core2_is_Store;
    // exe
    wire signed [15:0] alu_a, alu_b;
    reg signed [15:0] alu_result, alu_result_r;
    wire [31:0] mult_result;
    reg [31:0] mult_result_r;
    wire mult_done;
    // pc   
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) pc <= 0;
        else if(is_wb) pc <= pc + 2;
        else pc <= pc;
    end
    // pc2   
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) pc_2 <= 0;
        else if(is_wb) pc_2 <= pc_2 + 2;
        else pc_2 <= pc_2;
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            instr_valid_r <= 0;
            if_instr_r <= 0;
        end
        else if(instr_valid) begin
            instr_valid_r <= 1;
            if_instr_r <= if_instr;
        end
        else if(state == ID) begin
            instr_valid_r <= 0;
            if_instr_r <= if_instr_r;
        end
        else begin
            instr_valid_r <= instr_valid_r;
            if_instr_r <= if_instr_r;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            instr_valid_2_r <= 0;
            if_instr_2_r <= 0;
        end
        else if(instr_valid_2) begin
            instr_valid_2_r <= 1;
            if_instr_2_r <= if_instr_2;
        end
        else if(state == ID) begin
            instr_valid_2_r <= 0;
            if_instr_2_r <= if_instr_2_r;
        end
        else begin
            instr_valid_2_r <= instr_valid_2_r;
            if_instr_2_r <= if_instr_2_r;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) current_core <= 0;
        else if(state == WB) current_core <= ~current_core;
        else current_core <= current_core;
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IF;
        else  state <= next_state;
    end
    
    always @(*) begin
        case(state)
            IF: begin
                if((instr_valid || instr_valid_r) && (instr_valid_2 || instr_valid_2_r)) next_state = ID;
                else next_state = IF;
            end
            ID: begin
                next_state = EXE;
            end
            EXE: begin
                if(is_mult) next_state = EXE2;
                else  next_state = WB;
            end
            EXE2: begin
                next_state =mult_done ?  WB : EXE2;
            end
            WB: next_state = current_core == 0 ? ID : IF;
            default: next_state = IF;
        endcase
    end
    
    assign is_wb = (state == WB && current_core == 1) ? 1 : 0;
    
    // Unused outputs (LW/SW not implemented yet)
    assign rf_write     = state == WB ? 1 : 0;
    assign rf_rl_write  = state == WB && is_mult ? 1 : 0;
    assign rf_wdata     = is_mult ? mult_result_r[31:16] : alu_result_r;
    assign rf_rl_wdata  = mult_result_r[15:0];
    
    Fetch fetch(
        .clk(clk),
        .rst_n(rst_n),
        .in_valid_i(state == IF ? 1'b1 : 1'b0),
        .pc_i(pc), 
        .instr_o(if_instr), 
        .instr_valid_o(instr_valid),
        // AXI read addr 
        .arready_m_inf_inst(arready_m_inf_inst),
        .arvalid_m_inf_inst(arvalid_m_inf_inst),
        .araddr_m_inf_inst(araddr_m_inf_inst),
        // AXI read data channel
        .rlast_m_inf_inst(rlast_m_inf_inst),
        .rvalid_m_inf_inst(rvalid_m_inf_inst),
        .rdata_m_inf_inst(rdata_m_inf_inst),
        .rready_m_inf_inst(rready_m_inf_inst)
    );
    Fetch fetch_2(
        .clk(clk),
        .rst_n(rst_n),
        .in_valid_i(state == IF ? 1'b1 : 1'b0),
        .pc_i(pc_2), 
        .instr_o(if_instr_2), 
        .instr_valid_o(instr_valid_2),
        // AXI read addr 
        .arready_m_inf_inst(arready_m_inf_inst2),
        .arvalid_m_inf_inst(arvalid_m_inf_inst2),
        .araddr_m_inf_inst(araddr_m_inf_inst2),
        // AXI read data channel
        .rlast_m_inf_inst(rlast_m_inf_inst2),
        .rvalid_m_inf_inst(rvalid_m_inf_inst2),
        .rdata_m_inf_inst(rdata_m_inf_inst2),
        .rready_m_inf_inst(rready_m_inf_inst2)
    );   

    // decode
    assign if_instr_sel = current_core ? if_instr_2_r : if_instr_r;
    assign opcode      = if_instr_sel[15:13];
    assign opcode2     = if_instr_2_r[15:13];
    assign rs_addr     = if_instr_sel[12:10];
    assign rt_addr     = if_instr_sel[9:7];
    assign rd_addr     = if_instr_sel[6:4];
    assign rl_addr     = if_instr_sel[3:1];
    assign alu_op      = if_instr_sel[3:1];
    assign imm         = if_instr_sel[6:0];
    assign jump_target = if_instr_sel[12:0];
    assign is_R        = opcode == 3'b000;
    assign is_mult     = opcode == 3'b001;
    assign is_ADDI     = opcode == 3'b010;
    assign is_SUBI     = opcode == 3'b011;
    assign is_I        = is_ADDI | is_SUBI;
    assign is_Load     = opcode == 3'b100;      
    assign is_Store    = opcode == 3'b101;
    assign is_Branch   = opcode == 3'b110;
    assign is_Jump     = opcode == 3'b111;

    assign core2_is_Load = opcode2 == 3'b100;
    assign core2_is_Store = opcode2 == 3'b101;
    always @(*) begin
        dec_wb_addr_r    = is_R | is_mult ? rd_addr : rt_addr;
        dec_wb_rl_addr_r = rl_addr;
    end
    
    // exe
    assign alu_a = rs_data;
    assign alu_b = is_R ? rt_data : $signed(imm);
    
    // FIX: corrected illegal case item syntax (e.g. "3'b001:3'b111:" -> separate items)
    always @(*) begin
        if(is_ADDI) alu_result = alu_a + alu_b;
        else if(is_SUBI) alu_result = alu_a - alu_b;
        else begin
            case(alu_op)
                3'b000: alu_result = alu_a + alu_b;
                3'b001: alu_result = alu_a - alu_b;
                3'b111: alu_result = alu_a - alu_b;
                3'b010: alu_result = alu_a & alu_b;
                3'b100: alu_result = alu_a & alu_b;
                3'b011: alu_result = alu_a | alu_b;
                3'b101: alu_result = alu_a | alu_b;
                3'b110: alu_result = alu_a ^ alu_b;
                default: alu_result = 0;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) alu_result_r <= 0;
        else begin
            if(alu_op == 3'b100 || alu_op == 3'b101) alu_result_r <= ~alu_result;
            else if(alu_op == 3'b111) alu_result_r <= alu_result[15] ? 1 : 0;
            else alu_result_r <= alu_result;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) mult_result_r <= 0;
        else mult_result_r <= mult_result;
    end
    
    mult_16bit mult(
        .clk(clk),
        .rst_n(rst_n),
        .A(rs_data),
        .B(rt_data),
        .mult_en((state == EXE) && is_mult),
        .result(mult_result),
        .mult_done(mult_done)
    );
    
    endmodule
    
    module Fetch(
        input clk,
        input rst_n,
        input in_valid_i,
        input [12:0] pc_i,
        output reg [15:0] instr_o,
        output reg        instr_valid_o,
        // AXI read addr 
        input                   arready_m_inf_inst,
        output reg              arvalid_m_inf_inst,
        output [31:0]           araddr_m_inf_inst,
    
        // AXI read data channel
        input rlast_m_inf_inst,
        input rvalid_m_inf_inst,
        input [15:0] rdata_m_inf_inst,
        output rready_m_inf_inst
    );
    
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 16;
    
    reg [2:0] state, next_state;
    localparam IDLE      = 3'd0;
    localparam READ      = 3'd1;
    localparam READ_DONE = 3'd2;
    localparam FETCH_DONE = 3'd3;
    localparam DONE = 3'd4;
    
    wire cache_hit;
    wire [6:0] icache_addr;
    reg [6:0] icache_addr_cnt;
    wire [15:0] icache_rdata;
    reg         icache_web;
    reg [15:0] icache_w_data;
    reg [4:0] icache_tag;
    reg       icache_data_valid;
    
    assign cache_hit = (pc_i[12:8] == icache_tag) && icache_data_valid;
    
    // rready: always ready to accept read data
    assign rready_m_inf_inst = 1'b1;
    
    // araddr: fetch the 256-byte page containing pc_i
    assign araddr_m_inf_inst = {19'b0, pc_i[12:8], 8'b0};
    
    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state <= IDLE;
        else  state <= next_state;
    end
    
    // FSM next state
    always @(*) begin
        case(state)
            IDLE: begin
                if(in_valid_i) next_state = cache_hit ? READ_DONE : READ;
                else next_state = IDLE;
            end
            READ: begin
                // FIX: was checking rlast before rvalid; both must be checked
                if(rvalid_m_inf_inst && rlast_m_inf_inst) next_state = FETCH_DONE;
                else next_state = READ;
            end
            READ_DONE: next_state = DONE;
            DONE: next_state = IDLE;
            FETCH_DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // icache tag and valid
    // FIX: FINISH_JOB -> READ (transition into READ_DONE means last data received)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) icache_data_valid <= 0;
        // Latch valid when the last beat arrives
        else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_data_valid <= 1;
        else icache_data_valid <= icache_data_valid;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) icache_tag <= 0;
        else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_tag <= pc_i[12:8];
        else icache_tag <= icache_tag;
    end
    
    // arvalid: assert when starting a cache miss fetch
    // FIX: removed reference to undefined stall_i
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            arvalid_m_inf_inst <= 0;
        end
        else if(state == IDLE && in_valid_i && !cache_hit) begin
            arvalid_m_inf_inst <= 1;
        end
        else if(arready_m_inf_inst) begin
            arvalid_m_inf_inst <= 0;
        end
        else begin
            arvalid_m_inf_inst <= arvalid_m_inf_inst;
        end
    end
    
    // icache write enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            icache_web <= 1'b1;
            icache_w_data <= 0;
        end
        else if (state == READ && rvalid_m_inf_inst) begin
            icache_web <= 1'b0;  // write when data is valid
            icache_w_data <= rdata_m_inf_inst;
        end
        else begin
            icache_web <= 1'b1;
            icache_w_data <= icache_w_data;
        end
    end
    
    // icache write address counter
    // FIX: original incremented on icache_web (high=read), should increment when writing (!icache_web)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            icache_addr_cnt <= 7'd0;
        end
        else if(state == IDLE) begin
            icache_addr_cnt <= 7'd0;
        end
        else if(!icache_web) begin
            // Advance after each write beat
            icache_addr_cnt <= icache_addr_cnt + 1;
        end
        else begin
            icache_addr_cnt <= icache_addr_cnt;
        end
    end
    assign icache_addr = state == READ || state == FETCH_DONE ? icache_addr_cnt : pc_i[7:1];
    // instruction output
     always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_o       <= 0;
        end
        else begin
            instr_o       <= icache_rdata;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_valid_o <= 0;
        end
        // Hit from cache: read from SRAM
        else if(state == READ_DONE) begin
            instr_valid_o <= 1;
        end
        else begin
            instr_valid_o <= 0;
        end
    end
    
    SRAM_128_16 icache(
        .clk(clk),
        .addr(icache_addr),
        .data_i(icache_w_data),
        .WEB(icache_web),
        .data_o(icache_rdata)
    );
    
    endmodule
    
    // =====================================================================
    // mult_16bit: 2-stage pipelined 16-bit signed multiplier
    // =====================================================================
    // module mult_16bit(
    //     input clk,
    //     input rst_n,
    //     input  signed [15:0] a,
    //     input  signed [15:0] b,
    //     output reg [31:0] result
    // );
    // reg        sign_r;
    // reg [15:0] ll, lh, hl, hh;
    // wire [15:0] unsigned_a = a[15] ? (~a + 1) : a;
    // wire [15:0] unsigned_b = b[15] ? (~b + 1) : b;
    // wire [31:0] unsigned_result;
    
    // always @(posedge clk or negedge rst_n) begin
    //     if(!rst_n) begin
    //         ll     <= 0;
    //         lh     <= 0;
    //         hl     <= 0;
    //         hh     <= 0;
    //         sign_r <= 0;
    //         result <= 0;
    //     end
    //     else begin
    //         ll     <= unsigned_a[7:0]  * unsigned_b[7:0];
    //         lh     <= unsigned_a[7:0]  * unsigned_b[15:8];
    //         hl     <= unsigned_a[15:8] * unsigned_b[7:0];
    //         hh     <= unsigned_a[15:8] * unsigned_b[15:8];
    //         sign_r <= a[15] ^ b[15];
    //         result <= sign_r ? (~unsigned_result + 1) : unsigned_result;
    //     end
    // end
    // assign unsigned_result = {hh, 16'b0} + {lh, 8'b0} + {hl, 8'b0} + ll;
    // endmodule
//    module mult_16bit(
//     input                clk,
//     input                rst_n,
//     input  signed [15:0] A,
//     input  signed [15:0] B,
//     output signed [31:0] result
// );

//     wire sign = A[15] ^ B[15];

//     wire [15:0] abs_A = A[15] ? (~A + 16'd1) : A;
//     wire [15:0] abs_B = B[15] ? (~B + 16'd1) : B;

//     wire [3:0] a_w0 = abs_A[3:0];
//     wire [3:0] a_w1 = abs_A[7:4];
//     wire [3:0] a_w2 = abs_A[11:8];
//     wire [3:0] a_w3 = abs_A[15:12];

//     wire [3:0] b_w0 = abs_B[3:0];
//     wire [3:0] b_w1 = abs_B[7:4];
//     wire [3:0] b_w2 = abs_B[11:8];
//     wire [3:0] b_w3 = abs_B[15:12];

//     reg [7:0] p_0_0, p_0_1, p_0_2, p_0_3;
//     reg [7:0] p_1_0, p_1_1, p_1_2, p_1_3;
//     reg [7:0] p_2_0, p_2_1, p_2_2, p_2_3;
//     reg [7:0] p_3_0, p_3_1, p_3_2, p_3_3;

//     reg sign_r1, sign_r2, sign_r3;

//     reg [31:0] l0, l1, l2, l3, l4, l5, l6;
//     reg [31:0] partial_sum;

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             p_0_0 <= 0; p_0_1 <= 0; p_0_2 <= 0; p_0_3 <= 0;
//             p_1_0 <= 0; p_1_1 <= 0; p_1_2 <= 0; p_1_3 <= 0;
//             p_2_0 <= 0; p_2_1 <= 0; p_2_2 <= 0; p_2_3 <= 0;
//             p_3_0 <= 0; p_3_1 <= 0; p_3_2 <= 0; p_3_3 <= 0;

//             sign_r1 <= 0;
//             sign_r2 <= 0;
//             sign_r3 <= 0;

//             l0 <= 0; l1 <= 0; l2 <= 0; l3 <= 0;
//             l4 <= 0; l5 <= 0; l6 <= 0;
//             partial_sum <= 0;
//         end
//         else begin
//             // stage 1: 4x4 partial products
//             p_0_0 <= a_w0 * b_w0;
//             p_0_1 <= a_w0 * b_w1;
//             p_0_2 <= a_w0 * b_w2;
//             p_0_3 <= a_w0 * b_w3;

//             p_1_0 <= a_w1 * b_w0;
//             p_1_1 <= a_w1 * b_w1;
//             p_1_2 <= a_w1 * b_w2;
//             p_1_3 <= a_w1 * b_w3;

//             p_2_0 <= a_w2 * b_w0;
//             p_2_1 <= a_w2 * b_w1;
//             p_2_2 <= a_w2 * b_w2;
//             p_2_3 <= a_w2 * b_w3;

//             p_3_0 <= a_w3 * b_w0;
//             p_3_1 <= a_w3 * b_w1;
//             p_3_2 <= a_w3 * b_w2;
//             p_3_3 <= a_w3 * b_w3;

//             sign_r1 <= sign;
//             sign_r2 <= sign_r1;
//             sign_r3 <= sign_r2;

//             // stage 2: group by weight
//             l0 <= p_0_0;
//             l1 <= (p_0_1 + p_1_0) << 4;
//             l2 <= (p_0_2 + p_1_1 + p_2_0) << 8;
//             l3 <= (p_0_3 + p_1_2 + p_2_1 + p_3_0) << 12;
//             l4 <= (p_1_3 + p_2_2 + p_3_1) << 16;
//             l5 <= (p_2_3 + p_3_2) << 20;
//             l6 <= p_3_3 << 24;

//             // stage 3: final sum
//             partial_sum <= l0 + l1 + l2 + l3 + l4 + l5 + l6;
//         end
//     end

//     assign result = sign_r3 ? (~partial_sum + 32'd1) : partial_sum;

// endmodule
// module mult_16bit(
//     input                    clk,
//     input                    rst_n,
//     input                    mult_en,
//     input  signed [15:0]     A,
//     input  signed [15:0]     B,
//     output signed [31:0]     result,
//     output                   mult_done
// );

//     // ── 絕對值與符號 ─────────────────────────────────────
//     wire [15:0] abs_A = A[15] ? (~A + 16'd1) : A;
//     wire [15:0] abs_B = B[15] ? (~B + 16'd1) : B;
//     wire        sign  = A[15] ^ B[15];

//     // ── 暫存器 ───────────────────────────────────────────
//     // shifted_A 最大：abs_A(15-bit) << 14 = 29-bit，取 30-bit 安全
//     reg [30:0]  shifted_A;
//     // shift_B：{abs_B[15:0], prev=0}，共 17-bit，每次右移 2-bit
//     reg [17:0]  shift_B;    // 18-bit = 16 + 補的 2-bit (前一位 + 多一位 padding)
//     reg [30:0]  acc;
//     reg         sign_r;
//     reg [3:0]   cnt;
//     reg         running;

//     // ── FSM ──────────────────────────────────────────────
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             cnt     <= 0;
//             running <= 0;
//         end
//         else if (mult_en) begin
//             cnt     <= 1;
//             running <= 1;
//         end
//         else if (running) begin
//             if (cnt == 4'd8) begin
//                 cnt     <= 0;
//                 running <= 0;
//             end
//             else cnt <= cnt + 1;
//         end
//     end

//     assign mult_done = running && (cnt == 4'd8);

//     // ── Booth radix-4 主體 ───────────────────────────────
//     // shift_B 初始：{1'b0, abs_B, 1'b0}（高位補 0，低位補 B[-1]=0）
//     // 每拍看 shift_B[2:0]（3-bit 窗口）：
//     //   000, 111 → +0
//     //   001, 010 → +shifted_A
//     //   011      → +2*shifted_A
//     //   100      → -2*shifted_A
//     //   101, 110 → -shifted_A
//     // 然後 shift_B 右移 2-bit，shifted_A 左移 2-bit

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             shifted_A <= 0;
//             shift_B   <= 0;
//             acc       <= 0;
//             sign_r    <= 0;
//         end
//         else if (mult_en) begin
//             sign_r    <= sign;
//             shifted_A <= {15'b0, abs_A};          // 初始不移位
//             shift_B   <= {1'b0, abs_B, 1'b0};     // {0, B[15:0], B[-1]=0}
//             acc       <= 0;
//         end
//         else if (running && cnt != 4'd8) begin
//             case (shift_B[2:0])
//                 3'b000: acc <= acc;
//                 3'b001: acc <= acc + shifted_A;
//                 3'b010: acc <= acc + shifted_A;
//                 3'b011: acc <= acc + (shifted_A << 1);
//                 3'b100: acc <= acc - (shifted_A << 1);
//                 3'b101: acc <= acc - shifted_A;
//                 3'b110: acc <= acc - shifted_A;
//                 3'b111: acc <= acc;
//                 default: acc <= acc;
//             endcase
//             shifted_A <= shifted_A << 2;           // 每拍移 2-bit
//             shift_B   <= {2'b0, shift_B[17:2]};   // 每拍右移 2-bit
//         end
//     end

//     // ── 輸出補符號 ───────────────────────────────────────
//     wire [31:0] unsigned_result = {1'b0, acc};
//     assign result = sign_r ? (~unsigned_result + 32'd1) : unsigned_result;

// endmodule
module mult_16bit(
    input                    clk,
    input                    rst_n,
    input                    mult_en,
    input  signed [15:0]     A,
    input  signed [15:0]     B,
    output signed [31:0]     result,
    output                   mult_done
);
    reg [3:0] shift_cnt;
    reg start_mult;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_mult <= 0;
        end
        else if (mult_en) begin
            start_mult <= 1;
        end
        else if (mult_done) begin
            start_mult <= 0;
        end
        else begin
            start_mult <= start_mult;
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_cnt <= 0;
        end
        else if (start_mult) begin
            shift_cnt <= shift_cnt + 1;
        end
        else begin
            shift_cnt <= 0;
        end
    end
    assign mult_done = shift_cnt == 4'd14;
    wire [15:0] abs_A = A[15] ? (~A + 16'd1) : A;
    wire [15:0] abs_B = B[15] ? (~B + 16'd1) : B;
    wire        sign  = A[15] ^ B[15];

    reg [31:0]  shifted_A;
    reg [15:0]  shift_B;
    reg         sign_r;
    reg [31:0]  acc;              

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_A <= 0;
            shift_B   <= 0;
            sign_r    <= 0;
            acc       <= 0;
        end
        else if (mult_en) begin
            sign_r    <= sign;
            shifted_A <= {16'b0, abs_A} << 1;
            shift_B   <= {1'b0, abs_B[15:1]};
            acc       <= abs_B[0] ? {16'b0, abs_A} : 32'd0;
        end
        else begin
            shifted_A <= shifted_A << 1;
            acc       <= shift_B[0] ? acc + shifted_A : acc;
            shift_B   <= {1'b0, shift_B[15:1]};
        end
    end

    assign result = sign_r ? (~acc + 32'd1) : acc;

endmodule
    // =====================================================================
    // SRAM_128_16 wrapper
    // =====================================================================
    module SRAM_128_16(
        clk, addr, data_i, WEB, data_o
    );
    input         clk;
    input  [6:0]  addr;
    input  [15:0] data_i;
    input         WEB;
    output [15:0] data_o;
    
    CACHE_128X16X1BM1 u_SRAM_128_16
    (
        .A0(addr[0]), .A1(addr[1]), .A2(addr[2]),.A3(addr[3]), .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), 
        .DO0(data_o[0]),  .DO1(data_o[1]),  .DO2(data_o[2]),   .DO3(data_o[3]),   .DO4(data_o[4]),   .DO5(data_o[5]),   .DO6(data_o[6]),   .DO7(data_o[7]),  
        .DO8(data_o[8]),  .DO9(data_o[9]),  .DO10(data_o[10]), .DO11(data_o[11]), .DO12(data_o[12]), .DO13(data_o[13]), .DO14(data_o[14]), .DO15(data_o[15]),
        .DI0(data_i[0]),   .DI1(data_i[1]),   .DI2(data_i[2]),    .DI3(data_i[3]),    .DI4(data_i[4]),    .DI5(data_i[5]),    .DI6(data_i[6]),    .DI7(data_i[7]),   
        .DI8(data_i[8]),   .DI9(data_i[9]),   .DI10(data_i[10]),  .DI11(data_i[11]),  .DI12(data_i[12]),  .DI13(data_i[13]),  .DI14(data_i[14]),  .DI15(data_i[15]),   
        .CK(clk),           .WEB(WEB),   	     .OE(1'b1), 	     .CS(1'b1)
    );
    
    endmodule