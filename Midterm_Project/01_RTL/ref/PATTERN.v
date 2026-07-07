`define RTL

`ifdef RTL
`define CYCLE_TIME 5.2
`endif
`ifdef GATE
`define CYCLE_TIME 5.2
`endif
// `define MAX_LATENCY 2000

`define MAX_LATENCY 2000000
`define PAT_NUM 3710    // DEMO
// `define PAT_NUM 20
// `define PAT_NUM 10      // DEBUG

`include "./pseudo_data_DRAM.v"
`include "./pseudo_inst_DRAM.v"

module PATTERN #(parameter ID_WIDTH=4, DATA_WIDTH_inst=16, DATA_WIDTH_data=8, ADDR_WIDTH=32) (
	// TOP IO 
	clk            	,	
	rst_n          	,	
	IO_stall        ,

	// AXI4 IO for Data DRAM
        awaddr_s_inf_data,
        awvalid_s_inf_data,
        awready_s_inf_data,
        awlen_s_inf_data,     

        wdata_s_inf_data,
        wvalid_s_inf_data,
        wlast_s_inf_data,
        wready_s_inf_data,
                    
        
        bresp_s_inf_data,
        bvalid_s_inf_data,
        bready_s_inf_data,
                    
        araddr_s_inf_data,
        arvalid_s_inf_data,         
        arready_s_inf_data, 
        arlen_s_inf_data,

        rdata_s_inf_data,
        rvalid_s_inf_data,
        rlast_s_inf_data,
        rready_s_inf_data,
    // AXI4 IO for Instruction DRAM
        araddr_s_inf_inst,
        arvalid_s_inf_inst,         
        arready_s_inf_inst, 
        arlen_s_inf_inst,
        
        rdata_s_inf_inst,
        rvalid_s_inf_inst,
        rlast_s_inf_inst,
        rready_s_inf_inst      

    );

// ===============================================================
//  					Input / Output 
// ===============================================================
// << TOP io port with system >>
output reg			  	clk,rst_n;
input 			        IO_stall;   
 
// << AXI Interface wire connecttion for pseudo Data DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
wire [ID_WIDTH-1:0]             awid_s_inf_data = 'd0;
input wire [ADDR_WIDTH-1:0]     awaddr_s_inf_data;
wire [2:0]                      awsize_s_inf_data = 'b011;   // 8-byte
wire [1:0]                      awburst_s_inf_data = 'b01;   // increment
input wire [7:0]                awlen_s_inf_data;      // burst lenght
input wire                      awvalid_s_inf_data;
// 		src slave   
output wire                     awready_s_inf_data;
// -----------------------------
// (2)	axi write data channel 
// 		src master
input wire [DATA_WIDTH_data-1:0]  wdata_s_inf_data;
input wire                   wlast_s_inf_data;
input wire                   wvalid_s_inf_data;
// 		src slave
output wire                  wready_s_inf_data;
// -----------------------------
// (3)	axi write response channel 
// 		src slave
wire  [ID_WIDTH-1:0]         bid_s_inf_data = 'd0;
output wire  [1:0]           bresp_s_inf_data;
output wire                  bvalid_s_inf_data;
// 		src master 
input wire                   bready_s_inf_data;
// -----------------------------
// (4)	axi read address channel 
// 		src master
wire [ID_WIDTH-1:0]             arid_s_inf_data = 'd0;
input wire [ADDR_WIDTH-1:0]     araddr_s_inf_data;
input wire [7:0]                arlen_s_inf_data; 
wire [2:0]                      arsize_s_inf_data = 'b011;   //  8-byte
wire [1:0]                      arburst_s_inf_data = 'b01;   // increment
input wire                      arvalid_s_inf_data;
// 		src slave
output wire                     arready_s_inf_data;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
wire [ID_WIDTH-1:0]           rid_s_inf_data = 'd0;
output wire [DATA_WIDTH_data-1:0]  rdata_s_inf_data;
wire [1:0]                    rresp_s_inf_data;
output wire                   rlast_s_inf_data;
output wire                   rvalid_s_inf_data;
// 		src master
input wire                    rready_s_inf_data;

