#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common.h"
#include "bmp_type.h"

static BYTE validate_file_pointer(FILE *fp, LWORD *error_record)
{
    if(!fp)
        return error_checker(0, error_record, ERROR_CANNOT_READ_BMP_HEADER, __LINE__);

    return 1;
}

BMPImage *read_bmp(FILE *fp, LWORD *error_record)
{
    BMPImage *img = NULL;
    LWORD image_size_by_bytes = 0;

    if(!error_record)
        return NULL;
    *error_record = 0;

    if(!validate_file_pointer(fp, error_record))
        return NULL;

    img = (BMPImage*)calloc(1, sizeof(BMPImage));
    if(!error_checker(img != NULL, error_record, ERROR_NOT_ENOUGH_MEMORY, __LINE__))
        return NULL;

    // Read BMP header
    rewind(fp);
    if(!error_checker(fread(&img->header, BMP_HEADER_SIZE, 1, fp) == 1, error_record, ERROR_CANNOT_READ_BMP_HEADER, __LINE__))
        goto fail;

    if(!bmp_header_check(img, error_record))
        goto fail;

    LWORD file_size = get_image_file_size(fp);
    if(!error_checker(file_size != FUNC_FAIL, error_record, ERROR_WRONG_BMP_FILE_SIZE, __LINE__))
        goto fail;

    if(!error_checker(img->header.stBMPFileHeader.u32FileSize == file_size, error_record, ERROR_WRONG_BMP_FILE_SIZE, __LINE__))
        goto fail;

    image_size_by_bytes = get_image_size_by_bytes(&img->header);
    if(!error_checker(image_size_by_bytes > 0, error_record, ERROR_WRONG_BMP_IMAGE_SIZE, __LINE__))
        goto fail;

    if(!error_checker(img->header.stBMPFileHeader.u32FileSize == BMP_HEADER_SIZE + image_size_by_bytes, error_record, ERROR_WRONG_BMP_IMAGE_SIZE, __LINE__))
        goto fail;

    // Read BMP pixel data
    if(!error_checker(fseek(fp, BMP_HEADER_SIZE, SEEK_SET) == 0, error_record, ERROR_CANNOT_READ_PIXEL_DATA, __LINE__))
        goto fail;

    img->p08Data = (BYTE*)malloc(image_size_by_bytes);
    if(!error_checker(img->p08Data != NULL, error_record, ERROR_NOT_ENOUGH_MEMORY, __LINE__))
        goto fail;

    if(!error_checker(fread(img->p08Data, image_size_by_bytes, 1, fp) == 1, error_record, ERROR_CANNOT_READ_PIXEL_DATA, __LINE__))
        goto fail;

    return img;

fail:
    free_bmp_image(img);
    return NULL;
}

BYTE bmp_header_check(const BMPImage *img, LWORD *error_record)
{
    if(!error_checker(img != NULL, error_record, ERROR_CANNOT_READ_BMP_HEADER, __LINE__))
        return 0;

    BMPFileHeader bmp_file_header = img->header.stBMPFileHeader;
    if(!error_checker(bmp_file_header.u16FileType == BMP_MAGIC_NUMBER, error_record, ERROR_INVALID_BMP_SIGNATURE, __LINE__))
        return 0;

    if(!error_checker(bmp_file_header.u32PixelDataOffset == BMP_HEADER_SIZE, error_record, ERROR_WRONG_BMP_HEADER_SIZE, __LINE__))
        return 0;

    BMPInfoHeader bmp_info_header = img->header.stBMPInfoHeader;
    if(!error_checker(bmp_info_header.u32HeaderSize == BMP_INFOHEADER_SIZE, error_record, ERROR_WRONG_BMP_INFO_HEADER_SIZE, __LINE__))
        return 0;

    if(!error_checker(bmp_info_header.u16Planes == BMP_NUM_PLANE, error_record, ERROR_WRONG_BMP_NUM_PLANE, __LINE__))
        return 0;

    if(!error_checker(bmp_info_header.u32Compression == BMP_COMPRESSION, error_record, ERROR_WRONG_BMP_COMPRESSION, __LINE__))
        return 0;

    if(!error_checker(bmp_info_header.u32TotalColors == BMP_TOTAL_COLORS, error_record, ERROR_WRONG_BMP_TOTAL_COLORS, __LINE__))
        return 0;

    if(!error_checker(bmp_info_header.u32ImportantColors == BMP_IMPORTANT_COLORS, error_record, ERROR_WRONG_BMP_IMPORTANT_COLORS, __LINE__))
        return 0;

    if(!error_checker(bmp_info_header.u16BitsPerPixel == BMP_BITS_PER_PIXEL, error_record, ERROR_WRONG_BMP_BITS_PER_PIXEL, __LINE__))
        return 0;

    if(!error_checker(bmp_info_header.u32ImageWidth > 0 && bmp_info_header.u32ImageHeight > 0, error_record, ERROR_WRONG_BMP_IMAGE_SIZE, __LINE__))
        return 0;

    return 1;
}

