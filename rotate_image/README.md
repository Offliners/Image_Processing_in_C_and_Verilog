# Rotate Image
Read image from BMP (bitmap) file, and then rotate it in 90 degree (clockwise).

| Input                   | Output                         |
| ----------------------- | ------------------------------ |
| ![input](./lena256.bmp) | ![output](./output_rot_90.bmp) |

## Usage
```shell
# C
$ cd ./rotate_image/C
$ make
$ ./rotate_image.o ../lena256.bmp

# Verilog
$ make check
$ make simulate
$ make wave
```