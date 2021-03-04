#include "wb_enc.h"
#include <string.h>
#include "wb_state.h"
#include "wb_enc_tbl.h"


int wb_encrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength) {
    size_t bufferSize = WB_ENC_BUFFER_SIZE(length);
    size_t padding = bufferSize - length;
    *resultLength = bufferSize;
    int blocks = (int) (length >> 4);
    uint8_t state[16];
    for (int block = 0; block < blocks; block++) {
        wb_init_state(input, state, block);
        wb_transpose(state);
        wb_state(state, wb_enc_shift_rows, wb_enc_t1, wb_enc_t2, wb_enc_t3, wb_enc_xor, wb_enc_xor_ex);
        memcpy(result + block * 16, state, 16);
    }
    size_t remain = length % 16;
    if (remain > 0) {
        memcpy(state, input + 16 * blocks, remain);
    }
    for (int i = 0; i < padding; i++) {
        state[remain + i] = (uint8_t) padding;
    }
    wb_transpose(state);
    wb_state(state, wb_enc_shift_rows, wb_enc_t1, wb_enc_t2, wb_enc_t3, wb_enc_xor, wb_enc_xor_ex);
    memcpy(result + blocks * 16, state, 16);
    return 0;
}
