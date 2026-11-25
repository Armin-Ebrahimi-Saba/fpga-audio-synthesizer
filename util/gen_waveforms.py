import numpy as np

# Parameters
amplitude = 32767  # Max for int16

def print_waveform(lut, name):
    print(f"const int16_t {name}_lut[{len(lut)}] = {{")
    for i, val in enumerate(lut, 1):
        print(f"{val:6}, ", end="")
        if i % 8 == 0:
            print()
    print("};\n")

def gen_sine(samples):
    sine_lut = np.round(amplitude * np.sin(2 * np.pi * np.arange(samples) / samples)).astype(np.int16)
    print_waveform(sine_lut, "sine")

def gen_triangle(samples):
    triangle_lut = (2 * amplitude / np.pi) * np.arcsin(np.sin(2 * np.pi * np.arange(samples) / samples))
    triangle_lut = np.round(triangle_lut).astype(np.int16)
    print_waveform(triangle_lut, "triangle")

def gen_waveforms(samples):
    gen_sine(samples)
    gen_triangle(samples)

def print_header():
    print("""#ifndef _WAVEFORMS_H_
#define _WAVEFORMS_H_

#include "rvlab.h"

""")    

print_header()
print("#if LUT_CONFIG == 0")
gen_waveforms(256)
print("#elif LUT_CONFIG == 1")
gen_waveforms(512)
print("#elif LUT_CONFIG == 2")
gen_waveforms(1024)
print("#elif LUT_CONFIG == 3")
gen_waveforms(2048)
print("#endif // LUT_CONFIG")

print("#endif")
