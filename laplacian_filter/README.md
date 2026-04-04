# Laplacian Filter
Detect edges using 3x3 Laplacian operator on a grayscale image.

| Input                   | Output (3×3 Laplacian)  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
The **Laplacian** highlights regions of rapid intensity change via the **second spatial derivatives** of the image. In the continuous form,

```math
\nabla^{2}I = \frac{\partial^{2}I}{\partial x^{2}} + \frac{\partial^{2}I}{\partial y^{2}}
```

A discrete **3×3** mask \(L\) implements \(\nabla^{2}I \approx I \ast L\) on grayscale pixels.

## Usage
```shell
# C
$ cd ./laplacian_filter/C
$ make
$ ./laplacian_filter.o ../lena256.bmp

# RTL
$ cd ./laplacian_filter/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./laplacian_filter
$ python3 compare.py
```