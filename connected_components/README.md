# Connected Components
Label connected components on a binarized grayscale image (4-connectivity).

| Input                   | Output (4-connectivity) |
| ----------------------- | ----------------------- |
| ![input](./lena256.bmp) | ![output](./output.bmp) |

## Principle
After binarization, **connected-component labeling** partitions foreground pixels into disjoint sets such that two pixels are in the same component if they are linked by **4-neighborhood** paths (up/down/left/right). Each component receives a **unique label** (visualized as a color in the output BMP). Graph view: vertices = foreground pixels, edges = unit orthogonal adjacency; components are **connected components** of that graph (often found by **BFS/DFS** or union–find).

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
