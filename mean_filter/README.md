# Mean Filter
Read image from BMP (bitmap) file, and then use mean filter to blur image.

| Input                   | Output (filter size: 3)  |
| ----------------------- | ------------------------ |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
A **mean (box) filter** replaces each pixel by the **arithmetic average** over a \(k\times k\) neighborhood \(W_k(x,y)\), reducing random noise and smoothing detail:

```math
\hat{I}(x,y)=\frac{1}{k^{2}}\sum_{(i,j)\in W_k(x,y)} I(i,j)
```

## Usage
```shell
# C
$ cd ./mean_filter/C
$ make
$ ./mean_filter.o ../lena256.bmp 3

# RTL
$ cd ./mean_filter/RTL
$ make ivl_rtl
$ make gtk_wave

# Compare C vs RTL
$ cd ./mean_filter
$ python3 compare.py
```
