# Mean Filter
Read image from BMP (bitmap) file, and then use mean filter to blur image.

| Input                   | Output (filter size: 3)          |
| ----------------------- | -------------------------------- |
| ![input](./lena256.bmp) | ![output](./output_filtered.bmp) |

## Usage
```shell
# C
$ cd ./mean_filter/C
$ make
$ ./mean_filter.o ../lena256.bmp 3 # set the size of mean filter to 3

# RTL
$ cd ./mean_filter/RTL
$ make check
$ make simulate
$ make wave

# Confirm whether the two BMP images are the same
$ cd ./mean_filter
$ python3 compare.py 
```