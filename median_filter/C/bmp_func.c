#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

BMPColorTable **create_pixel_matrix(LWORD height, LWORD width)
{
    LWORD u32i = 0;
    if(height == 0 || width == 0)
        return NULL;

    BMPColorTable **pixel = (BMPColorTable **)malloc(height * sizeof(BMPColorTable*));
    if(!pixel)
        return NULL;
    for(u32i = 0; u32i < height; u32i++)
    {
        pixel[u32i] = (BMPColorTable *)malloc(width * sizeof(BMPColorTable));
        if(!pixel[u32i])
        {
            free_pixel_matrix(pixel, u32i);
            return NULL;
        }
    }

    return pixel;
}

BMPColorTable **copy_pixel_matrix(BMPColorTable **mat, LWORD height, LWORD width)
{
    if(!mat)
        return NULL;

    BMPColorTable **copy_mat = create_pixel_matrix(height, width);
    if(!copy_mat)
        return NULL;
    LWORD u32i, u32j;
    for(u32i = 0; u32i < height; u32i++)
    {
        for(u32j = 0; u32j < width; u32j++)
        {
            copy_mat[u32i][u32j].u08Blue  = mat[u32i][u32j].u08Blue;
            copy_mat[u32i][u32j].u08Green = mat[u32i][u32j].u08Green;
            copy_mat[u32i][u32j].u08Red   = mat[u32i][u32j].u08Red;
        }
    }

    return copy_mat;
}

void free_pixel_matrix(BMPColorTable **mat, LWORD height)
{
    LWORD u32i = 0;
    if(mat)
    {
        for(u32i = 0; u32i < height; u32i++)
            free(mat[u32i]);
        
        free(mat);
    }
}

BMPImage *MedianFilter(BMPImage *src_img, LWORD mask_size)
{
    LWORD u32i = 0;
    LWORD u32j = 0;
    if(!src_img || mask_size == 0 || (mask_size % 2) == 0)
        return NULL;

    BMPImage *filtered_img = copy_bmp(src_img);
    if(!filtered_img)
        return NULL;

    LWORD img_width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD img_height = src_img->header.stBMPInfoHeader.u32ImageHeight;

    BMPColorTable **pixel = create_pixel_matrix(img_height, img_width);
    if(!pixel)
    {
        free_bmp_image(filtered_img);
        return NULL;
    }
    LWORD count = 0;
    for(u32i = 0; u32i < img_height; u32i++)
    {
        for(u32j = 0; u32j < img_width; u32j++)
        {
            pixel[u32i][u32j].u08Blue = src_img->p08Data[count];
            count++;
            pixel[u32i][u32j].u08Green = src_img->p08Data[count];
            count++;
            pixel[u32i][u32j].u08Red = src_img->p08Data[count];
            count++;
            pixel[u32i][u32j].u08Reserved = 0;
        }
    }

    BMPColorTable **copy_pixel = copy_pixel_matrix(pixel, img_height, img_width);
    if(!copy_pixel)
    {
        free_pixel_matrix(pixel, img_height);
        free_bmp_image(filtered_img);
        return NULL;
    }
    LWORD u32x, u32y, u32num;
    BMPColorTable median_pixel;
    LWORD offset = mask_size / 2;
    LWORD mask_area = mask_size * mask_size;
    BMPColorTable *mask = (BMPColorTable*)malloc(mask_area * sizeof(BMPColorTable));
    if(!mask)
    {
        free_pixel_matrix(pixel, img_height);
        free_pixel_matrix(copy_pixel, img_height);
        free_bmp_image(filtered_img);
        return NULL;
    }
    for(u32i = offset; u32i < img_height - offset; u32i++)
    {
        for(u32j = offset; u32j < img_width - offset; u32j++)
        {
            u32num = 0;
            for(u32x = 0; u32x < 2 * offset + 1; u32x++)
            {
                for(u32y = 0; u32y < 2 * offset + 1; u32y++)
                {
                    mask[u32num].u08Blue  = pixel[u32i + u32x - offset][u32j + u32y - offset].u08Blue;
                    mask[u32num].u08Green = pixel[u32i + u32x - offset][u32j + u32y - offset].u08Green;
                    mask[u32num].u08Red   = pixel[u32i + u32x - offset][u32j + u32y - offset].u08Red;
                    u32num += 1;
                }
            }

            median_pixel = cal_median(mask, mask_area);

            copy_pixel[u32i][u32j].u08Blue  = median_pixel.u08Blue;
            copy_pixel[u32i][u32j].u08Green = median_pixel.u08Green;
            copy_pixel[u32i][u32j].u08Red   = median_pixel.u08Red;
        }
    }

    count = 0;
    for(u32i = 0; u32i < img_height; u32i++)
    {
        for(u32j = 0; u32j < img_width; u32j++)
        {
            filtered_img->p08Data[count] = copy_pixel[u32i][u32j].u08Blue;
            count++;
            filtered_img->p08Data[count] = copy_pixel[u32i][u32j].u08Green;
            count++;
            filtered_img->p08Data[count] = copy_pixel[u32i][u32j].u08Red;
            count++;
        }
    }

    free_pixel_matrix(pixel, img_height);
    free_pixel_matrix(copy_pixel, img_height);
    free(mask);
    return filtered_img;
}

/* Merge sort on BYTE keys (merge step uses work[] scratch). */
static void merge_sort_u8(BYTE *a, BYTE *work, LWORD n)
{
    LWORD mid, i, j, k;
    if(n <= 1)
        return;
    mid = n / 2;
    merge_sort_u8(a, work, mid);
    merge_sort_u8(a + mid, work, n - mid);
    i = 0;
    j = mid;
    k = 0;
    while(i < mid && j < n)
    {
        if(a[i] <= a[j])
            work[k++] = a[i++];
        else
            work[k++] = a[j++];
    }
    while(i < mid)
        work[k++] = a[i++];
    while(j < n)
        work[k++] = a[j++];
    for(i = 0; i < n; i++)
        a[i] = work[i];
}

/* Per-channel median: sort B, G, R separately (3×3 → 9 samples), then take middle index. */
BMPColorTable cal_median(BMPColorTable *arr, LWORD arr_size)
{
    BYTE b[9], g[9], r[9];
    BYTE work[9];
    BMPColorTable out;
    LWORD k;
    if(!arr || arr_size == 0 || arr_size > 9)
    {
        out.u08Blue = 0;
        out.u08Green = 0;
        out.u08Red = 0;
        out.u08Reserved = 0;
        return out;
    }
    for(k = 0; k < arr_size; k++)
    {
        b[k] = arr[k].u08Blue;
        g[k] = arr[k].u08Green;
        r[k] = arr[k].u08Red;
    }
    merge_sort_u8(b, work, arr_size);
    merge_sort_u8(g, work, arr_size);
    merge_sort_u8(r, work, arr_size);
    k = arr_size / 2;
    out.u08Blue = b[k];
    out.u08Green = g[k];
    out.u08Red = r[k];
    out.u08Reserved = 0;
    return out;
}