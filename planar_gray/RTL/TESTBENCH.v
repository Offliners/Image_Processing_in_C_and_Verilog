`timescale 1ns/1ps
`define CYCLE 20.0

`include "DEFINE.vh"
`include "LOAD_BMP_PLANAR_GRAY.v"
`include "PLANAR_GRAY_ALGO_IDENTITY.v"
`include "PLANAR_GRAY_MERGE_TO_BMP.v"
`include "BMP_ROM.v"
`include "BMP_LWORD_RAM.v"

module TESTBENCH();

integer k, latency, bi, wi;
integer input_bmp_id, txt_bmp_id, output_bmp_id;
`ifdef __ICARUS__
integer put_rc;
`endif
reg [7:0] pch;
reg [31:0] dword;

function [7:0] pick_byte_from_word;
    input [31:0] w;
    input [1:0] sel;
    case(sel)
        2'b00: pick_byte_from_word = w[7:0];
        2'b01: pick_byte_from_word = w[15:8];
        2'b10: pick_byte_from_word = w[23:16];
        default: pick_byte_from_word = w[31:24];
    endcase
endfunction

wire [`LWORD_WIDTH-1:0] ROM_out;
wire [`ROM_ADDR_WIDTH-1:0] ROM_addr;
wire ROM_ren;

wire py_wen;
wire [`ADDR_WIDTH-1:0] py_addr;
wire [`BYTE_WIDTH-1:0] py_in;

wire ay_wen;
wire [`ADDR_WIDTH-1:0] ay_addr;
wire [`BYTE_WIDTH-1:0] ay_in;

wire load_out_wen;
wire [`ADDR_WIDTH-1:0] load_out_addr;
wire [`BYTE_WIDTH-1:0] load_out_byte;

wire merge_out_wen;
wire [`ADDR_WIDTH-1:0] merge_out_addr;
wire [`BYTE_WIDTH-1:0] merge_out_byte;
wire [`ADDR_WIDTH-1:0] merge_planar_rd;
wire merge_done;
wire load_done;
wire algo_done;

wire [`ADDR_WIDTH-1:0] mux_y_addr = py_wen ? py_addr : (ay_wen ? ay_addr : merge_planar_rd);

