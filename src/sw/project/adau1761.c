#include "adau1761.h"

#include <stdio.h>
#include "rvlab.h"
#include "i2c_ctrl.h"

  
void init_adau1761()
{
  int i = -1;
  i = adau1761_write_reg(0x4000, 0b00001110);  //use PLL
  printf("use PLL return: %d\n", i);

  // pll config according to data sheet for mclk=24MHz and sampling rate = 48kHz
  uint8_t pll[] = {0x00, 0x7d, 0x00, 0x0c, 0x23, 0x01};
  i = adau1761_write_pll_reg(pll);
  printf("config PLL return: %d\n", i);

  int locking_bit = 0;
  while(!locking_bit) {
     locking_bit = (adau1761_read_pll_reg()[5] & 2);
     printf("reg value: %x\n", adau1761_read_pll_reg()[5]);
  }

  i = adau1761_write_reg(0x4000, 0b00001111); //activate core clock
  printf("core clock return: %d\n", i);
  // debug: read core clock register value
  int output = 0;
  output = adau1761_read_reg(0x4000);
  printf("Reg value: %08x\n", output);

  printf("bclk to lrclk return: %d\n", i);
  i = adau1761_write_reg(0x4016, 0b01000000); // set bclk cycles per lrclk frame to 48

  // ---- CONFIGURE AUDIO PATH
  // left dac to mx3
  i = adau1761_write_reg(0x401C, 0b00100001);
  printf("enable mixer3: %d\n", i);
   
  // somehow the first config after bclk set always fails, so repeat...
  i = adau1761_write_reg(0x401C, 0b00100001);
  printf("enable mixer3: %d\n", i);

  // right dac to mx4 
  i = adau1761_write_reg(0x401E, 0b01000001);
  printf("enable mixer4: %d\n", i);

  // mx4 to mx6 (line out right)
  i = adau1761_write_reg(0x4021, 0b00001001);
  printf("enable mixer6: %d\n", i);

  // mx3 to mx5 (line out left)
  i = adau1761_write_reg(0x4020, 0b00000011);
  printf("enable mixer5: %d\n", i);

  // set dejitter to 0 during config, re-enable at the end
  i = adau1761_write_reg(0x4036, 0b00000000);
  printf("dejitter to 0 %d\n", i);

  // output volume right
  i = adau1761_write_reg(0x4026, 0b11100110);
  printf("right out volume: %d\n", i);

  // output volume left
  i = adau1761_write_reg(0x4025, 0b11100110);
  printf("left out volume: %d\n", i);

  // mono output mute
  i = adau1761_write_reg(0x4027, 0b00000000);
  printf("mute mono out : %d\n", i);

  // channels enable
  i = adau1761_write_reg(0x4029, 0b00000011);
  printf("enable left and right channel %d\n", i);

  // enable DACs
  i = adau1761_write_reg(0x402A, 0b00000011);
  printf("enable both DACs %d\n", i);

  // DAC to serial output routing
  i = adau1761_write_reg(0x40F2, 0b00000001);
  printf("route DACs to serial out %d\n", i);

  // enable clocks for helper modules in audio chain
  i = adau1761_write_reg(0x40F9, 0b01011111);
  printf("enable clocks %d\n", i);

  // enable clock generator for DACs
  i = adau1761_write_reg(0x40FA, 0b00000001);
  printf("enable clocks 2 %d\n", i);

  // set dejitter control back to 3
  i = adau1761_write_reg(0x4036, 0b00000011);
  printf("dejitter to 3 %d\n", i);
}

