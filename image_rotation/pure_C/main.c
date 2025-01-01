#include <stdio.h>
#include <stdlib.h>

#define FUNC_FAIL 1
#define FUNC_SUC  0

#define RED_COLOR    "\033[0;31m"
#define GREEN_COLOR  "\033[0;32m"
#define YELLOW_COLOR "\033[0;33m"
#define ENDL_COLOR   "\033[m"

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