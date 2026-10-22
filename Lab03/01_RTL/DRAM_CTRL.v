module DRAM_CTRL (
    input               clk,
    input               rst_n,
    
    // AXI4-Lite slave interface
    input [31:0]        aw_addr,
    input               aw_valid,
    output reg          aw_ready,
    input [63:0]        w_data,
    input               w_valid,
    output reg          w_ready,
    output reg [1:0]   b_resp,
    output reg         b_valid,
    input               b_ready,
    
    input [31:0]        ar_addr,
    input               ar_valid,
    output reg          ar_ready,
    output reg [63:0]   r_data,
    output reg [1:0]   r_resp,
    output reg         r_valid,
    input               r_ready,

    // DRAM master interface
    output reg  [3:0]   dram_cmd,  // {CS_n, RAS_n, CAS_n, WE_n}
    output reg  [1:0]   dram_ba,
    output reg  [10:0]  dram_addr,
    output reg  [63:0]  dram_wdata,
    input [63:0]        dram_rdata,
    input               dram_valid
);

reg [1:0] last_bank;
reg [5:0] last_row [0:3];
reg activated [0:3];
reg [1:0] precharge_cnt;
reg [1:0] act_cnt;
reg [8:0] read_cnt, read_cmd_cnt;
reg [2:0] wait_read_cnt;
reg [5:0] state, next_state;
localparam  IDLE = 0; // 1
localparam  ACT = 1; // 2
localparam WAIT_READ = 2; // 4
localparam READ = 3; // 8
localparam WRITE = 4; // 16
localparam PRECHARGE =5; // 32
localparam PENDING = 6;
localparam INIT = 7;
wire access_the_same_row [0:3];
wire [1:0] read_bank;
wire [5:0] read_row;
wire [7:0] read_col;
reg [31:0] ar_addr_reg;
reg ar_addr_reg_valid;
reg ar_addr_reg_sz;
reg [8:0] write_cnt, write_cmd_cnt;
wire [1:0] write_bank;
wire [5:0] write_row;
wire [7:0] write_col;
wire [1:0] bank_sel;
wire [5:0] row_sel;
wire [7:0] col_sel;
wire [1:0] addr_reg_bank;
wire [5:0] addr_reg_row;
wire [7:0] addr_reg_col;
wire access_the_same_row_sel, activated_sel;
assign write_bank = aw_addr[15:14];
assign write_row = aw_addr[13:8];
assign write_col = aw_addr[7:0];
assign addr_reg_bank = ar_addr_reg[15:14];
assign addr_reg_row = ar_addr_reg[13:8];
assign addr_reg_col = ar_addr_reg[7:0];
assign bank_sel = ar_addr_reg_sz ? addr_reg_bank : write_bank;
assign row_sel = ar_addr_reg_sz ? addr_reg_row : write_row;
assign col_sel = ar_addr_reg_sz ? addr_reg_col : write_col;
assign access_the_same_row[0] = (last_row[0] == row_sel);
assign access_the_same_row[1] = (last_row[1] == row_sel);
assign access_the_same_row[2] = (last_row[2] == row_sel);
assign access_the_same_row[3] = (last_row[3] == row_sel);

assign access_the_same_row_sel = access_the_same_row[bank_sel];
assign activated_sel = activated[bank_sel];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT;
    end else begin
        state <= next_state;
    end
