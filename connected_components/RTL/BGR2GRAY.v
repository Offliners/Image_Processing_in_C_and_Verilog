`include "DEFINE.vh"

// Streaming: header bytes pass through; each BGR triplet -> gray (x3 for 24bpp BMP).
// Output bytes go through a byte FIFO; when fifo_cnt >= 8, drain exactly 8 bytes in 8 cycles.
// After all pixels converted, remaining FIFO bytes (<8) drain in DRAIN_TAIL.

module BGR2GRAY(
    clk,
    rst_n,
    start,
    RAM_in_out,
    RAM_in_ren,
    RAM_in_addr,
    RAM_out_wen,
    RAM_out_in,
    RAM_out_addr,
    done
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

localparam [3:0] IDLE        = 4'd0,
                 STREAM_HDR  = 4'd1,
                 STREAM_PIX  = 4'd2,
                 DRAIN8      = 4'd3,
                 DRAIN_TAIL  = 4'd4,
                 FINISH      = 4'd5;

localparam [31:0] PIXEL_DATA_SIZE = (`BMP_TOTAL_SIZE - `BMP_HEADER_SIZE);
localparam [`ADDR_WIDTH-1:0] HDR_LAST = `BMP_HEADER_SIZE - 1;
localparam [31:0] PIXEL_LAST = PIXEL_DATA_SIZE - 1;
localparam integer FIFO_DEPTH = 16;
localparam integer FIFO_AW = 4;

reg [3:0] state;
reg [`ADDR_WIDTH-1:0] out_addr;
reg [31:0] stream_pos;
reg [1:0] rgb_phase;
reg [`BYTE_WIDTH-1:0] b_hold, g_hold;
reg pix_done;

reg [`BYTE_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];
reg [FIFO_AW-1:0] wr_ptr;
reg [FIFO_AW-1:0] rd_ptr;
reg [FIFO_AW:0] fifo_cnt;

reg [3:0] drain_left;

function [`BYTE_WIDTH-1:0] gray_from_bgr;
    input [`BYTE_WIDTH-1:0] bb, gg, rr;
    reg [16:0] mx;
    begin
        mx = bb * 9'd30 + gg * 9'd150 + rr * 9'd76;
        gray_from_bgr = mx[15:8];
    end
endfunction

wire [`BYTE_WIDTH-1:0] gray_comb = gray_from_bgr(b_hold, g_hold, RAM_in_out);
wire [FIFO_AW-1:0] fifo_wp0 = wr_ptr;
wire [FIFO_AW-1:0] fifo_wp1 = wr_ptr + 1'b1;
wire [FIFO_AW-1:0] fifo_wp2 = wr_ptr + 2'd2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state    <= IDLE;
        out_addr <= 0;
        stream_pos <= 0;
        rgb_phase <= 0;
        b_hold <= 0;
        g_hold <= 0;
        pix_done <= 0;
        wr_ptr <= 0;
        rd_ptr <= 0;
        fifo_cnt <= 0;
        drain_left <= 0;
        done <= 0;
    end else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                if (start) begin
                    out_addr <= 0;
                    stream_pos <= 0;
                    rgb_phase <= 0;
                    pix_done <= 0;
                    wr_ptr <= 0;
                    rd_ptr <= 0;
                    fifo_cnt <= 0;
                    state <= STREAM_HDR;
                end
            end

            STREAM_HDR: begin
                if (out_addr == HDR_LAST)
                    state <= STREAM_PIX;
                out_addr <= out_addr + 1'b1;
            end

            STREAM_PIX: begin
                if (fifo_cnt >= 8) begin
                    state <= DRAIN8;
                    drain_left <= 4'd8;
                end else if (pix_done) begin
                    if (fifo_cnt != 0) begin
                        state <= DRAIN_TAIL;
                        drain_left <= fifo_cnt[3:0];
                    end else begin
                        state <= FINISH;
                        done <= 1'b1;
                    end
                end else begin
                    case (rgb_phase)
                        2'd0: begin
                            b_hold <= RAM_in_out;
                            rgb_phase <= 2'd1;
                            stream_pos <= stream_pos + 1'b1;
                        end
                        2'd1: begin
                            g_hold <= RAM_in_out;
                            rgb_phase <= 2'd2;
                            stream_pos <= stream_pos + 1'b1;
                        end
                        default: begin
                            fifo_mem[fifo_wp0] <= gray_comb;
                            fifo_mem[fifo_wp1] <= gray_comb;
                            fifo_mem[fifo_wp2] <= gray_comb;
                            wr_ptr <= wr_ptr + 3'd3;
                            fifo_cnt <= fifo_cnt + 3'd3;
                            rgb_phase <= 2'd0;
                            if (stream_pos == PIXEL_LAST)
                                pix_done <= 1'b1;
                            else
                                stream_pos <= stream_pos + 1'b1;
                        end
                    endcase
                end
            end

            DRAIN8: begin
                if (drain_left != 0) begin
                    rd_ptr <= rd_ptr + 1'b1;
                    fifo_cnt <= fifo_cnt - 1'b1;
                    out_addr <= out_addr + 1'b1;
                    drain_left <= drain_left - 1'b1;
                end else begin
                    if (fifo_cnt >= 8) begin
                        drain_left <= 4'd8;
                    end else if (pix_done) begin
                        if (fifo_cnt != 0) begin
                            state <= DRAIN_TAIL;
                            drain_left <= fifo_cnt[3:0];
                        end else begin
                            state <= FINISH;
                            done <= 1'b1;
                        end
                    end else
                        state <= STREAM_PIX;
                end
            end

            DRAIN_TAIL: begin
                if (drain_left != 0) begin
                    rd_ptr <= rd_ptr + 1'b1;
                    fifo_cnt <= fifo_cnt - 1'b1;
                    out_addr <= out_addr + 1'b1;
                    drain_left <= drain_left - 1'b1;
                end else begin
                    if (pix_done) begin
                        state <= FINISH;
                        done <= 1'b1;
                    end else
                        state <= STREAM_PIX;
                end
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
            RAM_in_addr  = out_addr;
            RAM_out_wen  = 1'b1;
            RAM_out_addr = out_addr;
            RAM_out_in   = RAM_in_out;
        end
        STREAM_PIX: begin
            // Drain FIFO first; do not read past last pixel once pix_done.
            if ((fifo_cnt < 8) && !pix_done) begin
                RAM_in_ren  = 1'b1;
                RAM_in_addr = `BMP_HEADER_SIZE + stream_pos[`ADDR_WIDTH-1:0];
            end
        end
        DRAIN8, DRAIN_TAIL: begin
            if (drain_left != 0) begin
                RAM_out_wen  = 1'b1;
                RAM_out_addr = out_addr;
                RAM_out_in   = fifo_mem[rd_ptr];
            end
        end
        default: begin
            RAM_in_ren   = 1'b0;
            RAM_out_wen  = 1'b0;
        end
    endcase
end

endmodule
