//
// Created by 何思远 on 2018/4/3.
// Copyright (c) 2018 何思远. All rights reserved.
//

#import <Foundation/Foundation.h>

#define __ZY_DECRYPTOR
#define __ZY_ENCRYPTOR


extern NSString *__nullable zy_crypto_version;

#ifdef __ZY_ENCRYPTOR
NSData *__nullable zy_encrypt(NSData *__nullable data);
NSData *__nullable zy_encrypt_to_base64(NSData *__nullable data);
#endif

#ifdef __ZY_DECRYPTOR
NSData *__nullable zy_decrypt(NSData *__nullable data);
NSData *__nullable zy_decrypt_with_base64(NSData *__nullable data);
#endif
