#ifndef _BMP_TYPE_H_
#define _BMP_TYPE_H_

#include "com_type.h"

typedef struct BMP_FILE_HEADER {
    LWORD signature;
    LWORD file_size;
    WORD  reserved1;
    WORD  reserved2;
    LWORD pixel_array_offset;
} bmp_file_header;

typedef struct BMP_



#endif