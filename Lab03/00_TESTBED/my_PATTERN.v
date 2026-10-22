`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif



module PATTERN(
    output reg      clk,
    output reg      rst_n,
    // AXI4-Lite Master
    input [31:0]    aw_addr,
    input           aw_valid,
    input           aw_ready,
    input [63:0]    w_data,
    input           w_valid,
    input           w_ready,
    input [1:0]     b_resp,
    input           b_valid,
    input           b_ready,
    
    input [31:0]    ar_addr,
    input           ar_valid,
    input           ar_ready,
    input [63:0]    r_data,
    input [1:0]     r_resp,
    input           r_valid,
    input           r_ready,

    output reg       in_mode_valid,
    output reg [1:0] in_mode,
    output reg       in_valid,
    output reg [1:0] in_bank,
    output reg [5:0] in_src_row,
    output reg [5:0] in_dst_row,
    output reg [63:0]in_data,
    
    input             out_valid,
    input [63:0]      out_data
);


// Golden Memory for Verification
reg [63:0] golden_DRAM [0:65535];
parameter DRAM_p_r = "../00_TESTBED/DRAM_init.dat";
initial $readmemh(DRAM_p_r, golden_DRAM);
//you can access psuedo_DRAM memory by u_DRAM.DRAM
//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer total_latency;
real CYCLE = `CYCLE_TIME;
parameter PATNUM = 63;
integer patcount;
integer error_count;
integer total_errors;
integer passed_patterns;
integer failed_patterns;
integer wait_val_time;
integer wait_aw_ready_time;
integer wait_w_ready_time;
integer wait_b_valid_time;
integer wait_b_ready_time;
integer wait_ar_ready_time;
integer wait_r_valid_time;
integer wait_r_ready_time;


integer aw_has_communicate, w_vr_has_response;
integer wait_w_vr_response;

integer w_has_communicate, b_vr_has_response;
integer wait_b_vr_response;

integer ar_has_communicate, r_vr_has_response;
integer wait_r_vr_response;

integer main1, main2, main3, main4, main5, axi1, axi2, axi3, axi4, axi5, axi6;
reg aw_after_w;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [1:0] all_mode [0:PATNUM-1];
reg [5:0] all_src_row [0:PATNUM-1];
reg [5:0] all_dst_row [0:PATNUM-1];
reg [1:0] all_bank [0:PATNUM-1];
reg [63:0] random_write_data [0:255];
reg [31:0] prev_aw_addr;
reg start_aw_addr;
reg [63:0] prev_w_data;
reg start_w_data;
reg [1:0] prev_b_resp;
reg start_b_resp;
reg [31:0] prev_ar_addr;
reg start_ar_addr;
reg [1:0] prev_r_resp;
reg start_r_resp;
reg signed [63:0] expected_calc_result [0:3];
reg [63:0] sorted_data [0:1023];
integer f_in, a;
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
initial 
begin
	clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial 
begin
    f_in  = $fopen("../00_TESTBED/input.txt", "r");
	rst_n = 1'b1;
    in_mode_valid = 1'b0;
    in_mode = 'bx;
    in_valid = 1'b0;
    in_bank = 'bx;
    in_src_row = 'bx;
    in_dst_row = 'bx;
    in_data = 'bx;
    force clk = 0;
    total_latency = 0;
    error_count = 0;
    total_errors = 0;
    passed_patterns = 0;
    failed_patterns = 0;
    prev_aw_addr = 0;
    start_aw_addr = 0;
    prev_w_data = 0;
    start_w_data = 0;
    prev_b_resp = 0;
    start_b_resp = 0;
    prev_ar_addr = 0;
    start_ar_addr = 0;
    prev_r_resp = 0;
    start_r_resp = 0;
    main1 = 0;
    main2 = 0;
    main3 = 0;
    main4 = 0;
    main5 = 0;
    axi1 = 0;
    axi2 = 0;
    axi3 = 0;
    axi4 = 0;
    axi5 = 0;
    axi6 = 0;
    generate_testcase;
    reset_signal_task;
    
    #(CYCLE*3);
    $display("========================================================================");
	$display("Total Patterns  : %0d", PATNUM);
	$display("========================================================================");
	$display("");
	for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) 
	begin
        $display("------------------------------------------------------------------------");
		$display("  Testing Pattern %0d/%0d", patcount+1, PATNUM);
		$display("------------------------------------------------------------------------");
        repeat($urandom_range(1, 3)) @(negedge clk);
		input_task;
		wait_out_valid;
		check_ans;
		if(error_count == 0) begin
			passed_patterns = passed_patterns + 1;
			$display("  [PASS] Pattern %0d", patcount+1);
		end else begin
			failed_patterns = failed_patterns + 1;
            YOU_FAIL_task;
        end
    end
    YOU_PASS_task;
