#include <stdio.h>
#include <stdlib.h>
#include "bmp_type.h"

BMPImage *read_bmp(const FILE *fp, LWORD *error_record)
{
    BMPImage *img = malloc(sizeof(BMPImage));

    if(!error_checker(img != NULL, error_record, ERROR_NOT_ENOUGH_MEMORY))
        return NULL;

    rewind(fp);
    int num_fread = fread(&img->header, BMP_HEADER_SIZE, 1, fp);
    if(!error_checker(num_fread == 1, error_record, ERROR_CANNOT_READ_BMP_HEADER))
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