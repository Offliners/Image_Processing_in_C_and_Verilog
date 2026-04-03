.PHONY: clean

CUR_DIR = ./
OUTPUT_IMG = ./output.bmp

all:
	gcc ${CUR_DIR}main.c ../../common/C/bmp_func.c -o horizontal_flip.o -I${CUR_DIR} -I../../common/C

clean:
	rm -rf *.o ${OUTPUT_IMG}
