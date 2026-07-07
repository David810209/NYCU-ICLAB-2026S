//############################################################################
//   2025 Digital Circuit and System Lab
//   Final Project : MCU System with CNN Instruction Acceleration
//   Author      : Ceres Lab 2025 MS1
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   Date        : 2025/05/24
//   Version     : v1.0
//   File Name   : TOP.v
//   Module Name : TOP
//############################################################################
//==============================================//
//           TOP Module Declaration             //
//==============================================//
module TOP(
	// System IO 
	clk            	,	
	rst_n          	,	
	IO_stall        ,	

	// AXI4 IO for Data DRAM
        awaddr_m_inf_data,
        awvalid_m_inf_data,
        awready_m_inf_data,
        awlen_m_inf_data,     

        wdata_m_inf_data,
        wvalid_m_inf_data,
        wlast_m_inf_data,
        wready_m_inf_data,
                    
        
        bresp_m_inf_data,
        bvalid_m_inf_data,
        bready_m_inf_data,
                    
        araddr_m_inf_data,
        arvalid_m_inf_data,         
        arready_m_inf_data, 
        arlen_m_inf_data,

        rdata_m_inf_data,
        rvalid_m_inf_data,
        rlast_m_inf_data,
        rready_m_inf_data,
    // AXI4 IO for Instruction DRAM
        araddr_m_inf_inst,
        arvalid_m_inf_inst,         
        arready_m_inf_inst, 
        arlen_m_inf_inst,
        
        rdata_m_inf_inst,
        rvalid_m_inf_inst,
        rlast_m_inf_inst,
        rready_m_inf_inst   
);
// ===============================================================
//  			   		Parameters
// ===============================================================
parameter ADDR_WIDTH = 32;           // Do not modify
parameter DATA_WIDTH_inst = 16;      // Do not modify
parameter DATA_WIDTH_data = 8;       // Do not modify

// ===============================================================
//  					Input / Output 
// ===============================================================
// << System io port >>
input wire			  	clk,rst_n;
output  			    IO_stall;   
 
// << AXI Interface wire connecttion for pseudo Data DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     awaddr_m_inf_data;
output reg [7:0]                awlen_m_inf_data;      // burst length 0~127
output reg                      awvalid_m_inf_data;
// 		src slave   
input wire                     awready_m_inf_data;
// -----------------------------
// (2)	axi write data channel 
// 		src master
output reg [DATA_WIDTH_data-1:0]  wdata_m_inf_data;
output reg                   wlast_m_inf_data;
output reg                   wvalid_m_inf_data;
// 		src slave
input wire                  wready_m_inf_data;
// -----------------------------
// (3)	axi write response channel 
// 		src slave
input wire  [1:0]           bresp_m_inf_data;
input wire                  bvalid_m_inf_data;
// 		src master 
output reg                   bready_m_inf_data;
// -----------------------------
// (4)	axi read address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     araddr_m_inf_data;
output reg [7:0]                arlen_m_inf_data;     // burst length 0~127
output reg                      arvalid_m_inf_data;
// 		src slave
input wire                     arready_m_inf_data;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
input wire [DATA_WIDTH_data-1:0]  rdata_m_inf_data;
input wire                   rlast_m_inf_data;
input wire                   rvalid_m_inf_data;
// 		src master
output reg                    rready_m_inf_data;

// << AXI Interface wire connecttion for pseudo Instruction DRAM read >>
// -----------------------------
// (1)	axi read address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     araddr_m_inf_inst;
output reg [7:0]                arlen_m_inf_inst;     // burst length 0~127
output reg                      arvalid_m_inf_inst;
// 		src slave
input wire                     arready_m_inf_inst;
// -----------------------------
// (2)	axi read data channel 
// 		src slave
input wire [DATA_WIDTH_inst-1:0]  rdata_m_inf_inst;
input wire                   rlast_m_inf_inst;
input wire                   rvalid_m_inf_inst;
// 		src master
output reg                    rready_m_inf_inst;

// ===============================================================
//  					Signal Declaration 
// ===============================================================
// reg signed [7:0] reg_file    [0:15];    // Registor File for Microcontroller

////////////////////////////////////////////////////////////////
// PC stage singal
////////////////////////////////////////////////////////////////
wire [ADDR_WIDTH-1:0] pcu_pc; // Program Counter
////////////////////////////////////////////////////////////////
// Fetct stage singal
////////////////////////////////////////////////////////////////
wire [DATA_WIDTH_inst-1:0] fet2dec_instr;
wire [ADDR_WIDTH-1:0] fet2dec_pc;
wire stall_instr_fetch;
////////////////////////////////////////////////////////////////
// decode stage singal
////////////////////////////////////////////////////////////////
// decode to exe
wire [ADDR_WIDTH-1:0] dec2exe_pc; 
wire                  dec_is_branch;
wire                  dec_is_jump;
wire                  dec_is_load;
wire                  dec_is_store;
wire                  dec_is_add;
wire                  dec_is_sub;
wire                  dec_is_mul;
wire [4:0]            dec_imm;
wire                  dec_wb;
wire                  dec_is_CNN;
wire [8:0]           dec_CNN_info;
// decode to reg_file
wire [3:0]            dec2rf_rs;
wire [3:0]            dec2rf_rt;
wire [3:0]            dec2exe_rd;
wire [3:0]            dec2exe_rs;
wire [3:0]            dec2exe_rt;
// decode to pcu
wire [ADDR_WIDTH-1:0] dec2pcu_jump_addr;

// register file to execution
wire [DATA_WIDTH_data-1:0] rf2dec_rs1_data;
wire [DATA_WIDTH_data-1:0] rf2dec_rs2_data;
wire [DATA_WIDTH_data-1:0] dec2exe_rs1_data;
wire [DATA_WIDTH_data-1:0] dec2exe_rs2_data;
// forwarding
wire [1:0] forward_rs1;
wire [1:0] forward_rs2;
////////////////////////////////////////////////////////////////
// execution stage singal
////////////////////////////////////////////////////////////////
    // to pcu
wire                  exe_branch_taken;
wire [ADDR_WIDTH-1:0] exe2pcu_branch_addr;
 // to memory
wire  store_forward;
wire                  exe2mem_load;
wire                  exe2mem_store;
wire                  exe2mem_wb;
wire [DATA_WIDTH_data-1:0] exe2mem_reg_data;
wire [DATA_WIDTH_data-1:0] exe2mem_alu_result;
wire [ADDR_WIDTH-1:0] exe2mem_addr;
wire [ADDR_WIDTH-1:0] exe2mem_pc;
wire [3:0]            exe2mem_rd;
wire                  exe2mem_mem2reg_mux;

wire [DATA_WIDTH_data-1:0] exe_rs1_sel;
wire [DATA_WIDTH_data-1:0] exe_rs2_sel;

// CNN signal
wire [1:0] CNN2exe_result;
wire CNN_done;
// (4)	axi read address channel 
// 		src master
wire [ADDR_WIDTH-1:0]     CNN_araddr_m_inf_data;
wire [7:0]                CNN_arlen_m_inf_data;     // burst length 0~127
wire                      CNN_arvalid_m_inf_data;
// 		src slave
wire                    CNN_arready_m_inf_data;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
wire [DATA_WIDTH_data-1:0]  CNN_rdata_m_inf_data;
wire                  CNN_rlast_m_inf_data;
wire                   CNN_rvalid_m_inf_data;
// 		src master
wire                    CNN_rready_m_inf_data;
////////////////////////////////////////////////////////////////
// memory stage singal
////////////////////////////////////////////////////////////////
wire [DATA_WIDTH_data-1:0] exe2mem_reg_data_mux;
wire [DATA_WIDTH_data-1:0] mem2wb_mem_data;
wire [DATA_WIDTH_data-1:0] mem2wb_alu_result;
wire                       mem2wb_wb;
wire [3:0]                 mem2wb_rd;
wire                       mem2wb_mem2reg_mux;
wire [ADDR_WIDTH-1:0] mem2wb_pc;
wire for_IO_stall;
// << AXI Interface wire connecttion for pseudo Data DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
wire [ADDR_WIDTH-1:0]     DMEM_awaddr_m_inf_data;
wire [7:0]                DMEM_awlen_m_inf_data;      // burst length 0~127
wire                      DMEM_awvalid_m_inf_data;
// 		src slave   
wire                     DMEM_awready_m_inf_data;
// -----------------------------
// (2)	axi write data channel 
// 		src master
wire [DATA_WIDTH_data-1:0]  DMEM_wdata_m_inf_data;
wire                   DMEM_wlast_m_inf_data;
wire                   DMEM_wvalid_m_inf_data;
// 		src slave
wire                  DMEM_wready_m_inf_data;
// -----------------------------
// (3)	axi write response channel 
// 		src slave
wire  [1:0]           DMEM_bresp_m_inf_data;
wire                  DMEM_bvalid_m_inf_data;
// 		src master 
wire                  DMEM_bready_m_inf_data;
// (4)	axi read address channel 
// 		src master
wire [ADDR_WIDTH-1:0]     DMEM_araddr_m_inf_data;
wire [7:0]                DMEM_arlen_m_inf_data;     // burst length 0~127
wire                      DMEM_arvalid_m_inf_data;
// 		src slave
wire                    DMEM_arready_m_inf_data;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
wire [DATA_WIDTH_data-1:0]  DMEM_rdata_m_inf_data;
wire                  DMEM_rlast_m_inf_data;
wire                   DMEM_rvalid_m_inf_data;
// 		src master
wire                    DMEM_rready_m_inf_data;
////////////////////////////////////////////////////////////////
// write back stage singal
////////////////////////////////////////////////////////////////
wire [3:0] wb2rf_rd;
wire [DATA_WIDTH_data-1:0] wb2rf_write_data;
wire                       wb2rf_write_enable;
////////////////////////////////////////////////////////////////
// other stage singal
////////////////////////////////////////////////////////////////
// data hazard
wire load_use_hazard;
// stall
wire stall_pipeline;
wire CNN_stall;
// reg [31:0] CNN_stall_profile; // profiling CNN stall
// reg [63:0] instr_fetch_stall_profile;
// reg [63:0] data_fetch_stall_profile;
// reg [63:0] fetch_stall_profile;
// reg [63:0] all_stall_profile;
// reg [63:0] all_stall_profile2;
// reg [31:0] load_use_hazard_profile; // profiling load-use hazard
// ===============================================================
//  					Start Your Design
// ===============================================================
////////////////////////////////////////////////////////////////
// CNN, DMEM read port arbiter
////////////////////////////////////////////////////////////////
reg ARBITER_state, next_ARBITER_state;
localparam ARBITER_IDLE = 0,
           ARBITER_WAIT = 1;
reg [1:0] current_master;
wire rready_m_inf_data_sel;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) ARBITER_state <= 0;
    else ARBITER_state <= next_ARBITER_state;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_master <= 0;
    else if(ARBITER_state == ARBITER_IDLE && DMEM_arvalid_m_inf_data) current_master <= 0;
    else if(ARBITER_state == ARBITER_IDLE && DMEM_awvalid_m_inf_data) current_master <= 2;
    else if(ARBITER_state == ARBITER_IDLE && CNN_arvalid_m_inf_data) current_master <= 1;
    else current_master <= current_master;
