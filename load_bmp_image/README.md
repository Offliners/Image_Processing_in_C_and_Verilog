# Load BMP Image
Read image from BMP (bitmap) file, and then write it into another.

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
A BMP **DIB** stores a header (this project uses the classic **54-byte** file + info header) followed by **raw pixel rows**. Rows are often stored **bottom-up**, and each scanline is **padded** to a **4-byte** boundary. For 24-bit images, pixels are packed as **B, G, R** per sample (little-endian byte order in the file stream).

## Usage
```shell
# C
$ cd ./load_bmp_image/C
$ make
$ ./load_bmp_image.o ../lena256.bmp

# RTL
$ cd ./load_bmp_image/RTL
$ make ivl_rtl
$ make gtk_wave

# Compare C vs RTL (writes under C/ and RTL/)
$ cd ./load_bmp_image
$ python3 compare.py
```

*C writes `C/output.bmp`; RTL writes `RTL/output.bmp`. `compare.py` uses those paths by default.*

## BMP File Format
![BMP format](./img/bitmap_format.png)
