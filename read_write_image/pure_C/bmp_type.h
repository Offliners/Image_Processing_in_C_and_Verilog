#ifndef _BMP_TYPE_H_
#define _BMP_TYPE_H_

#include "common.h"

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
    ERROR_NOT_ENOUGH_MEMORY,
    ERROR_CANNOT_READ_BMP_HEADER,
    ERROR_END
} ErrorType;

typedef struct {
    LWORD error_type;
    char * error_message;
} Error_Message;

static Error_Message error_table[ERROR_END] = {
    [NO_ERROR]                     = {.error_type = (0),      .error_message = "No error"},
    [ERROR_NOT_ENOUGH_MEMORY]      = {.error_type = (1 << 0), .error_message = "Not enough memory"},
    [ERROR_CANNOT_READ_BMP_HEADER] = {.error_type = (1 << 1), .error_message = "Cannot read BMP header"}
};

#endif