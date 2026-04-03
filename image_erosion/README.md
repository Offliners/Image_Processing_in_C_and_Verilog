# Image Erosion
Apply 3x3 erosion on a binarized grayscale image.

| Input                   | Output (3×3 erosion)    |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./image_erosion/C
$ make
$ ./image_erosion.o ../lena256.bmp

# RTL
$ cd ./image_erosion/RTL
$ make simulate

# Compare C vs RTL
$ cd ./image_erosion
$ python3 compare.py
```
