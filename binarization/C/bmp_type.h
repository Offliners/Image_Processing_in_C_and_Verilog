#ifndef _BINARIZATION_BMP_TYPE_WRAPPER_H_
#define _BINARIZATION_BMP_TYPE_WRAPPER_H_

#include "../../common/C/bmp_type.h"

BMPImage *RGB2Gray(BMPImage *src_img);
BMPImage *binarize_bmp(BMPImage *src_img, BYTE threshold);

#endif // _BINARIZATION_BMP_TYPE_WRAPPER_H_