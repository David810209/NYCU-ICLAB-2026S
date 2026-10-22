`define CYCLE_TIME 12.0

module PATTERN (
    output reg [3:0]  drc_sel,
    output [18:0] shape0 ,
    output [18:0] shape1 ,
    output [18:0] shape2 ,
    output [18:0] shape3 ,
    output [18:0] shape4 ,
    output [18:0] shape5 ,
    output [18:0] shape6 ,
    output [18:0] shape7 ,
    output [18:0] shape8 ,
    output [18:0] shape9 ,
    output [18:0] shape10 ,
    output [18:0] shape11 ,
    output [18:0] shape12 ,
    output [18:0] shape13 ,
    output [18:0] shape14 ,
    output [18:0] shape15 ,
    input  [4:0]  drc_out
);

integer a, f_in, PATNUM = 1;
reg [4:0] golden_out;
reg [2:0] typ [0:15];
reg [3:0] llx [0:15];
reg [3:0] lly [0:15];
reg [3:0] urx [0:15];
reg [3:0] ury [0:15];
//================================================================
// clock
//================================================================
reg clk;
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// initial
//================================================================

initial begin
    f_in  = $fopen("../00_TESTBED/input.txt", "r");
    a = $fscanf(f_in, "%d", PATNUM);
    
    #10;
    release clk;

    drc_sel = 4'b0;
    //for(int z = 0; z < 16; z = z + 1) begin
    typ = '{16{3'b0}};
    llx = '{16{4'b0}};
    lly = '{16{4'b0}};
    urx = '{16{4'b0}};
    ury = '{16{4'b0}};
    //end
    //assign {typ[z],  llx[z],  lly[z],  urx[z],  ury[z]} = 19'b0;
    repeat(2) @(negedge clk);

    if(drc_out !== 0) begin
        $display("********************************************************");     
        $display("*                         FAIL!                        *");
        $display("*      Output should be zero when all input are 0      *"); //over max
        $display("********************************************************");
	    repeat(2) @(negedge clk);
	    $finish;
    end

    a = $fscanf(f_in, "%d", golden_out);
    a = $fscanf(f_in, "%d", drc_sel);
    for(int z = 0; z < 16; z = z + 1) a = $fscanf(f_in, "%d %d %d %d %d", typ[z],  llx[z],  lly[z],  urx[z],  ury[z]);
    @(negedge clk);

    for(int i_pat = 0; i_pat < PATNUM; i_pat = i_pat + 1) begin
        if(drc_out !== golden_out) begin
            $display("********************************************************");     
            $display("*                         FAIL!                        *");
            $display("*         Your output: %2d, Golden ouput: %2d            *", drc_out, golden_out); //over max
            $display("********************************************************");
            repeat(2) @(negedge clk);
            $finish;
        end
        a = $fscanf(f_in, "%d", golden_out);
        a = $fscanf(f_in, "%d", drc_sel);
        for(int z = 0; z < 16; z = z + 1) a = $fscanf(f_in, "%d %d %d %d %d", typ[z],  llx[z],  lly[z],  urx[z],  ury[z]);
        @(negedge clk);

        $display("\033[0;34mPASS PATTERN NO.%4d \033[m", i_pat);
    end
    repeat(5) @(negedge clk);
    display_pass;
    $finish; 
end

assign shape0 =  {typ[0],  llx[0],  lly[0],  urx[0],  ury[0]};
assign shape1 =  {typ[1],  llx[1],  lly[1],  urx[1],  ury[1]};
assign shape2 =  {typ[2],  llx[2],  lly[2],  urx[2],  ury[2]};
assign shape3 =  {typ[3],  llx[3],  lly[3],  urx[3],  ury[3]};
assign shape4 =  {typ[4],  llx[4],  lly[4],  urx[4],  ury[4]};
assign shape5 =  {typ[5],  llx[5],  lly[5],  urx[5],  ury[5]};
assign shape6 =  {typ[6],  llx[6],  lly[6],  urx[6],  ury[6]};
assign shape7 =  {typ[7],  llx[7],  lly[7],  urx[7],  ury[7]};
assign shape8 =  {typ[8],  llx[8],  lly[8],  urx[8],  ury[8]};
assign shape9 =  {typ[9],  llx[9],  lly[9],  urx[9],  ury[9]};
assign shape10 = {typ[10], llx[10], lly[10], urx[10], ury[10]};
assign shape11 = {typ[11], llx[11], lly[11], urx[11], ury[11]};
assign shape12 = {typ[12], llx[12], lly[12], urx[12], ury[12]};
assign shape13 = {typ[13], llx[13], lly[13], urx[13], ury[13]};
assign shape14 = {typ[14], llx[14], lly[14], urx[14], ury[14]};
assign shape15 = {typ[15], llx[15], lly[15], urx[15], ury[15]};

task display_pass;
begin
        $display("\n");
        $display("\n");
        $display("        ----------------------------               ");
        $display("        --                        --       |\__||  ");
        $display("        --  Congratulations !!    --      / O.O  | ");
        $display("        --                        --    /_____   | ");
        $display("        --  Simulation out!!     --   /^ ^ ^ \\  |");
        $display("        --                        --  |^ ^ ^ ^ |w| ");
        $display("        ----------------------------   \\m___m__|_|");
        $display("\n");
end
endtask

endmodule