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
`define BMP_TOTAL_SIZE       196662
`define ADDR_WIDTH           18

`define BMP_ROM_NUM_WORDS    (((`BMP_TOTAL_SIZE) + 3) / 4)
`define BMP_RAM_NUM_WORDS    (((`BMP_TOTAL_SIZE) + 3) / 4)
`define ROM_ADDR_WIDTH       16
`define BMP_ROM_LAST_IX      ((`BMP_ROM_NUM_WORDS) - 1)
`define BMP_FILE_HEADER_SZIE 14
`define BMP_INFO_HEADER_SZIE 40
`define BMP_HEADER_SIZE      54

// ROM/RAM Address
`define INIT_ADDR            {`ADDR_WIDTH{1'b1}}

// Latency
`define MAX_LATENCY          100_0000

`endif
