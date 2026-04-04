`include "DEFINE.vh"

// Stream header and pixels; mirror rows in Y. No full-frame buffers.

module VERTICAL_FLIP(
    clk, rst_n, start, RAM_in_out,
    RAM_in_ren, RAM_in_addr, RAM_out_wen, RAM_out_in, RAM_out_addr, done
);
input clk;
input rst_n;
input start;
input [`BYTE_WIDTH-1:0] RAM_in_out;
output reg RAM_in_ren;
output reg [`ADDR_WIDTH-1:0] RAM_in_addr;
output reg RAM_out_wen;
output reg [`BYTE_WIDTH-1:0] RAM_out_in;
output reg [`ADDR_WIDTH-1:0] RAM_out_addr;
output reg done;

localparam [1:0] IDLE = 2'd0, STREAM_HDR = 2'd1, STREAM_PIX = 2'd2, FINISH = 2'd3;

localparam [31:0] PIXEL_DATA_SIZE = (`BMP_TOTAL_SIZE - `BMP_HEADER_SIZE);
localparam [`ADDR_WIDTH-1:0] HDR_LAST = `BMP_HEADER_SIZE - 1;
localparam [31:0] PIXEL_LAST = PIXEL_DATA_SIZE - 1;

reg [1:0] state;
reg [`ADDR_WIDTH-1:0] hidx;
reg [31:0] pidx;

wire [31:0] pi = pidx / 32'd3;
wire [31:0] y = pi / `BMP_WIDTH;
wire [31:0] x = pi % `BMP_WIDTH;
wire [31:0] y_m = `BMP_HEIGHT - 32'd1 - y;
wire [31:0] out_pi = y_m * `BMP_WIDTH + x;
wire [31:0] out_pidx = out_pi * 32'd3 + (pidx % 32'd3);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        hidx <= 0;
        pidx <= 0;
        done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                if (start) begin
                    hidx <= 0;
                    state <= STREAM_HDR;
                end
            end
            STREAM_HDR: begin
                if (hidx == HDR_LAST) begin
                    state <= STREAM_PIX;
                    pidx <= 0;
                end
                hidx <= hidx + 1'b1;
            end
            STREAM_PIX: begin
                if (pidx == PIXEL_LAST)
                    state <= FINISH;
                else
                    pidx <= pidx + 32'd1;
            end
            FINISH: done <= 1'b1;
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    RAM_in_ren   = 1'b0;
    RAM_in_addr  = 0;
    RAM_out_wen  = 1'b0;
    RAM_out_addr = 0;
    RAM_out_in   = 0;

    case (state)
        STREAM_HDR: begin
            RAM_in_ren   = 1'b1;
            RAM_in_addr  = hidx;
            RAM_out_wen  = 1'b1;
            RAM_out_addr = hidx;
            RAM_out_in   = RAM_in_out;
        end
        STREAM_PIX: begin
            RAM_in_ren   = 1'b1;
            RAM_in_addr  = `BMP_HEADER_SIZE + pidx[`ADDR_WIDTH-1:0];
            RAM_out_wen  = 1'b1;
            RAM_out_addr = `BMP_HEADER_SIZE + out_pidx[`ADDR_WIDTH-1:0];
            RAM_out_in   = RAM_in_out;
        end
        default: begin
            RAM_in_ren  = 1'b0;
            RAM_out_wen = 1'b0;
        end
    endcase
end

endmodule
