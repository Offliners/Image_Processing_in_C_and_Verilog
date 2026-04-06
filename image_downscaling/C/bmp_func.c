#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

static BYTE avg4(BYTE a, BYTE b, BYTE c, BYTE d)
{
    LWORD s = (LWORD)a + (LWORD)b + (LWORD)c + (LWORD)d;
    return (BYTE)((s + 2) >> 2);
}

/* 256x256 -> 128x128: each output pixel = average of a 2x2 BGR block (box filter). */
BMPImage *bmp_downscale_half_box(BMPImage *src)
{
    LWORD in_w, in_h, out_w, out_h;
    LWORD oy, ox;
    LWORD di00, di01, di10, di11;
    LWORD out_idx;
    BMPImage *dst;

    if(!src || !src->p08Data)
        return NULL;

    in_w = src->header.stBMPInfoHeader.u32ImageWidth;
    in_h = src->header.stBMPInfoHeader.u32ImageHeight;
    if((in_w & 1) || (in_h & 1) || in_w < 2 || in_h < 2)
        return NULL;

    out_w = in_w / 2;
    out_h = in_h / 2;

    dst = (BMPImage *)calloc(1, sizeof(BMPImage));
    if(!dst)
        return NULL;

    dst->header = src->header;
    dst->header.stBMPInfoHeader.u32ImageWidth = out_w;
    dst->header.stBMPInfoHeader.u32ImageHeight = out_h;
    dst->header.stBMPInfoHeader.u32ImageSize = out_w * out_h * 3;
    dst->header.stBMPFileHeader.u32FileSize = BMP_HEADER_SIZE + dst->header.stBMPInfoHeader.u32ImageSize;

    dst->p08Data = (BYTE *)malloc(dst->header.stBMPInfoHeader.u32ImageSize);
    if(!dst->p08Data)
    {
        free(dst);
        return NULL;
    }

    for(oy = 0; oy < out_h; oy++)
    {
        for(ox = 0; ox < out_w; ox++)
        {
            di00 = ((oy * 2) * in_w + (ox * 2)) * 3;
            di01 = ((oy * 2) * in_w + (ox * 2 + 1)) * 3;
            di10 = (((oy * 2 + 1) * in_w) + (ox * 2)) * 3;
            di11 = (((oy * 2 + 1) * in_w) + (ox * 2 + 1)) * 3;
            out_idx = (oy * out_w + ox) * 3;

            dst->p08Data[out_idx + 0] = avg4(
                src->p08Data[di00 + 0], src->p08Data[di01 + 0],
                src->p08Data[di10 + 0], src->p08Data[di11 + 0]);
            dst->p08Data[out_idx + 1] = avg4(
                src->p08Data[di00 + 1], src->p08Data[di01 + 1],
                src->p08Data[di10 + 1], src->p08Data[di11 + 1]);
            dst->p08Data[out_idx + 2] = avg4(
                src->p08Data[di00 + 2], src->p08Data[di01 + 2],
                src->p08Data[di10 + 2], src->p08Data[di11 + 2]);
        }
    }

    return dst;
}
