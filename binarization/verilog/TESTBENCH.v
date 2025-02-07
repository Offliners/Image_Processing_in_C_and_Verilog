`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"
`include "BGR2GRAY.v"
`include "BINARIZATION.v"
`include "BMP_ROM.v"
`include "BMP_DUAL_PORT_RAM.v"

module TESTBENCH();

integer i, k, latency;
integer input_bmp_id;
integer txt_bmp_id;
integer output_bmp_id;

wire [`BYTE_WIDTH-1:0] ROM_out;
wire ROM_valid;
wire [`ADDR_WIDTH-1:0] ROM_addr;
wire RAM_ren1, RAM_wen1;
wire RAM_ren2, RAM_wen2;
wire [`BYTE_WIDTH-1:0] RAM_in1, RAM_in2;
wire [`BYTE_WIDTH-1:0] RAM_out1, RAM_out2;
wire [`ADDR_WIDTH-1:0] RAM_addr1, RAM_addr2;
wire gray_done, done;

reg clk;
reg rst_n;
reg in_valid;
reg [`BYTE_WIDTH-1:0] bmp_data [0:`BMP_TOTAL_SIZE-1];

always #(`CYCLE/2) clk = ~clk;

initial begin
    $dumpfile("BINARIZATION.vcd");
    $dumpvars;
end

initial begin
    // Step 1: Initialize
    rst_n = 1'b1;  
    latency = 0;
    force clk = 1'b0;

    // Step 2: Read input BMP
    input_bmp_id  = $fopen(`INPUT_BMP_IMAGE_PATH, "rb");
    if(!input_bmp_id) display_fail;
    $display("\033[0;32mImage found!\033[m");
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

    // Step 5: Set timeout condition
    while(!done) begin
        latency = latency + 1;
        @(negedge clk);
        if(latency > `MAX_LATENCY) display_fail;
    end
    $display("\033[0;32mThe execution latency are %d cycles\033[m", latency);
end

BGR2GRAY BGR2GRAY1(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .ROM_out(ROM_out),
    .ROM_valid(ROM_valid),
    .ROM_addr(ROM_addr),
    .RAM_ren(RAM_ren1),
    .RAM_wen(RAM_wen1),
    .RAM_in(RAM_in1),
    .RAM_addr(RAM_addr1),
    .gray_done(gray_done)
);

BMP_ROM BMP_ROM1 (
    .clk(clk),
    .rst_n(rst_n),
    .ROM_valid(ROM_valid),
    .ROM_addr(ROM_addr),
    .ROM_out(ROM_out)
);

BMP_DUAL_PORT_RAM BMP_DUAL_PORT_RAM1(
    .clk(clk),
    .RAM_ren1(RAM_ren1),
    .RAM_wen1(RAM_wen1),
    .RAM_addr1(RAM_addr1),
    .RAM_in1(RAM_in1),
    .RAM_ren2(RAM_ren2),
    .RAM_wen2(RAM_wen2),
    .RAM_addr2(RAM_addr2),
    .RAM_in2(RAM_in2),
    .RAM_out1(RAM_out1),
    .RAM_out2(RAM_out2)
);

BINARIZATION BINARIZATION1(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .gray_done(gray_done),
    .RAM_out(RAM_out2),
    .RAM_ren(RAM_ren2),
    .RAM_wen(RAM_wen2),
    .RAM_in(RAM_in2),
    .RAM_addr(RAM_addr2),
    .done(done)
);

always @(posedge done)begin
    // Write output BMP
    $display("\033[0;32mOutput BMP Image!\033[m");
    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 4)
        $fwrite(output_bmp_id, "%u", {BMP_DUAL_PORT_RAM1.ram_data[i+3], BMP_DUAL_PORT_RAM1.ram_data[i+2], BMP_DUAL_PORT_RAM1.ram_data[i+1], BMP_DUAL_PORT_RAM1.ram_data[i]});
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