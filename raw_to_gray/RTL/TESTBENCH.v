`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"
`include "LOAD_RAW.v"
`include "RAW_TO_GRAY.v"
`include "RAW_ROM.v"
`include "BMP_LWORD_RAM.v"

module TESTBENCH();
integer i, k, latency;
integer bi, wi;
integer input_raw_id;
integer txt_raw_id;
integer output_bmp_id;
reg [7:0] pch;

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

wire [`ADDR_WIDTH-1:0] raw_ram_addr;
wire raw_ram_mux_wen_lword;
wire [`LWORD_WIDTH-1:0] raw_ram_din;
wire [`LWORD_WIDTH-1:0] ram_in_lword;
wire [`LWORD_WIDTH-1:0] bmp_ram_din;

assign raw_ram_addr = load_done ? algo_ram_addr : load_ram_addr;
assign raw_ram_mux_wen_lword = load_done ? 1'b0 : load_ram_wen_lword;
assign raw_ram_din = load_ram_din;
assign ram_in_lword = RAW_RAM_IN.RAM_read_word;
assign bmp_ram_din = {24'h0, algo_ram_in};

reg clk;
reg rst_n;
reg in_valid;
reg [`BYTE_WIDTH-1:0] raw_data [0:`RAW_TOTAL_SIZE-1];

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
    $dumpfile("RAW_TO_GRAY.vcd");
    $dumpvars;
end

initial begin
    rst_n = 1'b1;  
    latency = 0;
    force clk = 1'b0;

    input_raw_id  = $fopen(`INPUT_RAW_IMAGE_PATH, "rb");
    if(!input_raw_id) display_fail;
    k = $fread(raw_data, input_raw_id);
    $fclose(input_raw_id);

    txt_raw_id = $fopen(`OUTPUT_RAWDATA_TXT_PATH, "w");
    for(i = 0; i < `RAW_TOTAL_SIZE; i = i + 4)
        $fwrite(txt_raw_id, "%08h\n", {raw_data[i+3], raw_data[i+2], raw_data[i+1], raw_data[i]});
    $fwrite(txt_raw_id, "%08h\n", 32'h0);
    $fclose(txt_raw_id);

    #(0.5) rst_n = 0;
    #(3)   release clk;
    #(3)   rst_n = 1;

    in_valid = 1'b1;

    while(!done) begin
        latency = latency + 1;
        @(negedge clk);
    end
end

LOAD_RAW LOAD_RAW1(
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

BMP_LWORD_RAM #(.NUM_WORDS(`RAW_RAM_NUM_WORDS)) RAW_RAM_IN(
    .clk(clk),
    .RAM_wen_lword(raw_ram_mux_wen_lword),
    .RAM_wen_byte(1'b0),
    .RAM_addr(raw_ram_addr),
    .RAM_din(raw_ram_din),
    .RAM_read_word()
);

RAW_TO_GRAY RAW_TO_GRAY1(
    .clk(clk),
    .rst_n(rst_n),
    .start(load_done),
    .RAM_in_lword(ram_in_lword),
    .RAM_in_ren(algo_ram_ren),
    .RAM_in_addr(algo_ram_addr),
    .RAM_out_wen(algo_ram_wen),
    .RAM_out_in(algo_ram_in),
    .RAM_out_addr(algo_ram_out_addr),
    .done(done)
);

RAW_ROM RAW_ROM1(
    .clk(clk),
    .rst_n(rst_n),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .ROM_out(ROM_out)
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
        $display("\033[0;31mImage not found!\033[m");
        $finish;
end endtask

endmodule
