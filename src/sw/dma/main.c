#include <stdlib.h>
#include <stdio.h>
#include "rvlab.h"
#include "memset.h"
#include "memcpy.h"
#include "init.h"

// Test memset
// -----------

static int test_memset_singlecase(uint32_t length_words, uint32_t pattern, void (*func_memset)(void *, uint32_t, uint32_t), int print_cycles, void* target_buf) {
    int errcnt = 0;
    int mcycle_start, mcycle_end;
    
    unsigned int *buf = (unsigned int*)target_buf;
    for (int i = 0; i < 258; i++) {
        buf[i] = 0;
    }
    buf[0] = 0xcafe;
    buf[257] = 0xbeef;
    
    mcycle_start = read_csr("mcycle");
    (*func_memset)(buf+1, pattern, length_words*sizeof(int));
    mcycle_end = read_csr("mcycle");

    if(print_cycles) {
        printf("cycles count for %i words: %i\n", length_words, mcycle_end - mcycle_start);
    }

    for (int i = 0; i < 258; i++) {
        int val_expected;
        if(i==0) {
            val_expected = 0xcafe;
        } else if (i<(1+length_words)) {
            val_expected = pattern;
        } else if (i<257) {
            val_expected = 0;
        } else { // i == 63
            val_expected = 0xbeef;
        }
        int val_read = buf[i];
        //printf("%x ", buf[i]);
        if(val_read != val_expected) {
            printf("Error: buf[%i] was %i != %i\n", i, val_read, val_expected);
            errcnt++;
        }
    }
    return errcnt;
}

int test_memset(void (*func_memset)(void *, uint32_t, uint32_t)) {
    int errcnt = 0;
    // sram
    unsigned int buf[258];
    errcnt += test_memset_singlecase(256, 0x55, func_memset, 1, buf);

    // ddr3
    unsigned int* ddr_buf = malloc(258*sizeof(int));
    errcnt += test_memset_singlecase(256, 0xffffffff, func_memset, 1, ddr_buf);
    free(ddr_buf);

    return errcnt;
}

// Test memcpy
// -----------

static int test_memcpy_singlecase(uint32_t length_words, void *src_buf, void (*func_memcpy)(void *, void *, uint32_t), int print_cycles, void* target_buf) {
    int errcnt = 0;
    int mcycle_start, mcycle_end;

    unsigned int *buf = (unsigned int*)target_buf; 
    for (int i = 0; i < 258; i++) {
            buf[i] = 0;
    }
    buf[0] = 0xcafe;
    buf[257] = 0xbeef;
    
    mcycle_start = read_csr("mcycle");
    (*func_memcpy)(buf+1, src_buf, length_words*sizeof(int));
    mcycle_end = read_csr("mcycle");
    
    if(print_cycles) {
        printf("cycles count for %i words: %i\n", length_words, mcycle_end - mcycle_start);
    }

    for (int i = 0; i < 258; i++) {
        int val_expected;
        if(i==0) {
            val_expected = 0xcafe;
        } else if (i<(1+length_words)) {
            val_expected = ((uint32_t *)src_buf)[i-1];
        } else if (i<257) {
            val_expected = 0;
        } else { // i == 257
            val_expected = 0xbeef;
        }
        int val_read = buf[i];
        //printf("%x ", buf[i]);
        if(val_read != val_expected) {
            printf("Error: buf[%i] was %i != %i\n", i, val_read, val_expected);
            errcnt++;
        }
    }
    return errcnt;
}

int test_memcpy(void (*func_memcpy)(void *, void *, uint32_t)) {
    int errcnt = 0;

    uint32_t src_buf[258];
    for(int i=0;i<258;i++) {
        src_buf[i] = 0x11223300 + i;
    }
    // sram to sram
    unsigned int buf[258];
    errcnt += test_memcpy_singlecase(256, src_buf, func_memcpy, 1, buf);

    // sram to dram
    unsigned int* ddr_buf_target = malloc(258*sizeof(int));
    errcnt += test_memcpy_singlecase(256, src_buf, func_memcpy, 1, ddr_buf_target);
    free(ddr_buf_target);

    // dram to sram
    unsigned int* ddr_buf_source = malloc(258*sizeof(int));
    for(int i=0;i<258;i++) {
        ddr_buf_source[i] = 0x11223300 + i;
    }
    uint32_t trg_buf[258];
    errcnt += test_memcpy_singlecase(256, ddr_buf_source, func_memcpy, 1, trg_buf);
    free(ddr_buf_source);

    return errcnt;
}

// Main
// ----

int main(void) {
    ddr_init();
    add_malloc_block((void*)0x80000000, 0x00000400);
    int res, retval=0;

    printf("test memset_soft:\n");    
    res = test_memset(memset_soft);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    printf("test memset_dma:\n");
    res = test_memset(memset_dma);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");
    
    printf("test memcpy_soft:\n");
    res = test_memcpy(memcpy_soft);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    printf("test memcpy_dma:\n");
    res = test_memcpy(memcpy_dma);
    retval += res;
    printf("--> %s\n", res?"fail":"pass");

    return retval;
}