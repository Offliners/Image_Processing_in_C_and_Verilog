# Sobel Filter
Detect edges using Sobel operator on a grayscale image.

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./sobel_filter/C
$ make
$ ./sobel_filter.o ../lena256.bmp

# RTL
$ cd ./sobel_filter/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./sobel_filter
$ python3 compare.py
```
