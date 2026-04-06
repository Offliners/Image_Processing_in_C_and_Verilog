`include "DEFINE.vh"

// After planar SRAMs are valid (optionally post-algorithm): read B,G,R at the same pixel index
// and write interleaved BGR (file order) to output RAM.

module PLANAR_MERGE_TO_BMP(
    clk,
    rst_n,
    merge_start,
    in_b,
    in_g,
    in_r,
    planar_rd_addr,
    out_wen_byte,
    out_addr,
    out_byte,
    merge_done
);

input clk;
input rst_n;
input merge_start;
input [`BYTE_WIDTH-1:0] in_b, in_g, in_r;
output reg [`ADDR_WIDTH-1:0] planar_rd_addr;
output reg out_wen_byte;
output reg [`ADDR_WIDTH-1:0] out_addr;
output reg [`BYTE_WIDTH-1:0] out_byte;
output reg merge_done;

localparam [2:0] IDLE = 3'd0,
                 WB  = 3'd1,
                 WG  = 3'd2,
                 WR  = 3'd3,
                 FIN = 3'd4;

reg [2:0] state;
reg [`PLANAR_ADDR_WIDTH-1:0] pix;
reg merge_start_seen;

wire [`ADDR_WIDTH-1:0] padr = {{(`ADDR_WIDTH - `PLANAR_ADDR_WIDTH){1'b0}}, pix};
wire [17:0] pix_x3 = {2'b0, pix} * 18'd3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        pix <= 0;
        merge_start_seen <= 1'b0;
        merge_done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                merge_done <= 1'b0;
                if (merge_start && !merge_start_seen) begin
                    merge_start_seen <= 1'b1;
                    pix <= 0;
                    state <= WB;
                end
            end
            WB: state <= WG;
            WG: state <= WR;
            WR: begin
                if (pix == (`PLANAR_PIXELS - 1)) begin
                    state <= FIN;
                    merge_done <= 1'b1;
                end else begin
                    pix <= pix + 1'b1;
                    state <= WB;
                end
            end
            FIN: state <= FIN;
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    planar_rd_addr = 0;
    out_wen_byte = 1'b0;
    out_addr = 0;
    out_byte = 0;

    case (state)
        WB: begin
            planar_rd_addr = padr;
            out_wen_byte = 1'b1;
            out_addr = (`BMP_HEADER_SIZE + pix_x3);
            out_byte = in_b;
        end
        WG: begin
            planar_rd_addr = padr;
            out_wen_byte = 1'b1;
            out_addr = (`BMP_HEADER_SIZE + pix_x3 + 18'd1);
            out_byte = in_g;
        end
        WR: begin
            planar_rd_addr = padr;
            out_wen_byte = 1'b1;
            out_addr = (`BMP_HEADER_SIZE + pix_x3 + 18'd2);
            out_byte = in_r;
        end
        default: ;
    endcase
end

endmodule
