# Image Histogram
Compute grayscale histogram and render it as a 256x256 BMP.  
Input must be a **grayscale** 24-bit BMP (`lena256.bmp`: B=G=R per pixel); the **B** channel is used as the gray level.

| Input                   | Output (histogram BMP)  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./image_histogram/C
$ make
$ ./image_histogram.o ../lena256.bmp

# RTL
$ cd ./image_histogram/RTL
$ make simulate

# Compare C vs RTL
$ cd ./image_histogram
$ python3 compare.py
```
