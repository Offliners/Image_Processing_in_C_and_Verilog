# Median Filter
Read image with salt and pepper noise from BMP (bitmap) file, and then use median filter to remove noise.

Base image in this folder is **`./lena256.bmp`**. Both **C** and **RTL** read the same noisy input **`./lena256_noise.bmp`**; generate it with `add_noise.py` (below). Program output is **`./output.bmp`** (C writes `C/output.bmp`, RTL writes `RTL/output.bmp`; `compare.py` compares those).

| Input                          | Output (filter size: 3)  |
| ------------------------------ | ------------------------ |
| ![input](./lena256_noise.bmp) | ![output](./output.bmp) |

## Principle
The **median filter** is an **order-statistic** smoother: the center pixel becomes the **median** of intensities inside a \(k\times k\) window. It removes **salt-and-pepper** impulses better than a mean filter while keeping edges sharper than strong blurring:

```math
\hat{I}(x,y)=\mathrm{median}\{\, I(i,j) : (i,j)\in W_k(x,y)\,\}
```

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
$ make ivl_rtl
$ make gtk_wave

# Compare C vs RTL
$ cd ./median_filter
$ python3 compare.py
```
