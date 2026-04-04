# Sobel Filter
Detect edges using Sobel operator on a grayscale image.

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
The **Sobel operator** estimates gradients with two separable **3×3** masks \(S_x\) (horizontal derivative) and \(S_y\) (vertical). Let \(G_x = I \ast S_x\), \(G_y = I \ast S_y\). Edge strength is often shown as

```math
|G| \approx |G_x| + |G_y|
\quad\text{or}\quad
|G| = \sqrt{G_x^{2}+G_y^{2}}
```

(Input is grayscale; output is encoded back to BMP.)

## Usage
```shell
# C
$ cd ./sobel_filter/C
$ make
$ ./sobel_filter.o ../lena256.bmp

# RTL
$ cd ./sobel_filter/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./sobel_filter
$ python3 compare.py
```
