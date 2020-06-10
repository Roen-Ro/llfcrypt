//
//  main.m
//  tingleetool
//
//  Created by 罗亮富 on 2020/6/5.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeancloudUploader.h"


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


void leancloudUpload(void) {
    
    LeancloudUploader *upl = [[LeancloudUploader alloc]initWithDirectory:[NSURL fileURLWithPath:@"/Users/jiangwenbin/Documents/听力资源/英语/飞屋环游记(OK)"]];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [upl startUploadWithCompletion:^{
        dispatch_group_leave(group);
    }];

    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    NSLog(@"leancloudUpload Task Finished!!!!");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        leancloudUpload();
    }
    return 0;
}
