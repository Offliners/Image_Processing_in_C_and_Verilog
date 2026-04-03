#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "bmp_type.h"

#define HIST_WIDTH  256
#define HIST_HEIGHT 256

static BYTE calc_gray(BYTE blue, BYTE green, BYTE red)
{
    return (BYTE)((blue * 30 + green * 150 + red * 76) >> 8);
}

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
    memset(img->p08Data, 0xFF, image_size);

    return img;
}

BMPImage *histogram_bmp(BMPImage *src_img)
{
    if(!src_img)
        return NULL;

    LWORD width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD height = src_img->header.stBMPInfoHeader.u32ImageHeight;
    LWORD row_size = get_image_row_size_bytes(&src_img->header);
    LWORD total = width * height;

    LWORD hist[256] = {0};
    for(LWORD y = 0; y < height; y++)
    {
        for(LWORD x = 0; x < width; x++)
        {
            LWORD idx = y * row_size + x * 3;
            BYTE gray = calc_gray(src_img->p08Data[idx], src_img->p08Data[idx + 1], src_img->p08Data[idx + 2]);
            hist[gray]++;
        }
    }

    LWORD max_count = 0;
    for(LWORD i = 0; i < 256; i++)
    {
        if(hist[i] > max_count)
            max_count = hist[i];
    }
    if(max_count == 0)
        return NULL;

    BMPImage *hist_img = create_bmp(HIST_WIDTH, HIST_HEIGHT);
    if(!hist_img)
        return NULL;

    LWORD hist_row_size = get_image_row_size_bytes(&hist_img->header);
    for(LWORD x = 0; x < HIST_WIDTH; x++)
    {
        LWORD bar_height = (hist[x] * (HIST_HEIGHT - 1)) / max_count;
        for(LWORD y = 0; y <= bar_height; y++)
        {
            LWORD draw_y = (HIST_HEIGHT - 1) - y;
            LWORD out_idx = draw_y * hist_row_size + x * 3;
            hist_img->p08Data[out_idx] = 0;
            hist_img->p08Data[out_idx + 1] = 0;
            hist_img->p08Data[out_idx + 2] = 0;
        }
    }

    return hist_img;
}