BYTE error_checker(BYTE condition, LWORD *error_record, LWORD error, LWORD line)
{
    BYTE is_valid = 1;
    if(!condition)
    {
        is_valid = 0;
        if(error_record)
            *error_record = error_table[error].error_type;
        printf(RED_COLOR "FAIL at %d: %s\n" ENDL_COLOR, line, error_table[error].error_message);
    }

    return is_valid;
}

LWORD get_image_file_size(FILE *fp)
{
    long cur_pos = ftell(fp);
    if(cur_pos < 0)
        return FUNC_FAIL;

    if(fseek(fp, 0, SEEK_END) != 0)
        return FUNC_FAIL;

    long file_size = ftell(fp);
    if(file_size < 0)
        return FUNC_FAIL;

    if(fseek(fp, cur_pos, SEEK_SET) != 0)
        return FUNC_FAIL;

    return (LWORD)file_size;
}

LWORD get_image_size_by_bytes(const BMPHeader *bmp_header)
{
    return get_image_row_size_bytes(bmp_header) * bmp_header->stBMPInfoHeader.u32ImageHeight;
}

LWORD get_image_row_size_bytes(const BMPHeader *bmp_header)
{
    LWORD bytes_per_row_without_padding = bmp_header->stBMPInfoHeader.u32ImageWidth * get_bytes_per_pixel(bmp_header);
    return bytes_per_row_without_padding + padding_byte(bmp_header);
}

LWORD padding_byte(const BMPHeader *bmp_header)
{
    return (LWORD_SIZE - (bmp_header->stBMPInfoHeader.u32ImageWidth * get_bytes_per_pixel(bmp_header)) % LWORD_SIZE) % LWORD_SIZE;
}

LWORD get_bytes_per_pixel(const BMPHeader *bmp_header)
{
    return bmp_header->stBMPInfoHeader.u16BitsPerPixel / BMP_BITS_PER_BYTE;
}

BYTE write_bmp(FILE *fp, BMPImage *img, LWORD *error_record)
{
    if(!error_record)
        return FUNC_FAIL;
    *error_record = 0;

    if(!validate_file_pointer(fp, error_record))
        return FUNC_FAIL;

    if(!error_checker(img != NULL && img->p08Data != NULL, error_record, ERROR_CANNOT_WRITE_BMP_IMAGE, __LINE__))
        return FUNC_FAIL;

    // Write BMP header
    rewind(fp);
    if(!error_checker(fwrite(&img->header, BMP_HEADER_SIZE, 1, fp) == 1, error_record, ERROR_CANNOT_WRITE_BMP_HEADER, __LINE__))
        return FUNC_FAIL;

    // Write BMP pixel data
    if(!error_checker(fseek(fp, BMP_HEADER_SIZE, SEEK_SET) == 0, error_record, ERROR_CANNOT_WRITE_BMP_IMAGE, __LINE__))
        return FUNC_FAIL;

    LWORD image_size_by_bytes = get_image_size_by_bytes(&img->header);
    if(!error_checker(fwrite(img->p08Data, image_size_by_bytes, 1, fp) == 1, error_record, ERROR_CANNOT_WRITE_BMP_IMAGE, __LINE__))
        return FUNC_FAIL;

    return FUNC_SUC;
}

