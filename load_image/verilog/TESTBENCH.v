`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"

module TESTBENCH();

integer i, k;
integer input_bmp_id;
integer txt_bmp_id;
integer output_bmp_id;

reg clk;
reg rst_n;
reg write_valid;
reg [`BYTE_WIDTH-1:0] bmp_data [0:`BMP_TOTAL_SIZE-1];

initial begin
    $dumpfile("LOAD_BMP.vcd");
    $dumpvars;
end

initial begin
    input_bmp_id  = $fopen(`INPUT_BMP_IMAGE_PATH, "rb");
    k = $fread(bmp_data, input_bmp_id);
    $fclose(input_bmp_id);

    txt_bmp_id = $fopen(`OUTPUT_BMP_RAWDATA_TXT_PATH, "w");
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 4)
        $fwrite(txt_bmp_id, "%h %h %h %h\n", bmp_data[i], bmp_data[i+1], bmp_data[i+2], bmp_data[i+3]);

    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
end

initial begin
    clk         = 1'b0;
    rst_n       = 1'b0;  
    write_valid = 1'b0;
end

always #(`CYCLE/2) clk = ~clk;

initial begin
    #100_0000;
    $finish;
end
// initial @(write_valid) begin
//     // for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 1) begin
//     //     $fwrite();
//     // end

//     $finish;
// end

endmodule