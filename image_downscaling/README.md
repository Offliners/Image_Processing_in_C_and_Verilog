# Image Downscaling

Read a **256×256** 24-bit BMP and write a **128×128** BMP: each output pixel is the **average of a 2×2 block** of input pixels, **per channel** (B, G, R). Rounding matches RTL: \((\mathrm{sum} + 2) / 4\) with integer truncation.

Both **C** and **RTL** read **`./lena256.bmp`** and write **`./output.bmp`** (C in the module root, RTL in `RTL/output.bmp`). Use **`python3 compare.py`** to verify they match.

| Input (256×256) | Output (128×128) |
| --------------- | ---------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage

```shell
cd ./image_downscaling/C
make
./image_downscale.o ../lena256.bmp

cd ../RTL
make ivl_rtl

cd ..
python3 compare.py
```

## Principle

With input size \(H \times W\) (even), output size is \((H/2) \times (W/2)\). For output coordinates \((y,x)\):

\[
\hat{I}(y,x)=\frac{1}{4}\sum_{dy=0}^{1}\sum_{dx=0}^{1} I(2y+dy,\,2x+dx)
\]

applied independently to B, G, and R. The BMP header is updated (file size, width, height, image size).
