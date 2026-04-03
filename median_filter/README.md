# Median Filter
Read image with salt and pepper noise from BMP (bitmap) file, and then use median filter to remove noise.

Base image in this folder is **`./lena256.bmp`**. For the noisy input used by the C program, generate **`./lena256_noise.bmp`** (see below). Program output is **`./output.bmp`** (written under `C/output.bmp` when you run from `C/`).

| Input                          | Output (filter size: 3)  |
| ------------------------------ | ------------------------ |
| ![input](./lena256_noise.bmp) | ![output](./output.bmp) |

## Usage
```shell
# Generate salt-and-pepper image from ./lena256.bmp
$ cd ./median_filter
$ python3 add_noise.py -i ./lena256.bmp -o ./lena256_noise.bmp

# C
$ cd ./median_filter/C
$ make
$ ./median_filter.o ../lena256_noise.bmp 3

# RTL
$ cd ./median_filter/RTL
$ make check
$ make simulate
$ make wave

# Compare C vs RTL
$ cd ./median_filter
$ python3 compare.py
```
