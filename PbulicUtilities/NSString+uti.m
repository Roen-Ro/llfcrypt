//
//  NSString+Verification.m
//  2bulu-QuanZi
//
//  Created by Kent Peifeng Ke on 14-5-26.
//  Copyright (c) 2014年 Lolaage. All rights reserved.
//

#import "NSString+uti.h"

@implementation NSString (Utility)

+(NSString *)timeDisplayStringBySecond:(NSTimeInterval)second
{
    int seconds = (int)second;
    if(seconds<3600)
    {
        int min, sec;
        min = seconds/60ll;
        sec = seconds%60;
        return [NSString stringWithFormat:@"%02d:%02d",min,sec];
    }
    else
    {
        int hour,min,sec;
        hour = seconds/3600;
        min = (seconds%3600)/60;
        sec = seconds%60;
        return [NSString stringWithFormat:@"%02d:%02d:%02d",hour,min,sec];
    }
}

+(NSString *)timeDisplayStringByDecimalSecond:(NSTimeInterval)second
{
    NSString *secStr = [self timeDisplayStringBySecond:second];
    int decimalSec = ((int)(second*100))%100;
    return [secStr stringByAppendingFormat:@".%02d",decimalSec];
}

+(NSString *)minuteSecondDisplay:(NSTimeInterval)second
{
    int seconds = (int)second;
    int min, sec;
    min = seconds/60;
    sec = seconds%60;
    if(min>=1)
        return [NSString stringWithFormat:@"%d\'%d\"",min,sec];
    else
        return [NSString stringWithFormat:@"%d\"",sec];
}



-(NSString *)urlencode {

    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    int sourceLen = strlen((const char *)source);
    
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}


- (NSString *)urldecode {
    
    NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

//URLEncode
-(NSString*)encodeUrlString
{
    // CharactersToBeEscaped = @":/?&=;+!@#$()~',*";
    // CharactersToLeaveUnescaped = @"[].";
    
    NSString *encodedString = (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                              (CFStringRef)self,
                                                              NULL,
                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8));
    
    return encodedString;
}

//URLDEcode
-(NSString *)decodeUrlString

{
    //NSString *decodedString = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ];
    
    NSString *decodedString  = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                                                                                     (__bridge CFStringRef)self,
                                                                                                                     CFSTR(""),
                                                                                                                     CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return decodedString;
}

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


-(void)findSubString:(nonnull NSString *)subString withBlock:(nonnull void(^)(NSRange subStringRange))block {
    
    //NSLog(@"-->%@ [%@]",self,subString);
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.charactersToBeSkipped = nil; //NSScanner 默认是跳过换行和空白行的，去掉默认行为
    BOOL found = NO;
    NSUInteger preLoc = 0;
    do {
        preLoc = scanner.scanLocation;
        found = [scanner scanUpToString:subString intoString:nil];
        if(found ||  scanner.scanLocation == preLoc) { //scanner.scanLocation == preLoc means [theRestString hasPrefix:subString] == YES
            
            if(scanner.scanLocation < self.length) {
                
                if(block)
                    block(NSMakeRange (scanner.scanLocation,subString.length));
                
                scanner.scanLocation += subString.length;
            }
            
        }
        
    } while (![scanner isAtEnd]);
    
  //  NSLog(@"OUT =======>>>>>");
    
}

//移除标签 例如 <i>hello</i>等, 适应场景有限，只使用所有beginTag必须在endTag之前出现且两者出现次数相等的情况
-(NSString *)trimTagBegin:(NSString *)beginTag end:(NSString *)endTag {
    
    NSInteger sIdx = NSNotFound;
    NSInteger eIdx = NSNotFound;
    NSString *retString = self;

     while(1) {

        sIdx = [retString rangeOfString:beginTag].location;//self.indexOf(beginTag);
        eIdx = [retString rangeOfString:endTag].location;
       NSUInteger len = retString.length;
       if(sIdx != NSNotFound && eIdx != NSNotFound && eIdx > sIdx) {
         NSString * tmsStr1 = @"";
         if(sIdx > 0)
             tmsStr1 = [retString substringToIndex:sIdx];//tmpStr.substring(0,sIdx);

           if(eIdx < len-2) {
               NSString *s = [retString substringFromIndex:eIdx+1];
              tmsStr1 = [NSString stringWithFormat:@"%@ %@",tmsStr1,s];
           }
           

         retString = tmsStr1;
       }
       else
         break;
     }
     return retString;
}


@end


@implementation NSMutableAttributedString (uti)

-(void)addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs
forOccurrencesOfString:(NSString *)ocString {
    [self addAttributes:attrs forOccurrencesOfString:ocString caseSenstive:NO trimWhitespace:YES];
}

-(void)addAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs
forOccurrencesOfString:(NSString *)ocString
        caseSenstive:(BOOL)senstive
      trimWhitespace:(BOOL)trim
{
    
    NSString *s1 = self.string;
    NSString *s2 = ocString;
    
    if(trim)
        s2 = [s2 stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];//去除两端空格
    
    if(!senstive) {
        s1 = [s1 lowercaseString];
        s2 = [s2 lowercaseString];
    }
        
    [s1 findSubString:s2 withBlock:^(NSRange subStringRange) {
        [self addAttributes:attrs range:subStringRange];
    }];
   
}


@end


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
