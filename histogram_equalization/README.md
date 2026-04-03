# Histogram Equalization
Equalize grayscale histogram to enhance contrast.  
Input must be a **grayscale** 24-bit BMP (`lena256.bmp`: B=G=R per pixel); histogram and mapping use the **B** channel, output remains B=G=R.

| Input                   | Output                  |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./histogram_equalization/C
$ make
$ ./histogram_equalization.o ../lena256.bmp

# RTL
$ cd ./histogram_equalization/RTL
$ make simulate

# Compare C vs RTL
$ cd ./histogram_equalization
$ python3 compare.py
```
