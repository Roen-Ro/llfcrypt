//
//  main.m
//  tingleetool
//
//  Created by 罗亮富 on 2020/6/5.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeancloudUploader.h"
#import "NSString+uti.h"

void ffmpeg() {
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/local/bin/ffmpeg";
    task.arguments = @[@"-i",@"/Users/jiangwenbin/Desktop/TED演讲/Bill.And.Melinda/BillGates_2014-950k.mp4"];
    
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
        
        const char *cmd = argv[0];//命令本身
        const char *opt = argv[1];//操作指令
        const char *fpath = argv[2];//路径，文件或目录
        
        
//        opt = "lcup";
//        fpath = "/Users/jiangwenbin/Documents/听力资源/英语/当幸福来敲门(OK)";
        
        if(opt == nil || strlen(opt)==0) {

            printf("输入指令，帮助输入 \'tingleetool help\'\n");
            return 0;
        }
        
        if(strcmp(opt, "help") == 0) //文件加密
        {
            printf("\n==========>tingleetool help<===========\n");
            printf("\'tingleetool lcup directory\' 对目录下面的文件上传到leancloud云端");

            printf("\n==========>Help end<===========\n");
        }
        else if(strcmp(opt, "lcup") == 0) //文件加密
        {
            NSString *path = [NSString stringWithCString:fpath encoding:NSUTF8StringEncoding];
            path = resolvePath(path);
            BOOL dir;
            BOOL exist = [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&dir];
            if(!exist)
                NSLog(@"Error: directory does not exist at %@",path);
            
            if(!dir)
                NSLog(@"Error: %@ is not a directory",path);
            
            leancloudUpload(path);
            
        }
        else {
            printf("<========invalid input==========>\n");
            printf("\n帮助输入 tingleetool help!\n");
        }
        
    }
    return 0;
}
