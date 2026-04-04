#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

/* Input: 24-bit BMP with grayscale pixels (B ≈ G ≈ R), e.g. lena256.bmp */
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
            gray[y * width + x] = src_img->p08Data[idx];
        }
    }

    return gray;
}

BMPImage *equalize_histogram(BMPImage *src_img)
{
    if(!src_img)
        return NULL;

    LWORD width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD height = src_img->header.stBMPInfoHeader.u32ImageHeight;
    LWORD row_size = get_image_row_size_bytes(&src_img->header);
    LWORD total = width * height;
    LWORD i;
    LWORD y;
    LWORD x;

    BYTE *gray = create_gray_buffer(src_img);
    if(!gray)
        return NULL;

    LWORD hist[256] = {0};
    for(i = 0; i < total; i++)
        hist[gray[i]]++;

    LWORD cdf[256] = {0};
    LWORD cumulative = 0;
    for(i = 0; i < 256; i++)
    {
        cumulative += hist[i];
        cdf[i] = cumulative;
    }

    LWORD cdf_min = 0;
    for(i = 0; i < 256; i++)
    {
        if(cdf[i] != 0)
        {
            cdf_min = cdf[i];
            break;
        }
    }

    BMPImage *out_img = copy_bmp(src_img);
    if(!out_img)
    {
        free(gray);
        return NULL;
    }

    for(y = 0; y < height; y++)
    {
        for(x = 0; x < width; x++)
        {
            LWORD idx = y * row_size + x * 3;
            BYTE g = gray[y * width + x];
            BYTE eq = g;
            if(total != cdf_min)
            {
                LWORD mapped = (cdf[g] - cdf_min) * 255;
                mapped = mapped / (total - cdf_min);
                if(mapped > 255)
                    mapped = 255;
                eq = (BYTE)mapped;
            }
            out_img->p08Data[idx] = eq;
            out_img->p08Data[idx + 1] = eq;
            out_img->p08Data[idx + 2] = eq;
        }
    }

    free(gray);
    return out_img;
}
