.PHONY: clean

CUR_DIR = ./
OUTPUT_IMG = ./output.bmp

all:
	gcc ${CUR_DIR}*.c ../../common/C/bmp_func.c -o load_bmp_image.o -I${CUR_DIR} -I../../common/C

clean:
	rm -rf *.o ${OUTPUT_IMG}