end

always @(*) begin
    case (ARBITER_state) 
        ARBITER_IDLE: begin
            if(CNN_arvalid_m_inf_data || DMEM_arvalid_m_inf_data || DMEM_awvalid_m_inf_data) next_ARBITER_state = ARBITER_WAIT;
            else next_ARBITER_state = ARBITER_IDLE; 
        end
        ARBITER_WAIT: begin
            if((rready_m_inf_data_sel && rvalid_m_inf_data && rlast_m_inf_data) || (bvalid_m_inf_data && bready_m_inf_data)) next_ARBITER_state = ARBITER_IDLE;
            else next_ARBITER_state = ARBITER_WAIT;
        end
        default: next_ARBITER_state = ARBITER_IDLE;
    endcase
end

assign awaddr_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_awaddr_m_inf_data : 0;
assign awlen_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_awlen_m_inf_data : 0;
assign awvalid_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_awvalid_m_inf_data : 0;
assign DMEM_awready_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 2) ? awready_m_inf_data : 1'b0;
assign wdata_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_wdata_m_inf_data : 0;
assign wlast_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_wlast_m_inf_data : 1'b0;
assign wvalid_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_wvalid_m_inf_data : 0;
assign DMEM_wready_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 2) ? wready_m_inf_data : 1'b0;
assign bready_m_inf_data = (current_master == 2 && ARBITER_state == ARBITER_WAIT) ? DMEM_bready_m_inf_data : 1'b0;
assign DMEM_bresp_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 2) ? bresp_m_inf_data : 0;
assign DMEM_bvalid_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 2) ? bvalid_m_inf_data : 1'b0;



assign rready_m_inf_data_sel = (current_master == 0) ? DMEM_rready_m_inf_data :
                               (current_master == 1) ? CNN_rready_m_inf_data : 1'b0;

assign araddr_m_inf_data = (ARBITER_state == ARBITER_IDLE || current_master == 2) ? 0 :
                            (current_master == 0) ? DMEM_araddr_m_inf_data : CNN_araddr_m_inf_data;
assign arlen_m_inf_data = (ARBITER_state == ARBITER_IDLE || current_master == 2) ? 0 :
                            (current_master == 0) ? DMEM_arlen_m_inf_data : CNN_arlen_m_inf_data;
assign arvalid_m_inf_data = (ARBITER_state == ARBITER_IDLE || current_master == 2) ? 0 :
                            (current_master == 0) ? DMEM_arvalid_m_inf_data : CNN_arvalid_m_inf_data;   
assign DMEM_arready_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 0) ? arready_m_inf_data : 1'b0;
assign CNN_arready_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 1) ? arready_m_inf_data : 1'b0;
assign rready_m_inf_data = (ARBITER_state == ARBITER_IDLE || current_master == 2) ? 0 :
                            (current_master == 0) ? DMEM_rready_m_inf_data : CNN_rready_m_inf_data;
assign DMEM_rdata_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 0) ? rdata_m_inf_data : 0;
assign CNN_rdata_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 1) ? rdata_m_inf_data : 0;
assign DMEM_rlast_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 0) ? rlast_m_inf_data : 1'b0;
assign CNN_rlast_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 1) ? rlast_m_inf_data : 1'b0;
assign DMEM_rvalid_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 0) ? rvalid_m_inf_data : 1'b0;
assign CNN_rvalid_m_inf_data = (ARBITER_state == ARBITER_WAIT && current_master == 1) ? rvalid_m_inf_data : 1'b0;

////////////////////////////////////////////////////////////////
// PC stage 
////////////////////////////////////////////////////////////////
pcu #(.ADDR_WIDTH(ADDR_WIDTH)) pcu (
    // System signals
    .clk(clk),
    .rst_n(rst_n),
    .stall_i(stall_pipeline || load_use_hazard),

    // from decode
    .dec_is_jump_i(dec_is_jump),
    .dec2pcu_jump_addr_i(dec2pcu_jump_addr),
    // from exe
    .exe2pcu_branch_addr_i(exe2pcu_branch_addr),
    .exe_branch_taken_i(exe_branch_taken),

    .pcu_pc_o(pcu_pc)
);
////////////////////////////////////////////////////////////////
// Fetct stage 
////////////////////////////////////////////////////////////////
Fetch #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH_inst)) fetch (
    // System signal
    .clk(clk),
    .rst_n(rst_n),
    .stall_i(stall_pipeline || load_use_hazard),
    .flush_i(dec_is_jump || exe_branch_taken), // flush if jump or branch taken

    // from pcu
    .pcu_pc_i(pcu_pc),

    // instr fetch stall
    .stall_instr_fetch_o(stall_instr_fetch),

    // AXI Interface for instruction DRAM
    .araddr_m_inf_inst(araddr_m_inf_inst),
    .arlen_m_inf_inst(arlen_m_inf_inst),
    .arvalid_m_inf_inst(arvalid_m_inf_inst),         
    .arready_m_inf_inst(arready_m_inf_inst), 
    
    .rdata_m_inf_inst(rdata_m_inf_inst),
    .rlast_m_inf_inst(rlast_m_inf_inst),
    .rvalid_m_inf_inst(rvalid_m_inf_inst),
    .rready_m_inf_inst(rready_m_inf_inst),

    // to decode
    .fet2dec_instr(fet2dec_instr),
    .fet2dec_pc(fet2dec_pc)
);
////////////////////////////////////////////////////////////////
// decode stage singal
////////////////////////////////////////////////////////////////
decode #(.DATA_WIDTH_inst(DATA_WIDTH_inst), .ADDR_WIDTH(ADDR_WIDTH)) decode (
    // System signals
    .clk(clk),
    .rst_n(rst_n),
    .stall_i(stall_pipeline),
    .flush_i(exe_branch_taken || load_use_hazard), 

    // from fetch
    .fet2dec_instr(fet2dec_instr),
    .fet2dec_pc(fet2dec_pc),

    // to execution
    .dec2exe_pc(dec2exe_pc),
    .dec_is_branch(dec_is_branch),
    .dec_is_jump(dec_is_jump),
    .dec_is_load(dec_is_load),
    .dec_is_store(dec_is_store),
    .dec_is_add(dec_is_add),
    .dec_is_sub(dec_is_sub),
    .dec_is_mul(dec_is_mul),
    .dec_imm(dec_imm),
    .dec_wb(dec_wb),
    .dec2exe_rd(dec2exe_rd),
    .dec2exe_rs(dec2exe_rs),
    .dec2exe_rt(dec2exe_rt),
    .dec_is_CNN(dec_is_CNN),
    .dec_CNN_info(dec_CNN_info),
    .dec2exe_rs1_data(dec2exe_rs1_data),
    .dec2exe_rs2_data(dec2exe_rs2_data),
    // to reg_file
    .dec2rf_rs(dec2rf_rs),
    .dec2rf_rt(dec2rf_rt),
    .rs1_data(rf2dec_rs1_data),
    .rs2_data(rf2dec_rs2_data),
    // to pcu
    .dec2pcu_jump_addr(dec2pcu_jump_addr),
    // to hazard detection
    .is_load_hazard_o(load_use_hazard)
);

reg_file #(.DATA_WIDTH_data(DATA_WIDTH_data)) reg_file (
    // System signals
    .clk(clk),
    .rst_n(rst_n),

    // from Decode
    .rs1_addr_i(dec2rf_rs),
    .rs2_addr_i(dec2rf_rt),
    .we_i(wb2rf_write_enable),
    .write_addr_i(wb2rf_rd),
    .write_data_i(wb2rf_write_data),

    // to Execute
    .rs1_data_o(rf2dec_rs1_data),
    .rs2_data_o(rf2dec_rs2_data)
);

// forwarding
assign forward_rs1 = (dec2exe_rs == exe2mem_rd && exe2mem_wb) ? 2'b10  // forward from memory stage
                     :  (dec2exe_rs == mem2wb_rd && mem2wb_wb) ? 2'b01 // forward from write back stage
                     : 2'b00;

assign forward_rs2 = (dec2exe_rt == exe2mem_rd && exe2mem_wb) ? 2'b10  // forward from memory stage
                     :  (dec2exe_rt == mem2wb_rd && mem2wb_wb) ? 2'b01 // forward from write back stage
                     : 2'b00;

assign exe_rs1_sel = forward_rs1 == 2'b10 ? exe2mem_alu_result :
                    forward_rs1 == 2'b01 ? wb2rf_write_data : dec2exe_rs1_data;
assign exe_rs2_sel = forward_rs2 == 2'b10 ? exe2mem_alu_result :
                    forward_rs2 == 2'b01 ? wb2rf_write_data : dec2exe_rs2_data;
////////////////////////////////////////////////////////////////
// execution stage 
////////////////////////////////////////////////////////////////
execution #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH_data(DATA_WIDTH_data)) execution (
    // System signals
    .clk(clk),
    .rst_n(rst_n),
    .stall_i(stall_pipeline),
    // .flush_i(exe_branch_taken), // flush if load-use hazard
    // from decode
    .dec2exe_pc(dec2exe_pc),
    .dec_is_branch(dec_is_branch),
    .dec_is_load(dec_is_load),
    .dec_is_store(dec_is_store),
    .dec_is_add(dec_is_add),
    .dec_is_sub(dec_is_sub),
    .dec_is_mul(dec_is_mul),
    .dec_wb(dec_wb),
    .dec_imm(dec_imm),
    .dec2exe_rd(dec2exe_rd),
    .dec_is_CNN(dec_is_CNN),
    
    // from/to CNN
    .CNN_done(CNN_done),
    .CNN2exe_result(CNN2exe_result),
    // from reg_file
    .rf2exe_rs1_data(exe_rs1_sel),
    .rf2exe_rs2_data(exe_rs2_sel),

    // to pcu
    .exe_branch_taken(exe_branch_taken),
    .exe2pcu_branch_addr(exe2pcu_branch_addr),

    // to memory
    .exe2mem_load(exe2mem_load),
    .exe2mem_store(exe2mem_store),
    .exe2mem_wb(exe2mem_wb),
    .exe2mem_reg_data(exe2mem_reg_data),
    .exe2mem_alu_result(exe2mem_alu_result),
    .exe2mem_addr(exe2mem_addr),
    .exe2mem_pc(exe2mem_pc),
    .exe2mem_rd(exe2mem_rd),
    .exe2mem_mem2reg_mux(exe2mem_mem2reg_mux),
    .CNN_stall_o(CNN_stall)
);

CNN #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH_data))
CNN(
    .clk(clk),
    .rst_n(rst_n),
    .dec_is_CNN(dec_is_CNN),
    .dec_CNN_info(dec_CNN_info),
    .out_done(CNN_done),
    .out_data(CNN2exe_result),

    // AXI4 IO for Data DRAM
    .araddr_m_inf_data(CNN_araddr_m_inf_data),
    .arvalid_m_inf_data(CNN_arvalid_m_inf_data),         
    .arready_m_inf_data(CNN_arready_m_inf_data), 
    .arlen_m_inf_data(CNN_arlen_m_inf_data),

    .rdata_m_inf_data(CNN_rdata_m_inf_data),
    .rvalid_m_inf_data(CNN_rvalid_m_inf_data),
    .rlast_m_inf_data(CNN_rlast_m_inf_data),
    .rready_m_inf_data(CNN_rready_m_inf_data)
);

