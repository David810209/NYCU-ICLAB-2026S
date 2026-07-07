//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define INST_OPCODE_FIELD 15:13
`define INST_RS_FIELD     12: 9
`define INST_RT_FIELD      8: 5
`define INST_RD_FIELD      4: 1
`define INST_FUNC_FIELD    0: 0
`define INST_IMM_FIELD     4: 0
`define INST_ADDR_FIELD   12: 0


module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

//==============================================================================
// Local Parameter Declaration
//==============================================================================

// Instruction Opcode
localparam INST_ADD_SUB = 3'b000; // ADD or SUB
localparam INST_SLT_MUL = 3'b001; // SLT or MUL
localparam INST_LW      = 3'b010; // Load Word
localparam INST_SW      = 3'b011; // Store Word
localparam INST_BEQ     = 3'b100; // Branch if Equal
localparam INST_JUMP    = 3'b101; // Jump instruction

// Memory Operation Codes
localparam MEM_NONE  = 2'd0; // No memory operation
localparam MEM_READ  = 2'd2; // Memory read operation
localparam MEM_WRITE = 2'd3; // Memory write operation

// ALU Function Codes
localparam ADD = 2'b00; // Addition
localparam SUB = 2'b01; // Subtraction
localparam SLT = 2'b10; // Set Less Than
localparam MUL = 2'b11; // Multiplication

// Request Type
localparam INST_READ  = 2'd0; // Instruction read
localparam INST_WRITE = 2'd1; // Instruction write
localparam DATA_READ  = 2'd2; // Data read
localparam DATA_WRITE = 2'd3; // Data write

// State Machine States
localparam FETCH   		= 3'd0;
localparam DECODE  		= 3'd1;
localparam EXECUTE 		= 3'd2;
localparam EXECUTE_2 	= 3'd3;
localparam MEMORY  		= 3'd4;
localparam WRITE   		= 3'd5;
localparam FLUSH   		= 3'd6;

//==============================================================================
// Register and Wire Declaration
//==============================================================================

reg [31:0]  pc;         // Program Counter
reg [15:0]  ir;		 	// Instruction Register
wire        pc_legal;

// branch 
wire        branch_taken; // Branch taken signal
wire        jump_taken;  // Jump taken signal

// memory operation
reg  [1:0]  mem_op;

// write back data
reg  [15:0] write_back_data; // Data to write back to register
reg  		write_enable;    // Write enable signal for register file

// instruction decode signals
wire [2:0]  inst_opcode;  // Instruction opcode
wire [3:0]  inst_rs;      // Source register 1
wire [3:0]  inst_rt;      // Source register 2
wire [3:0]  inst_rd;      // Destination register
wire [4:0]  inst_imm;     // Immediate value
wire [15:0] signed_imm;   // Sign-extended immediate value
wire [31:0] signed_imm_ext; // Extended immediate value
wire [12:0] inst_addr;    // Address for jump instruction
reg         pc_sel;       // Program Counter select signal
reg  [3:0]  write_reg;

reg  [15:0]  rt;
reg  [15:0]  rs;         

// ALU signals
reg  [1:0]  alu_func;     // ALU function code
reg  [15:0] operand1;     // First operand for ALU
reg  [15:0] operand2;     // Second operand for ALU
wire [15:0] alu_result;   // ALU result
reg  [15:0] alu_result_reg; // Register to hold ALU result

// Multiplier signals
wire [31:0] mul_result; // Result of multiplication

// Cache signals
wire [31:0] cache_addr; 		// Cache address
wire  [1:0] cache_req_type; 	// Cache request type
reg  [15:0] cache_data_in; 		// Data to write into cache
wire        cache_in_valid; 	// Cache input valid signal
wire        cache_out_valid; 	// Cache output valid signal
wire [15:0] cache_data_out; 	// Data read from cache
wire        cache_flush;
reg   [3:0] flush_cnt;
reg         need_flush;

// FSM
reg [2:0] state;      			// FSM state
reg [2:0] next_state; 			// Next state for FSM

wire 	  fetch_to_decode;      // Transition from FETCH to DECODE
wire      execute_to_memory;
wire      execute_to_exexute_2;
wire      memory_to_write;  
wire	  write_to_flush;
wire      flush_to_fetch;
wire      execute_to_fetch;
wire      decode_to_fetch;
integer   i;

//================================================================================
// Cache Declaration
//================================================================================

