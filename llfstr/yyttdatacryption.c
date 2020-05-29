//
//  yyttdatacryption.c
//  llfstr
//
//  Created by 罗亮富 on 2020/5/28.
//  Copyright © 2020 roen. All rights reserved.
//

#include "yyttdatacryption.h"


void encrypt_data(void *buffer, size_t len) {
    char *pData = (char *)buffer;
    char v, c1, c2;
    for(size_t i=0; i<len; i++) {
        v = pData[i];
        if(i%2==0) {
            pData[i] = ~v;
        }
        else
        {
            c1 = 0xf0&(~v);//高4位按位取反
            c2 = 0x0f&v;//低4为
            pData[i] = c1+c2;//合并
        }
    }
}


void decrypt_data(void *buffer, size_t len) {
    //反正是取反，再加密一次就是解密
    encrypt_data(buffer,len);
}
