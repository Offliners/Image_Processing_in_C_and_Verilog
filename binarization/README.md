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
$ cd ./binarization/verilog
$ make check
$ make simulate
$ make wave

# Confirm whether the two BMP images are the same
$ cd ./binarization
$ python3 compare.py
```