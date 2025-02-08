#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "bmp_type.h"

BMPImage *read_bmp(FILE *fp, LWORD *error_record)
{
    BMPImage *img = malloc(sizeof(BMPImage));

    if(!error_checker(img != NULL, error_record, ERROR_NOT_ENOUGH_MEMORY, __LINE__))
        return NULL;

    // Read BMP header
    rewind(fp);
    BYTE num_fread = fread(&img->header, BMP_HEADER_SIZE, 1, fp);
    if(!error_checker(num_fread == 1, error_record, ERROR_CANNOT_READ_BMP_HEADER, __LINE__))
        return NULL;

    bmp_header_check(img, error_record);

    if(!error_checker(img->header.stBMPFileHeader.u32FileSize == get_image_file_size(fp), error_record, ERROR_WRONG_BMP_FILE_SIZE, __LINE__))
        return NULL;

    LWORD image_size_by_bytes = get_image_size_by_bytes(&img->header);
    if(!error_checker(img->header.stBMPFileHeader.u32FileSize == BMP_HEADER_SIZE + image_size_by_bytes, error_record, ERROR_WRONG_BMP_IMAGE_SIZE, __LINE__))
        return NULL;

    // Read BMP pixel data
    fseek(fp, BMP_HEADER_SIZE, SEEK_SET);
    img->p08Data = (BYTE*)malloc(image_size_by_bytes);
    num_fread = fread(img->p08Data, image_size_by_bytes, 1, fp);
    if(!error_checker(num_fread == 1, error_record, ERROR_CANNOT_READ_PIXEL_DATA, __LINE__))
        return NULL;

    return img;
}

void *bmp_header_check(const BMPImage *img, LWORD *error_record)
{
    BMPFileHeader bmp_file_header = img->header.stBMPFileHeader;
    if(!error_checker(bmp_file_header.u16FileType == BMP_MAGIC_NUMBER, error_record, ERROR_INVALID_BMP_SIGNATURE, __LINE__))
        return NULL;

    if(!error_checker(bmp_file_header.u32PixelDataOffset == BMP_HEADER_SIZE, error_record, ERROR_WRONG_BMP_HEADER_SIZE, __LINE__))
        return NULL;

    BMPInfoHeader bmp_info_header = img->header.stBMPInfoHeader;
    if(!error_checker(bmp_info_header.u32HeaderSize == BMP_INFOHEADER_SIZE, error_record, ERROR_WRONG_BMP_INFO_HEADER_SIZE, __LINE__))
        return NULL;

    if(!error_checker(bmp_info_header.u16Planes == BMP_NUM_PLANE, error_record, ERROR_WRONG_BMP_NUM_PLANE, __LINE__))
        return NULL;

    if(!error_checker(bmp_info_header.u32Compression == BMP_COMPRESSION, error_record, ERROR_WRONG_BMP_COMPRESSION, __LINE__))
        return NULL;

    if(!error_checker(bmp_info_header.u32TotalColors == BMP_TOTAL_COLORS, error_record, ERROR_WRONG_BMP_TOTAL_COLORS, __LINE__))
        return NULL;

    if(!error_checker(bmp_info_header.u32ImportantColors == BMP_IMPORTANT_COLORS, error_record, ERROR_WRONG_BMP_IMPORTANT_COLORS, __LINE__))
        return NULL;

    if(!error_checker(bmp_info_header.u16BitsPerPixel == BMP_BITS_PER_PIXEL, error_record, ERROR_WRONG_BMP_BITS_PER_PIXEL, __LINE__))
        return NULL;
}

BYTE error_checker(BYTE condition, LWORD *error_record, LWORD error, LWORD line)
{
    BYTE is_valid = 1;
    if(!condition)
    {
        is_valid = 0;
        *error_record = error_table[error].error_type;
        printf(RED_COLOR "FAIL at %d: %s\n" ENDL_COLOR, line, error_table[error].error_message);
    }

    return is_valid;
}

LWORD get_image_file_size(FILE *fp)
{   
    LWORD u32CurPos = ftell(fp);
    if(u32CurPos == -1)
    {
        return FUNC_FAIL;
    }

    if(fseek(fp, 0, SEEK_END) != 0)
    {
        return FUNC_FAIL;
    }

    LWORD u32FileSize = ftell(fp);
    if(u32FileSize == -1)
    {
        return FUNC_FAIL;
    }

    if(fseek(fp, u32CurPos, SEEK_SET) != 0)
    {
        return FUNC_FAIL;
    }

    return u32FileSize;
}

LWORD get_image_size_by_bytes(BMPHeader *bmp_header)
{
    return get_image_row_size_bytes(bmp_header) * bmp_header->stBMPInfoHeader.u32ImageHeight;
}

LWORD get_image_row_size_bytes(BMPHeader *bmp_header)
{
    LWORD bytes_per_row_without_padding = bmp_header->stBMPInfoHeader.u32ImageWidth * get_bytes_per_pixel(bmp_header);
    return bytes_per_row_without_padding + padding_byte(bmp_header);
}

