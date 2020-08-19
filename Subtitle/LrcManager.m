//
//  LrcManager.m
//  EnTT
//
//  Created by 罗 亮富 on 12-4-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

@class SubLineInfo;
#import "LrcManager.h"
#import "yyttdatacryption.h"

extern NSString *lrcTimeRgexp;
extern NSString *timeOffsetTagRgexp;
extern NSString *lrcTagRgexp;
extern NSString *lrcStarMarkRgexp ;
extern NSString *lrcLineRgexp;

//NSString *lrcTimeRgexp = @"\\[-?(\\d{1,4}):(\\d{2})\\.(\\d{2})\\]";
//NSString *timeOffsetTagRgexp =  @"\\[offset:-?\\d*\\]";
//NSString *lrcTagRgexp = @"\\[.*?\\]";
//NSString *lrcStarMarkRgexp = @"\\[star:\\d+\\]";
//NSString *lrcLineRgexp =@"\\[-?(\\d{1,4}):(\\d{2})\\.(\\d{2})\\].*";



#define LAST_LINE_DURATION 8



@implementation LrcManager {
    NSMutableArray *_lrcLines;
}
@synthesize lrcLines = _lrcLines;

@synthesize dirtyFlag;
@synthesize lrcContent;
@synthesize lrcPath;
@synthesize encode;
@synthesize offsetTagRange;
@synthesize timeOffset;

+(NSString *)parseLrcAtFile:(NSString *)filePath encode:(NSStringEncoding *)encode
{
    NSStringEncoding tmpEncode;
    
    NSData *data = [[NSData alloc]initWithContentsOfFile:filePath];
    if(data.length < 4)
        return nil;
    
    //解密
    if([filePath hasSuffix:@".ytenc"]) {
        decrypt_data(data.bytes,data.length);
    }
    
    unsigned char charset[4];
    [data getBytes:charset range:NSMakeRange(0, 4)];
    
    
    if(charset[0]==0xFF && charset[1]==0XFE) // Unicode/UTF-16/UCS-2
        tmpEncode = NSUnicodeStringEncoding;
    else if(charset[0]==0xFE&& charset[1]==0XFF) // Unicode/UTF-16/UCS-2 Big edian
        tmpEncode = NSUTF16BigEndianStringEncoding;
    else if(charset[0]==0xEF && charset[1]==0XBB && charset[2]==0XBF) //utf-8
        tmpEncode = NSUTF8StringEncoding;
    else //if(*((uint32_t *)charset)==0x3A69745B)
        tmpEncode = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    
    NSString *lrcString = [[NSString alloc]initWithData:data encoding:tmpEncode];
    if(lrcString == nil)
    {
        NSLog(@"USE NSUTF8StringEncoding decode.");
        tmpEncode = NSUTF8StringEncoding;
        lrcString = [[NSString alloc]initWithData:data encoding:tmpEncode];
    }
    if(encode)
        *encode = tmpEncode;
    
    return lrcString;
}



-(id)initWithLrcContent:(NSString *)lrc
{
    self = [super init];
    if(self)
    {
        self.lrcContent = [[NSMutableString alloc]initWithString:lrc];
        self.encode = DEFAULT_ENCODING;
        self.dirtyFlag = NO;
    }

    return self;
}

-(id)initWithLrcFile:(NSString *)filePath
{
    self = [super init];
    if(self)
    {
        NSString *s = [[self class] parseLrcAtFile:filePath encode:&encode];
        if(s) {
            self.lrcContent = [NSMutableString stringWithString:s];
            self.dirtyFlag = NO;
        }
        self.lrcPath = filePath;
    }
    return self;
}


-(NSTimeInterval)ConvertTimeFromTag:(NSString *)tag
{
    NSArray* parts = [tag componentsSeparatedByString:@":"];
    
    NSString *str1 = [parts objectAtIndex:0];
    NSString *str2 = [parts objectAtIndex:1];
    
    NSString *minString = [str1 substringWithRange:NSMakeRange(1, [str1 length]-1)];
    NSString *secString = [str2 substringWithRange:NSMakeRange(0, [str2 length]-1)];;

    int min = [minString intValue];
    float sec = [secString floatValue];
    return (min*60+sec);
}

-(NSString *)convertTagFromTime:(NSTimeInterval)time
{
    NSInteger min;
    NSTimeInterval sec,second;
    NSString *timetag;
    
    second=fabs(time);
    
    if(second>=60)
    {
        min = second/60;
    }
    else 
        min=0;
    
    sec = second-min*60;
    
    if(time>=0)
        timetag=[[NSString alloc] initWithFormat:@"[%02ld:%05.2f]",(long)min,sec];
    else 
        timetag=[[NSString alloc] initWithFormat:@"[-%02ld:%05.2f]",(long)min,sec];
    
    return timetag;
}

