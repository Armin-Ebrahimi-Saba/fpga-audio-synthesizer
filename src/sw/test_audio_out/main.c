#include <stdio.h>
#include <stdbool.h>
#include "rvlab.h"

static void delay_cycles(int n_cycles) {
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
    while(REG32(RV_TIMER_TIMER_V_LOWER0(0)) < n_cycles);
}

static void i2c_start_timer()
{
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
}

bool get_ready_strobe ()
{
    return (bool) REG8(SYN_AUDIO_OUT_TEST_AUDIO_IN(0));
}

void set_audio_in (uint16_t samples[], int len)
{
    for (int i=0; i < len; i++)
    {
        REG16(SYN_AUDIO_OUT_TEST_AUDIO_IN(0)) = samples[i];

        i2c_start_timer();

        while (!get_ready_strobe())
        {
            if (REG32(RV_TIMER_TIMER_V_LOWER0(0)) > 5000) break;
        }
        delay_cycles(1000);
    }
}


int main(void)
{
    delay_cycles(5000);
    uint16_t samples[] =   {0b1010101001010101,
                            0b1111111111111111,
                            0b0111000011110000,
                            0b1111111100000001,
                            0b1010010000100101};
    set_audio_in(samples, 5);

    delay_cycles(1000);
}
