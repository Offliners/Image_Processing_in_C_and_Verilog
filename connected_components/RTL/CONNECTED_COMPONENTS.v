`include "DEFINE.vh"

// bin_mem[]: gray > threshold (same weights as C). BFS labeling: one queue pop per states
// S_BFSPOP..S_BFS_NB3 chain (<= only in clocked always; temps via wires / second always @(*)).

module CONNECTED_COMPONENTS(
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

localparam [31:0] PIXEL_DATA_SIZE = (`BMP_TOTAL_SIZE - `BMP_HEADER_SIZE);
localparam [`ADDR_WIDTH-1:0] HDR_LAST = `BMP_HEADER_SIZE - 1;
localparam [31:0] PIXEL_LAST = PIXEL_DATA_SIZE - 1;

localparam [3:0] S_IDLE      = 4'd0;
localparam [3:0] S_HDR_LD    = 4'd1;
localparam [3:0] S_LOAD      = 4'd2;
localparam [3:0] S_CLR       = 4'd3;
localparam [3:0] S_BFS_SCAN  = 4'd4;
localparam [3:0] S_BFSPOP    = 4'd5;
localparam [3:0] S_BFS_NB0   = 4'd6;
localparam [3:0] S_BFS_NB1   = 4'd7;
localparam [3:0] S_BFS_NB2   = 4'd8;
localparam [3:0] S_BFS_NB3   = 4'd9;
localparam [3:0] S_WRITE_H   = 4'd10;
localparam [3:0] S_WRITE_B   = 4'd11;
localparam [3:0] S_FIN       = 4'd12;

reg [3:0] st;
reg [`ADDR_WIDTH-1:0] hix;
reg [31:0] ldx;
reg [31:0] wdx;
reg [31:0] scan_i;
reg [31:0] ci;
reg [31:0] label_count;
reg [`BYTE_WIDTH-1:0] hdr [0:`BMP_HEADER_SIZE-1];
reg [`BYTE_WIDTH-1:0] bin_mem [0:`BMP_PIXEL_COUNT-1];
reg [`BYTE_WIDTH-1:0] b_hold, g_hold;

reg [31:0] label_r [0:`BMP_PIXEL_COUNT-1];
reg [31:0] qx_w [0:`BMP_PIXEL_COUNT-1];
reg [31:0] qy_w [0:`BMP_PIXEL_COUNT-1];

reg [31:0] head_q;
reg [31:0] tail_q;
reg [31:0] pop_cx;
reg [31:0] pop_cy;
reg [31:0] cur_lbl_r;

