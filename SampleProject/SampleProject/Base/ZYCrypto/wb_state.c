#include "wb_state.h"

inline static void wb_xor_state(const uint8_t xt[32][256], uint8_t a[16], const uint8_t b[16]) {
    for (int i = 0; i < 16; i++) {
        a[i] = (xt[2 * i][((a[i] & 0xF) << 4) | (b[i] & 0xF)]) |
               (xt[2 * i + 1][(((a[i] >> 4) & 0xF) << 4) | ((b[i] >> 4) & 0xF)] << 4);
    }
}

inline static void wb_xor_states(const uint8_t xorts[15][32][256], uint8_t states[16][16]) {
    int offset = 0;
    for (int i = 0; i < 4; i++) {
        int ops = 1 << (3 - i);
        int gap = 1 << i;
        for (int j = 0; j < ops; j++) {
            int fst = 2 * gap * j;
            wb_xor_state(xorts[offset + j], states[fst], states[fst + gap]);
        }
        offset += ops;
    }
}

inline static uint32_t wb_xor64_32(const uint8_t xtbl[8][256], uint32_t a, uint32_t b) {
    uint32_t result = 0, tmp;
    for (int i = 0; i < 8; i++) {
        tmp = (((a >> (i * 4)) & 0xF) << 4) | ((b >> (i * 4)) & 0xF);
        result |= (xtbl[i][tmp] << (i * 4));
    }
    return result;
}


inline static uint32_t wb_xor128_32(const uint8_t xt[3][8][256], uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3) {
    uint32_t lx = wb_xor64_32(xt[0], a0, a1);
    uint32_t rx = wb_xor64_32(xt[1], a2, a3);
    uint32_t cx = wb_xor64_32(xt[2], lx, rx);
    return cx;
}

inline static void wb_int_to_uint8_t(uint32_t a, uint8_t b[4]) {
    b[0] = (uint8_t) (a & 0xFF);
    b[1] = (uint8_t) ((a >> 8) & 0xFF);
    b[2] = (uint8_t) ((a >> 16) & 0xFF);
    b[3] = (uint8_t) ((a >> 24) & 0xFF);
}

inline static void wb_set_column(uint8_t *state, uint32_t xor, uint32_t col) {
    for (int i = 0; i < 4; i++) {
        state[i * 4 + col] = (uint8_t) ((xor >> (i * 8)) & 0xff);
    }
}


void wb_state(uint8_t state[16], const int wb_shift_rows[16], const uint8_t wb_t1[2][16][256][16],
              const uint32_t wb_t2[9][16][256], const uint32_t wb_t3[9][16][256], const uint8_t wb_xor[9][8][3][8][256],
              const uint8_t wb_xor_ex[2][15][32][256]) {
    uint8_t states[16][16];
    const uint8_t *st;
    for (int i = 0; i < 16; i++) {
        st = wb_t1[0][i][state[i]];
        memcpy(states[i], st, 16);
    }
    wb_xor_states(wb_xor_ex[0], states);
    memcpy(state, states[0], 16);

    for (int r = 0; r < 9; r++) {
        uint32_t ires[16];
        for (int i = 0; i < 16; i++) {
            ires[i] = wb_t2[r][i][state[wb_shift_rows[i]]];
        }
        for (uint32_t i = 0; i < 4; i++) {
            ires[i] = wb_xor128_32(wb_xor[r][i * 2], ires[i], ires[i + 4], ires[i + 8], ires[i + 12]);
            uint8_t cires[4];
            wb_int_to_uint8_t(ires[i], cires);
            ires[i + 0] = wb_t3[r][i + 0][cires[0]];
            ires[i + 4] = wb_t3[r][i + 4][cires[1]];
            ires[i + 8] = wb_t3[r][i + 8][cires[2]];
            ires[i + 12] = wb_t3[r][i + 12][cires[3]];

            ires[i] = wb_xor128_32(wb_xor[r][i * 2 + 1], ires[i], ires[i + 4], ires[i + 8], ires[i + 12]);
            wb_set_column(state, ires[i], i);
        }
    }

    for (int i = 0; i < 16; i++) {
        st = wb_t1[1][i][state[wb_shift_rows[i]]];
        memcpy(states[i], st, 16);
    }

    wb_xor_states(wb_xor_ex[1], states);
    memcpy(state, states[0], 16);
}