cache u_cache(
	.clk			(clk),
	.rst_n			(rst_n),
	.flush          (cache_flush),
	.req_type		(cache_req_type),
	.data_in		(cache_data_in),
	.in_valid		(cache_in_valid),
	.addr			(cache_addr),
	.out_valid		(cache_out_valid),
	.data_out		(cache_data_out),
	.awid_m_inf		(awid_m_inf),
	.awaddr_m_inf	(awaddr_m_inf),
	.awsize_m_inf	(awsize_m_inf),
	.awburst_m_inf	(awburst_m_inf),
	.awlen_m_inf	(awlen_m_inf),
	.awvalid_m_inf	(awvalid_m_inf),
	.awready_m_inf	(awready_m_inf),
	.wdata_m_inf	(wdata_m_inf),
	.wlast_m_inf	(wlast_m_inf),
	.wvalid_m_inf	(wvalid_m_inf),
	.wready_m_inf	(wready_m_inf),
	.bid_m_inf		(bid_m_inf),
	.bresp_m_inf	(bresp_m_inf),
	.bvalid_m_inf	(bvalid_m_inf),
	.bready_m_inf	(bready_m_inf),
	.arid_m_inf		(arid_m_inf),
	.araddr_m_inf	(araddr_m_inf),
	.arlen_m_inf	(arlen_m_inf),
	.arsize_m_inf	(arsize_m_inf),
	.arburst_m_inf	(arburst_m_inf),
	.arvalid_m_inf	(arvalid_m_inf),
	.arready_m_inf	(arready_m_inf),
	.rid_m_inf		(rid_m_inf),
	.rdata_m_inf	(rdata_m_inf),
	.rresp_m_inf	(rresp_m_inf),
	.rlast_m_inf	(rlast_m_inf),
	.rvalid_m_inf	(rvalid_m_inf),
	.rready_m_inf	(rready_m_inf)
);

//================================================================================
// ALU Declaration
//================================================================================

ALU u_ALU(
	.func 		(alu_func),
	.operand1 	(operand1),
	.operand2 	(operand2),
	.result 	(alu_result)
);

//================================================================================
// Multiplier Declaration
//================================================================================

DW02_mult_2_stage #(16, 16) u_dw_mult (
	.A(operand1),
	.B(operand2),
	.TC(1'b1),
	.CLK(clk),
	.PRODUCT(mul_result)
);

//================================================================================
// Cache Logic
//================================================================================

assign cache_addr 		= (state == FETCH)   ? pc
						 :(state == MEMORY)  ? (alu_result_reg <<< 1) + 16'h1000
				  		 : 				       32'b0;

assign cache_req_type 	= (state == FETCH)  ? INST_READ
						 :(state == MEMORY) ? mem_op
				  		 : 				      2'b0;

assign cache_in_valid   = (state == FETCH && pc_legal) || (state == MEMORY);

assign cache_data_in = rt; // Data to write into cache

