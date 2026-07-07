//###############################################################################################
//***********************************************************************************************
//    File Name   : SORT_IP.v
//    Module Name : SORT_TP
//***********************************************************************************************
//###############################################################################################

module SORT_IP #(parameter IP_WIDTH = 3)(
	//Input signals
	IN_character, IN_weight,
	//Output signalsll
	OUT_character
);

// ======================================================
// Input & Output Declaration
// ======================================================
input [IP_WIDTH*4-1:0]  IN_character;
input [IP_WIDTH*5-1:0]  IN_weight;

output [IP_WIDTH*4-1:0] OUT_character;
reg [8:0] arr [IP_WIDTH-1:0];
reg [IP_WIDTH*4-1:0] out_arr;
integer i, j;
genvar idx;
// ======================================================
// Design start
// ======================================================

always @(*) begin
    for(i = 0; i < IP_WIDTH; i = i + 1)
        arr[i] = { IN_weight[i*5 +: 5], IN_character[i*4 +: 4] };

    for(j = 0; j < IP_WIDTH; j = j + 1)
        for(i = 0; i < IP_WIDTH-1-j; i = i + 1)
            if(arr[i][8:4] > arr[i+1][8:4])
                {arr[i], arr[i+1]} = {arr[i+1], arr[i]};
end

generate
    for(idx = 0; idx < IP_WIDTH; idx = idx + 1) begin : gen_out
        always @(*) begin
            out_arr[idx*4 +: 4] = arr[idx][3:0];
        end
    end
endgenerate

assign OUT_character = out_arr;

endmodule