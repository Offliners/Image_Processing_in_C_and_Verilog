`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"

module TESTBENCH();

integer i, k;
integer input_bmp_id;
integer txt_bmp_id;
integer output_bmp_id;

wire [`BYTE_WIDTH-1:0] BMP_ram_data [0:`BMP_TOTAL_SIZE-1];

reg clk;
reg rst_n;
reg write_valid;
reg [`BYTE_WIDTH-1:0] bmp_data [0:`BMP_TOTAL_SIZE-1];

always #(`CYCLE/2) clk = ~clk;

initial begin
    $dumpfile("LOAD_BMP.vcd");
    $dumpvars;
end

initial begin
    // Initialize
    clk         = 1'b0;
    rst_n       = 1'b0;  
    write_valid = 1'b0;

    // Read input BMP
    $display("\033[0;32mImage found!\033[m");
    input_bmp_id  = $fopen(`INPUT_BMP_IMAGE_PATH, "rb");
    k = $fread(bmp_data, input_bmp_id);
    $fclose(input_bmp_id);

    // Write BMP raw data in txt
    txt_bmp_id = $fopen(`OUTPUT_BMP_RAWDATA_TXT_PATH, "w");
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 4)
        $fwrite(txt_bmp_id, "%h %h %h %h\n", bmp_data[i], bmp_data[i+1], bmp_data[i+2], bmp_data[i+3]);
    $fclose(txt_bmp_id);

    #(100) write_valid = 1'b1;
end

LOAD_BMP LOAD_BMP1(

);

BMP_ROM BMP_ROM1 (
    .clk(clk),
    .rst_n(rst_n),
    .ROM_valid(),
    .in_addr(),
    .ROM_odata()
);

BMP_RAM BMP_RAM1(
    .clk(clk),
    .RAM_valid(),
    .in_addr(),
    .in_data()
);

always @(posedge write_valid)begin
    // Write output BMP
    $display("\033[0;32mOutput BMP Image!\033[m");
    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
    for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 4)
        $fwrite(output_bmp_id, "%u", {BMP_ram_data[i+3], BMP_ram_data[i+2], BMP_ram_data[i+1], BMP_ram_data[i]});
    $fclose(output_bmp_id);

    #(100) $finish;
end

endmodule