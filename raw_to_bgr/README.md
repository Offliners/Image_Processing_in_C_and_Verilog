# RAW to BGR
Convert 8-bit-per-channel RGB interleaved RAW (`width × height × 3` bytes) to 24-bit BGR BMP.

| Input                                           | Output                  |
| ----------------------------------------------- | ----------------------- |
| ![preview](./lena256.bmp) **`lena256_rgb.raw`** | ![output](./output.bmp) |

*Actual pixel source for the program is **`./lena256_rgb.raw`** (RGB interleaved). **`./lena256.bmp`** is a preview of the same scene.*

輸出前會呼叫共用函式 `bmp_flip_top_bottom_inplace()`（與 [Image Vertical Flip](../image_vertical_flip/README.md) 相同概念），以配合 BMP 由下往上的光柵順序，避免畫面上下顛倒。

## Usage
```shell
# C
$ cd ./raw_to_bgr/C
$ make
$ ./raw_to_bgr.o ../lena256_rgb.raw

# RTL
$ cd ./raw_to_bgr/RTL
$ make simulate

# Compare C vs RTL
$ cd ./raw_to_bgr
$ python3 compare.py
```
