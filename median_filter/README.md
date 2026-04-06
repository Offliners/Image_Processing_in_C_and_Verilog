# Median Filter
Read image with salt and pepper noise from BMP (bitmap) file, and then use median filter to remove noise.

| Input                          | Output (filter size: 3)  |
| ------------------------------ | ------------------------ |
| ![input](./lena256_noise.bmp) | ![output](./output.bmp) |

## Principle
The **median filter** uses a \(k\times k\) window. This project applies the **median separately to each BMP channel** (B, G, R): collect the nine \(B\) values, sort them, take the **middle** sample; repeat for \(G\) and \(R\). **C** uses **merge sort** on each channel; **RTL** uses a **Batcher odd-even mergesort** comparator network (merge-sort class, fixed 28 compare–exchange stages per channel for \(n=9\)).

```math
\hat{B}=\mathrm{median}\{B_{i,j}\},\quad
\hat{G}=\mathrm{median}\{G_{i,j}\},\quad
\hat{R}=\mathrm{median}\{R_{i,j}\},\quad (i,j)\in W_k
```

## Usage
```shell
# Generate salt-and-pepper image from ./lena256.bmp
$ cd ./median_filter
$ python3 add_noise.py -i ./lena256.bmp -o ./lena256_noise.bmp

# C
$ cd ./median_filter/C
$ make
$ ./median_filter.o ../lena256_noise.bmp

# RTL
$ cd ./median_filter/RTL
$ make ivl_rtl
$ make gtk_wave

# Compare C vs RTL
$ cd ./median_filter
$ python3 compare.py
```
