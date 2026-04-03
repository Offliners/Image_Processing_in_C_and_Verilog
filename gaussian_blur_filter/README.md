# Gaussian Blur Filter
Apply 3x3 Gaussian blur on a grayscale image.

| Input                   | Output (3×3 Gaussian)        |
| ----------------------- | ---------------------------- |
| ![input](../lena256.bmp) | ![output](./C/output.bmp) |

## Usage
```shell
# C
$ cd ./gaussian_blur_filter/C
$ make
$ ./gaussian_blur.o ../../lena256.bmp

# RTL
$ cd ./gaussian_blur_filter/RTL
$ make simulate
```
