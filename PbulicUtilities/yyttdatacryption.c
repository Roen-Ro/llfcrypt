//
//  yyttdatacryption.c
//  llfstr
//
//  Created by 罗亮富 on 2020/5/28.
//  Copyright © 2020 roen. All rights reserved.
//

#include "yyttdatacryption.h"
#include <sys/stat.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

void encrypt_data(void *buffer, size_t len) {
    char *pData = (char *)buffer;
    char v, c1, c2;
    bool even = true;
    for(size_t i=0; i<len; i++) {
        v = pData[i];
        if(even)//偶数位
        {
            c1 = 0x69&(~v);//取反位    01101001
            c2 = 0x96&v;//保留原始值位  10010110
        }
        else //奇数位
        {
            c1 = 0xf0&(~v);//取反位 高4位
            c2 = 0x0f&v;//保留位   低4位
        }
        
        even = !even;
        pData[i] = c1+c2;//合并
    }
}


void decrypt_data(void *buffer, size_t len) {
    //反正是取反，再加密一次就是解密
    encrypt_data(buffer,len);
}

#define BUFFER_PAGE_SIZE 1024*1024*40 //每次读取20M


size_t get_file_size(const char* filename)
{
    struct stat statbuf;
    stat(filename,&statbuf);
    size_t size = statbuf.st_size;
 
    return size;
}

int is_path_directory(const char* filename) {
    struct stat statbuf;
    stat(filename,&statbuf);
    return S_ISDIR(statbuf.st_mode);
}

void crypt_file(const char *srcPath, const char *destPath, void (*func)(void *, size_t)) {
    
    if(is_path_directory(srcPath)) {
        printf("file %s is a directory\n",srcPath);
        return;
    }
    
    FILE *f_src = fopen(srcPath, "r");
    FILE *f_dest = fopen(destPath, "w");
    size_t b_len = BUFFER_PAGE_SIZE;
    void *buffer = calloc(b_len, 1);
    size_t r_len;
    
    do {
        
        r_len = fread(buffer, 1, b_len, f_src);
        if(r_len == 0)
            break;
        
        func(buffer, r_len);
        fwrite(buffer, 1, r_len, f_dest);
        
    } while (r_len == b_len);
    
    fflush(f_dest);
    
    printf(">> %s -> %s\n",srcPath,destPath);
    fclose(f_src);
    fclose(f_dest);
    free(buffer);
}

void encrypt_file(const char *srcPath, const char *destPath) {
    crypt_file(srcPath, destPath, encrypt_data);
}

void decrypt_file(const char *srcPath, const char *destPath) {
    crypt_file(srcPath, destPath, decrypt_data);
}
