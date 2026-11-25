
def midi_note_to_phase_inc(midi_note, sample_rate=48000):
    freq = 440.0 * 2 ** ((midi_note - 69) / 12)
    phase_inc = int(round((freq * (2**32)) / sample_rate))
    return phase_inc

def generate_phase_inc_lut():
    sample_rate = 48000
    lut = []
    for note in range(128):
        phase_inc = midi_note_to_phase_inc(note, sample_rate)
        lut.append(phase_inc)
    return lut

def print_sv_lut(lut):
    print("logic [31:0] phase_inc_lut [0:127] = '{")
    for i, val in enumerate(lut):
        sep = "," if i < len(lut) -1 else ""
        print(f"    32'd{val}{sep}")
    print("};")

if __name__ == "__main__":
    lut = generate_phase_inc_lut()
    print_sv_lut(lut)
