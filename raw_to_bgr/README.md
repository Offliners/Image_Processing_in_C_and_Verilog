# RAW to BGR
Convert 8-bit-per-channel RGB interleaved RAW (`width × height × 3` bytes) to 24-bit BGR BMP.

| Input             | Output                  |
| ----------------- | ----------------------- |
| `lena256_rgb.raw` | ![output](./output.bmp) |

## Principle
The RAW file is **8-bit RGB interleaved**, **row-major**, with **\(3WH\)** bytes for width \(W\) and height \(H\) (\(R,G,R,G,\ldots\) per row). BMP 24-bit pixels are stored as **B, G, R** per sample, and DIB rows are typically **bottom-up**, so the converter **reorders channels** and may **flip rows** to match BMP conventions.

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
