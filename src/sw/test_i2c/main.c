#include <stdio.h>
#include "rvlab.h"
#include "i2c_ctrl.h"

int main(void) {
    i2c_init_scl();
    printf("Write to register 0: 0x00000005 ...\n");
    adau1761_write_reg(0, 5);
    printf("Read register 0 ...\n");
    int i = adau1761_read_reg(0);
    printf("reg 0: 0x%08x \n", i);

    printf("Write to register 2: 0x00000093 ...\n");
    adau1761_write_reg(0, 147);
    printf("Read register 2 ...\n");
    i = adau1761_read_reg(0);
    printf("reg 2: 0x%08x \n", i);
}
