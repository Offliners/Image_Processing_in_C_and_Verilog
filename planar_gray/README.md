# Planar gray (BGR → single Y plane → 24 bpp gray BMP)

Demonstrates **one planar SRAM** (one byte per pixel) instead of three B/G/R planes:

1. **Load** (`LOAD_BMP_PLANAR_GRAY`): BMP header → output RAM; body BGR stream → \(Y = (30B + 150G + 76R) \gg 8\) written to planar RAM.
2. **Algorithm** (`PLANAR_GRAY_ALGO_IDENTITY`): after `load_done`, identity byte writes on the Y plane (TB mux: **LOAD > ALGO > MERGE read**), then `algo_done` → `merge_start` (same handshake as `planar_bgr`).
3. **Merge** (`PLANAR_GRAY_MERGE_TO_BMP`): read \(Y\) per pixel; write **B=G=R=Y** to interleaved output (same style as [BGR to Gray](../bgr_to_gray/README.md) output).

RTL verification in this repo uses **Synopsys VCS**: `make vs_rtl` (see each module’s `RTL/Makefile`).

| Input (color BMP) | Output (grayscale 24 bpp) |
| ----------------- | ------------------------- |
| ![in](./lena256.bmp) | ![out](./output.bmp) |

## Usage

```shell
cd ./planar_gray/C && make && ./planar_gray.o ../lena256.bmp
cd ../RTL && make vs_rtl
cd .. && python3 compare.py
```

## Note on memory

Total **pixel storage** is **one** plane (plus output buffer), smaller than storing full B+G+R separately. For further area reduction, combine with **line buffers** and window-based reads for kernels.
