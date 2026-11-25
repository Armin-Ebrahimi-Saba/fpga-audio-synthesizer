#ifndef _PROJECT_I2C_H_
#define _PROJECT_I2C_H_

#include <stdbool.h>

#define I2C_DELAY_CYCLES        100
#define CLK_STRETCHING_TIMEOUT  1000

// initialize SCL with 3 cycles
void i2c_init_scl (void);

// start transmission
void i2c_start(void);

// stop transmission
void i2c_stop(void);

// Write a bit to I2C bus
void i2c_write_bit(bool bit);

// Read a bit from I2C bus
bool i2c_read_bit(void);

// Write a byte to I2C bus. Return 0 if ack by the target.
bool i2c_write_byte(bool send_start, bool send_stop, uint8_t byte);

// Read a byte from I2C bus
uint8_t i2c_read_byte(bool send_stop);

// write single byte config register (0-66)
int adau1761_write_reg (unsigned int reg_num, uint8_t data);

// write pll register
int adau1761_write_pll_reg (uint8_t data[]);

// read single byte config register (0-66)
uint8_t adau1761_read_reg (unsigned int reg_num);

// read pll register
uint8_t* adau1761_read_pll_reg (void);


#endif // _PROJECT_I2C_H_
