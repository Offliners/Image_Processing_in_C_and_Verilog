# Binarization
Read image from BMP (bitmap) file, and then convert it (BGR image) to grayscale. Finally, set pixels to white or black determined by threshold.

| Input                   | Output (threshold: 8'd127) |
| ----------------------- | -------------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp)    |

## Principle
Each pixel is first mapped to a scalar gray \(Y\) (same luma idea as BGR→Gray), then **binarized** against a fixed threshold \(T\):

```math
O(x,y)=
\begin{cases}
255 & \text{if } Y(x,y) \ge T \\
0   & \text{otherwise}
\end{cases}
```

(All three BMP channels are set to \(O(x,y)\).)

## Usage
```shell
# C
$ cd ./binarization/C
$ make
$ ./binarization.o ../lena256.bmp

# RTL
$ cd ./binarization/RTL
$ make ivl_rtl
$ make gtk_wave

# Compare C vs RTL
$ cd ./binarization
$ python3 compare.py
```
