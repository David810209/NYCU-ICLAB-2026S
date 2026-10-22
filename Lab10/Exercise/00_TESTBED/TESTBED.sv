/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : TESTBED.sv
Module Name : TESTBED
Release version : v1.0 (Release Date: May-2026)
Author : Chia-Hsin Lee
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`timescale 1ns/1ps
`define CYCLE_TIME 20.0

`include "Usertype.sv"
`include "INF.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "DSS.sv"
  `include "PATTERN.sv"
  `include "CHECKER.sv"
`elsif COV
  `include "TA_DSS.sv"
  `include "PATTERN.sv"
  `include "CHECKER.sv"
`elsif ASSERT
  `include "TA_DSS.sv"
  `include "TA_PATTERN.sv"
  `include "CHECKER.sv"
`endif

module TESTBED;
  
parameter simulation_cycle = `CYCLE_TIME;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 
  CHECKER         check_inst(.clk(SystemClock), .inf(inf.CHECKER));
	DSS             dut_p(.clk(SystemClock), .inf(inf.DSS_inf) );

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
  $fsdbDumpfile("DSS.fsdb");
  $fsdbDumpvars(0,"+all");
  $fsdbDumpSVA;
end

endmodule