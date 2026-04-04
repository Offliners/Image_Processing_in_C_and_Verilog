`include "DEFINE.vh"

// 3-line buffer on B channel (matches legacy: gray = B only) + streaming Sobel.

module SOBEL_FILTER(
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

localparam integer RB = `BMP_WIDTH * 3;
localparam [31:0] PIXEL_DATA_SIZE = (`BMP_TOTAL_SIZE - `BMP_HEADER_SIZE);
localparam [`ADDR_WIDTH-1:0] HDR_LAST = `BMP_HEADER_SIZE - 1;
localparam [31:0] PIXEL_LAST = PIXEL_DATA_SIZE - 1;

localparam [2:0] S_IDLE = 3'd0, S_HDR_LD = 3'd1, S_HDR_OUT = 3'd2, S_STREAM = 3'd3, S_FIN = 3'd4;

reg [2:0] st;
reg [`ADDR_WIDTH-1:0] hix;
reg [`ADDR_WIDTH-1:0] oix;
reg [31:0] ibi;
reg [31:0] obi;
reg [`BYTE_WIDTH-1:0] hdr [0:`BMP_HEADER_SIZE-1];
reg [`BYTE_WIDTH-1:0] L0 [0:RB-1];
reg [`BYTE_WIDTH-1:0] L1 [0:RB-1];
reg [`BYTE_WIDTH-1:0] L2 [0:RB-1];


wire body_rd = (st == S_STREAM) && (ibi <= PIXEL_LAST);
wire [31:0] wr_py_i  = ibi / RB;
wire [31:0] wr_px_i  = (ibi / 32'd3) % `BMP_WIDTH;
wire [31:0] wr_off_i = wr_px_i * 32'd3 + (ibi % 32'd3);
wire [31:0] wr_sl_i  = wr_py_i % 32'd3;

function [`BYTE_WIDTH-1:0] f_pix;
    input [31:0] py, px, cch;
    reg [31:0] ai, off;
    reg [1:0] sl;
    begin
        ai = (py * `BMP_WIDTH + px) * 32'd3 + cch;
        off = px * 32'd3 + cch[1:0];
        sl = py % 32'd3;
        if (body_rd && (ibi == ai))
            f_pix = RAM_in_out;
        else case (sl)
            2'd0: f_pix = L0[off];
            2'd1: f_pix = L1[off];
            default: f_pix = L2[off];
        endcase
    end
endfunction

wire [31:0] ob_pix = obi / 32'd3;
wire [31:0] ox_b = ob_pix % `BMP_WIDTH;
wire [31:0] oy_b = ob_pix / `BMP_WIDTH;
wire bod = (oy_b == 0) || (ox_b == 0) || (oy_b == `BMP_HEIGHT - 1) || (ox_b == `BMP_WIDTH - 1);
wire [31:0] need_k = bod ? obi : (((oy_b + 32'd1) * `BMP_WIDTH + (ox_b + 32'd1)) * 32'd3 + 32'd2);
wire out_ok = (st == S_STREAM) && (obi <= PIXEL_LAST) && (ibi > need_k);

reg [`BYTE_WIDTH-1:0] out_val;
integer gx_c, gy_c, mag_c;

always @(*) begin
    out_val = 0;
    if (st == S_STREAM && obi <= PIXEL_LAST && out_ok) begin
        if (bod) begin
            out_val = 8'd0;
        end else begin
            gx_c = 0;
            gy_c = 0;
            gx_c = gx_c - f_pix(oy_b - 32'd1, ox_b - 32'd1, 32'd0);
            gx_c = gx_c + f_pix(oy_b - 32'd1, ox_b + 32'd1, 32'd0);
            gx_c = gx_c - (f_pix(oy_b, ox_b - 32'd1, 32'd0) << 1);
            gx_c = gx_c + (f_pix(oy_b, ox_b + 32'd1, 32'd0) << 1);
            gx_c = gx_c - f_pix(oy_b + 32'd1, ox_b - 32'd1, 32'd0);
            gx_c = gx_c + f_pix(oy_b + 32'd1, ox_b + 32'd1, 32'd0);
            gy_c = gy_c + f_pix(oy_b - 32'd1, ox_b - 32'd1, 32'd0);
            gy_c = gy_c + (f_pix(oy_b - 32'd1, ox_b, 32'd0) << 1);
            gy_c = gy_c + f_pix(oy_b - 32'd1, ox_b + 32'd1, 32'd0);
            gy_c = gy_c - f_pix(oy_b + 32'd1, ox_b - 32'd1, 32'd0);
            gy_c = gy_c - (f_pix(oy_b + 32'd1, ox_b, 32'd0) << 1);
            gy_c = gy_c - f_pix(oy_b + 32'd1, ox_b + 32'd1, 32'd0);
            if (gx_c < 0)
                gx_c = -gx_c;
            if (gy_c < 0)
                gy_c = -gy_c;
            mag_c = gx_c + gy_c;
            if (mag_c > 255)
                mag_c = 255;
            out_val = mag_c[7:0];
        end
    end
end

wire str_done = (st == S_STREAM) && (ibi > PIXEL_LAST) && (obi > PIXEL_LAST);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        st <= S_IDLE;
        hix <= 0;
        oix <= 0;
        ibi <= 0;
        obi <= 0;
        done <= 1'b0;
    end else begin
        case (st)
            S_IDLE: begin
                done <= 1'b0;
                if (start) begin
                    hix <= 0;
                    st <= S_HDR_LD;
                end
            end
            S_HDR_LD: begin
                hdr[hix] <= RAM_in_out;
                if (hix == HDR_LAST) begin
                    oix <= 0;
                    ibi <= 0;
                    obi <= 0;
                    st <= S_HDR_OUT;
                end else
                    hix <= hix + 1'b1;
            end
            S_HDR_OUT: begin
                if (oix == HDR_LAST)
                    st <= S_STREAM;
                oix <= (oix == HDR_LAST) ? oix : (oix + 1'b1);
            end
            S_STREAM: begin
                if (str_done) begin
                    done <= 1'b1;
                    st <= S_FIN;
                end else begin
                    if (body_rd) begin
                        case (wr_sl_i)
                            32'd0: L0[wr_off_i] <= RAM_in_out;
                            32'd1: L1[wr_off_i] <= RAM_in_out;
                            default: L2[wr_off_i] <= RAM_in_out;
                        endcase
                        ibi <= ibi + 32'd1;
                    end
                    if (out_ok)
                        obi <= obi + 32'd1;
                end
            end
            S_FIN: done <= 1'b1;
            default: st <= S_IDLE;
        endcase
    end
end

always @(*) begin
    RAM_in_ren = 1'b0;
    RAM_in_addr = 0;
    RAM_out_wen = 1'b0;
    RAM_out_addr = 0;
    RAM_out_in = 0;
    case (st)
        S_HDR_LD: begin
            RAM_in_ren = 1'b1;
            RAM_in_addr = hix;
        end
        S_HDR_OUT: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = oix;
            RAM_out_in = hdr[oix];
        end
        S_STREAM: begin
            if (ibi <= PIXEL_LAST) begin
                RAM_in_ren = 1'b1;
                RAM_in_addr = `BMP_HEADER_SIZE + ibi[`ADDR_WIDTH-1:0];
            end
            if (out_ok) begin
                RAM_out_wen = 1'b1;
                RAM_out_addr = `BMP_HEADER_SIZE + obi[`ADDR_WIDTH-1:0];
                RAM_out_in = out_val;
            end
        end
        default: begin
            RAM_in_ren = 1'b0;
            RAM_out_wen = 1'b0;
        end
    endcase
end

endmodule
