#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

BMPImage *RGB2Gray(BMPImage *src_img)
{
    LWORD i = 0;
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
    for(i = 0; i < pixel_data_size; i = i + 3)
    {
        blue  = src_img->p08Data[i];
        green = src_img->p08Data[i + 1];
        red   = src_img->p08Data[i + 2];
        gray  = (blue * 30 + green * 150 + red * 76) >> 8;

        gray_img->p08Data[i]     = gray;
        gray_img->p08Data[i + 1] = gray;
        gray_img->p08Data[i + 2] = gray;
    }

    return gray_img;
}