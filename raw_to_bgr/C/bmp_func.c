#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "bmp_type.h"

static BMPImage *create_bmp(LWORD width, LWORD height)
{
    if(width == 0 || height == 0)
        return NULL;

    BMPImage *img = (BMPImage*)calloc(1, sizeof(BMPImage));
    if(!img)
        return NULL;

    img->header.stBMPFileHeader.u16FileType = BMP_MAGIC_NUMBER;
    img->header.stBMPFileHeader.u16Reserved1 = 0;
    img->header.stBMPFileHeader.u16Reserved2 = 0;
    img->header.stBMPFileHeader.u32PixelDataOffset = BMP_HEADER_SIZE;

    img->header.stBMPInfoHeader.u32HeaderSize = BMP_INFOHEADER_SIZE;
    img->header.stBMPInfoHeader.u32ImageWidth = width;
    img->header.stBMPInfoHeader.u32ImageHeight = height;
    img->header.stBMPInfoHeader.u16Planes = BMP_NUM_PLANE;
    img->header.stBMPInfoHeader.u16BitsPerPixel = BMP_BITS_PER_PIXEL;
    img->header.stBMPInfoHeader.u32Compression = BMP_COMPRESSION;
    img->header.stBMPInfoHeader.u32XpixelsPerMeter = 0;
    img->header.stBMPInfoHeader.u32YpixelsPerMeter = 0;
    img->header.stBMPInfoHeader.u32TotalColors = BMP_TOTAL_COLORS;
    img->header.stBMPInfoHeader.u32ImportantColors = BMP_IMPORTANT_COLORS;

    LWORD image_size = get_image_size_by_bytes(&img->header);
    img->header.stBMPInfoHeader.u32ImageSize = image_size;
    img->header.stBMPFileHeader.u32FileSize = BMP_HEADER_SIZE + image_size;

    img->p08Data = (BYTE*)malloc(image_size);
    if(!img->p08Data)
    {
        free(img);
        return NULL;
    }
    memset(img->p08Data, 0, image_size);

    return img;
}

/* raw: interleaved R,G,B per pixel (width * height * 3 bytes). BMP stores B,G,R. */
BMPImage *raw_to_bgr(const BYTE *raw, LWORD width, LWORD height)
{
    if(!raw)
        return NULL;

    BMPImage *img = create_bmp(width, height);
    if(!img)
        return NULL;

    LWORD row_size = get_image_row_size_bytes(&img->header);
    LWORD y;
    LWORD x;
    for(y = 0; y < height; y++)
    {
        for(x = 0; x < width; x++)
        {
            LWORD raw_base = (y * width + x) * 3;
            LWORD out_index = y * row_size + x * 3;
            BYTE r = raw[raw_base];
            BYTE g = raw[raw_base + 1];
            BYTE b = raw[raw_base + 2];
            img->p08Data[out_index] = b;
            img->p08Data[out_index + 1] = g;
            img->p08Data[out_index + 2] = r;
        }
    }

    bmp_flip_top_bottom_inplace(img);
    return img;
}
