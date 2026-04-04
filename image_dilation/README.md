# Image Dilation
Apply 3x3 dilation on a binarized grayscale image.

| Input                   | Output (3×3 dilation)   |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
**Binary dilation** (morphology) expands **foreground** (white) regions. With structuring element \(S\) (here **3×3** ones) and binary image \(I\),

```math
(I\oplus S)(p)=\bigvee_{s\in S} I(p+s)
```

where \(\vee\) is logical **OR** (equivalently **max** on \(\{0,255\}\) pixels).

## Usage
```shell
# C
$ cd ./image_dilation/C
$ make
$ ./image_dilation.o ../lena256.bmp

# RTL
$ cd ./image_dilation/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./image_dilation
$ python3 compare.py
```
