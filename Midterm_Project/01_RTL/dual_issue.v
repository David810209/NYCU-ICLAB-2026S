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
    
        // =====================================================
        // AXI data channel wires: Core (Memory) -> DCCPU ports
        // Channels used inside Memory are wired through; the rest
        // keep the DCCPU default values.
        // =====================================================
        wire                  arvalid_data_c;
        wire [ADDR_WIDTH-1:0] araddr_data_c;
        wire                  awvalid_data_c;
        wire [ADDR_WIDTH-1:0] awaddr_data_c;
        wire [BURST_LEN-1:0]  awlen_data_c;
        wire [DATA_WIDTH-1:0] wdata_data_c;
        wire                  wvalid_data_c;
        wire                  wlast_data_c;
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
        assign awsize_m_inf_inst_2  = 3'b001;
        assign awburst_m_inf_inst_2 = 2'b01;
        assign awlen_m_inf_inst_2   = 0;
        assign awvalid_m_inf_inst_2 = 0;
        assign wdata_m_inf_inst_2   = 0;
        assign wlast_m_inf_inst_2   = 0;
        assign wvalid_m_inf_inst_2  = 0;
        assign bready_m_inf_inst_2  = 0;
        
        // Data write:
        //   AW/W signals that Memory actually drives -> pass-through.
        //   Unused fields keep the original DCCPU defaults.
        assign awid_m_inf_data    = 0;
        assign awaddr_m_inf_data  = awaddr_data_c;
        assign awsize_m_inf_data  = 3'b001;
        assign awburst_m_inf_data = 2'b01;
        assign awlen_m_inf_data   = awlen_data_c;
        assign awvalid_m_inf_data = awvalid_data_c;
        assign wdata_m_inf_data   = wdata_data_c;
        assign wlast_m_inf_data   = wlast_data_c;
        assign wvalid_m_inf_data  = wvalid_data_c;
        assign bready_m_inf_data  = 1;
        
        // Data read (AR / R): wire up to Core -> Memory
        assign arid_m_inf_data    = 0;
        assign arlen_m_inf_data   = 7'b1111111;
        assign arsize_m_inf_data  = 3'b001;
        assign arburst_m_inf_data = 2'b01;
        assign arvalid_m_inf_data = arvalid_data_c;
        assign araddr_m_inf_data  = araddr_data_c;
        assign rready_m_inf_data  = 1'b1;
        
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
            .rready_m_inf_inst2(rready_inst_2),
            // AXI data read (AR + R)
            .arvalid_m_inf_data(arvalid_data_c),
            .araddr_m_inf_data(araddr_data_c),
            .arready_m_inf_data(arready_m_inf_data),
            .rvalid_m_inf_data(rvalid_m_inf_data),
            .rlast_m_inf_data(rlast_m_inf_data),
            .rdata_m_inf_data(rdata_m_inf_data),
            // AXI data write (AW + W)
            .awvalid_m_inf_data(awvalid_data_c),
            .awaddr_m_inf_data(awaddr_data_c),
            .awlen_m_inf_data(awlen_data_c),
            .awready_m_inf_data(awready_m_inf_data),
            .wdata_m_inf_data(wdata_data_c),
            .wlast_m_inf_data(wlast_data_c),
            .wvalid_m_inf_data(wvalid_data_c),
            .wready_m_inf_data(wready_m_inf_data)
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
                stall_1 <= 1;
                stall_2 <= 1;
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
            output  current_core,
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
            output                  rready_m_inf_inst2,
    
            // AXI read addr channel (data)
            output                  arvalid_m_inf_data,
            output [31:0]           araddr_m_inf_data,
            input                   arready_m_inf_data,
            // AXI read data channel (data)
            input                   rlast_m_inf_data,
            input                   rvalid_m_inf_data,
            input  [15:0]           rdata_m_inf_data,
            // AXI write addr channel (data)
            output                  awvalid_m_inf_data,
            output [31:0]           awaddr_m_inf_data,
            output [6:0]            awlen_m_inf_data,
            input                   awready_m_inf_data,
            // AXI write data channel (data)
            output [15:0]           wdata_m_inf_data,
            output                   wlast_m_inf_data,
            output                   wvalid_m_inf_data,
            input                   wready_m_inf_data
        );
        // FSM
        reg [2:0] state, next_state;
        localparam IF  = 3'd0;
        localparam ID  = 3'd1;
        localparam EXE = 3'd2;
        localparam EXE2= 3'd3;
        localparam WB  = 3'd4;
        localparam MEM = 3'd5;
        localparam  FLUSH = 3'd6;
        localparam FLUSH_WB = 3'd7;
        // PC
        reg [12:0] pc;
        reg [12:0] pc_2;
        wire [12:0] pc_sel;
        wire [12:0] pc_next;
        // icache signal
        reg [15:0] if_instr_r [1:0];
        reg instr_prefetch_flag [1:0];
        wire [15:0] if_instr_sel;
        reg current_fetch_core;
        wire instr_fetch;
        // prefetch
        wire can_prefetch;
        reg start_prefetch;
        // decode
        wire [2:0] opcode;
        wire [2:0] opcode2;
        wire [2:0] alu_op;
        wire [6:0] imm;
        wire [12:0] jump_target;
        wire [2:0] rd_addr;
        wire is_R, is_mult, is_I, is_Load, is_Store, is_Branch, is_Jump, is_ADDI, is_SUBI;
        wire core1_is_Branch, core1_is_Jump;
        wire core2_is_Branch, core2_is_Jump;
        wire core1_is_Load, core1_is_Store;
        wire core2_is_Load, core2_is_Store;
        reg current_core_r;
        // exe
        wire signed [15:0] alu_a, alu_b;
        reg signed [15:0] alu_result, alu_result_r;
        wire [31:0] mult_result;
        wire branch_taken;
        // reg [31:0] mult_result_r;
        wire mult_done;
    
        wire                  fetch_arvalid;
        wire [31:0]           fetch_araddr;
        wire                  fetch_arready;
        wire                  fetch_rlast;
        wire                  fetch_rvalid;
        wire [15:0]           fetch_rdata;
        // memory
        wire change_order;
        reg change_order_r;
        // Memory module I/O
        wire [15:0] cache_data_o;
        wire        cache_data_valid_o;
        wire [12:0] mem_addr_sel;
        // flush signal
        reg [5:0] instr_counter;
        wire flush_done;
        assign arvalid_m_inf_inst   = (current_fetch_core == 1'b0) ? fetch_arvalid : 1'b0;
        assign araddr_m_inf_inst    = (current_fetch_core == 1'b0) ? fetch_araddr  : 32'b0;
        assign rready_m_inf_inst    = 1'b1;
    
        assign arvalid_m_inf_inst2  = (current_fetch_core == 1'b1) ? fetch_arvalid : 1'b0;
        assign araddr_m_inf_inst2   = (current_fetch_core == 1'b1) ? fetch_araddr  : 32'b0;
        assign rready_m_inf_inst2   = 1'b1;
    
        assign fetch_arready = (current_fetch_core == 1'b0) ? arready_m_inf_inst  : arready_m_inf_inst2;
        assign fetch_rlast   = (current_fetch_core == 1'b0) ? rlast_m_inf_inst    : rlast_m_inf_inst2;
        assign fetch_rvalid  = (current_fetch_core == 1'b0) ? rvalid_m_inf_inst   : rvalid_m_inf_inst2;
        assign fetch_rdata   = (current_fetch_core == 1'b0) ? rdata_m_inf_inst    : rdata_m_inf_inst2;
    
        // pc   
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) pc <= 0;
            else if(is_wb && !(core1_is_Branch || core1_is_Jump)) pc <= pc + 2;
            else if(state == EXE && current_core == 0 && is_Branch) pc <= branch_taken ? alu_result[12:0] : pc + 2;
            else if(state == ID && current_core == 0 && is_Jump) pc <= jump_target;
            else pc <= pc;
        end
        // pc2   
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) pc_2 <= 0;
            else if(is_wb && !(core2_is_Branch || core2_is_Jump)) pc_2 <= pc_2 + 2;
            else if(state == EXE && current_core == 1 && is_Branch) pc_2 <= branch_taken ? alu_result[12:0] : pc_2 + 2;
            else if(state == ID && current_core == 1 && is_Jump) pc_2 <= jump_target;
            else pc_2 <= pc_2;
        end
        assign pc_sel = current_core == 0 ? pc : pc_2;
        assign pc_next = pc_sel + 2;
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                instr_prefetch_flag <= '{default: 0};
            end
            else if(state == IF) begin
                instr_prefetch_flag[current_fetch_core] <= 0;
            end
            else if(start_prefetch && cache_data_valid_o) begin
                instr_prefetch_flag[current_fetch_core] <= 1;
            end
            else begin
                instr_prefetch_flag[1:0] <= instr_prefetch_flag[1:0];
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                if_instr_r <= '{default: 0};
            end
            else if(instr_fetch && cache_data_valid_o) begin
                if_instr_r[current_fetch_core] <= cache_data_o;
            end
            else begin
                if_instr_r[1:0] <= if_instr_r[1:0];
            end
        end
        
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) current_core_r <= 0;
            else if(change_order) current_core_r <= 1;
            else if(state == WB) begin
                if(change_order_r && current_core_r == 0) current_core_r <= 0;
                else current_core_r <= ~current_core_r;
            end
            else current_core_r <= current_core_r;
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) current_fetch_core <= 0;
            else if(instr_fetch && cache_data_valid_o) current_fetch_core <= ~current_fetch_core;
            else current_fetch_core <= current_fetch_core;
        end
        // flush
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                instr_counter <= 0;
            end
            else if(is_wb) begin
                instr_counter <= instr_counter == 49 ? 0 : instr_counter + 1;
            end
            else begin
                instr_counter <= instr_counter;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) state <= IF;
            else  state <= next_state;
        end
        
        always @(*) begin
            case(state)
                IF: begin
                    if((cache_data_valid_o && current_fetch_core == 1)) next_state = ID;
                    else next_state = IF;
                end
                ID: begin
                    if(is_Jump) next_state = WB;
                    else 
                    next_state = EXE;
                end
                EXE: begin
                    if(is_Branch && branch_taken) next_state = WB;
                    else if(is_mult) next_state = EXE2;
                    else if(is_Load | is_Store) next_state = MEM;
                    else  next_state = WB;
                end
                EXE2: begin
                    next_state =mult_done ?  WB : EXE2;
                end
                MEM: begin
                    next_state = cache_data_valid_o ? WB : MEM;
                end
                WB: begin
                    if((change_order_r == 0 && current_core_r == 0) || (change_order_r == 1 && current_core_r == 1)) next_state = ID;
                    else if(instr_counter == 49 || (pc == 13'h1FFE && pc_2 == 13'h1FFE))next_state = FLUSH;
                    else next_state = IF;
                end 
                FLUSH:begin
                    if(flush_done) next_state = FLUSH_WB;
                    else next_state = FLUSH;
                end
                FLUSH_WB :begin
                    next_state = IF;
                end
                default: next_state = IF;
            endcase
        end
        
        assign is_wb = (state == WB && ((change_order_r == 0 && current_core_r == 1) || (change_order_r == 1 && current_core_r == 0)) && instr_counter != 49 && ((pc != 13'h1FFE && pc_2 != 13'h1FFE))) || state == FLUSH_WB ? 1 : 0;
        
        assign rf_write     = state == WB && ~is_Store && ~is_Branch && ~is_Jump ? 1 : 0;
        assign rf_rl_write  = state == WB && is_mult ? 1 : 0;
        assign rf_wdata     = is_mult ? mult_result[31:16] : is_Load ? cache_data_o : alu_result_r;
        assign rf_rl_wdata  = mult_result[15:0];
        assign mem_addr_sel = state == MEM ? {alu_result_r[11:0], 1'b0} : (start_prefetch || can_prefetch) ? current_fetch_core == 1 ? pc_2 + 2 : pc +2 : 
                                                                            : current_fetch_core == 1 ? pc_2 : pc;
        assign instr_fetch = state == IF || start_prefetch || can_prefetch;
        Memory memory(
            .clk(clk),
            .rst_n(rst_n),
            .instr_in_valid_i(instr_fetch), 
            .current_fetch_core(current_fetch_core),
            .data_in_valid_i(state == MEM),
            .addr_i(mem_addr_sel),
            .wdata_i(rt_data),
            .is_Store(is_Store),
            .data_o(cache_data_o),
            .data_valid_o(cache_data_valid_o),
            .flush_i(state == FLUSH ? 1'b1 : 1'b0),
            .flush_done_o(flush_done),
            // AXI read addr 
            .arready_m_inf_inst(fetch_arready),
            .arvalid_m_inf_inst(fetch_arvalid),
            .araddr_m_inf_inst(fetch_araddr),
            // AXI read data channel
            .rlast_m_inf_inst(fetch_rlast),
            .rvalid_m_inf_inst(fetch_rvalid),
            .rdata_m_inf_inst(fetch_rdata),
            // AXI read addr (data)
            .arready_m_inf_data(arready_m_inf_data),
            .arvalid_m_inf_data(arvalid_m_inf_data),
            .araddr_m_inf_data(araddr_m_inf_data),
            // AXI read data (data)
            .rlast_m_inf_data(rlast_m_inf_data),
            .rvalid_m_inf_data(rvalid_m_inf_data),
            .rdata_m_inf_data(rdata_m_inf_data),
            // AXI write addr (data)
            .awvalid_m_inf_data(awvalid_m_inf_data),
            .awaddr_m_inf_data(awaddr_m_inf_data),
            .awlen_m_inf_data(awlen_m_inf_data),
            .awready_m_inf_data(awready_m_inf_data),
            // AXI write data (data)
            .wdata_m_inf_data(wdata_m_inf_data),
            .wlast_m_inf_data(wlast_m_inf_data),
            .wvalid_m_inf_data(wvalid_m_inf_data),
            .wready_m_inf_data(wready_m_inf_data)
        );
        // decode
        assign if_instr_sel = change_order ? if_instr_r[1] : 
                                current_core ? if_instr_r[1] : if_instr_r[0];
        assign opcode      = if_instr_sel[15:13];
        assign opcode2     = if_instr_r[1][15:13];
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
        assign core1_is_Branch = if_instr_r[0][15:13] == 3'b110;
        assign core1_is_Jump   = if_instr_r[0][15:13] == 3'b111;
        assign core2_is_Branch = opcode2 == 3'b110;
        assign core2_is_Jump   = opcode2 == 3'b111;
        assign is_Branch   = current_core ? core2_is_Branch : core1_is_Branch;
        assign is_Jump     = current_core ? core2_is_Jump : core1_is_Jump;
        assign core1_is_Load = if_instr_r[0][15:13] == 3'b100;
        assign core1_is_Store = if_instr_r[0][15:13] == 3'b101;
        assign core2_is_Load = opcode2 == 3'b100;
        assign core2_is_Store = opcode2 == 3'b101;
        always @(*) begin
            dec_wb_addr_r    = is_R | is_mult ? rd_addr : rt_addr;
        end
        assign current_core = change_order ? 1'b1 : current_core_r;
        assign change_order = state == ID && current_core_r == 0 && core1_is_Load && core2_is_Store && change_order_r == 0;
    
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) change_order_r <= 0;
            else if(change_order)change_order_r <= 1;
            else if(state == WB && current_core_r == 0) change_order_r <= 0;
            else change_order_r <= change_order_r;
        end
    
        // prefetch
        assign can_prefetch = state == ID && (is_R || is_mult || is_I);
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) start_prefetch <= 0;
            else if(can_prefetch)start_prefetch <= 1;
            else if(data_valid_o) start_prefetch <= 0;
            else start_prefetch <= start_prefetch;
        end
        // exe
        assign alu_a = is_Branch ? pc_next : rs_data;
        assign alu_b = is_R ? rt_data :  {{9{imm[6]}}, imm};
        assign branch_taken = rs_data == rt_data;
        // FIX: corrected illegal case item syntax (e.g. "3'b001:3'b111:" -> separate items)
        always @(*) begin
            if(is_ADDI || is_Load || is_Store || is_Branch) alu_result = alu_a + alu_b;
            else if(is_SUBI) alu_result = alu_a - alu_b;
            else begin
                case(alu_op)
                    3'b000: alu_result = alu_a + alu_b;
                    3'b001: alu_result = alu_a - alu_b;
                    3'b111: alu_result = alu_a < alu_b ? 1 : 0;
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
                if(is_ADDI || is_SUBI || is_Load || is_Store) alu_result_r <= alu_result;
                else begin
                    if(alu_op == 3'b100 || alu_op == 3'b101) alu_result_r <= ~alu_result;
                    else alu_result_r <= alu_result;
                end
            end
        end
        
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) mult_result_r <= 0;
        //     else mult_result_r <= mult_result;
        // end
        
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
        
        module Memory(
            input clk,
            input rst_n,
            input instr_in_valid_i,
            input current_fetch_core,
            input data_in_valid_i,
            input [12:0] addr_i,
            input [15:0] wdata_i,
            input is_Store,
            output reg [15:0] data_o,
            output reg        data_valid_o,
            input flush_i,
            output reg flush_done_o,
            // AXI read addr 
            input                   arready_m_inf_inst,
            output reg              arvalid_m_inf_inst,
            output [31:0]           araddr_m_inf_inst,
        
            // AXI read data channel
            input rlast_m_inf_inst,
            input rvalid_m_inf_inst,
            input [15:0] rdata_m_inf_inst,
            // AXI read addr 
            input                   arready_m_inf_data,
            output reg              arvalid_m_inf_data,
            output [31:0]           araddr_m_inf_data,
        
            // AXI read data channel
            input rlast_m_inf_data,
            input rvalid_m_inf_data,
            input [15:0] rdata_m_inf_data,
    
            // AXI write addr channel
            input                   awready_m_inf_data,
            output reg              awvalid_m_inf_data,
            output [31:0]           awaddr_m_inf_data,
            output reg [6:0]            awlen_m_inf_data,
    
            // AXI write data channel
            input                   wready_m_inf_data,
            output   reg           wlast_m_inf_data,
            output               wvalid_m_inf_data,
            output   [15:0]      wdata_m_inf_data
        );
        
        parameter ADDR_WIDTH = 32;
        parameter DATA_WIDTH = 16;
        
        reg [2:0] state, next_state;
        localparam IDLE      = 3'd0;
        localparam READ      = 3'd1;
        localparam READ_DONE = 3'd2;
        localparam FETCH_DONE = 3'd3;
        localparam DONE = 3'd4;
        localparam WRITE = 3'd5;
        localparam ISSUE_WRITE = 3'd6;
        localparam GET_CACHE_DATA = 3'd7;
        wire cache_hit;
        wire [8:0] dcache_addr;
        wire [6:0] dcache_addr_sel;
        reg [6:0] dcache_addr_cnt;
        wire [15:0] dcache_rdata;
        reg         dcache_web;
        reg [15:0] dcache_w_data;
        reg [3:0] dcache_tag [1:0];
        reg dcache_dirty [1:0];
        reg       dcache_data_valid [1:0];
        wire cache_idx;
        wire [3:0] cache_tag;
        wire [6:0] cache_offset;
        wire [1:0] plus_dram_addr_offest;
    
        reg [6:0] dcache_dirty_start_addr [1:0];
        reg [6:0] dcache_dirty_end_addr [1:0];
        reg [6:0] dirty_data_num;
        wire [1:0] victim_plus_dram_addr_offest;
        wire flush_entry;
        wire [1:0] need_flush_num;
        reg [1:0] need_flush_num_r;
        reg [1:0] flush_cnt;
        reg [1:0] flush_read_cache_cnt;
        reg [6:0] flush_issue_cnt;
        wire entry_sel;
        reg [15:0] cache_data_buffer [1:0];
    
        // icache
        wire icache_hit;
        reg [4:0] icache_tag[1:0];
        reg       icache_data_valid [1:0];
        wire [6:0] icache_addr_sel;
        reg [6:0] icache_addr_cnt;
        // icache
        assign icache_hit = (addr_i[12:8] == icache_tag[current_fetch_core]) && icache_data_valid[current_fetch_core];
        assign araddr_m_inf_inst = {19'b0, addr_i[12:8], 8'b0};
        // icache tag and valid
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) icache_data_valid [1:0] <= '{default :0};
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_data_valid[current_fetch_core] <= 1;
            else icache_data_valid[1:0] <= icache_data_valid[1:0];
        end
        
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) icache_tag[1:0] <= '{default :0};
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_tag[current_fetch_core] <= addr_i[12:8];
            else icache_tag[1:0] <= icache_tag[1:0];
        end
    
        assign cache_idx = addr_i[8];
        assign cache_tag = addr_i[12:9];
        assign cache_offset = addr_i[7:1];
        assign cache_hit = (cache_tag == dcache_tag[cache_idx]) && dcache_data_valid[cache_idx];
        
        //assign plus_dram_addr_offest = addr_i[12] ? 2'b10 : 2'b01;
        assign plus_dram_addr_offest = {addr_i[12], ~addr_i[12]};
        // araddr: fetch the 256-byte page containing addr_i
        assign araddr_m_inf_data = {18'b0, plus_dram_addr_offest,addr_i[11:8], 8'b0};
        
        // FSM state register
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) state <= IDLE;
            else  state <= next_state;
        end
        
        // FSM next state
        always @(*) begin
            case(state)
                IDLE: begin
                    if(flush_i) begin
                        if(need_flush_num == 0) next_state = DONE;
                        else next_state = ISSUE_WRITE;
                    end
                    else if(data_in_valid_i) next_state = cache_hit ? READ_DONE : 
                                dcache_dirty[cache_idx] ? ISSUE_WRITE : READ;
                    else if(instr_in_valid_i) next_state = icache_hit ? READ_DONE : READ;
                    else next_state = IDLE;
                end
                WRITE: begin
                    if(wlast_m_inf_data && wready_m_inf_data)begin 
                        if(flush_i) begin
                            if(need_flush_num_r == flush_cnt + 1) next_state = DONE;
                            else next_state = ISSUE_WRITE;
                        end
                        else next_state = READ;
                    end
                    else next_state = WRITE;
                end
                READ: begin
                    if(rvalid_m_inf_data && rlast_m_inf_data) next_state = FETCH_DONE;
                    else if(rvalid_m_inf_inst && rlast_m_inf_inst) next_state = FETCH_DONE;
                    else next_state = READ;
                end
                ISSUE_WRITE:begin
                    if(awready_m_inf_data) next_state = GET_CACHE_DATA;
                    else next_state = ISSUE_WRITE;
                end
                GET_CACHE_DATA:begin
                    if(flush_read_cache_cnt == 3) next_state = WRITE;
                    else next_state = GET_CACHE_DATA;
                end
                READ_DONE: next_state = DONE;
                DONE: next_state = IDLE;
                FETCH_DONE: next_state = IDLE;
                default: next_state = IDLE;
            endcase
        end
        
        // dcache tag and valid
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) dcache_data_valid[1:0] <= '{default : 0};
            else if(state == READ && rvalid_m_inf_data && rlast_m_inf_data) dcache_data_valid[cache_idx] <= 1;
            else dcache_data_valid[1:0] <= dcache_data_valid[1:0];
        end
    
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                dcache_dirty[1:0] <= '{default : 0};
    
                dcache_dirty_start_addr[0] <= 127;
                dcache_dirty_start_addr[1] <= 127;
                dcache_dirty_end_addr[0] <= 0;
                dcache_dirty_end_addr[1] <= 0;
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i) begin
                dcache_dirty[cache_idx] <= 1;
    
                if(cache_offset > dcache_dirty_end_addr[cache_idx]) 
                    dcache_dirty_end_addr[cache_idx] <= cache_offset;
                if(cache_offset < dcache_dirty_start_addr[cache_idx]) 
                    dcache_dirty_start_addr[cache_idx] <= cache_offset;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data) begin
                dcache_dirty[entry_sel] <= 0;
    
                dcache_dirty_start_addr[entry_sel] <= 127;
                dcache_dirty_end_addr[entry_sel] <= 0;
            end
            else begin
                dcache_dirty[1:0] <= dcache_dirty[1:0];
    
                dcache_dirty_start_addr[1:0] <= dcache_dirty_start_addr[1:0];
                dcache_dirty_end_addr[1:0] <= dcache_dirty_end_addr[1:0];
            end
        end
        assign entry_sel = flush_i ? flush_entry : cache_idx;
        assign dirty_data_num = dcache_dirty_end_addr[entry_sel] - dcache_dirty_start_addr[entry_sel];
    
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) dcache_tag[1:0] <= '{default : 0};
            else if(state == READ && rvalid_m_inf_data && rlast_m_inf_data) dcache_tag[cache_idx]  <= addr_i[12:9];
            else dcache_tag[1:0] <= dcache_tag[1:0];
        end
        
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                arvalid_m_inf_data <= 0;
            end
            else if(state != READ && next_state == READ && data_in_valid_i) begin
                arvalid_m_inf_data <= 1;
            end
    
            else if(arready_m_inf_data) begin
                arvalid_m_inf_data <= 0;
            end
            else begin
                arvalid_m_inf_data <= arvalid_m_inf_data;
            end
        end
        // aw addr
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                awvalid_m_inf_data <= 0;
            end
            else if(state == IDLE && data_in_valid_i && ~cache_hit && dcache_dirty[cache_idx]) begin
                awvalid_m_inf_data <= 1;
            end
            else if(state == ISSUE_WRITE) begin
                if(awready_m_inf_data) awvalid_m_inf_data <= 0;
                else awvalid_m_inf_data <= 1;
            end
            else begin
                awvalid_m_inf_data <= awvalid_m_inf_data;
            end
        end
    
        // dcache write enable
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dcache_web <= 1'b1;
                dcache_w_data <= 0;
            end
            else if (state == READ && rvalid_m_inf_data) begin
                dcache_web <= 1'b0;  // write when data is valid
                dcache_w_data <= rdata_m_inf_data;
            end
            else if (state == READ && rvalid_m_inf_inst) begin
                dcache_web <= 1'b0;  
                dcache_w_data <= rdata_m_inf_inst;
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i) begin
                dcache_web <= 1'b0;
                dcache_w_data <= wdata_i;
            end
            else begin
                dcache_web <= 1'b1;
                dcache_w_data <= dcache_w_data;
            end
        end
        
        // dcache write address counter
        // FIX: original incremented on dcache_web (high=read), should increment when writing (!dcache_web)
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dcache_addr_cnt <= 7'd0;
            end
            else if(state  == ISSUE_WRITE) begin
                dcache_addr_cnt <= dcache_dirty_start_addr[entry_sel];
            end
            else if(state != READ && next_state == READ) begin
                dcache_addr_cnt <= 7'd0;
            end
            else if(state == GET_CACHE_DATA) begin
                if(flush_read_cache_cnt >= 2) dcache_addr_cnt <= dcache_addr_cnt;
                else dcache_addr_cnt <= dcache_addr_cnt + 1;
            end
            else if(state == WRITE) begin
                if(wready_m_inf_data) dcache_addr_cnt <= dcache_addr_cnt + 1;
                else dcache_addr_cnt <= dcache_addr_cnt;
            end
            else if(!dcache_web) begin
                // Advance after each write beat
                dcache_addr_cnt <= dcache_addr_cnt + 1;
            end
            else begin
                dcache_addr_cnt <= dcache_addr_cnt;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                icache_addr_cnt <= 7'd0;
            end
            else if(state == IDLE) begin
                icache_addr_cnt <= 7'd0;
            end
            else if(!dcache_web) begin
                icache_addr_cnt <= icache_addr_cnt + 1;
            end
            else begin
                icache_addr_cnt <= icache_addr_cnt;
            end
        end
        assign icache_addr_sel = state == READ || state == FETCH_DONE ? icache_addr_cnt : addr_i[7:1];
        assign dcache_addr_sel = state == READ || state == FETCH_DONE || state == ISSUE_WRITE || state == GET_CACHE_DATA || state == WRITE ? dcache_addr_cnt : cache_offset;
        assign dcache_addr = instr_in_valid_i ? {1'b0, current_fetch_core, icache_addr_sel} : {1'b1, entry_sel, dcache_addr_sel};
        // instruction output
            always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                data_o       <= 0;
            end
            else begin
                data_o       <= dcache_rdata;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                data_valid_o <= 0;
            end
            // Hit from cache: read from SRAM
            else if(state == READ_DONE) begin
                data_valid_o <= 1;
            end
            else begin
                data_valid_o <= 0;
            end
        end
        
        SRAM_512_16 dcache(
            .clk(clk),
            .addr(dcache_addr),
            .data_i(dcache_w_data),
            .WEB(dcache_web),
            .data_o(dcache_rdata)
        );
        // write back to memory
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_cnt <= 0;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data) begin
                flush_cnt <= flush_cnt + 1;
            end
            else if(state == DONE)begin
                flush_cnt <= 0;
            end
            else begin
                flush_cnt <= flush_cnt;
            end
        end
    
        assign flush_entry = dcache_dirty[0] && flush_cnt == 0 ? 0 : 1;
        assign need_flush_num = dcache_dirty[0] + dcache_dirty[1];
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                need_flush_num_r <= 0;
            end
            else if(state == IDLE) begin
                need_flush_num_r <= need_flush_num;
            end
            else begin
                need_flush_num_r <= need_flush_num_r;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_read_cache_cnt <= 0;
            end
            else if(state == GET_CACHE_DATA) begin
                flush_read_cache_cnt <= flush_read_cache_cnt == 3 ? 3 : flush_read_cache_cnt + 1;
            end
            else begin
                flush_read_cache_cnt <= 0;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_issue_cnt <= 0;
            end
            else if(state == WRITE) begin
                if(wready_m_inf_data) flush_issue_cnt <= flush_issue_cnt + 1;
                else flush_issue_cnt <= flush_issue_cnt;
            end
            else begin
                flush_issue_cnt <= 0;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                cache_data_buffer <= '{default:0};
            end
            else if(state == GET_CACHE_DATA && flush_read_cache_cnt <= 3) begin
                cache_data_buffer[1] <= data_o;
                cache_data_buffer[0] <= cache_data_buffer[1];
            end
            else if(state == WRITE && wready_m_inf_data)begin
                cache_data_buffer[1] <= 0;
                cache_data_buffer[0] <= cache_data_buffer[1];
            end
        end
        //assign victim_plus_dram_addr_offest = dcache_tag[entry_sel][3] ? 2'b10 : 2'b01;
        assign victim_plus_dram_addr_offest = {dcache_tag[entry_sel][3], ~dcache_tag[entry_sel][3]};
        // araddr: fetch the 256-byte page containing addr_i
        assign awaddr_m_inf_data = {18'b0, victim_plus_dram_addr_offest,dcache_tag[entry_sel][2:0],entry_sel, dcache_dirty_start_addr[entry_sel], 1'b0};
        // assign awlen_m_inf_data = dirty_data_num;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                awlen_m_inf_data <= 0;
            end
            else begin
                awlen_m_inf_data <= dirty_data_num;
            end
        end
        assign wdata_m_inf_data = flush_issue_cnt <= 1 ? cache_data_buffer[0] : data_o;
        assign wvalid_m_inf_data = state == WRITE;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                wlast_m_inf_data <= 0;
            end
            else if(state == WRITE) begin
                if(flush_issue_cnt + 1 == dirty_data_num && wready_m_inf_data) wlast_m_inf_data <= 1;
                else if(dirty_data_num == 0)wlast_m_inf_data <= 1;
                else wlast_m_inf_data <= 0;
            end
            else begin
                wlast_m_inf_data <= 0;
            end
        end
        // assign wlast_m_inf_data = state == WRITE && flush_issue_cnt == dirty_data_num && wready_m_inf_data;
        assign flush_done_o = state == DONE && flush_i;
    
        // i cache
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                arvalid_m_inf_inst <= 0;
            end
            else if(state == IDLE && instr_in_valid_i && !icache_hit) begin
                arvalid_m_inf_inst <= 1;
            end
            else if(arready_m_inf_inst) begin
                arvalid_m_inf_inst <= 0;
            end
            else begin
                arvalid_m_inf_inst <= arvalid_m_inf_inst;
            end
        end
        
        endmodule
        // =====================================================================
        // mult_16bit: 2-stage pipelined 16-bit signed multiplier
        // =====================================================================
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
        // SRAM_512_16 wrapper
        // =====================================================================
        module SRAM_512_16(
            clk, addr, data_i, WEB, data_o
        );
        input         clk;
        input  [8:0]  addr;
        input  [15:0] data_i;
        input         WEB;
        output [15:0] data_o;
        
        SUMA180_512X16X1BM1 u_SRAM_512_16
        (
            .A0(addr[0]), .A1(addr[1]), .A2(addr[2]),.A3(addr[3]), .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), .A7(addr[7]), .A8(addr[8]),
            .DO0(data_o[0]),  .DO1(data_o[1]),  .DO2(data_o[2]),   .DO3(data_o[3]),   .DO4(data_o[4]),   .DO5(data_o[5]),   .DO6(data_o[6]),   .DO7(data_o[7]),  
            .DO8(data_o[8]),  .DO9(data_o[9]),  .DO10(data_o[10]), .DO11(data_o[11]), .DO12(data_o[12]), .DO13(data_o[13]), .DO14(data_o[14]), .DO15(data_o[15]),
            .DI0(data_i[0]),   .DI1(data_i[1]),   .DI2(data_i[2]),    .DI3(data_i[3]),    .DI4(data_i[4]),    .DI5(data_i[5]),    .DI6(data_i[6]),    .DI7(data_i[7]),   
            .DI8(data_i[8]),   .DI9(data_i[9]),   .DI10(data_i[10]),  .DI11(data_i[11]),  .DI12(data_i[12]),  .DI13(data_i[13]),  .DI14(data_i[14]),  .DI15(data_i[15]),   
            .CK(clk),           .WEB(WEB),   	     .OE(1'b1), 	     .CS(1'b1)
        );
        
        endmodule
    
            // module Fetch(
        //     input clk,
        //     input rst_n,
        //     input in_valid_i,
        //     input [12:0] pc_i,
        //     input current_fetch_core,
        //     output reg [15:0] instr_o,
        //     output reg        instr_valid_o,
        //     // AXI read addr 
        //     input                   arready_m_inf_inst,
        //     output reg              arvalid_m_inf_inst,
        //     output [31:0]           araddr_m_inf_inst,
        
        //     // AXI read data channel
        //     input rlast_m_inf_inst,
        //     input rvalid_m_inf_inst,
        //     input [15:0] rdata_m_inf_inst
        // );
        
        // parameter ADDR_WIDTH = 32;
        // parameter DATA_WIDTH = 16;
        
        // reg [2:0] state, next_state;
        // localparam IDLE      = 3'd0;
        // localparam READ      = 3'd1;
        // localparam READ_DONE = 3'd2;
        // localparam FETCH_DONE = 3'd3;
        // localparam DONE = 3'd4;
        
        // wire cache_hit;
        // wire [7:0] icache_addr;
        // wire [6:0] icache_addr_sel;
        // reg [6:0] icache_addr_cnt;
        // wire [15:0] icache_rdata;
        // reg         icache_web;
        // reg [15:0] icache_w_data;
        // reg [4:0] icache_tag [1:0];
        // reg       icache_data_valid [1:0];
        
        // assign cache_hit = (pc_i[12:8] == icache_tag[current_fetch_core]) && icache_data_valid[current_fetch_core];
        
        // assign araddr_m_inf_inst = {19'b0, pc_i[12:8], 8'b0};
        
        // // FSM state register
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) state <= IDLE;
        //     else  state <= next_state;
        // end
        
        // // FSM next state
        // always @(*) begin
        //     case(state)
        //         IDLE: begin
        //             if(in_valid_i) next_state = cache_hit ? READ_DONE : READ;
        //             else next_state = IDLE;
        //         end
        //         READ: begin
        //             if(rvalid_m_inf_inst && rlast_m_inf_inst) next_state = FETCH_DONE;
        //             else next_state = READ;
        //         end
        //         READ_DONE: next_state = DONE;
        //         DONE: next_state = IDLE;
        //         FETCH_DONE: next_state = IDLE;
        //         default: next_state = IDLE;
        //     endcase
        // end
        
        // // icache tag and valid
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) icache_data_valid [1:0] <= '{default :0};
        //     else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_data_valid[current_fetch_core] <= 1;
        //     else icache_data_valid[1:0] <= icache_data_valid[1:0];
        // end
        
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) icache_tag[1:0] <= '{default :0};
        //     else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_tag[current_fetch_core] <= pc_i[12:8];
        //     else icache_tag[1:0] <= icache_tag[1:0];
        // end
        
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) begin
        //         arvalid_m_inf_inst <= 0;
        //     end
        //     else if(state == IDLE && in_valid_i && !cache_hit) begin
        //         arvalid_m_inf_inst <= 1;
        //     end
        //     else if(arready_m_inf_inst) begin
        //         arvalid_m_inf_inst <= 0;
        //     end
        //     else begin
        //         arvalid_m_inf_inst <= arvalid_m_inf_inst;
        //     end
        // end
        
        // // icache write enable
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         icache_web <= 1'b1;
        //         icache_w_data <= 0;
        //     end
        //     else if (state == READ && rvalid_m_inf_inst) begin
        //         icache_web <= 1'b0;  
        //         icache_w_data <= rdata_m_inf_inst;
        //     end
        //     else begin
        //         icache_web <= 1'b1;
        //         icache_w_data <= icache_w_data;
        //     end
        // end
        
        // // icache write address counter
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         icache_addr_cnt <= 7'd0;
        //     end
        //     else if(state == IDLE) begin
        //         icache_addr_cnt <= 7'd0;
        //     end
        //     else if(!icache_web) begin
        //         icache_addr_cnt <= icache_addr_cnt + 1;
        //     end
        //     else begin
        //         icache_addr_cnt <= icache_addr_cnt;
        //     end
        // end
        // assign icache_addr_sel = state == READ || state == FETCH_DONE ? icache_addr_cnt : pc_i[7:1];
        // assign icache_addr = {current_fetch_core, icache_addr_sel};
        // // instruction output
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         instr_o       <= 0;
        //     end
        //     else begin
        //         instr_o       <= ic//############################################################################
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
    
        // =====================================================
        // AXI data channel wires: Core (Memory) -> DCCPU ports
        // Channels used inside Memory are wired through; the rest
        // keep the DCCPU default values.
        // =====================================================
        wire                  arvalid_data_c;
        wire [ADDR_WIDTH-1:0] araddr_data_c;
        wire                  awvalid_data_c;
        wire [ADDR_WIDTH-1:0] awaddr_data_c;
        wire [BURST_LEN-1:0]  awlen_data_c;
        wire [DATA_WIDTH-1:0] wdata_data_c;
        wire                  wvalid_data_c;
        wire                  wlast_data_c;
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
        assign awsize_m_inf_inst_2  = 3'b001;
        assign awburst_m_inf_inst_2 = 2'b01;
        assign awlen_m_inf_inst_2   = 0;
        assign awvalid_m_inf_inst_2 = 0;
        assign wdata_m_inf_inst_2   = 0;
        assign wlast_m_inf_inst_2   = 0;
        assign wvalid_m_inf_inst_2  = 0;
        assign bready_m_inf_inst_2  = 0;
        
        // Data write:
        //   AW/W signals that Memory actually drives -> pass-through.
        //   Unused fields keep the original DCCPU defaults.
        assign awid_m_inf_data    = 0;
        assign awaddr_m_inf_data  = awaddr_data_c;
        assign awsize_m_inf_data  = 3'b001;
        assign awburst_m_inf_data = 2'b01;
        assign awlen_m_inf_data   = awlen_data_c;
        assign awvalid_m_inf_data = awvalid_data_c;
        assign wdata_m_inf_data   = wdata_data_c;
        assign wlast_m_inf_data   = wlast_data_c;
        assign wvalid_m_inf_data  = wvalid_data_c;
        assign bready_m_inf_data  = 1;
        
        // Data read (AR / R): wire up to Core -> Memory
        assign arid_m_inf_data    = 0;
        assign arlen_m_inf_data   = 7'b1111111;
        assign arsize_m_inf_data  = 3'b001;
        assign arburst_m_inf_data = 2'b01;
        assign arvalid_m_inf_data = arvalid_data_c;
        assign araddr_m_inf_data  = araddr_data_c;
        assign rready_m_inf_data  = 1'b1;
        
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
            .rready_m_inf_inst2(rready_inst_2),
            // AXI data read (AR + R)
            .arvalid_m_inf_data(arvalid_data_c),
            .araddr_m_inf_data(araddr_data_c),
            .arready_m_inf_data(arready_m_inf_data),
            .rvalid_m_inf_data(rvalid_m_inf_data),
            .rlast_m_inf_data(rlast_m_inf_data),
            .rdata_m_inf_data(rdata_m_inf_data),
            // AXI data write (AW + W)
            .awvalid_m_inf_data(awvalid_data_c),
            .awaddr_m_inf_data(awaddr_data_c),
            .awlen_m_inf_data(awlen_data_c),
            .awready_m_inf_data(awready_m_inf_data),
            .wdata_m_inf_data(wdata_data_c),
            .wlast_m_inf_data(wlast_data_c),
            .wvalid_m_inf_data(wvalid_data_c),
            .wready_m_inf_data(wready_m_inf_data)
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
                stall_1 <= 1;
                stall_2 <= 1;
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
            output  current_core,
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
            output                  rready_m_inf_inst2,
    
            // AXI read addr channel (data)
            output                  arvalid_m_inf_data,
            output [31:0]           araddr_m_inf_data,
            input                   arready_m_inf_data,
            // AXI read data channel (data)
            input                   rlast_m_inf_data,
            input                   rvalid_m_inf_data,
            input  [15:0]           rdata_m_inf_data,
            // AXI write addr channel (data)
            output                  awvalid_m_inf_data,
            output [31:0]           awaddr_m_inf_data,
            output [6:0]            awlen_m_inf_data,
            input                   awready_m_inf_data,
            // AXI write data channel (data)
            output [15:0]           wdata_m_inf_data,
            output                   wlast_m_inf_data,
            output                   wvalid_m_inf_data,
            input                   wready_m_inf_data
        );
        // FSM
        reg [2:0] state, next_state;
        localparam IF  = 3'd0;
        localparam ID  = 3'd1;
        localparam EXE = 3'd2;
        localparam EXE2= 3'd3;
        localparam WB  = 3'd4;
        localparam MEM = 3'd5;
        localparam  FLUSH = 3'd6;
        localparam FLUSH_WB = 3'd7;
        // PC
        reg [12:0] pc;
        reg [12:0] pc_2;
        wire [12:0] pc_sel;
        wire [12:0] pc_next;
        // icache signal
        reg [15:0] if_instr_r [1:0];
        reg instr_prefetch_flag [1:0];
        wire [15:0] if_instr_sel;
        reg current_fetch_core;
        wire instr_fetch;
        // prefetch
        wire can_prefetch;
        reg start_prefetch;
        // decode
        wire [2:0] opcode;
        wire [2:0] opcode2;
        wire [2:0] alu_op;
        wire [6:0] imm;
        wire [12:0] jump_target;
        wire [2:0] rd_addr;
        wire is_R, is_mult, is_I, is_Load, is_Store, is_Branch, is_Jump, is_ADDI, is_SUBI;
        wire core1_is_Branch, core1_is_Jump;
        wire core2_is_Branch, core2_is_Jump;
        wire core1_is_Load, core1_is_Store;
        wire core2_is_Load, core2_is_Store;
        reg current_core_r;
        // exe
        wire signed [15:0] alu_a, alu_b;
        reg signed [15:0] alu_result, alu_result_r;
        wire [31:0] mult_result;
        wire branch_taken;
        // reg [31:0] mult_result_r;
        wire mult_done;
    
        wire                  fetch_arvalid;
        wire [31:0]           fetch_araddr;
        wire                  fetch_arready;
        wire                  fetch_rlast;
        wire                  fetch_rvalid;
        wire [15:0]           fetch_rdata;
        // memory
        wire change_order;
        reg change_order_r;
        // Memory module I/O
        wire [15:0] cache_data_o;
        wire        cache_data_valid_o;
        wire [12:0] mem_addr_sel;
        // flush signal
        reg [5:0] instr_counter;
        wire flush_done;
        assign arvalid_m_inf_inst   = (current_fetch_core == 1'b0) ? fetch_arvalid : 1'b0;
        assign araddr_m_inf_inst    = (current_fetch_core == 1'b0) ? fetch_araddr  : 32'b0;
        assign rready_m_inf_inst    = 1'b1;
    
        assign arvalid_m_inf_inst2  = (current_fetch_core == 1'b1) ? fetch_arvalid : 1'b0;
        assign araddr_m_inf_inst2   = (current_fetch_core == 1'b1) ? fetch_araddr  : 32'b0;
        assign rready_m_inf_inst2   = 1'b1;
    
        assign fetch_arready = (current_fetch_core == 1'b0) ? arready_m_inf_inst  : arready_m_inf_inst2;
        assign fetch_rlast   = (current_fetch_core == 1'b0) ? rlast_m_inf_inst    : rlast_m_inf_inst2;
        assign fetch_rvalid  = (current_fetch_core == 1'b0) ? rvalid_m_inf_inst   : rvalid_m_inf_inst2;
        assign fetch_rdata   = (current_fetch_core == 1'b0) ? rdata_m_inf_inst    : rdata_m_inf_inst2;
    
        // pc   
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) pc <= 0;
            else if(is_wb && !(core1_is_Branch || core1_is_Jump)) pc <= pc + 2;
            else if(state == EXE && current_core == 0 && is_Branch) pc <= branch_taken ? alu_result[12:0] : pc + 2;
            else if(state == ID && current_core == 0 && is_Jump) pc <= jump_target;
            else pc <= pc;
        end
        // pc2   
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) pc_2 <= 0;
            else if(is_wb && !(core2_is_Branch || core2_is_Jump)) pc_2 <= pc_2 + 2;
            else if(state == EXE && current_core == 1 && is_Branch) pc_2 <= branch_taken ? alu_result[12:0] : pc_2 + 2;
            else if(state == ID && current_core == 1 && is_Jump) pc_2 <= jump_target;
            else pc_2 <= pc_2;
        end
        assign pc_sel = current_core == 0 ? pc : pc_2;
        assign pc_next = pc_sel + 2;
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                instr_prefetch_flag <= '{default: 0};
            end
            else if(state == IF) begin
                instr_prefetch_flag[current_fetch_core] <= 0;
            end
            else if(start_prefetch && cache_data_valid_o) begin
                instr_prefetch_flag[current_fetch_core] <= 1;
            end
            else begin
                instr_prefetch_flag[1:0] <= instr_prefetch_flag[1:0];
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                if_instr_r <= '{default: 0};
            end
            else if(instr_fetch && cache_data_valid_o) begin
                if_instr_r[current_fetch_core] <= cache_data_o;
            end
            else begin
                if_instr_r[1:0] <= if_instr_r[1:0];
            end
        end
        
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) current_core_r <= 0;
            else if(change_order) current_core_r <= 1;
            else if(state == WB) begin
                if(change_order_r && current_core_r == 0) current_core_r <= 0;
                else current_core_r <= ~current_core_r;
            end
            else current_core_r <= current_core_r;
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) current_fetch_core <= 0;
            else if(instr_fetch && cache_data_valid_o) current_fetch_core <= ~current_fetch_core;
            else current_fetch_core <= current_fetch_core;
        end
        // flush
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                instr_counter <= 0;
            end
            else if(is_wb) begin
                instr_counter <= instr_counter == 49 ? 0 : instr_counter + 1;
            end
            else begin
                instr_counter <= instr_counter;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) state <= IF;
            else  state <= next_state;
        end
        
        always @(*) begin
            case(state)
                IF: begin
                    if(((cache_data_valid_o || instr_prefetch_flag[1]) && current_fetch_core == 1)) next_state = ID;
                    else next_state = IF;
                end
                ID: begin
                    if(is_Jump) next_state = WB;
                    else 
                    next_state = EXE;
                end
                EXE: begin
                    if(is_Branch && branch_taken) next_state = WB;
                    else if(is_mult) next_state = EXE2;
                    else if(is_Load | is_Store) next_state = MEM;
                    else  next_state = WB;
                end
                EXE2: begin
                    next_state =mult_done ?  WB : EXE2;
                end
                MEM: begin
                    next_state = cache_data_valid_o ? WB : MEM;
                end
                WB: begin
                    if((change_order_r == 0 && current_core_r == 0) || (change_order_r == 1 && current_core_r == 1)) next_state = ID;
                    else if(instr_counter == 49 || (pc == 13'h1FFE && pc_2 == 13'h1FFE))next_state = FLUSH;
                    else next_state = IF;
                end 
                FLUSH:begin
                    if(flush_done) next_state = FLUSH_WB;
                    else next_state = FLUSH;
                end
                FLUSH_WB :begin
                    next_state = IF;
                end
                default: next_state = IF;
            endcase
        end
        
        assign is_wb = (state == WB && ((change_order_r == 0 && current_core_r == 1) || (change_order_r == 1 && current_core_r == 0)) && instr_counter != 49 && ((pc != 13'h1FFE && pc_2 != 13'h1FFE))) || state == FLUSH_WB ? 1 : 0;
        
        assign rf_write     = state == WB && ~is_Store && ~is_Branch && ~is_Jump ? 1 : 0;
        assign rf_rl_write  = state == WB && is_mult ? 1 : 0;
        assign rf_wdata     = is_mult ? mult_result[31:16] : is_Load ? cache_data_o : alu_result_r;
        assign rf_rl_wdata  = mult_result[15:0];
        assign mem_addr_sel = state == MEM ? {alu_result_r[11:0], 1'b0} : (start_prefetch || can_prefetch) ? current_fetch_core == 1 ? pc_2 + 2 : pc +2 : 
                                                                            : current_fetch_core == 1 ? pc_2 : pc;
        assign instr_fetch = state == IF || start_prefetch || can_prefetch;
        Memory memory(
            .clk(clk),
            .rst_n(rst_n),
            .instr_in_valid_i(instr_fetch), 
            .current_fetch_core(current_fetch_core),
            .data_in_valid_i(state == MEM),
            .addr_i(mem_addr_sel),
            .wdata_i(rt_data),
            .is_Store(is_Store),
            .data_o(cache_data_o),
            .data_valid_o(cache_data_valid_o),
            .flush_i(state == FLUSH ? 1'b1 : 1'b0),
            .flush_done_o(flush_done),
            // AXI read addr 
            .arready_m_inf_inst(fetch_arready),
            .arvalid_m_inf_inst(fetch_arvalid),
            .araddr_m_inf_inst(fetch_araddr),
            // AXI read data channel
            .rlast_m_inf_inst(fetch_rlast),
            .rvalid_m_inf_inst(fetch_rvalid),
            .rdata_m_inf_inst(fetch_rdata),
            // AXI read addr (data)
            .arready_m_inf_data(arready_m_inf_data),
            .arvalid_m_inf_data(arvalid_m_inf_data),
            .araddr_m_inf_data(araddr_m_inf_data),
            // AXI read data (data)
            .rlast_m_inf_data(rlast_m_inf_data),
            .rvalid_m_inf_data(rvalid_m_inf_data),
            .rdata_m_inf_data(rdata_m_inf_data),
            // AXI write addr (data)
            .awvalid_m_inf_data(awvalid_m_inf_data),
            .awaddr_m_inf_data(awaddr_m_inf_data),
            .awlen_m_inf_data(awlen_m_inf_data),
            .awready_m_inf_data(awready_m_inf_data),
            // AXI write data (data)
            .wdata_m_inf_data(wdata_m_inf_data),
            .wlast_m_inf_data(wlast_m_inf_data),
            .wvalid_m_inf_data(wvalid_m_inf_data),
            .wready_m_inf_data(wready_m_inf_data)
        );
        // decode
        assign if_instr_sel = change_order ? if_instr_r[1] : 
                                current_core ? if_instr_r[1] : if_instr_r[0];
        assign opcode      = if_instr_sel[15:13];
        assign opcode2     = if_instr_r[1][15:13];
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
        assign core1_is_Branch = if_instr_r[0][15:13] == 3'b110;
        assign core1_is_Jump   = if_instr_r[0][15:13] == 3'b111;
        assign core2_is_Branch = opcode2 == 3'b110;
        assign core2_is_Jump   = opcode2 == 3'b111;
        assign is_Branch   = current_core ? core2_is_Branch : core1_is_Branch;
        assign is_Jump     = current_core ? core2_is_Jump : core1_is_Jump;
        assign core1_is_Load = if_instr_r[0][15:13] == 3'b100;
        assign core1_is_Store = if_instr_r[0][15:13] == 3'b101;
        assign core2_is_Load = opcode2 == 3'b100;
        assign core2_is_Store = opcode2 == 3'b101;
        always @(*) begin
            dec_wb_addr_r    = is_R | is_mult ? rd_addr : rt_addr;
        end
        assign current_core = change_order ? 1'b1 : current_core_r;
        assign change_order = state == ID && current_core_r == 0 && core1_is_Load && core2_is_Store && change_order_r == 0;
    
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) change_order_r <= 0;
            else if(change_order)change_order_r <= 1;
            else if(state == WB && current_core_r == 0) change_order_r <= 0;
            else change_order_r <= change_order_r;
        end
    
        // prefetch
        assign can_prefetch = state == ID && (is_R || is_mult || is_I);
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) start_prefetch <= 0;
            else if(can_prefetch)start_prefetch <= 1;
            else if(data_valid_o) start_prefetch <= 0;
            else start_prefetch <= start_prefetch;
        end
        // exe
        assign alu_a = is_Branch ? pc_next : rs_data;
        assign alu_b = is_R ? rt_data :  {{9{imm[6]}}, imm};
        assign branch_taken = rs_data == rt_data;
        // FIX: corrected illegal case item syntax (e.g. "3'b001:3'b111:" -> separate items)
        always @(*) begin
            if(is_ADDI || is_Load || is_Store || is_Branch) alu_result = alu_a + alu_b;
            else if(is_SUBI) alu_result = alu_a - alu_b;
            else begin
                case(alu_op)
                    3'b000: alu_result = alu_a + alu_b;
                    3'b001: alu_result = alu_a - alu_b;
                    3'b111: alu_result = alu_a < alu_b ? 1 : 0;
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
                if(is_ADDI || is_SUBI || is_Load || is_Store) alu_result_r <= alu_result;
                else begin
                    if(alu_op == 3'b100 || alu_op == 3'b101) alu_result_r <= ~alu_result;
                    else alu_result_r <= alu_result;
                end
            end
        end
        
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) mult_result_r <= 0;
        //     else mult_result_r <= mult_result;
        // end
        
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
        
        module Memory(
            input clk,
            input rst_n,
            input instr_in_valid_i,
            input current_fetch_core,
            input data_in_valid_i,
            input [12:0] addr_i,
            input [15:0] wdata_i,
            input is_Store,
            output reg [15:0] data_o,
            output reg        data_valid_o,
            input flush_i,
            output reg flush_done_o,
            // AXI read addr 
            input                   arready_m_inf_inst,
            output reg              arvalid_m_inf_inst,
            output [31:0]           araddr_m_inf_inst,
        
            // AXI read data channel
            input rlast_m_inf_inst,
            input rvalid_m_inf_inst,
            input [15:0] rdata_m_inf_inst,
            // AXI read addr 
            input                   arready_m_inf_data,
            output reg              arvalid_m_inf_data,
            output [31:0]           araddr_m_inf_data,
        
            // AXI read data channel
            input rlast_m_inf_data,
            input rvalid_m_inf_data,
            input [15:0] rdata_m_inf_data,
    
            // AXI write addr channel
            input                   awready_m_inf_data,
            output reg              awvalid_m_inf_data,
            output [31:0]           awaddr_m_inf_data,
            output reg [6:0]            awlen_m_inf_data,
    
            // AXI write data channel
            input                   wready_m_inf_data,
            output   reg           wlast_m_inf_data,
            output               wvalid_m_inf_data,
            output   [15:0]      wdata_m_inf_data
        );
        
        parameter ADDR_WIDTH = 32;
        parameter DATA_WIDTH = 16;
        
        reg [2:0] state, next_state;
        localparam IDLE      = 3'd0;
        localparam READ      = 3'd1;
        localparam READ_DONE = 3'd2;
        localparam FETCH_DONE = 3'd3;
        localparam DONE = 3'd4;
        localparam WRITE = 3'd5;
        localparam ISSUE_WRITE = 3'd6;
        localparam GET_CACHE_DATA = 3'd7;
        wire cache_hit;
        wire [8:0] dcache_addr;
        wire [6:0] dcache_addr_sel;
        reg [6:0] dcache_addr_cnt;
        wire [15:0] dcache_rdata;
        reg         dcache_web;
        reg [15:0] dcache_w_data;
        reg [3:0] dcache_tag [1:0];
        reg dcache_dirty [1:0];
        reg       dcache_data_valid [1:0];
        wire cache_idx;
        wire [3:0] cache_tag;
        wire [6:0] cache_offset;
        wire [1:0] plus_dram_addr_offest;
    
        reg [6:0] dcache_dirty_start_addr [1:0];
        reg [6:0] dcache_dirty_end_addr [1:0];
        reg [6:0] dirty_data_num;
        wire [1:0] victim_plus_dram_addr_offest;
        wire flush_entry;
        wire [1:0] need_flush_num;
        reg [1:0] need_flush_num_r;
        reg [1:0] flush_cnt;
        reg [1:0] flush_read_cache_cnt;
        reg [6:0] flush_issue_cnt;
        wire entry_sel;
        reg [15:0] cache_data_buffer [1:0];
    
        // icache
        wire icache_hit;
        reg [4:0] icache_tag[1:0];
        reg       icache_data_valid [1:0];
        wire [6:0] icache_addr_sel;
        reg [6:0] icache_addr_cnt;
        // icache
        assign icache_hit = (addr_i[12:8] == icache_tag[current_fetch_core]) && icache_data_valid[current_fetch_core];
        assign araddr_m_inf_inst = {19'b0, addr_i[12:8], 8'b0};
        // icache tag and valid
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) icache_data_valid [1:0] <= '{default :0};
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_data_valid[current_fetch_core] <= 1;
            else icache_data_valid[1:0] <= icache_data_valid[1:0];
        end
        
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) icache_tag[1:0] <= '{default :0};
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_tag[current_fetch_core] <= addr_i[12:8];
            else icache_tag[1:0] <= icache_tag[1:0];
        end
    
        assign cache_idx = addr_i[8];
        assign cache_tag = addr_i[12:9];
        assign cache_offset = addr_i[7:1];
        assign cache_hit = (cache_tag == dcache_tag[cache_idx]) && dcache_data_valid[cache_idx];
        
        //assign plus_dram_addr_offest = addr_i[12] ? 2'b10 : 2'b01;
        assign plus_dram_addr_offest = {addr_i[12], ~addr_i[12]};
        // araddr: fetch the 256-byte page containing addr_i
        assign araddr_m_inf_data = {18'b0, plus_dram_addr_offest,addr_i[11:8], 8'b0};
        
        // FSM state register
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) state <= IDLE;
            else  state <= next_state;
        end
        
        // FSM next state
        always @(*) begin
            case(state)
                IDLE: begin
                    if(flush_i) begin
                        if(need_flush_num == 0) next_state = DONE;
                        else next_state = ISSUE_WRITE;
                    end
                    else if(data_in_valid_i) next_state = cache_hit ? READ_DONE : 
                                dcache_dirty[cache_idx] ? ISSUE_WRITE : READ;
                    else if(instr_in_valid_i) next_state = icache_hit ? READ_DONE : READ;
                    else next_state = IDLE;
                end
                WRITE: begin
                    if(wlast_m_inf_data && wready_m_inf_data)begin 
                        if(flush_i) begin
                            if(need_flush_num_r == flush_cnt + 1) next_state = DONE;
                            else next_state = ISSUE_WRITE;
                        end
                        else next_state = READ;
                    end
                    else next_state = WRITE;
                end
                READ: begin
                    if(rvalid_m_inf_data && rlast_m_inf_data) next_state = FETCH_DONE;
                    else if(rvalid_m_inf_inst && rlast_m_inf_inst) next_state = FETCH_DONE;
                    else next_state = READ;
                end
                ISSUE_WRITE:begin
                    if(awready_m_inf_data) next_state = GET_CACHE_DATA;
                    else next_state = ISSUE_WRITE;
                end
                GET_CACHE_DATA:begin
                    if(flush_read_cache_cnt == 3) next_state = WRITE;
                    else next_state = GET_CACHE_DATA;
                end
                READ_DONE: next_state = DONE;
                DONE: next_state = IDLE;
                FETCH_DONE: next_state = IDLE;
                default: next_state = IDLE;
            endcase
        end
        
        // dcache tag and valid
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) dcache_data_valid[1:0] <= '{default : 0};
            else if(state == READ && rvalid_m_inf_data && rlast_m_inf_data) dcache_data_valid[cache_idx] <= 1;
            else dcache_data_valid[1:0] <= dcache_data_valid[1:0];
        end
    
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                dcache_dirty[1:0] <= '{default : 0};
    
                dcache_dirty_start_addr[0] <= 127;
                dcache_dirty_start_addr[1] <= 127;
                dcache_dirty_end_addr[0] <= 0;
                dcache_dirty_end_addr[1] <= 0;
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i) begin
                dcache_dirty[cache_idx] <= 1;
    
                if(cache_offset > dcache_dirty_end_addr[cache_idx]) 
                    dcache_dirty_end_addr[cache_idx] <= cache_offset;
                if(cache_offset < dcache_dirty_start_addr[cache_idx]) 
                    dcache_dirty_start_addr[cache_idx] <= cache_offset;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data) begin
                dcache_dirty[entry_sel] <= 0;
    
                dcache_dirty_start_addr[entry_sel] <= 127;
                dcache_dirty_end_addr[entry_sel] <= 0;
            end
            else begin
                dcache_dirty[1:0] <= dcache_dirty[1:0];
    
                dcache_dirty_start_addr[1:0] <= dcache_dirty_start_addr[1:0];
                dcache_dirty_end_addr[1:0] <= dcache_dirty_end_addr[1:0];
            end
        end
        assign entry_sel = flush_i ? flush_entry : cache_idx;
        assign dirty_data_num = dcache_dirty_end_addr[entry_sel] - dcache_dirty_start_addr[entry_sel];
    
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) dcache_tag[1:0] <= '{default : 0};
            else if(state == READ && rvalid_m_inf_data && rlast_m_inf_data) dcache_tag[cache_idx]  <= addr_i[12:9];
            else dcache_tag[1:0] <= dcache_tag[1:0];
        end
        
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                arvalid_m_inf_data <= 0;
            end
            else if(state != READ && next_state == READ && data_in_valid_i) begin
                arvalid_m_inf_data <= 1;
            end
    
            else if(arready_m_inf_data) begin
                arvalid_m_inf_data <= 0;
            end
            else begin
                arvalid_m_inf_data <= arvalid_m_inf_data;
            end
        end
        // aw addr
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                awvalid_m_inf_data <= 0;
            end
            else if(state == IDLE && data_in_valid_i && ~cache_hit && dcache_dirty[cache_idx]) begin
                awvalid_m_inf_data <= 1;
            end
            else if(state == ISSUE_WRITE) begin
                if(awready_m_inf_data) awvalid_m_inf_data <= 0;
                else awvalid_m_inf_data <= 1;
            end
            else begin
                awvalid_m_inf_data <= awvalid_m_inf_data;
            end
        end
    
        // dcache write enable
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dcache_web <= 1'b1;
                dcache_w_data <= 0;
            end
            else if (state == READ && rvalid_m_inf_data) begin
                dcache_web <= 1'b0;  // write when data is valid
                dcache_w_data <= rdata_m_inf_data;
            end
            else if (state == READ && rvalid_m_inf_inst) begin
                dcache_web <= 1'b0;  
                dcache_w_data <= rdata_m_inf_inst;
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i) begin
                dcache_web <= 1'b0;
                dcache_w_data <= wdata_i;
            end
            else begin
                dcache_web <= 1'b1;
                dcache_w_data <= dcache_w_data;
            end
        end
        
        // dcache write address counter
        // FIX: original incremented on dcache_web (high=read), should increment when writing (!dcache_web)
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                dcache_addr_cnt <= 7'd0;
            end
            else if(state  == ISSUE_WRITE) begin
                dcache_addr_cnt <= dcache_dirty_start_addr[entry_sel];
            end
            else if(state != READ && next_state == READ) begin
                dcache_addr_cnt <= 7'd0;
            end
            else if(state == GET_CACHE_DATA) begin
                if(flush_read_cache_cnt >= 2) dcache_addr_cnt <= dcache_addr_cnt;
                else dcache_addr_cnt <= dcache_addr_cnt + 1;
            end
            else if(state == WRITE) begin
                if(wready_m_inf_data) dcache_addr_cnt <= dcache_addr_cnt + 1;
                else dcache_addr_cnt <= dcache_addr_cnt;
            end
            else if(!dcache_web) begin
                // Advance after each write beat
                dcache_addr_cnt <= dcache_addr_cnt + 1;
            end
            else begin
                dcache_addr_cnt <= dcache_addr_cnt;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                icache_addr_cnt <= 7'd0;
            end
            else if(state == IDLE) begin
                icache_addr_cnt <= 7'd0;
            end
            else if(!dcache_web) begin
                icache_addr_cnt <= icache_addr_cnt + 1;
            end
            else begin
                icache_addr_cnt <= icache_addr_cnt;
            end
        end
        assign icache_addr_sel = state == READ || state == FETCH_DONE ? icache_addr_cnt : addr_i[7:1];
        assign dcache_addr_sel = state == READ || state == FETCH_DONE || state == ISSUE_WRITE || state == GET_CACHE_DATA || state == WRITE ? dcache_addr_cnt : cache_offset;
        assign dcache_addr = instr_in_valid_i ? {1'b0, current_fetch_core, icache_addr_sel} : {1'b1, entry_sel, dcache_addr_sel};
        // instruction output
            always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                data_o       <= 0;
            end
            else begin
                data_o       <= dcache_rdata;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                data_valid_o <= 0;
            end
            // Hit from cache: read from SRAM
            else if(state == READ_DONE) begin
                data_valid_o <= 1;
            end
            else begin
                data_valid_o <= 0;
            end
        end
        
        SRAM_512_16 dcache(
            .clk(clk),
            .addr(dcache_addr),
            .data_i(dcache_w_data),
            .WEB(dcache_web),
            .data_o(dcache_rdata)
        );
        // write back to memory
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_cnt <= 0;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data) begin
                flush_cnt <= flush_cnt + 1;
            end
            else if(state == DONE)begin
                flush_cnt <= 0;
            end
            else begin
                flush_cnt <= flush_cnt;
            end
        end
    
        assign flush_entry = dcache_dirty[0] && flush_cnt == 0 ? 0 : 1;
        assign need_flush_num = dcache_dirty[0] + dcache_dirty[1];
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                need_flush_num_r <= 0;
            end
            else if(state == IDLE) begin
                need_flush_num_r <= need_flush_num;
            end
            else begin
                need_flush_num_r <= need_flush_num_r;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_read_cache_cnt <= 0;
            end
            else if(state == GET_CACHE_DATA) begin
                flush_read_cache_cnt <= flush_read_cache_cnt == 3 ? 3 : flush_read_cache_cnt + 1;
            end
            else begin
                flush_read_cache_cnt <= 0;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_issue_cnt <= 0;
            end
            else if(state == WRITE) begin
                if(wready_m_inf_data) flush_issue_cnt <= flush_issue_cnt + 1;
                else flush_issue_cnt <= flush_issue_cnt;
            end
            else begin
                flush_issue_cnt <= 0;
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                cache_data_buffer <= '{default:0};
            end
            else if(state == GET_CACHE_DATA && flush_read_cache_cnt <= 3) begin
                cache_data_buffer[1] <= data_o;
                cache_data_buffer[0] <= cache_data_buffer[1];
            end
            else if(state == WRITE && wready_m_inf_data)begin
                cache_data_buffer[1] <= 0;
                cache_data_buffer[0] <= cache_data_buffer[1];
            end
        end
        //assign victim_plus_dram_addr_offest = dcache_tag[entry_sel][3] ? 2'b10 : 2'b01;
        assign victim_plus_dram_addr_offest = {dcache_tag[entry_sel][3], ~dcache_tag[entry_sel][3]};
        // araddr: fetch the 256-byte page containing addr_i
        assign awaddr_m_inf_data = {18'b0, victim_plus_dram_addr_offest,dcache_tag[entry_sel][2:0],entry_sel, dcache_dirty_start_addr[entry_sel], 1'b0};
        // assign awlen_m_inf_data = dirty_data_num;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                awlen_m_inf_data <= 0;
            end
            else begin
                awlen_m_inf_data <= dirty_data_num;
            end
        end
        assign wdata_m_inf_data = flush_issue_cnt <= 1 ? cache_data_buffer[0] : data_o;
        assign wvalid_m_inf_data = state == WRITE;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                wlast_m_inf_data <= 0;
            end
            else if(state == WRITE) begin
                if(flush_issue_cnt + 1 == dirty_data_num && wready_m_inf_data) wlast_m_inf_data <= 1;
                else if(dirty_data_num == 0)wlast_m_inf_data <= 1;
                else wlast_m_inf_data <= 0;
            end
            else begin
                wlast_m_inf_data <= 0;
            end
        end
        // assign wlast_m_inf_data = state == WRITE && flush_issue_cnt == dirty_data_num && wready_m_inf_data;
        assign flush_done_o = state == DONE && flush_i;
    
        // i cache
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                arvalid_m_inf_inst <= 0;
            end
            else if(state == IDLE && instr_in_valid_i && !icache_hit) begin
                arvalid_m_inf_inst <= 1;
            end
            else if(arready_m_inf_inst) begin
                arvalid_m_inf_inst <= 0;
            end
            else begin
                arvalid_m_inf_inst <= arvalid_m_inf_inst;
            end
        end
        
        endmodule
        // =====================================================================
        // mult_16bit: 2-stage pipelined 16-bit signed multiplier
        // =====================================================================
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
        // SRAM_512_16 wrapper
        // =====================================================================
        module SRAM_512_16(
            clk, addr, data_i, WEB, data_o
        );
        input         clk;
        input  [8:0]  addr;
        input  [15:0] data_i;
        input         WEB;
        output [15:0] data_o;
        
        SUMA180_512X16X1BM1 u_SRAM_512_16
        (
            .A0(addr[0]), .A1(addr[1]), .A2(addr[2]),.A3(addr[3]), .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), .A7(addr[7]), .A8(addr[8]),
            .DO0(data_o[0]),  .DO1(data_o[1]),  .DO2(data_o[2]),   .DO3(data_o[3]),   .DO4(data_o[4]),   .DO5(data_o[5]),   .DO6(data_o[6]),   .DO7(data_o[7]),  
            .DO8(data_o[8]),  .DO9(data_o[9]),  .DO10(data_o[10]), .DO11(data_o[11]), .DO12(data_o[12]), .DO13(data_o[13]), .DO14(data_o[14]), .DO15(data_o[15]),
            .DI0(data_i[0]),   .DI1(data_i[1]),   .DI2(data_i[2]),    .DI3(data_i[3]),    .DI4(data_i[4]),    .DI5(data_i[5]),    .DI6(data_i[6]),    .DI7(data_i[7]),   
            .DI8(data_i[8]),   .DI9(data_i[9]),   .DI10(data_i[10]),  .DI11(data_i[11]),  .DI12(data_i[12]),  .DI13(data_i[13]),  .DI14(data_i[14]),  .DI15(data_i[15]),   
            .CK(clk),           .WEB(WEB),   	     .OE(1'b1), 	     .CS(1'b1)
        );
        
        endmodule
    
            // module Fetch(
        //     input clk,
        //     input rst_n,
        //     input in_valid_i,
        //     input [12:0] pc_i,
        //     input current_fetch_core,
        //     output reg [15:0] instr_o,
        //     output reg        instr_valid_o,
        //     // AXI read addr 
        //     input                   arready_m_inf_inst,
        //     output reg              arvalid_m_inf_inst,
        //     output [31:0]           araddr_m_inf_inst,
        
        //     // AXI read data channel
        //     input rlast_m_inf_inst,
        //     input rvalid_m_inf_inst,
        //     input [15:0] rdata_m_inf_inst
        // );
        
        // parameter ADDR_WIDTH = 32;
        // parameter DATA_WIDTH = 16;
        
        // reg [2:0] state, next_state;
        // localparam IDLE      = 3'd0;
        // localparam READ      = 3'd1;
        // localparam READ_DONE = 3'd2;
        // localparam FETCH_DONE = 3'd3;
        // localparam DONE = 3'd4;
        
        // wire cache_hit;
        // wire [7:0] icache_addr;
        // wire [6:0] icache_addr_sel;
        // reg [6:0] icache_addr_cnt;
        // wire [15:0] icache_rdata;
        // reg         icache_web;
        // reg [15:0] icache_w_data;
        // reg [4:0] icache_tag [1:0];
        // reg       icache_data_valid [1:0];
        
        // assign cache_hit = (pc_i[12:8] == icache_tag[current_fetch_core]) && icache_data_valid[current_fetch_core];
        
        // assign araddr_m_inf_inst = {19'b0, pc_i[12:8], 8'b0};
        
        // // FSM state register
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) state <= IDLE;
        //     else  state <= next_state;
        // end
        
        // // FSM next state
        // always @(*) begin
        //     case(state)
        //         IDLE: begin
        //             if(in_valid_i) next_state = cache_hit ? READ_DONE : READ;
        //             else next_state = IDLE;
        //         end
        //         READ: begin
        //             if(rvalid_m_inf_inst && rlast_m_inf_inst) next_state = FETCH_DONE;
        //             else next_state = READ;
        //         end
        //         READ_DONE: next_state = DONE;
        //         DONE: next_state = IDLE;
        //         FETCH_DONE: next_state = IDLE;
        //         default: next_state = IDLE;
        //     endcase
        // end
        
        // // icache tag and valid
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) icache_data_valid [1:0] <= '{default :0};
        //     else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_data_valid[current_fetch_core] <= 1;
        //     else icache_data_valid[1:0] <= icache_data_valid[1:0];
        // end
        
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) icache_tag[1:0] <= '{default :0};
        //     else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) icache_tag[current_fetch_core] <= pc_i[12:8];
        //     else icache_tag[1:0] <= icache_tag[1:0];
        // end
        
        // always @(posedge clk or negedge rst_n) begin
        //     if(!rst_n) begin
        //         arvalid_m_inf_inst <= 0;
        //     end
        //     else if(state == IDLE && in_valid_i && !cache_hit) begin
        //         arvalid_m_inf_inst <= 1;
        //     end
        //     else if(arready_m_inf_inst) begin
        //         arvalid_m_inf_inst <= 0;
        //     end
        //     else begin
        //         arvalid_m_inf_inst <= arvalid_m_inf_inst;
        //     end
        // end
        
        // // icache write enable
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         icache_web <= 1'b1;
        //         icache_w_data <= 0;
        //     end
        //     else if (state == READ && rvalid_m_inf_inst) begin
        //         icache_web <= 1'b0;  
        //         icache_w_data <= rdata_m_inf_inst;
        //     end
        //     else begin
        //         icache_web <= 1'b1;
        //         icache_w_data <= icache_w_data;
        //     end
        // end
        
        // // icache write address counter
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         icache_addr_cnt <= 7'd0;
        //     end
        //     else if(state == IDLE) begin
        //         icache_addr_cnt <= 7'd0;
        //     end
        //     else if(!icache_web) begin
        //         icache_addr_cnt <= icache_addr_cnt + 1;
        //     end
        //     else begin
        //         icache_addr_cnt <= icache_addr_cnt;
        //     end
        // end
        // assign icache_addr_sel = state == READ || state == FETCH_DONE ? icache_addr_cnt : pc_i[7:1];
        // assign icache_addr = {current_fetch_core, icache_addr_sel};
        // // instruction output
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         instr_o       <= 0;
        //     end
        //     else begin
        //         instr_o       <= icache_rdata;
        //     end
        // end
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         instr_valid_o <= 0;
        //     end
        //     else if(state == READ_DONE) begin
        //         instr_valid_o <= 1;
        //     end
        //     else begin
        //         instr_valid_o <= 0;
        //     end
        // end
        
        // SRAM_256_16 icache(
        //     .clk(clk),
        //     .addr(icache_addr),
        //     .data_i(icache_w_data),
        //     .WEB(icache_web),
        //     .data_o(icache_rdata)
        // );
        
        // endmoduleache_rdata;
        //     end
        // end
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         instr_valid_o <= 0;
        //     end
        //     else if(state == READ_DONE) begin
        //         instr_valid_o <= 1;
        //     end
        //     else begin
        //         instr_valid_o <= 0;
        //     end
        // end
        
        // SRAM_256_16 icache(
        //     .clk(clk),
        //     .addr(icache_addr),
        //     .data_i(icache_w_data),
        //     .WEB(icache_web),
        //     .data_o(icache_rdata)
        // );
        
        // endmodule