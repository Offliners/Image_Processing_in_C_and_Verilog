`include "DEFINE.vh"

/* 32-bit word storage; byte address. wen_lword: write full word at RAM_addr>>2. wen_byte: RMW one byte. */
module BMP_LWORD_RAM #(
    parameter integer NUM_WORDS = 1
)(
    clk,
    RAM_wen_lword,
    RAM_wen_byte,
    RAM_addr,
    RAM_din,
    RAM_read_word
);

input clk;
input RAM_wen_lword;
input RAM_wen_byte;
input [`ADDR_WIDTH-1:0] RAM_addr;
input [`LWORD_WIDTH-1:0] RAM_din;
output [`LWORD_WIDTH-1:0] RAM_read_word;

integer ri;
reg [`LWORD_WIDTH-1:0] ram_word [0:NUM_WORDS-1];
reg [`LWORD_WIDTH-1:0] rmw_tmp;
wire [`ADDR_WIDTH-1:0] widx;

assign widx = RAM_addr >> 2;
assign RAM_read_word = ram_word[widx];

initial begin
    for(ri = 0; ri < NUM_WORDS; ri = ri + 1)
        ram_word[ri] = 32'h0;
end

always @(posedge clk) begin
    if(RAM_wen_byte) begin
        rmw_tmp = ram_word[widx];
        case(RAM_addr[1:0])
            2'b00: rmw_tmp[7:0]   = RAM_din[7:0];
            2'b01: rmw_tmp[15:8]  = RAM_din[7:0];
            2'b10: rmw_tmp[23:16] = RAM_din[7:0];
            2'b11: rmw_tmp[31:24] = RAM_din[7:0];
        endcase
        ram_word[widx] <= rmw_tmp;
    end else if(RAM_wen_lword)
        ram_word[widx] <= RAM_din;
end

endmodule
