#ifndef _BMP_TYPE_H_
#define _BMP_TYPE_H_

#include "common.h"

#define BMP_MAGIC_NUMBER     0x4d42  // 0x4d is "M" and 0x42 is "B"
#define BMP_NUM_PLANE        1
#define BMP_COMPRESSION      0
#define BMP_TOTAL_COLORS     0
#define BMP_IMPORTANT_COLORS 0
#define BMP_BITS_PER_PIXEL   24
#define BMP_BITS_PER_BYTE    8

// BMP format
#pragma pack(push)
#pragma pack(1)
typedef struct {
    WORD  u16FileType;
    LWORD u32FileSize;
    WORD  u16Reserved1;
    WORD  u16Reserved2;
    LWORD u32PixelDataOffset;
} BMPFileHeader;
#pragma pack(pop)

#pragma pack(push)
#pragma pack(1)
typedef struct {
    LWORD u32HeaderSize;
    LWORD u32ImageWidth;
    LWORD u32ImageHeight;
    WORD  u16Planes;
    WORD  u16BitsPerPixel;
    LWORD u32Compression;
    LWORD u32ImageSize;
    LWORD u32XpixelsPerMeter;
    LWORD u32YpixelsPerMeter;
    LWORD u32TotalColors;
    LWORD u32ImportantColors;
} BMPInfoHeader;
#pragma pack(pop)

#define BMP_FILEHEADER_SIZE (sizeof(BMPFileHeader))
#define BMP_INFOHEADER_SIZE (sizeof(BMPInfoHeader))
#define BMP_HEADER_SIZE     (BMP_FILEHEADER_SIZE + BMP_INFOHEADER_SIZE)

typedef struct {
    BMPFileHeader stBMPFileHeader;
    BMPInfoHeader stBMPInfoHeader;
} BMPHeader;

typedef struct {
    BMPHeader header;
    BYTE*     p08Data;
} BMPImage;

#pragma pack(push)
#pragma pack(1)
typedef struct {
    BYTE u08Red;
    BYTE u08Green;
    BYTE u08Blue;
    BYTE u08Reserved;
} BMPColorTable;
#pragma pack(pop)

#define BMP_COLORTABLE_SIZE (sizeof(BMPColorTable))

// Error handler
typedef enum {
    NO_ERROR,

    // Read error handler
    ERROR_NOT_ENOUGH_MEMORY,
    ERROR_CANNOT_READ_BMP_HEADER,
    ERROR_INVALID_BMP_SIGNATURE,
    ERROR_WRONG_BMP_HEADER_SIZE,
    ERROR_WRONG_BMP_INFO_HEADER_SIZE,
    ERROR_WRONG_BMP_NUM_PLANE,
    ERROR_WRONG_BMP_COMPRESSION,
    ERROR_WRONG_BMP_TOTAL_COLORS,
    ERROR_WRONG_BMP_IMPORTANT_COLORS,
    ERROR_WRONG_BMP_BITS_PER_PIXEL,
    ERROR_WRONG_BMP_FILE_SIZE,
    ERROR_WRONG_BMP_IMAGE_SIZE,
    ERROR_CANNOT_READ_PIXEL_DATA,

    // Copy error handler
    ERROR_COPY_BMP_IMAGE_FAIL,

    // Write error handler
    ERROR_CANNOT_WRITE_BMP_HEADER,
    ERROR_CANNOT_WRITE_BMP_IMAGE,
    ERROR_END
} ErrorType;

typedef struct {
    LWORD error_type;
    char *error_message;
} Error_Message;

static Error_Message error_table[ERROR_END] = {
    [NO_ERROR]                          = {.error_type = (0),       .error_message = "No error"},
    
    // Read error handler
    [ERROR_NOT_ENOUGH_MEMORY]           = {.error_type = (1),   .error_message = "Not enough memory"},
    [ERROR_CANNOT_READ_BMP_HEADER]      = {.error_type = (2),   .error_message = "Cannot read BMP header"},
    [ERROR_INVALID_BMP_SIGNATURE]       = {.error_type = (3),   .error_message = "Invalid BMP signature"},
    [ERROR_WRONG_BMP_HEADER_SIZE]       = {.error_type = (4),   .error_message = "Wrong BMP header size"},
    [ERROR_WRONG_BMP_INFO_HEADER_SIZE]  = {.error_type = (5),   .error_message = "Wrong BMP INFO header size"},
    [ERROR_WRONG_BMP_NUM_PLANE]         = {.error_type = (6),   .error_message = "Wrong BMP number of plane"},
    [ERROR_WRONG_BMP_COMPRESSION]       = {.error_type = (7),   .error_message = "Wrong BMP compression"},
    [ERROR_WRONG_BMP_TOTAL_COLORS]      = {.error_type = (8),   .error_message = "Wrong BMP total colors"},
    [ERROR_WRONG_BMP_IMPORTANT_COLORS]  = {.error_type = (9),   .error_message = "Wrong BMP important colors"},
    [ERROR_WRONG_BMP_BITS_PER_PIXEL]    = {.error_type = (10),  .error_message = "Wrong BMP bits per pixel"},
    [ERROR_WRONG_BMP_FILE_SIZE]         = {.error_type = (11), .error_message = "Wrong BMP file size"},
    [ERROR_WRONG_BMP_IMAGE_SIZE]        = {.error_type = (12), .error_message = "Wrong BMP image size"},
    [ERROR_CANNOT_READ_PIXEL_DATA]      = {.error_type = (13), .error_message = "Cannot read BMP pixel data"},

    // Copy error handler
    [ERROR_COPY_BMP_IMAGE_FAIL]         = {.error_type = (14), .error_message = "Cannot copy BMP image"},
    
    // Write error handler
    [ERROR_CANNOT_WRITE_BMP_HEADER]     = {.error_type = (15), .error_message = "Cannot write BMP header"},
    [ERROR_CANNOT_WRITE_BMP_IMAGE]      = {.error_type = (16), .error_message = "Cannot write BMP image"}
};

// BMP operation
BMPImage *read_bmp(FILE *fp, LWORD *error_record);
void *bmp_header_check(const BMPImage *img, LWORD *error_record);
BYTE error_checker(BYTE condition, LWORD *error_record, LWORD error, LWORD line);
LWORD get_image_file_size(FILE *fp);
LWORD get_image_size_by_bytes(BMPHeader *bmp_header);
LWORD get_image_row_size_bytes(BMPHeader *bmp_header);
LWORD padding_byte(BMPHeader *bmp_header);
LWORD get_bytes_per_pixel(BMPHeader *bmp_header);
BYTE write_bmp(FILE *fp, BMPImage *img, LWORD *error_record);
void show_bmp_info(const BMPImage *img);
BMPImage *copy_bmp(BMPImage *img);
void free_bmp_image(BMPImage *img);
BMPImage *RGB2Gray(BMPImage *src_img);

#endif