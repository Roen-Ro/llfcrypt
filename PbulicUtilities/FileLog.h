//
//  FileLog.h
//  OutdoorAssistantApplication
//
//  Created by 罗亮富 on 15/10/9.
//  Copyright © 2015年 Lolaage. All rights reserved.
//



#ifndef FileLog_h
#define FileLog_h

#import <Foundation/Foundation.h>

extern const char *logFilePath;

extern void FLog(NSString * format, ...);

#endif /* FileLog_h */
