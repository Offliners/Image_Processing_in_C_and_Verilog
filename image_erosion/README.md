# Image Erosion
Apply 3x3 erosion on a binarized grayscale image.

| Input                   | Output (3×3 erosion)    |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
**Binary erosion** shrinks white regions by requiring the structuring element \(S\) to **fully fit** inside foreground at each location:

```math
(I\ominus S)(p)=\bigwedge_{s\in S} I(p+s)
```

where \(\wedge\) is logical **AND** (equivalently **min** on \(\{0,255\}\) pixels).

## Usage
```shell
# C
$ cd ./image_erosion/C
$ make
$ ./image_erosion.o ../lena256.bmp

# RTL
$ cd ./image_erosion/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./image_erosion
$ python3 compare.py
```
