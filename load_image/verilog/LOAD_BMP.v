`include "DEFINE.vh"

module LOAD_BMP(
    // Input signals
    clk,
    rst_n,
    in_valid,
    ROM_out,

    // Output signals
    ROM_ren,
    ROM_addr,
    RAM_ren,
    RAM_wen,
    RAM_in,
    RAM_addr,
    done
);

input clk;
input rst_n;
input in_valid;
input [`BYTE_WIDTH-1:0] ROM_out;

output reg ROM_ren;
output reg [`ADDR_WIDTH-1:0] ROM_addr;
output reg RAM_ren, RAM_wen;
output reg [`BYTE_WIDTH-1:0] RAM_in;
output reg [`ADDR_WIDTH-1:0] RAM_addr;
output reg done;

integer i;
reg [1:0] state, next_state;
parameter [1:0] IDLE      = 2'b00, 
                READ      = 2'b01,
                WRITE     = 2'b10;

reg [`BYTE_WIDTH-1:0] bmp_data_buf;

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
            next_state = in_valid ? READ : IDLE;
        READ: 
            next_state = WRITE;
        WRITE:
            next_state = done ? IDLE : READ;
    endcase
end

always @(*) begin
    RAM_ren = 1'b0;
    case(state)
        default: begin
            ROM_ren = 1'b0;
            RAM_wen = 1'b0;
        end
        IDLE: begin
            ROM_ren = 1'b0;
            RAM_wen = 1'b0;
        end
        READ: begin
            ROM_ren = 1'b1;
            RAM_wen = 1'b0;
        end
        WRITE: begin
            ROM_ren = 1'b0;
            RAM_wen = 1'b1;
        end
    endcase
end

always @(*) begin
    case(state)
        READ: begin
            bmp_data_buf = ROM_out;
        end
        WRITE: begin
            RAM_in = bmp_data_buf;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        ROM_addr <= 0;
    else if(ROM_ren)
        ROM_addr <= ROM_addr + 1;
    else
        ROM_addr <= ROM_addr;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        RAM_addr <= `INIT_ADDR;
    else if(RAM_wen)
        RAM_addr <= RAM_addr + 1;
    else
        RAM_addr <= RAM_addr;
end

always @(*) begin
    done = (RAM_addr > `BMP_TOTAL_SIZE && RAM_addr != `INIT_ADDR) ? 1 : 0;
end

endmodule