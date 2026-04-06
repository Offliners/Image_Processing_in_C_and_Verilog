#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

/* De-interleave BGR -> three planes, then merge back (identity). Matches RTL planar flow. */
BMPImage *bmp_planar_roundtrip(BMPImage *src)
{
    LWORD w, h, i, px, sz;
    BYTE *bpl, *gpl, *rpl;
    BMPImage *dst;

    if(!src || !src->p08Data)
        return NULL;

    w = src->header.stBMPInfoHeader.u32ImageWidth;
    h = src->header.stBMPInfoHeader.u32ImageHeight;
    sz = w * h;
    if(sz == 0)
        return NULL;

    bpl = (BYTE *)malloc(sz);
    gpl = (BYTE *)malloc(sz);
    rpl = (BYTE *)malloc(sz);
    if(!bpl || !gpl || !rpl)
        goto fail_planes;

    for(px = 0; px < sz; px++)
    {
        i = px * 3;
        bpl[px] = src->p08Data[i];
        gpl[px] = src->p08Data[i + 1];
        rpl[px] = src->p08Data[i + 2];
    }

    dst = (BMPImage *)calloc(1, sizeof(BMPImage));
    if(!dst)
        goto fail_planes;
    dst->header = src->header;
    dst->p08Data = (BYTE *)malloc(sz * 3);
    if(!dst->p08Data)
    {
        free(dst);
        goto fail_planes;
    }

    for(px = 0; px < sz; px++)
    {
        i = px * 3;
        dst->p08Data[i]     = bpl[px];
        dst->p08Data[i + 1] = gpl[px];
        dst->p08Data[i + 2] = rpl[px];
    }

    free(bpl);
    free(gpl);
    free(rpl);
    return dst;

fail_planes:
    free(bpl);
    free(gpl);
    free(rpl);
    return NULL;
}
