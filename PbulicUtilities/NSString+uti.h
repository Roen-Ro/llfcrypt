//
//  NSString+Verification.h
//  2bulu-QuanZi
//
//  Created by Kent Peifeng Ke on 14-5-26.
//  Copyright (c) 2014年 Lolaage. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface NSString (Utility)

//time
+(NSString *)timeDisplayStringBySecond:(NSTimeInterval)second;
+(NSString *)timeDisplayStringByDecimalSecond:(NSTimeInterval)second;
+(NSString *)minuteSecondDisplay:(NSTimeInterval)second;


-(NSString *)urlencode;
-(NSString *)urldecode;
-(NSString*)encodeUrlString;
-(NSString *)decodeUrlString;

//在当面目录下生成新的文件名，如果name为nil，则文件名和原文件名一致，如果extention为nil，则扩展名与原文件一致，二者不能同时为nil，否则就返回self，这样操作会有风险
-(NSString *)pathByReplaceingWithFileName:(nullable NSString *)name extention:(nullable NSString *)extention;

-(void)findSubString:(nonnull NSString *)subString withBlock:(nonnull void(^)(NSRange subStringRange))block;

//移除标签 例如 <i>hello</i>等
-(NSString *)trimTagBegin:(NSString *)beginTag end:(NSString *)endTag;

@end


@interface NSMutableAttributedString (uti)

-(void)addAttributes:(nonnull NSDictionary<NSAttributedStringKey,id> *)attrs forOccurrencesOfString:(nonnull NSString *)ocString;

-(void)addAttributes:(nonnull NSDictionary<NSAttributedStringKey,id> *)attrs
    forOccurrencesOfString:(nonnull NSString *)ocString
            caseSenstive:(BOOL)senstive
          trimWhitespace:(BOOL)trim;

@end

extern NSString * resolvePath(NSString *path);