void show_bmp_info(const BMPImage *img)
{
    if(!img)
        return;

    // Show basic image information
    printf("==========================\n");
    printf("size (byte): %u\n", img->header.stBMPFileHeader.u32FileSize);
    printf("height     : %u\n", img->header.stBMPInfoHeader.u32ImageHeight);
    printf("width      : %u\n", img->header.stBMPInfoHeader.u32ImageWidth);
    printf("==========================\n\n");
}

BMPImage *copy_bmp(const BMPImage *img)
{
    LWORD error_record = 0;
    if(!error_checker(img != NULL, &error_record, ERROR_COPY_BMP_IMAGE_FAIL, __LINE__))
        return NULL;

    LWORD pixel_data_size = get_image_size_by_bytes(&img->header);
    BMPImage *img_copy = (BMPImage*)malloc(sizeof(BMPImage));
    if(!error_checker(img_copy != NULL, &error_record, ERROR_NOT_ENOUGH_MEMORY, __LINE__))
        return NULL;

    img_copy->p08Data = (BYTE*)malloc(pixel_data_size);
    if(!error_checker(img_copy->p08Data != NULL, &error_record, ERROR_NOT_ENOUGH_MEMORY, __LINE__))
    {
        free(img_copy);
        return NULL;
    }

    img_copy->header = img->header;
    memcpy(img_copy->p08Data, img->p08Data, pixel_data_size);

    if(!bmp_header_check(img_copy, &error_record))
    {
        free_bmp_image(img_copy);
        return NULL;
    }

    return img_copy;
}

void bmp_flip_top_bottom_inplace(BMPImage *img)
{
    LWORD y;
    LWORD h;
    LWORD row_bytes;
    BYTE *tmp;
    BYTE *row_a;
    BYTE *row_b;

    if(!img || !img->p08Data)
        return;

    h = img->header.stBMPInfoHeader.u32ImageHeight;
    if(h < 2)
        return;

    row_bytes = get_image_row_size_bytes(&img->header);
    tmp = (BYTE*)malloc(row_bytes);
    if(!tmp)
        return;

    for(y = 0; y < h / 2; y++)
    {
        row_a = img->p08Data + y * row_bytes;
        row_b = img->p08Data + (h - 1 - y) * row_bytes;
        memcpy(tmp, row_a, row_bytes);
        memcpy(row_a, row_b, row_bytes);
        memcpy(row_b, tmp, row_bytes);
    }

    free(tmp);
}

void bmp_flip_left_right_inplace(BMPImage *img)
{
    LWORD y, x;
    LWORD w, h;
    LWORD row_bytes;
    BYTE *row;
    BYTE *a;
    BYTE *b;
    BYTE tmp[3];

    if(!img || !img->p08Data)
        return;

    w = img->header.stBMPInfoHeader.u32ImageWidth;
    h = img->header.stBMPInfoHeader.u32ImageHeight;
    if(w < 2)
        return;

    row_bytes = get_image_row_size_bytes(&img->header);

    for(y = 0; y < h; y++)
    {
        row = img->p08Data + y * row_bytes;
        for(x = 0; x < w / 2; x++)
        {
            a = row + x * 3;
            b = row + (w - 1 - x) * 3;
            tmp[0] = a[0];
            tmp[1] = a[1];
            tmp[2] = a[2];
            a[0] = b[0];
            a[1] = b[1];
            a[2] = b[2];
            b[0] = tmp[0];
            b[1] = tmp[1];
            b[2] = tmp[2];
        }
    }
}

void free_bmp_image(BMPImage *img)
{
    if(img)
    {
        free(img->p08Data);
        free(img);
    }
}
