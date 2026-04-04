# Image Histogram
Compute grayscale histogram and render it as a 256x256 BMP.  
Input must be a **grayscale** 24-bit BMP (`lena256.bmp`: B=G=R per pixel); the **B** channel is used as the gray level.

| Input                   | Output (histogram BMP)  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
A **histogram** counts pixels at each gray level \(k\in\{0,\ldots,255\}\) (here using the **B** channel as gray on a B=G=R input):

```math
h[k]=\sum_{x,y}\mathbf{1}\bigl[g(x,y)=k\bigr],\qquad \sum_k h[k]=N
```

The result is drawn as a **256×256** bar-style BMP for visualization.

## Usage
```shell
# C
$ cd ./image_histogram/C
$ make
$ ./image_histogram.o ../lena256.bmp

# RTL
$ cd ./image_histogram/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./image_histogram
$ python3 compare.py
```
