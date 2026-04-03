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

BMPImage *MeanFilter(BMPImage *src_img, LWORD mask_size)
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
    BMPColorTable mean_pixel;
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

            mean_pixel = cal_mean(mask, mask_area);

            copy_pixel[u32i][u32j].u08Blue  = mean_pixel.u08Blue;
            copy_pixel[u32i][u32j].u08Green = mean_pixel.u08Green;
            copy_pixel[u32i][u32j].u08Red   = mean_pixel.u08Red;
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

BMPColorTable cal_mean(BMPColorTable *arr, LWORD arr_size)
{
    LWORD u32i;
    LWORD u32_blue_sum = 0;
    LWORD u32_green_sum = 0;
    LWORD u32_red_sum = 0;
    BMPColorTable mean_pixel;
    for(u32i = 0; u32i < arr_size; u32i++)
    {
        u32_blue_sum  += arr[u32i].u08Blue;
        u32_green_sum += arr[u32i].u08Green;
        u32_red_sum   += arr[u32i].u08Red;
    }

    mean_pixel.u08Blue  = u32_blue_sum / arr_size;
    mean_pixel.u08Green = u32_green_sum / arr_size;
    mean_pixel.u08Red   = u32_red_sum / arr_size;

    return mean_pixel;
}