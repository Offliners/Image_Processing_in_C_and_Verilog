`include "DEFINE.vh"

// Pass1: histogram of B channel. Output fixed header + bar chart body (no full img/out arrays).

module IMAGE_HISTOGRAM(
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

localparam [2:0] S_IDLE = 3'd0, S_HDR_LD = 3'd1, S_PASS1 = 3'd2,
    S_BUILD = 3'd3, S_HOUT = 3'd4, S_BOUT = 3'd5, S_FIN = 3'd6;

reg [2:0] st;
reg [`ADDR_WIDTH-1:0] hix;
reg [31:0] ibi;
reg [31:0] obi;
reg [31:0] hist_mem [0:255];
reg [31:0] max_c;
reg [7:0] gh [0:53];

integer hi;
integer max_t;

initial begin
    gh[0]=8'h42; gh[1]=8'h4D; gh[2]=8'h36; gh[3]=8'h00; gh[4]=8'h03; gh[5]=8'h00;
    gh[6]=8'h00; gh[7]=8'h00; gh[8]=8'h00; gh[9]=8'h00; gh[10]=8'h36; gh[11]=8'h00;
    gh[12]=8'h00; gh[13]=8'h00; gh[14]=8'h28; gh[15]=8'h00; gh[16]=8'h00; gh[17]=8'h00;
    gh[18]=8'h00; gh[19]=8'h01; gh[20]=8'h00; gh[21]=8'h00; gh[22]=8'h00; gh[23]=8'h01;
    gh[24]=8'h00; gh[25]=8'h00; gh[26]=8'h01; gh[27]=8'h00; gh[28]=8'h18; gh[29]=8'h00;
    gh[30]=8'h00; gh[31]=8'h00; gh[32]=8'h00; gh[33]=8'h00; gh[34]=8'h00; gh[35]=8'h00;
    gh[36]=8'h03; gh[37]=8'h00; gh[38]=8'h00; gh[39]=8'h00; gh[40]=8'h00; gh[41]=8'h00;
    gh[42]=8'h00; gh[43]=8'h00; gh[44]=8'h00; gh[45]=8'h00; gh[46]=8'h00; gh[47]=8'h00;
    gh[48]=8'h00; gh[49]=8'h00; gh[50]=8'h00; gh[51]=8'h00; gh[52]=8'h00; gh[53]=8'h00;
end

wire [31:0] p2 = obi / 32'd3;
wire [31:0] x_im = p2 % `BMP_WIDTH;
wire [31:0] y_im = p2 / `BMP_WIDTH;
wire [31:0] bar_h = (max_c == 0) ? 0 : ((hist_mem[x_im] * 32'd255) / max_c);
wire [31:0] from_bot = `BMP_HEIGHT - 32'd1 - y_im;
wire is_blk = (from_bot <= bar_h);
reg [7:0] obv;

always @(*) begin
    obv = is_blk ? 8'h00 : 8'hFF;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        st <= S_IDLE;
        hix <= 0;
        ibi <= 0;
        obi <= 0;
        max_c <= 0;
        done <= 1'b0;
    end else begin
        case (st)
            S_IDLE: begin
                done <= 1'b0;
                if (start) begin
                    for (hi = 0; hi < 256; hi = hi + 1)
                        hist_mem[hi] <= 0;
                    hix <= 0;
                    st <= S_HDR_LD;
                end
            end
            S_HDR_LD: begin
                if (hix == HDR_LAST) begin
                    ibi <= 0;
                    st <= S_PASS1;
                end else
                    hix <= hix + 1'b1;
            end
            S_PASS1: begin
                if (ibi <= PIXEL_LAST) begin
                    if ((ibi % 32'd3) == 0) begin
                        hist_mem[RAM_in_out] <= hist_mem[RAM_in_out] + 32'd1;
                    end
                    ibi <= ibi + 32'd1;
                end else
                    st <= S_BUILD;
            end
            S_BUILD: begin
                max_t = 0;
                for (hi = 0; hi < 256; hi = hi + 1) begin
                    if (hist_mem[hi] > max_t)
                        max_t = hist_mem[hi];
                end
                max_c <= max_t;
                obi <= 0;
                st <= S_HOUT;
            end
            S_HOUT: begin
                if (obi == HDR_LAST) begin
                    obi <= 0;
                    st <= S_BOUT;
                end else
                    obi <= obi + 32'd1;
            end
            S_BOUT: begin
                if (obi == PIXEL_LAST) begin
                    done <= 1'b1;
                    st <= S_FIN;
                end else
                    obi <= obi + 32'd1;
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
        S_PASS1: begin
            if (ibi <= PIXEL_LAST) begin
                RAM_in_ren = 1'b1;
                RAM_in_addr = `BMP_HEADER_SIZE + ibi[`ADDR_WIDTH-1:0];
            end
        end
        S_HOUT: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = obi[`ADDR_WIDTH-1:0];
            RAM_out_in = gh[obi];
        end
        S_BOUT: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = `BMP_HEADER_SIZE + obi[`ADDR_WIDTH-1:0];
            RAM_out_in = obv;
        end
        default: begin
            RAM_in_ren = 1'b0;
            RAM_out_wen = 1'b0;
        end
    endcase
end

endmodule
