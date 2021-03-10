#ifndef WB_ENC_H
#define WB_ENC_H

#include <stdint.h>
#include <stddef.h>

#define WB_ENC_BUFFER_SIZE(len) (((len)&(-16))+16)

int wb_encrypt(const void *input, size_t length, uint8_t *result, size_t *resultLength);

#endif
