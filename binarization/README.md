# Binarization
Read image from BMP (bitmap) file, and then convert it (BGR image) to grayscale. Finally, set pixels to white or black determined by threshold.

| Input                   | Output                               |
| ----------------------- | ------------------------------------ |
| ![input](./lena256.bmp) | ![output](./output_binarization.bmp) |

## Usage
```shell
# C
$ cd ./binarization/C
$ make
$ ./binarization.o ../lena256.bmp

# Verilog
$ make check
$ make simulate
$ make wave
```