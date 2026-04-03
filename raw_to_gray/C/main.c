#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

#define RAW_WIDTH  256
#define RAW_HEIGHT 256

BYTE check_img_exist(char *filename);
BMPImage *read_raw_image(const char *filename);
BYTE write_image(const char *filename, BMPImage *img);

int main(int argc, char *argv[])
{
    if(argc != 2)
    {
        printf(RED_COLOR "Error arguments!\n" ENDL_COLOR);
        return FUNC_FAIL;
    }

    if(check_img_exist(argv[1]))
    {
        printf(RED_COLOR "RAW file not found!\n" ENDL_COLOR);
        return FUNC_FAIL;
    }
    else
        printf(GREEN_COLOR "RAW file found!\n\n" ENDL_COLOR);

    BYTE u08Ret = FUNC_SUC;
    BMPImage *img = read_raw_image(argv[1]);
    if(!img)
    {
        printf(RED_COLOR "RAW to Gray BMP failed!\n" ENDL_COLOR);
        return FUNC_FAIL;
    }

    printf(YELLOW_COLOR "Output Image\n" ENDL_COLOR);
    show_bmp_info(img);

    u08Ret |= write_image("output.bmp", img);
    free_bmp_image(img);

    return u08Ret;
}

BYTE check_img_exist(char *filename)
{
    FILE *fp = fopen(filename, "rb");

    if(!fp)
        return FUNC_FAIL;

    fclose(fp);
    return FUNC_SUC;
}

BMPImage *read_raw_image(const char *filename)
{
    FILE *fp = fopen(filename, "rb");
    if(!fp)
        return NULL;

    LWORD raw_size = RAW_WIDTH * RAW_HEIGHT;
    BYTE *raw = (BYTE*)malloc(raw_size);
    if(!raw)
    {
        fclose(fp);
        return NULL;
    }

    size_t num_read = fread(raw, 1, raw_size, fp);
    fclose(fp);
    if(num_read != raw_size)
    {
        free(raw);
        return NULL;
    }

    BMPImage *img = raw_to_gray_bmp(raw, RAW_WIDTH, RAW_HEIGHT);
    free(raw);
    return img;
}

BYTE write_image(const char *filename, BMPImage *img)
{
    if(!img)
    {
        printf(RED_COLOR "No image data!\n" ENDL_COLOR);
        return FUNC_FAIL;
    }

    BYTE u08Ret = FUNC_SUC;
    LWORD error_record = 0;
    FILE *fp = fopen(filename, "wb");

    if(!fp)
    {
        printf(RED_COLOR "This file path cannot be written BMP image!" ENDL_COLOR);
        u08Ret |= FUNC_FAIL;
    }
    else
    {
        if(write_bmp(fp, img, &error_record))
            u08Ret |= FUNC_FAIL;
        else
            printf(GREEN_COLOR "Image has been written!\n" ENDL_COLOR);
    }

    fclose(fp);
    return u08Ret;
}