////////////////////////////////////////////////////////////////
// memory stage 
////////////////////////////////////////////////////////////////
assign store_forward = (exe2mem_store && (exe2mem_rd == mem2wb_rd) && mem2wb_wb);

assign exe2mem_reg_data_mux = store_forward ? wb2rf_write_data : exe2mem_reg_data;

memory #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH_data)) memory (
    // system signal
    .clk(clk),
    .rst_n(rst_n),
    .stall_i(stall_pipeline),
    .stall_instr_fetch_i(stall_instr_fetch),

    .stall_data_fetch_o(stall_data_fetch_o),

    // from execution
    .exe2mem_load(exe2mem_load),
    .exe2mem_store(exe2mem_store),
    .exe2mem_wb(exe2mem_wb),
    .exe2mem_reg_data(exe2mem_reg_data_mux),
    .exe2mem_alu_result(exe2mem_alu_result),
    .exe2mem_addr(exe2mem_addr),
    .exe2mem_pc(exe2mem_pc),
    .exe2mem_rd(exe2mem_rd),
    .exe2mem_mem2reg_mux(exe2mem_mem2reg_mux),

    // to write back
    .mem2wb_mem_data(mem2wb_mem_data),
    .mem2wb_alu_result(mem2wb_alu_result),
    .mem2wb_wb(mem2wb_wb),
    .mem2wb_rd(mem2wb_rd),
    .mem2wb_mem2reg_mux(mem2wb_mem2reg_mux),
    .mem2wb_pc(mem2wb_pc),

    // AXI4 IO for Data DRAM
    .awaddr_m_inf_data(DMEM_awaddr_m_inf_data),
    .awvalid_m_inf_data(DMEM_awvalid_m_inf_data),
    .awready_m_inf_data(DMEM_awready_m_inf_data),
    .awlen_m_inf_data(DMEM_awlen_m_inf_data),     

    .wdata_m_inf_data(DMEM_wdata_m_inf_data),
    .wvalid_m_inf_data(DMEM_wvalid_m_inf_data),
    .wlast_m_inf_data(DMEM_wlast_m_inf_data),
    .wready_m_inf_data(DMEM_wready_m_inf_data),

    
    .bresp_m_inf_data(DMEM_bresp_m_inf_data),
    .bvalid_m_inf_data(DMEM_bvalid_m_inf_data),
    .bready_m_inf_data(DMEM_bready_m_inf_data),

    .araddr_m_inf_data(DMEM_araddr_m_inf_data),
    .arvalid_m_inf_data(DMEM_arvalid_m_inf_data),         
    .arready_m_inf_data(DMEM_arready_m_inf_data), 
    .arlen_m_inf_data(DMEM_arlen_m_inf_data),

    .rdata_m_inf_data(DMEM_rdata_m_inf_data),
    .rvalid_m_inf_data(DMEM_rvalid_m_inf_data),
    .rlast_m_inf_data(DMEM_rlast_m_inf_data),
    .rready_m_inf_data(DMEM_rready_m_inf_data),
    .for_IO_stall(for_IO_stall)
);

////////////////////////////////////////////////////////////////
// write back stage 
////////////////////////////////////////////////////////////////
assign wb2rf_rd = mem2wb_rd;
assign wb2rf_write_data = mem2wb_mem2reg_mux ? mem2wb_alu_result :mem2wb_mem_data;
assign wb2rf_write_enable = mem2wb_wb;

assign IO_stall = !for_IO_stall;
// hazard detection

assign stall_pipeline = stall_instr_fetch || (stall_data_fetch_o) || CNN_stall;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) CNN_stall_profile <= 0;
//     else if(CNN_stall) CNN_stall_profile <= CNN_stall_profile + 1;
//     else CNN_stall_profile <= CNN_stall_profile;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) instr_fetch_stall_profile <= 0;
//     else if(stall_instr_fetch) instr_fetch_stall_profile <= instr_fetch_stall_profile + 1;
//     else instr_fetch_stall_profile <= instr_fetch_stall_profile;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) data_fetch_stall_profile <= 0;
//     else if(stall_data_fetch_o) data_fetch_stall_profile <= data_fetch_stall_profile + 1;
//     else data_fetch_stall_profile <= data_fetch_stall_profile;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) fetch_stall_profile <= 0;
//     else if(stall_instr_fetch || stall_data_fetch_o) fetch_stall_profile <= fetch_stall_profile + 1;
//     else fetch_stall_profile <= fetch_stall_profile;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) all_stall_profile <= 0;
//     else if(stall_pipeline || load_use_hazard) all_stall_profile <= all_stall_profile + 1;
//     else all_stall_profile <= all_stall_profile;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) all_stall_profile2 <= 0;
//     else if(stall_pipeline) all_stall_profile2 <= all_stall_profile2 + 1;
//     else all_stall_profile2 <= all_stall_profile2;
// end

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) load_use_hazard_profile <= 0;
//     else if(load_use_hazard) load_use_hazard_profile <= load_use_hazard_profile + 1;
//     else load_use_hazard_profile <= load_use_hazard_profile;
// end

endmodule

// program counter unit
module pcu #( parameter ADDR_WIDTH = 32 )
(
    // System signals
    input                   clk,
    input                   rst_n, 
    input                   stall_i,

    // from decode
    input                   dec_is_jump_i,
    input [ADDR_WIDTH-1:0]  dec2pcu_jump_addr_i,
    // from exe
    input  [ADDR_WIDTH-1:0] exe2pcu_branch_addr_i,
    input                   exe_branch_taken_i,

    output reg [ADDR_WIDTH-1:0] pcu_pc_o
);

always @(posedge clk or negedge rst_n)begin
    if(!rst_n) pcu_pc_o <= 0;
    else if(stall_i) pcu_pc_o <= pcu_pc_o;
    else if(exe_branch_taken_i) pcu_pc_o <= exe2pcu_branch_addr_i;
    else if(dec_is_jump_i) pcu_pc_o <= dec2pcu_jump_addr_i;
    else pcu_pc_o <= pcu_pc_o + 1;
end

endmodule

// fetch stage
module Fetch #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 16)
(
	// system signal
	clk            	,	
	rst_n          	,	
    stall_i         ,
    flush_i,

    // from pcu
    pcu_pc_i,

    // instr fetch stall
    stall_instr_fetch_o,
                
    araddr_m_inf_inst    ,
    arlen_m_inf_inst,
    arvalid_m_inf_inst   ,         
    arready_m_inf_inst   , 
    
    rdata_m_inf_inst     ,
    rlast_m_inf_inst,
    rvalid_m_inf_inst    ,
    rready_m_inf_inst ,
    // to decode
    fet2dec_instr,
    fet2dec_pc
);

// system signal					
input clk, rst_n, stall_i;
input  flush_i;
input [ADDR_WIDTH-1:0] pcu_pc_i;
// << AXI Interface wire connecttion for pseudo Instruction DRAM read >>
// -----------------------------
// (1)	axi read address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     araddr_m_inf_inst;
output reg [7:0]                arlen_m_inf_inst;     // burst length 0~127
output reg                      arvalid_m_inf_inst;
// 		src slave
input wire                     arready_m_inf_inst;
// -----------------------------
// (2)	axi read data channel 
// 		src slave
input wire [DATA_WIDTH-1:0]  rdata_m_inf_inst;
input wire                   rlast_m_inf_inst;
input wire                   rvalid_m_inf_inst;
// 		src master
output reg                    rready_m_inf_inst;

// to decode
output reg [DATA_WIDTH-1:0] fet2dec_instr;
output reg [ADDR_WIDTH-1:0] fet2dec_pc;

// stall instr fetch
output stall_instr_fetch_o;
// ===============================================================
//  					Signal Declaration 
// ===============================================================
localparam IDLE = 0,
            READ =1, 
            WAIT_READ = 2,
            SELECT_DATA = 3,
            FINISH_JOB =4;
reg [2:0] state , next_state;
// reg [DATA_WIDTH-1:0] dram_data_buffer;
localparam CACHE_ENTRY = 2;
localparam INDEX_BIT = $clog2(CACHE_ENTRY);
localparam BURST_LENGTH = 7;
localparam BURST_BIT = $clog2(BURST_LENGTH + 1); 
localparam CACHE_WIDTH = (BURST_LENGTH + 1) * DATA_WIDTH; 
reg [CACHE_WIDTH-1:0] instr_input_buffer[0:CACHE_ENTRY - 1];
reg [ADDR_WIDTH-1-BURST_BIT-INDEX_BIT:0] addr_buffer[0:CACHE_ENTRY - 1];
wire [ADDR_WIDTH-1-BURST_BIT-INDEX_BIT:0] current_tag;
wire [BURST_BIT-1:0] current_offset;
wire [INDEX_BIT-1:0] current_index;
wire cache_hit;
reg [DATA_WIDTH-1:0] output_instr;
// reg [ADDR_WIDTH-1:0] pcu_reg;
// ===============================================================
//  					Start Your Design
// ===============================================================

//FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: begin
            next_state = cache_hit ? SELECT_DATA : READ;
        end
        READ: begin
            if(arready_m_inf_inst) next_state = WAIT_READ;
            else next_state = READ;
        end
        WAIT_READ: begin
            if(rvalid_m_inf_inst && rlast_m_inf_inst) next_state = SELECT_DATA;
            else next_state = WAIT_READ;
        end
        SELECT_DATA: next_state = FINISH_JOB;
        FINISH_JOB: next_state = stall_i ? FINISH_JOB : IDLE;
        default: next_state = IDLE;
    endcase
end
// // pcu_reg
// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) pcu_reg <= 32'b0;
//     else if(state == IDLE && !stall_i) pcu_reg <= pcu_pc_i;
//     else pcu_reg <= pcu_reg;
// end

assign stall_instr_fetch_o = (state == FINISH_JOB) ? 1'b0 : 1'b1;

// fet2dec_instr
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) fet2dec_instr <= 16'b0;
    else if(stall_i)fet2dec_instr <= fet2dec_instr;
    else if(flush_i) fet2dec_instr <= 0;
    else fet2dec_instr <= output_instr;
end
// [ tag | index | offset ]
assign current_tag = pcu_pc_i[ADDR_WIDTH-1:BURST_BIT+INDEX_BIT];
assign current_offset = pcu_pc_i[BURST_BIT-1:0];
assign current_index = pcu_pc_i[INDEX_BIT + BURST_BIT - 1:BURST_BIT];
assign cache_hit = (state == IDLE) && (addr_buffer[current_index] == current_tag);

integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < CACHE_ENTRY;i = i + 1) instr_input_buffer[i] <= 0;
    end
    else if(state == WAIT_READ && rvalid_m_inf_inst)
            instr_input_buffer[current_index] <= {instr_input_buffer[current_index][(CACHE_WIDTH - DATA_WIDTH - 1):0], rdata_m_inf_inst};
    else begin
        for(i = 0;i < CACHE_ENTRY;i = i + 1) instr_input_buffer[i] <= instr_input_buffer[i];
    end
