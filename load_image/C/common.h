#ifndef _COMMON_H_
#define _COMMON_H_

#define FUNC_FAIL 1
#define FUNC_SUC  0

#define RED_COLOR    "\033[0;31m"
#define GREEN_COLOR  "\033[0;32m"
#define YELLOW_COLOR "\033[0;33m"
#define ENDL_COLOR   "\033[m"

typedef unsigned char  BYTE;
typedef unsigned short WORD;
typedef unsigned int   LWORD;

#define LWORD_SIZE   (sizeof(LWORD))

#endif // _COMMON_H_