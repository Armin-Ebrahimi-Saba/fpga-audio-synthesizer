#include <stdio.h>
#include "rvlab.h"
#include "../rlight/rlight.h"
#include "irq_ctrl.h"
#define DEBUG_MODE 0
#define MAX_IRQ_LINES 32

typedef void (*irq_handler_t)(void);


static void delay_cycles(int n_cycles) {
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
    while(REG32(RV_TIMER_TIMER_V_LOWER0(0)) < n_cycles);
}


void irq_handler(void) {
    fputs("I am timer interrupt\n", stdout);
    REG32(STUDENT_IRQ_CTRL_TEST_IRQ(0)) = 0x00000000;
}

static void run_timer_irq(int n_cycles) {
        REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
        REG32(RV_TIMER_TIMER_V_UPPER0(0)) = 0;
        REG32(RV_TIMER_COMPARE_LOWER0_0(0)) = n_cycles;
        REG32(RV_TIMER_COMPARE_UPPER0_0(0)) = 0;
        REG32(RV_TIMER_CTRL(0)) = (1 << RV_TIMER_CTRL_ACTIVE0_LSB);
}



// Default dummy handler
static void dummy_irq_handler(void) {
    #if DEBUG_MODE
        printf("dummy was called.\n");
    #endif
    // No operation
}

static void rlight_irq_left_handler(void) {
    set_mode(RIGHT);
    #if DEBUG_MODE
        printf("rlight_irq_left_handler() was called.\n");
    #endif
}

static void rlight_irq_right_handler(void) {
    set_mode(LEFT);
    #if DEBUG_MODE
        printf("rlight_irq_right_handler() was called.\n");
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
        printf("student_irq_ctrl_get() was called.\n");
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

int main(void) {
    set_mode(STOP);
    set_pattern(0b00011000);
    set_frequency_hz(300000);

    student_irq_ctrl_set(30, rlight_irq_right_handler);
    student_irq_ctrl_set(31, rlight_irq_left_handler);
    SET_ALL_EN(1);
    SET_MASK(0xFFFFFFFF);
    
    irq_enable((1<<IRQ_TIMER) | (1<<IRQ_EXTERNAL));
    set_mode(LEFT);
    delay_cycles(5000);
    return 0;
}
