# Mean Filter
Read image from BMP (bitmap) file, and then use mean filter to blur image.

| Input                   | Output (filter size: 3)  |
| ----------------------- | ------------------------ |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./mean_filter/C
$ make
$ ./mean_filter.o ../lena256.bmp 3

# RTL
$ cd ./mean_filter/RTL
$ make check
$ make simulate
$ make wave

# Compare C vs RTL
$ cd ./mean_filter
$ python3 compare.py
```
