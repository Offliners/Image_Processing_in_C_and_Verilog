`include "DEFINE.vh"

// After load_done: identity byte write on the single gray plane (same pattern as planar_bgr algo).

module PLANAR_GRAY_ALGO_IDENTITY(
    clk,
    rst_n,
    load_done,
    in_word_y,
    ay_wen,
    ay_addr,
    ay_in,
    algo_done
);

input wire clk;
input wire rst_n;
input wire load_done;
input wire [`LWORD_WIDTH-1:0] in_word_y;
output reg ay_wen;
output reg [`ADDR_WIDTH-1:0] ay_addr;
output reg [`BYTE_WIDTH-1:0] ay_in;
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

localparam [1:0] IDLE = 2'd0,
                 RUN = 2'd1,
                 DONE = 2'd2;

reg [1:0] state;
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
                    state <= RUN;
                end
            end
            RUN: begin
                if (pix == (`PLANAR_PIXELS - 1))
                    state <= DONE;
                else
                    pix <= pix + 1'b1;
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
    ay_wen = 1'b0;
    ay_addr = 0;
    ay_in = 0;
    if (state == RUN) begin
        ay_wen = 1'b1;
        ay_addr = padr;
        ay_in = pick_byte_from_word(in_word_y, lane);
    end
end

endmodule
