# Image Horizontal Flip
**Horizontal flip** (mirror left and right): each row’s pixels are reversed so the image appears mirrored along the vertical center line. This is different from [Image Vertical Flip](../image_vertical_flip/README.md), which swaps top and bottom rows.

| Input                   | Output (mirrored)        |
| ----------------------- | ------------------------ |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
**Horizontal flip** mirrors each row about the vertical midline. With image width \(W\),

```math
I'(x,y)=I(W-1-x,\,y)
```

## Usage
```shell
# C
$ cd ./image_horizontal_flip/C
$ make
$ ./horizontal_flip.o ../lena256.bmp

# RTL
$ cd ./image_horizontal_flip/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./image_horizontal_flip
$ python3 compare.py
```
