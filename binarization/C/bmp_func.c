#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

BMPImage *RGB2Gray(BMPImage *src_img)
{
    LWORD u32i = 0;
    if(!src_img)
        return NULL;

    BMPImage *gray_img = (BMPImage*)malloc(sizeof(BMPImage));
    if(!gray_img)
        return NULL;

    LWORD pixel_data_size = get_image_size_by_bytes(&src_img->header);
    gray_img->header = src_img->header;
    gray_img->p08Data = (BYTE*)malloc(pixel_data_size);
    if(!gray_img->p08Data)
    {
        free(gray_img);
        return NULL;
    }

    BYTE blue, green, red, gray;
    for(u32i = 0; u32i < pixel_data_size; u32i = u32i + 3)
    {
        blue  = src_img->p08Data[u32i];
        green = src_img->p08Data[u32i + 1];
        red   = src_img->p08Data[u32i + 2];
        gray  = (blue * 30 + green * 150 + red * 76) >> 8;

        gray_img->p08Data[u32i]     = gray;
        gray_img->p08Data[u32i + 1] = gray;
        gray_img->p08Data[u32i + 2] = gray;
    }

    return gray_img;
}

BMPImage *binarize_bmp(BMPImage *src_img, BYTE threshold)
{
    LWORD u32i = 0;
    if(!src_img)
        return NULL;

    BMPImage *binary_img = (BMPImage*)malloc(sizeof(BMPImage));
    if(!binary_img)
        return NULL;

    LWORD pixel_data_size = get_image_size_by_bytes(&src_img->header);
    binary_img->header = src_img->header;
    binary_img->p08Data = (BYTE*)malloc(pixel_data_size);
    if(!binary_img->p08Data)
    {
        free(binary_img);
        return NULL;
    }

    for(u32i = 0; u32i < pixel_data_size; u32i = u32i + 1)
    {
        if(src_img->p08Data[u32i] > threshold)
            binary_img->p08Data[u32i] = WHITE_PIXEL_DATA;
        else
            binary_img->p08Data[u32i] = BLACK_PIXEL_DATA;
    }

    return binary_img;
}