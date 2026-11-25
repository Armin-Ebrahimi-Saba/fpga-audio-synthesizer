#include <stdio.h>
#include "rvlab.h"
#include "rlight.h"

static void delay_cycles(int n_cycles) {
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
    while(REG32(RV_TIMER_TIMER_V_LOWER0(0)) < n_cycles);
}

// takes a 4bit pattern and shifts it to the middle
static void update_small_pattern(unsigned char pattern) {
    unsigned char small_pattern = pattern & 0b00001111;
    small_pattern = small_pattern << 2;
    set_pattern(small_pattern);
}

static inline uint8_t left_limit() {
    return get_state() & 0b11000000;
}

static inline uint8_t right_limit() {
    return get_state() & 0b00000011;
}

int main(void) {
    // setup
    set_frequency_hz(1800000); // N = 27
    update_small_pattern(0b1001);

    // algorithm starts HERE
    set_mode(LEFT);
    for (int i = 0; i < 100; i++) {
        while (!left_limit()) {
            // wait
        }
        set_mode(RIGHT);
        while (!right_limit()) {
            // wait
        }
        set_mode(LEFT);
    }
    return 0;
}
