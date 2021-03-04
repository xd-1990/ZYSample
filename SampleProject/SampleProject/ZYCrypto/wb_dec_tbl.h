#ifndef WB_DEC_TABLE_H
#define WB_DEC_TABLE_H

#include <stdint.h>

static const int wb_dec_shift_rows[16] = {0, 1, 2, 3, 7, 4, 5, 6, 10, 11, 8, 9, 13, 14, 15, 12};

extern const uint8_t wb_dec_t1[2][16][256][16];
extern const uint32_t wb_dec_t2[9][16][256];
extern const uint32_t wb_dec_t3[9][16][256];
extern const uint8_t wb_dec_xor[9][8][3][8][256];
extern const uint8_t wb_dec_xor_ex[2][15][32][256];

#endif
