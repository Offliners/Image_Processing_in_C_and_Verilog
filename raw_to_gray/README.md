# RAW to Gray
Read 8-bit grayscale RAW (`width × height` bytes) and write 24-bit BMP with B=G=R (same style as BGR→Gray output).

| Input              | Output                  |
| -------------------| ----------------------- |
| `lena256_gray.raw` | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./raw_to_gray/C
$ make
$ ./raw_to_gray.o ../lena256_gray.raw

# RTL
$ cd ./raw_to_gray/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./raw_to_gray
$ python3 compare.py
```
