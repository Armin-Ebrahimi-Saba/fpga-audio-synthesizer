#ifndef _IRQ_CTRL_H_
#define _IRQ_CTRL_H_

#define SET_ALL_EN(enable) \
    (REG32(STUDENT_IRQ_CTRL_ALL_EN(0)) = ((uint32_t)0 | (enable)))

#define SET_MASK(mask) \
    (REG32(STUDENT_IRQ_CTRL_MASK(0)) = (mask))

#define SET_MASK_SET(mask_set) \
    (REG32(STUDENT_IRQ_CTRL_MASK_SET(0)) = (mask_set))

#define SET_MASK_CLR(mask_clr) \
    (REG32(STUDENT_IRQ_CTRL_MASK_CLR(0)) = (mask_clr))

#define SET_STATUS(status) \
    (REG32(STUDENT_IRQ_CTRL_STATUS(0)) = (status))

#define SET_IRQ_NO(irq_no) \
    (REG32(STUDENT_IRQ_CTRL_IRQ_NO(0)) = (irq_no))

#define SET_TEST(test) \
    (REG32(STUDENT_IRQ_CTRL_TEST(0)) = ((uint32_t)0 | (test)))

#define SET_TEST_IRQ(test_irq) \
    (REG32(STUDENT_IRQ_CTRL_TEST_IRQ(0)) = (test_irq))

#define GET_ALL_EN()          ((bool)((REG32(STUDENT_IRQ_CTRL_ALL_EN(0))) & 1))
#define GET_MASK()            ((uint32_t)(REG32(STUDENT_IRQ_CTRL_MASK(0))))
#define GET_MASK_SET()        ((uint32_t)(REG32(STUDENT_IRQ_CTRL_MASK_SET(0))))
#define GET_MASK_CLR()        ((uint32_t)(REG32(STUDENT_IRQ_CTRL_MASK_CLR(0))))
#define GET_STATUS()          ((uint32_t)(REG32(STUDENT_IRQ_CTRL_STATUS(0))))
#define GET_IRQ_NO()          ((uint32_t)(REG32(STUDENT_IRQ_CTRL_IRQ_NO(0))))
#define GET_TEST()            ((bool)((REG32(STUDENT_IRQ_CTRL_TEST(0))) & 1))
#define GET_TEST_IRQ()        ((uint32_t)(REG32(STUDENT_IRQ_CTRL_TEST_IRQ(0))))

#endif // _STUDENT_IRQ_CTRL_H_