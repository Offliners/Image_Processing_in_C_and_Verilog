#include <stdio.h>
#include <stdlib.h>
#include "com_type.h"
#include "bmp_type.h"

int check_img_exist(char *filename);

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

    return FUNC_SUC;
}

int check_img_exist(char *filename)
{
    FILE *fp = fopen(filename, "r");

    if(!fp)
        return FUNC_FAIL;
    
    return FUNC_SUC;
}