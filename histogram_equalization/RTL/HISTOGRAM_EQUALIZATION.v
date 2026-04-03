`include "DEFINE.vh"

module HISTOGRAM_EQUALIZATION(
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
integer cdf [0:255];
integer i;
integer xi, yi;
integer base_idx;
integer total_pixels;
integer cumulative;
integer cdf_min;
integer mapped;
reg [7:0] g;

function [7:0] to_gray;
    input [7:0] b;
    input [7:0] g_in;
    input [7:0] r;
    integer s;
    begin
        s = b * 30 + g_in * 150 + r * 76;
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
                total_pixels = `BMP_PIXEL_COUNT;
                for(i = 0; i < 256; i = i + 1) begin
                    hist[i] = 0;
                    cdf[i] = 0;
                end
                for(yi = 0; yi < `BMP_HEIGHT; yi = yi + 1) begin
                    for(xi = 0; xi < `BMP_WIDTH; xi = xi + 1) begin
                        base_idx = (yi * `BMP_WIDTH + xi) * 3;
                        g = to_gray(img_data[base_idx], img_data[base_idx + 1], img_data[base_idx + 2]);
                        hist[g] = hist[g] + 1;
                    end
                end
                cumulative = 0;
                for(i = 0; i < 256; i = i + 1) begin
                    cumulative = cumulative + hist[i];
                    cdf[i] = cumulative;
                end
                cdf_min = 0;
                for(i = 0; i < 256; i = i + 1) begin
                    if(cdf[i] != 0 && cdf_min == 0)
                        cdf_min = cdf[i];
                end
                for(yi = 0; yi < `BMP_HEIGHT; yi = yi + 1) begin
                    for(xi = 0; xi < `BMP_WIDTH; xi = xi + 1) begin
                        base_idx = (yi * `BMP_WIDTH + xi) * 3;
                        g = to_gray(img_data[base_idx], img_data[base_idx + 1], img_data[base_idx + 2]);
                        if(total_pixels != cdf_min) begin
                            mapped = (cdf[g] - cdf_min) * 255;
                            mapped = mapped / (total_pixels - cdf_min);
                            if(mapped > 255)
                                mapped = 255;
                            g = mapped[7:0];
                        end
                        out_data[base_idx] = g;
                        out_data[base_idx + 1] = g;
                        out_data[base_idx + 2] = g;
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
