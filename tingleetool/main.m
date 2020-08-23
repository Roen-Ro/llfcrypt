//
//  main.m
//  tingleetool
//
//  Created by 罗亮富 on 2020/6/5.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RRUti/SubTitleProcess.h>
#import <RRUti/SubLineManager.h>
#import "LeancloudUploader.h"
#import <NSString+Utility.h>
#import "MediaSplitHelper.h"

void ffmpegtask() {
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/local/bin/ffmpeg";
    task.arguments = @[@"-i",@"/Users/jiangwenbin/Desktop/MF_Documents/sample-002.mkv",@"-vn",@"-acodec",@"copy",@"/Users/jiangwenbin/Desktop/MF_Documents/999998.m4a"];
    
    NSPipe *outputPipe = [NSPipe pipe];
    
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    NSFileHandle *readHandle = [outputPipe fileHandleForReading];

    [task launch];//启动task
    NSLog(@"A---");
    [task waitUntilExit];//直到程序运行结束，相应程序才会往下执
    NSLog(@"B---");
    NSData *outputData = [readHandle readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    NSLog(@"C---");
    
    NSLog(@"%@",outputString);
    
}

NSString * absolute_path_from_input(const char *inputPath , BOOL *isDir)
{
    NSString *path = [NSString stringWithCString:inputPath encoding:NSUTF8StringEncoding];
    path = resolvePath(path);
    BOOL exist = [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:isDir];
    if(!exist) {
        NSLog(@"Error: directory does not exist at %@",path);
        exit(1);
    }
    return path;
}

#define CHECK_DIRECTORY(dir,path)    if(!dir) { \
    NSLog(@"Error: %@ is not a directory",path);\
    exit(1);\
}

void leancloudUpload(NSString *path) {
    
     NSRunLoop *rlp = [NSRunLoop currentRunLoop];
    
    LeancloudUploader *upl = [[LeancloudUploader alloc]initWithDirectory:[NSURL fileURLWithPath:path]];
    
    //注意，这里不能用 dispatch_group,因为业务代码里面会有很多block是在主线程回调，而如果用了dispatch_group主线程就会处于等待状态，导致永远没有回调
    __block BOOL finished = NO;
    [upl startUploadWithCompletion:^{
        finished = YES;
        exit(0);
    }];

    [rlp run];
   
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
#warning test
        [MediaSplitHelper splitTimePointWithSrtFile:@"/Users/lolaage/Desktop/srt_debug/en.srt" expectedSegmentDuration:600 trimStart:true];
        return 0;
        
        //调试的时候参数可以在Edit scheme -> Arguments -> Arguments passed on launch中添加
        const char *cmd = argv[0];//命令本身
        const char *opt = argv[1];//操作指令
        const char *fpath = argv[2];//路径，文件或目录
        
        
        if(opt == nil || strlen(opt)==0) {

            printf("输入指令，帮助输入 \'tingleetool help\'\n");
            return 0;
        }
        
        if(strcmp(opt, "help") == 0) //文件加密
        {
            printf("\n==========>tingleetool help<===========\n");
            printf("\'tingleetool lcup directory\' 对目录下面的文件上传到leancloud云端\n");
            printf("\'tingleetool msrt directory [-org lan]\' 合并目录下的srt文件成一个多语言的merge.srtx文件,-org lan 可选，指定原语言，默认是en，指定中文 -org zh(来源文件说明：中文zh.srt,英文en.srt,日语jp.srt,法语fre.srt...)\n");
            printf("\'tingleetool bsrt srt_path\' 将普通的双语srt文件分割成两个文件，例如中英双语字幕srt文件，会分割成中文和英文两个srt文件,并将文件存储在当前目录下\n");
            printf("\'tingleetool zhensrtx srtx_path\' 将srtx文件转换成只包含中英双语字幕的srt文件\n");
            printf("\'tingleetool offsetsrtx srtx_path second\' 设置srtx/srt偏移时间\n");
            printf("\'tingleetool split -a audio_file_path -s srtx_file_path\' 自动分割音频和srtx文件\n");

            printf("\n==========>Help end<===========\n");
        }
        else if(strcmp(opt, "lcup") == 0)
        {
            BOOL dir;
            NSString *path = absolute_path_from_input(fpath, &dir);
            CHECK_DIRECTORY(dir,path)

            leancloudUpload(path);
            
        }
        else if(strcmp(opt, "msrt") == 0){
            BOOL dir;
            NSString *path = absolute_path_from_input(fpath, &dir);
            CHECK_DIRECTORY(dir,path)
            NSString *orgLan = @"en";
            const char *orl = argv[3];//原语言种类
            if(orl && strcmp(orl, "-org") == 0) {
                const char *lan = argv[4];
                if(lan)
                    orgLan = [NSString stringWithCString:lan encoding:NSUTF8StringEncoding];
            }
            
            [SubTitleProcess mergeLinesAtDirectory:path withOriginLan:orgLan];
        }
        else if(strcmp(opt, "bsrt") == 0) {
            NSString *path = absolute_path_from_input(fpath, NULL);
            [SubTitleProcess breakLinesWithSrtFile:path];
        }
        else if(strcmp(opt, "zhensrtx") == 0) {
            NSString *path = absolute_path_from_input(fpath, NULL);
            [SubTitleProcess srtxToBilingualChs_EngSrt:path];
        }
        else if(strcmp(opt, "offsetsrtx") == 0) {
            NSString *path = absolute_path_from_input(fpath, NULL);
            NSTimeInterval offset = 0;
            const char *offchar = argv[3];//偏移时间
            if(!offchar)
            {
                NSLog(@"请输入偏移时间");
                exit(1);
            }
            
            NSString *offv = [NSString stringWithCString:offchar encoding:NSUTF8StringEncoding];
            offset = [offv doubleValue];
            NSLog(@"set offset %.1f with %@",offset,path);
            [SubTitleProcess setTimeOffset:offset forsrtAtPath:path];
        }
        else {
            printf("<========invalid input==========>\n");
            printf("\n帮助输入 tingleetool help!\n");
        }
        
    }
    return 0;
}


