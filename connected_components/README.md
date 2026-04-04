# Connected Components
Label connected components on a binarized grayscale image (4-connectivity).

| Input                   | Output (4-connectivity) |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Usage
```shell
# C
$ cd ./connected_components/C
$ make
$ ./connected_components.o ../lena256.bmp

# RTL
$ cd ./connected_components/RTL
$ make ivl_rtl

# Compare C vs RTL
$ cd ./connected_components
$ python3 compare.py
```
