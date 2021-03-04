//
// Created by 何思远 on 2018/4/3.
// Copyright (c) 2018 何思远. All rights reserved.
//

#import "ZYCrypto.h"

NSString *zy_crypto_version = @"WBKDZEH4J4";


#ifdef __ZY_ENCRYPTOR

#import "wb_enc.h"

NSData *zy_encrypt(NSData *data) {
    if (data) {
        const uint8_t *bytes = (const uint8_t *) data.bytes;
        int bytesLength = (int) data.length;

        int bufferSize = WB_ENC_BUFFER_SIZE(bytesLength);
        void *buffer = malloc(bufferSize);
        if (buffer) {
            size_t resultSize = 0;
            if (wb_encrypt(bytes, bytesLength, buffer, &resultSize) == 0) {
                return [NSData dataWithBytesNoCopy:buffer length:resultSize freeWhenDone:YES];
            } else {
                free(buffer);
            }
        }
    }
    return nil;
}

NSData *zy_encrypt_to_base64(NSData *data) {
    if (data) {
        NSData *encrypted = zy_encrypt(data);
        if(encrypted) {
            return [encrypted base64EncodedDataWithOptions:0];
        }
    }
    return nil;
}

#endif

#ifdef __ZY_DECRYPTOR

#import "wb_dec.h"

NSData *zy_decrypt(NSData *data) {
    if (data) {
        const uint8_t *bytes = (const uint8_t *) data.bytes;
        size_t bytesLength = data.length;

        size_t bufferSize = WB_DEC_BUFFER_SIZE(bytesLength);
        void *buffer = malloc(bufferSize);
        if (buffer) {
            size_t resultSize = 0;
            if (wb_decrypt(bytes, bytesLength, buffer, &resultSize) == 0) {
                return [NSData dataWithBytesNoCopy:buffer length:resultSize freeWhenDone:YES];
            } else {
                free(buffer);
            }
        }
    }
    return nil;
}

NSData *zy_decrypt_with_base64(NSData *data) {
    if (data) {
        NSData *decode = [[NSData alloc] initWithBase64EncodedData:data options:0];
        return zy_decrypt(decode);
    }
    return nil;
}

#endif
