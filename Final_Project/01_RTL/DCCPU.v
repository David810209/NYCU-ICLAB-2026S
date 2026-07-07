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
//latency: 45307
// area 576109.654
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
    
        // awid_m_inf_inst_1,
        // awaddr_m_inf_inst_1,
        // awsize_m_inf_inst_1,
        // awburst_m_inf_inst_1,
        // awlen_m_inf_inst_1,
        // awvalid_m_inf_inst_1,
        // awready_m_inf_inst_1,
                    
        // wdata_m_inf_inst_1,
        // wlast_m_inf_inst_1,
        // wvalid_m_inf_inst_1,
        // wready_m_inf_inst_1,
    
        // bid_m_inf_inst_1,
        // bresp_m_inf_inst_1,
        // bvalid_m_inf_inst_1,
        // bready_m_inf_inst_1,
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
    
        // awid_m_inf_inst_2,
        // awaddr_m_inf_inst_2,
        // awsize_m_inf_inst_2,
        // awburst_m_inf_inst_2,
        // awlen_m_inf_inst_2,
        // awvalid_m_inf_inst_2,
        // awready_m_inf_inst_2,
                    
        // wdata_m_inf_inst_2,
        // wlast_m_inf_inst_2,
        // wvalid_m_inf_inst_2,
        // wready_m_inf_inst_2,
    
        // bid_m_inf_inst_2,
        // bresp_m_inf_inst_2,
        // bvalid_m_inf_inst_2,
        // bready_m_inf_inst_2,  
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
    // // axi write addr channel 
    // // src master
    // output wire [ID_WIDTH-1:0]   awid_m_inf_inst_1; 
    // output wire [ADDR_WIDTH-1:0] awaddr_m_inf_inst_1;
    // output wire [2:0]            awsize_m_inf_inst_1; 
    // output wire [1:0]            awburst_m_inf_inst_1; 
    // output wire [BURST_LEN-1:0]  awlen_m_inf_inst_1;
    // output wire                  awvalid_m_inf_inst_1;
    // // src slave
    // input wire                   awready_m_inf_inst_1;
    // // -------------------------
    
    // // axi write data channel 
    // // src master
    // output wire [DATA_WIDTH-1:0] wdata_m_inf_inst_1;
    // output wire                  wlast_m_inf_inst_1;
    // output wire                  wvalid_m_inf_inst_1;
    // // src slave
    // input wire                   wready_m_inf_inst_1;
    
    // // axi write resp channel 
    // // src slave
    // input wire  [ID_WIDTH-1:0] bid_m_inf_inst_1; 
    // input wire  [1:0]          bresp_m_inf_inst_1; 
    // input wire                 bvalid_m_inf_inst_1;
    // // src master 
    // output wire                bready_m_inf_inst_1;
    // // ------------------------
    
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
    // // axi write addr channel 
    // // src master
    // output wire [ID_WIDTH-1:0]   awid_m_inf_inst_2; 
    // output wire [ADDR_WIDTH-1:0] awaddr_m_inf_inst_2;
    // output wire [2:0]            awsize_m_inf_inst_2; 
    // output wire [1:0]            awburst_m_inf_inst_2; 
    // output wire [BURST_LEN-1:0]  awlen_m_inf_inst_2;
    // output wire                  awvalid_m_inf_inst_2;
    // // src slave
    // input wire                   awready_m_inf_inst_2;
    // // -------------------------
    
    // // axi write data channel 
    // // src master
    // output wire [DATA_WIDTH-1:0] wdata_m_inf_inst_2;
    // output wire                  wlast_m_inf_inst_2;
    // output wire                  wvalid_m_inf_inst_2;
    // // src slave
    // input wire                   wready_m_inf_inst_2;
    
    // // axi write resp channel 
    // // src slave
    // input wire  [ID_WIDTH-1:0] bid_m_inf_inst_2; 
    // input wire  [1:0]          bresp_m_inf_inst_2; 
    // input wire                 bvalid_m_inf_inst_2;
    // // src master 
    // output wire                bready_m_inf_inst_2;
    // // ------------------------
    
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
        wire rf_read_en;
        reg [15:0] dec_rs_data;
        reg [15:0] dec_rt_data;
        wire is_wb;
        wire [7:0] dec_wb_addr_r;
        wire [7:0] rl_addr;
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
        assign arlen_m_inf_inst_1   = 7'b0111111;
        assign arsize_m_inf_inst_1  = 3'b001;
        assign arburst_m_inf_inst_1 = 2'b01;
        
        assign arid_m_inf_inst_2    = 0;
        assign arlen_m_inf_inst_2   = 7'b0111111;
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
            .rf_read_en(rf_read_en),
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
        // =====================================================================
        // Register File with per-register clock gating (AND-gating)
        // =====================================================================

        // core_1 enable signals
        wire en_c1 = (current_core == 0);
        wire en_c1_rf [7:0];
        wire en_c1_rl [7:0];
        genvar i;
        generate
            for (i = 0; i < 8; i = i + 1) begin : CG_EN_C1
                assign en_c1_rf[i] = en_c1 & rf_write    & dec_wb_addr_r[i];
                assign en_c1_rl[i] = en_c1 & rf_rl_write & (rl_addr[i]);
            end
        endgenerate

        // core_2 enable signals
        wire en_c2 = (current_core == 1);
        wire en_c2_rf [7:0];
        wire en_c2_rl [7:0];
        generate
            for (i = 0; i < 8; i = i + 1) begin : CG_EN_C2
                assign en_c2_rf[i] = en_c2 & rf_write    & (dec_wb_addr_r[i]);
                assign en_c2_rl[i] = en_c2 & rf_rl_write & (rl_addr[i]);
            end
        endgenerate

        // Gated clocks (AND-gating)
        wire gclk_c1 [7:0];
        wire gclk_c2 [7:0];
        wire gclk_c1_en [7:0];
        wire gclk_c2_en [7:0];
        generate
            for (i = 0; i < 8; i = i + 1) begin : GCLK_GEN
                assign gclk_c1_en[i] = en_c1_rf[i] | en_c1_rl[i];
                assign gclk_c2_en[i] = en_c2_rf[i] | en_c2_rl[i];
                assign gclk_c1[i] = clk & gclk_c1_en[i];
                assign gclk_c2[i] = clk & gclk_c2_en[i];
                // assign gclk_c1[i] = clk;
                // assign gclk_c2[i] = clk;
            end
        endgenerate

        // ----- core_1 -----
        always @(posedge gclk_c1[0] or negedge rst_n) begin
            if (!rst_n) core_1_r0 <= 16'd0;
            else if (dec_wb_addr_r[0]) core_1_r0 <= rf_wdata;
            else if (rl_addr[0]) core_1_r0 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[1] or negedge rst_n) begin
            if (!rst_n) core_1_r1 <= 16'd0;
            else if (dec_wb_addr_r[1]) core_1_r1 <= rf_wdata;
            else if (rl_addr[1]) core_1_r1 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[2] or negedge rst_n) begin
            if (!rst_n) core_1_r2 <= 16'd0;
            else if (dec_wb_addr_r[2]) core_1_r2 <= rf_wdata;
            else if (rl_addr[2]) core_1_r2 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[3] or negedge rst_n) begin
            if (!rst_n) core_1_r3 <= 16'd0;
            else if (dec_wb_addr_r[3]) core_1_r3 <= rf_wdata;
            else if (rl_addr[3]) core_1_r3 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[4] or negedge rst_n) begin
            if (!rst_n) core_1_r4 <= 16'd0;
            else if (dec_wb_addr_r[4]) core_1_r4 <= rf_wdata;
            else if (rl_addr[4]) core_1_r4 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[5] or negedge rst_n) begin
            if (!rst_n) core_1_r5 <= 16'd0;
            else if (dec_wb_addr_r[5]) core_1_r5 <= rf_wdata;
            else if (rl_addr[5]) core_1_r5 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[6] or negedge rst_n) begin
            if (!rst_n) core_1_r6 <= 16'd0;
            else if (dec_wb_addr_r[6]) core_1_r6 <= rf_wdata;
            else if (rl_addr[6]) core_1_r6 <= rf_rl_wdata;
        end
        always @(posedge gclk_c1[7] or negedge rst_n) begin
            if (!rst_n) core_1_r7 <= 16'd0;
            else if (dec_wb_addr_r[7]) core_1_r7 <= rf_wdata;
            else if (rl_addr[7]) core_1_r7 <= rf_rl_wdata;
        end

        // ----- core_2 -----
        always @(posedge gclk_c2[0] or negedge rst_n) begin
            if (!rst_n) core_2_r0 <= 16'd0;
            else if (dec_wb_addr_r[0]) core_2_r0 <= rf_wdata;
            else if (rl_addr[0]) core_2_r0 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[1] or negedge rst_n) begin
            if (!rst_n) core_2_r1 <= 16'd0;
            else if (dec_wb_addr_r[1]) core_2_r1 <= rf_wdata;
            else if (rl_addr[1]) core_2_r1 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[2] or negedge rst_n) begin
            if (!rst_n) core_2_r2 <= 16'd0;
            else if (dec_wb_addr_r[2]) core_2_r2 <= rf_wdata;
            else if (rl_addr[2]) core_2_r2 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[3] or negedge rst_n) begin
            if (!rst_n) core_2_r3 <= 16'd0;
            else if (dec_wb_addr_r[3]) core_2_r3 <= rf_wdata;
            else if (rl_addr[3]) core_2_r3 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[4] or negedge rst_n) begin
            if (!rst_n) core_2_r4 <= 16'd0;
            else if (dec_wb_addr_r[4]) core_2_r4 <= rf_wdata;
            else if (rl_addr[4]) core_2_r4 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[5] or negedge rst_n) begin
            if (!rst_n) core_2_r5 <= 16'd0;
            else if (dec_wb_addr_r[5]) core_2_r5 <= rf_wdata;
            else if (rl_addr[5]) core_2_r5 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[6] or negedge rst_n) begin
            if (!rst_n) core_2_r6 <= 16'd0;
            else if (dec_wb_addr_r[6]) core_2_r6 <= rf_wdata;
            else if (rl_addr[6]) core_2_r6 <= rf_rl_wdata;
        end
        always @(posedge gclk_c2[7] or negedge rst_n) begin
            if (!rst_n) core_2_r7 <= 16'd0;
            else if (dec_wb_addr_r[7]) core_2_r7 <= rf_wdata;
            else if (rl_addr[7]) core_2_r7 <= rf_rl_wdata;
        end
        
        // reg file read - core 1 (rs and rt)// reg file read - core 1 (rs and rt)
        always @(*) begin
                    if(current_core == 0) begin
                        case (dec_rs_addr)
                            3'b000: dec_rs_data = core_1_r0;
                            3'b001: dec_rs_data = core_1_r1;
                            3'b010: dec_rs_data = core_1_r2;
                            3'b011: dec_rs_data = core_1_r3;
                            3'b100: dec_rs_data = core_1_r4;
                            3'b101: dec_rs_data = core_1_r5;
                            3'b110: dec_rs_data = core_1_r6;
                            3'b111: dec_rs_data = core_1_r7;
                        endcase
                    end
                    else begin
                        case (dec_rs_addr)
                            3'b000: dec_rs_data = core_2_r0;
                            3'b001: dec_rs_data = core_2_r1;
                            3'b010: dec_rs_data = core_2_r2;
                            3'b011: dec_rs_data = core_2_r3;
                            3'b100: dec_rs_data = core_2_r4;
                            3'b101: dec_rs_data = core_2_r5;
                            3'b110: dec_rs_data = core_2_r6;
                            3'b111: dec_rs_data = core_2_r7;
                        endcase
                    end
        end
        always @(*) begin
                    if(current_core == 0) begin
                        // FIX: add rt read (was missing in original)
                        case (dec_rt_addr)
                            3'b000: dec_rt_data = core_1_r0;
                            3'b001: dec_rt_data = core_1_r1;
                            3'b010: dec_rt_data = core_1_r2;
                            3'b011: dec_rt_data = core_1_r3;
                            3'b100: dec_rt_data = core_1_r4;
                            3'b101: dec_rt_data = core_1_r5;
                            3'b110: dec_rt_data = core_1_r6;
                            3'b111: dec_rt_data = core_1_r7;
                        endcase
                    end
                    else begin
                        case (dec_rt_addr)
                            3'b000: dec_rt_data = core_2_r0;
                            3'b001: dec_rt_data = core_2_r1;
                            3'b010: dec_rt_data = core_2_r2;
                            3'b011: dec_rt_data = core_2_r3;
                            3'b100: dec_rt_data = core_2_r4;
                            3'b101: dec_rt_data = core_2_r5;
                            3'b110: dec_rt_data = core_2_r6;
                            3'b111: dec_rt_data = core_2_r7;
                        endcase
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
            output rf_read_en,
            output  current_core,
            input  [15:0] rs_data,
            input  [15:0] rt_data,

            output [7:0] dec_wb_addr_r,
            output [7:0] rl_addr,
            output       rf_write,
            output       rf_rl_write,
            output reg [15:0] rf_wdata,
            output reg [15:0] rf_rl_wdata,

            // AXI read addr channel (inst)
            output                  arvalid_m_inf_inst,
            output [31:0]           araddr_m_inf_inst,
            input                   arready_m_inf_inst,

            // AXI read data channel (inst)
            input                   rlast_m_inf_inst,
            input                   rvalid_m_inf_inst,
            input  [15:0]           rdata_m_inf_inst,
            output                  rready_m_inf_inst,

            // AXI read addr channel (inst) core 2
            output                  arvalid_m_inf_inst2,
            output [31:0]           araddr_m_inf_inst2,
            input                   arready_m_inf_inst2,

            // AXI read data channel (inst) core 2
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
            output                  wlast_m_inf_data,
            output                  wvalid_m_inf_data,
            input                   wready_m_inf_data
        );

            // ================================================================
            // FSM
            // ================================================================
            reg [2:0] state, next_state;

            localparam IF     = 3'd0;
            localparam ID     = 3'd1;
            localparam EXE    = 3'd2;
            localparam EXE2   = 3'd3;
            localparam WB     = 3'd4;
            localparam MEM    = 3'd5;
            localparam FLUSH  = 3'd6;

            // ================================================================
            // PC
            // ================================================================
            reg  [12:0] pc;
            reg  [12:0] pc_2;

            wire [12:0] pc_sel;
            wire [12:0] pc_next;
            wire [12:0] pc_plus2;
            wire [12:0] pc_n;

            wire signed [12:0] branch_offset;
            wire signed [12:0] branch_offset_plus2;
            wire [12:0] branch_target;

            // ================================================================
            // Instruction registers
            // ================================================================
            reg [15:0] if_instr_r;
            reg [15:0] if_instr_2_r;

            reg instr1_valid, instr2_valid;
            reg current_fetch_core;
            reg current_core_r;

            wire core_pick;
            wire [15:0] if_instr_sel;

            // ================================================================
            // Decode
            // ================================================================
            wire [2:0] opcode;
            wire [2:0] opcode2;
            wire [2:0] core1_opcode;
            wire [2:0] core2_opcode;

            wire [2:0] alu_op;
            wire [2:0] rt_sel;
            wire [2:0] rl_addr_decode;
            wire [6:0] imm;
            wire [12:0] jump_target;
            wire [2:0] rd_addr;

            wire is_R;
            wire is_mult;
            wire is_I;
            wire is_Load;
            wire is_Store;
            wire is_Branch;
            wire is_Jump;
            wire is_ADDI;
            wire is_SUBI;

            wire core1_is_Load;
            wire core1_is_Store;
            wire core2_is_Load;
            wire core2_is_Store;

            // ================================================================
            // EXE / ALU
            // ================================================================
            wire signed [15:0] alu_a;
            wire signed [15:0] alu_b;

            reg  signed [15:0] alu_result;
            reg  signed [15:0] alu_result_r;

            wire [15:0] alu_result_comb;

            wire alu_sub_mode;
            wire signed [15:0] alu_b_inv;
            wire signed [15:0] alu_addsub;

            wire signed [15:0] alu_and_result;
            wire signed [15:0] alu_or_result;
            wire signed [15:0] alu_xor_result;
            wire alu_slt_result;

            wire branch_taken;

            // ================================================================
            // Multiplier
            // ================================================================
            wire [31:0] mult_result;
            wire mult_done;

            // ================================================================
            // Fetch shared signals
            // ================================================================
            wire                  fetch_arvalid;
            wire [31:0]           fetch_araddr;
            wire                  fetch_arready;
            wire                  fetch_rlast;
            wire                  fetch_rvalid;
            wire [15:0]           fetch_rdata;

            // ================================================================
            // Memory
            // ================================================================
            wire [15:0] cache_data_o;
            wire        cache_data_valid_o;
            wire [12:0] mem_addr_sel;

            // ================================================================
            // Flush / change order
            // ================================================================
            reg [5:0] instr_counter;
            wire flush_done;

            wire change_order;
            reg  change_order_r;
            wire pair_fetch_done;
            wire pair_swap;

            wire wb_to_if;
            reg rf_wen;
            reg rl_wen;
            // ================================================================
            // AXI inst channel select
            // ================================================================
            assign arvalid_m_inf_inst  = (current_fetch_core == 1'b0) ? fetch_arvalid : 1'b0;
            assign araddr_m_inf_inst   = (current_fetch_core == 1'b0) ? fetch_araddr  : 32'b0;
            assign rready_m_inf_inst   = 1'b1;

            assign arvalid_m_inf_inst2 = (current_fetch_core == 1'b1) ? fetch_arvalid : 1'b0;
            assign araddr_m_inf_inst2  = (current_fetch_core == 1'b1) ? fetch_araddr  : 32'b0;
            assign rready_m_inf_inst2  = 1'b1;

            assign fetch_arready = (current_fetch_core == 1'b0) ? arready_m_inf_inst  : arready_m_inf_inst2;
            assign fetch_rlast   = (current_fetch_core == 1'b0) ? rlast_m_inf_inst    : rlast_m_inf_inst2;
            assign fetch_rvalid  = (current_fetch_core == 1'b0) ? rvalid_m_inf_inst   : rvalid_m_inf_inst2;
            assign fetch_rdata   = (current_fetch_core == 1'b0) ? rdata_m_inf_inst    : rdata_m_inf_inst2;

            // ================================================================
            // Core select
            // ================================================================
            // swap decision is registered when the second instruction is fetched,
            // so execute/decode no longer depends on change_order_r combinationally.
            assign core_pick    = current_core_r;
            assign current_core = current_core_r;

            // ================================================================
            // PC logic
            // ================================================================
            assign pc_sel   = core_pick ? pc_2 : pc;
            assign pc_plus2 = pc_sel + 13'd2;
            assign pc_next  = pc_plus2;

            assign branch_offset       = {{5{imm[6]}}, imm, 1'b0};
            assign branch_offset_plus2 = branch_offset + 13'sd2;
            assign branch_target       = pc_sel + branch_offset_plus2;

            assign pc_n = is_Jump      ? jump_target   :
                        branch_taken ? branch_target :
                                        pc_plus2;

            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    pc <= 13'd0;
                end
                else if(state == EXE && !core_pick) begin
                    pc <= pc_n;
                end
            end

            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    pc_2 <= 13'd0;
                end
                else if(state == EXE && core_pick) begin
                    pc_2 <= pc_n;
                end
            end

            // ================================================================
            // Instruction register
            // ================================================================
            wire instr0_en = (state == IF && cache_data_valid_o && current_fetch_core == 1'b0);
            wire instr1_en = (state == IF && cache_data_valid_o && current_fetch_core == 1'b1);

            wire gclk_instr0 = clk & instr0_en;
            wire gclk_instr1 = clk & instr1_en;

            always @(posedge gclk_instr0 or negedge rst_n) begin
                if(!rst_n) begin
                    if_instr_r <= 16'd0;
                end
                else begin
                    if_instr_r <= cache_data_o;
                end
            end

            always @(posedge gclk_instr1 or negedge rst_n) begin
                if(!rst_n) begin
                    if_instr_2_r <= 16'd0;
                end
                else begin
                    if_instr_2_r <= cache_data_o;
                end
            end


            // Decode order is decided exactly when the second instruction of the pair is fetched.
            // This copies the timing idea of the faster version, but keeps this module structure.
            assign pair_fetch_done = (state == IF) && cache_data_valid_o && (current_fetch_core == 1'b1);
            assign pair_swap       = pair_fetch_done && (if_instr_r[15:13] == 3'b100) &&
                                                       (cache_data_o[15:13] == 3'b101);
            assign change_order    = pair_swap;

            // ================================================================
            // Current execute core
            // ================================================================
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    current_core_r <= 1'b0;
                end
                else if(pair_fetch_done) begin
                    current_core_r <= pair_swap;
                end
                else if(state == WB) begin
                    if(change_order_r && current_core_r == 1'b0) begin
                        current_core_r <= 1'b0;
                    end
                    else begin
                        current_core_r <= ~current_core_r;
                    end
                end
                else begin
                    current_core_r <= current_core_r;
                end
            end

            // ================================================================
            // Current fetch core
            // ================================================================
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    current_fetch_core <= 1'b0;
                end
                else if(state == IF && cache_data_valid_o) begin
                    current_fetch_core <= ~current_fetch_core;
                end
                else begin
                    current_fetch_core <= current_fetch_core;
                end
            end

            // ================================================================
            // Instruction counter
            // ================================================================
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    instr_counter <= 6'd0;
                end
                else if(state == ID && (pc == 13'h1FFE && pc_2 == 13'h1FFE)) begin
                    instr_counter <= 6'd49;
                end
                else if(is_wb) begin
                    instr_counter <= (instr_counter == 6'd49) ? 6'd0 : instr_counter + 6'd1;
                end
            end

            // ================================================================
            // FSM
            // ================================================================
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    state <= IF;
                end
                else begin
                    state <= next_state;
                end
            end

            always @(*) begin
                case(state)
                    IF: begin
                        if(cache_data_valid_o && current_fetch_core == 1'b1) begin
                            next_state = ID;
                        end
                        else begin
                            next_state = IF;
                        end
                    end

                    ID: begin
                        next_state = EXE;
                    end

                    EXE: begin
                        if(is_Jump | is_Branch) begin
                            next_state = WB;
                        end
                        else if(is_mult) begin
                            next_state = EXE2;
                        end
                        else if(is_Load | is_Store) begin
                            next_state = MEM;
                        end
                        else begin
                            next_state = WB;
                        end
                    end

                    EXE2: begin
                        next_state = mult_done ? WB : EXE2;
                    end

                    MEM: begin
                        next_state = cache_data_valid_o ? WB : MEM;
                    end

                    WB: begin
                        if((change_order_r == 1'b0 && current_core_r == 1'b0) ||
                        (change_order_r == 1'b1 && current_core_r == 1'b1)) begin
                            next_state = ID;
                        end
                        else if(instr_counter == 6'd49) begin
                            next_state = FLUSH;
                        end
                        else begin
                            next_state = IF;
                        end
                    end

                    FLUSH: begin
                        if(flush_done) begin
                            next_state = IF;
                        end
                        else begin
                            next_state = FLUSH;
                        end
                    end

                    default: begin
                        next_state = IF;
                    end
                endcase
            end

            assign wb_to_if = (state == WB) &&
                            (change_order_r != current_core_r) &&
                            (instr_counter != 6'd49);

            assign is_wb = wb_to_if || (state == FLUSH && flush_done);

            // ================================================================
            // RF write
            // ================================================================
            assign rf_write    = state == WB && rf_wen;
            assign rf_rl_write = state == WB && rl_wen;

            wire rf_wdata_en = (state == EXE && (is_R || is_ADDI || is_SUBI)) ||
                            (state == EXE2 && mult_done) ||
                            (state == MEM && is_Load && cache_data_valid_o) || state == WB;

            wire gclk_rf_wdata = clk & rf_wdata_en;

            always @(posedge gclk_rf_wdata or negedge rst_n) begin
                if(!rst_n) begin
                    rf_wdata <= 16'd0;
                    rf_wen <= 0;
                end
                else if(state == EXE) begin
                    rf_wdata <= alu_result_comb;
                    rf_wen <= 1;
                end
                else if(state == EXE2 && mult_done) begin
                    rf_wdata <= mult_result[31:16];
                    rf_wen <= 1;
                end
                else if(state == MEM && is_Load && cache_data_valid_o) begin
                    rf_wdata <= cache_data_o;
                    rf_wen <= 1;
                end
                else if(state == WB)begin
                    rf_wdata <= 0;
                    rf_wen <= 0;
                end
            end

            always @(posedge gclk_rf_wdata or negedge rst_n) begin
                if(!rst_n) begin
                    rf_rl_wdata <= 16'd0;
                    rl_wen <= 0;
                end
                else if(state == EXE2 && mult_done) begin
                    rf_rl_wdata <= mult_result[15:0];
                    rl_wen <= 1;
                end
                else if(state == WB)begin
                    rf_rl_wdata <= 0;
                    rl_wen <= 0;
                end
            end

            // ================================================================
            // Memory instance
            // ================================================================
            assign mem_addr_sel = (state == MEM) ? {alu_result_r[11:0], 1'b0} :
                                (current_fetch_core == 1'b1) ? pc_2 : pc;

            Memory memory(
                .clk(clk),
                .rst_n(rst_n),

                .instr_in_valid_i(state == IF),
                .current_fetch_core(current_fetch_core),

                .data_in_valid_i(state == MEM),
                .addr_i(mem_addr_sel),
                .wdata_i(rt_data),
                .is_Store(is_Store),
                .data_o(cache_data_o),
                .data_valid_o(cache_data_valid_o),

                .flush_i(state == FLUSH),
                .flush_done_o(flush_done),

                // AXI read addr inst
                .arready_m_inf_inst(fetch_arready),
                .arvalid_m_inf_inst(fetch_arvalid),
                .araddr_m_inf_inst(fetch_araddr),

                // AXI read data inst
                .rlast_m_inf_inst(fetch_rlast),
                .rvalid_m_inf_inst(fetch_rvalid),
                .rdata_m_inf_inst(fetch_rdata),

                // AXI read addr data
                .arready_m_inf_data(arready_m_inf_data),
                .arvalid_m_inf_data(arvalid_m_inf_data),
                .araddr_m_inf_data(araddr_m_inf_data),

                // AXI read data data
                .rlast_m_inf_data(rlast_m_inf_data),
                .rvalid_m_inf_data(rvalid_m_inf_data),
                .rdata_m_inf_data(rdata_m_inf_data),

                // AXI write addr data
                .awvalid_m_inf_data(awvalid_m_inf_data),
                .awaddr_m_inf_data(awaddr_m_inf_data),
                .awlen_m_inf_data(awlen_m_inf_data),
                .awready_m_inf_data(awready_m_inf_data),

                // AXI write data data
                .wdata_m_inf_data(wdata_m_inf_data),
                .wlast_m_inf_data(wlast_m_inf_data),
                .wvalid_m_inf_data(wvalid_m_inf_data),
                .wready_m_inf_data(wready_m_inf_data)
            );

            // ================================================================
            // Decode
            // ================================================================
            assign core1_opcode = if_instr_r[15:13];
            assign core2_opcode = if_instr_2_r[15:13];

            assign if_instr_sel = core_pick ? if_instr_2_r : if_instr_r;

            assign opcode  = if_instr_sel[15:13];
            assign opcode2 = core2_opcode;

            assign rs_addr = if_instr_sel[12:10];
            assign rt_addr = if_instr_sel[9:7];

            assign rd_addr         = if_instr_sel[6:4];
            assign rl_addr_decode  = if_instr_sel[3:1];
            assign alu_op          = if_instr_sel[3:1];
            assign imm             = if_instr_sel[6:0];
            assign jump_target     = if_instr_sel[12:0];

            assign rf_read_en = state == ID;

            assign is_R      = opcode == 3'b000;
            assign is_mult   = opcode == 3'b001;
            assign is_ADDI   = opcode == 3'b010;
            assign is_SUBI   = opcode == 3'b011;
            assign is_I      = is_ADDI | is_SUBI;
            assign is_Load   = opcode == 3'b100;
            assign is_Store  = opcode == 3'b101;
            assign is_Branch = opcode == 3'b110;
            assign is_Jump   = opcode == 3'b111;

            assign core1_is_Load  = core1_opcode == 3'b100;
            assign core1_is_Store = core1_opcode == 3'b101;
            assign core2_is_Load  = core2_opcode == 3'b100;
            assign core2_is_Store = core2_opcode == 3'b101;

            assign rt_sel = (is_R | is_mult) ? rd_addr : rt_addr;

            assign dec_wb_addr_r = rf_write ? (8'b0000_0001 << rt_sel) : 8'b0;
            assign rl_addr       = rf_rl_write ? (8'b0000_0001 << rl_addr_decode) : 8'b0;

            // ================================================================
            // Change order
            // ================================================================
            // change_order_r is the registered swap flag for the current two-instruction pair.
            // It is no longer used to select the instruction combinationally.
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    change_order_r <= 1'b0;
                end
                else if(pair_fetch_done) begin
                    change_order_r <= pair_swap;
                end
                else if(state == WB && current_core_r == 1'b0) begin
                    change_order_r <= 1'b0;
                end
                else begin
                    change_order_r <= change_order_r;
                end
            end

            // ================================================================
            // EXE / inline ALU
            // ================================================================
            assign alu_a = rs_data;
            assign alu_b = is_R ? rt_data : {{9{imm[6]}}, imm};

            assign branch_taken = is_Branch && (rs_data == rt_data);

            assign alu_sub_mode = is_SUBI ||
                                (is_R && alu_op == 3'b001) ||
                                (is_R && alu_op == 3'b111);

            assign alu_b_inv  = alu_b ^ {16{alu_sub_mode}};
            assign alu_addsub = alu_a + alu_b_inv + {15'd0, alu_sub_mode};

            assign alu_and_result = alu_a & alu_b;
            assign alu_or_result  = alu_a | alu_b;
            assign alu_xor_result = alu_a ^ alu_b;

            assign alu_slt_result = (alu_a[15] == alu_b[15]) ? alu_addsub[15] : alu_a[15];

            always @(*) begin
                if(is_ADDI || is_SUBI || is_Load || is_Store) begin
                    alu_result = alu_addsub;
                end
                else if(is_R) begin
                    case(alu_op)
                        3'b000: alu_result = alu_addsub;
                        3'b001: alu_result = alu_addsub;
                        3'b111: alu_result = {15'd0, alu_slt_result};
                        3'b010: alu_result = alu_and_result;
                        3'b100: alu_result = ~alu_and_result;
                        3'b011: alu_result = alu_or_result;
                        3'b101: alu_result = ~alu_or_result;
                        3'b110: alu_result = alu_xor_result;
                        default: alu_result = 16'd0;
                    endcase
                end
                else begin
                    alu_result = 16'd0;
                end
            end

            assign alu_result_comb = alu_result;

            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    alu_result_r <= 16'd0;
                end
                else if(state == EXE) begin
                    alu_result_r <= alu_result_comb;
                end
            end

            // ================================================================
            // Multiplier
            // ================================================================
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
            output  reg [15:0]data_o,
            output reg        data_valid_o,
            input flush_i,
            output reg flush_done_o,
            // AXI read addr 
            input                   arready_m_inf_inst,
            output reg              arvalid_m_inf_inst,
            output reg [31:0]       araddr_m_inf_inst,
        
            // AXI read data channel
            input rlast_m_inf_inst,
            input rvalid_m_inf_inst,
            input [15:0] rdata_m_inf_inst,
            // AXI read addr 
            input                   arready_m_inf_data,
            output reg              arvalid_m_inf_data,
            output reg [31:0]       araddr_m_inf_data,
        
            // AXI read data channel
            input rlast_m_inf_data,
            input rvalid_m_inf_data,
            input [15:0] rdata_m_inf_data,
    
            // AXI write addr channel
            input                   awready_m_inf_data,
            output reg              awvalid_m_inf_data,
            output reg [31:0]       awaddr_m_inf_data,
            output reg [6:0]            awlen_m_inf_data,
    
            // AXI write data channel
            input                   wready_m_inf_data,
            output   reg           wlast_m_inf_data,
            output   reg         wvalid_m_inf_data,
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
wire is_read, is_write;
        wire         dcache_oe, dcache_cs;
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
        reg [6:0] dirty_data_num_r;
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
// SRAM_384_16 layout:
//   0   ~ 255 : data cache, unchanged address mapping
//   256 ~ 319 : instr0 cache, 1-entry x 64 words
//   320 ~ 383 : instr1 cache, 1-entry x 64 words
//
// Instruction cache block size:
//   64 words x 16 bits = 128 bytes
//   block tag = addr_i[12:7]
//   offset    = addr_i[6:1]
        wire icache_hit;
        reg  [5:0] icache_tag [1:0];
        reg        icache_data_valid [1:0];
wire [5:0] icache_offset;
        wire [5:0] icache_addr_sel;
wire [8:0] instr_sram_addr;
wire [8:0] data_sram_addr;


// synopsys translate_off
        // ================================================================
        // Simulation-only cache access profiler
        // ================================================================
        localparam integer MAX_PROFILE_MISSES = 65536;
        localparam integer MAX_PROFILE_BLOCKS = 64;

        integer inst0_profile_fd;
        integer inst1_profile_fd;
        integer data_profile_fd;

        integer inst0_miss_count;
        integer inst1_miss_count;
        integer data_miss_count;
        integer profile_i;
        integer profile_block_i;

        reg [12:0] inst0_miss_addr [0:MAX_PROFILE_MISSES-1];
        reg [12:0] inst1_miss_addr [0:MAX_PROFILE_MISSES-1];
        reg [12:0] data_miss_addr  [0:MAX_PROFILE_MISSES-1];

        // One 64-bit bitmap per 128-byte block.
        // addr_i[12:7] selects one of 64 blocks.
        // addr_i[6:1] selects one of 64 16-bit entries in that block.
        reg [63:0] inst0_block_used [0:MAX_PROFILE_BLOCKS-1];
        reg [63:0] inst1_block_used [0:MAX_PROFILE_BLOCKS-1];
        reg [63:0] data_block_used  [0:MAX_PROFILE_BLOCKS-1];

        function integer count_used_entries;
            input [63:0] used_bitmap;
            integer bit_i;
            begin
                count_used_entries = 0;
                for(bit_i = 0; bit_i < 64; bit_i = bit_i + 1)
                    count_used_entries = count_used_entries + used_bitmap[bit_i];
            end
        endfunction

        initial begin
            inst0_profile_fd = $fopen("inst0_profile.txt", "w");
            inst1_profile_fd = $fopen("inst1_profile.txt", "w");
            data_profile_fd  = $fopen("data_profile.txt",  "w");

            if(inst0_profile_fd == 0)
                $display("[Memory profile] cannot open inst0_profile.txt");
            if(inst1_profile_fd == 0)
                $display("[Memory profile] cannot open inst1_profile.txt");
            if(data_profile_fd == 0)
                $display("[Memory profile] cannot open data_profile.txt");

            inst0_miss_count = 0;
            inst1_miss_count = 0;
            data_miss_count  = 0;

            for(profile_block_i = 0;
                profile_block_i < MAX_PROFILE_BLOCKS;
                profile_block_i = profile_block_i + 1) begin
                inst0_block_used[profile_block_i] = 64'b0;
                inst1_block_used[profile_block_i] = 64'b0;
                data_block_used[profile_block_i]  = 64'b0;
            end
        end

        task dump_inst0_block_usage;
            integer block_i;
            integer used_count;
            begin
                $fwrite(inst0_profile_fd, "\n========================================\n");
                $fwrite(inst0_profile_fd, "CACHE BLOCK USAGE (64 entries/block)\n");
                for(block_i = 0; block_i < MAX_PROFILE_BLOCKS; block_i = block_i + 1) begin
                    used_count = count_used_entries(inst0_block_used[block_i]);
                    if(used_count != 0)
                        $fwrite(inst0_profile_fd,
                                "block %04h: %0d\n",
                                block_i << 7, used_count);
                end
            end
        endtask

        task dump_inst1_block_usage;
            integer block_i;
            integer used_count;
            begin
                $fwrite(inst1_profile_fd, "\n========================================\n");
                $fwrite(inst1_profile_fd, "CACHE BLOCK USAGE (64 entries/block)\n");
                for(block_i = 0; block_i < MAX_PROFILE_BLOCKS; block_i = block_i + 1) begin
                    used_count = count_used_entries(inst1_block_used[block_i]);
                    if(used_count != 0)
                        $fwrite(inst1_profile_fd,
                                "block %04h: %0d\n",
                                block_i << 7, used_count);
                end
            end
        endtask

        task dump_data_block_usage;
            integer block_i;
            integer used_count;
            begin
                $fwrite(data_profile_fd, "\n========================================\n");
                $fwrite(data_profile_fd, "CACHE BLOCK USAGE (64 entries/block)\n");
                for(block_i = 0; block_i < MAX_PROFILE_BLOCKS; block_i = block_i + 1) begin
                    used_count = count_used_entries(data_block_used[block_i]);
                    if(used_count != 0)
                        $fwrite(data_profile_fd,
                                "block %04h: %0d\n",
                                block_i << 7, used_count);
                end
            end
        endtask

        task dump_inst0_miss_summary;
            begin
                $fwrite(inst0_profile_fd, "\n========================================\n");
                $fwrite(inst0_profile_fd, "MISS COUNT: %0d\n", inst0_miss_count);
                $fwrite(inst0_profile_fd, "inst 0: ");
                if(inst0_miss_count == 0) begin
                    $fwrite(inst0_profile_fd, "none");
                end
                else begin
                    for(profile_i = 0; profile_i < inst0_miss_count; profile_i = profile_i + 1) begin
                        if(profile_i != 0)
                            $fwrite(inst0_profile_fd, ", ");
                        $fwrite(inst0_profile_fd, "%02h", inst0_miss_addr[profile_i]);
                    end
                end
                $fwrite(inst0_profile_fd, "\n");
            end
        endtask

        task dump_inst1_miss_summary;
            begin
                $fwrite(inst1_profile_fd, "\n========================================\n");
                $fwrite(inst1_profile_fd, "MISS COUNT: %0d\n", inst1_miss_count);
                $fwrite(inst1_profile_fd, "inst 1: ");
                if(inst1_miss_count == 0) begin
                    $fwrite(inst1_profile_fd, "none");
                end
                else begin
                    for(profile_i = 0; profile_i < inst1_miss_count; profile_i = profile_i + 1) begin
                        if(profile_i != 0)
                            $fwrite(inst1_profile_fd, ", ");
                        $fwrite(inst1_profile_fd, "%02h", inst1_miss_addr[profile_i]);
                    end
                end
                $fwrite(inst1_profile_fd, "\n");
            end
        endtask

        task dump_data_miss_summary;
            begin
                $fwrite(data_profile_fd, "\n========================================\n");
                $fwrite(data_profile_fd, "MISS COUNT: %0d\n", data_miss_count);
                $fwrite(data_profile_fd, "data: ");
                if(data_miss_count == 0) begin
                    $fwrite(data_profile_fd, "none");
                end
                else begin
                    for(profile_i = 0; profile_i < data_miss_count; profile_i = profile_i + 1) begin
                        if(profile_i != 0)
                            $fwrite(data_profile_fd, ", ");
                        $fwrite(data_profile_fd, "%02h", data_miss_addr[profile_i]);
                    end
                end
                $fwrite(data_profile_fd, "\n");
            end
        endtask

        // Only write the summary and close files when the simulation truly ends.
        // Do not close them at FLUSH because this CPU enters FLUSH periodically.
        final begin
            // Print block usage first so the miss-address list remains
            // the final section in each profile file.
            dump_inst0_block_usage();
            dump_inst1_block_usage();
            dump_data_block_usage();

            dump_inst0_miss_summary();
            dump_inst1_miss_summary();
            dump_data_miss_summary();

            $fclose(inst0_profile_fd);
            $fclose(inst1_profile_fd);
            $fclose(data_profile_fd);
        end
// synopsys translate_on
        
assign icache_offset = addr_i[6:1];

        assign icache_hit = icache_data_valid[current_fetch_core] &&
                    (icache_tag[current_fetch_core] == addr_i[12:7]);

// 64-word instruction block => 128-byte aligned address.
        // registered AXI inst read address (timing: remove addr_i->output I/O path)
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) araddr_m_inf_inst <= 32'b0;
            else       araddr_m_inf_inst <= {19'b0, addr_i[12:7], 7'b0};
        end

        // icache tag and valid
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
        icache_data_valid[0] <= 1'b0;
        icache_data_valid[1] <= 1'b0;
    end
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst) begin
        icache_data_valid[current_fetch_core] <= 1'b1;
end
    else begin
        icache_data_valid[0] <= icache_data_valid[0];
        icache_data_valid[1] <= icache_data_valid[1];
    end
        end
        wire gclk_itag_en0 = (state == READ && rvalid_m_inf_inst && rlast_m_inf_inst && current_fetch_core == 0);
        wire gclk_itag0 = clk & gclk_itag_en0;
        always @(posedge gclk_itag0 or negedge rst_n) begin
            if(!rst_n) begin
                icache_tag[0] <= 6'd0;
            end
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst && current_fetch_core == 0) begin
                icache_tag[0] <= addr_i[12:7];
            end
        end
        wire gclk_itag_en1 = (state == READ && rvalid_m_inf_inst && rlast_m_inf_inst && current_fetch_core == 1);
        wire gclk_itag1 = clk & gclk_itag_en1;
        always @(posedge gclk_itag1 or negedge rst_n) begin
            if(!rst_n) begin
                icache_tag[1] <= 6'd0;
            end
            else if(state == READ && rvalid_m_inf_inst && rlast_m_inf_inst && current_fetch_core == 1) begin
                icache_tag[1] <= addr_i[12:7];
            end
        end
        assign cache_idx = addr_i[8];
        assign cache_tag = addr_i[12:9];
        assign cache_offset = addr_i[7:1];
        assign cache_hit = (cache_tag == dcache_tag[cache_idx]) && dcache_data_valid[cache_idx];


// synopsys translate_off
        // Record exactly one access when the Memory FSM accepts a request.
        // Data has priority over instruction, matching the IDLE next-state logic.
        // A value other than a definite 1 is treated as a miss. This also catches
        // an uninitialized/X valid or tag instead of silently dropping the miss.
        always @(posedge clk) begin
            if(rst_n && state == IDLE && !flush_i) begin
                if(data_in_valid_i) begin
                    data_block_used[addr_i[12:7]][addr_i[6:1]] = 1'b1;

                    if(cache_hit === 1'b1) begin
                        if(is_Store)
                            $fdisplay(data_profile_fd,
                                      "time=%0t STORE addr=%02h cache_idx=%0d HIT",
                                      $time, addr_i, cache_idx);
                        else
                            $fdisplay(data_profile_fd,
                                      "time=%0t LOAD  addr=%02h cache_idx=%0d HIT",
                                      $time, addr_i, cache_idx);
                    end
                    else begin
                        if(is_Store)
                            $fdisplay(data_profile_fd,
                                      "time=%0t STORE addr=%02h cache_idx=%0d MISS",
                                      $time, addr_i, cache_idx);
                        else
                            $fdisplay(data_profile_fd,
                                      "time=%0t LOAD  addr=%02h cache_idx=%0d MISS",
                                      $time, addr_i, cache_idx);

                        if(data_miss_count < MAX_PROFILE_MISSES) begin
                            data_miss_addr[data_miss_count] = addr_i;
                            data_miss_count = data_miss_count + 1;
                        end
                    end
                end
                else if(instr_in_valid_i) begin
                    if(current_fetch_core == 1'b0) begin
                        inst0_block_used[addr_i[12:7]][addr_i[6:1]] = 1'b1;

                        if(icache_hit === 1'b1) begin
                            $fdisplay(inst0_profile_fd,
                                      "time=%0t addr=%02h HIT",
                                      $time, addr_i);
                        end
                        else begin
                            $fdisplay(inst0_profile_fd,
                                      "time=%0t addr=%02h MISS",
                                      $time, addr_i);

                            if(inst0_miss_count < MAX_PROFILE_MISSES) begin
                                inst0_miss_addr[inst0_miss_count] = addr_i;
                                inst0_miss_count = inst0_miss_count + 1;
                            end
                        end
                    end
                    else begin
                        inst1_block_used[addr_i[12:7]][addr_i[6:1]] = 1'b1;

                        if(icache_hit === 1'b1) begin
                            $fdisplay(inst1_profile_fd,
                                      "time=%0t addr=%02h HIT",
                                      $time, addr_i);
                        end
                        else begin
                            $fdisplay(inst1_profile_fd,
                                      "time=%0t addr=%02h MISS",
                                      $time, addr_i);

                            if(inst1_miss_count < MAX_PROFILE_MISSES) begin
                                inst1_miss_addr[inst1_miss_count] = addr_i;
                                inst1_miss_count = inst1_miss_count + 1;
                            end
                        end
                    end
                end
            end
        end
// synopsys translate_on
        
        //assign plus_dram_addr_offest = addr_i[12] ? 2'b10 : 2'b01;
        assign plus_dram_addr_offest = {addr_i[12], ~addr_i[12]};
        // araddr: fetch the 256-byte page containing addr_i
        // registered AXI data read address (timing: remove addr_i->output I/O path)
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) araddr_m_inf_data <= 32'b0;
            else       araddr_m_inf_data <= {18'b0, plus_dram_addr_offest, addr_i[11:8], 8'b0};
        end
        
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
                            if(need_flush_num_r == flush_cnt) next_state = DONE;
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
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i) begin
                dcache_dirty[cache_idx] <= 1;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data) begin
                dcache_dirty[entry_sel] <= 0;
            end
            else begin
                dcache_dirty[1:0] <= dcache_dirty[1:0];
            end
        end

        // dirty-range pointer bank, separated so DC gives it a dedicated
        // NOTE: relies on DC `set_clock_gating_style -positive_edge_logic {and}`;
        //       do NOT hand-roll `clk & en` (bare AND, glitch-prone).
        wire gclk_dirty_ptr0_en = (state == READ_DONE && is_Store && data_in_valid_i && cache_idx == 0) || (state == WRITE && wlast_m_inf_data && wready_m_inf_data && entry_sel == 0);
        wire gclk_dirty_ptr0 = clk & gclk_dirty_ptr0_en;
        always @(posedge gclk_dirty_ptr0 or negedge rst_n) begin
            if(!rst_n) begin
                dcache_dirty_start_addr[0] <= 127;
                dcache_dirty_end_addr[0] <= 0;
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i && cache_idx == 0) begin
                if(cache_offset > dcache_dirty_end_addr[0]) 
                    dcache_dirty_end_addr[0] <= cache_offset;
                if(cache_offset < dcache_dirty_start_addr[0]) 
                    dcache_dirty_start_addr[0] <= cache_offset;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data && entry_sel == 0) begin
                dcache_dirty_start_addr[0] <= 127;
                dcache_dirty_end_addr[0] <= 0;
            end
        end
        wire gclk_dirty_ptr1_en = (state == READ_DONE && is_Store && data_in_valid_i && cache_idx == 1) || (state == WRITE && wlast_m_inf_data && wready_m_inf_data && entry_sel == 1);
        wire gclk_dirty_ptr1 = clk & gclk_dirty_ptr1_en;
        always @(posedge gclk_dirty_ptr1 or negedge rst_n) begin
            if(!rst_n) begin
                dcache_dirty_start_addr[1] <= 127;
                dcache_dirty_end_addr[1] <= 0;
            end
            else if(state == READ_DONE && is_Store && data_in_valid_i && cache_idx == 1) begin
                if(cache_offset > dcache_dirty_end_addr[1]) 
                    dcache_dirty_end_addr[1] <= cache_offset;
                if(cache_offset < dcache_dirty_start_addr[1]) 
                    dcache_dirty_start_addr[1] <= cache_offset;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data && entry_sel == 1) begin
                dcache_dirty_start_addr[1] <= 127;
                dcache_dirty_end_addr[1] <= 0;
            end
        end
        assign entry_sel = flush_i ? flush_entry : cache_idx;
        assign dirty_data_num = dcache_dirty_end_addr[entry_sel] - dcache_dirty_start_addr[entry_sel];

        // timing: removes (entry_sel mux + subtractor) from wlast's FF->FF path
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)                    dirty_data_num_r <= 7'd0;
            else if(state == ISSUE_WRITE) dirty_data_num_r <= dirty_data_num;
            else                          dirty_data_num_r <= dirty_data_num_r;
        end
        // wire gclk_dtag_en0 = (state == READ && rvalid_m_inf_data && rlast_m_inf_data && cache_idx == 0);
        // wire gclk_dtag0 = clk & gclk_dtag_en0;
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) dcache_tag[0] <= 0;
            else if(state == READ && rvalid_m_inf_data && rlast_m_inf_data && cache_idx == 0) dcache_tag[0]  <= addr_i[12:9];
        end
        // wire gclk_dtag_en1 = (state == READ && rvalid_m_inf_data && rlast_m_inf_data && cache_idx == 1);
        // wire gclk_dtag1 = clk & gclk_dtag_en1;
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) dcache_tag[1] <= 0;
            else if(state == READ && rvalid_m_inf_data && rlast_m_inf_data && cache_idx == 1) dcache_tag[1]  <= addr_i[12:9];
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
assign is_read = (state == IDLE && ((data_in_valid_i && cache_hit) || (instr_in_valid_i && icache_hit))) 
                            || (state == GET_CACHE_DATA) || (state == WRITE && wready_m_inf_data) || (state == READ_DONE);
        assign is_write = dcache_web == 0;
        assign dcache_oe = 1'b1;
        assign dcache_cs = is_read || is_write;

        reg is_read_d;
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) is_read_d <= 1'b0;
            else       is_read_d <= is_read;
        end
               
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
        // always @(posedge clk or negedge rst_n) begin
        //     if (!rst_n) begin
        //         icache_addr_cnt <= 7'd0;
        //     end
        //     else if(state == IDLE) begin
        //         icache_addr_cnt <= 7'd0;
        //     end
        //     else if(!dcache_web) begin
        //         icache_addr_cnt <= icache_addr_cnt + 1;
        //     end
        //     else begin
        //         icache_addr_cnt <= icache_addr_cnt;
        //     end
        // end
        // Instruction SRAM address:
//   instr0 base = 256 = 9'h100
//   instr1 base = 320 = 9'h140
// During refill, dcache_addr_cnt[5:0] writes offset 0~63.
assign icache_addr_sel = (state == READ || state == FETCH_DONE) ?
                         dcache_addr_cnt[5:0] :
                         icache_offset;

        assign dcache_addr_sel = state == READ || state == FETCH_DONE || state == ISSUE_WRITE || state == GET_CACHE_DATA || state == WRITE ? dcache_addr_cnt : cache_offset;
        
assign data_sram_addr  = {1'b0, entry_sel, dcache_addr_sel};       // 0~255
assign instr_sram_addr = current_fetch_core ?
                          {3'b101, icache_addr_sel} :              // 320~383
                          {3'b100, icache_addr_sel};               // 256~319

assign dcache_addr = instr_in_valid_i ? instr_sram_addr : data_sram_addr;
        // instruction output
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                data_o       <= 0;
            end
            else if(state == READ_DONE) begin
                data_o       <= dcache_rdata;
            end
        end
        reg [15:0] mem_data_o;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                mem_data_o       <= 0;
            end
            else if(is_read_d) begin
                mem_data_o       <= dcache_rdata;
            end
            else begin
                mem_data_o       <= mem_data_o;
            end
        end
        // assign data_valid_o = state == DONE;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                data_valid_o <= 0;
            end
            // Hit from cache: read from SRAM
            else if(next_state == DONE) begin
                data_valid_o <= 1;
            end
            else begin
                data_valid_o <= 0;
            end
        end
        
        SRAM_384_16 dcache(
            .clk(clk),
            .addr(dcache_addr),
            .data_i(dcache_w_data),
            .WEB(dcache_web),
            .data_o(dcache_rdata),
            .cache_oe(dcache_oe),
            .cache_cs(dcache_cs)
        );
        // write back to memory
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                flush_cnt <= 1;
            end
            else if(state == WRITE && wlast_m_inf_data && wready_m_inf_data) begin
                flush_cnt <= flush_cnt + 1;
            end
            else if(state == DONE)begin
                flush_cnt <= 1;
            end
            else begin
                flush_cnt <= flush_cnt;
            end
        end
    
        assign flush_entry = dcache_dirty[0] && flush_cnt == 1 ? 0 : 1;
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
                cache_data_buffer[1] <= mem_data_o;
                cache_data_buffer[0] <= cache_data_buffer[1];
            end
            else if(state == WRITE && wready_m_inf_data)begin
                cache_data_buffer[1] <= 0;
                cache_data_buffer[0] <= cache_data_buffer[1];
            end
        end
        //assign victim_plus_dram_addr_offest = dcache_tag[entry_sel][3] ? 2'b10 : 2'b01;
        assign victim_plus_dram_addr_offest = {dcache_tag[entry_sel][3], ~dcache_tag[entry_sel][3]};
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) awaddr_m_inf_data <= 32'b0;
            else       awaddr_m_inf_data <= {18'b0, victim_plus_dram_addr_offest,
                                             dcache_tag[entry_sel][2:0], entry_sel,
                                             dcache_dirty_start_addr[entry_sel], 1'b0};
        end
        // assign awlen_m_inf_data = dirty_data_num;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                awlen_m_inf_data <= 0;
            end
            else begin
                awlen_m_inf_data <= dirty_data_num;
            end
        end
        assign wdata_m_inf_data = flush_issue_cnt <= 1 ? cache_data_buffer[0] : mem_data_o;
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) wvalid_m_inf_data <= 1'b0;
            else        wvalid_m_inf_data <= (next_state == WRITE);
        end
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                wlast_m_inf_data <= 0;
            end
            else if(state == WRITE) begin
                if(flush_issue_cnt + 1 == dirty_data_num_r && wready_m_inf_data) wlast_m_inf_data <= 1;
                else if(dirty_data_num_r == 0)wlast_m_inf_data <= 1;
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
    output                mult_done
);

    reg  [3:0] shift_cnt;
    wire       busy = (shift_cnt != 4'd0);

    wire gclk_shift_mult_en = mult_en | busy;
    wire gclk_shift = clk & gclk_shift_mult_en;
    always @(posedge gclk_shift or negedge rst_n) begin
        if      (!rst_n)            shift_cnt <= 4'd0;
        else if (mult_en && !busy)  shift_cnt <= 4'd8;
        else if (busy)              shift_cnt <= shift_cnt - 4'd1;
    end
    assign mult_done = (shift_cnt == 4'd0);

    reg  signed [33:0] A_r;
    reg  signed [17:0] B_r;
    reg  signed [33:0] result_r;

    reg  signed [33:0] add_sel_r;
    reg                op;

    wire signed [33:0] add_sel;
    wire signed [33:0] result_comb;

    always @(*) begin
        case (B_r[2:0])
            3'b001, 3'b010: begin add_sel_r = A_r;        end
            3'b011:         begin add_sel_r = A_r <<< 1; end
            3'b100:         begin add_sel_r = A_r <<< 1;  end
            3'b101, 3'b110: begin add_sel_r = A_r;        end
            default:        begin add_sel_r = 0;  end
        endcase
    end
    always @(*) begin
        case (B_r[2:0])
            3'b001, 3'b010: begin op = 1'b0; end
            3'b011:         begin  op = 1'b0; end
            3'b100:         begin op = 1'b1; end
            3'b101, 3'b110: begin op = 1'b1; end
            default:        begin op = 1'b0; end
        endcase
    end
    assign add_sel = op ? ~add_sel_r : add_sel_r;
    wire gclk_mult_en = mult_en | busy;
    wire gclk_mult = clk & gclk_mult_en;
    always @(posedge gclk_mult or negedge rst_n) begin
        if (!rst_n) begin
            A_r <= 0;
        end
        else if (mult_en && !busy) begin
            A_r <= {{18{A[15]}}, A};
        end
        else if (busy) begin
            A_r <= A_r <<< 2;
        end
    end
    wire gclk_mult2 = clk & gclk_mult_en;
    always @(posedge gclk_mult2 or negedge rst_n) begin
        if (!rst_n) begin
            B_r   <= 0;
        end
        else if (mult_en && !busy) begin
            B_r   <= {B[15], B, 1'b0};
        end
        else if (busy) begin
            B_r   <= {{2{B_r[17]}}, B_r[17:2]};
        end
    end
    wire gclk_mult3 = clk & gclk_mult_en;
    
    assign result_comb   = result_r + add_sel + {{33{1'b0}}, op};
    always @(posedge gclk_mult3 or negedge rst_n) begin
        if (!rst_n) begin
            result_r       <= 0;
        end
        else if (mult_en && !busy) begin
            result_r       <= 0;
        end
        else if (busy) begin
            result_r       <= result_comb;
        end
    end
    assign result = result_r[31:0];

endmodule
     // =====================================================================
        // SRAM_384_16 wrapper
        // =====================================================================
        module SRAM_384_16(
            clk, addr, data_i, WEB, data_o, cache_oe, cache_cs
        );
        input         clk;
        input  [8:0]  addr;
        input  [15:0] data_i;
        input         WEB;
        output [15:0] data_o;
input        cache_oe;
        input        cache_cs;
        
        SUMA180_384X16X1BM1 u_SRAM_384_16
        (
            .A0(addr[0]), .A1(addr[1]), .A2(addr[2]),.A3(addr[3]), .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), .A7(addr[7]), .A8(addr[8]),
            .DO0(data_o[0]),  .DO1(data_o[1]),  .DO2(data_o[2]),   .DO3(data_o[3]),   .DO4(data_o[4]),   .DO5(data_o[5]),   .DO6(data_o[6]),   .DO7(data_o[7]),  
            .DO8(data_o[8]),  .DO9(data_o[9]),  .DO10(data_o[10]), .DO11(data_o[11]), .DO12(data_o[12]), .DO13(data_o[13]), .DO14(data_o[14]), .DO15(data_o[15]),
            .DI0(data_i[0]),   .DI1(data_i[1]),   .DI2(data_i[2]),    .DI3(data_i[3]),    .DI4(data_i[4]),    .DI5(data_i[5]),    .DI6(data_i[6]),    .DI7(data_i[7]),   
            .DI8(data_i[8]),   .DI9(data_i[9]),   .DI10(data_i[10]),  .DI11(data_i[11]),  .DI12(data_i[12]),  .DI13(data_i[13]),  .DI14(data_i[14]),  .DI15(data_i[15]),   
            .CK(clk),           .WEB(WEB),   	     .OE(cache_oe), 	     .CS(cache_cs)
        );
        
        endmodule
    