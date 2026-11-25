#ifndef _ECHO_H_
#define _ECHO_H_

#include <stdbool.h>
#include "regaccess.h"
#include "rvlab.h"

// enable echo effect
void enable_echo(bool enable)
{
    REG32(SYN_ECHO_ENABLE(0)) = enable;
}

// set how much of the previous sample is fed back to buffer
void set_feedback_gain(uint8_t gain)
{
    REG32(SYN_ECHO_FEEDBACK(0)) = gain & 0x0F;
}

// set mixing ratio between currently played sample and echoed sample
void set_decay_gain(uint8_t gain)
{
    REG32(SYN_ECHO_DECAY(0)) = gain & 0x0F;
}

// set how many samples the echo is delayed (delay time (s) = delay/48000)
void set_delay(uint16_t samples)
{
    REG32(SYN_ECHO_DELAY(0)) = samples;
}

#endif // _ECHO_H_
