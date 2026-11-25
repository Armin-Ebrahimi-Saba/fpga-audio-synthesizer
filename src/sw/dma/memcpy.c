#include "rvlab.h"
#include "dma.h"

void memcpy_soft(void *dest, void *src, uint32_t length) {
    int* dest_i = (int*) dest;
    int* src_i = (int*) src;
    for (int i = 0; i < (length/sizeof(int)); i++) {
        dest_i[i] = src_i[i];
    }
}

void memcpy_dma(void *dest, void *src, uint32_t length) {
    volatile dma_descriptor_t d;
    
    d.operation = DMA_OP_MEMCPY;
    d.dst_adr   = (uint32_t) dest;
    d.src_adr   = (uint32_t) src;
    d.length    = length;
    
    dma_write_desc(&d);
    dma_wait(); 
}