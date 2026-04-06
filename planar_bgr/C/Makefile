.PHONY: clean

CUR_DIR = ./
OUTPUT_IMG = ../output.bmp

all:
	gcc ${CUR_DIR}main.c ${CUR_DIR}bmp_func.c ../../common/C/bmp_func.c -o planar_bgr.o -I${CUR_DIR} -I../../common/C

clean:
	rm -rf *.o ${OUTPUT_IMG}
