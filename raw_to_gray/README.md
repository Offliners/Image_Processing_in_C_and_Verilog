# RAW to Gray
Read 8-bit grayscale RAW (`width × height` bytes) and write 24-bit BMP with B=G=R (same style as BGR→Gray output).

| Input                                            | Output                  |
| ------------------------------------------------ | ----------------------- |
| ![preview](./lena256.bmp) **`lena256_gray.raw`** | ![output](./output.bmp) |

*Actual pixel source for the program is **`./lena256_gray.raw`** (8-bit grayscale). **`./lena256.bmp`** is a color preview at the same resolution.*

輸出前會呼叫 `bmp_flip_top_bottom_inplace()`（與 [Image Vertical Flip](../image_vertical_flip/README.md) 相同），對齊 BMP 列順序。

## Usage
```shell
# C
$ cd ./raw_to_gray/C
$ make
$ ./raw_to_gray.o ../lena256_gray.raw

# RTL
$ cd ./raw_to_gray/RTL
$ make simulate

# Compare C vs RTL
$ cd ./raw_to_gray
$ python3 compare.py
```
