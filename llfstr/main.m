//
//  main.m
//  llfcrypt
//
//  Created by 罗亮富 on 2020/5/28.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+uti.h"
#import "yyttdatacryption.h"


extern NSString * resolvePath(NSString *path);
extern void createDirectoryIfNotExisted(NSURL *directory);
extern bool cryptionAtPath(const char *cPath, char *subDir, void (*f)(void *, size_t));

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
#if debug
        for(int i=0;;i++) {
            const char *s = argv[i];
            if(s == nil || strlen(s)==0)
                break;
            else
                printf("%d > %s\n",i,s);
        }
#endif
        
        const char *cmd = argv[0];//命令本身
        const char *opt = argv[1];//操作指令
        const char *fpath = argv[2];//路径，文件或目录
        if(opt == nil || strlen(opt)==0) {

            printf("\n输入指令，帮助输入 \'llfcrypt help\'\n");
            return 0;
        }

        if(strcmp(opt, "help") == 0) //文件加密
        {
            printf("\n==========>llfcrypt help<===========\n");
            printf("\'fenc file\' 表示对文件进行加密（file为文件路径），加密文件会自动输出到子目录encryption下\n");
            printf("\'fenc directory\' 表示对目录下（directory为目录路径）所有文件进行加密(不包括子目录),加密文件会自动输出到子目录encryption下\n");
            printf("\'fdec file\' 表示对文件进行解密（file为文件路径），解密文件会自动输出到子目录decryption下\n");
            printf("\'fdec directory\' 表示对目录下（directory为目录路径）所有文件进行解密(不包括子目录),解密文件会自动输出到子目录decryption下\n");

            printf("\n==========>Help end<===========\n");
        }
        else if(strcmp(opt, "fenc") == 0) //文件加密
        {
            cryptionAtPath(fpath, "encryption", encrypt_data);
            
        }
        else if(strcmp(opt, "fdec") == 0) //文件解密
        {
            cryptionAtPath(fpath, "decryption", decrypt_data);
        }
        else {
            printf("<========invalid input==========>\n");
            printf("\n帮助输入 llfcrypt help!\n");
        }
    }
    return 0;
}


NSString * resolvePath(NSString *path)
{

    if([path hasPrefix:@"~/"])
        return [path stringByResolvingSymlinksInPath];
    
    if([path hasPrefix:@"/"])
        return path;
    
    
    NSString *curDir = [[NSFileManager defaultManager] currentDirectoryPath];
    NSArray *inCmps = [path componentsSeparatedByString:@"/"];
    NSMutableArray *curCmps = [[curDir componentsSeparatedByString:@"/"] mutableCopy];
    

    for(NSString *s in inCmps) {
        if([s isEqualToString:@".."]) {
            [curCmps removeLastObject];
        }
        else if([s isEqualToString:@"."]) {
            //do nothing
        }
        else {
            [curCmps addObject:s];
        }
    }
    
    NSMutableString *mStr = [NSMutableString string];
    for(NSString *s in curCmps) {
        [mStr appendFormat:@"%@/",s];
    }
    
    [mStr deleteCharactersInRange:NSMakeRange(mStr.length-1, 1)];
    return mStr;
}


void createDirectoryIfNotExisted(NSURL *directory)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    if(![fm fileExistsAtPath:directory.path isDirectory:NULL])
    {
        [fm createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error];
    }

}


void cryptionFile(NSString *srcPath, NSString *destPath, void (*f)(void *, size_t))
{
    NSData *d = [NSData dataWithContentsOfFile:srcPath];
    if(d.length == 0)
        return;
    const void *bytes = [d bytes];
    f((void *)bytes,d.length);
    [d writeToFile:destPath atomically:YES];
    printf("processed file to %s\n",[destPath cStringUsingEncoding:NSUTF8StringEncoding]);
}


bool cryptionAtPath(const char *cPath, char *subDir, void (*f)(void *, size_t))
{
    NSString *abPath = resolvePath([NSString stringWithCString:cPath encoding:NSUTF8StringEncoding]);
    BOOL isDir = NO;
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:abPath isDirectory:&isDir];
    if(!exist) {
        printf("file doesn't exist at path:%s\n",[abPath cStringUsingEncoding:NSUTF8StringEncoding]);
        return false;
    }
    
    NSString *curDir = abPath;
    if(!isDir)
        curDir = [abPath stringByDeletingLastPathComponent];
        
    
    NSString *desDir = [curDir stringByAppendingPathComponent:[NSString stringWithCString:subDir encoding:NSUTF8StringEncoding]];
    createDirectoryIfNotExisted([NSURL fileURLWithPath:desDir]);
    
    if(isDir) //指定的目录
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *files = [fm contentsOfDirectoryAtPath:abPath error:nil];
          
          for(NSString *name in files)
          {
              NSString *path1 = [abPath stringByAppendingPathComponent:name];
            //  NSString *fName = [NSString stringWithFormat:@"%@.e%@",[name stringByDeletingPathExtension],[name pathExtension]];
              NSString *path2 = [desDir stringByAppendingPathComponent:name];
              cryptionFile(path1,path2,f);
              
          }
    }
    else //指定的文件
    {
        NSString *name = [abPath lastPathComponent];
        NSString *path2 = [desDir stringByAppendingPathComponent:name];
        cryptionFile(abPath,path2,f);
    }
    
    printf("=========>>finished processing!!!\n");
    return true;
}


