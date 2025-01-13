`include "DEFINE.vh"

module BGR2GRAY(
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
reg [2:0] state, next_state;
parameter [2:0] IDLE             = 3'b000, 
                READ_BMP_HEADER  = 3'b001,
                WRITE_BMP_HEADER = 3'b010,
                READ_BMP_DATA    = 3'b011,
                WRITE_BMP_DATA   = 3'b100;

reg [1:0] read_bgr_count, write_gray_count;
reg read_bgr_done, write_gray_done;
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
            next_state = WRITE_BMP_HEADER;
        WRITE_BMP_HEADER:
            next_state = (ROM_addr <= `BMP_HEADER_SIZE) ? READ_BMP_HEADER : READ_BMP_DATA;
        READ_BMP_DATA:
            next_state = read_bgr_done ? WRITE_BMP_DATA : READ_BMP_DATA; 
        WRITE_BMP_DATA:
            next_state = done ? IDLE : (write_gray_done ? READ_BMP_DATA : WRITE_BMP_DATA);
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
        WRITE_BMP_HEADER: begin
            ROM_valid = 1'b0;
            RAM_valid = 1'b1;
        end
        READ_BMP_DATA: begin
            ROM_valid = 1'b1;
            RAM_valid = 1'b0;
        end
        WRITE_BMP_DATA: begin
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
        WRITE_BMP_HEADER: begin
            RAM_D = bmp_data_buf[0];
        end
        READ_BMP_DATA: begin
            bmp_data_buf[read_bgr_count] = ROM_Q;
        end
        WRITE_BMP_DATA: begin
            RAM_D = gray_data_buf;
        end
    endcase
end

always @(*) begin
    if(read_bgr_done) begin
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
        read_bgr_count <= 0;
    else if(state == READ_BMP_DATA) begin
        if(read_bgr_count == 2'b10)
            read_bgr_count <= 0;
        else
            read_bgr_count <= read_bgr_count + 1;
    end
    else
        read_bgr_count <= read_bgr_count;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        write_gray_count <= 0;
    else if(state == WRITE_BMP_DATA) begin
        if(write_gray_count == 2'b10)
            write_gray_count <= 0;
        else
            write_gray_count <= write_gray_count + 1;
    end
    else
        write_gray_count <= write_gray_count;
end

always @(*) begin
    done = (RAM_addr > `BMP_TOTAL_SIZE) ? 1 : 0;
    read_bgr_done = (read_bgr_count == 2'b10) ? 1 : 0;
    write_gray_done = (write_gray_count == 2'b10) ? 1 : 0;
end

endmodule