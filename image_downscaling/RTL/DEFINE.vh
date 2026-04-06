`ifndef _DEFINE_VH_
`define _DEFINE_VH_

// Type
`define BYTE_WIDTH  8
`define LWORD_WIDTH 32

// BMP file path (input is 256x256)
`define INPUT_BMP_IMAGE_PATH         "../lena256.bmp"
`define OUTPUT_BMP_RAWDATA_TXT_PATH  "./temp_bmp.txt"
`define OUTPUT_BMP_IMAGE_PATH        "./output.bmp"

// Input BMP (loaded into RAM_IN)
`define BMP_IN_HEIGHT        256
`define BMP_IN_WIDTH         256
`define BMP_CHANNEL          3
`define BMP_TOTAL_SIZE       196662  // BMP_IN_H * BMP_IN_W * 3 + 54
`define BMP_HEADER_SIZE      54

// Output BMP (128x128, 24 bpp)
`define BMP_OUT_HEIGHT       128
`define BMP_OUT_WIDTH        128
`define BMP_OUT_PIXEL_BYTES  49152   // 128*128*3
`define BMP_OUT_TOTAL_SIZE   49206   // pixel bytes + header

`define ADDR_WIDTH           18

`define BMP_ROM_NUM_WORDS    (((`BMP_TOTAL_SIZE) + 3) / 4)
`define BMP_RAM_IN_NUM_WORDS `BMP_ROM_NUM_WORDS
`define BMP_RAM_OUT_NUM_WORDS (((`BMP_OUT_TOTAL_SIZE) + 3) / 4)
`define ROM_ADDR_WIDTH       16
`define BMP_ROM_LAST_IX      ((`BMP_ROM_NUM_WORDS) - 1)

`define BMP_FILE_HEADER_SZIE 14
`define BMP_INFO_HEADER_SZIE 40

`define INIT_ADDR            {`ADDR_WIDTH{1'b1}}

`define MAX_LATENCY          100_0000

`endif
