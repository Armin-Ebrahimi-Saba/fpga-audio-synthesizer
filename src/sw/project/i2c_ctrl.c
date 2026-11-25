/*
 * adapted from: https://en.wikipedia.org/wiki/I%C2%B2C
 *
 * Adapted to project specific hardware
 * Added read and write functions specific to ADAU1761 config registers
 */

#include <stdio.h>
#include "rvlab.h"
#include "i2c_ctrl.h"


bool started = false;

static void i2c_delay()
{
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
    while(REG32(RV_TIMER_TIMER_V_LOWER0(0)) < I2C_DELAY_CYCLES);
}

static void i2c_start_timer()
{
    REG32(RV_TIMER_CTRL(0)) = (1<<RV_TIMER_CTRL_ACTIVE0_LSB);
    REG32(RV_TIMER_TIMER_V_LOWER0(0)) = 0;
}

bool i2c_get_sda ()
{
    return REG32(SYN_I2C_CTRL_SDA_HW2REG(0));
}

bool i2c_get_scl ()
{
    return REG32(SYN_I2C_CTRL_SCL_HW2REG(0));
}

void i2c_set_sda (bool sda)
{
    REG32(SYN_I2C_CTRL_SDA_REG2HW(0)) = !sda;
}

void i2c_set_scl (bool scl)
{
    REG32(SYN_I2C_CTRL_SCL_REG2HW(0)) = !scl;
}

void i2c_init_scl ()
{
    for (int i=4; i > 0; i--)
    {
        i2c_delay();
        i2c_set_scl(0);
        i2c_delay();
        i2c_set_scl(1);
    }
}

void i2c_start()
{
    if (started) {
        // if started, do a restart condition
        // set SDA to 1
        i2c_set_sda(1);
        i2c_delay();
        i2c_set_scl(1);

        i2c_start_timer();
        while (i2c_get_scl() == 0) { // Clock stretching
            if (REG32(RV_TIMER_TIMER_V_LOWER0(0)) > CLK_STRETCHING_TIMEOUT) break;
        }

        // Repeated start setup time, minimum 4.7us
        i2c_delay();
    }

    if (i2c_get_sda() == 0) {
        //arbitration_lost();
    }

    // SCL is high, set SDA from 1 to 0.
    i2c_set_sda(0);
    i2c_delay();
    i2c_set_scl(0);
    started = true;
}

void i2c_stop()
{
    // set SDA to 0
    i2c_set_sda(0);
    i2c_delay();
    i2c_set_scl(1);

    // Clock stretching
    i2c_start_timer();
    while (i2c_get_scl() == 0) { // Clock stretching
        if (REG32(RV_TIMER_TIMER_V_LOWER0(0)) > CLK_STRETCHING_TIMEOUT) break;
    }

    // Stop bit setup time, minimum 4us
    i2c_delay();

    // SCL is high, set SDA from 0 to 1
    i2c_set_sda(1);
    i2c_delay();

    if (i2c_get_sda() == 0) {
        //arbitration_lost();
    }

    started = false;
}

// Write a bit to I2C bus
void i2c_write_bit(bool bit)
{
    i2c_set_sda(bit);

    // SDA change propagation delay
    i2c_delay();

    // Set SCL high to indicate a new valid SDA value is available
    i2c_set_scl(1);

    // Wait for SDA value to be read by target, minimum of 4us for standard mode
    i2c_delay();

    i2c_start_timer();
    while (i2c_get_scl() == 0) { // Clock stretching
        if (REG32(RV_TIMER_TIMER_V_LOWER0(0)) > CLK_STRETCHING_TIMEOUT) break;
    }

    // SCL is high, now data is valid
    // If SDA is high, check that nobody else is driving SDA
    if (bit && (i2c_get_sda() == 0)) {
        //arbitration_lost();
    }

    // Clear the SCL to low in preparation for next change
    i2c_set_scl(0);
}

// Read a bit from I2C bus
bool i2c_read_bit()
{
    bool bit;

    // Let the target drive data
    i2c_set_sda(1);

    // Wait for SDA value to be written by target, minimum of 4us for standard mode
    i2c_delay();

    // Set SCL high to indicate a new valid SDA value is available
    i2c_set_scl(1);

    i2c_start_timer();
    while (i2c_get_scl() == 0) { // Clock stretching
        if (REG32(RV_TIMER_TIMER_V_LOWER0(0)) > CLK_STRETCHING_TIMEOUT) break;
    }

    // Wait for SDA value to be written by target, minimum of 4us for standard mode
    i2c_delay();

    // SCL is high, read out bit
    i2c_set_sda(1);
    bit = i2c_get_sda();

    // Set SCL low in preparation for next operation
    i2c_set_scl(0);

    return bit;
}

