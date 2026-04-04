# RAW to BGR
Convert 8-bit-per-channel RGB interleaved RAW (`width × height × 3` bytes) to 24-bit BGR BMP.

| Input             | Output                  |
| ----------------- | ----------------------- |
| `lena256_rgb.raw` | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./raw_to_bgr/C
$ make
$ ./raw_to_bgr.o ../lena256_rgb.raw

# RTL
$ cd ./raw_to_bgr/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./raw_to_bgr
$ python3 compare.py
```