end

// integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;i < CACHE_ENTRY;i = i + 1) addr_buffer[i] <= 32'hFFFFFFFF;
    end
    else if(state == WAIT_READ && rvalid_m_inf_inst && rlast_m_inf_inst) 
            addr_buffer[current_index] <= current_tag;
    else begin
        for(i = 0;i < CACHE_ENTRY;i = i + 1) addr_buffer[i] <= addr_buffer[i];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) fet2dec_pc <= 0;
    else if(stall_i)fet2dec_pc <= fet2dec_pc;
    else if(flush_i) fet2dec_pc <= 32'hFFFFFFFF;
    else fet2dec_pc <= pcu_pc_i;
end

always @(posedge clk) begin
    case(current_offset)
        0: output_instr <= instr_input_buffer[current_index][8*DATA_WIDTH-1:7*DATA_WIDTH];
        1: output_instr <= instr_input_buffer[current_index][7*DATA_WIDTH-1:6*DATA_WIDTH];
        2: output_instr <= instr_input_buffer[current_index][6*DATA_WIDTH-1:5*DATA_WIDTH];
        3: output_instr <= instr_input_buffer[current_index][5*DATA_WIDTH-1:4*DATA_WIDTH];
        4: output_instr <= instr_input_buffer[current_index][4*DATA_WIDTH-1:3*DATA_WIDTH];
        5: output_instr <= instr_input_buffer[current_index][3*DATA_WIDTH-1:2*DATA_WIDTH];
        6: output_instr <= instr_input_buffer[current_index][2*DATA_WIDTH-1:DATA_WIDTH];
        7: output_instr <= instr_input_buffer[current_index][DATA_WIDTH-1:0];
        default: output_instr <= 16'b0;
endcase
end

// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (4)	axi read address channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arvalid_m_inf_inst <= 1'b0;
    else if(state == READ && !arready_m_inf_inst) arvalid_m_inf_inst <= 1'b1;
    else arvalid_m_inf_inst <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) araddr_m_inf_inst <= 32'b0;
    else if(state == READ) araddr_m_inf_inst <= {current_tag, current_index, {BURST_BIT{1'b0}}};
    else araddr_m_inf_inst <= 32'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arlen_m_inf_inst <= 8'b0;
    else if(state == READ) arlen_m_inf_inst <= (BURST_LENGTH);
    else arlen_m_inf_inst <= 8'b0;
end

// (5)	axi read data channel

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rready_m_inf_inst <= 1'b0;
    else if(next_state == WAIT_READ) rready_m_inf_inst <= 1'b1;
    else rready_m_inf_inst <= 1'b0;
end

endmodule

module decode #(parameter DATA_WIDTH_inst = 16, ADDR_WIDTH = 32)
(
    // System signals
    input                   clk,
    input                   rst_n, 
    input                   stall_i,
    input                   flush_i,

    // from fetch
    input [DATA_WIDTH_inst-1:0] fet2dec_instr,
    input [ADDR_WIDTH-1:0] fet2dec_pc,
    // to execution
    output reg [ADDR_WIDTH-1:0] dec2exe_pc,
    output reg              dec_is_branch,
    output                  dec_is_jump,
    output reg              dec_is_load,
    output reg              dec_is_store,
    output reg              dec_is_add,
    output reg              dec_is_sub,
    output reg              dec_is_mul,
    output reg [4:0]        dec_imm,
    output reg              dec_wb,
    output reg              dec_is_CNN,
    output reg [8:0]       dec_CNN_info,
    output reg [7:0] dec2exe_rs1_data, 
    output reg [7:0] dec2exe_rs2_data,  
    output reg [3:0]        dec2exe_rd,
    output reg[3:0]         dec2exe_rs,
    output reg[3:0]         dec2exe_rt,
    // to reg_file
    output  [3:0]        dec2rf_rs,
    output  [3:0]        dec2rf_rt,

    input [7:0] rs1_data, 
    input [7:0] rs2_data,  
    // to pcu
    output  [ADDR_WIDTH-1:0] dec2pcu_jump_addr,

    output                  is_load_hazard_o
);

wire [2:0] opcode;
wire is_branch;
wire is_jump;
wire is_load;
wire is_store;
wire is_add_sub;
wire is_mul;
wire [ADDR_WIDTH-1:0] jump_addr;
wire is_CNN;
wire [8:0] CNN_info;
wire rs1_rd_same, rs2_rd_same;

assign opcode = fet2dec_instr[15:13];
assign is_branch = opcode == 3'b100;
assign is_jump = opcode == 3'b101;
assign is_load = opcode == 3'b010;
assign is_store = opcode == 3'b011;
assign is_add_sub = opcode == 3'b000; 
assign is_mul = opcode == 3'b001;
assign is_CNN = opcode == 3'b111;
assign CNN_info = {fet2dec_instr[12:7], fet2dec_instr[2:0]}; 
assign jump_addr = {19'b0, fet2dec_instr[12:0]};

assign dec2rf_rs = fet2dec_instr[12:9];
assign dec2rf_rt = fet2dec_instr[8:5];

assign rs1_rd_same = (dec2rf_rs == dec2exe_rd) && (!is_jump);
assign rs2_rd_same = (dec2rf_rt == dec2exe_rd) && (is_add_sub || is_mul || is_branch || is_CNN);
assign is_load_hazard_o = (rs1_rd_same || rs2_rd_same) && dec_is_load;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dec2exe_rd <= 4'b0;
        dec2exe_pc <= 32'b0;
        dec_is_branch <= 1'b0;
        // dec_is_jump <= 1'b0;
        dec_is_load <= 1'b0;
        dec_is_store <= 1'b0;
        dec_is_add <= 1'b0;
        dec_is_sub <= 1'b0;
        dec_is_mul <= 1'b0;
        dec_imm <= 5'b0;
        // dec2pcu_jump_addr <= 32'b0;
        dec_wb <= 1'b0;
        dec2exe_rs <= 4'b0;
        dec2exe_rt <= 4'b0;
        dec_is_CNN <= 1'b0;
        dec_CNN_info <= 9'b0;
        dec2exe_rs1_data <= 0;
        dec2exe_rs2_data <= 0;
    end
    else if(stall_i) begin
        dec2exe_rd <= dec2exe_rd;
        dec2exe_pc <= dec2exe_pc;
        dec_is_branch <= dec_is_branch;
        // dec_is_jump <= dec_is_jump;
        dec_is_load <= dec_is_load;
        dec_is_store <= dec_is_store;
        dec_is_add <= dec_is_add;
        dec_is_sub <= dec_is_sub;
        dec_is_mul <= dec_is_mul;
        dec_imm <= dec_imm;
        // dec2pcu_jump_addr <= dec2pcu_jump_addr;
        dec_wb <= dec_wb;
        dec2exe_rs <= dec2exe_rs;
        dec2exe_rt <= dec2exe_rt;
        dec_is_CNN <= dec_is_CNN;
        dec_CNN_info <= dec_CNN_info;
        dec2exe_rs1_data <= dec2exe_rs1_data;
        dec2exe_rs2_data <= dec2exe_rs2_data;
    end
    else if(flush_i) begin
        dec2exe_rd <= 4'b0;
        dec2exe_pc <= 32'hFFFFFFFF;
        dec_is_branch <= 1'b0;
        // dec_is_jump <= 1'b0;
        dec_is_load <= 1'b0;
        dec_is_store <= 1'b0;
        dec_is_add <= 1'b0;
        dec_is_sub <= 1'b0;
        dec_is_mul <= 1'b0;
        dec_imm <= 5'b0;
        // dec2pcu_jump_addr <= 32'b0;
        dec_wb <= 1'b0;
        dec2exe_rs <= 4'b0;
        dec2exe_rt <= 4'b0;
        dec_is_CNN <= 1'b0;
        dec_CNN_info <= 9'b0;
        dec2exe_rs1_data <= 0;
        dec2exe_rs2_data <= 0;
    end
    else begin
        dec2exe_rd <= is_CNN ? fet2dec_instr[6:3] :
                     is_load || is_store ? dec2rf_rt : fet2dec_instr[4:1];
        dec2exe_pc <= fet2dec_pc;
        dec_is_branch <= is_branch;
        // dec_is_jump <= is_jump;
        dec_is_load <= is_load;
        dec_is_store <= is_store;
        dec_is_add <= is_add_sub & ~fet2dec_instr[0];
        dec_is_sub <= is_add_sub & fet2dec_instr[0];
        dec_is_mul <= is_mul;
        dec_imm <= fet2dec_instr[4:0];
        // dec2pcu_jump_addr <= jump_addr;
        dec_wb <=  is_load | is_add_sub | is_mul | is_CNN;
        dec2exe_rs <= dec2rf_rs;
        dec2exe_rt <= dec2rf_rt;
        dec_is_CNN <= is_CNN;
        dec_CNN_info <= CNN_info;
        dec2exe_rs1_data <= rs1_data;
        dec2exe_rs2_data <= rs2_data;
    end
end

assign dec2pcu_jump_addr = jump_addr;
assign dec_is_jump = is_jump;

endmodule

module reg_file #(parameter DATA_WIDTH_data = 8)
(
    // System signals
    input clk,
    input rst_n,

    input [3:0] rs1_addr_i, // source register 1 address
    input [3:0] rs2_addr_i, // source register 2 address
    input we_i,          // write enable signal
    input [3:0] write_addr_i,  // destination register address

    input [DATA_WIDTH_data-1:0] write_data_i, // data to write to the destination register

    output   [DATA_WIDTH_data-1:0] rs1_data_o, // data from source register 1
    output   [DATA_WIDTH_data-1:0] rs2_data_o  // data from source register 2
);

reg signed [7:0] reg_file    [0:15];    // Registor File for Microcontroller
integer i;
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        for(i = 0; i < 16; i = i + 1) begin
            reg_file[i] <=  8'b0;
        end
    end else
    begin
        if(we_i) reg_file[write_addr_i] <= write_data_i;
    end
end

// always @(posedge clk or negedge rst_n)
// begin
//     if (!rst_n)
//     begin
//         rs1_data_o <= 0;
//         rs2_data_o <= 0;
//     end
//     else
//     begin
//         rs1_data_o <= reg_file[rs1_addr_i];
//         rs2_data_o <= reg_file[rs2_addr_i];
//     end
// end
   assign     rs1_data_o = reg_file[rs1_addr_i];
   assign     rs2_data_o = reg_file[rs2_addr_i];
endmodule

module execution #(parameter ADDR_WIDTH = 32, DATA_WIDTH_data = 8)
(
    // System signals
    input clk,
    input rst_n,
    input stall_i,
    // input flush_i,
    // from decode
    input [ADDR_WIDTH-1:0] dec2exe_pc,
    input dec_is_branch,
    input dec_is_load,
    input dec_is_store,
    input dec_is_add,
    input dec_is_sub,
    input dec_is_mul,
    input dec_wb,
    input  [4:0] dec_imm,
    input [3:0] dec2exe_rd,
    input dec_is_CNN,

    // from/to CNN
    input CNN_done,
    input [1:0] CNN2exe_result,
    // from reg_file
    input  [DATA_WIDTH_data-1:0] rf2exe_rs1_data,
    input  [DATA_WIDTH_data-1:0] rf2exe_rs2_data,

    // to pcu
    output  exe_branch_taken,
    output  [ADDR_WIDTH-1:0] exe2pcu_branch_addr,

    // to memory
    output reg exe2mem_load,
    output reg exe2mem_store,
    output reg exe2mem_wb,
    output reg  [DATA_WIDTH_data-1:0] exe2mem_reg_data,
    output reg  [DATA_WIDTH_data-1:0] exe2mem_alu_result,
    output reg [ADDR_WIDTH-1:0] exe2mem_addr,
    output reg [ADDR_WIDTH-1:0] exe2mem_pc,
    output reg [3:0] exe2mem_rd,
    output reg   exe2mem_mem2reg_mux,

    output           CNN_stall_o
);
// small alu
wire  [ADDR_WIDTH-1:0] alu_rs1, alu_rs2;
wire  [ADDR_WIDTH-1:0] alu_result;
wire [1:0] alu_op;

reg exe_is_CNN;
assign CNN_stall_o = dec_is_CNN && !CNN_done;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        // exe_branch_taken <= 1'b0;
        // exe2pcu_branch_addr <= 32'b0;
        exe2mem_load <= 1'b0;
        exe2mem_store <= 1'b0;
        exe2mem_wb <= 1'b0;
        exe2mem_reg_data <= 8'b0;
        exe2mem_alu_result <= 8'b0;
        exe2mem_addr <= 32'b0;
        exe2mem_pc <= 32'b0;
        exe2mem_rd <= 4'b0;
        exe2mem_mem2reg_mux <= 1'b0;
        exe_is_CNN <= 1'b0;
    end
    else if(stall_i) begin
        // exe_branch_taken <= exe_branch_taken;
        // exe2pcu_branch_addr <= exe2pcu_branch_addr;
        exe2mem_load <= exe2mem_load;
        exe2mem_store <= exe2mem_store;
        exe2mem_wb <= exe2mem_wb;
        exe2mem_reg_data <= exe2mem_reg_data;
        exe2mem_alu_result <= exe2mem_alu_result;
        exe2mem_addr <= exe2mem_addr;
        exe2mem_pc <= exe2mem_pc;
        exe2mem_rd <= exe2mem_rd;
        exe2mem_mem2reg_mux <= exe2mem_mem2reg_mux;
        exe_is_CNN <= exe_is_CNN;
    end
    // else if(flush_i) begin
    //     // exe_branch_taken <= 1'b0;
    //     // exe2pcu_branch_addr <= 32'b0;
    //     exe2mem_load <= 1'b0;
    //     exe2mem_store <= 1'b0;
    //     exe2mem_wb <= 1'b0;
    //     exe2mem_reg_data <= 8'b0;
    //     exe2mem_alu_result <= 8'b0;
    //     exe2mem_addr <= 32'b0;
    //     exe2mem_pc <= 32'hFFFFFFFF;
    //     exe2mem_rd <= 4'b0;
    //     exe2mem_mem2reg_mux <= 1'b0;
    //     exe_is_CNN <= 1'b0;
    // end
    else begin
        // exe_branch_taken <= rf2exe_rs1_data == rf2exe_rs2_data && dec_is_branch;
        // exe2pcu_branch_addr <= alu_result + 1;
        exe2mem_load <= dec_is_load;
        exe2mem_store <= dec_is_store;
        exe2mem_wb <= dec_wb;
        exe2mem_reg_data <= rf2exe_rs2_data;
        exe2mem_alu_result <= alu_result[7:0];
        exe2mem_addr <= alu_result + dec_imm;
        exe2mem_pc <= dec2exe_pc;
        exe2mem_rd <= dec2exe_rd;
        exe2mem_mem2reg_mux <= dec_is_add || dec_is_sub || dec_is_mul || dec_is_CNN;
        exe_is_CNN <= dec_is_CNN;
    end
end

// small alu
assign alu_rs1 = dec_is_branch ? dec2exe_pc : {{24{rf2exe_rs1_data[7]}}, rf2exe_rs1_data};
assign alu_rs2 = (dec_is_branch || dec_is_load || dec_is_store) ? {{27{dec_imm[4]}}, dec_imm} :  rf2exe_rs2_data;
assign alu_op = (dec_is_CNN) ? 2'b11 :  (dec_is_add || dec_is_branch) ? 2'b00 :
                (dec_is_sub) ? 2'b01 : 2'b10; 

assign alu_result = (alu_op == 2'b00) ? alu_rs1 + alu_rs2 :
                  (alu_op == 2'b01) ? alu_rs1 - alu_rs2 :
                  (alu_op == 2'b10) ? alu_rs1 * alu_rs2 : {27'b0, CNN2exe_result};
// branch
assign exe2pcu_branch_addr = alu_result + 1;
assign exe_branch_taken = rf2exe_rs1_data == rf2exe_rs2_data && dec_is_branch;
endmodule



module CNN #(parameter ADDR_WIDTH = 32, DATA_WIDTH = 8)
(
	// system signal
	clk            	,	
	rst_n          	,	
    dec_is_CNN    	,
    dec_CNN_info  	,
    out_done      	,
    out_data      	,

    // AXI4 IO
    araddr_m_inf_data,
    arvalid_m_inf_data,         
    arready_m_inf_data, 
    arlen_m_inf_data,

    rdata_m_inf_data,
    rvalid_m_inf_data,
    rlast_m_inf_data,
    rready_m_inf_data
);
input                       clk;
input                       rst_n;
input                       dec_is_CNN;
input   [8:0]               dec_CNN_info;
output reg                  out_done;
output reg    [1:0]  out_data;
// -----------------------------
// (4)	axi read address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     araddr_m_inf_data;
output reg [7:0]                arlen_m_inf_data;     // burst length 0~127
output reg                      arvalid_m_inf_data;
// 		src slave
input wire                     arready_m_inf_data;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
input wire [DATA_WIDTH-1:0]  rdata_m_inf_data;
input wire                   rlast_m_inf_data;
input wire                   rvalid_m_inf_data;
// 		src master
output reg                    rready_m_inf_data;
//==================================================================
// parameter & integer
//==================================================================
integer i;

//==================================================================
// Regs
//==================================================================
reg [6:0] input_cnt;

reg signed [7:0] image[0:3];
reg signed [7:0] weight_arr_reg0, weight_arr_reg1, weight_arr_reg2, weight_arr_reg3,
                    weight_arr_reg4, weight_arr_reg5, weight_arr_reg6, weight_arr_reg7,
                    weight_arr_reg8, weight_arr_reg9, weight_arr_reg10, weight_arr_reg11,
                    weight_arr_reg12, weight_arr_reg13, weight_arr_reg14, weight_arr_reg15;
reg [2:0] fcn_in_cnt;
reg [2:0] fcn_calc_cnt;

reg signed [7:0] weight_arr[0:31];

reg signed [7:0] img_reg0, img_reg1, img_reg2, img_reg3;

reg signed [15:0] tmp_mul_result[0:15];
reg signed [16:0] tmp_add_result1[0:7];
reg signed [17:0] tmp_add_result2[0:3];
reg signed [19:0] out_result[0:3]; 
reg signed [19:0] max_comp_0, max_comp_1, max_comp_2;
reg [1:0] max_index;

reg [2:0] compute_status, compute_status_next; // 0 idle, 1 first half, 2 second half, 3 select, 4output
localparam COMP_IDLE = 0, COMP_CAL_1 = 1, COMP_CAL_2 = 2, COMP_CALC_3 = 3, COMP_OUTPUT = 4;
// DMA part
localparam IDLE = 2'b00,
            READ = 2'b01, 
            WAIT_READ = 2'b10,
            WAIT_DONE = 2'b11;
reg [1:0] read_CNN_data_state; //  0 for kernel,1 for  weight , 2 for image 0,  3 for image 1
reg [1:0] state , next_state;
reg [31:0] addr_sel;
wire [7:0]  conv_out_ch1;
wire conv_out_valid_ch1;
wire [2:0] imgA, imgB;
wire [2:0] img_sel;
wire Kernel_sel, weight_sel, mode;
wire data_in_valid;
//==================================================================
// Design
//==================================================================

// CNN part
assign imgA = dec_CNN_info[8:6];
assign imgB = dec_CNN_info[5:3];
assign Kernel_sel = dec_CNN_info[2];
assign weight_sel = dec_CNN_info[1];
assign mode = dec_CNN_info[0];
assign data_in_valid = rready_m_inf_data && rvalid_m_inf_data;
// DMA part

//FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: begin
            if(dec_is_CNN) next_state = READ;
            else next_state = IDLE;
        end
        READ: begin
            if(arready_m_inf_data) next_state = WAIT_READ;
            else next_state = READ;
        end
        WAIT_READ: begin
            if(rvalid_m_inf_data && rlast_m_inf_data) 
                next_state = read_CNN_data_state == 3 ? WAIT_DONE : READ;
            else next_state = WAIT_READ;
        end
        WAIT_DONE: begin
            if(out_done) next_state = IDLE;
            else next_state = WAIT_DONE;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) read_CNN_data_state <= 0;
    else if(state == WAIT_READ && rvalid_m_inf_data && rlast_m_inf_data) 
        read_CNN_data_state <= read_CNN_data_state + 1;
    else read_CNN_data_state <= read_CNN_data_state;
end

assign img_sel = read_CNN_data_state == 2 ? imgA : imgB;

always @(*)begin
    if(read_CNN_data_state == 0) begin
        if(Kernel_sel) addr_sel = 32'h1252;
        else addr_sel = 32'h1240;
    end
    else if(read_CNN_data_state == 2 || read_CNN_data_state == 3)begin
        case(img_sel) 
            0: addr_sel = 32'h1000; // image 0
            1: addr_sel = 32'h1048; // image 1
            2: addr_sel = 32'h1090; // image 2
            3: addr_sel = 32'h10D8; // image 3
            4: addr_sel = 32'h1120; // image 4
            5: addr_sel = 32'h1168; // image 5
            6: addr_sel = 32'h11B0; // image 6
            7: addr_sel = 32'h11F8; // image 7
            default: addr_sel = 32'h1000; // default to image 0
        endcase
    end
    else begin
        if(weight_sel) addr_sel = 32'h1284; 
        else addr_sel = 32'h1264; 
    end
end

// (4)	axi read address channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arvalid_m_inf_data <= 1'b0;
    else if(state == READ && !arready_m_inf_data) arvalid_m_inf_data <= 1'b1;
    else arvalid_m_inf_data <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) araddr_m_inf_data <= 32'b0;
    else if(state == READ) araddr_m_inf_data <= addr_sel;
    else araddr_m_inf_data <= 32'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arlen_m_inf_data <= 8'b0;
    else if(state == READ) 
        arlen_m_inf_data <= read_CNN_data_state == 2 || read_CNN_data_state == 3 ? 71 :
                            read_CNN_data_state == 0 ? 17 : 31;
    else arlen_m_inf_data <= 8'b0;
end

// (5)	axi read data channel

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rready_m_inf_data <= 1'b0;
    else if(state == WAIT_READ) rready_m_inf_data <= 1'b1;
    else rready_m_inf_data <= 1'b0;
end

// Input Counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        input_cnt <= 0;
    end else if(data_in_valid && read_CNN_data_state == 1) begin
        if(input_cnt == 31) input_cnt <= 0;
        else input_cnt <= input_cnt + 1;
    end else  begin
        input_cnt <= input_cnt;
    end
end

// weight buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 32; i = i + 1) begin
            weight_arr[i] <= 0;
        end
    end else if(data_in_valid && read_CNN_data_state == 1) begin
        weight_arr[input_cnt] <= rdata_m_inf_data;
    end
    else begin
        for(i = 0; i < 32; i = i + 1) begin
            weight_arr[i] <= weight_arr[i];
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        weight_arr_reg0 <= 0;
        weight_arr_reg1 <= 0;
        weight_arr_reg2 <= 0;
        weight_arr_reg3 <= 0;
        weight_arr_reg4 <= 0;
        weight_arr_reg5 <= 0;
        weight_arr_reg6 <= 0;
        weight_arr_reg7 <= 0;
        weight_arr_reg8 <= 0;
        weight_arr_reg9 <= 0;
        weight_arr_reg10 <= 0;
        weight_arr_reg11 <= 0;
        weight_arr_reg12 <= 0;
        weight_arr_reg13 <= 0;
        weight_arr_reg14 <= 0;
        weight_arr_reg15 <= 0;
    end
    else
    if(compute_status == COMP_CAL_1) begin
        weight_arr_reg0 <= weight_arr[0];
        weight_arr_reg1 <= weight_arr[1];
        weight_arr_reg2 <= weight_arr[2];
        weight_arr_reg3 <= weight_arr[3];
        weight_arr_reg4 <= weight_arr[8];
        weight_arr_reg5 <= weight_arr[9];
        weight_arr_reg6 <= weight_arr[10];
        weight_arr_reg7 <= weight_arr[11];
        weight_arr_reg8 <= weight_arr[16];
        weight_arr_reg9 <= weight_arr[17];
        weight_arr_reg10 <= weight_arr[18];
        weight_arr_reg11 <= weight_arr[19];
        weight_arr_reg12 <= weight_arr[24];
        weight_arr_reg13 <= weight_arr[25];
        weight_arr_reg14 <= weight_arr[26];
        weight_arr_reg15 <= weight_arr[27];
    end
    else if(compute_status == COMP_CAL_2) begin 
        weight_arr_reg0 <= weight_arr[4];
        weight_arr_reg1 <= weight_arr[5];
        weight_arr_reg2 <= weight_arr[6];
        weight_arr_reg3 <= weight_arr[7];
        weight_arr_reg4 <= weight_arr[12];
        weight_arr_reg5 <= weight_arr[13];
        weight_arr_reg6 <= weight_arr[14];
        weight_arr_reg7 <= weight_arr[15];
        weight_arr_reg8 <= weight_arr[20];
        weight_arr_reg9 <= weight_arr[21];
        weight_arr_reg10 <= weight_arr[22];
        weight_arr_reg11 <= weight_arr[23];
        weight_arr_reg12 <= weight_arr[28];
        weight_arr_reg13 <= weight_arr[29];
        weight_arr_reg14 <= weight_arr[30];
        weight_arr_reg15 <= weight_arr[31];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        img_reg0 <= 0;
        img_reg1 <= 0;
        img_reg2 <= 0;
        img_reg3 <= 0;
    end else begin
        img_reg0 <= image[0];
        img_reg1 <= image[1];
        img_reg2 <= image[2];
        img_reg3 <= image[3];
    end
end

// INPUT FROM CONV_LAYER
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            image[i] <= 0;
        end
    end else if(conv_out_valid_ch1) begin
        image[fcn_in_cnt[1:0]] <= conv_out_ch1;
    end
end

// fcn_in_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcn_in_cnt <= 0;
    end else if(conv_out_valid_ch1) begin
        fcn_in_cnt <= fcn_in_cnt + 1;
    end 
    else begin
        fcn_in_cnt <= fcn_in_cnt;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) compute_status <= COMP_IDLE;
    else compute_status <= compute_status_next;
end

// compute_status
always @(*) begin
    case ( compute_status )
        COMP_IDLE :  compute_status_next = (fcn_in_cnt == 3) ? COMP_CAL_1 : (fcn_in_cnt == 7) ? COMP_CAL_2 : 0;
        COMP_CAL_1 :  compute_status_next = (fcn_calc_cnt == 4) ? COMP_IDLE : COMP_CAL_1;
        COMP_CAL_2 :  compute_status_next = (fcn_calc_cnt == 4) ? COMP_CALC_3 : COMP_CAL_2;
        COMP_CALC_3: compute_status_next = COMP_OUTPUT;
        COMP_OUTPUT :  compute_status_next = COMP_IDLE;
        default: compute_status_next = 0;
    endcase
end

// multiply
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 15; i = i + 1) begin
            tmp_mul_result[i] <= 0;
        end
    end else   begin
        tmp_mul_result[0] <= img_reg0 * weight_arr_reg0;
        tmp_mul_result[1] <= img_reg1 * weight_arr_reg1;
        tmp_mul_result[2] <= img_reg2 * weight_arr_reg2;
        tmp_mul_result[3] <= img_reg3 * weight_arr_reg3;

        tmp_mul_result[4] <= img_reg0 * weight_arr_reg4;
        tmp_mul_result[5] <= img_reg1 * weight_arr_reg5;
        tmp_mul_result[6] <= img_reg2 * weight_arr_reg6;
        tmp_mul_result[7] <= img_reg3 * weight_arr_reg7;
        tmp_mul_result[8] <= img_reg0 * weight_arr_reg8;
        tmp_mul_result[9] <= img_reg1 * weight_arr_reg9;
        tmp_mul_result[10] <= img_reg2 * weight_arr_reg10;
        tmp_mul_result[11] <= img_reg3 * weight_arr_reg11;
        tmp_mul_result[12] <= img_reg0 * weight_arr_reg12;
        tmp_mul_result[13] <= img_reg1 * weight_arr_reg13;
        tmp_mul_result[14] <= img_reg2 * weight_arr_reg14;
        tmp_mul_result[15] <= img_reg3 * weight_arr_reg15;
    end
end

// add 1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 8; i = i + 1) begin
            tmp_add_result1[i] <= 0;
        end
    end else   begin
        tmp_add_result1[0] <= tmp_mul_result[0] + tmp_mul_result[1];
        tmp_add_result1[1] <= tmp_mul_result[2] + tmp_mul_result[3];
        tmp_add_result1[2] <= tmp_mul_result[4] + tmp_mul_result[5];
        tmp_add_result1[3] <= tmp_mul_result[6] + tmp_mul_result[7];
        tmp_add_result1[4] <= tmp_mul_result[8] + tmp_mul_result[9];
        tmp_add_result1[5] <= tmp_mul_result[10] + tmp_mul_result[11];
        tmp_add_result1[6] <= tmp_mul_result[12] + tmp_mul_result[13];
        tmp_add_result1[7] <= tmp_mul_result[14] + tmp_mul_result[15];
    end
end

// add 2 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            tmp_add_result2[i] <= 0;
        end
    end else   begin
        tmp_add_result2[0] <= tmp_add_result1[0] + tmp_add_result1[1];
        tmp_add_result2[1] <= tmp_add_result1[2] + tmp_add_result1[3];
        tmp_add_result2[2] <= tmp_add_result1[4] + tmp_add_result1[5];
        tmp_add_result2[3] <= tmp_add_result1[6] + tmp_add_result1[7];
    end
end

// add 3
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 4; i = i + 1) begin
            out_result[i] <= 0;
        end
    end else  if(fcn_calc_cnt == 4) begin
        if(compute_status == COMP_CAL_1) begin
            out_result[0] <= tmp_add_result2[0];
            out_result[1] <= tmp_add_result2[1];
            out_result[2] <= tmp_add_result2[2];
            out_result[3] <= tmp_add_result2[3];
        end else if(compute_status == COMP_CAL_2) begin
            out_result[0] <= out_result[0] + tmp_add_result2[0];
            out_result[1] <= out_result[1] +tmp_add_result2[1];
            out_result[2] <= out_result[2] +tmp_add_result2[2];
            out_result[3] <= out_result[3] +tmp_add_result2[3];
        end
    end
end

assign max_comp_0 = out_result[0] > out_result[1] ? out_result[0] : out_result[1];
assign max_comp_1 = out_result[2] > out_result[3] ? out_result[2] : out_result[3];
assign max_comp_2 = max_comp_0 > max_comp_1 ? max_comp_0 : max_comp_1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) max_index <= 0;
    else
    max_index <= max_comp_2 == out_result[0] ? 0 :
                   max_comp_2 == out_result[1] ? 1 :
                   max_comp_2 == out_result[2] ? 2 : 3;
