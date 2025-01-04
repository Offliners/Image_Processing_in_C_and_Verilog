`include "DEFINE.vh"

module LOAD_BMP(
    // Input signals
    clk,
    rst_n,
    in_valid,
    in_data,

    // Output signals
    out_valid,
    out_data
);

input clk;
input rst_n;
input in_valid;
input [`BYTE_WIDTH-1:0] in_data;

output reg out_valid;
output reg [`BYTE_WIDTH-1:0] out_data;

integer i;
reg [1:0] state, next_state;
reg [1:0] IDLE, READ, OPERATION, WRITE;

reg [`COUNTER_WIDTH-1:0] count;
reg [`BYTE_WIDTH-1:0] bmp_data      [0:`BMP_TOTAL_SIZE-1];
reg [`BYTE_WIDTH-1:0] bmp_data_next [0:`BMP_TOTAL_SIZE-1];


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case (state)
        default:   
            next_state = IDLE;
        IDLE:      
            next_state = in_valid ? READ : IDLE;
        READ:     
            next_state = (count < `BMP_TOTAL_SIZE) ? READ : OPERATION;
        OPERATION: 
            next_state = WRITE;
        WRITE: begin
            out_valid  = 1;     
            next_state = (count < `BMP_TOTAL_SIZE) ? WRITE : IDLE;
        end
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        count <= 0;
    else
        count <= count + 1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        for(i = 0; i < `BMP_TOTAL_SIZE; i = i + 1)
            bmp_data[i] <= 0;
    else
        bmp_data[count] <= bmp_data_next[count];
end

always @(*) begin
    bmp_data_next[count] = in_valid ? in_data : bmp_data[count];
end

endmodule