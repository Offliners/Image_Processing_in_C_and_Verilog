# Computer Vision in C & Verilog
In this repository there are some computer vision algorithms implemented using C and Verilog

## Table of Contents
* [Table of Contents](#table-of-contents)
* [Overview](#overview)
* [Contents](#contents)
    + [Load Image](#load-image)
    + [BGR to Gray](#bgr-to-gray)
    + [Rotate Image](#rotate-image)
* [Tools](#tools)

## Overview
|[Load Image](./load_image/README.md)|[BGR to Gray](./bgr_to_gray/README.md)|[Rotate Image](./rotate_image/README.md)|
|-|-|-|
|![load image](./load_image/output.bmp)|![load image](./bgr_to_gray/output_gray.bmp)|![rotate image](./rotate_image/output_rot_90.bmp)|

## Contents
### Load Image
Read image from BMP (bitmap) file , and then write it into another.
<details>
<summary>More</summary>

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./load_image/lena256.bmp) | ![output](./load_image/output.bmp) |

</details>

### BGR to Gray
Read image from BMP (bitmap) file , and then convert it (BGR image) to grayscale.

<details>
<summary>More</summary>

| Input                   | Output                       |
| ----------------------- | ---------------------------- |
| ![input](./bgr_to_gray/lena256.bmp) | ![output](./bgr_to_gray/output_gray.bmp) |

</details>

### Rotate Image
Read image from BMP (bitmap) file , and then rotate it in 90 degree (clockwise).

<details>
<summary>More</summary>

| Input                   | Output                         |
| ----------------------- | ------------------------------ |
| ![input](./rotate_image/lena256.bmp) | ![output](./rotate_image/output_rot_90.bmp) |

</details>

## Tools
* GNU Compiler Collection
* Icarus Verilog
* GTKWave