#ifndef _OSCILLATOR_H_
#define _OSCILLATOR_H_

#include "regaccess.h"
#include "rvlab.h"
#include "waveforms.h"

typedef enum
{
  DEFAULT = 0,
  TEST_CYCLES = 1,
} test_mode_t;

void set_test_mode(test_mode_t mode)
{
  for (int i = 0; i < NO_VOICES; i++) {
    REG32(SYN_OSCILLATOR_TEST(0) + i * MODULE_SIZE) = mode;
  }
}

void set_test_cycles(uint16_t cycles)
{
  for (int i = 0; i < NO_VOICES; i++) {
    REG32(SYN_OSCILLATOR_TEST_N_READYBURST(0) + i * MODULE_SIZE) = cycles;
  }
}

void set_note(uint8_t note, uint8_t oscillator)
{
  REG32(SYN_OSCILLATOR_NOTE(0) + oscillator * MODULE_SIZE) = note;
}


void set_velocity(uint8_t velocity, uint8_t oscillator)
{
  REG32(SYN_OSCILLATOR_VELOCITY(0) + oscillator * MODULE_SIZE) = velocity;
}

void stop_osc(uint8_t oscillator)
{
  REG32(SYN_OSCILLATOR_STOP(0) + oscillator * MODULE_SIZE) = 1;
}

void set_env_config(uint8_t oscillator, uint8_t attack, uint8_t decay, uint8_t sustain, uint8_t release)
{
  uint32_t config = 0;
  config = (uint32_t)((attack & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_ATTACK_VALUE_LSB |
                      (decay & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_DECAY_VALUE_LSB |
                      (sustain & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_SUSTAIN_VALUE_LSB |
                      (release & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_RELEASE_VALUE_LSB);
  REG32(SYN_OSCILLATOR_ENV_CONFIG(0) + oscillator * MODULE_SIZE) = config;
}

void set_env_config_global(uint8_t attack, uint8_t decay, uint8_t sustain, uint8_t release)
{
  uint32_t config = 0;
  config = (uint32_t)((attack & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_ATTACK_VALUE_LSB |
                      (decay & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_DECAY_VALUE_LSB |
                      (sustain & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_SUSTAIN_VALUE_LSB |
                      (release & 0x0F) << SYN_OSCILLATOR_ENV_CONFIG_RELEASE_VALUE_LSB);
  for (int i = 0; i < NO_VOICES; i++) {
    REG32(SYN_OSCILLATOR_ENV_CONFIG(0) + i * MODULE_SIZE) = config;
  }
}

uint8_t get_oscillator_note(uint8_t oscillator) {
  return (uint8_t) REG32(SYN_OSCILLATOR_NOTE(0) + oscillator * MODULE_SIZE);
}

uint8_t is_osc_busy(uint8_t oscillator)
{
  return (uint8_t) REG32(SYN_OSCILLATOR_STATUS_STATE(0) + oscillator * MODULE_SIZE);
}

void set_sample_config_global(uint8_t sample_index)
{
  for (int i = 0; i < NO_VOICES; i++) {
    REG32(SYN_OSCILLATOR_SAMPLE(0) + i * MODULE_SIZE) =
      (LUT_CONFIG << SYN_OSCILLATOR_SAMPLE_SAMPLE_SIZE_LSB) |
      sample_index;
  }
}

void set_sample_config(uint8_t sample_index, uint8_t oscillator)
{
  REG32(SYN_OSCILLATOR_SAMPLE(0) + oscillator * MODULE_SIZE) =
    (LUT_CONFIG << SYN_OSCILLATOR_SAMPLE_SAMPLE_SIZE_LSB) |
    sample_index;
}

uint8_t get_sample_config(uint8_t oscillator)
{
  return (uint8_t) (
    REG32(SYN_OSCILLATOR_SAMPLE(0) + oscillator * MODULE_SIZE)
    & SYN_OSCILLATOR_SAMPLE_SAMPLE_INDEX_MASK);
}

#endif // _OSCILLATOR_H_
