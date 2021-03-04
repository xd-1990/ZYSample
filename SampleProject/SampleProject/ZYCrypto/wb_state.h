#ifndef WB_COMMON_H
#define WB_COMMON_H

#include <stdint.h>
#include <string.h>

inline static void wb_init_state(const uint8_t *input, uint8_t state[16], int blockIndex) {
    memcpy(state, input + blockIndex * 16, 16);
}

inline static void wb_transpose(uint8_t state[16]) {
    uint8_t tmp[16];
    int i, j;
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4; j++) {
            tmp[i * 4 + j] = state[j * 4 + i];
        }
    }
    memcpy(state, tmp, 16);
}

void wb_state(uint8_t state[16], const int wb_shift_rows[16], const uint8_t wb_t1[2][16][256][16],
              const uint32_t wb_t2[9][16][256], const uint32_t wb_t3[9][16][256], const uint8_t wb_xor[9][8][3][8][256],
              const uint8_t wb_xor_ex[2][15][32][256]);


#endif //WB_COMMON_H
