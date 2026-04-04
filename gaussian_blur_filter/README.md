# Gaussian Blur Filter
Apply a 3×3 Gaussian blur **per color channel** (BGR); output is a **24-bit RGB/BGR** image. Border pixels are copied unchanged.

| Input                   | Output (3×3 Gaussian)   |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./gaussian_blur_filter/C
$ make
$ ./gaussian_blur.o ../lena256.bmp

# RTL
$ cd ./gaussian_blur_filter/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./gaussian_blur_filter
$ python3 compare.py
```
