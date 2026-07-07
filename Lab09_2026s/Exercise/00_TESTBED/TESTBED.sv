`timescale 1ns/1ps

`include "Usertype.sv"
`include "INF.sv"
`include "../00_TESTBED/PATTERN.svp"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "DSS.sv"
  `define CYCLE_TIME 2.9
`endif

`ifdef GATE
  `include "DSS_SYN.v"
  `include "DSS_Wrapper.sv"
  `define CYCLE_TIME 2.9
`endif

module TESTBED;
  
parameter simulation_cycle = `CYCLE_TIME;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 

  `ifdef RTL
	DSS      dut_p(.clk(SystemClock), .inf(inf.DSS_inf) );
  `endif
  
  `ifdef GATE
	DSS_svsim     dut_p(.clk(SystemClock), .inf(inf.DSS_inf) );
  `endif  
 //------ Generate Clock ------------
  initial begin
    SystemClock = 0;
	#200
    forever begin
      #(simulation_cycle/2.0)
        SystemClock = ~SystemClock;
    end
  end

//------ Dump FSDB File ------------  
initial begin
  `ifdef RTL
    // $fsdbDumpfile("DSS.fsdb");
    // $fsdbDumpvars(0,"+all");
    // $fsdbDumpSVA;
  `elsif GATE
    // $fsdbDumpfile("DSS_SYN.fsdb");  
    $sdf_annotate("DSS_SYN.sdf",dut_p.DSS);      
    // $fsdbDumpvars(0,"+all");
  `endif
end

endmodule