wire [15:0] gray_pix = (b_hold * 16'd30 + g_hold * 16'd150 + RAM_in_out * 16'd76) >> 8;

// Neighbor linear indices (mux avoids underflow on unused side)
wire [31:0] n0_idx = (pop_cx > 0) ? (pop_cy * 32'd`BMP_WIDTH + pop_cx - 32'd1) : 32'd0;
wire [31:0] n1_idx = (pop_cx + 1 < `BMP_WIDTH) ? (pop_cy * 32'd`BMP_WIDTH + pop_cx + 32'd1) : 32'd0;
wire [31:0] n2_idx = (pop_cy > 0) ? ((pop_cy - 32'd1) * 32'd`BMP_WIDTH + pop_cx) : 32'd0;
wire [31:0] n3_idx = (pop_cy + 1 < `BMP_HEIGHT) ? ((pop_cy + 32'd1) * 32'd`BMP_WIDTH + pop_cx) : 32'd0;

// Write-back pixel color (same mapping as original C/RTL)
wire [31:0] wr_pix_lbl = label_r[wdx / 32'd3];
wire [31:0] wr_pix_mul = (wr_pix_lbl * 32'd37) & 32'd255;
wire [31:0] wr_pix_out = (wr_pix_lbl == 0) ? 32'd0 :
                         (wr_pix_mul == 0) ? 32'd1 : wr_pix_mul;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        st <= S_IDLE;
        hix <= 0;
        ldx <= 0;
        wdx <= 0;
        scan_i <= 0;
        ci <= 0;
        label_count <= 0;
        b_hold <= 0;
        g_hold <= 0;
        done <= 1'b0;
        head_q <= 0;
        tail_q <= 0;
        pop_cx <= 0;
        pop_cy <= 0;
        cur_lbl_r <= 0;
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
                    ldx <= 0;
                    st <= S_LOAD;
                end else
                    hix <= hix + 1'b1;
            end
            S_LOAD: begin
                if ((ldx % 32'd3) == 0)
                    b_hold <= RAM_in_out;
                if ((ldx % 32'd3) == 1)
                    g_hold <= RAM_in_out;
                if ((ldx % 32'd3) == 2)
                    bin_mem[ldx / 32'd3] <= (gray_pix > `BIN_THRESHOLD) ? 8'd1 : 8'd0;
                if (ldx == PIXEL_LAST) begin
                    ci <= 0;
                    st <= S_CLR;
                end else
                    ldx <= ldx + 32'd1;
            end
            S_CLR: begin
                label_r[ci] <= 0;
                if (ci == `BMP_PIXEL_COUNT - 1) begin
                    scan_i <= 0;
                    label_count <= 0;
                    st <= S_BFS_SCAN;
                end else
                    ci <= ci + 32'd1;
            end
            S_BFS_SCAN: begin
                if (scan_i >= `BMP_PIXEL_COUNT) begin
                    wdx <= 0;
                    st <= S_WRITE_H;
                end else if (bin_mem[scan_i] != 0 && label_r[scan_i] == 0) begin
                    label_r[scan_i] <= label_count + 32'd1;
                    label_count <= label_count + 32'd1;
                    cur_lbl_r <= label_count + 32'd1;
                    head_q <= 0;
                    tail_q <= 1;
                    qx_w[0] <= scan_i % `BMP_WIDTH;
                    qy_w[0] <= scan_i / `BMP_WIDTH;
                    st <= S_BFSPOP;
                end else
                    scan_i <= scan_i + 32'd1;
            end
            S_BFSPOP: begin
                if (head_q >= tail_q) begin
                    scan_i <= scan_i + 32'd1;
                    st <= S_BFS_SCAN;
                end else begin
                    pop_cx <= qx_w[head_q];
                    pop_cy <= qy_w[head_q];
                    head_q <= head_q + 32'd1;
                    st <= S_BFS_NB0;
                end
            end
            S_BFS_NB0: begin
                if (pop_cx > 0 &&
                    bin_mem[n0_idx] != 0 &&
                    label_r[n0_idx] == 0) begin
                    label_r[n0_idx] <= cur_lbl_r;
                    qx_w[tail_q] <= pop_cx - 32'd1;
                    qy_w[tail_q] <= pop_cy;
                    tail_q <= tail_q + 32'd1;
                end
                st <= S_BFS_NB1;
            end
            S_BFS_NB1: begin
                if (pop_cx + 1 < `BMP_WIDTH &&
                    bin_mem[n1_idx] != 0 &&
                    label_r[n1_idx] == 0) begin
                    label_r[n1_idx] <= cur_lbl_r;
                    qx_w[tail_q] <= pop_cx + 32'd1;
                    qy_w[tail_q] <= pop_cy;
                    tail_q <= tail_q + 32'd1;
                end
                st <= S_BFS_NB2;
            end
            S_BFS_NB2: begin
                if (pop_cy > 0 &&
                    bin_mem[n2_idx] != 0 &&
                    label_r[n2_idx] == 0) begin
                    label_r[n2_idx] <= cur_lbl_r;
                    qx_w[tail_q] <= pop_cx;
                    qy_w[tail_q] <= pop_cy - 32'd1;
                    tail_q <= tail_q + 32'd1;
                end
                st <= S_BFS_NB3;
            end
            S_BFS_NB3: begin
                if (pop_cy + 1 < `BMP_HEIGHT &&
                    bin_mem[n3_idx] != 0 &&
                    label_r[n3_idx] == 0) begin
                    label_r[n3_idx] <= cur_lbl_r;
                    qx_w[tail_q] <= pop_cx;
                    qy_w[tail_q] <= pop_cy + 32'd1;
                    tail_q <= tail_q + 32'd1;
                end
                st <= S_BFSPOP;
            end
            S_WRITE_H: begin
                if (wdx == HDR_LAST) begin
                    wdx <= 0;
                    st <= S_WRITE_B;
                end else
                    wdx <= wdx + 32'd1;
            end
            S_WRITE_B: begin
                if (wdx == PIXEL_LAST) begin
                    done <= 1'b1;
                    st <= S_FIN;
                end else
                    wdx <= wdx + 32'd1;
            end
            S_FIN: done <= 1'b1;
            default: st <= S_IDLE;
        endcase
    end
end

// Output mux: combinational; outputs driven with blocking assigns (no regs declared here)
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
        S_LOAD: begin
            RAM_in_ren = 1'b1;
            RAM_in_addr = `BMP_HEADER_SIZE + ldx[`ADDR_WIDTH-1:0];
        end
        S_WRITE_H: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = wdx[`ADDR_WIDTH-1:0];
            RAM_out_in = hdr[wdx];
        end
        S_WRITE_B: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = `BMP_HEADER_SIZE + wdx[`ADDR_WIDTH-1:0];
            RAM_out_in = wr_pix_out[7:0];
        end
        default: begin
            RAM_in_ren = 1'b0;
            RAM_out_wen = 1'b0;
        end
    endcase
end

endmodule
