`include "DEFINE.vh"

module BMP_ROM (
    // Input signals
    clk,
    rst_n,
    ROM_valid,
    ROM_addr,

    // Output signals
    ROM_Q
);

input clk;
input rst_n;
input ROM_valid;
input [`ADDR_WIDTH-1:0] ROM_addr;

output reg [`BYTE_WIDTH-1:0] ROM_Q;

reg [`BYTE_WIDTH-1:0] rom_data [0:`BMP_TOTAL_SIZE-1];

initial begin
    @(negedge rst_n) $readmemh(`OUTPUT_BMP_RAWDATA_TXT_PATH, rom_data);
end

always @(posedge clk) begin
    if(ROM_valid)
        ROM_Q <= rom_data[ROM_addr];
end

endmodule