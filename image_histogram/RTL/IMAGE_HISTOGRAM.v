`include "DEFINE.vh"

module IMAGE_HISTOGRAM(
    // Input signals
    clk,
    rst_n,
    start,
    RAM_in_out,

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
input [`BYTE_WIDTH-1:0] RAM_in_out;

output reg RAM_in_ren;
output reg [`ADDR_WIDTH-1:0] RAM_in_addr;
output reg RAM_out_wen;
output reg [`BYTE_WIDTH-1:0] RAM_out_in;
output reg [`ADDR_WIDTH-1:0] RAM_out_addr;
output reg done;

localparam [2:0] IDLE        = 3'b000,
                 COPY_HEADER = 3'b001,
                 LOAD_PIXELS = 3'b010,
                 PROCESS     = 3'b011,
                 WRITE_HEAD  = 3'b100,
                 WRITE_DATA  = 3'b101,
                 FINISH      = 3'b110;

localparam integer PIXEL_DATA_SIZE = (`BMP_TOTAL_SIZE - `BMP_HEADER_SIZE);

reg [2:0] state;
reg [`ADDR_WIDTH-1:0] header_idx;
reg [31:0] load_idx;
reg [31:0] write_idx;

reg [`BYTE_WIDTH-1:0] header_data [0:`BMP_HEADER_SIZE-1];
reg [`BYTE_WIDTH-1:0] img_data [0:PIXEL_DATA_SIZE-1];
reg [`BYTE_WIDTH-1:0] out_data [0:PIXEL_DATA_SIZE-1];

integer hist [0:255];
integer i;
integer x, y;
integer idx;
integer max_count;
integer bar_height;

function [7:0] to_gray;
    input [7:0] b;
    input [7:0] g;
    input [7:0] r;
    integer s;
    begin
        s = b * 30 + g * 150 + r * 76;
        to_gray = s >> 8;
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        header_idx <= 0;
        load_idx <= 0;
        write_idx <= 0;
        done <= 1'b0;
    end else begin
        case(state)
            IDLE: begin
                done <= 1'b0;
                if(start) begin
                    header_idx <= 0;
                    state <= COPY_HEADER;
                end
            end
            COPY_HEADER: begin
                header_data[header_idx] <= RAM_in_out;
                if(header_idx == `BMP_HEADER_SIZE - 1) begin
                    load_idx <= 0;
                    state <= LOAD_PIXELS;
                end else begin
                    header_idx <= header_idx + 1;
                end
            end
            LOAD_PIXELS: begin
                img_data[load_idx] <= RAM_in_out;
                if(load_idx == PIXEL_DATA_SIZE - 1) begin
                    state <= PROCESS;
                end else begin
                    load_idx <= load_idx + 1;
                end
            end
            PROCESS: begin
                for(i = 0; i < 256; i = i + 1)
                    hist[i] = 0;

                for(y = 0; y < `BMP_HEIGHT; y = y + 1) begin
                    for(x = 0; x < `BMP_WIDTH; x = x + 1) begin
                        idx = (y * `BMP_WIDTH + x) * 3;
                        hist[to_gray(img_data[idx], img_data[idx + 1], img_data[idx + 2])] =
                            hist[to_gray(img_data[idx], img_data[idx + 1], img_data[idx + 2])] + 1;
                    end
                end

                max_count = 0;
                for(i = 0; i < 256; i = i + 1) begin
                    if(hist[i] > max_count)
                        max_count = hist[i];
                end

                // Build BMP header for 256x256, 24-bit
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

                for(i = 0; i < PIXEL_DATA_SIZE; i = i + 1)
                    out_data[i] = 8'hFF;

                for(x = 0; x < 256; x = x + 1) begin
                    if(max_count == 0)
                        bar_height = 0;
                    else
                        bar_height = (hist[x] * 255) / max_count;

                    for(y = 0; y <= bar_height; y = y + 1) begin
                        idx = ((`BMP_HEIGHT - 1 - y) * `BMP_WIDTH + x) * 3;
                        out_data[idx] = 8'h00;
                        out_data[idx + 1] = 8'h00;
                        out_data[idx + 2] = 8'h00;
                    end
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
        COPY_HEADER: begin
            RAM_in_ren = 1'b1;
            RAM_in_addr = header_idx;
        end
        LOAD_PIXELS: begin
            RAM_in_ren = 1'b1;
            RAM_in_addr = `BMP_HEADER_SIZE + load_idx[`ADDR_WIDTH-1:0];
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
