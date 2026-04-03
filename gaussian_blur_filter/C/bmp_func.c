#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

BMPImage *gaussian_blur(BMPImage *src_img)
{
    if(!src_img)
        return NULL;

    LWORD width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD height = src_img->header.stBMPInfoHeader.u32ImageHeight;
    LWORD row_size = get_image_row_size_bytes(&src_img->header);

    BMPImage *out_img = copy_bmp(src_img);
    if(!out_img)
        return NULL;

    const int kernel[3][3] = {
        {1, 2, 1},
        {2, 4, 2},
        {1, 2, 1}
    };

    for(LWORD y = 0; y < height; y++)
    {
        for(LWORD x = 0; x < width; x++)
        {
            LWORD out_idx = y * row_size + x * 3;
            if(y == 0 || y + 1 >= height || x == 0 || x + 1 >= width)
            {
                out_img->p08Data[out_idx] = src_img->p08Data[out_idx];
                out_img->p08Data[out_idx + 1] = src_img->p08Data[out_idx + 1];
                out_img->p08Data[out_idx + 2] = src_img->p08Data[out_idx + 2];
                continue;
            }
            int sum_b = 0, sum_g = 0, sum_r = 0;
            for(int ky = -1; ky <= 1; ky++)
            {
                for(int kx = -1; kx <= 1; kx++)
                {
                    LWORD ni = (y + ky) * row_size + (x + kx) * 3;
                    int w = kernel[ky + 1][kx + 1];
                    sum_b += (int)src_img->p08Data[ni] * w;
                    sum_g += (int)src_img->p08Data[ni + 1] * w;
                    sum_r += (int)src_img->p08Data[ni + 2] * w;
                }
            }
            out_img->p08Data[out_idx] = (BYTE)(sum_b / 16);
            out_img->p08Data[out_idx + 1] = (BYTE)(sum_g / 16);
            out_img->p08Data[out_idx + 2] = (BYTE)(sum_r / 16);
        }
    }

    return out_img;
}