// << AXI Interface wire connecttion for pseudo Instruction DRAM read/write >>
// (1) 	axi write address channel 
// 		src master
wire [ID_WIDTH-1:0]             awid_s_inf_inst = 'd0;
wire [ADDR_WIDTH-1:0]           awaddr_s_inf_inst;
wire [2:0]                      awsize_s_inf_inst = 'b011;   // 8-byte
wire [1:0]                      awburst_s_inf_inst = 'b01;   // increment
wire [7:0]                      awlen_s_inf_inst;
wire                            awvalid_s_inf_inst = 0;
// 		src slave   
wire                            awready_s_inf_inst;
// -----------------------------
// (2)	axi write data channel 
// 		src master
wire [DATA_WIDTH_inst-1:0]  wdata_s_inf_inst;
wire                   wlast_s_inf_inst;
wire                   wvalid_s_inf_inst = 0;
// 		src slave
wire                  wready_s_inf_inst;
// -----------------------------
// (3)	axi write response channel 
// 		src slave
wire  [ID_WIDTH-1:0]        bid_s_inf_inst = 'd0;
wire  [1:0]                 bresp_s_inf_inst;
wire                        bvalid_s_inf_inst;
// 		src master 
wire                        bready_s_inf_inst;
// -----------------------------
// (4)	axi read address channel 
// 		src master
wire [ID_WIDTH-1:0]             arid_s_inf_inst = 'd0;
input wire [ADDR_WIDTH-1:0]     araddr_s_inf_inst;
input wire [7:0]                arlen_s_inf_inst; 
wire [2:0]                      arsize_s_inf_inst = 'b011;   //  8-byte
wire [1:0]                      arburst_s_inf_inst = 'b01;   // increment
input wire                      arvalid_s_inf_inst;
// 		src slave
output wire                     arready_s_inf_inst;
// -----------------------------
// (5)	axi read data channel 
// 		src slave
wire [ID_WIDTH-1:0]           rid_s_inf_inst;
output wire [DATA_WIDTH_inst-1:0]  rdata_s_inf_inst;
wire [1:0]                    rresp_s_inf_inst;
output wire                   rlast_s_inf_inst;
output wire                   rvalid_s_inf_inst;
// 		src master
input wire                    rready_s_inf_inst;

// -------------------------//
//     DRAM Connection      //
//--------------------------//
pseudo_data_DRAM u_data_DRAM(

   .clk(clk),
   .rst_n(rst_n),

   .   awid_s_inf(   awid_s_inf_data),
   . awaddr_s_inf( awaddr_s_inf_data),
   . awsize_s_inf( awsize_s_inf_data),
   .awburst_s_inf(awburst_s_inf_data),
   .  awlen_s_inf(  awlen_s_inf_data),
   .awvalid_s_inf(awvalid_s_inf_data),
   .awready_s_inf(awready_s_inf_data),

   .  wdata_s_inf(  wdata_s_inf_data),
   .  wlast_s_inf(  wlast_s_inf_data),
   . wvalid_s_inf( wvalid_s_inf_data),
   . wready_s_inf( wready_s_inf_data),

   .    bid_s_inf(    bid_s_inf_data),
   .  bresp_s_inf(  bresp_s_inf_data),
   . bvalid_s_inf( bvalid_s_inf_data),
   . bready_s_inf( bready_s_inf_data),

   .   arid_s_inf(   arid_s_inf_data),
   . araddr_s_inf( araddr_s_inf_data),
   .  arlen_s_inf(  arlen_s_inf_data),
   . arsize_s_inf( arsize_s_inf_data),
   .arburst_s_inf(arburst_s_inf_data),
   .arvalid_s_inf(arvalid_s_inf_data),
   .arready_s_inf(arready_s_inf_data), 

   .    rid_s_inf(    rid_s_inf_data),
   .  rdata_s_inf(  rdata_s_inf_data),
   .  rresp_s_inf(  rresp_s_inf_data),
   .  rlast_s_inf(  rlast_s_inf_data),
   . rvalid_s_inf( rvalid_s_inf_data),
   . rready_s_inf( rready_s_inf_data) 
);