end
always @(*) begin
    case (state)
        INIT: begin
            next_state = IDLE;
        end
        IDLE: begin
            if(ar_valid) begin
                next_state = PENDING;
            end
            else if(aw_valid) begin
                if(activated_sel && access_the_same_row_sel) begin
                    next_state = WRITE;
                end
                else next_state = PRECHARGE;
            end
            else begin
                next_state = IDLE;
            end
        end
        PENDING: begin
            if(ar_addr_reg_valid) begin
                next_state = WAIT_READ;
            end
            else begin
                next_state = PRECHARGE;
            end
        end
        PRECHARGE: begin
            if(precharge_cnt == 3) begin
                next_state = ACT;
            end
            else begin
                next_state = PRECHARGE;
            end
        end
        ACT: begin
            if(act_cnt == 1) begin
                next_state = ar_addr_reg_sz ? WAIT_READ : WRITE;
            end
            else begin
                next_state = ACT;
            end
        end
        
        WAIT_READ: begin
            if(wait_read_cnt == 4) begin
                next_state = READ;
            end
            else begin
                next_state = WAIT_READ;
            end
        end
        READ: begin
            if(ar_addr_reg_sz && !ar_addr_reg_valid) begin
                next_state = PRECHARGE;
            end
            else if(read_cnt == read_cmd_cnt - 1) begin
                next_state = IDLE;
            end
            else begin
                next_state = READ;
            end
        end
        WRITE: begin
            if (aw_valid &&  activated_sel && ~access_the_same_row_sel) begin
                next_state = PRECHARGE;
            end
            else if(aw_valid && ~activated_sel) begin
                next_state = IDLE;
            end
            else if(write_cnt == write_cmd_cnt && !aw_valid) begin
                next_state = IDLE;
            end
            else begin
                next_state = WRITE;
            end
        end
        default: next_state = IDLE;
    endcase
end
// ar register
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ar_addr_reg <= 0;
        ar_addr_reg_valid <= 0;
        ar_addr_reg_sz <= 0;
    end
    else if(ar_valid && ar_ready) begin
        ar_addr_reg <= ar_addr;
        ar_addr_reg_valid <= activated[ar_addr[15:14]] && last_row[ar_addr[15:14]] == ar_addr[13:8];
        ar_addr_reg_sz <= 1;
    end
    else if(state == ACT && act_cnt == 1) begin
        ar_addr_reg_valid <= 1;
        ar_addr_reg <= ar_addr_reg;
        ar_addr_reg_sz <= ar_addr_reg_sz;
    end
    else if((state == WAIT_READ || state == READ) && ar_addr_reg_valid) begin
        ar_addr_reg_valid <= 0;
        ar_addr_reg <= 0;
        ar_addr_reg_sz <= 0;
    end
    else begin
        ar_addr_reg <= ar_addr_reg;
        ar_addr_reg_valid <= ar_addr_reg_valid;
        ar_addr_reg_sz <= ar_addr_reg_sz;
    end
end
// AXI
always @(*) begin
    ar_ready = ~(state == INIT || state == PENDING || (ar_addr_reg_sz && !ar_addr_reg_valid) && (state != IDLE || state != WAIT_READ || state != READ));
end

// r resp
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_valid <= 0;
        r_data <= 0;
        r_resp <= 0;
    end 
    else if(state == READ) begin
        r_data <= dram_rdata;
        r_valid <= 1;
        r_resp <= 0;
    end
    else begin
        r_valid <= 0;
        r_data <= 0;
        r_resp <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_cnt <= 0;
    end 
    else if(state == READ) begin
        read_cnt <= read_cnt + 1;
    end
    else begin
        read_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        read_cmd_cnt <= 0;
    end 
    else if(ar_valid && ar_ready) begin
        read_cmd_cnt <= read_cmd_cnt + 1;
    end
    else if(state == PRECHARGE)begin
        read_cmd_cnt <= 1;
    end
    else if(state == IDLE) begin
        read_cmd_cnt <= 0;
    end
    else begin
        read_cmd_cnt <= read_cmd_cnt;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wait_read_cnt <= 0;
    end 
    else if(state == WAIT_READ) begin
        wait_read_cnt <= wait_read_cnt + 1;
    end
    else begin
        wait_read_cnt <= 0;
    end
end

