# Load BMP Image
Read image from BMP (bitmap) file, and then write it into another.

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./load_bmp_image/C
$ make
$ ./load_bmp_image.o ../lena256.bmp

# RTL
$ cd ./load_bmp_image/RTL
$ make check
$ make simulate
$ make wave

# Compare C vs RTL (writes under C/ and RTL/)
$ cd ./load_bmp_image
$ python3 compare.py
```

*C writes `C/output.bmp`; RTL writes `RTL/output.bmp`. `compare.py` uses those paths by default.*

## BMP File Format
![BMP format](./img/bitmap_format.png)
