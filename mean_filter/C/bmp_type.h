#ifndef _MEAN_FILTER_BMP_TYPE_WRAPPER_H_
#define _MEAN_FILTER_BMP_TYPE_WRAPPER_H_

#include "../../common/C/bmp_type.h"

BMPColorTable **create_pixel_matrix(LWORD height, LWORD width);
BMPColorTable **copy_pixel_matrix(BMPColorTable **mat, LWORD height, LWORD width);
void free_pixel_matrix(BMPColorTable **mat, LWORD height);
BMPImage *MeanFilter(BMPImage *src_img, LWORD mask_size);
BMPColorTable cal_mean(BMPColorTable *arr, LWORD arr_size);

#endif // _MEAN_FILTER_BMP_TYPE_WRAPPER_H_