// aw w ready 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        aw_ready <= 0;
        w_ready <= 0;
    end
    else if(aw_valid && (state == IDLE || state == ACT || state == WRITE) && activated_sel && access_the_same_row_sel)begin
        aw_ready <= 1;
        w_ready <= 1;
    end
    else begin
        aw_ready <= 0;
        w_ready <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_cnt <= 0;
    end 
    else if(state == WRITE) begin
        write_cnt <= write_cnt + 1;
    end
    else begin
        write_cnt <= 0;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        write_cmd_cnt <= 0;
    end 
    else if(aw_ready) begin
        write_cmd_cnt <= write_cmd_cnt + 1;
    end
    else if(state == IDLE) begin
        write_cmd_cnt <= 0;
    end
    else begin
        write_cmd_cnt <= write_cmd_cnt;
    end
end

// b resp
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        b_resp = 0;
        b_valid = 0;
    end else if(state == WRITE)
    begin
        b_resp = 0;
        b_valid = 1;
    end
    else begin
        b_resp = 0;
        b_valid = 0;
    end
end
// DRAM CTRL

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        act_cnt <= 0;
    end
    else if(state == ACT) begin
        act_cnt <= act_cnt + 1;
    end
    else begin
        act_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        precharge_cnt <= 0;
    end
    else if(state == PRECHARGE) begin
        precharge_cnt <= precharge_cnt + 1;
    end
    else begin
        precharge_cnt <= 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        activated[0]   <= 0;
        activated[1]   <= 0;
        activated[2]   <= 0;
        activated[3]   <= 0;
    end
    else if(state == ACT) begin
        for(integer i = 0; i < 4; i = i + 1) begin
            if(i == bank_sel) begin
                activated[i] <= 1;
            end
            else activated[i] <= activated[i];
        end
    end
    else if(state == PRECHARGE) begin
        for(integer i = 0; i < 4; i = i + 1) begin
            if(i == bank_sel) begin
                activated[i] <= 1;
            end
            else activated[i] <= activated[i];
        end
    end
    else begin
        activated[0] <= activated[0];
        activated[1] <= activated[1];
        activated[2] <= activated[2];
        activated[3] <= activated[3];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        last_bank <= 0;
        last_row[0] <= 0;
        last_row[1] <= 0;
        last_row[2] <= 0;
        last_row[3] <= 0;
    end
    else if(state == ACT) begin
        last_bank <= bank_sel;
        for(integer i = 0; i < 4; i = i + 1) begin
            if(i == bank_sel) begin
                last_row[i] <= row_sel;
            end
            else last_row[i] <= last_row[i];
        end
    end
    else begin
        last_row[0] <= last_row[0];
        last_row[1] <= last_row[1];
        last_row[2] <= last_row[2];
        last_row[3] <= last_row[3];
        last_bank <= last_bank;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dram_cmd <= 4'b0111; // NOP
        dram_ba <= 0;
        dram_addr <= 0;
        dram_wdata <= 0;
    end
    // ACT
    else if(state == PRECHARGE && precharge_cnt == 3) begin
        dram_cmd <= 4'b0011;
        dram_ba <= ar_addr_reg_sz ? addr_reg_bank :  write_bank;
        dram_addr <= ar_addr_reg_sz ? addr_reg_row : write_row;
        dram_wdata <= 0;
    end
    // READ
    else if((state == WAIT_READ || state == READ) && ar_addr_reg_valid) begin
        dram_cmd <= 4'b0101;
        dram_ba <= addr_reg_bank;
        dram_addr <= addr_reg_col;
        dram_wdata <= 0;
    end
    // WRITE
    else if((state == WRITE) && aw_valid && aw_ready) begin
        dram_cmd <= 4'b0100;
        dram_ba <= write_bank;
        dram_addr <= write_col;
        dram_wdata <= w_data;
    end
    // PRECHARGE
    else if(state != PRECHARGE && next_state == PRECHARGE) begin
        dram_cmd <= 4'b0010;
        dram_ba <= ar_addr_reg_sz ? addr_reg_bank :  write_bank;
        dram_addr <= 0;
        dram_wdata <= 0;
    end
    else begin
        dram_cmd <= 4'b0111; // NOP
        dram_ba <= 0;
        dram_addr <= 0;
        dram_wdata <= 0;
    end
end

endmodule
