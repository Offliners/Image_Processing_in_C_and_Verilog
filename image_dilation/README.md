# Image Dilation
Apply 3x3 dilation on a binarized grayscale image.

| Input                   | Output (3×3 dilation)        |
| ----------------------- | ---------------------------- |
| ![input](../lena256.bmp) | ![output](./C/output.bmp) |

## Usage
```shell
# C
$ cd ./image_dilation/C
$ make
$ ./image_dilation.o ../../lena256.bmp

# RTL
$ cd ./image_dilation/RTL
$ make simulate
```
