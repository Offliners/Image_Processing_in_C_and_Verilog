import os
from typing import List
from argparse import ArgumentParser, Namespace

class bcolors:
    RED   = '\033[0;31m'
    GREEN = '\033[0;32m'
    ENDC  = '\033[m'


def parse_args() -> Namespace:
    parser = ArgumentParser(description='BMP Image Comparator')

    parser.add_argument(
        "-c",
        type=str,
        default="./C/output.bmp",
        help="Path to BMP image processed by C"
    )

    parser.add_argument(
        "-v",
        type=str,
        default="./verilog/output.bmp",
        help="Path to BMP image processed by Verilog"
    )

    args = parser.parse_args()
    return args

def read_file(path: str, size: int, mode: str = "rb") -> List[str]:
    raw_data = []
    with open(path, mode) as f:
        for _ in range(size):
            raw_data.append(f.read(1).hex())

    return raw_data


def data_compare(a: List[str], b: List[str]) -> dict:
    diff_info = {}
    for i in range(len(a)):
        if a[i] != b[i]:
            diff_info[i] = [a[i], b[i]]

    return diff_info


def main(args: ArgumentParser) -> None:
    if not os.path.exists(args.c):
        print(bcolors.RED + "Cannot find BMP file processed by C" + bcolors.ENDC)
        show_fail()
    
    if not os.path.exists(args.v):
        print(bcolors.RED + "Cannot find BMP file processed by Verilog" + bcolors.ENDC)
        show_fail()

    c_bmp_size = os.path.getsize(args.c)
    verilog_bmp_size = os.path.getsize(args.v)

    if c_bmp_size != verilog_bmp_size:
        print(bcolors.RED + "The two pictures have different sizes!" + bcolors.ENDC)
        show_fail()
    
    c_bmp_data = read_file(args.c, c_bmp_size)
    verilog_bmp_data = read_file(args.v, verilog_bmp_size)
    diff_info = data_compare(c_bmp_data, verilog_bmp_data)

    if diff_info:
        for k, v in diff_info.items():
            print(f"offset {hex(k)}:  C is 0x{v[0]}, Verilog is 0x{v[1]}")
            
        show_fail()

    show_pass()


def show_fail():
    print(bcolors.RED + "        ----------------------------               " + bcolors.ENDC)
    print(bcolors.RED + "        --                        --       |\\__|\\" + bcolors.ENDC)
    print(bcolors.RED + "        --  OOPS!!                --      / X,X  | " + bcolors.ENDC)
    print(bcolors.RED + "        --                        --    /_____   | " + bcolors.ENDC)
    print(bcolors.RED + "        --  COMPARE FAIL!!        --   /^ ^ ^ \\  |" + bcolors.ENDC)
    print(bcolors.RED + "        --                        --  |^ ^ ^ ^ |w| " + bcolors.ENDC)
    print(bcolors.RED + "        ----------------------------   \\m___m__|_|" + bcolors.ENDC)
    os._exit(1)


def show_pass():
    print(bcolors.GREEN + "        ----------------------------               " + bcolors.ENDC)
    print(bcolors.GREEN + "        --                        --       |\\__|\\" + bcolors.ENDC)
    print(bcolors.GREEN + "        --  Congratulations !!    --      / O.O  | " + bcolors.ENDC)
    print(bcolors.GREEN + "        --                        --    /_____   | " + bcolors.ENDC)
    print(bcolors.GREEN + "        --  COMPARE PASS!!        --   /^ ^ ^ \\  |" + bcolors.ENDC)
    print(bcolors.GREEN + "        --                        --  |^ ^ ^ ^ |w| " + bcolors.ENDC)
    print(bcolors.GREEN + "        ----------------------------   \\m___m__|_|" + bcolors.ENDC)


if __name__ == '__main__':
    args = parse_args()
    main(args)