#include <stdio.h>
#include <stdlib.h>
#include "bmp_type.h"

BMPImage *read_bmp(FILE *fp, LWORD *error_record)
{
    BMPImage *img = malloc(sizeof(BMPImage));

    if(!error_checker(img != NULL, error_record, ERROR_NOT_ENOUGH_MEMORY, __LINE__))
        return NULL;

    // Read BMP header
    rewind(fp);
    int num_fread = fread(&img->header, BMP_HEADER_SIZE, 1, fp);
    if(!error_checker(num_fread == 1, error_record, ERROR_CANNOT_READ_BMP_HEADER, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPFileHeader.u16FileType == BMP_MAGIC_NUMBER, error_record, ERROR_INVALID_BMP_SIGNATURE, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPFileHeader.u32PixelDataOffset == BMP_HEADER_SIZE, error_record, ERROR_WRONG_BMP_HEADER_SIZE, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32HeaderSize == BMP_INFOHEADER_SIZE, error_record, ERROR_WRONG_BMP_INFO_HEADER_SIZE, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u16Planes == BMP_NUM_PLANE, error_record, ERROR_WRONG_BMP_NUM_PLANE, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32Compression == BMP_COMPRESSION, error_record, ERROR_WRONG_BMP_COMPRESSION, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32TotalColors == BMP_TOTAL_COLORS, error_record, ERROR_WRONG_BMP_TOTAL_COLORS, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32ImportantColors == BMP_IMPORTANT_COLORS, error_record, ERROR_WRONG_BMP_IMPORTANT_COLORS, __LINE__))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u16BitsPerPixel == BMP_BITS_PER_PIXEL, error_record, ERROR_WRONG_BMP_BITS_PER_PIXEL, __LINE__))
        return NULL;

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

    printf("=== Image Info ===\n");
    printf("size (Byte): %d\n", img->header.stBMPFileHeader.u32FileSize);
    printf("height     : %d\n", img->header.stBMPInfoHeader.u32ImageHeight);
    printf("width      : %d\n", img->header.stBMPInfoHeader.u32ImageWidth);
    printf("==================\n\n");

    return img;
}

int error_checker(int condition, LWORD *error_record, LWORD error, int line)
{
    int is_valid = 1;
    if(!condition)
    {
        is_valid = 0;
        *error_record |= error_table[error].error_type;
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
    return (BMP_BYTE_PER_LWORD - (bmp_header->stBMPInfoHeader.u32ImageWidth * get_bytes_per_pixel(bmp_header)) % BMP_BYTE_PER_LWORD) % BMP_BYTE_PER_LWORD;
}

LWORD get_bytes_per_pixel(BMPHeader *bmp_header)
{
    return bmp_header->stBMPInfoHeader.u16BitsPerPixel / BMP_BITS_PER_BYTE;
}

int write_bmp(FILE *fp, BMPImage *img, LWORD *error_record)
{
    // Write BMP header
    rewind(fp);
    int num_fwrite = fwrite(&img->header, BMP_HEADER_SIZE, 1, fp);
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

void free_bmp_image(BMPImage *img)
{
    if(img)
    {
        free(img->p08Data);
        free(img);
    }
}