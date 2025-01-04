`include "DEFINE.vh"

module BMP_RAM (
    // Input signals
    clk,
    RAM_valid,
    in_addr,
    in_data
);

input clk;
input RAM_valid;
input in_addr;
input [`BYTE_WIDTH-1:0] in_data;

integer i;
reg [`BYTE_WIDTH-1:0] ram_data [0:`BMP_TOTAL_SIZE-1];

initial begin
    for(i = 0; i <= `BMP_TOTAL_SIZE; i = i + 1) 
        ram_data[i] = 0;
end

always @(posedge clk) begin
    if(RAM_valid)
        ram_data[in_addr] <= in_data;
end

endmodule