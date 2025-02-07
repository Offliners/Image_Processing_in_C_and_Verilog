`ifndef _DEFINE_VH_
`define _DEFINE_VH_

// Type
`define BYTE_WIDTH  8
`define LWORD_WIDTH 32

// BMP file path
`define INPUT_BMP_IMAGE_PATH         "../lena256.bmp"
`define OUTPUT_BMP_RAWDATA_TXT_PATH  "./temp_bmp.txt"
`define OUTPUT_BMP_IMAGE_PATH        "./output.bmp"

// BMP info
`define BMP_HEIGHT           256
`define BMP_WIDTH            256
`define BMP_CHANNEL          3
`define BMP_TOTAL_SIZE       196662  // BMP_HEIGHT * BMP_WIDTH * BMP_CHANNEL + BMP_HEADER
`define ADDR_WIDTH           18      // log2_(BMP_TOTAL_SIZE)
`define BMP_FILE_HEADER_SZIE 14
`define BMP_INFO_HEADER_SZIE 40
`define BMP_HEADER           54      // BMP_FILE_HEADER_SZIE + BMP_INFO_HEADER_SZIE

// ROM/RAM Address
`define INIT_ADDR            {`ADDR_WIDTH{1'b1}}

// Latency
`define MAX_LATENCY          1_0000_0000

`endif