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

## Flow
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
    b0[                  ] --- b2[ ] --- b4[ ] --- ImplementFlow --- b1[ ] --- b3[ ] --- b5[                  ]
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
    
    subgraph ImplementFlow
    direction TB
    style ImplementFlow fill:#ffffff00, stroke-width:0px

    direction TB
        A[Read BMP image from ROM]
        A --> B[Read BMP Header]
        B --> C[Write BMP Header to RAM]
        C --> D[Read BMP Pixel Data]
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