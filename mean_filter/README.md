# Mean Filter
Read image with salt and pepper noise from BMP (bitmap) file, and then use mean filter to remove noise.

| Input                         | Output (filter size: 3)          |
| ----------------------------- | -------------------------------- |
| ![input](./lena256_noise.bmp) | ![output](./output_filtered.bmp) |

## Usage
```shell
# Generate lena image with salt and pepper noise
$ cd ./mean_filter
$ python3 add_noise.py 

# C
$ cd ./mean_filter/C
$ make
$ ./mean_filter.o ../lena256_noise.bmp 3 # set the size of mean filter to 3

# RTL
$ cd ./mean_filter/RTL
$ make check
$ make simulate
$ make wave

# Confirm whether the two BMP images are the same
$ cd ./mean_filter
$ python3 compare.py 
```