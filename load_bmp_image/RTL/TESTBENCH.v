`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"
`ifdef GATE
`include "LOAD_BMP_SYN.v"
`else
`include "LOAD_BMP.v"
`endif
`include "BMP_ROM.v"
`include "BMP_LWORD_RAM.v"

module TESTBENCH();

integer i, k, latency;
integer bi, wi;
integer input_bmp_id;
integer txt_bmp_id;
integer output_bmp_id;
`ifdef __ICARUS__
integer put_rc;
`endif
reg [7:0] pch;
reg [31:0] dword;

wire [`LWORD_WIDTH-1:0] ROM_out;
wire [`ROM_ADDR_WIDTH-1:0] ROM_addr;
wire ROM_ren;

wire load_ram_wen_lword;
wire [`LWORD_WIDTH-1:0] load_ram_din;
wire [`ADDR_WIDTH-1:0] load_ram_addr;
wire load_done;

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
            $display("[LOAD BMP IMAGE] %0d cycles", sim_cycle_cnt);
    end
end

initial begin
`ifdef GATE
    $sdf_annotate("LOAD_BMP_SYN.sdf", LOAD_BMP1);
`endif
`ifndef GATE
    $dumpfile("LOAD_BMP.vcd");
    $dumpvars;
`endif
end

initial begin
    rst_n = 1'b1;
    latency = 0;
    force clk = 1'b0;

    $display("\033[0;32mImage found!\033[m");
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

    while(!load_done) begin
        latency = latency + 1;
        @(negedge clk);
        if(latency > `MAX_LATENCY) display_fail;
    end
    $display("\033[0;32mThe execution latency are %d cycles\033[m", latency);
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

BMP_ROM BMP_ROM1(
    .clk(clk),
    .rst_n(rst_n),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .ROM_out(ROM_out)
);

BMP_LWORD_RAM #(.NUM_WORDS(`BMP_RAM_NUM_WORDS)) BMP_RAM1(
    .clk(clk),
    .RAM_wen_lword(load_ram_wen_lword),
    .RAM_wen_byte(1'b0),
    .RAM_addr(load_ram_addr),
    .RAM_din(load_ram_din),
    .RAM_read_word()
);

always @(posedge load_done)begin
    @(negedge clk);
    $display("\033[0;32mOutput BMP Image!\033[m");
    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
    for(bi = 0; bi < `BMP_TOTAL_SIZE; bi = bi + 1) begin
        wi = bi >> 2;
        case (bi[1:0])
            2'b00: pch = BMP_RAM1.ram_word[wi][7:0];
            2'b01: pch = BMP_RAM1.ram_word[wi][15:8];
            2'b10: pch = BMP_RAM1.ram_word[wi][23:16];
            2'b11: pch = BMP_RAM1.ram_word[wi][31:24];
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
