`include "DEFINE.vh"

module BMP_SINGLE_PORT_RAM (
    // Input signals
    clk,
    RAM_ren,
    RAM_wen,
    RAM_addr,
    RAM_in,

    // Output signals
    RAM_out
);

input clk;
input RAM_ren, RAM_wen;
input [`ADDR_WIDTH-1:0] RAM_addr;
input [`BYTE_WIDTH-1:0] RAM_in;

output [`BYTE_WIDTH-1:0] RAM_out;

integer i;
reg [`BYTE_WIDTH-1:0] mem_data;
reg [`BYTE_WIDTH-1:0] ram_data [0:`BMP_TOTAL_SIZE];

initial begin
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 1) 
        ram_data[i] = 0;
end

always @(posedge clk) begin
    if(RAM_wen && !RAM_ren)
        ram_data[RAM_addr] <= RAM_in;
end

assign RAM_out = (RAM_ren && (!RAM_wen)) ? ram_data[RAM_addr] : 0;

endmodule