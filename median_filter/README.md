# Median Filter
Read image with salt and pepper noise from BMP (bitmap) file, and then use median filter to remove noise.

| Input                         | Output                  |
| ----------------------------- | ----------------------- |
| ![input](./lena256_noise.bmp) | ![output](./output.bmp) |

## Usage
```shell
# Generate lena image with salt and pepper noise
$ cd ./median_filter
$ python3 add_noise.py 

# C
$ cd ./median_filter/C
$ make
$ ./median_filter.o ../lena256.bmp

# RTL
$ cd ./median_filter/RTL
$ make check
$ make simulate
$ make wave

# Confirm whether the two BMP images are the same
$ cd ./median_filter
$ python3 compare.py 
```