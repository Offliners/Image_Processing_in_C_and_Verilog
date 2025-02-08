# Image Processing in C & Verilog
In this repository there are some image processing algorithms implemented using C and Verilog, and then use Python3 to compare the result whether there is any difference.

## Table of Contents
* [Table of Contents](#table-of-contents)
* [Contents](#contents)
    + [Load Image](#load-image)
    + [BGR to Gray](#bgr-to-gray)
    + [Binarization](#binarization)
    + [Median Filter](#median-filter)
* [Image Processing Flow](#image-processing-flow)
* [Tools](#tools)

## Contents
### [Load Image](./load_image/README.md)
Read image from BMP (bitmap) file, and then write it into another.
<details>
<summary>More</summary>

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./load_image/lena256.bmp) | ![output](./load_image/output.bmp) |

</details>

### [BGR to Gray](./bgr_to_gray/README.md)
Read image from BMP (bitmap) file, and then convert it (BGR image) to grayscale.

<details>
<summary>More</summary>

| Input                   | Output                       |
| ----------------------- | ---------------------------- |
| ![input](./bgr_to_gray/lena256.bmp) | ![output](./bgr_to_gray/output_gray.bmp) |

</details>

### [Binarization](./binarization/README.md)
Read image from BMP (bitmap) file, and then convert it (BGR image) to grayscale. Finally, set pixels to white or black determined by threshold.

<details>
<summary>More</summary>

| Input                   | Output                               |
| ----------------------- | ------------------------------------ |
| ![input](./binarization/lena256.bmp) | ![output](./binarization/output_binarization.bmp) |

</details>

### [Median Filter](./median_filter/README.md)
Read image with salt and pepper noise from BMP (bitmap) file, and then use median filter to remove noise.

<details>
<summary>More</summary>

| Input                         | Output (Filter size: 3) |
| ----------------------------- | ----------------------- |
| ![input](./median_filter/lena256_noise.bmp) | ![output](./median_filter/output_filtered.bmp) |

</details>

## Image Processing Flow
```mermaid
%%{
  init: {
    'theme': 'neutral',
    'themeVariables': {
      'textColor': '#000000',
      'noteTextColor' : '#000000',
      'fontSize': '20px'
    }
  }
}%%

flowchart LR
    b0[                  ] --- b2[ ] --- b4[ ] --- ProcessingFlow --- b1[ ] --- b3[ ] --- b5[                  ]
    style b0 stroke-width:0px, fill: #FFFFFF00, color:#FFFFFF00
    style b1 stroke-width:0px, fill: #FFFFFF00
    style b2 stroke-width:0px, fill: #FFFFFF00
    style b3 stroke-width:0px, fill: #FFFFFF00
    style b4 stroke-width:0px, fill: #FFFFFF00
    style b5 stroke-width:0px, fill: #FFFFFF00, color:#FFFFFF00

    linkStyle 0 stroke-width:0px
    linkStyle 1 stroke-width:0px
    linkStyle 2 stroke-width:0px
    linkStyle 3 stroke-width:0px
    linkStyle 4 stroke-width:0px
    linkStyle 5 stroke-width:0px
    
    subgraph ProcessingFlow
    direction TB
    style ProcessingFlow fill:#ffffff00, stroke-width:0px

    direction TB
        A[Put BMP image to ROM]
        A --> B[Read BMP Header from ROM]
        B --> C[Write BMP Header to RAM]
        C --> D[Read BMP Pixel Data from ROM]
        D --> E[Computer Vision Algorihtm]
        E --> F[Write BMP Pixel Data to RAM]
        style A fill:#74c2b5,stroke:#000000,stroke-width:4px
        style B fill:#f8cecc,stroke:#000000,stroke-width:4px
        style C fill:#fff2cc,stroke:#000000,stroke-width:4px
        style D fill:#cce5ff,stroke:#000000,stroke-width:4px
        style E fill:#fa6800,stroke:#000000,stroke-width:4px
        style F fill:#ff6666,stroke:#000000,stroke-width:4px
    end
```

## Tools
* GNU Compiler Collection
* Icarus Verilog
* GTKWave
* Python3