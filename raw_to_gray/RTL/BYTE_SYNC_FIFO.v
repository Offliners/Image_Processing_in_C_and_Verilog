`timescale 1ns/1ps

/* Synchronous FIFO; rd_valid pulses one cycle with rd_data after each successful pop. */
module BYTE_SYNC_FIFO #(
    parameter integer DEPTH  = 64,
    parameter integer ADDR_W = 6
)(
    input  wire clk,
    input  wire rst_n,
    input  wire wr_en,
    input  wire [7:0] din,
    input  wire rd_en,
    output reg  [7:0] dout,
    output wire full,
    output wire empty,
    output reg  rd_valid,
    output reg  [7:0] rd_data
);

    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] wp, rp;
    reg [ADDR_W:0] cnt;

    assign full  = (cnt == DEPTH);
    assign empty = (cnt == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wp       <= 0;
            rp       <= 0;
            cnt      <= 0;
            dout     <= 8'h0;
            rd_valid <= 1'b0;
            rd_data  <= 8'h0;
        end else begin
            rd_valid <= 1'b0;
            case ({rd_en && !empty, wr_en && !full})
                2'b10: cnt <= cnt - 1'b1;
                2'b01: cnt <= cnt + 1'b1;
                default: cnt <= cnt;
            endcase
            if (wr_en && !full) begin
                mem[wp] <= din;
                wp <= (wp == (DEPTH - 1)) ? {ADDR_W{1'b0}} : wp + 1'b1;
            end
            if (rd_en && !empty) begin
                dout     <= mem[rp];
                rd_data  <= mem[rp];
                rd_valid <= 1'b1;
                rp <= (rp == (DEPTH - 1)) ? {ADDR_W{1'b0}} : rp + 1'b1;
            end
        end
    end
endmodule