end
// assign max_index = max_comp_2 == out_result[0] ? 0 :
//                    max_comp_2 == out_result[1] ? 1 :
//                    max_comp_2 == out_result[2] ? 2 : 3;
// fcn calc cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fcn_calc_cnt <= 0;
    end else if((compute_status == COMP_CAL_1 || compute_status == COMP_CAL_2)) begin
        fcn_calc_cnt <= fcn_calc_cnt + 1;
    end 
    else begin
        fcn_calc_cnt <= 0;
    end
end

// output logic
always @( posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_done <= 0;
        out_data <= 0;
    end
    else if(compute_status == COMP_OUTPUT) begin
        out_done <= 1;
        out_data <= max_index;
    end
    else begin
        out_done <= 0;
        out_data <= 0;
    end
end

CONV_LAYER conv_layer_ch1 (
    .clk(clk),
    .rst_n(rst_n),
    .read_CNN_data_state(read_CNN_data_state),
    .in_valid(data_in_valid),
    .in_data(rdata_m_inf_data),
    .mode(mode),
    .out_valid(conv_out_valid_ch1),
    .out_data(conv_out_ch1)
);

endmodule

module CONV_LAYER (
    input                       clk,
    input                       rst_n,
    input                       in_valid,
    input   [1:0]  read_CNN_data_state,
    input       signed  [7:0]   in_data,
    input                       mode,
    output reg                  out_valid,
    output reg  signed  [7:0]  out_data
);
//==================================================================
// parameter & integer
//==================================================================

integer i;

//==================================================================
// Regs
//==================================================================
reg signed [7:0] input_image1 [0:35];
reg signed [7:0] kernel_arr1[0:8];
reg signed [7:0] kernel_arr2[0:8];

reg signed [7:0] tmp_in_imge1_0, tmp_in_imge1_1, tmp_in_imge1_2, tmp_in_imge1_3,
                    tmp_in_imge1_4, tmp_in_imge1_5, tmp_in_imge1_6, tmp_in_imge1_7,
                    tmp_in_imge1_8;
reg [6:0] input_cnt;
reg [17:0] kernel_input_cnt;
reg mode_reg;

reg [5:0] compute_idx;
reg [1:0] compute_inner_cnt;

reg prepare_done;
// stage 1 multiply
reg mul_done;
reg signed [15:0] mul_tmp_result1[0:8];
// stage 2 add 9 -> 3
reg add1_done;
reg signed [17:0] add_tmp_result_1_1;
reg signed [17:0] add_tmp_result_1_2;
reg signed [17:0] add_tmp_result_1_3;
// stage 3 add 3 -> 1
reg add2_done;
reg signed [19:0] add_tmp_result_1_4;

// stage 4 activation function
reg signed [20:0] activation_result;


//  store image
reg signed [19:0] store_result[0:15];
reg [5:0] store_cnt;
wire conv_done;

//  max pooling
wire signed [7:0] max0_0, max0_1, max0_01;
wire signed [7:0] max1_0, max1_1, max1_01;
wire signed [7:0] max2_0, max2_1, max2_01;
wire signed [7:0] max3_0, max3_1, max3_01;

reg signed [7:0] max_pooling_result[0:3]; 
reg max_pooling_done;

// output 
reg [1:0] output_cnt;
//==================================================================
// Wires
//==================================================================

wire more_than_127;
wire [5:0] input_cnt_mux;
wire calc_valid;
reg add2_done_reg;
reg kernel_mux;
wire signed [20:0] add_tmp_result, activation_tmp_result;
//==================================================================
// Design
//==================================================================

// Input Counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        input_cnt <= 0;
    end else if(input_cnt == 72) begin
        input_cnt <= 0;
    end
     else if(in_valid && (read_CNN_data_state == 2 || read_CNN_data_state == 3)) begin
        input_cnt <= input_cnt + 1;
    end else  begin
        input_cnt <= input_cnt;
    end
end

assign input_cnt_mux = input_cnt > 35 ? input_cnt - 36 : input_cnt;
// input image buffer   
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 36; i = i + 1) begin
            input_image1[i] <= 0;
        end
    end else if(in_valid && (read_CNN_data_state == 2 || read_CNN_data_state == 3)) begin
        input_image1[input_cnt_mux] <= in_data;
    end
