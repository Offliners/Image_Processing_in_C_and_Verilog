# Histogram Equalization
Equalize grayscale histogram to enhance contrast.  
Input must be a **grayscale** 24-bit BMP (`lena256.bmp`: B=G=R per pixel); histogram and mapping use the **B** channel, output remains B=G=R.

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
**Histogram equalization** remaps intensities using the **cumulative histogram** so the output uses the full dynamic range more uniformly. With \(N\) pixels, levels \(L=256\), and counts \(h[k]\):

```math
\mathrm{cdf}(k)=\sum_{t=0}^{k} h(t),\qquad
s(k)=\left\lfloor (L-1)\,\frac{\mathrm{cdf}(k)}{N}\right\rfloor
```

Output gray is \(s\bigl(g(x,y)\bigr)\), written as **B=G=R** in the BMP.

## Usage
```shell
# C
$ cd ./histogram_equalization/C
$ make
$ ./histogram_equalization.o ../lena256.bmp

# RTL
$ cd ./histogram_equalization/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./histogram_equalization
$ python3 compare.py
```
