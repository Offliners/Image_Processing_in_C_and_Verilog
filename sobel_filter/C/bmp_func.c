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
            gray[y * width + x] = calc_gray(src_img->p08Data[idx],
                                            src_img->p08Data[idx + 1],
                                            src_img->p08Data[idx + 2]);
        }
    }

    return gray;
}

BMPImage *sobel_filter(BMPImage *src_img)
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
            BYTE out_val = 0;
            if(y > 0 && y + 1 < height && x > 0 && x + 1 < width)
            {
                int gx = 0;
                int gy = 0;
                gx += -gray[(y - 1) * width + (x - 1)];
                gx += gray[(y - 1) * width + (x + 1)];
                gx += -2 * gray[y * width + (x - 1)];
                gx += 2 * gray[y * width + (x + 1)];
                gx += -gray[(y + 1) * width + (x - 1)];
                gx += gray[(y + 1) * width + (x + 1)];

                gy += gray[(y - 1) * width + (x - 1)];
                gy += 2 * gray[(y - 1) * width + x];
                gy += gray[(y - 1) * width + (x + 1)];
                gy += -gray[(y + 1) * width + (x - 1)];
                gy += -2 * gray[(y + 1) * width + x];
                gy += -gray[(y + 1) * width + (x + 1)];

                int mag = abs(gx) + abs(gy);
                if(mag > 255)
                    mag = 255;
                out_val = (BYTE)mag;
            }

            LWORD out_idx = y * row_size + x * 3;
            out_img->p08Data[out_idx] = out_val;
            out_img->p08Data[out_idx + 1] = out_val;
            out_img->p08Data[out_idx + 2] = out_val;
        }
    }

    free(gray);
    return out_img;
}
