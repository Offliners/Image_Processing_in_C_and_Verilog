# Image Histogram
Compute grayscale histogram and render it as a 256x256 BMP.

| Input                   | Output (histogram BMP)       |
| ----------------------- | ---------------------------- |
| ![input](../lena256.bmp) | ![output](./C/output.bmp) |

## Usage
```shell
# C
$ cd ./image_histogram/C
$ make
$ ./image_histogram.o ../../lena256.bmp

# RTL
$ cd ./image_histogram/RTL
$ make simulate
```
