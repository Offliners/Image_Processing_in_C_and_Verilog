`include "DEFINE.vh"

// After load_done: walk every planar byte (B then G then R per pixel) with a byte write equal
// to the current RAM read (identity RMW). Proves LOAD / ALGO / MERGE arbitration on the three planes.
// Replace this module with your kernel while keeping the same port pattern and TB mux priority.

module PLANAR_ALGO_BGR_IDENTITY(
    clk,
    rst_n,
    load_done,
    in_word_b,
    in_word_g,
    in_word_r,
    ab_wen,
    ab_addr,
    ab_in,
    ag_wen,
    ag_addr,
    ag_in,
    ar_wen,
    ar_addr,
    ar_in,
    algo_done
);

input wire clk;
input wire rst_n;
input wire load_done;
input wire [`LWORD_WIDTH-1:0] in_word_b, in_word_g, in_word_r;
output reg ab_wen, ag_wen, ar_wen;
output reg [`ADDR_WIDTH-1:0] ab_addr, ag_addr, ar_addr;
output reg [`BYTE_WIDTH-1:0] ab_in, ag_in, ar_in;
output reg algo_done;

function [7:0] pick_byte_from_word;
    input [31:0] w;
    input [1:0] sel;
    case (sel)
        2'b00: pick_byte_from_word = w[7:0];
        2'b01: pick_byte_from_word = w[15:8];
        2'b10: pick_byte_from_word = w[23:16];
        default: pick_byte_from_word = w[31:24];
    endcase
endfunction

localparam [2:0] IDLE = 3'd0,
                 WB   = 3'd1,
                 WG   = 3'd2,
                 WR   = 3'd3,
                 DONE = 3'd4;

reg [2:0] state;
reg [`PLANAR_ADDR_WIDTH-1:0] pix;

wire [`ADDR_WIDTH-1:0] padr = {{(`ADDR_WIDTH - `PLANAR_ADDR_WIDTH){1'b0}}, pix};
wire [1:0] lane = pix[1:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        pix <= 0;
        algo_done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                algo_done <= 1'b0;
                if (load_done) begin
                    pix <= 0;
                    state <= WB;
                end
            end
            WB: state <= WG;
            WG: state <= WR;
            WR: begin
                if (pix == (`PLANAR_PIXELS - 1))
                    state <= DONE;
                else begin
                    pix <= pix + 1'b1;
                    state <= WB;
                end
            end
            DONE: begin
                algo_done <= 1'b1;
                state <= DONE;
            end
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    ab_wen = 1'b0;
    ag_wen = 1'b0;
    ar_wen = 1'b0;
    ab_addr = 0;
    ag_addr = 0;
    ar_addr = 0;
    ab_in = 0;
    ag_in = 0;
    ar_in = 0;

    case (state)
        WB: begin
            ab_wen = 1'b1;
            ab_addr = padr;
            ab_in = pick_byte_from_word(in_word_b, lane);
        end
        WG: begin
            ag_wen = 1'b1;
            ag_addr = padr;
            ag_in = pick_byte_from_word(in_word_g, lane);
        end
        WR: begin
            ar_wen = 1'b1;
            ar_addr = padr;
            ar_in = pick_byte_from_word(in_word_r, lane);
        end
        default: ;
    endcase
end

// Note: merge_start (algo_done) is registered in DONE so it is not asserted in the same cycle
// as the last WR combinational write (avoids planar port contention with MERGE in that cycle).


endmodule
