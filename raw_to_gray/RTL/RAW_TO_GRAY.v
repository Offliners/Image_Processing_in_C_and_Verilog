`include "DEFINE.vh"

module RAW_TO_GRAY(
    // Input signals
    clk,
    rst_n,
    start,
    RAM_in_lword,

    // Output signals
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
input [`LWORD_WIDTH-1:0] RAM_in_lword;

output reg RAM_in_ren;
output reg [`ADDR_WIDTH-1:0] RAM_in_addr;
output reg RAM_out_wen;
output reg [`BYTE_WIDTH-1:0] RAM_out_in;
output reg [`ADDR_WIDTH-1:0] RAM_out_addr;
output reg done;

localparam [2:0] IDLE       = 3'b000,
                 LOAD_RAW   = 3'b001,
                 PROCESS    = 3'b010,
                 WRITE_HEAD = 3'b011,
                 WRITE_DATA = 3'b100,
                 FINISH     = 3'b101;

localparam integer PIXEL_DATA_SIZE = (`BMP_TOTAL_SIZE - `BMP_HEADER_SIZE);

reg [2:0] state;
reg [31:0] load_idx;
reg [31:0] write_idx;

reg [`BYTE_WIDTH-1:0] header_data [0:`BMP_HEADER_SIZE-1];
reg [`BYTE_WIDTH-1:0] raw_data [0:`RAW_TOTAL_SIZE-1];
reg [`BYTE_WIDTH-1:0] out_data [0:PIXEL_DATA_SIZE-1];

integer i;
integer pixel_idx;
integer yi, xi, dst_y, dst_base;
reg [7:0] val;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        load_idx <= 0;
        write_idx <= 0;
        done <= 1'b0;
    end else begin
        case(state)
            IDLE: begin
                done <= 1'b0;
                if(start) begin
                    load_idx <= 0;
                    state <= LOAD_RAW;
                end
            end
            LOAD_RAW: begin
                raw_data[(load_idx << 2) + 0] <= RAM_in_lword[7:0];
                raw_data[(load_idx << 2) + 1] <= RAM_in_lword[15:8];
                raw_data[(load_idx << 2) + 2] <= RAM_in_lword[23:16];
                raw_data[(load_idx << 2) + 3] <= RAM_in_lword[31:24];
                if(load_idx == (`RAW_ROM_NUM_WORDS - 1)) begin
                    state <= PROCESS;
                end else begin
                    load_idx <= load_idx + 1;
                end
            end
            PROCESS: begin
                // BMP header for 256x256 24-bit
                header_data[0]  = 8'h42;
                header_data[1]  = 8'h4D;
                header_data[2]  = 8'h36;
                header_data[3]  = 8'h00;
                header_data[4]  = 8'h03;
                header_data[5]  = 8'h00;
                header_data[6]  = 8'h00;
                header_data[7]  = 8'h00;
                header_data[8]  = 8'h00;
                header_data[9]  = 8'h00;
                header_data[10] = 8'h36;
                header_data[11] = 8'h00;
                header_data[12] = 8'h00;
                header_data[13] = 8'h00;
                header_data[14] = 8'h28;
                header_data[15] = 8'h00;
                header_data[16] = 8'h00;
                header_data[17] = 8'h00;
                header_data[18] = 8'h00;
                header_data[19] = 8'h01;
                header_data[20] = 8'h00;
                header_data[21] = 8'h00;
                header_data[22] = 8'h00;
                header_data[23] = 8'h01;
                header_data[24] = 8'h00;
                header_data[25] = 8'h00;
                header_data[26] = 8'h01;
                header_data[27] = 8'h00;
                header_data[28] = 8'h18;
                header_data[29] = 8'h00;
                header_data[30] = 8'h00;
                header_data[31] = 8'h00;
                header_data[32] = 8'h00;
                header_data[33] = 8'h00;
                header_data[34] = 8'h00;
                header_data[35] = 8'h00;
                header_data[36] = 8'h03;
                header_data[37] = 8'h00;
                header_data[38] = 8'h00;
                header_data[39] = 8'h00;
                header_data[40] = 8'h00;
                header_data[41] = 8'h00;
                header_data[42] = 8'h00;
                header_data[43] = 8'h00;
                header_data[44] = 8'h00;
                header_data[45] = 8'h00;
                header_data[46] = 8'h00;
                header_data[47] = 8'h00;
                header_data[48] = 8'h00;
                header_data[49] = 8'h00;
                header_data[50] = 8'h00;
                header_data[51] = 8'h00;
                header_data[52] = 8'h00;
                header_data[53] = 8'h00;

                for(pixel_idx = 0; pixel_idx < `RAW_TOTAL_SIZE; pixel_idx = pixel_idx + 1) begin
                    yi = pixel_idx / `BMP_WIDTH;
                    xi = pixel_idx % `BMP_WIDTH;
                    dst_y = `BMP_HEIGHT - 1 - yi;
                    dst_base = (dst_y * `BMP_WIDTH + xi) * 3;
                    val = raw_data[pixel_idx];
                    out_data[dst_base] = val;
                    out_data[dst_base + 1] = val;
                    out_data[dst_base + 2] = val;
                end
                write_idx <= 0;
                state <= WRITE_HEAD;
            end
            WRITE_HEAD: begin
                if(write_idx == `BMP_HEADER_SIZE - 1) begin
                    write_idx <= 0;
                    state <= WRITE_DATA;
                end else begin
                    write_idx <= write_idx + 1;
                end
            end
            WRITE_DATA: begin
                if(write_idx == PIXEL_DATA_SIZE - 1) begin
                    done <= 1'b1;
                    state <= FINISH;
                end else begin
                    write_idx <= write_idx + 1;
                end
            end
            FINISH: begin
                done <= 1'b1;
            end
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    RAM_in_ren = 1'b0;
    RAM_in_addr = 0;
    RAM_out_wen = 1'b0;
    RAM_out_addr = 0;
    RAM_out_in = 0;

    case(state)
        LOAD_RAW: begin
            RAM_in_ren = 1'b1;
            RAM_in_addr = {load_idx[`ROM_ADDR_WIDTH-1:0], 2'b00};
        end
        WRITE_HEAD: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = write_idx[`ADDR_WIDTH-1:0];
            RAM_out_in = header_data[write_idx];
        end
        WRITE_DATA: begin
            RAM_out_wen = 1'b1;
            RAM_out_addr = `BMP_HEADER_SIZE + write_idx[`ADDR_WIDTH-1:0];
            RAM_out_in = out_data[write_idx];
        end
        default: begin
            RAM_in_ren = 1'b0;
            RAM_out_wen = 1'b0;
        end
    endcase
end

endmodule
