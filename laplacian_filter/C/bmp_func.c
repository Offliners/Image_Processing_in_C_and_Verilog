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

    LWORD y;
    LWORD x;
    for(y = 0; y < height; y++)
    {
        for(x = 0; x < width; x++)
        {
            LWORD idx = y * row_size + x * 3;
            gray[y * width + x] = calc_gray(src_img->p08Data[idx],
                                            src_img->p08Data[idx + 1],
                                            src_img->p08Data[idx + 2]);
        }
    }

    return gray;
}

BMPImage *laplacian_filter(BMPImage *src_img)
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

    LWORD y;
    LWORD x;
    for(y = 0; y < height; y++)
    {
        for(x = 0; x < width; x++)
        {
            BYTE out_val = 0;
            if(y > 0 && y + 1 < height && x > 0 && x + 1 < width)
            {
                int sum = 0;
                sum += -gray[(y - 1) * width + x];
                sum += -gray[y * width + (x - 1)];
                sum += 4 * gray[y * width + x];
                sum += -gray[y * width + (x + 1)];
                sum += -gray[(y + 1) * width + x];
                if(sum < 0)
                    sum = -sum;
                if(sum > 255)
                    sum = 255;
                out_val = (BYTE)sum;
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
