# Python script to generate inverse duration LUT in Q2.30 format (32-bit unsigned)

CLOCK_FREQ_HZ = 48_000_000
T_SYS_MS = 1000 / CLOCK_FREQ_HZ  # 1 clock period in ms

# Predefined config times in milliseconds
config_times_ms = [
    2, 8, 16, 24, 38, 56, 68, 80,
    100, 250, 500, 800, 1000, 3000, 5000, 8000
]

def to_q30(value):
    """Convert float to unsigned Q2.30 fixed point integer"""
    return int(round(value * (1 << 30)))

def generate_inv_time_lut():
    print(f"// LUT holding inverse time duration for a sys-clock of {CLOCK_FREQ_HZ} hz")
    print("localparam logic [31:0] inv_duration_lut [0:15] = '{")
    for i, t_ms in enumerate(config_times_ms):
        inv = T_SYS_MS / t_ms
        q30_val = to_q30(inv)
        comma = "," if i < len(config_times_ms) - 1 else ""
        print(f"    32'd{q30_val}{comma} // {t_ms} ms -> inv={inv:.9e}")
    print("};")

def generate_sustain_lut(max_value: int):
    print(f"// 4-bit to 32-bit linear LUT mapping up to 0x{max_value:X}")
    print("localparam logic [31:0] linear_4bit_to_max_lut [0:15] = '{")
    for i in range(16):
        mapped = (i * max_value) // 15  # Integer division ensures clean SV output
        comma = "," if i < 15 else ""
        print(f"    32'h{mapped:08X}{comma} // {i}")
    print("};")

generate_inv_time_lut()
generate_sustain_lut(0x7FFFFFFF)
