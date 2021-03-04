#ifndef WB_DEC_H
#define WB_DEC_H

#include <stdint.h>
#include <stddef.h>

#define WB_DEC_BUFFER_SIZE(len) (len)

int wb_decrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength);

#endif