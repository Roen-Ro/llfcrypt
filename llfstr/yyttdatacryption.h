//
//  yyttdatacryption.h
//  llfstr
//
//  Created by 罗亮富 on 2020/5/28.
//  Copyright © 2020 roen. All rights reserved.
//

#ifndef yyttdatacryption_h
#define yyttdatacryption_h

#include <stdio.h>
extern void encrypt_data(void *buffer, size_t len);
extern void decrypt_data(void *buffer, size_t len);

extern void encrypt_file(const char *srcPath, const char *destPath);
extern void decrypt_file(const char *srcPath, const char *destPath);
#endif /* yyttdatacryption_h */
