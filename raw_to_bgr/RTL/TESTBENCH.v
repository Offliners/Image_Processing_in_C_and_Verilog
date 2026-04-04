`timescale 1ns/1ps
`define CYCLE 10.0

`include "DEFINE.vh"
`include "RAW_TO_BGR.v"
`include "RAW_ROM.v"
`include "BYTE_SYNC_FIFO.v"

module TESTBENCH();

integer i, k;
integer input_raw_id;
`ifdef __ICARUS__
integer put_rc;
`endif

wire [`LWORD_WIDTH-1:0] ROM_out;
wire ROM_ren;
wire [`ROM_ADDR_WIDTH-1:0] ROM_addr;

wire fifo_wr_en;
wire [7:0] fifo_din;
wire fifo_full;
reg fifo_rd_en;
wire [7:0] fifo_dout;
wire fifo_empty;
wire fifo_rd_valid;
wire [7:0] fifo_rd_data;

wire done;

reg clk;
reg rst_n;
reg in_valid;
reg [`BYTE_WIDTH-1:0] raw_data [0:`RAW_TOTAL_SIZE-1];

wire algo_start;
assign algo_start = rst_n & in_valid;

integer output_bmp_id;
reg [18:0] bmp_written;

always #(`CYCLE/2) clk = ~clk;

integer sim_cycle_cnt;
initial sim_cycle_cnt = 0;
always @(posedge clk) begin
    if (!rst_n)
        sim_cycle_cnt = 0;
    else begin
        sim_cycle_cnt = sim_cycle_cnt + 1;
        if (sim_cycle_cnt % 100000 == 0)
            $display("[RAW TO BGR] %0d cycles", sim_cycle_cnt);
    end
end

initial begin
    $dumpfile("RAW_TO_BGR.vcd");
    $dumpvars;
end

initial begin
    rst_n = 1'b1;
    force clk = 1'b0;
    fifo_rd_en   = 1'b0;
    output_bmp_id = 0;

    input_raw_id = $fopen(`INPUT_RAW_IMAGE_PATH, "rb");
    if (!input_raw_id) display_fail;
    k = $fread(raw_data, input_raw_id);
    $fclose(input_raw_id);

    begin
        integer txt_raw_id;
        txt_raw_id = $fopen(`OUTPUT_RAWDATA_TXT_PATH, "w");
        for (i = 0; i < `RAW_TOTAL_SIZE; i = i + 4)
            $fwrite(txt_raw_id, "%08h\n", {raw_data[i+3], raw_data[i+2], raw_data[i+1], raw_data[i]});
        $fwrite(txt_raw_id, "%08h\n", 32'h0);
        $fclose(txt_raw_id);
    end

    output_bmp_id = $fopen(`OUTPUT_BMP_IMAGE_PATH, "wb");
    if (!output_bmp_id) display_fail;

    #(0.5) rst_n = 0;
    #(3)   release clk;
    #(3)   rst_n = 1;

    in_valid = 1'b1;

    begin
        integer cyc_wait;
        cyc_wait = 0;
        while (bmp_written != `BMP_TOTAL_SIZE) begin
            @(posedge clk);
            cyc_wait = cyc_wait + 1;
            if (cyc_wait > 8000000) begin
                $display("TIMEOUT bmp_written=%0d done=%b full=%b empty=%b",
                         bmp_written, done, fifo_full, fifo_empty);
                $finish(1);
            end
        end
    end

    $fclose(output_bmp_id);
    #(100) $finish;
end

always @(posedge clk) begin
    if (!rst_n)
        fifo_rd_en <= 1'b0;
    else
        fifo_rd_en <= !fifo_empty;
end

always @(posedge clk) begin
    if (!rst_n)
        bmp_written <= 0;
    else if (fifo_rd_valid) begin
`ifdef __ICARUS__
        put_rc = $fputc(fifo_rd_data, output_bmp_id);
`else
        $fwrite(output_bmp_id, "%c", fifo_rd_data);
`endif
        bmp_written <= bmp_written + 1'b1;
    end
end

RAW_TO_BGR RAW_TO_BGR1(
    .clk(clk),
    .rst_n(rst_n),
    .start(algo_start),
    .ROM_out(ROM_out),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .fifo_wr_en(fifo_wr_en),
    .fifo_din(fifo_din),
    .fifo_full(fifo_full),
    .done(done)
);

BYTE_SYNC_FIFO #(
    .DEPTH(`BMP_BYTE_FIFO_DEPTH),
    .ADDR_W(`BMP_BYTE_FIFO_AW)
) BMP_FIFO (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(fifo_wr_en),
    .din(fifo_din),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .full(fifo_full),
    .empty(fifo_empty),
    .rd_valid(fifo_rd_valid),
    .rd_data(fifo_rd_data)
);

RAW_ROM RAW_ROM1(
    .clk(clk),
    .rst_n(rst_n),
    .ROM_ren(ROM_ren),
    .ROM_addr(ROM_addr),
    .ROM_out(ROM_out)
);

task display_fail;
    begin
        $display("\033[0;31mImage not found!\033[m");
        $finish;
    end
endtask

endmodule
