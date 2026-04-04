# Gaussian Blur Filter
Apply a 3×3 Gaussian blur **per color channel** (BGR); output is a **24-bit RGB/BGR** image. Border pixels are copied unchanged.

| Input                   | Output (3×3 Gaussian)   |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
**Gaussian smoothing** convolves the image with a kernel sampled from a 2D Gaussian (implemented here as a fixed **3×3** mask, **per BGR channel**). The continuous isotropic Gaussian is

```math
G_\sigma(x,y)=\frac{1}{2\pi\sigma^{2}}\exp\!\left(-\frac{x^{2}+y^{2}}{2\sigma^{2}}\right)
```

Discrete coefficients approximate \(G_\sigma\) on the integer grid; border pixels are left unchanged in this design.

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
