#ifndef _STUDENT_RLIGHT_H_
#define _STUDENT_RLIGHT_H_


inline void set_pattern(uint8_t pattern) {
    REG32(STUDENT_RLIGHT_PATTERN(0)) = (uint32_t)pattern;
}

typedef enum { 
    STOP = STUDENT_RLIGHT_MODE_MODE_STOP, 
    LEFT = STUDENT_RLIGHT_MODE_MODE_LEFT,
    RIGHT = STUDENT_RLIGHT_MODE_MODE_RIGHT,
    PINGPONG = STUDENT_RLIGHT_MODE_MODE_PINGPONG
} mode_t;

inline void set_mode(mode_t mode) {
    REG32(STUDENT_RLIGHT_MODE(0)) = (uint32_t)mode;
}

inline uint8_t get_pattern() {
    return REG32(STUDENT_RLIGHT_PATTERN(0));
}

#define FREQUENCY_HERTZ 50000000
inline void set_frequency_hz(uint32_t frequency) {
    uint32_t cycles = FREQUENCY_HERTZ / frequency;
    REG32(STUDENT_RLIGHT_N(0)) = cycles;
}

inline uint8_t get_state() {
    return (uint8_t)REG32(STUDENT_RLIGHT_STATE(0));
}

#endif // _STUDENT_RLIGHT_H_