end

// AXI-1
always @(negedge clk) begin
    if(aw_valid === 0 && aw_addr !== 0) begin
        axi1 = 1;
        $display("aw_valid is low but aw_addr is not 0: aw_addr = %x", aw_addr);
    end
    if(w_valid === 0 && w_data !== 0) begin
        axi1 = 1;
        $display("w_valid is low but w_data is not 0: w_data = %x", w_data);
    end
    if(b_valid === 0 && b_resp !== 0) begin
        axi1 = 1;
        $display("b_valid is low but b_resp is not 0: b_resp = %x", b_resp);
    end
    if(ar_valid === 0 && ar_addr !== 0) begin
        axi1 = 1;
        $display("ar_valid is low but ar_addr is not 0: ar_addr = %x", ar_addr);
    end
        if(r_valid === 0 && (r_resp !== 0 || r_data !== 0)) begin
        axi1 = 1;
        $display("r_valid is low but r_resp is not 0: r_resp = %x", r_resp);
        $display("or r_valid is low but r_data is not 0: r_data = %x", r_data);
    end
end
// aw addr
// AXI-2 4 5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_aw_addr <= 0;
        start_aw_addr <= 0;
        wait_aw_ready_time <= 0;
    end else begin
        if(start_aw_addr && !aw_valid && !aw_ready) begin
            axi2 = 1;
            $display("aw_valid deasserted during aw_addr transaction: previous %x", prev_aw_addr);
        end
        if(aw_valid && !aw_ready) begin
            if(start_aw_addr && aw_addr != prev_aw_addr) begin
                axi2 = 1;
                $display("aw_addr changes during aw_valid high: previous %x, current %x", prev_aw_addr, aw_addr);
            end
            if(aw_addr < 0 || aw_addr > 65535) begin
                axi4 = 1;
            end
            prev_aw_addr <= aw_addr;
            start_aw_addr <= 1;
            wait_aw_ready_time <= wait_aw_ready_time + 1;
            if(wait_aw_ready_time >= 50) begin
                $display("aw_ready not asserted within 50 cycles during aw_addr transaction");
                axi5 = 1;
            end
        end
        else begin
            start_aw_addr <= 0;
            prev_aw_addr <= 0;
            wait_aw_ready_time <= 0;
        end
    end
end
// axi 6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_has_communicate <= 0;
        w_vr_has_response <= 0;
    end else begin
        if(aw_valid && aw_ready && !(w_valid && w_ready)) begin
            aw_has_communicate <= 1;
        end
        else if(aw_has_communicate && w_valid && w_ready) begin
            aw_has_communicate <= 0;
            w_vr_has_response <= 1;
        end
        else begin
            aw_has_communicate <= aw_has_communicate;
            w_vr_has_response <= 0;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wait_w_vr_response <= 0;
    end else begin
        if(aw_has_communicate && w_vr_has_response === 0) begin
            wait_w_vr_response <= wait_w_vr_response + 1;
            if(wait_w_vr_response >= 150) begin
                $display("No response for w_data within 150 cycles after aw_valid/aw_ready handshake");
                axi6 = 1;
            end
        end
        else begin
            wait_w_vr_response <= 0;
        end
    end