assign cache_flush = (state == FLUSH);

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		flush_cnt <= 4'd10;
	end else if (state == DECODE) begin
		flush_cnt <= (flush_cnt == 4'd10) ? 4'd1 : flush_cnt + 1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		need_flush <= 1'b0;
	end else if (state == DECODE) begin
		need_flush <= (flush_cnt == 4'd10);
	end else if (state == FLUSH) begin
		need_flush <= 1'b0; // Reset need_flush after flushing
	end
end

//=================================================================================
// Program Counter Logic
//=================================================================================

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		pc <= 32'h1000; // Reset PC to 0x00001000
	end else if (state == DECODE) begin
		pc <= (jump_taken) ? inst_addr
			:                pc;
	end else if (state == EXECUTE) begin
		pc <= (branch_taken) ? pc + 2 + (signed_imm_ext <<< 1)
			:                  pc + 2;
	end
end

assign pc_legal = (pc >= 32'h1000 && pc < 32'h2000);

//================================================================================
// Fethc Logic
//================================================================================

// Instruction register update Logic
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ir <= 16'd0;
	end else if (state == FETCH) begin
		ir <= (cache_out_valid) ? cache_data_out : ir; // Load instruction from cache
	end
end

//==================================================================================
// Decode Logic
//==================================================================================

assign inst_opcode = ir[`INST_OPCODE_FIELD]; // Extract opcode from instruction
assign inst_rs     = ir[`INST_RS_FIELD];     // Extract source register 1
assign inst_rt     = ir[`INST_RT_FIELD];     // Extract source register 2
assign inst_rd     = ir[`INST_RD_FIELD];     // Extract destination register
assign inst_imm    = ir[`INST_IMM_FIELD];    // Extract immediate value
assign inst_addr   = ir[`INST_ADDR_FIELD];   // Extract address for jump instruction

assign signed_imm = {{11{inst_imm[4]}}, inst_imm}; // Sign-extend immediate value
assign signed_imm_ext = {{27{inst_imm[4]}}, inst_imm};

// rs
always @(*) begin
	case(inst_rs)
		4'd0:  rs = core_r0; // r0
		4'd1:  rs = core_r1; // r1
		4'd2:  rs = core_r2; // r2
		4'd3:  rs = core_r3; // r3
		4'd4:  rs = core_r4; // r4
		4'd5:  rs = core_r5; // r5
		4'd6:  rs = core_r6; // r6
		4'd7:  rs = core_r7; // r7
		4'd8:  rs = core_r8; // r8
		4'd9:  rs = core_r9; // r9
		4'd10: rs = core_r10; // r10
		4'd11: rs = core_r11; // r11
		4'd12: rs = core_r12; // r12
		4'd13: rs = core_r13; // r13
		4'd14: rs = core_r14; // r14
		4'd15: rs = core_r15; // r15
	endcase
end

// rt
always @(*) begin
	case(inst_rt)
		4'd0:  rt = core_r0; // r0
		4'd1:  rt = core_r1; // r1
		4'd2:  rt = core_r2; // r2
		4'd3:  rt = core_r3; // r3
		4'd4:  rt = core_r4; // r4
		4'd5:  rt = core_r5; // r5
		4'd6:  rt = core_r6; // r6
		4'd7:  rt = core_r7; // r7
		4'd8:  rt = core_r8; // r8
		4'd9:  rt = core_r9; // r9
		4'd10: rt = core_r10; // r10
		4'd11: rt = core_r11; // r11
		4'd12: rt = core_r12; // r12
		4'd13: rt = core_r13; // r13
		4'd14: rt = core_r14; // r14
		4'd15: rt = core_r15; // r15
	endcase
end

// operand1
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		operand1 <= 16'd0;
	end else if (state == DECODE) begin
		operand1 <= rs;
	end
end

// operand2
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		operand2 <= 16'd0;
	end else if (state == DECODE) begin
		operand2 <= (ir[15:14] == 2'b01) ? signed_imm // Load/Store
					:                      rt;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		alu_func <= 2'd0;
	end else if (state == DECODE) begin
		case(inst_opcode)
			INST_ADD_SUB:	alu_func <= (ir[`INST_FUNC_FIELD]) ? SUB : ADD; // ADD or SUB
			INST_SLT_MUL:	alu_func <= (ir[`INST_FUNC_FIELD]) ? MUL : SLT; // MUL or SLT
			INST_LW:  	 	alu_func <= ADD; 								// LW (load word)
			INST_SW:  	 	alu_func <= ADD; 								// SW (store word)
			INST_BEQ:    	alu_func <= SUB; 								// BEQ (branch if equal)
			default: 		alu_func <= 2'd0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		pc_sel <= 2'b00;
	end else if (state == DECODE) begin
		case (inst_opcode)
			INST_BEQ:  pc_sel <= 1'b1;  // BEQ: branch if equal
			default:   pc_sel <= 1'b0;  // Default: PC + 1
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		mem_op <= MEM_NONE; // Reset memory operation to none
	end else if (state == DECODE) begin
		case (inst_opcode)
			INST_LW:  mem_op <= MEM_READ;  // LW: Load Word
			INST_SW:  mem_op <= MEM_WRITE; // SW: Store Word
			default:  mem_op <= MEM_NONE;  // No memory operation
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		write_enable <= 1'b0; // Reset write enable to false
	end else if (state == DECODE) begin
	    case (inst_opcode)
			INST_ADD_SUB: write_enable <= 1'b1;
			INST_SLT_MUL: write_enable <= 1'b1;
			INST_LW:      write_enable <= 1'b1;
			default:      write_enable <= 1'b0;
		endcase
	end
end

// Write register
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		write_reg <= 4'd0;
	end else if (state == DECODE) begin
		case(inst_opcode)
			INST_ADD_SUB: 	write_reg <= inst_rd; // Write to rd
			INST_SLT_MUL: 	write_reg <= inst_rd; // Write to rd
			INST_LW: 		write_reg <= inst_rt; // Write to rt
		endcase
	end
end

//================================================================================
// Execute Logic
//================================================================================

assign branch_taken = (alu_result == 16'd0) && pc_sel == 1'b1; // Branch taken if ALU result is zero and pc_sel is set for branch
assign jump_taken   = (inst_opcode == 3'b101); // Jump taken if pc_sel is set for jump

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		alu_result_reg <= 16'd0;
	end else if (state == EXECUTE) begin
		alu_result_reg <= alu_result;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		write_back_data <= 16'd0;
	end else if (state == EXECUTE) begin
		write_back_data <= alu_result;
	end else if (state == MEMORY) begin
		write_back_data <= cache_data_out;
	end else if (state == EXECUTE_2) begin
		write_back_data <= mul_result[15:0]; // Use lower 16 bits of multiplication result
	end
end

//================================================================================
// Write Logic
//================================================================================

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		// Reset all registers to zero
		core_r0  <= 16'd0;
		core_r1  <= 16'd0;
		core_r2  <= 16'd0;
		core_r3  <= 16'd0;
		core_r4  <= 16'd0;
		core_r5  <= 16'd0;
		core_r6  <= 16'd0;
		core_r7  <= 16'd0;
		core_r8  <= 16'd0;
		core_r9  <= 16'd0;
		core_r10 <= 16'd0;
		core_r11 <= 16'd0;
		core_r12 <= 16'd0;
		core_r13 <= 16'd0;
		core_r14 <= 16'd0;
		core_r15 <= 16'd0;
	end else if (state == WRITE && write_enable) begin
		case (write_reg)
			4'd0:  core_r0  <= write_back_data; // Write to r0
			4'd1:  core_r1  <= write_back_data; // Write to r1
			4'd2:  core_r2  <= write_back_data; // Write to r2
			4'd3:  core_r3  <= write_back_data; // Write to r3
			4'd4:  core_r4  <= write_back_data; // Write to r4
			4'd5:  core_r5  <= write_back_data; // Write to r5
			4'd6:  core_r6  <= write_back_data; // Write to r6
			4'd7:  core_r7  <= write_back_data; // Write to r7
			4'd8:  core_r8  <= write_back_data; // Write to r8
			4'd9:  core_r9  <= write_back_data; // Write to r9
			4'd10: core_r10 <= write_back_data; // Write to r10
			4'd11: core_r11 <= write_back_data; // Write to r11
			4'd12: core_r12 <= write_back_data; // Write to r12
			4'd13: core_r13 <= write_back_data; // Write to r13
			4'd14: core_r14 <= write_back_data; // Write to r14
			4'd15: core_r15 <= write_back_data; // Write to r15
		endcase	
	end
end

//================================================================================
// Output Logic
//================================================================================

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		IO_stall <= 1'b1;
	end else if (state != FETCH && next_state == FETCH) begin
		IO_stall <= 1'b0;
	end else if (state == FETCH && !pc_legal)begin
		IO_stall <= 1'b0;
	end else begin
		IO_stall <= 1'b1;
	end
end

//================================================================================
// Finite State Machine
//================================================================================

// FSM transition logic
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
    	state <= FETCH; // Reset to FETCH state
  	end else begin
    	state <= next_state; // Transition to next state
  	end
end

// FSM next state logic
always @(*) begin
  case(state)
    FETCH:     next_state = (fetch_to_decode) 	   ? DECODE
	                       :                    	 FETCH;
	DECODE:    next_state = (decode_to_fetch)      ? (flush_cnt == 4'd10) ? FLUSH : FETCH
						   : 						 EXECUTE;
	EXECUTE:   next_state = (execute_to_exexute_2) ? EXECUTE_2
			  			   :(execute_to_memory)    ? MEMORY
						   :(execute_to_fetch)     ? (need_flush) ? FLUSH : FETCH
	                       :                         WRITE;
	EXECUTE_2: next_state = WRITE;
	MEMORY:    next_state = (memory_to_write) 	   ? WRITE
	                      :                          MEMORY;
	WRITE:     next_state = (write_to_flush)       ? FLUSH
						   :                         FETCH;
	FLUSH:     next_state = (flush_to_fetch)       ? FETCH
	                       :                         FLUSH;
	default:   next_state = FETCH;
  endcase
end

assign fetch_to_decode      = (cache_out_valid);
assign execute_to_memory    = (mem_op != MEM_NONE);
assign memory_to_write      = cache_out_valid;
assign execute_to_exexute_2 = (alu_func == MUL);
assign write_to_flush       = (need_flush);
assign flush_to_fetch       = cache_out_valid;
assign execute_to_fetch     = (pc_sel != 1'b0);
assign decode_to_fetch      = jump_taken;

endmodule
















module ALU(
			   func,
			operand1,
			operand2,
			  result
);

//================================================================================
// Input and Output Declaration
//================================================================================

input  wire         [1:0]  func;      // ALU function code
input  wire signed [15:0] operand1; // First operand
input  wire signed [15:0] operand2; // Second operand
output reg  signed [15:0] result;   // ALU result

//================================================================================
// Local Parameter Declaration
//================================================================================

// ALU Function Codes
localparam ADD = 2'b00; // Addition
localparam SUB = 2'b01; // Subtraction
localparam SLT = 2'b10; // Set Less Than
localparam MUL = 2'b11; // Multiplication

//================================================================================
// ALU Logic
//================================================================================

always @(*) begin
	case(func)
		ADD: result = operand1 + operand2; 	// Addition
		SUB: result = operand1 - operand2; 	// Subtraction
		SLT: result = operand1 < operand2; 	// Set Less Than
		default: result = 16'd0; 			// Default case
	endcase
end

endmodule


















module cache(
                clk,
              rst_n,
// cache interface
              flush,
           req_type,
		    data_in,
           in_valid, 
               addr,
          out_valid,
           data_out,
// axi write address channel 
         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
// axi write data channel 
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
// axi write response channel
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
// axi read address channel 
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
      arready_m_inf, 
// axi read data channel
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

//===============================================================================
// Input and Output Declaration
//===============================================================================

input  wire        clk;
input  wire        rst_n;
// cache interface
input  wire        flush; 
input  wire [ 1:0] req_type;
input  wire        in_valid;
input  wire [15:0] data_in;
input  wire [31:0] addr;
output wire        out_valid;
output reg  [15:0] data_out;

// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;

//===============================================================================
// Local Paramter Declaration
//===============================================================================

// Request Type
localparam INST_READ  = 2'd0; // Instruction read
localparam INST_WRITE = 2'd1; // Instruction write
localparam DATA_READ  = 2'd2; // Data read
localparam DATA_WRITE = 2'd3; // Data write

// State Machine States
localparam IDLE         = 4'd0;
localparam WAIT_ARREADY = 4'd1;
localparam WAIT_RLAST   = 4'd2;
localparam READ_CACHE   = 4'd3;
localparam OUTPUT       = 4'd4;
localparam WAIT_AWREADY = 4'd5;
localparam WAIT_WLAST   = 4'd6;
localparam WAIT_BVALID  = 4'd7;
localparam WRITE_CACHE  = 4'd8;
localparam WAIT_SRAM    = 4'd9;

//===============================================================================
// Register and Wire Declaration
//===============================================================================

wire        inst_req;
wire        data_req;
reg         req_miss;
reg [31:0]  addr_reg;

// Write signals
reg  [15:0] read_data;
reg         dirty;
reg  [6:0]  write_min_index;
reg  [6:0]  write_max_index;
reg  [15:0] buffer [0:2];
wire [6:0]  write_index;
reg  [1:0]  wait_cnt;
reg  [6:0]  burst_len;

// AXI4 Read Address Channel
wire [ADDR_WIDTH-1:0] araddr_inst;
wire                  arvalid_inst;
wire                  arready_inst;

wire [ADDR_WIDTH-1:0] araddr_data;
wire                  arvalid_data;
wire                  arready_data;

// AXI4 Read Data Channel
wire                  rready_inst;
wire [DATA_WIDTH-1:0] rdata_inst;
wire                  rlast_inst;
wire                  rvalid_inst;

wire				  rready_data;
wire [DATA_WIDTH-1:0] rdata_data;
wire                  rlast_data;
wire                  rvalid_data;

// AXI4 Write Address Channel
wire [ADDR_WIDTH-1:0] awaddr_data;
wire                  awvalid_data;
wire                  awready_data;

// AXI4 Write Data Channel
reg [DATA_WIDTH-1:0]  wdata_data;
wire                  wlast_data;
wire                  wvalid_data;
wire                  wready_data;

// AXI4 Write Response Channel
wire [1:0]            bresp_data;
wire                  bvalid_data;
wire                  bready_data;

// Cache signals
wire        inst_cache_miss; // Cache miss signal
wire        data_cache_miss; // Cache miss signal
reg  [6:0]  cnt;        // Read counter for reading data from dram
wire [31:0] base_addr;       // Base address for cache

// SRAM signals
reg  [23:0] inst_sram_tag;  // Tag for SRAM
reg  [23:0] data_sram_tag;  // Tag for SRAM

wire [15:0] sram_data_out;  // Data read from SRAM
wire [7:0]  sram_addr;      // Address for SRAM
wire        sram_WEB;       // Write Enable for SRAM
wire [15:0] sram_data_in;   // Data to write into SRAM

// FSM State
reg [3:0] state, next_state;
wire      idle_to_wait_arready;
wire      idle_to_read_cache;
wire 	  idle_to_wait_awready;
wire      wait_arready_to_wait_rlast;
wire      wait_rlast_to_output;
wire 	  wait_awready_to_wait_wlast;
wire      wait_wlast_to_wait_bvalid;	
wire 	  wait_bvalid_to_output;	
wire      idle_to_output;
wire      idle_to_write_cache;
wire	  wait_bvalid_to_wait_arready;
wire      wait_sram_to_wait_wlast;
wire      wait_rlast_to_write_cache;

//================================================================================
// AXI4 Read Channel
//================================================================================

// AXI4 Read Address Channel
assign arid_m_inf		= {4'd0, 4'd0};					// Read address ID
assign araddr_m_inf		= {araddr_inst, araddr_data};	// Read address
assign arlen_m_inf      = {7'd127, 7'd127}; 			// Read Burst Lenght
assign arsize_m_inf     = {3'd1, 3'd1};					// Read Size (16 bits)	
assign arburst_m_inf	= {2'd1, 2'd1}; 				// Read Burst Type, 2'b01 = INCR
assign arvalid_m_inf	= {arvalid_inst, arvalid_data}; // Read address valid

// Instruction
assign araddr_inst 		= base_addr;
assign arvalid_inst 	= (state == WAIT_ARREADY && inst_req);
assign arready_inst 	= arready_m_inf[1]; // Read address ready for instruction

// Data
assign araddr_data 		= base_addr;
assign arvalid_data     = (state == WAIT_ARREADY && data_req);
assign arready_data 	= arready_m_inf[0]; // Read address ready for data

// AXI4 Read Data Channel
assign rready_m_inf 	= {rready_inst, rready_data}; // Read data ready

// Instruction	
assign rready_inst 		= (state == WAIT_RLAST && inst_req);
assign rdata_inst 		= rdata_m_inf[DATA_WIDTH*2-1:DATA_WIDTH]; 	// Read data for instruction
assign rlast_inst 		= rlast_m_inf[1]; 							// Read last signal for instruction
assign rvalid_inst 		= rvalid_m_inf[1]; 							// Read data valid for instruction

// Data	
assign rready_data 		= (state == WAIT_RLAST && data_req);
assign rdata_data 		= rdata_m_inf[DATA_WIDTH-1:0]; 	// Read data for data
assign rlast_data 		= rlast_m_inf[0]; 				// Read last signal for data
assign rvalid_data 		= rvalid_m_inf[0]; 				// Read data valid for data

//================================================================================
// AXI4 Write Channel
//================================================================================

// AXI4 Write Address Channel
assign awid_m_inf    	= 4'd0; 								// Write address ID
assign awaddr_m_inf     = awaddr_data; 							// Write address
assign awlen_m_inf      = burst_len; 							// Write Burst Length
assign awsize_m_inf     = 3'd1; 								// Write Size (16 bits)
assign awburst_m_inf    = 2'd1; 								// Write Burst Type, 2'b01 = INCR
assign awvalid_m_inf    = awvalid_data; 						// Write address valid

// Data
assign awaddr_data      = {data_sram_tag, write_min_index, 1'b0}; 
assign awvalid_data     = (state == WAIT_AWREADY);
assign awready_data     = awready_m_inf[0]; 

// AXI4 Write Data Channel
assign wdata_m_inf      = wdata_data; 	// Write data
assign wlast_m_inf      = wlast_data; 	// Write last signal
assign wvalid_m_inf     = wvalid_data; 	// Write data valid

// Data
assign wdata_data       = (cnt[6:1]) ? buffer[2] : buffer[0]; // Write data input
assign wlast_data       = (cnt == burst_len);  			      // Write last signal
assign wvalid_data      = (state == WAIT_WLAST); 		      // Write data valid signal
assign wready_data      = wready_m_inf[0]; 				       // Write data ready signal

// AXI4 Write Response Channel
assign bready_m_inf     = bready_data; // Write response ready

// Data
assign bready_data      = (state == WAIT_BVALID); 	// Write response ready signal
assign bvalid_data      = bvalid_m_inf[0]; 			// Write response valid signal
assign bresp_data       = bresp_m_inf; 				// Write response status

//================================================================================
// SRAM Logic
//================================================================================

reg rvalid_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rvalid_reg <= 1'b0; // Reset rvalid_reg
    end else begin
        rvalid_reg <= (rvalid_inst || rvalid_data); // Set rvalid_reg based on read data valid signals
    end
end

reg [15:0] rdata_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata_reg <= 16'd0; // Reset rdata_reg
    end else if (rvalid_inst) begin
        rdata_reg <= rdata_inst; // Update rdata_reg with instruction read data
    end else if (rvalid_data) begin
        rdata_reg <= rdata_data; // Update rdata_reg with data read data
    end
end

reg rlast_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rlast_reg <= 1'b0; // Reset rlast_reg
    end else begin
        rlast_reg <= rlast_inst || rlast_data; // Update rlast_reg with instruction read last signal
    end
end


SRAM u_SRAM (
	.clk      (clk),
	.addr     (sram_addr),
	.data_in  (sram_data_in),
	.WEB      (sram_WEB),
	.data_out (sram_data_out)
);

assign sram_addr    = (state == WAIT_RLAST)  ? {req_type[1], cnt}
					: (state == WAIT_AWREADY)? {1'b1, write_index}
					: (state == WAIT_WLAST)  ? {1'b1, write_index}
					: (state == WAIT_SRAM)   ? {1'b1, write_index}
					:                          {req_type[1], addr[7:1]};
assign sram_data_in = (state == WRITE_CACHE) ? data_in
					: 						   rdata_reg;
					
assign sram_WEB     = (state == WAIT_RLAST)  ? ~rvalid_reg
					: (state == WRITE_CACHE) ? 1'b0
					:                          1'b1;



//=================================================================================
// Cache Design Logic
//=================================================================================

assign inst_req = (req_type[1] == 1'b0);
assign data_req = (req_type[1] == 1'b1);

assign inst_cache_miss = (inst_sram_tag != addr[31:8]); // Check if inst cache miss occurs
assign data_cache_miss = (data_sram_tag != addr[31:8]); // Check if data cache miss occurs
assign base_addr       = {addr_reg[31:8], 8'd0}; // Base address for cache

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		burst_len <= 7'd0; // Reset burst length
	end else if (state == IDLE) begin
		burst_len <= write_max_index - write_min_index;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		inst_sram_tag <= 24'd0; // Reset SRAM tag
	end else if (state == WAIT_ARREADY && inst_req) begin
		inst_sram_tag <= base_addr[31:8]; // Update base address for cache
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_sram_tag <= 24'd0; // Reset SRAM tag
	end else if (state == WAIT_ARREADY && data_req) begin
		data_sram_tag <= base_addr[31:8]; // Update base address for cache
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cnt <= 7'd0;
	end else if (state == WAIT_RLAST) begin
		cnt <= (rvalid_reg) ? cnt + 1 : cnt; // Increment read counter if data is valid
	end else if (state == WAIT_WLAST) begin
		cnt <= (wready_data) ? cnt + 1 : cnt; // Increment write counter if data is ready
	end else begin
		cnt <= 7'd0; // Reset read counter
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		dirty <= 1'b0;
	end else if (state == WAIT_BVALID) begin
		dirty <= 1'b0;
	end else if (state == WRITE_CACHE) begin
		dirty <= 1'b1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		write_min_index <= 7'd127;
		write_max_index <= 7'd0;
	end else if (state == WRITE_CACHE) begin
		if (addr[7:1] < write_min_index) begin
			write_min_index <= addr[7:1]; // Update minimum index for write
		end
		if (addr[7:1] > write_max_index) begin
			write_max_index <= addr[7:1]; // Update maximum index for write
		end
	end else if (state == WAIT_BVALID) begin
		write_min_index <= 7'd127; // Reset minimum index
		write_max_index <= 7'd0;    // Reset maximum index
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		buffer[0] <= 16'd0; // Reset buffer
		buffer[1] <= 16'd0; // Reset buffer
		buffer[2] <= 16'd0; // Reset buffer
	end else if (state == WAIT_AWREADY) begin
		buffer[0] <= sram_data_out;
	end else if (state == WAIT_SRAM) begin
		buffer[2] <= sram_data_out;
		buffer[1] <= buffer[2];
	end else if (wready_data) begin
		buffer[2] <= sram_data_out;
		buffer[0] <= buffer[1];
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		wait_cnt <= 2'b0; // Reset write count
	end else if (state == WAIT_SRAM) begin
		wait_cnt <= wait_cnt + 1;
	end else begin
		wait_cnt <= 2'b0; // Reset write count
	end
end

assign write_index = (state == WAIT_AWREADY) ? write_min_index + cnt
					:(state == WAIT_SRAM)    ? write_min_index + cnt + 1 + wait_cnt
					: 						   write_min_index + cnt + 2;

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		req_miss <= 1'b0;
	end else if (state == IDLE && in_valid) begin
		req_miss <= (req_type == INST_READ && inst_cache_miss) || (req_type == DATA_READ && data_cache_miss);
	end else if (state == OUTPUT) begin
		req_miss <= 1'b0; // Reset request miss flag after output
	end
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		addr_reg <= 32'd0; // Reset address register
	end else if (in_valid) begin
		addr_reg <= addr; // Update address register with incoming address
	end
end

//=================================================================================
// Output Logic
//=================================================================================

assign out_valid = (state == OUTPUT);
assign data_out  = read_data; // Output data from read_data register


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		read_data <= 16'd0;
	end else if (state == WAIT_RLAST) begin
		read_data <= (cnt == addr[7:1] && rvalid_reg) ?  rdata_reg
		           :								     read_data;
	end else if (state == READ_CACHE) begin
		read_data <= sram_data_out;
	end
end

//================================================================================
// FSM Logic
//================================================================================

// FSM transition logic
always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
    	state <= IDLE; // Reset to IDLE state
  	end else begin
    	state <= next_state; // Transition to next state
  	end
end

// FSM next state logic
always @(*) begin
  	case(state)
    	IDLE: 			next_state = (idle_to_wait_arready) 		? WAIT_ARREADY
		      			            :(idle_to_read_cache)   		? READ_CACHE
			  			  		  	:(idle_to_wait_awready) 		? WAIT_AWREADY
									:(idle_to_write_cache) 		    ? WRITE_CACHE
		      			            :(idle_to_output)               ? OUTPUT
									: 								  IDLE;
		WAIT_ARREADY:	next_state = (wait_arready_to_wait_rlast) 	? WAIT_RLAST
		      			            : 								  WAIT_ARREADY;
		WAIT_RLAST:     next_state = (wait_rlast_to_output) 		? OUTPUT
		      			            : (wait_rlast_to_write_cache) 	? WRITE_CACHE
		      			            : 								  WAIT_RLAST;
		READ_CACHE:     next_state = OUTPUT;
		WAIT_AWREADY:	next_state = (wait_awready_to_wait_wlast) 	? WAIT_SRAM
		      			            : 								  WAIT_AWREADY;
		WAIT_SRAM:      next_state = (wait_sram_to_wait_wlast)      ? WAIT_WLAST
		      			            : 								  WAIT_SRAM;
		WAIT_WLAST:    next_state =  (wait_wlast_to_wait_bvalid) 	? WAIT_BVALID
		      			            : 								  WAIT_WLAST;
		WAIT_BVALID:    next_state =  (wait_bvalid_to_output) 	 	? OUTPUT
		      			            : (wait_bvalid_to_wait_arready) ? WAIT_ARREADY
		      			            : 								  WAIT_BVALID;
		WRITE_CACHE:    next_state = OUTPUT;
		OUTPUT:         next_state = IDLE;
		default:        next_state = IDLE; // Default case to prevent latches
  	endcase
end

assign idle_to_wait_arready 		= in_valid && ((inst_req  && inst_cache_miss) || (data_req && data_cache_miss && !dirty));
assign idle_to_read_cache   		= in_valid && ((inst_req   && !inst_cache_miss) || ((req_type == DATA_READ) && !data_cache_miss));
assign idle_to_write_cache          = in_valid && (req_type == DATA_WRITE  && !data_cache_miss);
assign idle_to_wait_awready 		= (in_valid && (data_req && data_cache_miss && dirty)) || (flush && dirty);
assign idle_to_output               = flush && !dirty;

assign wait_arready_to_wait_rlast 	= (arready_inst || arready_data);
assign wait_rlast_to_output 		= rlast_reg && (req_type != DATA_WRITE);
assign wait_rlast_to_write_cache    = rlast_reg && (req_type == DATA_WRITE);
assign wait_awready_to_wait_wlast 	= (awready_data);
assign wait_wlast_to_wait_bvalid 	= (wlast_data && wready_data);

assign wait_sram_to_wait_wlast      = (wait_cnt == 2'd2);

assign wait_bvalid_to_output		= (bvalid_data && flush);
assign wait_bvalid_to_wait_arready	= (bvalid_data && !flush);

endmodule
















module SRAM(
	input         clk,
	input  [7:0]  addr,
	input  [15:0] data_in,
	input         WEB,
	output [15:0] data_out
);

SRAM_256x16 u_SRAM_256x16
(
    .A0(addr[0]),   	.A1(addr[1]),   	.A2(addr[2]),        .A3(addr[3]),   	  .A4(addr[4]),  	   .A5(addr[5]),   		.A6(addr[6]),        .A7(addr[7]),
    .DO0(data_out[0]),  .DO1(data_out[1]),  .DO2(data_out[2]),   .DO3(data_out[3]),   .DO4(data_out[4]),   .DO5(data_out[5]),   .DO6(data_out[6]),   .DO7(data_out[7]),  
    .DO8(data_out[8]),  .DO9(data_out[9]),  .DO10(data_out[10]), .DO11(data_out[11]), .DO12(data_out[12]), .DO13(data_out[13]), .DO14(data_out[14]), .DO15(data_out[15]),
    .DI0(data_in[0]),   .DI1(data_in[1]),   .DI2(data_in[2]),    .DI3(data_in[3]),    .DI4(data_in[4]),    .DI5(data_in[5]),    .DI6(data_in[6]),    .DI7(data_in[7]),   
    .DI8(data_in[8]),   .DI9(data_in[9]),   .DI10(data_in[10]),  .DI11(data_in[11]),  .DI12(data_in[12]),  .DI13(data_in[13]),  .DI14(data_in[14]),  .DI15(data_in[15]),   
    .CK(clk),           .WEB(WEB),   	     .OE(1'b1), 	     .CS(1'b1)
);

endmodule