LWORD padding_byte(BMPHeader *bmp_header)
{
    return (LWORD_SIZE - (bmp_header->stBMPInfoHeader.u32ImageWidth * get_bytes_per_pixel(bmp_header)) % LWORD_SIZE) % LWORD_SIZE;
}

LWORD get_bytes_per_pixel(BMPHeader *bmp_header)
{
    return bmp_header->stBMPInfoHeader.u16BitsPerPixel / BMP_BITS_PER_BYTE;
}

BYTE write_bmp(FILE *fp, BMPImage *img, LWORD *error_record)
{
    // Write BMP header
    rewind(fp);
    BYTE num_fwrite = fwrite(&img->header, BMP_HEADER_SIZE, 1, fp);
    if(!error_checker(num_fwrite == 1, error_record, ERROR_CANNOT_WRITE_BMP_HEADER, __LINE__))
        return FUNC_FAIL;

    // Write BMP pixel data
    fseek(fp, BMP_HEADER_SIZE, SEEK_SET);
    LWORD image_size_by_bytes = get_image_size_by_bytes(&img->header);
    num_fwrite = fwrite(img->p08Data, image_size_by_bytes, 1, fp);
    if(!error_checker(num_fwrite == 1, error_record, ERROR_CANNOT_WRITE_BMP_IMAGE, __LINE__))
        return FUNC_FAIL;

    return FUNC_SUC;
}

void show_bmp_info(const BMPImage *img)
{
    // Show basic image information
    printf("==========================\n");
    printf("size (byte): %d\n", img->header.stBMPFileHeader.u32FileSize);
    printf("height     : %d\n", img->header.stBMPInfoHeader.u32ImageHeight);
    printf("width      : %d\n", img->header.stBMPInfoHeader.u32ImageWidth);
    printf("==========================\n\n");
}

BMPImage *copy_bmp(BMPImage *img)
{   
    LWORD error_record = 0;
    LWORD pixel_data_size = get_image_size_by_bytes(&img->header);
    BMPImage *img_copy = (BMPImage*)malloc(sizeof(BMPImage));
    img_copy->p08Data = (BYTE*)malloc(pixel_data_size);

    img_copy->header = img->header;
    for(LWORD u32i = 0; u32i < pixel_data_size; u32i++)
        img_copy->p08Data[u32i] = img->p08Data[u32i];

    bmp_header_check((BMPImage*)img_copy, &error_record);
    if(!error_checker(error_record == 0, &error_record, ERROR_COPY_BMP_IMAGE_FAIL, __LINE__))
        return NULL;

    return (BMPImage*)img_copy;
}

void free_bmp_image(BMPImage *img)
{
    if(img)
    {
        free(img->p08Data);
        free(img);
    }
}

BMPColorTable **create_pixel_matrix(LWORD height, LWORD width)
{
    LWORD u32i = 0;
    BMPColorTable **pixel = (BMPColorTable **)malloc(height * sizeof(BMPColorTable*));
    for(u32i = 0; u32i < height; u32i++)
        pixel[u32i] = (BMPColorTable *)malloc(width * sizeof(BMPColorTable));

    return pixel;
}

BMPColorTable **copy_pixel_matrix(BMPColorTable **mat, LWORD height, LWORD width)
{
    BMPColorTable **copy_mat = create_pixel_matrix(height, width);
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
    BMPImage *filtered_img = copy_bmp(src_img);

    LWORD img_width = src_img->header.stBMPInfoHeader.u32ImageWidth;
    LWORD img_height = src_img->header.stBMPInfoHeader.u32ImageHeight;

    BMPColorTable **pixel = create_pixel_matrix(img_height, img_width);
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
    LWORD u32x, u32y, u32num;
    BMPColorTable median_pixel;
    BYTE offset = mask_size / 2;
    LWORD mask_area = mask_size * mask_size;
    BMPColorTable *mask = (BMPColorTable*)malloc(mask_area * sizeof(BMPColorTable));
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
    return filtered_img;
}

BMPColorTable cal_median(BMPColorTable *arr, LWORD arr_size)
{
    BYTE u32i, u32j;
    LWORD u32a_sum = 0;
    LWORD u32b_sum = 0;
    BYTE isSorted = 1;

    // Bubble sort
    for(u32i = 0; u32i < arr_size; u32i++)
    {
        for(u32j = u32i + 1; u32j < arr_size; u32j++)
        {
            u32a_sum = arr[u32i].u08Blue + arr[u32i].u08Green + arr[u32i].u08Red;
            u32b_sum = arr[u32j].u08Blue + arr[u32j].u08Green + arr[u32j].u08Red;
            if(u32a_sum > u32b_sum)
            {
                isSorted = 0;
                swap_data(&arr[u32i], &arr[u32j]);
            }
        }

        if(isSorted)
            break;
    }

    return arr[arr_size / 2];
}

void swap_data(BMPColorTable *a, BMPColorTable *b)
{
    BMPColorTable u08temp = *a;
    *a = *b;
    *b = u08temp;
}