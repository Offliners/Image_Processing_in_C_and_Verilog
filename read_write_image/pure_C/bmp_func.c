#include <stdio.h>
#include <stdlib.h>
#include "bmp_type.h"

BMPImage *read_bmp(FILE *fp, LWORD *error_record)
{
    BMPImage *img = malloc(sizeof(BMPImage));

    if(!error_checker(img != NULL, error_record, ERROR_NOT_ENOUGH_MEMORY))
        return NULL;

    rewind(fp);
    int num_fread = fread(&img->header, BMP_HEADER_SIZE, 1, fp);
    if(!error_checker(num_fread == 1, error_record, ERROR_CANNOT_READ_BMP_HEADER))
        return NULL;

    if(!error_checker(img->header.stBMPFileHeader.u16FileType == BMP_MAGIC_NUMBER, error_record, ERROR_INVALID_BMP_SIGNATURE))
        return NULL;

    if(!error_checker(img->header.stBMPFileHeader.u32PixelDataOffset == BMP_HEADER_SIZE, error_record, ERROR_WRONG_BMP_HEADER_SIZE))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32HeaderSize == BMP_INFOHEADER_SIZE, error_record, ERROR_WRONG_BMP_INFO_HEADER_SIZE))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u16Planes == BMP_NUM_PLANE, error_record, ERROR_WRONG_BMP_NUM_PLANE))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32Compression == BMP_COMPRESSION, error_record, ERROR_WRONG_BMP_COMPRESSION))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32TotalColors == BMP_TOTAL_COLORS, error_record, ERROR_WRONG_BMP_TOTAL_COLORS))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u32ImportantColors == BMP_IMPORTANT_COLORS, error_record, ERROR_WRONG_BMP_IMPORTANT_COLORS))
        return NULL;

    if(!error_checker(img->header.stBMPInfoHeader.u16BitsPerPixel == BMP_BITS_PER_PIXEL, error_record, ERROR_WRONG_BMP_BITS_PER_PIXEL))
        return NULL;

    if(!error_checker(img->header.stBMPFileHeader.u32FileSize == get_image_file_size(fp), error_record, ERROR_WRONG_BMP_FILE_SIZE))
        return NULL;

    if(!error_checker(img->header.stBMPFileHeader.u32FileSize == BMP_HEADER_SIZE + get_image_size_by_bytes(&img->header), error_record, ERROR_WRONG_BMP_IMAGE_SIZE))
        return NULL;

    return NULL;
}

int error_checker(int condition, LWORD *error_record, LWORD error)
{
    int is_valid = 1;
    if(!condition)
    {
        is_valid = 0;
        *error_record |= error_table[error].error_type;
        printf(RED_COLOR "%s\n" ENDL_COLOR, error_table[error].error_message);
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