-(NSString *)convertStarMarkTagFromLevel:(int)level {
    
    if(level == 0)
        return @"";
    else
        return [NSString stringWithFormat:@"[star:%d]",level];
}


-(NSString *)searchForOffsetTag
{
    NSInteger len = [lrcContent length];
    NSRange range = [lrcContent rangeOfString:timeOffsetTagRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, len)];
    self.offsetTagRange = range;
    if(range.location == NSNotFound || range.length == 0)
    {
        return nil;
    }
    return [lrcContent substringWithRange:range];
}

-(int)convertMarkeLevelFromMarkTag:(NSString *)markTag
{
    if([markTag length]<8)
        return 0;
    
    NSString *levelStr = [markTag substringWithRange:NSMakeRange(6, [markTag length]-7)];
    int level = (int)[levelStr intValue];
    
    return level;

}

-(BOOL)addStarMarkTagAtIndex:(NSInteger)index Level:(int)level forTimeTag:(NSInteger)timeTagIndex
{
 //  NSLog(@"timeTagIndex:%d",timeTagIndex);
    NSRegularExpression* regex = [[NSRegularExpression alloc]initWithPattern:lrcLineRgexp options:0 error:nil];
    NSArray* chunks = [regex matchesInString:lrcContent options:0 range:NSMakeRange(0, [lrcContent length])];
    if([chunks count]<=index)
    {
        NSLog(@"No such index in current lrc file");
        return NO;
    }
    NSTextCheckingResult* checkRsult1 = [chunks objectAtIndex:index];
    NSMutableString* line =[[NSMutableString alloc]initWithString:[lrcContent substringWithRange:checkRsult1.range]];
    NSRegularExpression* tagRegex =[NSRegularExpression regularExpressionWithPattern:lrcTimeRgexp options:0 error:nil];
    chunks = [tagRegex matchesInString:line options:0 range:NSMakeRange(0, [line length])];
    if([chunks count]<=timeTagIndex)
    {
        NSLog(@"No such time tag index in current lrc line");
        return NO;
    }
    NSTextCheckingResult* checkRsult2 = [chunks objectAtIndex:timeTagIndex];
    NSInteger loc = checkRsult2.range.location+checkRsult2.range.length;
    NSInteger len = [line length]-loc;
    NSRange range = [line rangeOfString:lrcStarMarkRgexp options:NSRegularExpressionSearch range:NSMakeRange(loc, len)];
    if(range.location==NSNotFound || range.length == 0)
    {
        if(level == 0)
        {   
            NSLog(@"no marked time tag here");
            return NO;
        }
        else
            [line insertString:[NSString stringWithFormat:@"[star:%d]",level] atIndex:loc];
    }
    else if(range.location == loc)
    {
        if(level == 0)
        {
            [line deleteCharactersInRange:range];
        }
        else 
            [line replaceCharactersInRange:range withString:[NSString stringWithFormat:@"[star:%d]",level]];
    }
    else if(level != 0)
    {
        [line insertString:[NSString stringWithFormat:@"[star:%d]",level] atIndex:loc];
    }
    else 
    {
        
        NSLog(@"marked tag is not for this time index,time tag loc %d star tagrange(%d,%d)",loc,range.location,range.length);
        return NO;
    }

//    dirtyFlag = YES;
    [lrcContent replaceCharactersInRange:checkRsult1.range withString:line];
  //  NSLog(@"%d-%@",level,line);

    [self saveEditedLrc];
    
    return YES;
}

