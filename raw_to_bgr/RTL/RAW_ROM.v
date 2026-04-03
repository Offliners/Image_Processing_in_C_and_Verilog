`include "DEFINE.vh"

module RAW_ROM (
    clk,
    rst_n,
    ROM_ren,
    ROM_addr,
    ROM_out
);

input clk;
input rst_n;
input ROM_ren;
input [`ROM_ADDR_WIDTH-1:0] ROM_addr;

output reg [`LWORD_WIDTH-1:0] ROM_out;

reg [`LWORD_WIDTH-1:0] rom_data [0:`RAW_ROM_NUM_WORDS];

initial begin
    @(negedge rst_n) $readmemh(`OUTPUT_RAWDATA_TXT_PATH, rom_data);
end

always @(posedge clk) begin
    if(ROM_ren)
        ROM_out <= rom_data[ROM_addr];
end

endmodule