pseudo_inst_DRAM u_inst_DRAM(

   .clk(clk),
   .rst_n(rst_n),

   .   awid_s_inf(   awid_s_inf_inst),
   . awaddr_s_inf( awaddr_s_inf_inst),
   . awsize_s_inf( awsize_s_inf_inst),
   .awburst_s_inf(awburst_s_inf_inst),
   .  awlen_s_inf(  awlen_s_inf_inst),
   .awvalid_s_inf(awvalid_s_inf_inst),
   .awready_s_inf(awready_s_inf_inst),

   .  wdata_s_inf(  wdata_s_inf_inst),
   .  wlast_s_inf(  wlast_s_inf_inst),
   . wvalid_s_inf( wvalid_s_inf_inst),
   . wready_s_inf( wready_s_inf_inst),

   .    bid_s_inf(    bid_s_inf_inst),
   .  bresp_s_inf(  bresp_s_inf_inst),
   . bvalid_s_inf( bvalid_s_inf_inst),
   . bready_s_inf( bready_s_inf_inst),

   .   arid_s_inf(   arid_s_inf_inst),
   . araddr_s_inf( araddr_s_inf_inst),
   .  arlen_s_inf(  arlen_s_inf_inst),
   . arsize_s_inf( arsize_s_inf_inst),
   .arburst_s_inf(arburst_s_inf_inst),
   .arvalid_s_inf(arvalid_s_inf_inst),
   .arready_s_inf(arready_s_inf_inst), 

   .    rid_s_inf(    rid_s_inf_inst),
   .  rdata_s_inf(  rdata_s_inf_inst),
   .  rresp_s_inf(  rresp_s_inf_inst),
   .  rlast_s_inf(  rlast_s_inf_inst),
   . rvalid_s_inf( rvalid_s_inf_inst),
   . rready_s_inf( rready_s_inf_inst) 
);

