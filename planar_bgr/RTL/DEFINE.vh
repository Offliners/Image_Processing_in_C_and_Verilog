`ifndef _PLANAR_BGR_DEFINE_VH_
`define _PLANAR_BGR_DEFINE_VH_

`define BYTE_WIDTH  8
`define LWORD_WIDTH 32

`define INPUT_BMP_IMAGE_PATH         "../lena256.bmp"
`define OUTPUT_BMP_RAWDATA_TXT_PATH  "./temp_bmp.txt"
`define OUTPUT_BMP_IMAGE_PATH        "./output.bmp"

`define BMP_HEIGHT           256
`define BMP_WIDTH            256
`define BMP_CHANNEL          3
`define BMP_TOTAL_SIZE       196662
`define BMP_HEADER_SIZE      54
`define BMP_PIXEL_BYTES      196608

// One plane: H*W bytes (256*256)
`define PLANAR_PIXELS        65536
`define PLANAR_ADDR_WIDTH    16

`define ADDR_WIDTH           18
`define BMP_ROM_NUM_WORDS    (((`BMP_TOTAL_SIZE) + 3) / 4)
`define BMP_RAM_OUT_NUM_WORDS (((`BMP_TOTAL_SIZE) + 3) / 4)
`define BMP_PLANAR_NUM_WORDS (((`PLANAR_PIXELS) + 3) / 4)

`define ROM_ADDR_WIDTH       16
`define BMP_ROM_LAST_IX      ((`BMP_ROM_NUM_WORDS) - 1)

`define MAX_LATENCY          100_0000

`endif
