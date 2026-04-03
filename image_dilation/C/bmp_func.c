#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

static BYTE calc_gray(BYTE blue, BYTE green, BYTE red)
{
    return (BYTE)((blue * 30 + green * 150 + red * 76) >> 8);
}

static BYTE *create_gray_buffer(const BMPImage *src_img)
{
    if(!src_img)
        return NULL;

    LWORD width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD height = src_img->header.stBMPInfoHeader.u32ImageHeight;
    LWORD row_size = get_image_row_size_bytes(&src_img->header);

    BYTE *gray = (BYTE*)malloc(width * height);
    if(!gray)
        return NULL;

    for(LWORD y = 0; y < height; y++)
    {
        for(LWORD x = 0; x < width; x++)
        {
            LWORD idx = y * row_size + x * 3;
            BYTE blue = src_img->p08Data[idx];
            BYTE green = src_img->p08Data[idx + 1];
            BYTE red = src_img->p08Data[idx + 2];
            gray[y * width + x] = calc_gray(blue, green, red);
        }
    }

    return gray;
}

BMPImage *dilate_bmp(BMPImage *src_img, BYTE threshold)
{
    if(!src_img)
        return NULL;

    LWORD width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD height = src_img->header.stBMPInfoHeader.u32ImageHeight;
    LWORD row_size = get_image_row_size_bytes(&src_img->header);

    BYTE *gray = create_gray_buffer(src_img);
    if(!gray)
        return NULL;

    BMPImage *out_img = copy_bmp(src_img);
    if(!out_img)
    {
        free(gray);
        return NULL;
    }

    for(LWORD y = 0; y < height; y++)
    {
        for(LWORD x = 0; x < width; x++)
        {
            BYTE result = BLACK_PIXEL_DATA;
            for(LWORD ky = 0; ky < 3; ky++)
            {
                for(LWORD kx = 0; kx < 3; kx++)
                {
                    LWORD ny = (LWORD)((long)y + (long)ky - 1);
                    LWORD nx = (LWORD)((long)x + (long)kx - 1);
                    if(ny < height && nx < width)
                    {
                        if(gray[ny * width + nx] > threshold)
                        {
                            result = WHITE_PIXEL_DATA;
                            ky = 3;
                            break;
                        }
                    }
                }
            }

            LWORD out_idx = y * row_size + x * 3;
            out_img->p08Data[out_idx] = result;
            out_img->p08Data[out_idx + 1] = result;
            out_img->p08Data[out_idx + 2] = result;
        }
    }

    free(gray);
    return out_img;
}