end

// mode reg
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mode_reg <= 0;
    else  mode_reg <= mode;
end

// kernel input  counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        kernel_input_cnt <= 0;
    end 
    else if(in_valid && read_CNN_data_state == 0) begin
        if(kernel_input_cnt == 17) kernel_input_cnt <= 0;
        else kernel_input_cnt <= kernel_input_cnt + 1;
    end else  begin
        kernel_input_cnt <= kernel_input_cnt;
    end
end

// kernel buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1) begin
            kernel_arr1[i] <= 0;
            kernel_arr2[i] <= 0;
        end
    end else if(in_valid && read_CNN_data_state == 0) begin
        if(kernel_input_cnt < 9) kernel_arr1[kernel_input_cnt] <= in_data;
        else kernel_arr2[kernel_input_cnt - 9] <= in_data;
    end
end

// stage 1 multiply
assign calc_valid = (input_cnt > 20 && input_cnt <= 36) || (input_cnt > 56);

// compute_idx 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) compute_idx <= 0;
    else if(calc_valid) compute_idx <= compute_idx == 21 ? 0 : compute_inner_cnt == 3 ? compute_idx + 3 : compute_idx + 1;
    else compute_idx <= 0;
end

// compute_inner_cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) compute_inner_cnt <= 0;
    else if(calc_valid) compute_inner_cnt <= compute_inner_cnt + 1;
    else compute_inner_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tmp_in_imge1_0 <= 0;
        tmp_in_imge1_1 <= 0;
        tmp_in_imge1_2 <= 0;
        tmp_in_imge1_3 <= 0;
        tmp_in_imge1_4 <= 0;
        tmp_in_imge1_5 <= 0;
        tmp_in_imge1_6 <= 0;
        tmp_in_imge1_7 <= 0;
        tmp_in_imge1_8 <= 0;
    end else 
     begin
        tmp_in_imge1_0 <= input_image1[compute_idx];
        tmp_in_imge1_1 <= input_image1[compute_idx + 1];
        tmp_in_imge1_2 <= input_image1[compute_idx + 2];
        tmp_in_imge1_3 <= input_image1[compute_idx + 6];
        tmp_in_imge1_4 <= input_image1[compute_idx + 7];
        tmp_in_imge1_5 <= input_image1[compute_idx + 8];
        tmp_in_imge1_6 <= input_image1[compute_idx + 12];
        tmp_in_imge1_7 <= input_image1[compute_idx + 13];
        tmp_in_imge1_8 <= input_image1[compute_idx + 14];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 9; i = i + 1) begin
            mul_tmp_result1[i] <= 0;
        end
    end else  begin
        if(kernel_mux) begin
            mul_tmp_result1[0] <= tmp_in_imge1_0 * kernel_arr2[0];
            mul_tmp_result1[1] <= tmp_in_imge1_1 * kernel_arr2[1];
            mul_tmp_result1[2] <= tmp_in_imge1_2 * kernel_arr2[2];
            mul_tmp_result1[3] <= tmp_in_imge1_3 * kernel_arr2[3];
            mul_tmp_result1[4] <= tmp_in_imge1_4 * kernel_arr2[4];
            mul_tmp_result1[5] <= tmp_in_imge1_5 * kernel_arr2[5];
            mul_tmp_result1[6] <= tmp_in_imge1_6 * kernel_arr2[6];
            mul_tmp_result1[7] <= tmp_in_imge1_7 * kernel_arr2[7];
            mul_tmp_result1[8] <= tmp_in_imge1_8 * kernel_arr2[8];
        end else begin
            mul_tmp_result1[0] <= tmp_in_imge1_0 * kernel_arr1[0];
            mul_tmp_result1[1] <= tmp_in_imge1_1 * kernel_arr1[1];
            mul_tmp_result1[2] <= tmp_in_imge1_2 * kernel_arr1[2];
            mul_tmp_result1[3] <= tmp_in_imge1_3 * kernel_arr1[3];
            mul_tmp_result1[4] <= tmp_in_imge1_4 * kernel_arr1[4];
            mul_tmp_result1[5] <= tmp_in_imge1_5 * kernel_arr1[5];
            mul_tmp_result1[6] <= tmp_in_imge1_6 * kernel_arr1[6];
            mul_tmp_result1[7] <= tmp_in_imge1_7 * kernel_arr1[7];
            mul_tmp_result1[8] <= tmp_in_imge1_8 * kernel_arr1[8];
        end

    end
end

// mul done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) prepare_done <= 0;
    else if(calc_valid)  prepare_done <= 1;
    else prepare_done <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mul_done <= 0;
    else if(prepare_done) mul_done <= 1;
    else mul_done <= 0;
end

// stage 2 add 9 -> 3
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_tmp_result_1_1 <= 0;
        add_tmp_result_1_2 <= 0;
        add_tmp_result_1_3 <= 0;
    end else begin
        add_tmp_result_1_1 <= (mul_tmp_result1[0] + mul_tmp_result1[1]) + mul_tmp_result1[2];
        add_tmp_result_1_2 <= (mul_tmp_result1[3] + mul_tmp_result1[4]) + mul_tmp_result1[5];
        add_tmp_result_1_3 <= (mul_tmp_result1[6] + mul_tmp_result1[7]) + mul_tmp_result1[8];
    end
end

// add1 done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) add1_done <= 0;
    else if(mul_done)  add1_done <= 1;
    else add1_done <= 0;
end

// stage 3 add 3x1
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        add_tmp_result_1_4 <= 0;
    end else  begin
        add_tmp_result_1_4 <= (add_tmp_result_1_1 + add_tmp_result_1_2) + add_tmp_result_1_3;
    end
end

// add2 done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) add2_done <= 0;
    else if(add1_done) add2_done <= 1;
    else add2_done <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) add2_done_reg <= 0;
    else add2_done_reg <= add2_done;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) kernel_mux <= 0;
    else if(conv_done) kernel_mux <= 0;
    else if(add2_done != add2_done_reg && add2_done == 0) kernel_mux <= ~kernel_mux;
    else kernel_mux <= kernel_mux;
end

// stage 4 store image + activation function

assign add_tmp_result = store_cnt <= 15 ? store_result[store_cnt] + add_tmp_result_1_4 : 
                                            store_result[store_cnt - 16] + add_tmp_result_1_4;
assign activation_tmp_result = mode_reg ? (add_tmp_result[20] ? ~add_tmp_result + 1 : add_tmp_result) : 
                                            (add_tmp_result[20] ? 0 : add_tmp_result);

assign more_than_127 = activation_tmp_result[19] | activation_tmp_result[18] | activation_tmp_result[17] | activation_tmp_result[16];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0; i < 16; i = i + 1) begin
            store_result[i] <= 0;
        end
    end 
     else if(add2_done) begin
        if(store_cnt <= 15) store_result[store_cnt] <= add_tmp_result_1_4;
        else store_result[store_cnt - 16] <= more_than_127 ? 20'd127 : {13'b0, activation_tmp_result[15:9]};
    end
end

// store cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) store_cnt <= 0;
    else if(output_cnt == 3) store_cnt <= 0;
    else if(add2_done) begin
        store_cnt <= store_cnt + 1;
    end
    else store_cnt <= store_cnt;
end

assign conv_done = store_cnt == 32 ? 1 : 0;

// stage 6 max pooling

assign max0_0 = store_result[0][7:0] > store_result[1][7:0] ? store_result[0][7:0] : store_result[1][7:0];
assign max0_1 = store_result[4][7:0] > store_result[5][7:0] ? store_result[4][7:0] : store_result[5][7:0];
assign max0_01 = max0_0 > max0_1 ? max0_0 : max0_1;

assign max1_0 = store_result[2][7:0] > store_result[3][7:0] ? store_result[2][7:0] : store_result[3][7:0];
assign max1_1 = store_result[6][7:0] > store_result[7][7:0] ? store_result[6][7:0] : store_result[7][7:0];
assign max1_01 = max1_0 > max1_1 ? max1_0 : max1_1;

assign max2_0 = store_result[8][7:0] > store_result[9][7:0] ? store_result[8][7:0] : store_result[9][7:0];
assign max2_1 = store_result[12][7:0] > store_result[13][7:0] ? store_result[12][7:0] : store_result[13][7:0];
assign max2_01 = max2_0 > max2_1 ? max2_0 : max2_1;

assign max3_0 = store_result[10][7:0] > store_result[11][7:0] ? store_result[10][7:0] : store_result[11][7:0];
assign max3_1 = store_result[14][7:0] > store_result[15][7:0] ? store_result[14][7:0] : store_result[15][7:0];
assign max3_01 = max3_0 > max3_1 ? max3_0 : max3_1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        max_pooling_result[0] <= 0;
        max_pooling_result[1] <= 0;
        max_pooling_result[2] <= 0;
        max_pooling_result[3] <= 0;
    end else begin
        max_pooling_result[0] <= max0_01;
        max_pooling_result[1] <= max1_01;
        max_pooling_result[2] <= max2_01;
        max_pooling_result[3] <= max3_01;
    end
end

// max pooling done
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) max_pooling_done <= 0;
    else if(output_cnt == 3) max_pooling_done <= 0;
    else if(conv_done) max_pooling_done <= 1;
    else max_pooling_done <= max_pooling_done;
end

// output
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        out_data <= 0;
    end else if(max_pooling_done) begin
        out_valid <= 1;
        out_data <= max_pooling_result[output_cnt];
    end else begin
        out_valid <= 0;
        out_data <= 0;
    end
