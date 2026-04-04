`include "DEFINE.vh"

/* Stream RGB RAW from ROM (random access) into BMP byte order with vertical flip.
 * ROM_ren/ROM_addr driven combinationally during FETCH (same pattern as LOAD_RAW).
 * Output goes to a small BYTE_SYNC_FIFO instead of a full frame buffer. */

module RAW_TO_BGR(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [`LWORD_WIDTH-1:0] ROM_out,
    output reg  ROM_ren,
    output reg  [`ROM_ADDR_WIDTH-1:0] ROM_addr,
    output reg  fifo_wr_en,
    output reg  [7:0] fifo_din,
    input  wire fifo_full,
    output reg  done
);

    localparam [2:0] ST_IDLE      = 3'd0,
                     ST_HEAD      = 3'd1,
                     ST_ROM_FETCH = 3'd2,
                     ST_ROM_LATCH = 3'd3,
                     ST_FINISH    = 3'd4;

    localparam [18:0] BMP_BYTES = `BMP_HEADER_SIZE + (`BMP_WIDTH * `BMP_HEIGHT * `BMP_CHANNEL);
    localparam [18:0] BMP_LAST  = BMP_BYTES - 1'b1;

    reg [2:0] state;
    reg [18:0] bidx;
    reg [1:0] rom_sel_r;

    reg [31:0] p_c, bmp_lin_c, bmp_row_c, bmp_col_c, raw_row_c, raw_lin_c, raw_byte_c;
    reg [`ROM_ADDR_WIDTH-1:0] rom_word_c;
    reg [7:0] hbyte_c;

    always @(*) begin
        hbyte_c = 8'h0;
        case (bidx[5:0])
            6'd0:  hbyte_c = 8'h42;
            6'd1:  hbyte_c = 8'h4D;
            6'd2:  hbyte_c = 8'h36;
            6'd3:  hbyte_c = 8'h00;
            6'd4:  hbyte_c = 8'h03;
            6'd5:  hbyte_c = 8'h00;
            6'd6:  hbyte_c = 8'h00;
            6'd7:  hbyte_c = 8'h00;
            6'd8:  hbyte_c = 8'h00;
            6'd9:  hbyte_c = 8'h00;
            6'd10: hbyte_c = 8'h36;
            6'd11: hbyte_c = 8'h00;
            6'd12: hbyte_c = 8'h00;
            6'd13: hbyte_c = 8'h00;
            6'd14: hbyte_c = 8'h28;
            6'd15: hbyte_c = 8'h00;
            6'd16: hbyte_c = 8'h00;
            6'd17: hbyte_c = 8'h00;
            6'd18: hbyte_c = 8'h00;
            6'd19: hbyte_c = 8'h01;
            6'd20: hbyte_c = 8'h00;
            6'd21: hbyte_c = 8'h00;
            6'd22: hbyte_c = 8'h00;
            6'd23: hbyte_c = 8'h01;
            6'd24: hbyte_c = 8'h00;
            6'd25: hbyte_c = 8'h00;
            6'd26: hbyte_c = 8'h01;
            6'd27: hbyte_c = 8'h00;
            6'd28: hbyte_c = 8'h18;
            6'd29: hbyte_c = 8'h00;
            6'd30: hbyte_c = 8'h00;
            6'd31: hbyte_c = 8'h00;
            6'd32: hbyte_c = 8'h00;
            6'd33: hbyte_c = 8'h00;
            6'd34: hbyte_c = 8'h00;
            6'd35: hbyte_c = 8'h00;
            6'd36: hbyte_c = 8'h03;
            6'd37: hbyte_c = 8'h00;
            6'd38: hbyte_c = 8'h00;
            6'd39: hbyte_c = 8'h00;
            6'd40: hbyte_c = 8'h00;
            6'd41: hbyte_c = 8'h00;
            6'd42: hbyte_c = 8'h00;
            6'd43: hbyte_c = 8'h00;
            6'd44: hbyte_c = 8'h00;
            6'd45: hbyte_c = 8'h00;
            6'd46: hbyte_c = 8'h00;
            6'd47: hbyte_c = 8'h00;
            6'd48: hbyte_c = 8'h00;
            6'd49: hbyte_c = 8'h00;
            6'd50: hbyte_c = 8'h00;
            6'd51: hbyte_c = 8'h00;
            6'd52: hbyte_c = 8'h00;
            6'd53: hbyte_c = 8'h00;
            default: hbyte_c = 8'h0;
        endcase
    end

    always @(*) begin
        p_c = bidx - `BMP_HEADER_SIZE;
        bmp_lin_c = p_c / 32'd3;
        bmp_row_c = bmp_lin_c / `BMP_WIDTH;
        bmp_col_c = bmp_lin_c % `BMP_WIDTH;
        raw_row_c = `BMP_HEIGHT - 32'd1 - bmp_row_c;
        raw_lin_c = raw_row_c * `BMP_WIDTH + bmp_col_c;
        raw_byte_c = raw_lin_c * 32'd3 + (32'd2 - (p_c % 32'd3));
        rom_word_c = raw_byte_c[`ROM_ADDR_WIDTH+1:2];
    end

    always @(*) begin
        ROM_ren  = 1'b0;
        ROM_addr = rom_word_c;
        case (state)
            ST_ROM_FETCH:
                if (!fifo_full && (bidx != BMP_BYTES))
                    ROM_ren = 1'b1;
            default: begin
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= ST_IDLE;
            bidx       <= 0;
            rom_sel_r  <= 0;
            done       <= 1'b0;
            fifo_wr_en <= 1'b0;
            fifo_din   <= 8'h0;
        end else begin
            fifo_wr_en <= 1'b0;
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        bidx  <= 0;
                        state <= ST_HEAD;
                    end
                end
                ST_HEAD: begin
                    if (!fifo_full) begin
                        fifo_wr_en <= 1'b1;
                        fifo_din   <= hbyte_c;
                        if (bidx == (`BMP_HEADER_SIZE - 1)) begin
                            bidx  <= `BMP_HEADER_SIZE;
                            state <= ST_ROM_FETCH;
                        end else
                            bidx <= bidx + 1'b1;
                    end
                end
                ST_ROM_FETCH: begin
                    if (!fifo_full) begin
                        if (bidx == BMP_BYTES) begin
                            done  <= 1'b1;
                            state <= ST_FINISH;
                        end else begin
                            rom_sel_r <= raw_byte_c[1:0];
                            state     <= ST_ROM_LATCH;
                        end
                    end
                end
                ST_ROM_LATCH: begin
                    if (!fifo_full) begin
                        fifo_wr_en <= 1'b1;
                        case (rom_sel_r)
                            2'b00: fifo_din <= ROM_out[7:0];
                            2'b01: fifo_din <= ROM_out[15:8];
                            2'b10: fifo_din <= ROM_out[23:16];
                            default: fifo_din <= ROM_out[31:24];
                        endcase
                        if (bidx == BMP_LAST) begin
                            bidx  <= BMP_BYTES;
                            done  <= 1'b1;
                            state <= ST_FINISH;
                        end else begin
                            bidx  <= bidx + 1'b1;
                            state <= ST_ROM_FETCH;
                        end
                    end
                end
                ST_FINISH: done <= 1'b1;
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
