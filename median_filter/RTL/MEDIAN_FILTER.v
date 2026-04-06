`include "DEFINE.vh"

// 3-line BGR buffer + streaming (no full-frame buffers).

module MEDIAN_FILTER(
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
// Infer as block memory where supported; avoids megabit FF arrays in some flows.
(* ram_style = "block" *)
reg [`BYTE_WIDTH-1:0] L0 [0:RB-1];
(* ram_style = "block" *)
reg [`BYTE_WIDTH-1:0] L1 [0:RB-1];
(* ram_style = "block" *)
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
wire [31:0] och = obi % 32'd3;
wire bod = (oy_b == 0) || (ox_b == 0) || (oy_b == `BMP_HEIGHT - 1) || (ox_b == `BMP_WIDTH - 1);
wire [31:0] need_k = bod ? obi : (((oy_b + 32'd1) * `BMP_WIDTH + (ox_b + 32'd1)) * 32'd3 + 32'd2);
wire out_ok = (st == S_STREAM) && (obi <= PIXEL_LAST) && (ibi > need_k);

reg [`BYTE_WIDTH-1:0] out_val;
integer dy, dx, wj, ix;
reg [`BYTE_WIDTH-1:0] wb [0:8];
reg [`BYTE_WIDTH-1:0] wg [0:8];
reg [`BYTE_WIDTH-1:0] wr [0:8];
reg [`BYTE_WIDTH-1:0] tmp;

// Batcher odd-even mergesort (merge-sort class), n=9 — one network per channel (BGR).
task ce_b;
    input integer ii;
    input integer jj;
    begin
        if (wb[ii] > wb[jj]) begin
            tmp = wb[ii]; wb[ii] = wb[jj]; wb[jj] = tmp;
        end
    end
endtask
task ce_g;
    input integer ii;
    input integer jj;
    begin
        if (wg[ii] > wg[jj]) begin
            tmp = wg[ii]; wg[ii] = wg[jj]; wg[jj] = tmp;
        end
    end
endtask
task ce_r;
    input integer ii;
    input integer jj;
    begin
        if (wr[ii] > wr[jj]) begin
            tmp = wr[ii]; wr[ii] = wr[jj]; wr[jj] = tmp;
        end
    end
endtask

task sort9_merge_net;
    begin
        ce_b(0, 1); ce_b(2, 3); ce_b(4, 5); ce_b(6, 7);
        ce_b(0, 2); ce_b(1, 3); ce_b(4, 6); ce_b(5, 7);
        ce_b(1, 2); ce_b(5, 6);
        ce_b(0, 4); ce_b(1, 5); ce_b(2, 6); ce_b(3, 7);
        ce_b(2, 4); ce_b(3, 5);
        ce_b(1, 2); ce_b(3, 4); ce_b(5, 6);
        ce_b(0, 8); ce_b(4, 8);
        ce_b(2, 4); ce_b(3, 5);
        ce_b(6, 8);
        ce_b(1, 2); ce_b(3, 4); ce_b(5, 6); ce_b(7, 8);

        ce_g(0, 1); ce_g(2, 3); ce_g(4, 5); ce_g(6, 7);
        ce_g(0, 2); ce_g(1, 3); ce_g(4, 6); ce_g(5, 7);
        ce_g(1, 2); ce_g(5, 6);
        ce_g(0, 4); ce_g(1, 5); ce_g(2, 6); ce_g(3, 7);
        ce_g(2, 4); ce_g(3, 5);
        ce_g(1, 2); ce_g(3, 4); ce_g(5, 6);
        ce_g(0, 8); ce_g(4, 8);
        ce_g(2, 4); ce_g(3, 5);
        ce_g(6, 8);
        ce_g(1, 2); ce_g(3, 4); ce_g(5, 6); ce_g(7, 8);

        ce_r(0, 1); ce_r(2, 3); ce_r(4, 5); ce_r(6, 7);
        ce_r(0, 2); ce_r(1, 3); ce_r(4, 6); ce_r(5, 7);
        ce_r(1, 2); ce_r(5, 6);
        ce_r(0, 4); ce_r(1, 5); ce_r(2, 6); ce_r(3, 7);
        ce_r(2, 4); ce_r(3, 5);
        ce_r(1, 2); ce_r(3, 4); ce_r(5, 6);
        ce_r(0, 8); ce_r(4, 8);
        ce_r(2, 4); ce_r(3, 5);
        ce_r(6, 8);
        ce_r(1, 2); ce_r(3, 4); ce_r(5, 6); ce_r(7, 8);
    end
endtask

always @(*) begin
    out_val = 0;
    for (ix = 0; ix < 9; ix = ix + 1) begin
        wb[ix] = 8'd0;
        wg[ix] = 8'd0;
        wr[ix] = 8'd0;
    end
    if (st == S_STREAM && obi <= PIXEL_LAST && out_ok) begin
        if (bod) begin
            out_val = f_pix(oy_b, ox_b, och);
        end else begin
            wj = 0;
            for (dy = -1; dy <= 1; dy = dy + 1) begin
                for (dx = -1; dx <= 1; dx = dx + 1) begin
                    wb[wj] = f_pix(oy_b + dy, ox_b + dx, 32'd0);
                    wg[wj] = f_pix(oy_b + dy, ox_b + dx, 32'd1);
                    wr[wj] = f_pix(oy_b + dy, ox_b + dx, 32'd2);
                    wj = wj + 1;
                end
            end
            // Per-channel median: Batcher odd-even mergesort (same ordering as C merge_sort_u8).
            sort9_merge_net;
            if (och == 32'd0)
                out_val = wb[4];
            else if (och == 32'd1)
                out_val = wg[4];
            else
                out_val = wr[4];
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
