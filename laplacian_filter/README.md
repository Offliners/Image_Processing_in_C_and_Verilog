# Laplacian Filter
Detect edges using 3x3 Laplacian operator on a grayscale image.

| Input                   | Output (3×3 Laplacian)       |
| ----------------------- | ---------------------------- |
| ![input](../lena256.bmp) | ![output](./C/output.bmp) |

## Usage
```shell
# C
$ cd ./laplacian_filter/C
$ make
$ ./laplacian_filter.o ../../lena256.bmp

# RTL
$ cd ./laplacian_filter/RTL
$ make simulate
```