// ===============================================================
//  					Parameter Declaration 
// ===============================================================
parameter CYCLE = `CYCLE_TIME;
parameter PAT_NUM = `PAT_NUM;    
parameter MAX_LATENCY = `MAX_LATENCY;

string reset_color          = "\033[1;0m";
string txt_black_prefix     = "\033[1;30m";
string txt_red_prefix       = "\033[1;31m";
string txt_green_prefix     = "\033[1;32m";
string txt_yellow_prefix    = "\033[1;33m";
string txt_blue_prefix      = "\033[1;34m";
string txt_magenta_prefix   = "\033[1;35m";
string txt_cyan_prefix      = "\033[1;36m";

string bkg_black_prefix     = "\033[40;1m";
string bkg_red_prefix       = "\033[41;1m";
string bkg_green_prefix     = "\033[42;1m";
string bkg_yellow_prefix    = "\033[43;1m";
string bkg_blue_prefix      = "\033[44;1m";
string bkg_white_prefix     = "\033[47;1m";
// ===============================================================
//  				    	signal 
// ===============================================================
integer i_pat;
integer i, k, l;
integer latency, total_latency;

reg [7:0] golden_data_DRAM [0:2047];
reg [15:0] golden_inst_DRAM [0:4095];
reg signed [7:0] golden_reg_file [0:15];
reg [15:0] _cur_inst;
reg signed [12:0] _cur_pc, _nxt_pc;

reg [2:0] _cur_op               ;
reg [3:0] _rs                   ;
reg [3:0] _rt                   ;
reg [3:0] _rd                   ;
reg _func                       ;
reg signed [4:0]  _immediate    ;
reg signed [12:0] _address      ;
reg [2:0] _imgA                 ;
reg [2:0] _imgB                 ;
reg [3:0] _rd_CNN               ;
reg _K                          ;
reg _W                          ; 
reg _mode                       ;

// Signals for CNN
reg [11:0] img1_head_addr, img2_head_addr;
reg [11:0] kernel_head_addr, weight_head_addr;
reg signed [7:0] in_data_ch1_reg    [0:1][0:35];
reg signed [7:0] in_data_ch2_reg    [0:1][0:35];
reg signed [7:0] kernel_ch1_reg     [0:8];
reg signed [7:0] kernel_ch2_reg     [0:8];
reg signed [7:0] weight_reg         [0:31];

reg signed [20:0]   ofmap_reg       [0:1][0:15];
reg signed [20:0]   pool_reg        [0:1][0:3];
reg signed [7:0]    flatten_reg     [0:7];

reg signed [18:0]   golden_out      [0:3];
reg signed [18:0]   out_reg         [0:9];
reg signed [7:0] _max_idx;
//================================================================
//                          clock
//================================================================
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
//                          MAIN
//================================================================
initial begin
    total_latency = 0;
    reset_task;
    set_env_task;
    
    // wait_MC_start_task;
    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1) begin
        latency = 0;
        wait_IO_stall_LOW_task;
        execute_task;   // golden execution
        $display("%0s Instruction NO. %4d executed | %0sLatency: %d%0s",txt_blue_prefix, i_pat, txt_green_prefix, latency, reset_color);
        if((i_pat % 10) == 9) begin
            check_DRAM_task;
        end 
        @(negedge clk);
    end
    you_pass_task;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)  total_latency <= 0;
    else    total_latency <= total_latency + 1;
end

always @(*) begin
    if(total_latency >= MAX_LATENCY) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("              Total Latency must not exceed MAX LATENCY %d    ", MAX_LATENCY);
        $display ("====================================================================");  
        $finish;
    end
end

task reset_task; begin
    integer iter_reg;
    rst_n = 'b1;

    //
    _cur_pc = 0;
    _nxt_pc = 0;
    for(iter_reg=0; iter_reg<16; iter_reg=iter_reg+1) begin
        golden_reg_file[iter_reg] = 'd0;
    end
    //

    force clk = 'b0;
    #CYCLE; rst_n = 'b0;
    repeat(3) #CYCLE;

    if(IO_stall !== 1'b1) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                IO_stall must be high after initial reset           ");
        $display ("====================================================================");  
        $finish;
    end    

    if(awvalid_s_inf_data !== 0 || wvalid_s_inf_data !== 0 || arvalid_s_inf_data !== 0 || arvalid_s_inf_inst !== 0) begin
        $display ("====================================================================");
        $display ("                                %0sFAIL!%0s                         ", txt_red_prefix, reset_color);
        $display ("                AXI signals must be low after initial reset         ");
        $display ("====================================================================");  
        $finish;
    end    
    
    #(0.5*CYCLE); rst_n = 'b1;
    #(5*CYCLE); release clk;
end endtask

task set_env_task; begin
    k = 0;
    for(i = 'h1000; i < 'h1800; i = i + 1) begin
        golden_data_DRAM[k] = u_data_DRAM.DRAM[i];
        k = k + 1;
    end
    for(i = 'h0; i < 'h1000; i = i + 1) begin
        golden_inst_DRAM[i] = u_inst_DRAM.DRAM[i];
    end
end endtask
    
task wait_IO_stall_LOW_task; begin
    while(IO_stall !== 'b0) begin
        latency = latency + 1;
        @(negedge clk);
    end
end endtask

task execute_task; begin
    integer mem_addr;
    _cur_pc = _nxt_pc;
    _cur_inst = golden_inst_DRAM[_cur_pc];
    _cur_op               = _cur_inst[15:13];
    _rs                   = _cur_inst[12:9];
    _rt                   = _cur_inst[8:5];
    _rd                   = _cur_inst[4:1];
    _func                 = _cur_inst[0];
    _immediate            = _cur_inst[4:0];
    _address              = _cur_inst[12:0];
    _imgA                 = _cur_inst[12:10];
    _imgB                 = _cur_inst[9:7];
    _rd_CNN               = _cur_inst[6:3];
    _K                    = _cur_inst[2];
    _W                    = _cur_inst[1]; 
    _mode                 = _cur_inst[0];

    _nxt_pc = _cur_pc + 1;
    mem_addr =  golden_reg_file[_rs] * _immediate + _immediate;
    case (_cur_op)
        3'b000 : begin      // ADD or SUB
            if(_cur_inst[0]) // SUB
                golden_reg_file[_rd] = golden_reg_file[_rs] - golden_reg_file[_rt];    
            else             // ADD
                golden_reg_file[_rd] = golden_reg_file[_rs] + golden_reg_file[_rt];    
        end 
        3'b001 : begin       // MULT
            golden_reg_file[_rd] = golden_reg_file[_rs] * golden_reg_file[_rt];                
        end
        3'b010 : begin       // Load
            golden_reg_file[_rt] = golden_data_DRAM[mem_addr];
        end
        3'b011 : begin       // Store
            golden_data_DRAM[mem_addr] = golden_reg_file[_rt];
        end
        3'b100 : begin       // Beq (Branch on equal)
            if(golden_reg_file[_rs] == golden_reg_file[_rt])    
                _nxt_pc = _cur_pc + 'd1 + _immediate;    
        end
        3'b101 : begin
            _nxt_pc = _address;
        end
    endcase
    
end endtask

task check_DRAM_task; begin
    // check dram status
    integer iter_dram;
    reg print_fail_flag;

    iter_dram = 0;
    print_fail_flag = 1;
    
    for(i = 'h1000; i < 'h1800; i = i + 1) begin
        if(golden_data_DRAM[iter_dram] !== u_data_DRAM.DRAM[i]) begin
            // fail, MEM status not correct
            if(print_fail_flag) begin
                $display ("=========================================================================");
                $display ("                              %0sFAIL!%0s                           ", txt_red_prefix, reset_color);
                $display ("                           Instruction NO. %04d                            ", i_pat);
                $display ("                        DRAM status is incorrect                           ");
                $display ("    ---------------------------------------------------------------------    ");
                $display ("           addr       |          idx  |       your_ans        golden_ans            ");
                $display ("    ---------------------------------------------------------------------    ");
                print_fail_flag = 0;
            end
            $display ("          0x%04H      |  %d  |      0x%h         0x%h        ", i, iter_dram, u_data_DRAM.DRAM[i], golden_data_DRAM[iter_dram]);
        end
        iter_dram = iter_dram + 1;
    end
    if(print_fail_flag == 0) begin
        $display ("    ---------------------------------------------------------------------");
        $display ("=========================================================================");
        $finish;
    end
    $display ("=====================    PASS DRAM CHECK     ==================");
end endtask

task you_pass_task; begin
    $display("                                           `:::::`                                                       ");
    $display("                                          .+-----++                                                      ");
    $display("                .--.`                    o:------/o                                                      ");
    $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
    $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
    $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
    $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
    $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
    $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
    $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
    $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
    $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
    $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
    $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
    $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
    $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
    $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
    $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
    $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
    $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
    $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
    $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
    $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
    $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
    $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
    $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.                                      ");
    $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
    $display("                        :yysssssssssssssssssssssssssssssssssyhysh-                                       ");
    $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
    $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:                                     ");
    $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
    $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
    $display("                       `s--------------------------::::::::-----:o                                       ");
    $display("                       +:----------------------------------------y`                                      ");
	$display("%0s======================================================================================================", txt_magenta_prefix);
	$display("                                     Congratulations!!");
    $display("                                    All Instructions Executed    ");
	$display("                                      Cycle time = %-2f ns", CYCLE);
	$display("                         Your execution cycles = %-4d cycles", total_latency);
	$display("========================================================================================================= %0s", reset_color);
	$finish;
end endtask

endmodule