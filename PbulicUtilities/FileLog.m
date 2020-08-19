//
//  FileLog.c
//  OutdoorAssistantApplication
//
//  Created by 罗亮富 on 15/10/9.
//  Copyright © 2015年 Lolaage. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

const char *logFilePath = NULL;
static FILE *logFile;

void FLog(NSString * format, ...)
{
#ifdef FILE_LOG
    if(logFilePath)
    {
        va_list argsp;
        va_start(argsp, format);
        if(logFile == NULL)
            logFile = fopen(logFilePath, "a+");
        
        NSString *s = [[NSString alloc]initWithFormat:format arguments:argsp];
        
        if(logFile)
        {
            
            
            NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *tStr = [formatter stringFromDate:[NSDate date]];
            
            NSString *finalStr = [NSString stringWithFormat:@"[%@]\n%@",tStr,s];
            fprintf(logFile, "%s\n", [finalStr cStringUsingEncoding:NSUTF8StringEncoding]);
            fflush(logFile);
        }
        
         NSLog(@"%@", s);
        
        va_end(argsp);
    }

   
#endif

}
