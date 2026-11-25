import numpy as np
import wave

def load_pcm_from_csv(filename):
    """
    Reads a comma-separated text file of 16-bit signed PCM values
    and returns a NumPy array of dtype int16.
    """
    with open(filename, 'r') as f:
        content = f.read()
    
    # Split by comma, strip whitespace, convert to int
    samples = [int(s.strip()) for s in content.split(',') if s.strip()]
    
    # Convert to NumPy array with int16 type
    pcm_array = np.array(samples, dtype=np.int16)
    
    return pcm_array
# PCM data
pcm_data = load_pcm_from_csv("./tmp/samples_out")

# Save to WAV
with wave.open("./tmp/output.wav", "w") as wav_file:
    wav_file.setnchannels(1)         # Mono
    wav_file.setsampwidth(2)         # 16-bit
    wav_file.setframerate(48000)     # Sample rate
    wav_file.writeframes(pcm_data.tobytes())

