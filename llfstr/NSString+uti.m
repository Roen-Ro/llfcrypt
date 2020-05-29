//
//  NSString+Verification.m
//  2bulu-QuanZi
//
//  Created by Kent Peifeng Ke on 14-5-26.
//  Copyright (c) 2014年 Lolaage. All rights reserved.
//

#import "NSString+uti.h"

@implementation NSString (Utility)

//在当面目录下生成新的文件名，如果name为nil，则文件名和原文件名一致，如果extention为nil，则扩展名与原文件一致，二者不能同时为nil，否则就返回self，这样操作会有风险
-(NSString *)pathByReplaceingWithFileName:(nullable NSString *)name extention:(nullable NSString *)extention
{
    NSString *dir = [self stringByDeletingLastPathComponent];
    NSString *orgName = [[self lastPathComponent] stringByDeletingPathExtension];
    NSString *ext = [self pathExtension];
    
    if(!name)
        name = orgName;
    
    if(!extention && ext)
        extention = ext;
    
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",name,extention]];
    
    
}


@end
