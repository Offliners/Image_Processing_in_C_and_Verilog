`include "DEFINE.vh"

module BMP_DUAL_PORT_RAM (
    // Input signals
    clk,
    RAM_ren1,
    RAM_wen1,
    RAM_addr1,
    RAM_D1,
    RAM_ren2,
    RAM_wen2,
    RAM_addr2,
    RAM_D2,

    // Output signals
    RAM_Q1,
    RAM_Q2,
);

input clk;
input RAM_ren1, RAM_wen1;
input RAM_ren2, RAM_wen2;
input [`ADDR_WIDTH-1:0] RAM_addr1, RAM_addr2;
input [`BYTE_WIDTH-1:0] RAM_D1, RAM_D2;

output reg [`BYTE_WIDTH-1:0] RAM_Q1, RAM_Q2;

integer i;
reg [`BYTE_WIDTH-1:0] mem_data1, mem_data2;
reg [`BYTE_WIDTH-1:0] ram_data [0:`BMP_TOTAL_SIZE];

initial begin
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 1) 
        ram_data[i] = 0;
end

always @(posedge clk) begin
    if(RAM_wen1 && !RAM_ren1)
        ram_data[RAM_addr1] <= RAM_D1;
    if(RAM_ren1 && !RAM_wen1)
        mem_data1 <= ram_data[RAM_addr1];
end

always @(posedge clk) begin
    if(RAM_wen2 && !RAM_ren2)
        ram_data[RAM_addr2] <= RAM_D2;
    if(RAM_ren2 && !RAM_wen2)
        mem_data2 <= ram_data[RAM_addr2];
end

always @(*) begin
    RAM_Q1 = (RAM_ren1 && (!RAM_wen1)) ? mem_data1: 0;
    RAM_Q2 = (RAM_ren2 && (!RAM_wen2)) ? mem_data2: 0;
end

endmodule