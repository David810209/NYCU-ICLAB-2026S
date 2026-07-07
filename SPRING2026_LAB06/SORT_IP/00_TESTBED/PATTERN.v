`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

module PATTERN #(parameter IP_WIDTH = 8)(
    output reg [IP_WIDTH*4-1:0] IN_character,
    output reg [IP_WIDTH*5-1:0] IN_weight,
    input      [IP_WIDTH*4-1:0] OUT_character
);
  reg a, b;
  initial $monitor("[MONITOR] time=%0t  a=%b  b=%b", $time, a, b);
  initial $strobe ("[STROBE]  time=%0t  a=%b  b=%b", $time, a, b);
   initial begin
    a = 0; b = 0;

    #10;
    a = 1;   // 同一時間步
    b = 1;   // 同一時間步

    #10;
    a = 0;

    #10;
    b = 0;

    #10;
    $finish;
  end
endmodule