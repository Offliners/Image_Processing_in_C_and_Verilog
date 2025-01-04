`include "DEFINE.vh"

module BMP_ROM (
    // Input signals
    clk,
    rst_n,
    ROM_valid,
    in_addr,

    // Output signals
    ROM_odata
);

input clk;
input rst_n;
input ROM_valid;
input [`ADDR_WIDTH-1:0] in_addr;

output reg [`BYTE_WIDTH-1:0] ROM_odata;

reg [`BYTE_WIDTH-1:0] rom_data [0:`BMP_TOTAL_SIZE-1];

initial begin
    @(negedge rst_n) $readmemh(`OUTPUT_BMP_RAWDATA_TXT_PATH, rom_data);
end

always @(posedge clk) begin
    if(ROM_valid)
        ROM_odata <= rom_data[in_addr];
end

endmodule