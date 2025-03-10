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

    printf("%d\n", bmp_file_header.u32PixelDataOffset);
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

BMPImage *RGB2Gray(BMPImage *src_img)
{
    LWORD u32i = 0;
    BMPImage *gray_img = (BMPImage*)malloc(sizeof(BMPImage));
    LWORD pixel_data_size = get_image_size_by_bytes(&src_img->header);
    gray_img->header = src_img->header;
    gray_img->p08Data = (BYTE*)malloc(pixel_data_size);

    BYTE blue, green, red, gray;
    for(u32i = 0; u32i < pixel_data_size; u32i = u32i + 3)
    {
        blue  = src_img->p08Data[u32i];
        green = src_img->p08Data[u32i + 1];
        red   = src_img->p08Data[u32i + 2];
        gray  = (blue * 30 + green * 150 + red * 76) >> 8;

        gray_img->p08Data[u32i]     = gray;
        gray_img->p08Data[u32i + 1] = gray;
        gray_img->p08Data[u32i + 2] = gray;
    }

    return gray_img;
}

BMPImage *binarize_bmp(BMPImage *src_img, BYTE threshold)
{
    LWORD u32i = 0;
    BMPImage *binary_img = (BMPImage*)malloc(sizeof(BMPImage));
    LWORD pixel_data_size = get_image_size_by_bytes(&src_img->header);
    binary_img->header = src_img->header;
    binary_img->p08Data = (BYTE*)malloc(pixel_data_size);

    for(u32i = 0; u32i < pixel_data_size; u32i = u32i + 1)
    {
        if(src_img->p08Data[u32i] > threshold)
            binary_img->p08Data[u32i] = WHITE_PIXEL_DATA;
        else
            binary_img->p08Data[u32i] = BLACK_PIXEL_DATA;
    }

    return binary_img;
}