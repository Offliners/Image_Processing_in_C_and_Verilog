import os
import random
import binascii
from typing import List
from argparse import ArgumentParser, Namespace

random.seed(0)

class bcolors:
    RED   = '\033[0;31m'
    GREEN = '\033[0;32m'
    ENDC  = '\033[m'


def parse_args() -> Namespace:
    parser = ArgumentParser(description='Add salt and pepper noise in BMP image')

    parser.add_argument(
        "-i",
        type=str,
        default="./lena256.bmp",
        help="Path to original BMP image"
    )

    parser.add_argument(
        "-o",
        type=str,
        default="./lena256_noise.bmp",
        help="Path to BMP image with noise"
    )

    args = parser.parse_args()
    return args


def read_file(path: str, size: int, mode: str = "rb") -> List[str]:
    raw_data = []
    with open(path, mode) as f:
        for _ in range(size):
            raw_data.append(f.read(1).hex())

    return raw_data


def write_file(path: str, size: int, data: List[str], mode: str = "wb") -> None:
    with open(path, mode) as f:
        for i in range(size):
            f.write(binascii.unhexlify(data[i]))


def add_noise(img: List[str], salt_ratio: float = 0.05, pepper_ratio: float = 0.05) -> List[str]:
    bmp_header_size = 54
    bmp_pixel_data = img[bmp_header_size:]

    img_width  = int("".join(img[18:22][::-1]), 16)
    img_height = int("".join(img[22:26][::-1]), 16)
    bits_per_pixel = int("".join(img[28:30][::-1]), 16)
    img_channel = bits_per_pixel // 8

    if len(bmp_pixel_data) != img_width * img_height * img_channel:
        print(bcolors.RED + "BMP pixel data is broken" + bcolors.ENDC)

    bgr_data = []
    for i in range(0, len(bmp_pixel_data), 3):
        blue  = bmp_pixel_data[i]
        green = bmp_pixel_data[i + 1]
        red   = bmp_pixel_data[i + 2]

        if random.random() < salt_ratio:
            bgr_data.append(['ff', 'ff', 'ff']) # white
        elif random.random() < pepper_ratio:
            bgr_data.append(['00', '00', '00']) # black
        else:
            bgr_data.append([blue, green, red])

    noise_img = img[:bmp_header_size]
    for data in bgr_data:
        noise_img += data

    return noise_img


def main(args: ArgumentParser) -> None:
    if not os.path.exists(args.i):
        print(bcolors.RED + "Cannot find original BMP file" + bcolors.ENDC)
        show_fail()

    bmp_size = os.path.getsize(args.i)
    img = read_file(args.i, bmp_size)
    noise_img = add_noise(img)

    write_file(args.o, bmp_size, noise_img)
    show_pass()


def show_fail():
    print(bcolors.RED + "        ----------------------------               " + bcolors.ENDC)
    print(bcolors.RED + "        --                        --       |\\__|\\" + bcolors.ENDC)
    print(bcolors.RED + "        --  OOPS!!                --      / X,X  | " + bcolors.ENDC)
    print(bcolors.RED + "        --                        --    /_____   | " + bcolors.ENDC)
    print(bcolors.RED + "        --  ADD NOISE FAIL!!      --   /^ ^ ^ \\  |" + bcolors.ENDC)
    print(bcolors.RED + "        --                        --  |^ ^ ^ ^ |w| " + bcolors.ENDC)
    print(bcolors.RED + "        ----------------------------   \\m___m__|_|" + bcolors.ENDC)
    os._exit(1)


def show_pass():
    print(bcolors.GREEN + "        ----------------------------               " + bcolors.ENDC)
    print(bcolors.GREEN + "        --                        --       |\\__|\\" + bcolors.ENDC)
    print(bcolors.GREEN + "        --  Congratulations !!    --      / O.O  | " + bcolors.ENDC)
    print(bcolors.GREEN + "        --                        --    /_____   | " + bcolors.ENDC)
    print(bcolors.GREEN + "        --  ADD NOISE PASS!!      --   /^ ^ ^ \\  |" + bcolors.ENDC)
    print(bcolors.GREEN + "        --                        --  |^ ^ ^ ^ |w| " + bcolors.ENDC)
    print(bcolors.GREEN + "        ----------------------------   \\m___m__|_|" + bcolors.ENDC)


if __name__ == '__main__':
    args = parse_args()
    main(args)