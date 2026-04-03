#include <stdlib.h>
#include <string.h>
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

BMPImage *connected_components(BMPImage *src_img, BYTE threshold)
{
    if(!src_img)
        return NULL;

    LWORD width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD height = src_img->header.stBMPInfoHeader.u32ImageHeight;
    LWORD row_size = get_image_row_size_bytes(&src_img->header);
    LWORD total = width * height;

    BYTE *gray = create_gray_buffer(src_img);
    if(!gray)
        return NULL;

    BYTE *binary = (BYTE*)malloc(total);
    if(!binary)
    {
        free(gray);
        return NULL;
    }
    for(LWORD i = 0; i < total; i++)
        binary[i] = (gray[i] > threshold) ? 1 : 0;

    int *labels = (int*)calloc(total, sizeof(int));
    LWORD *queue_x = (LWORD*)malloc(total * sizeof(LWORD));
    LWORD *queue_y = (LWORD*)malloc(total * sizeof(LWORD));
    if(!labels || !queue_x || !queue_y)
    {
        free(gray);
        free(binary);
        free(labels);
        free(queue_x);
        free(queue_y);
        return NULL;
    }

    int label = 0;
    for(LWORD y = 0; y < height; y++)
    {
        for(LWORD x = 0; x < width; x++)
        {
            LWORD idx = y * width + x;
            if(binary[idx] && labels[idx] == 0)
            {
                label++;
                LWORD head = 0;
                LWORD tail = 0;
                queue_x[tail] = x;
                queue_y[tail] = y;
                tail++;
                labels[idx] = label;

                while(head < tail)
                {
                    LWORD cx = queue_x[head];
                    LWORD cy = queue_y[head];
                    head++;

                    if(cx > 0)
                    {
                        LWORD nidx = cy * width + (cx - 1);
                        if(binary[nidx] && labels[nidx] == 0)
                        {
                            labels[nidx] = label;
                            queue_x[tail] = cx - 1;
                            queue_y[tail] = cy;
                            tail++;
                        }
                    }
                    if(cx + 1 < width)
                    {
                        LWORD nidx = cy * width + (cx + 1);
                        if(binary[nidx] && labels[nidx] == 0)
                        {
                            labels[nidx] = label;
                            queue_x[tail] = cx + 1;
                            queue_y[tail] = cy;
                            tail++;
                        }
                    }
                    if(cy > 0)
                    {
                        LWORD nidx = (cy - 1) * width + cx;
                        if(binary[nidx] && labels[nidx] == 0)
                        {
                            labels[nidx] = label;
                            queue_x[tail] = cx;
                            queue_y[tail] = cy - 1;
                            tail++;
                        }
                    }
                    if(cy + 1 < height)
                    {
                        LWORD nidx = (cy + 1) * width + cx;
                        if(binary[nidx] && labels[nidx] == 0)
                        {
                            labels[nidx] = label;
                            queue_x[tail] = cx;
                            queue_y[tail] = cy + 1;
                            tail++;
                        }
                    }
                }
            }
        }
    }

    BMPImage *out_img = copy_bmp(src_img);
    if(!out_img)
    {
        free(gray);
        free(binary);
        free(labels);
        free(queue_x);
        free(queue_y);
        return NULL;
    }
    memset(out_img->p08Data, 0, get_image_size_by_bytes(&out_img->header));

    for(LWORD y = 0; y < height; y++)
    {
        for(LWORD x = 0; x < width; x++)
        {
            LWORD idx = y * width + x;
            BYTE value = 0;
            if(labels[idx] > 0)
            {
                value = (BYTE)((labels[idx] * 37) & 0xFF);
                if(value == 0)
                    value = 1;
            }

            LWORD out_idx = y * row_size + x * 3;
            out_img->p08Data[out_idx] = value;
            out_img->p08Data[out_idx + 1] = value;
            out_img->p08Data[out_idx + 2] = value;
        }
    }

    free(gray);
    free(binary);
    free(labels);
    free(queue_x);
    free(queue_y);

    return out_img;
}
