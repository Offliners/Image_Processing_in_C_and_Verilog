# RAW to Gray
Read 8-bit grayscale RAW (`width × height` bytes) and write 24-bit BMP with B=G=R (same style as BGR→Gray output).

| Input                   | Output                       |
| ----------------------- | ---------------------------- |
| ![input](../lena256.bmp) | ![output](./C/output.bmp) |

*實際輸入檔為 `lena256_gray.raw`（8-bit 灰階）；左圖為同解析度場景之彩色參考，右圖為 RAW 轉 BMP 結果。*

輸出前會呼叫 `bmp_flip_top_bottom_inplace()`（與 [Image Vertical Flip](../image_vertical_flip/README.md) 相同），對齊 BMP 列順序。

## Usage
```shell
# C
$ cd ./raw_to_gray/C
$ make
$ ./raw_to_gray.o ../../lena256_gray.raw

# RTL
$ cd ./raw_to_gray/RTL
$ make simulate

# Confirm whether the two BMP images are the same
$ cd ./raw_to_gray
$ python3 ../load_image/compare.py -c ./C/output.bmp -rtl ./RTL/output.bmp
```