// Write a byte to I2C bus. Return 0 if ack by the target.
bool i2c_write_byte(bool send_start, bool send_stop, uint8_t byte)
{
    unsigned int bit;
    bool ack = 1;

    if (send_start) {
        i2c_start();
    }

    for (bit = 0; bit < 8; ++bit) {
        i2c_write_bit((byte & 0x80) != 0);
        byte <<= 1;
    }

    ack = i2c_read_bit();

    if (send_stop) {
        i2c_stop();
    }

    return ack;
}

// Read a byte from I2C bus
uint8_t i2c_read_byte(bool send_stop)
{
    uint8_t byte = 0;
    unsigned int bit;

    for (bit = 0; bit < 8; ++bit) {
        byte = (byte << 1) | i2c_read_bit();
    }

    i2c_write_bit(0);

    if (send_stop) {
        i2c_stop();
    }

    return byte;
}

int adau1761_write_reg (unsigned int reg_addr, uint8_t data)
{
    uint8_t adau1761_addr =  0b01110110;
    bool connection_established = 0;

    if (reg_addr == 0) return -1;

    connection_established = !i2c_write_byte(1, 0, adau1761_addr);
    if (!connection_established)
    {
        i2c_stop();
        return -2;
    }
    connection_established = !i2c_write_byte(0, 0, (reg_addr >> 8) & 0xFF);
    if (!connection_established)
    {
        i2c_stop();
        return -3;
    }

    connection_established = !i2c_write_byte(0, 0, reg_addr & 0xFF);
    if (!connection_established)
    {
        i2c_stop();
        return -4;
    }

    connection_established = !i2c_write_byte(0, 1, data);
    if (!connection_established)
    {
        i2c_stop();
        return -5;
    }

    return 0;
}

int adau1761_write_pll_reg (uint8_t data[])
{
    uint8_t adau1761_addr =  0b01110110;
    uint16_t reg_addr = 0x4002;
    bool connection_established = 0;


    connection_established = !i2c_write_byte(1, 0, adau1761_addr);
    if (!connection_established)
    {
        i2c_stop();
        return -1;
    }
    connection_established = !i2c_write_byte(0, 0, (reg_addr >> 8) & 0xFF);
    if (!connection_established)
    {
        i2c_stop();
        return -1;
    }

    connection_established = !i2c_write_byte(0, 0, reg_addr & 0xFF);
    if (!connection_established)
    {
        i2c_stop();
        return -1;
    }

    for (int i = 0; i < 6; i++)
    {
        connection_established = !i2c_write_byte(0, 0, data[i]);
        if (!connection_established)
        {
            i2c_stop();
            return -1;
        }
    }

    i2c_stop();

    return 0;
}

uint8_t adau1761_read_reg (unsigned int reg_addr)
{
    uint8_t adau1761_addr_write =  0b01110110;
    uint8_t adau1761_addr_read =  0b01110111;
    bool connection_established = 0;

    if (reg_addr == 0) return -1;

    connection_established = !i2c_write_byte(1, 0, adau1761_addr_write);
    if (!connection_established) return -1;

    connection_established = !i2c_write_byte(0, 0, (reg_addr >> 8) & 0xFF);
    if (!connection_established) return -1;

    connection_established = !i2c_write_byte(0, 0, reg_addr & 0xFF);
    if (!connection_established) return -1;

    connection_established = !i2c_write_byte(1, 0, adau1761_addr_read);
    if (!connection_established) return -1;

    return i2c_read_byte(1);
}

uint8_t* adau1761_read_pll_reg ()
{
    uint8_t adau1761_addr_write =  0b01110110;
    uint8_t adau1761_addr_read =  0b01110111;
    uint16_t reg_addr = 0x4002;
    static uint8_t data[6];

    i2c_write_byte(1, 0, adau1761_addr_write);

    i2c_write_byte(0, 0, (reg_addr >> 8) & 0xFF);

    i2c_write_byte(0, 0, reg_addr & 0xFF);

    i2c_write_byte(1, 0, adau1761_addr_read);

    for (int i = 0; i < 6; i++)
    {
        data[i] = i2c_read_byte(0);
    }

    i2c_stop();

    return data;
}

