`include "DEFINE.vh"

module BINARIZATION(
    // Input signals
    clk,
    rst_n,
    in_valid,
    gray_done,
    RAM_out,

    // Output signals
    RAM_ren,
    RAM_wen,
    RAM_in,
    RAM_addr,
    done
);

input clk;
input rst_n;
input in_valid;
input gray_done;
input [`BYTE_WIDTH-1:0] RAM_out;

output reg RAM_ren, RAM_wen;
output reg [`BYTE_WIDTH-1:0] RAM_in;
output reg [`ADDR_WIDTH-1:0] RAM_addr;
output reg done;

integer i;
integer threshold = 8'd127;
reg [2:0] state, next_state;
reg dummy_read_done;
parameter [2:0] IDLE           = 3'b000,
                DUMMY_READ     = 3'b001,
                READ_BMP_DATA  = 3'b010,
                WRITE_BMP_DATA = 3'b011,
                OP_DONE        = 3'b100;

reg [`BYTE_WIDTH-1:0] bmp_gray_buf;

always @(negedge rst_n) begin
    if(!rst_n)
        dummy_read_done = 1'b0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case(state)
        default:
            next_state = IDLE;
        IDLE:
            next_state = (in_valid && gray_done) ? READ_BMP_DATA : IDLE;// (dummy_read_done ? READ_BMP_DATA : DUMMY_READ) : IDLE;
        DUMMY_READ:
            next_state = IDLE;
        READ_BMP_DATA:
            next_state = WRITE_BMP_DATA;
        WRITE_BMP_DATA:
            next_state = OP_DONE;
        OP_DONE:
            next_state = READ_BMP_DATA;
    endcase
end

always @(*) begin
    case(state)
        default: begin
            RAM_ren = 1'b0;
            RAM_wen = 1'b0;
        end
        IDLE: begin
            RAM_ren = 1'b0;
            RAM_wen = 1'b0;
        end
        DUMMY_READ: begin
            RAM_ren = 1'b1;
            RAM_wen = 1'b0;
        end
        READ_BMP_DATA: begin
            RAM_ren = 1'b1;
            RAM_wen = 1'b0;
        end
        WRITE_BMP_DATA: begin
            RAM_ren = 1'b0;
            RAM_wen = 1'b1;
        end
        OP_DONE: begin
            RAM_ren = 1'b0;
            RAM_wen = 1'b0;
        end
    endcase
end

always @(*) begin
    case(state)
        DUMMY_READ: begin
            dummy_read_done = 1'b1;
            bmp_gray_buf = RAM_out;
        end
        READ_BMP_DATA: begin
            bmp_gray_buf = RAM_out;
        end
        WRITE_BMP_DATA: begin
            RAM_in = bmp_gray_buf; //(bmp_gray_buf > threshold) ? 8'd255 : 8'd0;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        RAM_addr <= `BMP_HEADER_SIZE;
    else if(RAM_wen)
        RAM_addr <= RAM_addr + 1;
    else
        RAM_addr <= RAM_addr;
end

always @(*) begin
    done = (RAM_addr > `BMP_TOTAL_SIZE) ? 1 : 0;
end

endmodule