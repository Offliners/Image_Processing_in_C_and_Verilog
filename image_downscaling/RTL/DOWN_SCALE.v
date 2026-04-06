`include "DEFINE.vh"

// 256x256 -> 128x128: 2x2 box average per BGR channel; BMP header fields patched for output size.

module DOWN_SCALE(
    clk,
    rst_n,
    start,
    RAM_in_out,
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

localparam [2:0] IDLE   = 3'd0,
                 HDR     = 3'd1,
                 PIX     = 3'd2,
                 FINISH  = 3'd3;

localparam [5:0] HDR_LAST = 6'd53;
localparam [13:0] OUT_PX_LAST = 14'd16383;

reg [2:0] state;
reg [5:0] hidx;
reg [13:0] out_px;
reg [3:0] step;
reg [9:0] sum;

wire [6:0] oy = out_px / 14'd128;
wire [6:0] ox = out_px % 14'd128;

wire rd_b = (step < 4'd4);
wire rd_g = (step > 4'd4) && (step < 4'd9);
wire rd_r = (step > 4'd9) && (step < 4'd14);

wire [3:0] step_crn = rd_b ? step : rd_g ? (step - 4'd5) : rd_r ? (step - 4'd10) : 4'd0;
wire [1:0] crn = step_crn[1:0];

wire [1:0] ch_off = rd_b ? 2'd0 : rd_g ? 2'd1 : 2'd2;

wire [8:0] in_row = ({1'b0, oy} << 1) + {8'd0, crn[1]};
wire [8:0] in_col = ({1'b0, ox} << 1) + {8'd0, crn[0]};
wire [31:0] idx2 = {22'd0, in_row} * `BMP_IN_WIDTH + {23'd0, in_col};
wire [31:0] rd_a32 = `BMP_HEADER_SIZE + idx2 * 32'd3 + {30'd0, ch_off};
wire [`ADDR_WIDTH-1:0] rd_addr = rd_a32[`ADDR_WIDTH-1:0];

wire [1:0] wr_ch = (step == 4'd4) ? 2'd0 : (step == 4'd9) ? 2'd1 : 2'd2;
wire [31:0] wr_base = `BMP_HEADER_SIZE + {17'd0, out_px} * 32'd3;
wire [31:0] wr_a32 = wr_base + {30'd0, wr_ch};
wire [`ADDR_WIDTH-1:0] wr_addr = wr_a32[`ADDR_WIDTH-1:0];

wire [9:0] sum_p2 = sum + 10'd2;
wire [`BYTE_WIDTH-1:0] wavg = sum_p2[9:2];

function [7:0] patch_hdr;
    input [5:0] idx;
    input [7:0] din;
    begin
        case (idx)
            6'd2: patch_hdr = 8'h36;
            6'd3: patch_hdr = 8'hC0;
            6'd4: patch_hdr = 8'h00;
            6'd5: patch_hdr = 8'h00;
            6'd18: patch_hdr = 8'h80;
            6'd19: patch_hdr = 8'h00;
            6'd20: patch_hdr = 8'h00;
            6'd21: patch_hdr = 8'h00;
            6'd22: patch_hdr = 8'h80;
            6'd23: patch_hdr = 8'h00;
            6'd24: patch_hdr = 8'h00;
            6'd25: patch_hdr = 8'h00;
            6'd34: patch_hdr = 8'h00;
            6'd35: patch_hdr = 8'hC0;
            6'd36: patch_hdr = 8'h00;
            6'd37: patch_hdr = 8'h00;
            default: patch_hdr = din;
        endcase
    end
endfunction

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        hidx <= 0;
        out_px <= 0;
        step <= 0;
        sum <= 0;
        done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                if (start) begin
                    hidx <= 0;
                    state <= HDR;
                end
            end
            HDR: begin
                if (hidx == HDR_LAST) begin
                    state <= PIX;
                    out_px <= 0;
                    step <= 0;
                    sum <= 0;
                end
                hidx <= hidx + 1'b1;
            end
            PIX: begin
                if (step < 4'd4) begin
                    if (step == 4'd0)
                        sum <= RAM_in_out;
                    else
                        sum <= sum + RAM_in_out;
                    step <= step + 1'b1;
                end else if (step == 4'd4) begin
                    step <= 4'd5;
                    sum <= 0;
                end else if (step < 4'd9) begin
                    if (step == 4'd5)
                        sum <= RAM_in_out;
                    else
                        sum <= sum + RAM_in_out;
                    step <= step + 1'b1;
                end else if (step == 4'd9) begin
                    step <= 4'd10;
                    sum <= 0;
                end else if (step < 4'd14) begin
                    if (step == 4'd10)
                        sum <= RAM_in_out;
                    else
                        sum <= sum + RAM_in_out;
                    step <= step + 1'b1;
                end else begin
                    if (out_px == OUT_PX_LAST) begin
                        state <= FINISH;
                        done <= 1'b1;
                    end else begin
                        out_px <= out_px + 1'b1;
                        step <= 0;
                    end
                end
            end
            FINISH: ;
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    RAM_in_ren   = 1'b0;
    RAM_in_addr  = 0;
    RAM_out_wen  = 1'b0;
    RAM_out_addr = 0;
    RAM_out_in   = 0;

    case (state)
        HDR: begin
            RAM_in_ren   = 1'b1;
            RAM_in_addr  = hidx;
            RAM_out_wen  = 1'b1;
            RAM_out_addr = hidx;
            RAM_out_in   = patch_hdr(hidx, RAM_in_out);
        end
        PIX: begin
            if ((step < 4'd4) || (step > 4'd4 && step < 4'd9) || (step > 4'd9 && step < 4'd14)) begin
                RAM_in_ren  = 1'b1;
                RAM_in_addr = rd_addr;
            end
            if ((step == 4'd4) || (step == 4'd9) || (step == 4'd14)) begin
                RAM_out_wen  = 1'b1;
                RAM_out_addr = wr_addr;
                RAM_out_in   = wavg;
            end
        end
        default: begin
        end
    endcase
end

endmodule