//used to parse lines that actually with time tag only
-(NSArray *) parseLrcLine:(NSString *)line withTimeOffset:(NSTimeInterval)offset andIndex:(NSInteger)index
{
    
    NSInteger /*loc = 0,*/ tidx = 0;
    NSInteger len = [line length];
    NSRange range,subrang;
    NSMutableArray *maray = [[NSMutableArray alloc]init];
    NSMutableString *lrcStr=[[NSMutableString alloc]initWithString:line];
    NSString *str1;
    
    while (1) 
    {
        range = [lrcStr rangeOfString:lrcTagRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, len)];
     //   loc = range.location + range.length;
        len = len - range.length;
        
        if(range.location == NSNotFound || range.length == 0)
        { 
            for(SubLineInfo *info in maray)
            {
                NSArray *cps = [lrcStr componentsSeparatedByString:LINE_BREAK];
                if(cps.count > 0)
                    info.mainLine = cps.firstObject;
                if(cps.count > 1)
                    info.transLine = [cps objectAtIndex:1];
            }
            break;
        }
        str1 = [lrcStr substringWithRange:range];
        subrang = [str1 rangeOfString:lrcTimeRgexp options:NSRegularExpressionSearch];
        if(subrang.location!=NSNotFound && subrang.length!=0) //time
        {
            SubLineInfo *tmpinfo = [[SubLineInfo alloc] init];
            NSTimeInterval sec = [self ConvertTimeFromTag:str1];
            sec+=offset;
            tmpinfo.timeTag = sec;
            tmpinfo.type = SubLineLrcType;
           // tmpinfo.timeTagIndex = tidx++;
           // tmpinfo.originalIndex = index;
            subrang = [lrcStr rangeOfString:lrcStarMarkRgexp options:NSRegularExpressionSearch];
            if(range.location+range.length == subrang.location && subrang.location != NSNotFound && subrang.length != 0)
            {
                tmpinfo.markLevel = [self convertMarkeLevelFromMarkTag:[lrcStr substringWithRange:subrang]];
            }
            [maray addObject:tmpinfo];
          
        }
        [lrcStr deleteCharactersInRange:range];
    }
    
    return maray;
}

-(NSArray *)parseLrc
{
    NSString *str1;
    NSTimeInterval offset;
    
    if (lrcContent == nil) 
    {   
        NSLog(@"can not parse lrc bcs lrc not found");
        return nil;
    }

    NSMutableArray *CtrlInfoArray=[NSMutableArray array];
    
    offset = [self getTimeOffset];
    //NSLog(@"offset:%f",offset);
    
    NSRegularExpression* regex = [[NSRegularExpression alloc]initWithPattern:lrcLineRgexp options:0 error:nil];
    NSArray* chunks = [regex matchesInString:lrcContent options:0 range:NSMakeRange(0, [lrcContent length])];
    
    NSInteger i=0;
    for (NSTextCheckingResult* b in chunks) 
    {
        str1 = [lrcContent substringWithRange:b.range];
        if(str1.length > 5)
        {
            NSArray *array = [self parseLrcLine:str1 withTimeOffset:offset andIndex:i++];
            [CtrlInfoArray addObjectsFromArray:array];
        }
        else
        {
#if DEBUG
            NSLog(@"skip empty str");
#endif
        }
    }
    
    [CtrlInfoArray sortUsingComparator:^(id obj1, id obj2) {
        SubLineInfo *info1 = (SubLineInfo *) obj1;
        SubLineInfo *info2 = (SubLineInfo *) obj2;
        if(info1.timeTag < info2.timeTag)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;

    }];
    
    NSUInteger c = CtrlInfoArray.count;
    
    for(int i = 0; i < c-1; i++)
    {
        SubLineInfo *l1 = [CtrlInfoArray objectAtIndex:i];
        SubLineInfo *l2 = [CtrlInfoArray objectAtIndex:i+1];
        l1.lastDuration = l2.timeTag - l1.timeTag;
    }
    
    SubLineInfo *l2 = CtrlInfoArray.lastObject;
    l2.lastDuration = LAST_LINE_DURATION;
    
    _lrcLines = CtrlInfoArray;
    
    return [NSArray arrayWithArray:CtrlInfoArray];
}

-(void)insertLrcLine:(SubLineInfo *)line {
    
    if(!line)
        return;
    
    NSUInteger idx = 0;
    NSUInteger c = _lrcLines.count;
    SubLineInfo *curL = nil;
    SubLineInfo *preL = nil;
    BOOL found = NO;
    for ( ; idx < c; idx++) {
        curL = [_lrcLines objectAtIndex:idx];
        if(line.timeTag < curL.timeTag) {
            
            found = YES;
            [_lrcLines insertObject:line atIndex:idx];
            break;
        }
        
        preL = curL;
    }
    
    if(!found) {
        [_lrcLines insertObject:line atIndex:c];
        curL = nil;
    }
    
    preL.lastDuration = line.timeTag - preL.timeTag;
    if(curL)
        line.lastDuration = line.timeTag - curL.timeTag;
    else
        line.lastDuration = LAST_LINE_DURATION;
    
}


-(NSInteger)parseOffsetTag:(NSString *)offsetTag
{
    NSArray* parts = [offsetTag componentsSeparatedByString:@":"];
    NSString *str = [parts objectAtIndex:1];
    NSString *timeStr = [str substringWithRange:NSMakeRange(0,[str length]-1)];
 //   NSLog(@"timeStr  %@",timeStr);
    return [timeStr intValue];
}