wire [`LWORD_WIDTH-1:0] planar_y_word;
wire [7:0] merge_in_y = pick_byte_from_word(planar_y_word, merge_planar_rd[1:0]);

wire out_ram_wen = load_out_wen | merge_out_wen;
wire [`ADDR_WIDTH-1:0] out_ram_addr = load_out_wen ? load_out_addr : merge_out_addr;
wire [`BYTE_WIDTH-1:0] out_ram_byte = load_out_wen ? load_out_byte : merge_out_byte;
wire [`LWORD_WIDTH-1:0] bmp_ram_din = {24'h0, out_ram_byte};

reg clk;
reg rst_n;
reg in_valid;
reg [`BYTE_WIDTH-1:0] bmp_data [0:`BMP_TOTAL_SIZE-1];

always #(`CYCLE/2) clk = ~clk;

integer sim_cycle_cnt;
initial sim_cycle_cnt = 0;
always @(posedge clk) begin
    if (!rst_n)
        sim_cycle_cnt = 0;
    else begin
        sim_cycle_cnt = sim_cycle_cnt + 1;
        if (sim_cycle_cnt % 100000 == 0)
            $display("[PLANAR GRAY] %0d cycles", sim_cycle_cnt);
    end
end

initial begin
`ifdef __ICARUS__
    $dumpfile("PLANAR_GRAY.vcd");
    $dumpvars;
`endif
end

initial begin
    rst_n = 1'b1;
    latency = 0;
    force clk = 1'b0;

    input_bmp_id = $fopen(`INPUT_BMP_IMAGE_PATH, "rb");
    if(!input_bmp_id) display_fail;
    k = $fread(bmp_data, input_bmp_id);
    $fclose(input_bmp_id);

    txt_bmp_id = $fopen(`OUTPUT_BMP_RAWDATA_TXT_PATH, "w");
    for(wi = 0; wi < `BMP_ROM_NUM_WORDS; wi = wi + 1) begin
        bi = wi << 2;
        dword = 32'h0;
        if(bi + 0 < `BMP_TOTAL_SIZE) dword[7:0]   = bmp_data[bi+0];
        if(bi + 1 < `BMP_TOTAL_SIZE) dword[15:8]  = bmp_data[bi+1];
        if(bi + 2 < `BMP_TOTAL_SIZE) dword[23:16] = bmp_data[bi+2];
        if(bi + 3 < `BMP_TOTAL_SIZE) dword[31:24] = bmp_data[bi+3];
        $fwrite(txt_bmp_id, "%08h\n", dword);
    end
    $fclose(txt_bmp_id);

    #(0.5) rst_n = 0;
    #(3)   release clk;
    #(3)   rst_n = 1;

    in_valid = 1'b1;

    while(!merge_done) begin
        latency = latency + 1;
        @(negedge clk);
        if(latency > `MAX_LATENCY) display_fail;
    end
    $display("\033[0;32mThe execution latency are %d cycles\033[m", latency);
end

LOAD_BMP_PLANAR_GRAY LOADG1(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .ROM_out(ROM_out),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .out_wen_byte(load_out_wen),
    .out_addr(load_out_addr),
    .out_byte(load_out_byte),
    .py_wen(py_wen),
    .py_addr(py_addr),
    .py_in(py_in),
    .load_done(load_done)
);

PLANAR_GRAY_ALGO_IDENTITY ALGOG1(
    .clk(clk),
    .rst_n(rst_n),
    .load_done(load_done),
    .in_word_y(planar_y_word),
    .ay_wen(ay_wen),
    .ay_addr(ay_addr),
    .ay_in(ay_in),
    .algo_done(algo_done)
);

PLANAR_GRAY_MERGE_TO_BMP MERGEG1(
    .clk(clk),
    .rst_n(rst_n),
    .merge_start(algo_done),
    .in_y(merge_in_y),
    .planar_rd_addr(merge_planar_rd),
    .out_wen_byte(merge_out_wen),
    .out_addr(merge_out_addr),
    .out_byte(merge_out_byte),
    .merge_done(merge_done)
);

BMP_ROM BMP_ROM1(
    .clk(clk),
    .rst_n(rst_n),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .ROM_out(ROM_out)
);

BMP_LWORD_RAM #(.NUM_WORDS(`BMP_PLANAR_NUM_WORDS)) BMP_PLANAR_Y(
    .clk(clk),
    .RAM_wen_lword(1'b0),
    .RAM_wen_byte(py_wen | ay_wen),
    .RAM_addr(mux_y_addr),
    .RAM_din({24'h0, py_wen ? py_in : ay_in}),
    .RAM_read_word(planar_y_word)
);

BMP_LWORD_RAM #(.NUM_WORDS(`BMP_RAM_OUT_NUM_WORDS)) BMP_RAM_OUT(
    .clk(clk),
    .RAM_wen_lword(1'b0),
    .RAM_wen_byte(out_ram_wen),
    .RAM_addr(out_ram_addr),
    .RAM_din(bmp_ram_din),
    .RAM_read_word()
);

always @(posedge merge_done) begin
    @(negedge clk);
    $display("\033[0;32mOutput BMP Image!\033[m");

    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
    for(bi = 0; bi < `BMP_TOTAL_SIZE; bi = bi + 1) begin
        wi = bi >> 2;
        case (bi[1:0])
            2'b00: pch = BMP_RAM_OUT.ram_word[wi][7:0];
            2'b01: pch = BMP_RAM_OUT.ram_word[wi][15:8];
            2'b10: pch = BMP_RAM_OUT.ram_word[wi][23:16];
            2'b11: pch = BMP_RAM_OUT.ram_word[wi][31:24];
        endcase
`ifdef __ICARUS__
        put_rc = $fputc(pch, output_bmp_id);
`else
        $fwrite(output_bmp_id, "%c", pch);
`endif
    end
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