end

// output cnt
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) output_cnt <= 0;
    else if(max_pooling_done) output_cnt <= output_cnt + 1;
    else output_cnt <= 0;
end

endmodule

module memory#(parameter ADDR_WIDTH = 32, DATA_WIDTH = 8)
(
	// system signal
	clk            	,	
	rst_n          	,	
    stall_i         ,	
    stall_instr_fetch_i,

    stall_data_fetch_o,
    // from execution
    exe2mem_load,
    exe2mem_store,
    exe2mem_wb,
    exe2mem_reg_data,
    exe2mem_alu_result,
    exe2mem_addr,
    exe2mem_pc,
    exe2mem_rd,
    exe2mem_mem2reg_mux,

    // to write back
    mem2wb_mem_data,
    mem2wb_alu_result,
    mem2wb_wb,
    mem2wb_rd,
    mem2wb_mem2reg_mux,
    mem2wb_pc,

	// AXI4 IO
    awaddr_m_inf_data,
    awvalid_m_inf_data,
    awready_m_inf_data,
    awlen_m_inf_data,     

    wdata_m_inf_data,
    wvalid_m_inf_data,
    wlast_m_inf_data,
    wready_m_inf_data,
                
    
    bresp_m_inf_data,
    bvalid_m_inf_data,
    bready_m_inf_data,
                
    araddr_m_inf_data,
    arvalid_m_inf_data,         
    arready_m_inf_data, 
    arlen_m_inf_data,

    rdata_m_inf_data,
    rvalid_m_inf_data,
    rlast_m_inf_data,
    rready_m_inf_data,
    for_IO_stall
);
// ===============================================================
//  					Input / Output 
// ===============================================================
// << SDMA io port with system >>					
input clk, rst_n, stall_i, stall_instr_fetch_i;
output stall_data_fetch_o;
output for_IO_stall;
input exe2mem_load, exe2mem_store, exe2mem_wb;
input [DATA_WIDTH-1:0] exe2mem_reg_data;
input [DATA_WIDTH-1:0] exe2mem_alu_result;
input [ADDR_WIDTH-1:0] exe2mem_addr;
input [ADDR_WIDTH-1:0] exe2mem_pc;
input [3:0] exe2mem_rd;
input  exe2mem_mem2reg_mux;
// to write back
output reg [DATA_WIDTH-1:0] mem2wb_mem_data;
output reg [DATA_WIDTH-1:0] mem2wb_alu_result;
output reg mem2wb_wb;
output reg [3:0] mem2wb_rd;
output reg mem2wb_mem2reg_mux;
output reg [ADDR_WIDTH-1:0] mem2wb_pc;
// << AXI Interface wire connecttion for pseudo Data DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     awaddr_m_inf_data;
output reg [7:0]                awlen_m_inf_data;      // burst length 0~127
output reg                      awvalid_m_inf_data;
// 		src slave   
input wire                     awready_m_inf_data;
// -----------------------------
// (2)	axi write data channel 
// 		src master
output reg [DATA_WIDTH-1:0]  wdata_m_inf_data;
output reg                   wlast_m_inf_data;
output reg                   wvalid_m_inf_data;
// 		src slave
input wire                  wready_m_inf_data;
// -----------------------------
// (3)	axi write response channel 
// 		src slave
input wire  [1:0]           bresp_m_inf_data;
input wire                  bvalid_m_inf_data;
// 		src master 
output reg                   bready_m_inf_data;
// -----------------------------
// (4)	axi read address channel 
// 		src master
output reg [ADDR_WIDTH-1:0]     araddr_m_inf_data;
output reg [7:0]                arlen_m_inf_data;     // burst length 0~127
output reg                      arvalid_m_inf_data;
// 		src slave
input wire                     arready_m_inf_data;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
input wire [DATA_WIDTH-1:0]  rdata_m_inf_data;
input wire                   rlast_m_inf_data;
input wire                   rvalid_m_inf_data;
// 		src master
output reg                    rready_m_inf_data;

// ===============================================================
//  					Signal Declaration 
// ===============================================================
localparam IDLE = 3'b000,
            ANALYSIS = 3'b001,
            READ = 3'b010, 
            WRITE = 3'b011,
            WAIT_READ = 3'b100,
            WAIT_WRITE = 3'b101,
            FINISH_JOB = 3'b110,
            WAIT_STALL = 3'b111;

reg [2:0] state , next_state;

reg [DATA_WIDTH-1:0] data_to_dram;
reg [DATA_WIDTH-1:0] dram_data_buffer;
reg [ADDR_WIDTH-1:0] addr_buffer;

reg has_wready_m_inf, has_awready_m_inf;
reg mem2wb_bubble;
reg [ADDR_WIDTH-1:0] mem2wb_pc_reg;
// ===============================================================
//  					Start Your Design
// ===============================================================

//FSM
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
    case(state)
        IDLE: begin
            if(exe2mem_load) next_state = READ;
            else if(exe2mem_store) next_state = WRITE;
            else next_state = IDLE;
        end
        READ: begin
            if(arready_m_inf_data) next_state = WAIT_READ;
            else next_state = READ;
        end
        WRITE: begin
            if(has_wready_m_inf && has_awready_m_inf) next_state = WAIT_WRITE;
            else next_state = WRITE;
        end
        WAIT_READ: begin
            if(rvalid_m_inf_data && rlast_m_inf_data) next_state = FINISH_JOB;
            else next_state = WAIT_READ;
        end
        WAIT_WRITE: begin
            if(bvalid_m_inf_data) next_state = FINISH_JOB;
            else next_state = WAIT_WRITE;
        end
        FINISH_JOB: next_state = stall_i ? WAIT_STALL : IDLE;
        WAIT_STALL: next_state = stall_i ? WAIT_STALL : IDLE;
        default: next_state = IDLE;
    endcase
end

assign stall_data_fetch_o = (state == IDLE && (exe2mem_load || exe2mem_store)) || 
                            (state == READ || state == WRITE || state == WAIT_READ || state == WAIT_WRITE) ? 1'b1 : 1'b0;


// data_to_dram
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) data_to_dram <= 16'b0;
    else if(state == IDLE) data_to_dram <= exe2mem_reg_data;
    else data_to_dram <= data_to_dram;
end

// dram_data_buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) dram_data_buffer <= 16'b0;
    else if(state == WAIT_READ && rvalid_m_inf_data)dram_data_buffer <= rdata_m_inf_data;
    else dram_data_buffer <= dram_data_buffer;
end

//addr_buffer
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) addr_buffer <= 32'b0;
    // else if(state == IDLE) addr_buffer <= exe2mem_addr + 32'h1000;
    // else addr_buffer <= addr_buffer;
    else addr_buffer <= exe2mem_addr + 32'h1000;
end

// memory to write back
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        mem2wb_mem_data <= 8'b0;
        mem2wb_alu_result <= 8'b0;
        mem2wb_wb <= 1'b0;
        mem2wb_rd <= 4'b0;
        mem2wb_mem2reg_mux <= 1'b0;
        mem2wb_pc <= 32'hFFFFFFFE;
    end
    else if(stall_i) begin
        mem2wb_mem_data <= mem2wb_mem_data;
        mem2wb_alu_result <= mem2wb_alu_result;
        mem2wb_wb <= mem2wb_wb;
        mem2wb_rd <= mem2wb_rd;
        mem2wb_mem2reg_mux <= mem2wb_mem2reg_mux;
        mem2wb_pc <= mem2wb_pc;
    end
    else begin
        mem2wb_mem_data <= dram_data_buffer;
        mem2wb_alu_result <= exe2mem_alu_result;
        mem2wb_wb <= exe2mem_wb;
        mem2wb_rd <= exe2mem_rd;
        mem2wb_mem2reg_mux <= exe2mem_mem2reg_mux;
        mem2wb_pc <= exe2mem_pc;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) mem2wb_pc_reg <= 32'hFFFFFFFE;
    else mem2wb_pc_reg <= mem2wb_pc;
end

assign for_IO_stall = mem2wb_pc != mem2wb_pc_reg && mem2wb_pc != 32'hFFFFFFFF;
// << AXI Interface wire connecttion for pseudo DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awvalid_m_inf_data <= 1'b0;
    else if(state == WRITE && ((!awready_m_inf_data && !has_awready_m_inf))) awvalid_m_inf_data <= 1'b1;
    else awvalid_m_inf_data <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awaddr_m_inf_data <= 32'b0;
    else if(state == WRITE) awaddr_m_inf_data <= addr_buffer;
    else awaddr_m_inf_data <= 32'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) awlen_m_inf_data <= 8'b0;
    else if(state == WRITE) awlen_m_inf_data <= 8'b0;
    else awlen_m_inf_data <= 8'b0;
end

// (2)	axi write data channel 
// 		src master

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wvalid_m_inf_data <= 1'b0;
    else if(state == WRITE && (!has_wready_m_inf && !wready_m_inf_data))  wvalid_m_inf_data <= 1'b1;
    else wvalid_m_inf_data <= 1'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wdata_m_inf_data <= 8'b0;
    else if(state == WRITE) wdata_m_inf_data <= data_to_dram;
    else wdata_m_inf_data <= 8'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wlast_m_inf_data <= 1'b0;
    else if(state == WRITE && (!has_wready_m_inf && !wready_m_inf_data))  wlast_m_inf_data <= 1'b1;
    else wlast_m_inf_data <= 1'b0;
end
// (3)	axi write response channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) bready_m_inf_data <= 1'b0;
    else if(state == WAIT_WRITE && bvalid_m_inf_data) bready_m_inf_data <= 1'b1;
    else bready_m_inf_data <= 1'b0;
end

// (4)	axi read address channel
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arvalid_m_inf_data <= 1'b0;
    else if(state == READ && !arready_m_inf_data) arvalid_m_inf_data <= 1'b1;
    else arvalid_m_inf_data <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) araddr_m_inf_data <= 32'b0;
    else if(state == READ && !arready_m_inf_data) araddr_m_inf_data <= addr_buffer;
    else araddr_m_inf_data <= 32'b0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) arlen_m_inf_data <= 8'b0;
    else if(state == READ && !arready_m_inf_data) arlen_m_inf_data <= 8'b0;
    else arlen_m_inf_data <= 8'b0;
end

// (5)	axi read data channel

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) rready_m_inf_data <= 1'b0;
    else if(state == WAIT_READ && !rvalid_m_inf_data) rready_m_inf_data <= 1'b1;
    else rready_m_inf_data <= 1'b0;
end

// has_wready_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  has_wready_m_inf <= 1'b0;
    else if(state == WRITE) begin
        if(wready_m_inf_data) has_wready_m_inf <= 1'b1;
        else has_wready_m_inf <= has_wready_m_inf;
    end
    else has_wready_m_inf <= 1'b0;
end
// has_awready_m_inf
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  has_awready_m_inf <= 1'b0;
    else if(state == WRITE) begin
        if(awready_m_inf_data) has_awready_m_inf <= 1'b1;
        else has_awready_m_inf <= has_awready_m_inf;
    end
    else has_awready_m_inf <= 1'b0;
end

endmodule
