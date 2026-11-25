#ifndef _RVLAB_H
#define _RVLAB_H

#define IRQ_TIMER 7
#define IRQ_EXTERNAL 11

#define DDR3_BASE_ADDR 0x80000000
#define DDR3_SIZE      0x20000000

#include "regaccess.h"

// SYN CONFIGURATION (SW)
#define STUDENT_ADDRESS_SPACE 0x01000000
#define NO_VOICES 4 // min 4, max 32 - also change in student.sv
#define NO_DEVICES (NO_VOICES << 2)
#define MODULE_SIZE (STUDENT_ADDRESS_SPACE / NO_DEVICES)
#define LUT_CONFIG 0 // 0 = arr[256], ..., 3 = arr[2048]

// ---- STUDENT SYN MODULES ----
#define SYN_WAVEBANKS_BASE_ADDR 0x10000000

#include "reggen/syn_oscillator.h"
#define SYN_OSCILLATOR0_BASE_ADDR 0x10400000

#include "reggen/student_irq_ctrl.h"
#define STUDENT_IRQ_CTRL0_BASE_ADDR (0x10800000 + 0 * MODULE_SIZE)

#include "reggen/syn_midi_parser.h"
#define SYN_MIDI_PARSER0_BASE_ADDR (0x10800000 + 1 * MODULE_SIZE)

#include "reggen/syn_audio_out.h"
#define SYN_AUDIO_OUT0_BASE_ADDR (0x10800000 + 2 * MODULE_SIZE)

#include "reggen/syn_i2c_ctrl.h"
#define SYN_I2C_CTRL0_BASE_ADDR (0x10800000 + 3 * MODULE_SIZE)

#include "reggen/syn_echo.h"
#define SYN_ECHO0_BASE_ADDR (0x10800000 + 4 * MODULE_SIZE)

#include "reggen/student_rlight.h"
#define STUDENT_RLIGHT0_BASE_ADDR (0x10800000 + 5 * MODULE_SIZE)
// ---- STUDENT MODULES END ----

#include "reggen/ddr_ctrl.h"
#define DDR_CTRL0_BASE_ADDR 0x1f001000

#include "reggen/regdemo.h"
#define REGDEMO0_BASE_ADDR 0x1f002000

#include "reggen/rv_timer.h"
#define RV_TIMER0_BASE_ADDR 0x1f000000

#include "reggen/student_dma.h"
#define STUDENT_DMA0_BASE_ADDR 0x20000000

#endif // _RVLAB_H