-(NSTimeInterval)getTimeOffset
{
    NSString *tag = [self searchForOffsetTag];
    if(tag == nil)
    {
        self.timeOffset = 0;
        return 0;
    }
    NSInteger msec=[self parseOffsetTag:tag];
    self.timeOffset = (NSTimeInterval)msec/1000;
    return timeOffset;
}

-(NSString *)composeOffsetTag:(NSInteger)minisecond
{
    return [NSString stringWithFormat:@"[offset:%ld]",(long)minisecond];
}

-(void)putAllLrcTimeInAdvance:(NSInteger)minisecond
{
    if( lrcContent == nil || minisecond == 0 )
        return;
    
    NSString *tag;
    NSString *offsettag = [self searchForOffsetTag];
    
    if(offsettag==nil)
    {    
        tag = [self composeOffsetTag:minisecond];
        NSRange range = [lrcContent rangeOfString:lrcTimeRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, [lrcContent length])];
        [lrcContent insertString:[tag stringByAppendingString:@"\n"] atIndex:range.location];
    }
    else
    {
        tag = [self composeOffsetTag:minisecond];
        [lrcContent replaceCharactersInRange:offsetTagRange  withString:tag];
    }
}

-(void)putAllLrcLineInAdvance:(NSTimeInterval)sec {
    NSUInteger idx = 0;
    NSUInteger c = _lrcLines.count;
    SubLineInfo *curL = nil;
    for ( ; idx < c; idx++) {
        curL = [_lrcLines objectAtIndex:idx];
        curL.timeTag += sec;
    }
}

-(void)putLrcTimeInAdvance:(NSTimeInterval)second forIndex:(NSInteger)index
{
    if( lrcContent == nil || second == 0 )
        return;
    
    
    NSInteger length = [lrcContent length];
    NSInteger loc = 0;
    NSInteger len = length;
    NSInteger i=0;
    while (1) 
    {
        NSRange range = [lrcContent rangeOfString:lrcTimeRgexp options:NSRegularExpressionSearch range:NSMakeRange(loc, len)];
        loc = range.location + range.length;
        len = [lrcContent length] - loc;
        if(len<=10 || range.location == NSNotFound || range.length == 0)
        { 
            NSLog(@"tag for index not found");
            break;
        }
    //    NSLog(@"%@ length:%d,loc:%d,len:%d",[lrcContent substringWithRange:range],length,loc,len);
        if(i==index)
        {
            NSTimeInterval sec = [self ConvertTimeFromTag:[lrcContent substringWithRange:range]];
            sec += second;
            NSString *newtag = [self convertTagFromTime:sec];
            [lrcContent replaceCharactersInRange:range withString:newtag];
            break;
        }
        i++;
    }

}

-(void)saveEditedLrc
{
    [self saveToFileCompletion:nil];
}
-(void)saveToFileCompletion:(void (^)(BOOL sucess))completion  {
    [self saveToFile:lrcPath completion:completion];
}
-(void)saveToFile:(NSString *)filePath completion:(void (^)(BOOL sucess))completion {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @synchronized (self)
        {
            BOOL suc = NO;
            if(0)
            {
#if DEBUG
               NSLog(@"lrc file does not existed");
#endif
            }
            else {
                NSMutableString *mStr = [NSMutableString stringWithCapacity:lrcContent.length + 256];
                
                NSArray *lines = [_lrcLines copy];
                for(SubLineInfo *l in lines) {
                    
                    NSMutableString *tmStr = [NSMutableString stringWithString:@""];
                    if(l.mainLine.length > 0)
                        [tmStr appendString:l.mainLine];
                    if(l.transLine.length > 0)
                        [tmStr appendFormat:@"%@%@",LINE_BREAK,l.transLine];
                    
                    NSString *s = [NSString stringWithFormat:@"%@%@%@\n",[self convertTagFromTime:l.timeTag],[self convertStarMarkTagFromLevel:l.markLevel],tmStr];
                    [mStr appendString:s];
                }
                lrcContent = mStr;
                
                //加密后再存储
                if([filePath hasSuffix:@".ytenc"]) {
                    NSData *d = [lrcContent dataUsingEncoding:NSUTF8StringEncoding];
                    encrypt_data(d.bytes,d.length);
                    [d writeToFile:filePath atomically:YES];
                }
                else
                    [lrcContent writeToFile:filePath atomically:YES encoding:encode error:nil];
                
                dirtyFlag = NO;
                
                suc = YES;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if(completion)
                    completion(suc);
            });
            
        }
    });
}


@end