end
// w data
// axi2 5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_w_data <= 0;
        start_w_data <= 0;
        wait_w_ready_time <= 0;
    end else begin
        if(start_w_data && !w_valid && !w_ready) begin
            $display("w_valid deasserted during w_data transaction: previous %x", prev_w_data);
            axi2 = 1;
        end
        if(w_valid && !w_ready) begin
            if(start_w_data && w_data != prev_w_data) begin
                $display("w_data changes during w_valid high: previous %x, current %x", prev_w_data, w_data);
                axi2 = 1;
            end
            prev_w_data <= w_data;
            start_w_data <= 1;
            wait_w_ready_time <= wait_w_ready_time + 1;
            if(wait_w_ready_time >= 100) begin
                $display("w_ready not asserted within 100 cycles during w_data transaction");
                axi5 = 1;
            end
        end
        else begin
            start_w_data <= 0;
            prev_w_data <= 0;
            wait_w_ready_time <= 0;
        end
    end
end
// axi3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        aw_after_w <= 1'b0;
    end
    else begin
        if (w_valid && !aw_after_w && !aw_valid) begin
            axi3 = 1;
        end

        if (aw_valid && aw_ready) begin
            aw_after_w <= 1'b1;
        end

        if (w_valid && w_ready) begin
            aw_after_w <= 1'b0;
        end
    end
end

// b resp
// axi2 5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_b_resp <= 0;
        prev_b_resp <= 0;
        wait_b_ready_time <= 0;
    end
    else begin
        if(start_b_resp && !b_ready && !b_valid) begin
            $display("b_valid deasserted during b_resp transaction: previous %x", prev_b_resp);
            axi2 = 1;
        end
        
        if(b_valid && !b_ready) begin
            if(start_b_resp && b_resp != prev_b_resp) begin
                $display("b_resp changes during b_valid high: previous %x, current %x", prev_b_resp, b_resp);
                axi2 = 1;
            end
            prev_b_resp <= b_resp;
            start_b_resp <= 1;
            wait_b_ready_time <= wait_b_ready_time + 1;
            if(wait_b_ready_time >= 100) begin
                $display("b_ready not asserted within 100 cycles during b_resp transaction");
                axi5 = 1;
            end
        end
        else begin
            start_b_resp <= 0;
            prev_b_resp <= 0;
            wait_b_ready_time <= 0;
        end
    end
end
// axi 6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        w_has_communicate <= 0;
        b_vr_has_response <= 0;
    end else begin
        if(w_valid && w_ready && !(b_valid && b_ready)) begin
            w_has_communicate <= 1;
        end
        else if(w_has_communicate && b_valid && b_ready) begin
            w_has_communicate <= 0;
            b_vr_has_response <= 1;
        end
        else begin
            b_vr_has_response <= 0;
            w_has_communicate <= 0;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wait_b_vr_response <= 0;
    end else begin
        if(w_has_communicate && b_vr_has_response === 0) begin
            wait_b_vr_response <= wait_b_vr_response + 1;
            if(wait_b_vr_response >= 150) begin
                $display("No response for b_resp within 150 cycles after w_valid/w_ready handshake");
                axi6 = 1;
            end
        end
        else begin
            wait_b_vr_response <= 0;
        end
    end
end

// ar addr
// axi2 5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_ar_addr <= 0;
        prev_ar_addr <= 0;
        wait_ar_ready_time <= 0;
    end
    else begin
        if(start_ar_addr && !ar_ready && !ar_valid) begin
            $display("ar_valid deasserted during ar_addr transaction: previous %x", prev_ar_addr);
            axi2 = 1;
        end
        if(ar_addr < 0 || ar_addr > 65535) begin
            axi4 = 1;
        end
        if(ar_valid && !ar_ready) begin
            if(start_ar_addr && ar_addr != prev_ar_addr) begin
                $display("ar_addr changes during ar_valid high: previous %x, current %x", prev_ar_addr, ar_addr);
                axi2 = 1;
            end
            prev_ar_addr <= ar_addr;
            start_ar_addr <= 1;
            wait_ar_ready_time <= wait_ar_ready_time + 1;
            if(wait_ar_ready_time >= 50) begin
                $display("ar_ready not asserted within 50 cycles during ar_addr transaction");
                axi5 = 1;
            end
        end
        else begin
            start_ar_addr <= 0;
            prev_ar_addr <= 0;
            wait_ar_ready_time <= 0;
        end
    end
end

