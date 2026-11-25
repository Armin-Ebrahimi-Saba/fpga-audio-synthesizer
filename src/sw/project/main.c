#include <stdio.h>
#include "rvlab.h"
#include "hal/wavebank.h"
#include "hal/oscillator.h"
#include "hal/midi_parser.h"
#include "hal/irq_ctrl.h"
#include "adau1761.h"
#include "hal/echo.h"

#define DEBUG_MODE 0
#define MAX_IRQ_LINES 1

uint8_t DEBUG_PARSER = 0;

// --------------- setup IRQ handling ---------------------
typedef void (*irq_handler_t)(void);

// Default dummy handler
static void dummy_irq_handler(void) {
  #if DEBUG_MODE
  printf("dummy was called.\n");
  #endif
  // No operation
}

static void midi_parser_debug_msg_handler(void) {
  uint8_t midi_event = get_midi_event();
  uint8_t midi_channel = get_midi_channel();
  uint8_t midi_note = get_data1();
  uint8_t ctrl_channel = midi_note;
  uint8_t midi_velocity = get_data2();
  uint8_t ctrl_value = midi_velocity;
  
  if (midi_event == 1) { // note ON
    printf("MIDI Note ON received: Channel %u, Note %u, Velocity %u\n", midi_channel, midi_note, midi_velocity);
  } 
  else if (midi_event == 0) { // note OFF
    printf("MIDI Note OFF received: Channel %u, Note %u\n", midi_channel, midi_note);
  }
  else if (midi_event == 3) { // MIDI CC
    printf("MIDI CC received: Channel %u, Value %u\n", ctrl_channel, ctrl_value);
    uint8_t adsr_value = ctrl_value >> 3;
    switch (ctrl_channel) {
      case 74: {
        printf("Attack: %u\n", adsr_value);
        break;
      }
      case 75: {
        printf("Decay: %u\n", adsr_value);
        break;
      }
      case 76: {
        printf("Sustain: %u\n", adsr_value);
        break;
      }
      case 77: {
        printf("Release: %u\n", adsr_value);
        break;
      }
      case 78: {
        if (ctrl_value == 0) {
          printf("Echo disabled\n");
        }
        else {
          uint16_t delay = (ctrl_value) * 256;
          printf("Echo enabled with delay %u\n", delay);
        }
        break;
      }
    }
  }
}

static void midi_parser_msg_handler(void) {
  static uint8_t prev_overwritten = 0;
  static uint8_t attack_configs[4] = {0,0,0,0};
  static uint8_t decay_configs[4] = {0,0,0,0};
  static uint8_t sustain_configs[4] = {15,15,15,15};
  static uint8_t release_configs[4] = {0,0,0,0};
  uint8_t midi_event = get_midi_event();
  uint8_t midi_channel = get_midi_channel();
  uint8_t midi_note = get_data1();
  uint8_t ctrl_channel = midi_note;
  uint8_t midi_velocity = get_data2();
  uint8_t ctrl_value = midi_velocity;
  
  if (midi_event == 1) { // note ON
    for (int i = 0; i < NO_VOICES; i++) {
      if (!is_osc_busy(i)) {
        set_sample_config(midi_channel, i);
        set_velocity(midi_velocity, i);
        set_env_config(
          i,
          attack_configs[midi_channel],
          decay_configs[midi_channel],
          sustain_configs[midi_channel],
          release_configs[midi_channel]);
        set_note(midi_note, i);
        return;
      }
    }
    // all busy: default to zero
    set_note(midi_note, prev_overwritten);
    prev_overwritten = (prev_overwritten + 1) & 0b111;
  } 
  else if (midi_event == 0) { // note OFF
    for (int i = 0; i < NO_VOICES; i++) {
      if (get_oscillator_note(i) == midi_note && get_sample_config(i) == midi_channel) {
        stop_osc(i);
        prev_overwritten = 0;
      }
    }
  }
  else if (midi_event == 3) { // MIDI CC
    uint8_t adsr_value = ctrl_value >> 3;
    switch (ctrl_channel) {
      case 74: {
        attack_configs[midi_channel] = adsr_value;
        break;
      }
      case 75: {
        decay_configs[midi_channel] = adsr_value;
        break;
      }
      case 76: {
        sustain_configs[midi_channel] = adsr_value;
        break;
      }
      case 77: {
        release_configs[midi_channel] = adsr_value;
        break;
      }
      case 78: {
        if (ctrl_value == 0) {
          enable_echo(0);
        }
        else {
          enable_echo(1);
          uint16_t delay = (ctrl_value) * 256;
          set_delay(delay);
        }
        break;
      }
    }
  }
  #if DEBUG_MODE
  printf("midi_parser_msg_handler() was called.\n");
  #endif
}

// IRQ handler table
irq_handler_t irq_table[MAX_IRQ_LINES] = { 
  [0 ... MAX_IRQ_LINES-1] = 
  dummy_irq_handler
};

// Read an IRQ handler
irq_handler_t student_irq_ctrl_get(uint32_t irq_no) {
  #if DEBUG_MODE
  printf("student_irq_ctrl_get(%u) was called.\n", irq_no);
  #endif
  return irq_table[irq_no];
}

// Set an IRQ handler
void student_irq_ctrl_set(uint32_t irq_no, irq_handler_t handler) {
  if (handler) {
    #if DEBUG_MODE
    printf("student_irq_ctrl_set() was called.\n");
    #endif
    irq_table[irq_no] = handler;
  }
}

