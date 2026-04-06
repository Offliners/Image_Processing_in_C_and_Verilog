#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

static BYTE gray_from_bgr(BYTE b, BYTE g, BYTE r)
{
    return (BYTE)(((LWORD)b * 30 + (LWORD)g * 150 + (LWORD)r * 76) >> 8);
}

/* Match RTL: BGR -> gray plane -> 24bpp B=G=R=Y. */
BMPImage *bmp_planar_gray_pipeline(BMPImage *src)
{
    LWORD w, h, px, sz, i;
    BYTE *ypl;
    BMPImage *dst;

    if(!src || !src->p08Data)
        return NULL;

    w = src->header.stBMPInfoHeader.u32ImageWidth;
    h = src->header.stBMPInfoHeader.u32ImageHeight;
    sz = w * h;
    if(sz == 0)
        return NULL;

    ypl = (BYTE *)malloc(sz);
    if(!ypl)
        return NULL;

    for(px = 0; px < sz; px++)
    {
        i = px * 3;
        ypl[px] = gray_from_bgr(src->p08Data[i], src->p08Data[i + 1], src->p08Data[i + 2]);
    }

    dst = (BMPImage *)calloc(1, sizeof(BMPImage));
    if(!dst)
    {
        free(ypl);
        return NULL;
    }
    dst->header = src->header;
    dst->p08Data = (BYTE *)malloc(sz * 3);
    if(!dst->p08Data)
    {
        free(ypl);
        free(dst);
        return NULL;
    }

    for(px = 0; px < sz; px++)
    {
        BYTE y = ypl[px];
        i = px * 3;
        dst->p08Data[i]     = y;
        dst->p08Data[i + 1] = y;
        dst->p08Data[i + 2] = y;
    }

    free(ypl);
    return dst;
}