// r resp
// axi2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_ar_addr <= 0;
        prev_ar_addr <= 0;
        wait_r_ready_time <= 0;
    end
    else begin
        if(start_r_resp && !r_ready && !r_valid) begin
            $display("r_valid deasserted during r_resp transaction: previous %x", prev_r_resp);
            axi2 = 1;
        end
        if(r_valid && !r_ready) begin
            if(start_r_resp && r_resp != prev_r_resp) begin
                $display("r_resp changes during r_valid high: previous %x, current %x", prev_r_resp, r_resp);
                axi2 = 1;
            end
            prev_r_resp <= r_resp;
            start_r_resp <= 1;
            wait_r_ready_time <= wait_r_ready_time + 1;
            if(wait_r_ready_time >= 100) begin
                $display("r_ready not asserted within 100 cycles during r_resp transaction");
                axi5 = 1;
            end
        end
        else begin
            start_r_resp <= 0;
            prev_r_resp <= 0;
            wait_r_ready_time <= 0;
        end
    end
end
// axi 6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ar_has_communicate <= 0;
        r_vr_has_response <= 0;
    end else begin
        if(ar_valid && ar_ready && !(r_valid && r_ready)) begin
            ar_has_communicate <= 1;
        end
        else if(ar_has_communicate && r_valid && r_ready) begin
            ar_has_communicate <= 0;
            r_vr_has_response <= 1;
        end
        else begin
            r_vr_has_response <= 0;
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wait_r_vr_response <= 0;
    end else begin
        if(ar_has_communicate && r_vr_has_response === 0) begin
            wait_r_vr_response <= wait_r_vr_response + 1;
            if(wait_r_vr_response >= 150) begin
                $display("No response for r_resp within 150 cycles after ar_valid/ar_ready handshake");
                axi6 = 1;
            end
        end
        else begin
            wait_r_vr_response <= 0;
        end
    end
end

