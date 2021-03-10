#ifndef WB_ENC_TABLE_H
#define WB_ENC_TABLE_H

#include <stdint.h>

static const int wb_enc_shift_rows[16] = {0, 1, 2, 3, 5, 6, 7, 4, 10, 11, 8, 9, 15, 12, 13, 14};

extern const uint8_t wb_enc_t1[2][16][256][16];
extern const uint32_t wb_enc_t2[9][16][256];
extern const uint32_t wb_enc_t3[9][16][256];
extern const uint8_t wb_enc_xor[9][8][3][8][256];
extern const uint8_t wb_enc_xor_ex[2][15][32][256];

#endif
