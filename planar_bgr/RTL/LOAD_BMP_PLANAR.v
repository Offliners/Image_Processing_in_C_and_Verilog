`include "DEFINE.vh"

// ROM -> BMP header bytes 0..53 to output RAM; pixel stream -> planar B, G, R (65536 bytes each).
// 4 host cycles per 32-bit ROM word (FETCH/LATCH + W0..W3).

module LOAD_BMP_PLANAR(
    clk,
    rst_n,
    in_valid,
    ROM_out,
    ROM_ren,
    ROM_addr,
    out_wen_byte,
    out_addr,
    out_byte,
    pb_wen,
    pb_addr,
    pb_in,
    pg_wen,
    pg_addr,
    pg_in,
    pr_wen,
    pr_addr,
    pr_in,
    load_done
);

input clk;
input rst_n;
input in_valid;
input [`LWORD_WIDTH-1:0] ROM_out;
output reg ROM_ren;
output reg [`ROM_ADDR_WIDTH-1:0] ROM_addr;
output reg out_wen_byte;
output reg [`ADDR_WIDTH-1:0] out_addr;
output reg [`BYTE_WIDTH-1:0] out_byte;
output reg pb_wen, pg_wen, pr_wen;
output reg [`ADDR_WIDTH-1:0] pb_addr, pg_addr, pr_addr;
output reg [`BYTE_WIDTH-1:0] pb_in, pg_in, pr_in;
output reg load_done;

localparam [2:0] IDLE  = 3'd0,
                 FETCH = 3'd1,
                 LATCH = 3'd2,
                 W0    = 3'd3,
                 W1    = 3'd4,
                 W2    = 3'd5,
                 W3    = 3'd6,
                 DONE  = 3'd7;

reg [2:0] state;
reg [`ROM_ADDR_WIDTH-1:0] word_idx;
reg [31:0] latched_word;
reg [`PLANAR_ADDR_WIDTH-1:0] pix_c;
reg [1:0] ph;

wire [17:0] ba0 = {word_idx, 2'b00};
wire [17:0] ba1 = ba0 + 18'd1;
wire [17:0] ba2 = ba0 + 18'd2;
wire [17:0] ba3 = ba0 + 18'd3;

function [7:0] pick_b;
    input [31:0] w;
    input [1:0] sel;
    begin
        case (sel)
            2'b00: pick_b = w[7:0];
            2'b01: pick_b = w[15:8];
            2'b10: pick_b = w[23:16];
            default: pick_b = w[31:24];
        endcase
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        word_idx <= 0;
        latched_word <= 0;
        pix_c <= 0;
        ph <= 0;
        load_done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                load_done <= 1'b0;
                if (in_valid) begin
                    word_idx <= 0;
                    pix_c <= 0;
                    ph <= 0;
                end
            end
            LATCH: latched_word <= ROM_out;
            W0, W1, W2, W3: begin
                if (state == W0 && ba0 >= `BMP_HEADER_SIZE && ba0 < `BMP_TOTAL_SIZE) begin
                    if (ph < 2'd2)
                        ph <= ph + 1'b1;
                    else begin
                        ph <= 2'd0;
                        pix_c <= pix_c + 1'b1;
                    end
                end else if (state == W1 && ba1 >= `BMP_HEADER_SIZE && ba1 < `BMP_TOTAL_SIZE) begin
                    if (ph < 2'd2)
                        ph <= ph + 1'b1;
                    else begin
                        ph <= 2'd0;
                        pix_c <= pix_c + 1'b1;
                    end
                end else if (state == W2 && ba2 >= `BMP_HEADER_SIZE && ba2 < `BMP_TOTAL_SIZE) begin
                    if (ph < 2'd2)
                        ph <= ph + 1'b1;
                    else begin
                        ph <= 2'd0;
                        pix_c <= pix_c + 1'b1;
                    end
                end else if (state == W3 && ba3 >= `BMP_HEADER_SIZE && ba3 < `BMP_TOTAL_SIZE) begin
                    if (ph < 2'd2)
                        ph <= ph + 1'b1;
                    else begin
                        ph <= 2'd0;
                        pix_c <= pix_c + 1'b1;
                    end
                end
                if (state == W3) begin
                    if (word_idx == `BMP_ROM_LAST_IX)
                        load_done <= 1'b1;
                    else
                        word_idx <= word_idx + 1'b1;
                end
            end
            default: ;
        endcase

        case (state)
            IDLE:  if (in_valid) state <= FETCH;
            FETCH: state <= LATCH;
            LATCH: state <= W0;
            W0:    state <= W1;
            W1:    state <= W2;
            W2:    state <= W3;
            W3:    state <= (word_idx == `BMP_ROM_LAST_IX) ? DONE : FETCH;
            DONE:  state <= DONE;
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    ROM_ren = 1'b0;
    ROM_addr = word_idx;
    out_wen_byte = 1'b0;
    out_addr = 0;
    out_byte = 0;
    pb_wen = 1'b0;
    pg_wen = 1'b0;
    pr_wen = 1'b0;
    pb_addr = {{(`ADDR_WIDTH - `PLANAR_ADDR_WIDTH){1'b0}}, pix_c};
    pg_addr = {{(`ADDR_WIDTH - `PLANAR_ADDR_WIDTH){1'b0}}, pix_c};
    pr_addr = {{(`ADDR_WIDTH - `PLANAR_ADDR_WIDTH){1'b0}}, pix_c};
    pb_in = 0;
    pg_in = 0;
    pr_in = 0;

    case (state)
        FETCH: begin
            ROM_ren = 1'b1;
            ROM_addr = word_idx;
        end
        W0: begin
            if (ba0 < `BMP_HEADER_SIZE) begin
                out_wen_byte = 1'b1;
                out_addr = ba0[`ADDR_WIDTH-1:0];
                out_byte = pick_b(latched_word, 2'b00);
            end else if (ba0 < `BMP_TOTAL_SIZE) begin
                case (ph)
                    2'd0: begin
                        pb_wen = 1'b1;
                        pb_in = pick_b(latched_word, 2'b00);
                    end
                    2'd1: begin
                        pg_wen = 1'b1;
                        pg_in = pick_b(latched_word, 2'b00);
                    end
                    default: begin
                        pr_wen = 1'b1;
                        pr_in = pick_b(latched_word, 2'b00);
                    end
                endcase
            end
        end
        W1: begin
            if (ba1 < `BMP_HEADER_SIZE) begin
                out_wen_byte = 1'b1;
                out_addr = ba1[`ADDR_WIDTH-1:0];
                out_byte = pick_b(latched_word, 2'b01);
            end else if (ba1 < `BMP_TOTAL_SIZE) begin
                case (ph)
                    2'd0: begin
                        pb_wen = 1'b1;
                        pb_in = pick_b(latched_word, 2'b01);
                    end
                    2'd1: begin
                        pg_wen = 1'b1;
                        pg_in = pick_b(latched_word, 2'b01);
                    end
                    default: begin
                        pr_wen = 1'b1;
                        pr_in = pick_b(latched_word, 2'b01);
                    end
                endcase
            end
        end
        W2: begin
            if (ba2 < `BMP_HEADER_SIZE) begin
                out_wen_byte = 1'b1;
                out_addr = ba2[`ADDR_WIDTH-1:0];
                out_byte = pick_b(latched_word, 2'b10);
            end else if (ba2 < `BMP_TOTAL_SIZE) begin
                case (ph)
                    2'd0: begin
                        pb_wen = 1'b1;
                        pb_in = pick_b(latched_word, 2'b10);
                    end
                    2'd1: begin
                        pg_wen = 1'b1;
                        pg_in = pick_b(latched_word, 2'b10);
                    end
                    default: begin
                        pr_wen = 1'b1;
                        pr_in = pick_b(latched_word, 2'b10);
                    end
                endcase
            end
        end
        W3: begin
            if (ba3 < `BMP_HEADER_SIZE) begin
                out_wen_byte = 1'b1;
                out_addr = ba3[`ADDR_WIDTH-1:0];
                out_byte = pick_b(latched_word, 2'b11);
            end else if (ba3 < `BMP_TOTAL_SIZE) begin
                case (ph)
                    2'd0: begin
                        pb_wen = 1'b1;
                        pb_in = pick_b(latched_word, 2'b11);
                    end
                    2'd1: begin
                        pg_wen = 1'b1;
                        pg_in = pick_b(latched_word, 2'b11);
                    end
                    default: begin
                        pr_wen = 1'b1;
                        pr_in = pick_b(latched_word, 2'b11);
                    end
                endcase
            end
        end
        default: ;
    endcase
end

endmodule