// The IRQ dispatcher
void student_irq_ctrl_top_handler(void) {
  #if DEBUG_MODE
  fputs("I am external interrupt\n", stdout);
  #endif
  uint32_t irq_no = GET_IRQ_NO();
  while (irq_no != MAX_IRQ_LINES) {
    student_irq_ctrl_get(irq_no)();
    irq_no = GET_IRQ_NO();
  }
}

void enable_interrupts() {
  if (DEBUG_PARSER) {
    student_irq_ctrl_set(0, midi_parser_debug_msg_handler);
  } else {
    student_irq_ctrl_set(0, midi_parser_msg_handler);
  }
  SET_ALL_EN(1);
  SET_MASK(0xFFFFFFFF);
  irq_enable(1<<IRQ_EXTERNAL);
}

  
// ------------ testing & helper functions ----------------------
static void delay_cycles(int n_cycles) {
  REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
  REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
  while(REG32(RV_TIMER_TIMER_V_LOWER0(0)) < n_cycles);
}

void enable_test_mode() {
  set_test_cycles(7);
  set_test_mode(TEST_CYCLES);
}

void play_max_voices() {
  for (int i = 0; i < NO_VOICES; i++) {
    set_note(10 + (i*2), i);
  }
}

void test_wavebank_rw() {
  int test1, test2, test3, test4, test5;
  set_value(0x0000, 5);
  set_value(0x0002, 3);
  test1 = get_value(0x0000);
  test2 = get_value(0x0002);
  test3 = get_value(0x0004);
  test4 = get_value(0x0FFC);
  test5 = get_value(0x1000);
  printf("Result test1: %i, test2: %i, test3: %i, test4: %i, test5: %i \n", test1, test2, test3, test4, test5);
}

void test_oscillator_control() {
  // full polyphony test:
  play_max_voices();
  // optional - enable midi ctrl to test overwriting of active voices
  enable_interrupts();
  delay_cycles(100000);
}

void test_env_shaper() {
  // scenario 1: sustain at max amplitude
  set_env_config(0, 0, 0, 15, 0);
  set_note(67, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(1000);
  // scenario 2: sustain at medium amplitude
  set_env_config(0, 0, 0, 7, 0);
  set_note(67, 0);
  delay_cycles(2000);
  stop_osc(0);
  delay_cycles(1000);
  // scenario 2: sustain at 0 (one-shot mode)
  set_env_config(0, 0, 0, 0, 0);
  set_note(67, 0);
  delay_cycles(2000);
  stop_osc(0);
  delay_cycles(1000);
  // scenario 3: release during attack
  set_env_config(0, 0, 0, 15, 0);
  set_note(67, 0);
  delay_cycles(500);
  stop_osc(0);
  delay_cycles(1000);
  // scenario 4: release during short decay (should FINISH decay stage)
  set_env_config(0, 0, 0, 7, 1);
  set_note(67, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(4000);
  // scenario 5: release during long decay (should IMMEDIATELY go to release)
  set_env_config(0, 0, 1, 7, 0);
  set_note(67, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(3000);
  // scenario 6: another trigger during decay
  set_env_config(0, 0, 0, 7, 0);
  set_note(67, 0);
  delay_cycles(1000);
  set_note(68, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(1000);
  // scenario 7: another trigger during sustain
  set_env_config(0, 0, 0, 7, 0);
  set_note(67, 0);
  delay_cycles(2000);
  set_note(68, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(1000);
  // scenario 8: another trigger during release
  set_env_config(0, 0, 0, 15, 0);
  set_note(67, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(500);
  set_note(68, 0);
  delay_cycles(1000);
  stop_osc(0);
  delay_cycles(1000);
}

void test_velocity() {
  set_velocity(127, 0);
  set_note(67, 0);
  delay_cycles(200000);
  
  set_velocity(63, 0);
  delay_cycles(200000);
  
  set_velocity(0, 0);
  delay_cycles(200000);
}

void test_parser() {
  DEBUG_PARSER = 1;
  enable_interrupts();
  while (1) {
  }
}

void echo_config(uint8_t feedback, uint8_t decay) {
  set_feedback_gain(feedback);
  set_decay_gain(decay);
}

void configure_echo() {
  printf("configure echo\n");
  echo_config(15, 15);
  printf("set echo delay\n");
  set_delay(18000);
  printf("enable echo\n");
  enable_echo(1);
}

static void play_note(uint8_t note, uint32_t duration, uint8_t oscillator) {
  set_note(note, oscillator);
  delay_cycles(duration);
  stop_osc(oscillator);
}

void play_echo_test() {
  set_note(67, 0);
  delay_cycles(200000);
  set_note(64, 1);
  delay_cycles(300000);
  set_note(69, 1);
  delay_cycles(300000);
  stop_osc(2);
  stop_osc(1);
  stop_osc(0);
  delay_cycles(200000);
  play_note(69, 100000, 1);
  play_note(67, 100000, 1);
  play_note(69, 100000, 1);
  delay_cycles(500000);
}


// ------------------- synthesizer setup ----------------
void default_syn_config() {
  // sets lutsize & global default wavebank selection
  set_sample_config_global(0);

  // set wavebank to midi channel-assignment
  set_sine(0);
  set_square(1);
  set_triangle(2);
  set_sine(3);

  // env-shaper config
  set_env_config_global(0b0000, 0b0000, 0b1111, 0b0000);
  
  echo_config(15, 15);
}

void fpga_software() {
  init_adau1761();
  default_syn_config();
  enable_interrupts();
  while (1) {
  }
}

void setup_local_test() {
  printf("setting default config\n");
  default_syn_config();
  printf("enabling test mode\n");
  enable_test_mode();
}

int main(void) {
  //fpga_software();
  //setup_local_test();
  return 0;
}
