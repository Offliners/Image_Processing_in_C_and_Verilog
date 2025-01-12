`include "DEFINE.vh"

module LOAD_BMP(
    // Input signals
    clk,
    rst_n,
    in_valid,
    ROM_Q,

    // Output signals
    ROM_valid,
    ROM_addr,
    RAM_valid,
    RAM_D,
    RAM_addr,
    done
);

input clk;
input rst_n;
input in_valid;
input [`BYTE_WIDTH-1:0] ROM_Q;

output reg ROM_valid;
output reg [`ADDR_WIDTH-1:0] ROM_addr;
output reg RAM_valid;
output reg [`BYTE_WIDTH-1:0] RAM_D;
output reg [`ADDR_WIDTH-1:0] RAM_addr;
output reg done;

integer i;
reg [1:0] state, next_state;
parameter [1:0] IDLE            = 2'b00, 
                READ_BMP_HEADER = 2'b01,
                READ_BMP_DATA   = 2'b10,
                WRITE           = 2'b11;

reg [1:0] bgr_count;
reg [`BYTE_WIDTH-1:0] bmp_data_buf [0:`BMP_CHANNEL-1];
reg [`BYTE_WIDTH-1:0] gray_data_buf;

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
            next_state = in_valid ? READ_BMP_HEADER : IDLE;
        READ_BMP_HEADER: 
            next_state = (ROM_addr < `BMP_HEADER_SIZE) ? WRITE : READ_BMP_DATA;
        READ_BMP_DATA:
            next_state = (bgr_count == 2'b11) ? WRITE : READ_BMP_DATA;
        WRITE:
            next_state = done ? IDLE : ((ROM_addr < `BMP_HEADER_SIZE) ? READ_BMP_HEADER : READ_BMP_DATA);
    endcase
end

always @(*) begin
    case(state)
        default: begin
            ROM_valid = 1'b0;
            RAM_valid = 1'b0;
        end
        IDLE: begin
            ROM_valid = 1'b0;
            RAM_valid = 1'b0;
        end
        READ_BMP_HEADER: begin
            ROM_valid = 1'b1;
            RAM_valid = 1'b0;
        end
        READ_BMP_DATA: begin
            ROM_valid = 1'b1;
            RAM_valid = 1'b0;
        end
        WRITE: begin
            ROM_valid = 1'b0;
            RAM_valid = 1'b1;
        end
    endcase
end

always @(*) begin
    case(state)
        READ_BMP_HEADER: begin
            bmp_data_buf[0] = ROM_Q;
        end
        READ_BMP_DATA: begin
            bmp_data_buf[bgr_count] = ROM_Q;
        end
        WRITE: begin
            if(RAM_addr < `BMP_HEADER_SIZE)
                RAM_D = bmp_data_buf[0];
            else
                RAM_D = gray_data_buf;
        end
    endcase
end

always @(*) begin
    if(bgr_count == 3'b11) begin
        gray_data_buf = (bmp_data_buf[0] * 30 + bmp_data_buf[1] * 150 + bmp_data_buf[2] * 76) >> 8;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ROM_addr <= 0;
    else if(ROM_valid)
        ROM_addr <= ROM_addr + 1;
    else
        ROM_addr <= ROM_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        RAM_addr <= 0;
    else if(RAM_valid)
        RAM_addr <= RAM_addr + 1;
    else
        RAM_addr <= RAM_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        bgr_count <= 0;
    else if(state == READ_BMP_DATA) begin
        if(bgr_count == 2'b11)
            bgr_count <= 0;
        else
            bgr_count <= bgr_count + 1;
    end
    else
        bgr_count <= bgr_count;
end

always @(*) begin
    done = (RAM_addr > `BMP_TOTAL_SIZE) ? 1 : 0;
end

endmodule