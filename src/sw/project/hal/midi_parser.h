#ifndef _MIDI_PARSER_H_
#define _MIDI_PARSER_H_

#include "regaccess.h"
#include "rvlab.h"

uint8_t get_data1() {
  return (uint8_t) (
    (REG32(SYN_MIDI_PARSER_STATUS_OUTPUT(0))
    >> SYN_MIDI_PARSER_STATUS_OUTPUT_DATA_1_LSB)
    & SYN_MIDI_PARSER_STATUS_OUTPUT_DATA_1_MASK);
}

uint8_t get_data2() {
  return (uint8_t) (
    (REG32(SYN_MIDI_PARSER_STATUS_OUTPUT(0))
    >> SYN_MIDI_PARSER_STATUS_OUTPUT_DATA_2_LSB)
    & SYN_MIDI_PARSER_STATUS_OUTPUT_DATA_2_MASK);
}

uint8_t get_midi_event() {
  return (uint8_t) (
    REG32(SYN_MIDI_PARSER_STATUS_OUTPUT(0))
    & SYN_MIDI_PARSER_STATUS_OUTPUT_EVENT_TYPE_MASK);
}

uint8_t get_midi_channel() {
  return (uint8_t) (
    (REG32(SYN_MIDI_PARSER_STATUS_OUTPUT(0))
    >> SYN_MIDI_PARSER_STATUS_OUTPUT_MIDI_CHANNEL_LSB)
    & SYN_MIDI_PARSER_STATUS_OUTPUT_MIDI_CHANNEL_MASK);
}

#endif // _MIDI_PARSER_H_

