//
//  LrcManager.h
//  EnTT
//
//  Created by 罗 亮富 on 12-4-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SubLineInfo.h"
#define DEFAULT_ENCODING CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000)



// lrc的处理用这个类
@interface LrcManager : NSObject

@property BOOL dirtyFlag __attribute__((deprecated("不便维护,不要再使用")));
@property (nonatomic, strong) NSMutableString *lrcContent;
@property (nonatomic, strong) NSString *lrcPath;
@property NSStringEncoding encode;
@property NSRange offsetTagRange;
@property NSTimeInterval timeOffset;
@property (nonatomic, copy) NSArray<SubLineInfo *> *lrcLines;

-(id)initWithLrcContent:(NSString *)lrc;
-(id)initWithLrcFile:(NSString *)filePath;

-(NSTimeInterval)getTimeOffset;
-(NSTimeInterval)ConvertTimeFromTag:(NSString *)tag;
-(void)putAllLrcTimeInAdvance:(NSInteger)minisecond __attribute__((deprecated("use -putAllLrcLineInAdvance:")));
-(void)putAllLrcLineInAdvance:(NSTimeInterval)sec;
-(void)putLrcTimeInAdvance:(NSTimeInterval)second forIndex:(NSInteger)index __attribute__((deprecated("不再使用 直接修改LrcLineInfo")));

-(void)saveEditedLrc  __attribute__((deprecated("use saveToFileCompletion:")));//异步操作
-(void)saveToFileCompletion:(void (^)(BOOL sucess))completion;//覆盖保存
-(void)saveToFile:(NSString *)filePath completion:(void (^)(BOOL sucess))completion;//另存为

-(NSArray<SubLineInfo *> *)parseLrc;

-(BOOL)addStarMarkTagAtIndex:(NSInteger)index Level:(int)level forTimeTag:(NSInteger)timeTagIndex __attribute__((deprecated("不再使用 直接修改LrcLineInfo")));


@end
