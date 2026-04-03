`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"
`include "LOAD_BMP.v"
`include "MEDIAN_FILTER.v"
`include "BMP_ROM.v"
`include "BMP_LWORD_RAM.v"

module TESTBENCH();

integer i, k, latency;
integer bi, wi;
integer input_bmp_id;
integer txt_bmp_id;
integer output_bmp_id;
reg [7:0] pch;
reg [31:0] dword;

function [7:0] pick_byte_from_word;
    input [31:0] w;
    input [1:0] sel;
    case(sel)
        2'b00: pick_byte_from_word = w[7:0];
        2'b01: pick_byte_from_word = w[15:8];
        2'b10: pick_byte_from_word = w[23:16];
        2'b11: pick_byte_from_word = w[31:24];
    endcase
endfunction

wire [`LWORD_WIDTH-1:0] ROM_out;
wire [`ROM_ADDR_WIDTH-1:0] ROM_addr;
wire ROM_ren;

wire load_ram_wen_lword;
wire [`LWORD_WIDTH-1:0] load_ram_din;
wire [`ADDR_WIDTH-1:0] load_ram_addr;
wire load_done;

wire algo_ram_ren;
wire [`ADDR_WIDTH-1:0] algo_ram_addr;
wire algo_ram_wen;
wire [`BYTE_WIDTH-1:0] algo_ram_in;
wire [`ADDR_WIDTH-1:0] algo_ram_out_addr;
wire done;

wire [`ADDR_WIDTH-1:0] ram_in_addr_mux;
wire ram_in_mux_wen_lword;
wire [`LWORD_WIDTH-1:0] ram_in_mux_din;
wire [7:0] ram_in_out;

assign ram_in_addr_mux = load_done ? algo_ram_addr : load_ram_addr;
assign ram_in_mux_wen_lword = load_done ? 1'b0 : load_ram_wen_lword;
assign ram_in_mux_din = load_ram_din;
assign ram_in_out = pick_byte_from_word(BMP_RAM_IN.RAM_read_word, ram_in_addr_mux[1:0]);

wire [`LWORD_WIDTH-1:0] bmp_ram_din;
assign bmp_ram_din = {24'h0, algo_ram_in};

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
        if (sim_cycle_cnt % 1000 == 0)
            $display("[TESTBENCH] %0d cycles", sim_cycle_cnt);
    end
end

initial begin
    $dumpfile("MEDIAN_FILTER.vcd");
    $dumpvars;
end

initial begin
    rst_n = 1'b1;
    latency = 0;
    force clk = 1'b0;

    input_bmp_id  = $fopen(`INPUT_BMP_IMAGE_PATH, "rb");
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

    while(!done) begin
        latency = latency + 1;
        @(negedge clk);
    end
end

LOAD_BMP LOAD_BMP1(
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .ROM_out(ROM_out),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .RAM_wen_lword(load_ram_wen_lword),
    .RAM_din(load_ram_din),
    .RAM_addr(load_ram_addr),
    .load_done(load_done)
);

MEDIAN_FILTER MEDIAN_FILTER1(
    .clk(clk),
    .rst_n(rst_n),
    .start(load_done),
    .RAM_in_out(ram_in_out),
    .RAM_in_ren(algo_ram_ren),
    .RAM_in_addr(algo_ram_addr),
    .RAM_out_wen(algo_ram_wen),
    .RAM_out_in(algo_ram_in),
    .RAM_out_addr(algo_ram_out_addr),
    .done(done)
);

BMP_ROM BMP_ROM1(
    .clk(clk),
    .rst_n(rst_n),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .ROM_out(ROM_out)
);

BMP_LWORD_RAM #(.NUM_WORDS(`BMP_RAM_NUM_WORDS)) BMP_RAM_IN(
    .clk(clk),
    .RAM_wen_lword(ram_in_mux_wen_lword),
    .RAM_wen_byte(1'b0),
    .RAM_addr(ram_in_addr_mux),
    .RAM_din(ram_in_mux_din),
    .RAM_read_word()
);

BMP_LWORD_RAM #(.NUM_WORDS(`BMP_RAM_NUM_WORDS)) BMP_RAM_OUT(
    .clk(clk),
    .RAM_wen_lword(1'b0),
    .RAM_wen_byte(algo_ram_wen),
    .RAM_addr(algo_ram_out_addr),
    .RAM_din(bmp_ram_din),
    .RAM_read_word()
);

always @(posedge done)begin
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
        $fwrite(output_bmp_id, "%c", pch);
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
