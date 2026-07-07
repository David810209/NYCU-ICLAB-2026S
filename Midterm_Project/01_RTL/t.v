module mult_16bit(
    input                    clk,
    input                    rst_n,
    input                    mult_en,
    input  signed [15:0]     A,
    input  signed [15:0]     B,
    output signed [31:0]     result,
    output                   mult_done
);

    reg [3:0] shift_cnt;
    reg start_mult;
    wire [15:0] abs_A = A[15] ? (~A + 16'd1) : A;
    wire [15:0] abs_B = B[15] ? (~B + 16'd1) : B;
    wire        sign  = A[15] ^ B[15];

    reg [31:0] shifted_A;
    reg [15:0] shift_B;
    reg        sign_r;
    reg [31:0] acc;
    reg [31:0] result_r;
    reg        done_r;

    wire [31:0] acc_next = shift_B[0] ? acc + shifted_A : acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_mult <= 0;
        end
        else if (mult_en && !start_mult) begin
            start_mult <= 1;
        end
        else if (done_r) begin
            start_mult <= 0;
        end
        else begin
            start_mult <= start_mult;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_cnt <= 0;
        end
        else if (mult_en && !start_mult) begin
            shift_cnt <= 0;
        end
        else if (start_mult) begin
            shift_cnt <= shift_cnt + 1;
        end
        else begin
            shift_cnt <= 0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_A <= 0;
            shift_B   <= 0;
            sign_r    <= 0;
            acc       <= 0;
            result_r  <= 0;
            done_r    <= 0;
        end
        else begin
            done_r <= 0;

            if (mult_en && !start_mult) begin
                sign_r    <= sign;
                shifted_A <= {16'b0, abs_A} << 1;
                shift_B   <= {1'b0, abs_B[15:1]};
                acc       <= abs_B[0] ? {16'b0, abs_A} : 32'd0;
            end
            else if (start_mult) begin
                shifted_A <= shifted_A << 1;
                shift_B   <= {1'b0, shift_B[15:1]};
                acc       <= acc_next;

                if (shift_cnt == 4'd14) begin
                    done_r   <= 1;
                    result_r <= sign_r ? (~acc_next + 32'd1) : acc_next;
                end
            end
        end
    end

    assign result    = result_r;
    assign mult_done = done_r;

endmodule