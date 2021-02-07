_all__ = ['print_palette']

bits_per_color = 4
nsteps = 2**bits_per_color
stepsize = (256//nsteps) + 1

def to_fpga_bits(color_8):
    index = color_8 // stepsize
    rem = color_8 & stepsize
    if (rem >= (stepsize / 2)):
        index += 1
    return index

def to_fpga_tuple(color_tuple):
    return tuple(to_fpga_bits(channel) for channel in color_tuple)

def to_fpga_word(fpga_tuple):
    return (fpga_tuple[0] << (2*bits_per_color)) | (fpga_tuple[1] << bits_per_color) | fpga_tuple[2]

def print_palette(colors):
    for color in colors:
        print("{:x}".format(to_fpga_word(to_fpga_tuple(color))).zfill(3))
