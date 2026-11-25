#ifndef _WAVEBANK_H_
#define _WAVEBANK_H_

#include "regaccess.h"
#include "rvlab.h"
#include "waveforms.h"
#include "oscillator.h"

const uint16_t LUT_SIZE = 256 << LUT_CONFIG;

// offset fixed for all LUT sizes! wavebank will always only fit 4 samples
const int TABLE_OFFSET = 2048;

void set_waveform(const int16_t* lut, uint16_t addr_offset) {
  for (int j = 0; j < NO_VOICES; j++) {
    for (int i = 0; i < LUT_SIZE; i++) {
      REG16(SYN_WAVEBANKS_BASE_ADDR + (j * MODULE_SIZE) + (addr_offset*TABLE_OFFSET*2 + i*2)) = lut[i];
    }
  }
}

void set_sine(uint16_t addr_offset){
  set_waveform(sine_lut, addr_offset);
}

void set_triangle(uint16_t addr_offset){
  set_waveform(triangle_lut, addr_offset);
}

void set_square(uint16_t addr_offset){
  for (int j = 0; j < NO_VOICES; j++) {
    for (int i = 0; i < LUT_SIZE/2; i++) {
      REG16(SYN_WAVEBANKS_BASE_ADDR + (j * MODULE_SIZE) + (addr_offset*TABLE_OFFSET*2 + i*2)) = 32767;
    }
    for (int i = LUT_SIZE/2; i < LUT_SIZE; i++) {
      REG16(SYN_WAVEBANKS_BASE_ADDR + (j * MODULE_SIZE) + (addr_offset*TABLE_OFFSET*2 + i*2)) = -32767;
    }
  }
}

inline void set_value(uint16_t address, uint16_t value) {
  REG16(SYN_WAVEBANKS_BASE_ADDR + address) = value;
}

inline uint32_t get_value(uint16_t address) {
  return REG16(SYN_WAVEBANKS_BASE_ADDR + address);
}

#endif

