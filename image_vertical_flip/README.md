# Image Vertical Flip（垂直翻轉）

將畫素列**上下對調**（垂直翻轉），不是左右鏡像。BMP／DIB 光柵通常**由下往上**儲存，而 RAW 掃描多為**由上往下**，直接對應會造成畫面**上下顛倒**；本操作與 [RAW to BGR](../raw_to_bgr/README.md)、[RAW to Gray](../raw_to_gray/README.md) 中使用的列對調一致。

| Input                   | Output (flipped)        |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./image_vertical_flip/C
$ make
$ ./vertical_flip.o ../lena256.bmp

# RTL
$ cd ./image_vertical_flip/RTL
$ make simulate

# Compare C vs RTL
$ cd ./image_vertical_flip
$ python3 compare.py
```
