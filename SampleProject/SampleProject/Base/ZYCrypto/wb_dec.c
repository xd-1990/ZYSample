#include "wb_dec.h"
#include <string.h>
#include "wb_state.h"
#include "wb_dec_tbl.h"


int wb_decrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength) {
    if ((length & 0xF) == 0x0) {
        int blocks = (int) (length >> 4);
        uint8_t state[16];
        for (int block = 0; block < blocks; block++) {
            wb_init_state(input, state, block);
            wb_transpose(state);
            wb_state(state, wb_dec_shift_rows, wb_dec_t1, wb_dec_t2, wb_dec_t3, wb_dec_xor, wb_dec_xor_ex);
            memcpy(result + block * 16, state, 16);
        }
        uint8_t padding = result[length - 1];
        if (padding > 0 && padding <= 16) {
            size_t len = length - padding;
            for (int i = 0; i < padding; i++) {
                if (result[len + i] != padding) {
                    return -1;
                }
            }
            *resultLength = len;
            return 0;
        }
    }
    return -1;
}