always @(negedge clk) begin
    if(main1 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-1 FAIL                            *");
        $display("*************************************************************************");
        $finish;
    end
    else if(axi1 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC AXI-1 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    else if(axi2 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC AXI-2 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    else if(axi3 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC AXI-3 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    else if(axi4 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC AXI-4 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    else if(axi5 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC AXI-5 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    else if(axi6 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC AXI-6 FAIL                             *");
        $display("*************************************************************************");
        $finish;
    end
    else if(main2 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-2 FAIL                            *");
        $display("*************************************************************************");
        $finish;
    end
    else if(main3 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-3 FAIL                            *");
        $display("*************************************************************************");
        $finish;
    end
    else if(main4 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-4 FAIL                            *");
        $display("*************************************************************************");
        $finish;
    end
    else if(main5 === 1) begin
        $display("*************************************************************************");
        $display("*                           SPEC MAIN-5 FAIL                            *");
        $display("*************************************************************************");
        $finish;
    end
end
// 

// =======================================
// helper
// =======================================
task YOU_FAIL_task; begin
    $display("*                              FAIL!                                    *");
    $display("*                    Error message from PATTERN.v                       *");
end endtask
task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("*                         Congratulations!                              *");
    $display("*                Your execution cycles = %5d cycles          *", total_latency);
    $display("*                Your clock period = %.1f ns          *", CYCLE);
    $display("*                Total Latency = %.1f ns          *", total_latency*CYCLE);
    $display("*************************************************************************");
    $finish;
end endtask

function [15:0] dram_addr;
    input [1:0] bank;
    input [5:0] row;
    input [7:0] col;
    begin
        dram_addr = {bank, row, col};
    end
endfunction

task generate_testcase;
    integer i, j, k;
    begin
        k = 0;
        for(i = 0;i <= 62;i = i + 1) begin
            // for(j = 32;j <= 62;j = j + 1) begin
                all_mode[k] = 3;
                all_bank[k] = 0;
                all_src_row[k] = i;
                all_dst_row[k] = 32;
                k = k + 1;
            // end
        end
    end
endtask

task reset_signal_task; 
begin 
    #(CYCLE);  rst_n = 0;
    #200;
    if((aw_addr !== 0) || (aw_valid !== 12'b0) || (aw_ready !== 12'b0) || (w_data !== 12'b0)
         || (w_valid !== 12'b0) || (w_ready !== 12'b0) || (b_resp !== 12'b0) || (b_valid !== 12'b0) || (b_ready !== 12'b0)
         || (ar_addr !== 0) || (ar_valid !== 12'b0) || (ar_ready !== 12'b0) || (r_data !== 12'b0) || (r_resp !== 12'b0) || (r_valid !== 12'b0) || (r_ready !== 12'b0)
         || (out_valid !== 1'b0) || (out_data !== 64'b0)
    ) 
    begin
        main1 = 1;
    end
    #(CYCLE);
    rst_n = 1;
	#(CYCLE);
    release clk;
end 
endtask
task input_task; 
begin
    in_mode_valid = 1'b1;
    in_mode = all_mode[patcount];
    @(negedge clk);
    in_mode_valid = 1'b0;
    in_mode = 'bx;
    in_valid = 1'b1;
    in_src_row = all_src_row[patcount];
    if(all_mode[patcount] == 0 || all_mode[patcount] == 1 ) begin
        in_bank = all_bank[patcount];
    end
    if(all_mode[patcount] == 1 || all_mode[patcount] == 3) begin
        in_dst_row = all_dst_row[patcount];
    end
    if(all_mode[patcount] == 1) begin
        // generate_write_data;
        in_data = random_write_data[0];
        in_src_row = 'bx;
    end
    if(all_mode[patcount] == 3) begin
        sort_data_L1;
    end
    $display("  Input pattern: mode = %d, bank = %d, src_row = %d, dst_row = %d", 
             all_mode[patcount], all_bank[patcount], all_src_row[patcount], all_dst_row[patcount]);
    @(negedge clk);
    in_src_row = 'bx;
    in_dst_row = 'bx;
    in_bank = 'bx;
    if(all_mode[patcount] == 1) begin
        for(integer i = 1; i < 256; i = i + 1) begin
            in_valid = 1'b1;
            in_data = random_write_data[i];
            @(negedge clk);
        end
    end
    in_valid = 1'b0;
    in_data = 'bx;
end
endtask

task generate_write_data; begin
    integer i;
    for (i = 0; i < 256; i = i + 1) begin
        // $fscanf(f_in, "%d", random_write_data[i]);
        // random_write_data[i] = {$urandom, $urandom};
        random_write_data[i] = $urandom;
    end
end 
endtask

task wait_out_valid; 
begin
    wait_val_time = 0;       

    while(out_valid !== 1'b1) begin
	    wait_val_time = wait_val_time + 1;
	    
	    if(wait_val_time > 10000) begin
            main2 = 1;
	    end
	    
	    @(negedge clk);
    end
    
    total_latency = total_latency + wait_val_time;
    $display("  Output completed in %0d cycles", wait_val_time);
end 
endtask

task check_ans;
    if(all_mode[patcount] === 0) begin
        read_dram_data;
        $display("  DRAM read data check completed");
    end
    else if(all_mode[patcount] === 1) begin
        $display("  DRAM write completed, checking DRAM data...");
        write_dram_data;
        check_dram_value;
    end
    else if(all_mode[patcount] === 2) begin
        $display("  Calculation completed, checking results...");
        check_calc_tree_result;
    end
    else begin
        $display("  Sorting completed, checking DRAM data...");
        
        check_dram_value;
    end
endtask

task sort_data_L1;
    integer i, j, k;
    reg [63:0] temp; 
    integer f1,f1_2, f1_3, f1_4, f2;
    begin
        // --- 1. 讀取與第一階段排序 (每 256 筆個別排序) ---
        for(i = 0; i < 256; i = i + 1) begin
            sorted_data[i]     = golden_DRAM[dram_addr(0, all_src_row[patcount], i)];
            sorted_data[i+256] = golden_DRAM[dram_addr(1, all_src_row[patcount], i)];
            sorted_data[i+512] = golden_DRAM[dram_addr(2, all_src_row[patcount], i)];
            sorted_data[i+768] = golden_DRAM[dram_addr(3, all_src_row[patcount], i)];
        end

        for(k = 0; k < 1024; k = k + 256) begin
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 255 - i; j = j + 1) begin
                    if (sorted_data[j+k][62:32] > sorted_data[j+1+k][62:32]) begin
                        temp = sorted_data[j+k];
                        sorted_data[j+k] = sorted_data[j+1+k];
                        sorted_data[j+1+k] = temp;
                    end
                end
            end
        end 

        // 輸出第一階段結果到 txt
        f1 = $fopen("L1_sorted_data.txt", "w");
        f1_2 = $fopen("L1_sorted_data_bank1.txt", "w");
        f1_3 = $fopen("L1_sorted_data_bank2.txt", "w");
        f1_4 = $fopen("L1_sorted_data_bank3.txt", "w");
        for(i = 0; i < 1024; i = i + 1) begin
            if(i % 256 == 0) begin
                $fdisplay(f1, "---- Bank %d, Row %d ----", i/256, all_src_row[patcount]);
            end
            if(i < 256) begin
                $fdisplay(f1, "Idx:%4d | Data:%h | Key(Dec):%d", i, sorted_data[i], sorted_data[i][62:32]);
            end
            else if(i < 512) begin
                $fdisplay(f1_2, "Idx:%4d | Data:%h | Key(Dec):%d", i-256, sorted_data[i], sorted_data[i][62:32]);
            end
            else if(i < 768) begin
                $fdisplay(f1_3, "Idx:%4d | Data:%h | Key(Dec):%d", i-512, sorted_data[i], sorted_data[i][62:32]);
            end
            else 
            $fdisplay(f1_4, "Idx:%4d | Data:%h | Key(Dec):%d", i-768, sorted_data[i], sorted_data[i][62:32]);
        end
        $fclose(f1);
        $fclose(f1_2);
        $fclose(f1_3);
        $fclose(f1_4);

        // --- 2. 寫回 L1 結果 ---
        for(i = 0; i < 256; i = i + 1) begin
            golden_DRAM[dram_addr(0, 6'd63, i)] = sorted_data[i];
            golden_DRAM[dram_addr(1, 6'd63, i)] = sorted_data[i+256];
            golden_DRAM[dram_addr(2, 6'd63, i)] = sorted_data[i+512];
            golden_DRAM[dram_addr(3, 6'd63, i)] = sorted_data[i+768];
        end

        // --- 3. 第二階段 Merge (L2) ---
        for (i = 0; i < 1024; i = i + 1) begin
            for (j = 0; j < 1023-i; j = j + 1) begin
                if (sorted_data[j][62:32] > sorted_data[j+1][62:32]) begin
                    temp = sorted_data[j];
                    sorted_data[j] = sorted_data[j+1];
                    sorted_data[j+1] = temp;
                end
            end
        end

        // 輸出第二階段結果到 txt (包含 64bit Hex 與 31bit Dec)
        f2 = $fopen("L2_merge_data.txt", "w");
        for(i = 0; i < 1024; i = i + 1) begin
            $fdisplay(f2, "Idx:%4d | Raw:%h | Key_Dec:%d", i, sorted_data[i], sorted_data[i][62:32]);
        end
        $fclose(f2);

        // --- 4. 寫回 L2 結果到 Row 63 ---
        for(i = 0;i < 256;i = i + 1) begin
            golden_DRAM[dram_addr(0,all_dst_row[patcount],i)] = sorted_data[i];
            golden_DRAM[dram_addr(1,all_dst_row[patcount],i)] = sorted_data[i+256];
            golden_DRAM[dram_addr(2,all_dst_row[patcount],i)] = sorted_data[i+512];
            golden_DRAM[dram_addr(3,all_dst_row[patcount],i)] = sorted_data[i+768];
        end
    end 
endtask

task read_dram_data;
    integer i;
    for(i = 0;i < 256;i = i + 1) begin
        if(out_valid !== 1'b1) begin
            main3 = 1;
        end
        if(out_data !== golden_DRAM[dram_addr(all_bank[patcount],all_src_row[patcount],i)]) begin
            $display("READ: fail at DRAM[ %d ], expect %x, receive %x",dram_addr(all_bank[patcount],all_src_row[patcount],i), 
                                        golden_DRAM[dram_addr(all_bank[patcount],all_src_row[patcount],i)], out_data);
            main4 = 1;
        end
        total_latency = total_latency + 1;
        @(negedge clk);
    end
    if(out_valid !== 1'b0) begin
        main3 = 1;
    end
endtask

task write_dram_data;
    integer i;
    for(i = 0;i < 256;i = i + 1) begin
        golden_DRAM[dram_addr(all_bank[patcount],all_dst_row[patcount],i)] = random_write_data[i];
    end
endtask

task check_dram_value;
integer bank, row, col;
begin
    if(out_valid !== 1'b1) begin
        main3 = 1;
    end
    
    for(integer i = 0;i < 65536;i = i + 1) begin
        if(golden_DRAM[i] != u_DRAM.DRAM[i]) begin
            bank = (i >> 14) & 2'b11; // Bank 位於 bit 15-14
            row  = (i >> 8) & 6'b111111; // Row 位於 bit 13-8
            col  = i & 8'b11111111; // Col 位於 bit 7-0
            $display("address = %x", i);
            $display("fail at DRAM[ %d,%d,%d ], expect %x, receive %x",bank,row,col, golden_DRAM[i], u_DRAM.DRAM[i]);
            main5 = 1;
        end
    end
    @(negedge clk);
    total_latency = total_latency + 1;
    if(out_valid === 1'b1) begin
        main3 = 1;
        // $display("*************************************************************************");
        // $display("*                           SPEC MAIN-3 FAIL                            *");
        // $display("*************************************************************************");
        // $finish;
    end
    @(negedge clk);
end
endtask

task check_calc_tree_result;
    integer b;
    reg [15:0] root_ptr;
    begin
        for (b = 0; b < 4; b = b + 1) begin
            if(out_valid !== 1'b1) begin
                main3 = 1;
            end
            // 組合成指標：{Bank[1:0], Row[5:0], Col[7:0]}
            // Root 固定在 Column 0
            root_ptr = {b[1:0], all_src_row[patcount], 8'h00};
            
            // 呼叫遞迴函數
            calc_tree_no_recursive_task(root_ptr, expected_calc_result[b]);
            if($signed(expected_calc_result[b]) !== $signed(out_data)) begin
                $display("CALC: fail at Bank %d, expect %d, receive %d", b, expected_calc_result[b], out_data);
                main4 = 1;
            end
            total_latency = total_latency + 1;
            @(negedge clk);
        end
        if(out_valid !== 1'b0) begin
            main3 = 1;
        end
    end
endtask
task calc_tree_no_recursive_task;
    input  [15:0] root_addr;
    output reg signed [63:0] result;

    // 堆疊宣告
    reg [63:0] op_stack [0:511];
    reg        op_flag_stack [0:511];
    reg signed [63:0] val_stack [0:511];
    reg        val_flag [0:511];
    
    integer op_stack_ptr;
    integer val_stack_ptr;
    integer file_ptr;

    // 內部變數
    reg [63:0] curr;
    reg        curr_flag;
    reg [63:0] root_node;
    reg [15:0] left_addr, right_addr;
    reg [63:0] left_node, right_node;
    reg signed [63:0] a, b, res, tmp;
    reg        a_flag, b_flag;
    reg [1:0]  op;
    integer    i;

    begin
        // 開啟檔案 (Append 模式)
        file_ptr = $fopen("calc.txt", "a");
        $fdisplay(file_ptr, "\n--- Start Calculation for root_addr: %h ---", root_addr);

        op_stack_ptr = -1;
        val_stack_ptr = -1;

        root_node = golden_DRAM[root_addr];

        // 1. 處理根節點是否為常數
        if (root_node[63] == 1'b0) begin
            res = {{33{root_node[62]}}, root_node[62:32]};
            $fdisplay(file_ptr, "Root is constant: %d", res);
            result = res;
            $fclose(file_ptr);
        end
        else begin
            // 2. 壓入第一個運算節點
            op_stack_ptr = op_stack_ptr + 1;
            op_stack[op_stack_ptr] = root_node;
            op_flag_stack[op_stack_ptr] = 1'b0;

            while (op_stack_ptr >= 0) begin
                curr = op_stack[op_stack_ptr];
                curr_flag = op_flag_stack[op_stack_ptr];
                op_stack_ptr = op_stack_ptr - 1;

                // 檢查 bit 61 是否為已展開標記
                if (curr[61] == 1'b1) begin
                    op = curr[33:32];
                    b = val_stack[val_stack_ptr];
                    b_flag = val_flag[val_stack_ptr];
                    a = val_stack[val_stack_ptr-1];
                    a_flag = val_flag[val_stack_ptr-1];
                    val_stack_ptr = val_stack_ptr - 2;

                    // 根據 flag 決定 a, b 順序
                    if (a_flag) begin
                        tmp = a;
                        a = b;
                        b = tmp;
                    end

                    case (op)
                        2'b00: res = a + b;
                        2'b01: res = a - b;
                        2'b10: res = a * b;
                        2'b11: res = a >>> b[5:0]; // 算術右移
                    endcase

                    val_stack_ptr = val_stack_ptr + 1;
                    val_stack[val_stack_ptr] = res;
                    val_flag[val_stack_ptr] = curr_flag;

                    $fdisplay(file_ptr, "curr=%h 標記位元為 1：執行運算", curr);
                    $fdisplay(file_ptr, "  a=%d b=%d op=%b result=%d", a, b, op, res);
                end
                else begin
                    left_addr  = curr[31:16];
                    right_addr = curr[15:0];
                    $fdisplay(file_ptr, "獲取左右子節點資料，父節點: %h (L:%h, R:%h)", curr, left_addr, right_addr);

                    left_node  = golden_DRAM[left_addr];
                    right_node = golden_DRAM[right_addr];

                    // 壓回當前節點並標記 bit 61
                    op_stack_ptr = op_stack_ptr + 1;
                    op_stack[op_stack_ptr] = curr | 64'h2000_0000_0000_0000;
                    op_flag_stack[op_stack_ptr] = curr_flag;

                    // 左子處理
                    if (left_node[63] == 1'b1) begin
                        op_stack_ptr = op_stack_ptr + 1;
                        op_stack[op_stack_ptr] = left_node;
                        op_flag_stack[op_stack_ptr] = 1'b0;
                        $fdisplay(file_ptr, "  左子節點 %h 是運算節點, 數值是%h", left_addr, left_node);
                    end
                    else begin
                        val_stack_ptr = val_stack_ptr + 1;
                        val_stack[val_stack_ptr] = {{33{left_node[62]}}, left_node[62:32]};
                        val_flag[val_stack_ptr] = 1'b0;
                        $fdisplay(file_ptr, "  左子節點 %h 是常數: %d", left_addr, val_stack[val_stack_ptr]);
                    end

                    // 右子處理
                    if (right_node[63] == 1'b1) begin
                        op_stack_ptr = op_stack_ptr + 1;
                        op_stack[op_stack_ptr] = right_node;
                        op_flag_stack[op_stack_ptr] = 1'b1;
                        $fdisplay(file_ptr, "  右子節點 %h 是運算節點, 數值是%h", right_addr, right_node);
                    end
                    else begin
                        val_stack_ptr = val_stack_ptr + 1;
                        val_stack[val_stack_ptr] = {{33{right_node[62]}}, right_node[62:32]};
                        val_flag[val_stack_ptr] = 1'b1;
                        $fdisplay(file_ptr, "  右子節點 %h 是常數: %d", right_addr, val_stack[val_stack_ptr]);
                    end
                end
            end
            result = val_stack[0];
            $fdisplay(file_ptr, "--- Final Result: %d ---", result);
            $fclose(file_ptr);
        end
    end
endtask
endmodule

// $display("*************************************************************************");
// $display("*                           SPEC MAIN-1 FAIL                            *");
// $display("*                           SPEC MAIN-2 FAIL                            *");
// $display("*                           SPEC MAIN-3 FAIL                            *");
// $display("*                           SPEC MAIN-4 FAIL                            *");
// $display("*                           SPEC MAIN-5 FAIL                            *");
// $display("*************************************************************************");

// $display("*************************************************************************");
// $display("*                          SPEC AXI-1 FAIL                              *");
// $display("*                          SPEC AXI-2 FAIL                              *");
// $display("*                          SPEC AXI-3 FAIL                              *");
// $display("*                          SPEC AXI-4 FAIL                              *");
// $display("*                          SPEC AXI-5 FAIL                              *");
// $display("*                          SPEC AXI-6 FAIL                              *");
// $display("*************************************************************************");