module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

NDFF_syn U_NDFF_req(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn U_NDFF_ack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) sreq <= 1'b0;
    else if(sack) sreq <= 1'b0;
    else if(sready) sreq <= 1'b1;
    else sreq <= sreq;
end
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dack <= 1'b0;
    else if(dreq & !dbusy) dack <= 1'b1;
    else if(!dreq) dack <= 1'b0;
    else dack <= dack;
end
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n)begin
        dvalid <= 1'b0;
        dout <= 'd0;
    end
    else if(!dack & dreq & !dbusy)begin
        dvalid <= 1'b1;
        dout <= din;
    end
    else begin
        dvalid <= 1'b0;
        dout <= dout;
    end
end
assign sidle = !sreq & !sack;
endmodule