# Histogram Equalization
Equalize grayscale histogram to enhance contrast.

| Input                   | Output                       |
| ----------------------- | ---------------------------- |
| ![input](../lena256.bmp) | ![output](./C/output.bmp) |

## Usage
```shell
# C
$ cd ./histogram_equalization/C
$ make
$ ./histogram_equalization.o ../../lena256.bmp

# RTL
$ cd ./histogram_equalization/RTL
$ make simulate
```
