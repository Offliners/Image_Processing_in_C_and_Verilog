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

# Confirm whether the two BMP images are the same
$ cd ./load_bmp_image
$ python3 compare.py 
```

## BMP File Format
![BMP format](./img/bitmap_format.png)