`include "DEFINE.vh"

/* 32-bit ROM read -> one 32-bit RAM write per 4 bytes. */
module LOAD_BMP(
    clk,
    rst_n,
    in_valid,
    ROM_out,
    ROM_ren,
    ROM_addr,
    RAM_wen_lword,
    RAM_din,
    RAM_addr,
    load_done
);

input clk;
input rst_n;
input in_valid;
input [`LWORD_WIDTH-1:0] ROM_out;

output reg ROM_ren;
output reg [`ROM_ADDR_WIDTH-1:0] ROM_addr;
output reg RAM_wen_lword;
output reg [`LWORD_WIDTH-1:0] RAM_din;
output reg [`ADDR_WIDTH-1:0] RAM_addr;
output reg load_done;

localparam [2:0] IDLE   = 3'd0,
                 FETCH  = 3'd1,
                 LATCH  = 3'd2,
                 W32    = 3'd3,
                 DONE   = 3'd4;

reg [2:0] state;
reg [2:0] next_state;
reg [`ROM_ADDR_WIDTH-1:0] word_idx;
reg [31:0] latched_word;
wire [`ADDR_WIDTH-1:0] byte_base;

assign byte_base = {word_idx, 2'b00};

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        word_idx <= 0;
        latched_word <= 32'h0;
    end else begin
        state <= next_state;
        if(state == IDLE && in_valid) begin
            word_idx <= 0;
        end else if(state == W32 && word_idx != (`BMP_ROM_NUM_WORDS - 1)) begin
            word_idx <= word_idx + 1;
        end

        if(state == LATCH)
            latched_word <= ROM_out;
    end
end

always @(*) begin
    next_state = state;
    case(state)
        IDLE:  next_state = in_valid ? FETCH : IDLE;
        FETCH: next_state = LATCH;
        LATCH: next_state = W32;
        W32:   next_state = (word_idx == (`BMP_ROM_NUM_WORDS - 1)) ? DONE : FETCH;
        DONE:  next_state = DONE;
        default: next_state = IDLE;
    endcase
end

always @(*) begin
    ROM_ren = 1'b0;
    ROM_addr = word_idx;
    RAM_wen_lword = 1'b0;
    RAM_din = 32'h0;
    RAM_addr = 0;
    load_done = (state == DONE);

    case(state)
        FETCH: begin
            ROM_ren = 1'b1;
        end
        W32: begin
            RAM_wen_lword = 1'b1;
            RAM_addr = byte_base;
            RAM_din = latched_word;
        end
        default: begin
            ROM_ren = 1'b0;
            RAM_wen_lword = 1'b0;
        end
    endcase
end

endmodule
