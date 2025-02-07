#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "bmp_type.h"

BYTE check_img_exist(char *filename);
BMPImage *read_image(const char *filename);
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
        printf(RED_COLOR "Image not found!\n" ENDL_COLOR);
        return FUNC_FAIL;
    }
    else
        printf(GREEN_COLOR "Image found!\n\n" ENDL_COLOR);

    BYTE u08Ret = FUNC_SUC;
    BMPImage *img = read_image(argv[1]);

    printf(YELLOW_COLOR "Input Image\n" ENDL_COLOR);
    show_bmp_info(img);

    BMPImage *gray_img = RGB2Gray(img);

    printf(YELLOW_COLOR "Output Image\n" ENDL_COLOR);
    show_bmp_info(gray_img);

    u08Ret |= write_image("output.bmp", gray_img);

    free_bmp_image(img);
    free_bmp_image(gray_img);

    return u08Ret;
}

BYTE check_img_exist(char *filename)
{
    FILE *fp = fopen(filename, "r");

    if(!fp)
        return FUNC_FAIL;
    
    return FUNC_SUC;
}

BMPImage *read_image(const char *filename)
{
    LWORD error_record = 0;
    FILE *fp = fopen(filename, "rb");
    BMPImage *img = read_bmp(fp, &error_record);

    if(error_record || !img)
        return NULL;
    
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
        u08Ret|= FUNC_FAIL;
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