`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"
`include "BGR2GRAY.v"
`include "BMP_ROM.v"
`include "BMP_RAM.v"

module TESTBENCH();

integer i, k;
integer input_bmp_id;
integer txt_bmp_id;
integer output_bmp_id;

wire [`BYTE_WIDTH-1:0] ROM_Q;
wire ROM_valid;
wire [`ADDR_WIDTH-1:0] ROM_addr;
wire RAM_valid;
wire [`BYTE_WIDTH-1:0] RAM_D;
wire [`ADDR_WIDTH-1:0] RAM_addr;
wire done;

reg clk;
reg rst_n;
reg in_valid;
reg [`BYTE_WIDTH-1:0] bmp_data [0:`BMP_TOTAL_SIZE-1];

always #(`CYCLE/2) clk = ~clk;

initial begin
    $dumpfile("BGR2GRAY.vcd");
    $dumpvars;
end

initial begin
    // Step 1: Initialize
    rst_n = 1'b1;  
    force clk = 1'b0;

    // Step 2: Read input BMP
    $display("\033[0;32mImage found!\033[m");
    input_bmp_id  = $fopen(`INPUT_BMP_IMAGE_PATH, "rb");
    k = $fread(bmp_data, input_bmp_id);
    $fclose(input_bmp_id);

    // Step 3: Write BMP raw data in txt
    txt_bmp_id = $fopen(`OUTPUT_BMP_RAWDATA_TXT_PATH, "w");
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 4)
        $fwrite(txt_bmp_id, "%h %h %h %h\n", bmp_data[i], bmp_data[i+1], bmp_data[i+2], bmp_data[i+3]);
    $fclose(txt_bmp_id);

    #(0.5) rst_n = 0;
    #(3)   release clk;
    #(3)   rst_n = 1;

    // Step 4: Set in_valid
    in_valid = 1'b1;

    // Step 5:
    // if(done != 1'b1) display_fail;
end

BGR2GRAY BGR2GRAY1(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .ROM_Q(ROM_Q),
    .ROM_valid(ROM_valid),
    .ROM_addr(ROM_addr),
    .RAM_valid(RAM_valid),
    .RAM_D(RAM_D),
    .RAM_addr(RAM_addr),
    .done(done)
);

BMP_ROM BMP_ROM1 (
    .clk(clk),
    .rst_n(rst_n),
    .ROM_valid(ROM_valid),
    .ROM_addr(ROM_addr),
    .ROM_Q(ROM_Q)
);

BMP_RAM BMP_RAM1(
    .clk(clk),
    .RAM_valid(RAM_valid),
    .RAM_addr(RAM_addr),
    .RAM_D(RAM_D)
);

always @(posedge done)begin
    // Write output BMP
    $display("\033[0;32mOutput BMP Image!\033[m");
    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
    for(i = 1; i <= `BMP_TOTAL_SIZE; i = i + 4)
        $fwrite(output_bmp_id, "%u", {BMP_RAM1.ram_data[i+3], BMP_RAM1.ram_data[i+2], BMP_RAM1.ram_data[i+1], BMP_RAM1.ram_data[i]});
    $fclose(output_bmp_id);

    #(100) $finish;
end

task display_fail; begin
        $display("\033[0;31m        ----------------------------               \033[m");
        $display("\033[0;31m        --                        --       |\\__|\\\033[m");
        $display("\033[0;31m        --  OOPS!!                --      / X,X  | \033[m");
        $display("\033[0;31m        --                        --    /_____   | \033[m");
        $display("\033[0;31m        --  Simulation FAIL!!     --   /^ ^ ^ \\  |\033[m");
        $display("\033[0;31m        --                        --  |^ ^ ^ ^ |w| \033[m");
        $display("\033[0;31m        ----------------------------   \\m___m__|_|\033[m");
        $finish;
end endtask

endmodule