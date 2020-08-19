//
//  SrtParser.m
//  EnTT
//
//  Created by lolaage on 2016/12/25.
//
//


#import "SubTitleProcess.h"
#import "LanguageModel.h"
#import "yyttdatacryption.h"


#define SRT_LINE_RGEXP_NUM @"(\\d+ *\\t*\\r\\n)??" //开头序号
//#define SRT_LINE_RGEXP_TIME @"\\d{2}:\\d{2}:\\d{2},\\d{1,3} --> \\d{2}:\\d{2}:\\d{2},\\d{1,3} *\\t*\\r\\n"//时间标签
#define SRT_LINE_RGEXP_LINE @"(.+ *\\t*(\\r\\n|$))+"//台词内容

#define SRTX_LINE_RGEXP_TIME @"\\d{1,2}:\\d{2}:\\d{2},\\d{0,3}\\s*-->\\s*\\d{1,2}:\\d{2}:\\d{2},\\d{0,3}"//时间标签 \s*匹配0-n个空格

NSString *lrcTimeRgexp = @"\\[-?(\\d{1,4}):(\\d{2})\\.(\\d{2})\\]";
NSString *timeOffsetTagRgexp =  @"\\[offset:-?\\d*\\]";
NSString *lrcTagRgexp = @"\\[.*?\\]";
NSString *lrcStarMarkRgexp = @"\\[star:\\d+\\]";
NSString *lrcLineRgexp =@"\\[-?(\\d{1,4}):(\\d{2})\\.(\\d{2})\\].*";

@interface SrtxLine  ()

@property (nonatomic, readonly) NSArray<NSString *> *lines; //台词内容,这里内容可能有多行，双语字幕就有原文和翻译两行

@end


@implementation SrtxLine
@synthesize lines = _lines;
@synthesize polyglotLines = _polyglotLines;
//@synthesize main_lan = _main_lan;

-(instancetype)copyWithZone:(NSZone *)zone {
    SrtxLine *l = [[SrtxLine alloc] init];
    [l copyPropertiesFromSourceObject:self];
    l.polyglotLines = [NSMutableDictionary dictionaryWithDictionary:self.polyglotLines];//重点!
    return l;
}


-(int)markLevel {
    NSString *s = [_polyglotLines objectForKey:SRTX_MARK];
    return s.intValue;
}

-(void)setMarkLevel:(int)markLevel {
    
    if(markLevel != 0) {
        if(!_polyglotLines)
            _polyglotLines  = [NSMutableDictionary dictionaryWithCapacity:20];
    
        [_polyglotLines setObject:[NSString stringWithFormat:@"%d",markLevel] forKey:SRTX_MARK];
    }
    else {
        [_polyglotLines removeObjectForKey:SRTX_MARK];
    }
}

-(NSTimeInterval)duration {
    return self.endSecond - self.startSecond;
}

-(void)parseLineFromContent:(NSString *)lineStr {
  //  NSString *k;
    NSDictionary *dic = nil;
    if(lineStr)
       dic = [SubTitleProcess polyglotLinesFromSrtxLineString:lineStr firstLineLan:nil];
    
//    if(!_main_lan) //优先取srtx文件头定义的，如果没有定义，默认取第一行
//        _main_lan = k;
    
    if(!_polyglotLines)
        _polyglotLines  = [NSMutableDictionary dictionaryWithCapacity:dic.count+1];
    
    [_polyglotLines addEntriesFromDictionary:dic];
}

//-(NSString *)main_line {
//    return [_polyglotLines objectForKey:self.main_lan];
//}

-(void)pareseTimeTagFromTimeString:(NSString *)timeString
{
    NSArray *times = [timeString componentsSeparatedByString:@"-->"];
    self.startSecond = [SubTitleProcess timeFromSrtxTimeString:times.firstObject];
    self.endSecond = [SubTitleProcess timeFromSrtxTimeString:[times objectAtIndex:1]];
}

-(NSString *)formarttedLineString {
    NSMutableString *mStr = [NSMutableString stringWithFormat:@"%zu\n",self.lineNum];
    
    if(self.isAlignLine)
        [mStr appendFormat:@"%@\n",SRTX_LINE_ALIGN];
    
    [mStr appendFormat:@"%@ --> %@\n",[SubTitleProcess srtxTimeStringFromValue:self.startSecond],[SubTitleProcess srtxTimeStringFromValue:self.endSecond]];
    
    NSMutableDictionary *mDic = [self.polyglotLines copy];
//    NSString *firstLine = [mDic objectForKey:self.main_lan];
//    if(firstLine)
//        [mStr appendFormat:@"%@\n",[SubTitleProcess formarttedSrtxWithLine:firstLine lan:self.main_lan]];
//
//    [mDic removeObjectForKey:self.main_lan];
    [mDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [mStr appendFormat:@"%@\n",[SubTitleProcess formarttedSrtxWithLine:obj lan:key]];
    }];
    
    return [mStr copy];
}


-(NSString *)convertToLrcLineByRevertingLineOrder:(BOOL)revert addLineSeparator:(NSString *)separator;
{
    if(self.lines.count == 0)
        return nil;
    
    if(!separator)
        separator = @" ";
    
    NSString *timetag =[SubTitleProcess lrcTimeTagStringForTime:self.startSecond];
    NSString *lrcLine;
    if(self.lines.count > 1)
    {
        NSString *line1 = self.lines.firstObject;
        NSString *line2 = [self.lines objectAtIndex:1];
        if(line2.length > 0)
        {
            if(revert)
            {
                line1 = [self.lines objectAtIndex:1];
                line2 = self.lines.firstObject;
            }
            
            lrcLine = [NSString stringWithFormat:@"%@%@%@%@\r\n",timetag,line1,separator,line2];
        }
        else
            lrcLine = [NSString stringWithFormat:@"%@%@\r\n",timetag,self.lines.firstObject];
    }
    else
    {
        lrcLine = [NSString stringWithFormat:@"%@%@\r\n",timetag,self.lines.firstObject];
    }
    
    
    return lrcLine;
}

#if DEBUG
-(NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p>,%.3f -> %.3f %@\n%@",NSStringFromClass([self class]),self,self.startSecond,self.endSecond,self.polyglotLines,self.formarttedLineString];
}
#endif

@end

#pragma mark-

@implementation LrcLine



@end


#pragma mark-
@implementation SubTitleProcess

+(NSString *)readStringFromFile:(NSString *)path
{
  //  NSLog(@"%s:%@",__PRETTY_FUNCTION__,path);
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    //解密
      if([path hasSuffix:@".ytenc"]) {
          decrypt_data((void *)data.bytes,data.length);
      }

    NSString *finalString = nil;
    NSInteger encodes[] = {
        NSUTF8StringEncoding,//最高优先级
        NSUnicodeStringEncoding, //次高优先，及时是NSUTF16LittleEndianStringEncoding也能被解析，但如果用NSUTF16LittleEndianStringEncoding的话在一些处理上有异常
        NSUTF16LittleEndianStringEncoding,
        NSUTF16StringEncoding,
        NSUTF16BigEndianStringEncoding,
        NSASCIIStringEncoding,
        NSISOLatin1StringEncoding,
        NSNEXTSTEPStringEncoding,
        NSJapaneseEUCStringEncoding,
        NSNonLossyASCIIStringEncoding,
        NSShiftJISStringEncoding,
        NSMacOSRomanStringEncoding,
    };
    NSUInteger c = sizeof(encodes)/sizeof(NSInteger);
    for(int i=0; i<c; i++) {
        finalString = [[NSString alloc]initWithData:data encoding:encodes[i]];
        if(finalString)
            break;
    }


    return finalString;
}

+(NSArray<NSTextCheckingResult *> *)chunksWithRegularExpressionPattern:(NSString *)pattern forString:(NSString *)stringContent
{
    NSError *error;
    NSRegularExpression* regex = [[NSRegularExpression alloc]initWithPattern:pattern options:0 error:&error];
    NSArray* chunks = [regex matchesInString:stringContent options:0 range:NSMakeRange(0, [stringContent length])];
    
    return chunks;
}

+(NSTimeInterval)timeFromSrtxTimeString:(NSString *)timeTag
{
    NSScanner *scanner = [[NSScanner alloc]initWithString:timeTag];
    NSString *hour, *minute, *second, *millisecond,*tmp;
    
    [scanner scanUpToString:@":" intoString:&hour];
    [scanner scanString:@":" intoString:&tmp];
    [scanner scanUpToString:@":" intoString:&minute];
    [scanner scanString:@":" intoString:&tmp];
    [scanner scanUpToString:@"," intoString:&second];
    [scanner scanString:@"," intoString:&tmp];
    [scanner scanUpToString:@" " intoString:&millisecond];
    if(!millisecond)
        [scanner scanUpToString:@"" intoString:&millisecond];
    
    NSTimeInterval interval = hour.intValue*3600 + minute.intValue*60 + second.intValue + millisecond.floatValue/1000;
    
    return interval;
}

+(NSString *)srtxTimeStringFromValue:(NSTimeInterval)t {
    int sec = floor(t);
    int h = floor(sec/3600);
    int m = floor((sec - h*3600)/60);
    int s = floor(sec%60);
    int ms = (t-(NSTimeInterval)sec)*1000;
    return [NSString stringWithFormat:@"%02d:%02d:%02d,%03d",h,m,s,ms];
}


/**
 解析srtx的字幕内容
 举个栗子：
 会将以下srtx字幕
 [zh:]我叫萧穗子
 [en:]My name is Xiao Suizi.[fix]
 [es:]Mi nombre es Xiao Suizi.
 解析成：
 @{
    @"zh":@"我叫萧穗子",
    @"en":@"My name is Xiao Suizi.",
    @"es":@"Mi nombre es Xiao Suizi.",
 }
 */
+(NSDictionary *)polyglotLinesFromSrtxLineString:(NSString *)lineString firstLineLan:(NSString **)lan{
    
    if([lineString hasPrefix:@"["])
    {
        NSArray *lineStrs = [lineString componentsSeparatedByString:@"\n"];
        NSString *lanS;
        NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:lineStrs.count];
        int i = 0;
        NSString *firstLanKey = nil;
        for(NSString *l in lineStrs) {
            lanS = nil;
            NSString *txt = [self parseSrtxLine:l lan:&lanS];
            
            if(!lanS)
                lanS = LAN_UNDEFINED;
            
            if(!firstLanKey && ![lanS isEqualToString:SRTX_MARK])
                firstLanKey = lanS;
            
            if(txt)
                [mDic setObject:txt forKey:lanS];
            
            i++;
        }
        
        if(lan)
            *lan = firstLanKey;
        
        return [NSDictionary dictionaryWithDictionary:mDic];
    }
    else {
        if(lan)
            *lan = LAN_UNDEFINED;
        return @{LAN_UNDEFINED:lineString};
    }
}

+(NSString *)parseSrtxLine:(NSString *)line lan:(NSString **)lan {
    
    if([line hasPrefix:@"["] && [line containsString:@":]"]) {
        NSString *lanStr = nil;
        NSScanner *scanner = [NSScanner scannerWithString:line];
        [scanner scanString:@"[" intoString:nil];
        [scanner scanUpToString:@":]" intoString:&lanStr];
        if(lanStr) {
            line = [line substringFromIndex:scanner.scanLocation+2];
            line = [line stringByReplacingOccurrencesOfString:LINE_BREAK withString:@"\n"];
            if(lan)
                *lan = lanStr;
        }
    }

    return line;
}

+(NSString *)formarttedSrtxWithLine:(NSString *)line lan:(NSString *)lan {
    
    if([lan isEqualToString:LAN_UNDEFINED])
        return line;
    else {
        return [NSString stringWithFormat:@"[%@:]%@",lan,[line stringByReplacingOccurrencesOfString:@"\n" withString:LINE_BREAK]];
    }
}

+(NSArray<SrtxLine *>*)parseSrtxFile:(NSString *)srtPath withOriginalLan:(NSString **)lan {
    
    return [self parseSrtxString:[self readStringFromFile:srtPath] withOriginalLan:lan];
}

+(NSArray<SrtxLine *>*)parseSrtxString:(NSString *)srtFileString withOriginalLan:(NSString **)lan
{
    if(srtFileString.length < 2)
        return nil;
    NSScanner *scanner = [NSScanner scannerWithString:srtFileString];
    scanner.charactersToBeSkipped = nil; //NSScanner 默认是跳过换行和空白行的，因为srt格式有空行，所以要去掉默认行为
    NSCharacterSet *whitespaceAndNewlineCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSPredicate *srtTimePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",SRTX_LINE_RGEXP_TIME];
    NSMutableArray *srtxLines = [NSMutableArray arrayWithCapacity:1000];
    
    SrtxLine *srtInfo;
    NSString *s;
    NSString *blank;
    srtFileString = [srtFileString stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
    if([srtFileString hasPrefix:ORIGINAL_LAN]) {
        
        [scanner scanUpToString:@"\n" intoString:&s];
        [scanner scanString:@"\n" intoString:&blank];
        if(lan)
            *lan = [s substringFromIndex:ORIGINAL_LAN.length];
    }
    
    NSString *markPrefix = [NSString stringWithFormat:@"[%@:]",SRTX_MARK];
    
    //0:空行或无效，1：索引，2：时间，3:内容 4:未知 5:对齐标记(用于字幕合并时标记时间对齐)
    int lastLineType = 0;
    int curLineType = 0;
    s = nil; //去残留
    NSString *curLineText;
    
    do {
        [scanner scanUpToString:@"\n" intoString:&s];
        [scanner scanString:@"\n" intoString:&blank];
        s = [s stringByTrimmingCharactersInSet:whitespaceAndNewlineCharacterSet];
        if(s.length == 0) //空行
        {
            curLineType = 0;
            if(srtInfo && curLineText) {
                [srtInfo parseLineFromContent:curLineText];
                [srtxLines addObject:srtInfo];
            }
            
            srtInfo = nil;
            curLineText = nil;
        }
        else if(lastLineType == 0) {
            
            if(s.integerValue > 0 )
            {
                curLineType = 1;
                srtInfo = [[SrtxLine alloc] init];
                srtInfo.lineNum = s.integerValue;
            }
            else {
                srtInfo = nil;
                curLineText = nil;
                curLineType = 4;
            }
        }
        else if(lastLineType == 1 || lastLineType == 5) {
            if([s isEqualToString:SRTX_LINE_ALIGN]) {
                curLineType = 5;
                srtInfo.isAlignLine = YES;
            }
            else if([srtTimePredicate evaluateWithObject:s]) {
                curLineType = 2;
                [srtInfo pareseTimeTagFromTimeString:s];
            }
            else {
                curLineType = 4;
                srtInfo = nil;
                curLineText = nil;
            }
        }
        else if(lastLineType == 2) {
            curLineType = 3;
            
            curLineText = [s trimTagBegin:@"{" end:@"}"];
            curLineText = [curLineText trimTagBegin:@"<" end:@">"];//这会吧<br>也trim掉
           // curLineText = [curLineText trimTagBegin:@"<" end:@">"];//这会吧<br>也trim掉
            
        }
        else if(lastLineType == 3) {
            
            if([s hasPrefix:markPrefix]) {
                srtInfo.markLevel = [s substringFromIndex:markPrefix.length].intValue;
            }
            else {
                NSString *s3 = [s trimTagBegin:@"{" end:@"}"];
                s3 = [s3 trimTagBegin:@"<" end:@">"];
                curLineText = [curLineText stringByAppendingFormat:@"\n%@",s3];
            }
        }
        
        s = nil; //这句很重要，否则会有残留
        lastLineType = curLineType;
        
    } while (![scanner isAtEnd]);
        

    if(srtInfo && curLineText)
    {
        [srtInfo parseLineFromContent:curLineText];
        [srtxLines addObject:srtInfo];
    }
        
#if DEBUG
    if(srtFileString.length > 20 && srtxLines.count == 0) {
        NSLog(@"\n string length:%zu READ %zu LINES ---->",srtFileString.length,srtxLines.count);
    }
#endif
    return srtxLines;

}

////移除类似xml的标签，除了<br>
//+(NSString *)removeTagsOfLineContent:(NSString *)lineContent {
//    lineContent = [lineContent stringByReplacingOccurrencesOfString:@"<i>" withString:@" "];
//    lineContent = [lineContent stringByReplacingOccurrencesOfString:@"</i>" withString:@" "];
//    lineContent = [lineContent stringByReplacingOccurrencesOfString:@"</font>" withString:@" "];
//    NSUInteger sIdx = [lineContent rangeOfString:@"<font"].location;
//    if(sIdx != NSNotFound) {
//    }
//
//    return lineContent;
//}

+(NSString *)convertSrtString2LrcString:(NSString *)srtString revertLineOrder:(BOOL)revert
{
    NSMutableArray *srtLines = [NSMutableArray arrayWithArray:[self parseSrtxString:srtString withOriginalLan:nil]];
    
    [srtLines sortUsingComparator:^(id obj1, id obj2) {
        SrtxLine *line1 = obj1;
        SrtxLine *line2 =  obj2;
        return (line1.startSecond > line2.startSecond ? NSOrderedDescending:NSOrderedAscending);
    }];
    
    NSMutableString *mStr = [NSMutableString string];
    
    SrtxLine *preLine = nil;
    for(SrtxLine *line in srtLines)
    {
        //如果上一句台词结束时间和当前台词开始时间差大于 1 秒，中间插入空行
        if(preLine && (line.startSecond - preLine.endSecond > 0.7))
        {
            [mStr appendFormat:@"%@\r\n",[self lrcTimeTagStringForTime:preLine.endSecond]];
        }
        
        NSString *lrc = [line convertToLrcLineByRevertingLineOrder:revert addLineSeparator:LINE_BREAK];
        if(lrc)
        {
            [mStr appendString:lrc];
        }
        
        preLine = line;
    }
    
    return mStr;
}

+(NSString *)convertSrtString2LrcStringFromFile:(NSString *)srtFilePath revertLineOrder:(BOOL)revert
{
    return [self convertSrtString2LrcString:[self readStringFromFile:srtFilePath] revertLineOrder:revert];
}

+(NSString *)lrcTimeTagStringForTime:(NSTimeInterval)time
{
    int min = time/60;
    float sec = (time - min*60);
    NSString *timetag = [[NSString alloc] initWithFormat:@"[%02d:%05.2f]",min,sec];
    
    return timetag;
}

+(NSString *)saveSrtxLines:(nonnull NSArray<SrtxLine *>*)lines withOriginalLan:(NSString *)orgLan toFile:(NSString *)path error:(NSError **)e
{
    
    NSMutableString *srtFileStr = [[NSMutableString alloc] initWithCapacity:1024*1024*2];
    if(orgLan && ![orgLan isEqualToString:LAN_UNDEFINED])
        [srtFileStr appendFormat:@"%@%@\n\n",ORIGINAL_LAN,orgLan];
    
    int i = 1;
    for(SrtxLine *l in lines) {
        if(l.polyglotLines.count == 0)
            continue;
        
        l.lineNum = i;
        [srtFileStr appendFormat:@"%@\n\n",l.formarttedLineString];
        i++;
    }
    
    //加密再存储
    if([path hasSuffix:@".ytenc"]) {
        NSData *d = [srtFileStr dataUsingEncoding:NSUTF8StringEncoding];
        encrypt_data((void *)d.bytes,d.length);
        [d writeToFile:path atomically:YES];
    }
    else
        [srtFileStr writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:e];
    
    return srtFileStr;
}


+(NSArray <SrtxLine*>*)convertLrcToSrtxLines:(NSString *)lrcPath {
    NSString *s = [self readStringFromFile:lrcPath];
    NSArray<LrcLine *> * lrcLines = [self parseLrcString:s];
    LrcLine *l0 = nil;
    int i = 0;
    NSMutableArray *srtLines = [NSMutableArray arrayWithCapacity:lrcLines.count];
    for(LrcLine *l1 in lrcLines) {
       
        SrtxLine *sline = [[SrtxLine alloc] init];
        if(i>0 && l0.content.length > 0) {
            sline.startSecond = l0.second;
            sline.endSecond = l1.second;
            NSString *c = [l0.content stringByReplacingOccurrencesOfString:LINE_BREAK withString:@"\n"];
            sline.polyglotLines = [NSMutableDictionary dictionaryWithObjectsAndKeys:c,LAN_UNDEFINED,nil];
        }
        
        if(i == lrcLines.count-1 && l1.content.length > 0) {
            sline.startSecond = l1.second;
            sline.endSecond = l1.second+3;
            NSString *c = [l1.content stringByReplacingOccurrencesOfString:LINE_BREAK withString:@"\n"];
            sline.polyglotLines = [NSMutableDictionary dictionaryWithObjectsAndKeys:c,LAN_UNDEFINED,nil];
        }
        
        if(sline.polyglotLines)
            [srtLines addObject:sline];
        
        l0 = l1;
        i++;
    }
    
    return srtLines;
}

//返回srtx文件路径
+(NSString *)convertLrcToSrtFile:(NSString *)lrcPath {
    
    NSArray <SrtxLine*>* lines = [self convertLrcToSrtxLines:lrcPath];
    NSString *dir = [lrcPath stringByDeletingLastPathComponent];
    NSString *name = [[lrcPath lastPathComponent] stringByDeletingPathExtension];
    NSString *destPath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.srt",name]];
    if(lines.count > 0)
        [self saveSrtxLines:lines withOriginalLan:nil toFile:destPath error:nil];
    
    return destPath;
}

//将srtx文件生成为中英双语的srt文件，返回新生成的文件路劲
+(NSString *)srtxToBilingualChs_EngSrt:(NSString *)srtxPath {
    
    NSString *s = [self readStringFromFile:srtxPath];
    NSArray<SrtxLine *>*lines = [self parseSrtxString:s withOriginalLan:nil];
    for(SrtxLine *l in lines) {
        NSString *enStr = [l.polyglotLines objectForKey:@"en"];
        NSString *zhStr = [l.polyglotLines objectForKey:@"zh"];
        [l.polyglotLines removeAllObjects];
        enStr = [enStr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        zhStr = [zhStr stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        NSString *c;
        if(enStr && zhStr)
            c = [NSString stringWithFormat:@"%@\n%@",zhStr,enStr];
        else if(enStr)
            c = enStr;
        else if(zhStr)
            c = zhStr;
        
        if(c)
            [l.polyglotLines setObject:c forKey:LAN_UNDEFINED];
    }
    
    NSString *destPath;
    if(lines.count > 0)
    {
        destPath = [srtxPath pathByReplaceingWithFileName:@"zh&eng" extention:@"srt"];
        [self saveSrtxLines:lines withOriginalLan:nil toFile:destPath error:nil];
    }
    
    return destPath;
    
}

//注意是拆分srt字幕，不是srtx字幕，就是单纯的把两行字幕，分别拆分成两组字幕
+(NSArray<NSArray <SrtxLine *> *>*)breakSrtLine:(NSArray <SrtxLine *> *)orglines {
    
    NSMutableArray *line1 = [NSMutableArray arrayWithCapacity:orglines.count];
    NSMutableArray *line2 = [NSMutableArray arrayWithCapacity:orglines.count];
    
    for(SrtxLine *rl in orglines) {
        
        NSString *l = [rl.polyglotLines allValues].firstObject;
        NSArray *lines = [l componentsSeparatedByString:@"\n"];
        if(lines.count > 0) {
            SrtxLine *l1 = [rl copy];
            l1.polyglotLines = [[NSMutableDictionary alloc] initWithObjects:@[lines.firstObject] forKeys:@[LAN_UNDEFINED]];
            [line1 addObject:l1];
        }
        
        if(lines.count > 1) {
            SrtxLine *l2 = [rl copy];
            l2.polyglotLines = [[NSMutableDictionary alloc] initWithObjects:@[lines[1]] forKeys:@[LAN_UNDEFINED]];
            [line2 addObject:l2];
        }
    }
    return @[line1,line2];
}

//注意是拆分srt字幕，不是srtx字幕，就是单纯的把两行字幕，分别拆分成两组字幕,返回其存放地址
+(NSArray <NSString *> *)breakLinesWithSrtFile:(NSString *)srtPath {
    
    NSArray<SrtxLine *> *olines = [self parseSrtxString:[self readStringFromFile:srtPath] withOriginalLan:nil];
    NSArray *lines = [self breakSrtLine:olines];
    NSString *name = [[srtPath lastPathComponent] stringByDeletingPathExtension];
    NSMutableArray *retPathes = [NSMutableArray arrayWithCapacity:lines.count];
    for(int i = 0; i<lines.count; i++) {
        NSString *pt = [[srtPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_breaked_%02d.srt",name,i]];
        [self saveSrtxLines:lines[i] withOriginalLan:nil toFile:pt error:nil];
        [retPathes addObject:pt];
    }
    
    if(retPathes.count > 0)
        return retPathes;
    else
        return nil;
}

#define INNER_TIME_ESP 0.1

#pragma mark- 合并
/// 字幕合并
/// @param orgLanSrt 原语言srt字幕
/// @param orgLan 原语言语种简写 en/zh/ko/ru/es等语言的简写，为nil的话表示不设置原语言，在orgLanSrt已经是多语言字幕的情况下，会忽略掉该值
/// @param transLanSrt 被合并的翻译语言srt字幕,必须要为没有标记语言种类的字幕
/// @param transLan 翻译语言语种
/// 注意1：这里会自动将transLanSrt第一句标记为align>字幕时间和orgLanSrt第一句标记为align>字幕时间进行同步, transLanSrt字幕内容也会被同步改变
/// 注意2：orgLanSrt字幕内容有可能被改变，在处理的时候都没有做深拷贝
+(NSArray<SrtxLine *>*)mergeOriginalSrt:(nonnull NSArray<SrtxLine *>*)orgLanSrt
                          setOriginalLan:(nullable NSString *)orgLan
                           withSrtLines:(nonnull NSArray<SrtxLine *>*)transLanSrt
                             ofTransLan:(nonnull NSString *)transLan
{
    NSUInteger cnt1 = orgLanSrt.count;
    NSUInteger cnt2 = transLanSrt.count;
    if(cnt1 == 0 && cnt2 == 0)
        return nil;
    
    orgLanSrt = [self fixLineOrderAndLappedTime:orgLanSrt];
    transLanSrt = [self fixLineOrderAndLappedTime:transLanSrt];
    cnt1 = orgLanSrt.count;
    cnt2 = transLanSrt.count;
    
    //自动对齐字幕
    SrtxLine *orgAlignLine = nil;//orgLanSrt[0];
    for(SrtxLine *l in orgLanSrt) {
        if(l.isAlignLine) {
            orgAlignLine = l;
            break;
        }
    }
    SrtxLine *transAlignLine = nil;//transLanSrt[0];
    for(SrtxLine *l in transLanSrt) {
        if(l.isAlignLine) {
            transAlignLine = l;
            break;
        }
    }
    NSTimeInterval diffSec = 0;
    if(orgAlignLine && transAlignLine)
        diffSec = transAlignLine.startSecond - orgAlignLine.startSecond;
    
    SrtxLine *orgLine = orgLanSrt[0];
    SrtxLine *nextOrgLine = nil;
    SrtxLine *transLine = transLanSrt[0];
    
    if(fabs(diffSec) > 0.1) {
        
        //时间同步矫正
         for(SrtxLine *tline in transLanSrt) {
             tline.startSecond -= diffSec;
             tline.endSecond -= diffSec;
         }
    }

    
    //开始按照时间匹配合并
    NSUInteger nextMatchIndex = 0;
    NSUInteger j = 0;
    NSTimeInterval lapTime1;//和当前原字幕重叠时间
    NSTimeInterval lapTime2;//和下一句原字幕重叠时间
    
    NSMutableIndexSet *mIndexSet = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, cnt2)]; //用于记录哪些字幕没有被合并
    NSMutableArray *tempToMergeLines = [NSMutableArray arrayWithCapacity:3];
    
    NSTimeInterval minLapTime = INNER_TIME_ESP; //两句字幕最少重叠时间
    
    for(NSUInteger i=0; i<cnt1; i++) {
        
        @autoreleasepool {
            orgLine = orgLanSrt[i];
            if(i<cnt1-1)
                nextOrgLine = orgLanSrt[i+1];
            else
                nextOrgLine = nil;
            
            lapTime2 = 0;
            lapTime1 = 0;
            [tempToMergeLines removeAllObjects];
            
            //需要设置源语言
            if(orgLan && orgLine.polyglotLines.count == 1 ) {
                
                NSString *curLan = (NSString *)orgLine.polyglotLines.allKeys.firstObject;
                if([curLan isEqualToString:LAN_UNDEFINED]) {
                    NSString *c = orgLine.polyglotLines.allValues.firstObject;
                    c = [c stringByReplacingOccurrencesOfString:@"\n" withString:LINE_BREAK];
                    [orgLine.polyglotLines removeAllObjects];
                    [orgLine.polyglotLines setObject:c forKey:orgLan];
                }
            }

//            NSLog(@"Roop %zu",i);
            for(j=nextMatchIndex; j<cnt2; j++)
            {
                transLine = transLanSrt[j];
                //计算和当前源字幕时间重叠
                lapTime1 = timeLapCal(orgLine.startSecond, orgLine.endSecond, transLine.startSecond, transLine.endSecond);
            
                minLapTime = MIN(orgLine.duration*0.3,transLine.duration*0.3);
                
     //           NSLog(@"%@(%zu) - %@(%zu) lap:%.2f",orgLan,i+1,transLan,j+1,lapTime1);
                if(lapTime1 >= minLapTime || lapTime1 > 2)//当发生时间重叠
                {
                    //计算和下一句源字幕重叠时间
                    if(nextOrgLine)
                        lapTime2 = timeLapCal(nextOrgLine.startSecond, nextOrgLine.endSecond, transLine.startSecond, transLine.endSecond);
                    
                    //和orgLine与nextOrgLine都有重叠，看谁的重叠时间更长
                    if(lapTime2 > lapTime1)
                    {
                        //和下一句源字幕时间重叠更长，跳出匹配嵌套的循环，在下一次外层循环中重新匹配
#if DEBUG
//                        if(orgLine.polyglotLines.count>0)
//                            NSLog(@"lapTime2:%.2f > lapTime1:%.2f\n%@",lapTime2,lapTime1,orgLine.polyglotLines.allValues.firstObject);
//                        else
//                             NSLog(@"lapTime2:%.2f > lapTime1:%.2f",lapTime2,lapTime1);
#endif
                        break;
                    }
                    else {
                        [tempToMergeLines addObject:transLine];
                        [mIndexSet removeIndex:j];
                    }
                    
                }
                else if(lapTime1 > 0) {
                    //修改第二句的开始时间，以免造成时间混乱
                    if(transLine.startSecond > orgLine.startSecond) {
                        transLine.startSecond = orgLine.endSecond + 0.1;
                        if(transLine.startSecond > transLine.endSecond)
                            transLine.endSecond = transLine.startSecond + transLine.duration;
                    }
                    else {
                        transLine.endSecond = orgLine.startSecond - 0.1;
                        if(transLine.startSecond > transLine.endSecond)
                            transLine.startSecond = transLine.endSecond - 0.2; //这种异常字幕就这样暴力处理
                    }
                }
                
                //注意这里不能以简单的transLine.startSecond>orgLine.endSecond来判断, 要结合lapTime1的时间
                if(transLine.startSecond - orgLine.endSecond >= -minLapTime) {
                    nextMatchIndex = j;
                    break;
                }
                
            } //for(j=nextMathIndex; j<cnt2; j++)
            
            for(SrtxLine *l1 in tempToMergeLines) {
                [self addSrtLine:l1 ofLan:transLan toSrtxLine:orgLine];
            }
        
        } //@autoreleasepool
        
    } //for(NSUInteger i=0; i<cnt1; i++)
    
    #if DEBUG
            NSLog(@"%zu 句没有合并的%@字幕 =====>>>>>",mIndexSet.count,transLan);
    #endif

    if(mIndexSet.count > 0) {

        NSMutableArray *mLines = [NSMutableArray arrayWithCapacity:orgLanSrt.count+mIndexSet.count];
        [mLines addObjectsFromArray:orgLanSrt];
        [mIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            
            SrtxLine *l1 = [transLanSrt objectAtIndex:idx];
            SrtxLine *preL0 = nil;
            BOOL inserted = NO;//YES 中间插入，NO要在最后插入
            for(NSUInteger x = 0; x<mLines.count; x++)
            {
                SrtxLine *l0 = [mLines objectAtIndex:x];
                SrtxLine *mergeToLine = l0;
                if(l1.startSecond <= l0.startSecond) //找到第一句比它开始时间大的字幕
                {
                    inserted = YES;
#if DEBUG
  //                  NSLog(@"INSERT LINE:\n%@",l1.formarttedLineString);
#endif
#if 0
            //----------将没有重叠的字幕合并到时间最接近的字幕中
                    //比较字幕时间距离哪句字幕时间更接近
                    if(preL0) {
                        NSTimeInterval toPre = l1.startSecond - preL0.endSecond;
                        NSTimeInterval toNext = l0.startSecond - l1.endSecond;
                        if(toPre < toNext)
                            mergeToLine = preL0;
                    }
                    
                    
                    [self addSrtLine:l1 ofLan:transLan toSrtxLine:mergeToLine];
        //----------
#else
        //----------将没有和源字幕时间重叠的字幕独立插入一行
                    SrtxLine *li = [self convertSrtLineToSrtx:l1 withLan:transLan];
                    if(li)
                        [mLines insertObject:li atIndex:x];
                    
       // ----------
#endif
                    break;
                } //if(l1.startSecond <= l0.startSecond)
                
                preL0 = l0;
            } //  END:for(NSUInteger x = 0; x<mLines.count; x++)
        
            if(!inserted) {
#if DEBUG
                NSLog(@"APPEND LINE:\n%@",l1.formarttedLineString);
#endif
                SrtxLine *li = [self convertSrtLineToSrtx:l1 withLan:transLan];
                if(li)
                    [mLines addObject:li];
            }
                
        }];
        
        return mLines;
    }
    else
        return orgLanSrt;
}

//注意 addLine 是srt字幕，不是srtx字幕
+(void)addSrtLine:(SrtxLine *)addLine ofLan:(NSString *)lan toSrtxLine:(SrtxLine *)targeLine {
    
    if(addLine.polyglotLines.count == 1) {
        
        NSString *lineContent = [targeLine.polyglotLines objectForKey:lan];
        if(!lineContent)
            lineContent = (NSString *)addLine.polyglotLines.allValues.firstObject;
        else
            lineContent = [lineContent stringByAppendingFormat:@"%@%@",LINE_BREAK, (NSString *)addLine.polyglotLines.allValues.firstObject];
        
        lineContent = [lineContent stringByReplacingOccurrencesOfString:@"\n" withString:LINE_BREAK];
        
        if(lineContent.length > 0) {
            if(!targeLine.polyglotLines)
                targeLine.polyglotLines = [NSMutableDictionary dictionaryWithCapacity:12];
            
            [targeLine.polyglotLines setObject:lineContent forKey:lan];
        }
    }
}

//将没有标记语言的srt字幕转成标记语言的srtx字幕
+(nullable SrtxLine *)convertSrtLineToSrtx:(nonnull SrtxLine *)srtLine withLan:(NSString *)lan {
    NSString *c = srtLine.polyglotLines.allValues.firstObject;
    SrtxLine *li = nil;
   if(c) {
       li = [srtLine copy];
       [li.polyglotLines removeAllObjects];
       c = [c stringByReplacingOccurrencesOfString:@"\n" withString:LINE_BREAK];
       [li.polyglotLines setObject:c forKey:lan];
   }
    return li;
}

//将所有lines的字幕，合并成一句
+(SrtxLine *)mergeSrtxLinesToOne:(nonnull NSArray <SrtxLine *> *)lines {
    
    if(lines.count == 0)
        return nil;
    
    if(lines.count == 1)
    return lines.firstObject;
    
    SrtxLine *l0 = lines.firstObject;
    SrtxLine *lm = nil;
    
    SrtxLine *retLine = [l0 copy];
    if(!retLine.polyglotLines)
        retLine.polyglotLines = [NSMutableDictionary dictionaryWithCapacity:20];
    
    retLine.endSecond = lines.lastObject.endSecond;
    
    for(int i=1; i<lines.count; i++) {
        lm = lines[i];
        
        [lm.polyglotLines enumerateKeysAndObjectsUsingBlock:^(NSString  *key, NSString  *obj, BOOL * _Nonnull stop) {
            
            NSString *c = [retLine.polyglotLines objectForKey:key];
            if(c)
                [retLine.polyglotLines setObject:[NSString stringWithFormat:@"%@%@%@",c,LINE_BREAK,obj] forKey:key];
            else
                [retLine.polyglotLines setObject:obj forKey:key];
                
        }];
    }
    
    return retLine;
}

/**
 合并统一目录下的多语言srt文件，
 要合并的各语言字幕文件分别以语种简写为文件名，放在同一目录下，例如en.srt/zh.srt/fre.srt/es.srt/de.srt/ru.srt/jp.srt/ko.srt....
 最终输出文件为merge.srtx
 @param directory 目录地址
 @param orgLan 源语言名称简写 en/zh/es....
 @return 合并后的文件路径
 最终输出文件为merge.srtx，在当前目录下
 合并规则说明：
 首先会读取目录下merge.srtx文件，
 -  merge.srtx存在;将其他“没有合并过的”语言字幕合并到merge.srtx文件，例如merge.srtx中包含了en/zh/ko三种语言，那么将忽略掉目录下en.srt, zh.srt, ko.srt，只合并其他语种文件到merge.srtx
 -  merge.srtx不存在，则首先读取orgLan语种文件，然后再和其他语种文件进行合并，最终输出 merge.srtx文件
 如果要重新合并，把目录下的 merge.srtx删除的就可以
 */
+(NSString *)mergeLinesAtDirectory:(NSString *)directory withOriginLan:(nonnull NSString*)orgLan {
    
    NSArray <LanguageModel *> *allLanDic = [LanguageModel availableLans];
    
    NSString *mergeSrtxPath = [directory stringByAppendingPathComponent:MERGE_SRTS_FILE_NAME];
    NSString *srtxLan;
    NSArray<SrtxLine *> *mergedLines = [self parseSrtxString:[self readStringFromFile:mergeSrtxPath] withOriginalLan:&srtxLan];
   
    NSSet *preMergedLan = nil;//执行此方法前，已经存在merge.srtx中合并的语种
    if(mergedLines.count > 0 && [srtxLan isEqualToString:orgLan])  //merge.srtx文件存在且合法
    {
        SrtxLine *l = mergedLines.firstObject;
        NSMutableSet *mLanSet = [NSMutableSet setWithArray:l.polyglotLines.allKeys];
        
        for(int i=0; i<8; i++) {
            l = [mergedLines objectAtIndex:rand()%mergedLines.count];
            [mLanSet addObjectsFromArray:l.polyglotLines.allKeys];
        }
        
        preMergedLan = mLanSet;
    }
    else {
        NSString *orgSrtFile = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.srt",orgLan]];
        mergedLines = [self parseSrtxString:[self readStringFromFile:orgSrtFile] withOriginalLan:nil];
        
    }
    
    for(LanguageModel *lanmodel in allLanDic) {
        @autoreleasepool {
            
            NSString *lan = lanmodel.shortName;
            
            if([preMergedLan containsObject:lan])
                continue;
            
            if([lan isEqualToString:orgLan]) //进入循环前，就已经读取解析过来，所以这里跳过源语言字幕文件
                continue;
            
            NSString *expectedFile = [directory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.srt",lan]];
            NSArray *lines = [self parseSrtxString:[self readStringFromFile:expectedFile] withOriginalLan:nil];
            if(lines.count > 0)
                mergedLines = [self mergeOriginalSrt:mergedLines setOriginalLan:orgLan withSrtLines:lines ofTransLan:lan];
        }
    }

    NSError *e;
    if(mergedLines.count > 0)
    {
        //--------- 处理连续的插入翻译语种字幕开始
        //如果有连续的插入的字幕(也就是没有原语言的字幕)，将这些连续的相邻的插入的各种语言的字幕进行合并
        NSMutableArray *tocombineTransLines = [NSMutableArray arrayWithCapacity:3];
        NSMutableArray *processedLines = [NSMutableArray arrayWithArray:mergedLines];
        
        for(SrtxLine *trsLine in mergedLines) {

            if([trsLine.polyglotLines objectForKey:orgLan]) {

                if(tocombineTransLines.count > 1) {

                    [processedLines removeObjectsInArray:tocombineTransLines];
                    SrtxLine *lo = [self mergeSrtxLinesToOne:tocombineTransLines];
                    if(lo) {
                        NSUInteger i = [processedLines indexOfObject:trsLine];
                        [processedLines insertObject:lo atIndex:i];
                    }
                }
                
                [tocombineTransLines removeAllObjects];
            }
            else {
                [tocombineTransLines addObject:trsLine];
            }
        }

        if(tocombineTransLines.count > 1) {

            [processedLines removeObjectsInArray:tocombineTransLines];
            SrtxLine *lo = [self mergeSrtxLinesToOne:tocombineTransLines];
            if(lo)
                [processedLines addObject:lo];
        }
        //--------- 处理连续的插入翻译语种字幕完毕
        
        [self saveSrtxLines:processedLines withOriginalLan:orgLan toFile:mergeSrtxPath error:&e];
#if DEBUG
        if(e)
            NSLog(@"Failed Write merge data to file %@",e);
        else
            NSLog(@"Finished Merge All SRT to file: %@",mergeSrtxPath);
#endif
        if(e)
            return nil;
        else
            return mergeSrtxPath;
    }
    else {
#if DEBUG
        NSLog(@"ERROR None lines in merge file");
#endif
        return nil;
    }
}

//对字幕进行分割
+(NSArray <NSArray<SrtxLine *> *>*)splitSrtLines:(NSArray<SrtxLine *>*)lines byTime:(NSArray<NSNumber *> *)splitTimes
{
    splitTimes = [splitTimes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        if(obj2.doubleValue > obj1.doubleValue)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
    
    NSUInteger t_len = splitTimes.count;
    NSUInteger l_len = lines.count;
    NSTimeInterval t0 = 0, t1 = 0;
    NSUInteger preIdx = 0;
    NSUInteger j = 0;
    SrtxLine *line_ = nil;
    NSMutableArray<NSArray <SrtxLine *>*> *groups = [NSMutableArray arrayWithCapacity:splitTimes.count+1];

     for(NSUInteger i=0; i <= t_len; i++) {

         if(i<t_len)
             t1 = splitTimes[i].doubleValue;
         else {
             t1 = lines[l_len-1].endSecond + 1;
             if(t1 < t0) //最后一段字幕，及时时间有错误，也可以不管，设定一个最大结束时间就可以了
                 t1 = CGFLOAT_MAX;
         }
     
     //    console.log(i+': split: '+ t0 + '->'+t1);
#if DEBUG
        NSLog(@"%zu: split %@ -> %@",i,[self srtxTimeStringFromValue:t0],[self srtxTimeStringFromValue:t1]);
#endif
         for(; j < l_len; j++) {
             line_ = lines[j];
             if(line_.startSecond >= t1) {
                 NSUInteger a_len = j-preIdx;
                 NSArray<SrtxLine *>* sub_lines = [lines subarrayWithRange:NSMakeRange(preIdx, a_len)]; //lines.slice(preIdx, j);
               //  groups[i] = sub_lines;
                 if(sub_lines.count > 0)
                     [groups addObject:sub_lines];
              //   console.log('finished group:'+i+' preIdx:'+preIdx+' j=' + j + ' len:' + a_len);
#if DEBUG
                 NSLog(@"finished group:%zu preIdx:%zu j=%zu  len:%zu sub_lines.count:%zu",i,preIdx,j,a_len,sub_lines.count);
#endif
                 preIdx = j;
                 break;
             }
             line_.startSecond -= t0;
             line_.endSecond -= t0;
         }
         t0 = t1;
     }
    
//    groups[t_len] = lines.slice(preIdx);
   NSArray *leftLines = [lines subarrayWithRange:NSMakeRange(preIdx, lines.count-preIdx)];
    if(leftLines.count > 0)
        [groups addObject:leftLines];
    
#if DEBUG
    NSLog(@"finished split into %zu segments",groups.count);
#endif
    
    if(groups.count > 0)
        return groups;
    else
        return nil;
}

//返回分割后字幕的路径
+(nullable NSArray <NSString *>*)splitSrtxFileAtPath:(nonnull NSString *)path
                                             byTimes:(nonnull NSArray<NSString *> *)splitTimes
                                            errorMsg:(NSString **)errorMsg
{
    if(splitTimes.count == 0)
        return @[path];
    
    NSMutableArray *tArray = [NSMutableArray arrayWithCapacity:splitTimes.count];
    
    for(NSString *s in splitTimes) {
        NSTimeInterval t = [self timeFromSrtxTimeString:s];
        if(isnan(t))
            continue;
        [tArray addObject:[NSNumber numberWithDouble:t]];
    }
    
    if(tArray.count == 0) {
        if(errorMsg)
            *errorMsg = @"No split time have been defined";
        return nil;
    }

    
    NSString *orgLan;
    NSArray<SrtxLine *> *lines = [self parseSrtxString:[self readStringFromFile:path] withOriginalLan:&orgLan];
    if(lines.count == 0){
        if(errorMsg)
            *errorMsg = @"No Lines parsed in original srtx file";
        return nil;
    }
    
    NSArray <NSArray<SrtxLine *> *>* splitGroups = [self splitSrtLines:lines byTime:tArray];
    if(splitGroups.count == 0) {
        
        if(errorMsg)
            *errorMsg = @"No Lines splited into defined time ranges";
        return nil;
    }
    
    NSMutableArray *mPathes = [NSMutableArray arrayWithCapacity:splitGroups.count];
    int i = 1;
    for(NSArray<SrtxLine *> *segs in splitGroups) {
        
        NSString *dir = [path stringByDeletingLastPathComponent];
        NSString *preName = [path lastPathComponent];
        NSString *fName =[NSString stringWithFormat:@"%@_%02d.srt",[preName stringByDeletingPathExtension],i];
        NSString *destPath = [dir stringByAppendingPathComponent:fName];
        NSError *e;
        [self saveSrtxLines:segs withOriginalLan:orgLan toFile:destPath error:&e];
        
        if(e) {
            
            if(errorMsg)
                *errorMsg = [NSString stringWithFormat:@"Save srt to %@ with error:%@",destPath,e];
            return nil;
        }
        
        [mPathes addObject:destPath];
        i++;
    }
    
    return mPathes;
    
}

//对字幕重新排序，对时间有重叠的字幕进行合并或调整处理
+(NSArray <SrtxLine *> *)fixLineOrderAndLappedTime:(NSArray <SrtxLine *> *)lines {
    if(lines.count < 3)
        return lines;
    
    //排序
   lines = [lines sortedArrayUsingComparator:^NSComparisonResult(SrtxLine *obj1, SrtxLine *obj2) {
        
        if(obj2.startSecond > obj1.startSecond)
            return NSOrderedAscending;
        else
            return NSOrderedDescending;
    }];
    
    NSUInteger c = lines.count;
    SrtxLine *l0 = lines[0];
    SrtxLine *l1 = nil;
    SrtxLine *mergedLine;
    double lapped = 0;

    NSMutableArray *fixedLines = [NSMutableArray arrayWithCapacity:lines.count];
    for(int i=1; i<c; i++) {
        
        l1 = lines[i];
        mergedLine = nil;
        lapped = l0.endSecond - l1.startSecond;
        double dur0 = l0.endSecond - l0.startSecond;
        double dur1 = l1.endSecond - l1.startSecond;
        if(lapped > 0.001) {
            //重叠时间大于1秒,或者重叠部分达到一定比例
            if(lapped > 2 || lapped > dur1*0.3 || lapped > dur0*0.3)
            {
                mergedLine = [self mergeSrtxLinesToOne:@[l0,l1]];
            }
            else //调整开始/结束时间
            {
                l0.endSecond -= lapped/2;
                l1.startSecond += (lapped/2+0.1);
            }
        }
        
        if(mergedLine) {
           // [fixedLines addObject:mergedLine];//合并后不需添加，等下一次循环的时候添加
            l0 = mergedLine;
        }
        else {
            
            [fixedLines addObject:l0];
            l0 = l1;
        }
    }
    
    [fixedLines addObject:l0];
    
    return fixedLines;
}

+(NSString *)logSuitableSplitTimePoints:(NSString *)srtFilePath {
    
    NSArray<SrtxLine *> *lines = [self parseSrtxString:[self readStringFromFile:srtFilePath] withOriginalLan:nil];
    NSUInteger c = lines.count;
    
    if(c == 0)
        return @"No Lines found";
    
    NSMutableString *mStr = [NSMutableString stringWithCapacity:1024*2];
    
    SrtxLine *l1 = lines[0];
    SrtxLine *l2 = nil;
    for(NSUInteger i=1; i<c; i++) {
        l2 = lines[i];
        if(l2.startSecond - l1.endSecond > 5) {
            [mStr appendFormat:@"\ninterval:%.1f (%zu -> %zu) \n%@| |%@\n", l2.startSecond-l1.endSecond,l1.lineNum, l2.lineNum, [self srtxTimeStringFromValue:l1.endSecond],[self srtxTimeStringFromValue:l2.startSecond]];
        }
        l1 = l2;
    }
    
    return [NSString stringWithString:mStr];
}

+(NSArray <SrtxLine *> *)findAbnormalTimelineLines:(NSArray <SrtxLine *> *)lines {
    
    if(lines.count < 2)
        return nil;
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:lines.count/10];
    SrtxLine *preLine = lines[0];
    for(int i=1; i<lines.count; i++) {
        SrtxLine *l = lines[i];
        if(l.startSecond - preLine.endSecond < -INNER_TIME_ESP) {
            [ma addObject:preLine];
        }
        preLine = l;
    }
    
    return ma;
}

+(void)findAbnormalTimelineLinesAtPath:(NSString *)srtPath toFile:(NSString *)exceptionPath {
    NSString *lan;
    NSArray *lines = [self parseSrtxString:[self readStringFromFile:srtPath] withOriginalLan:&lan];
    NSArray *errorlines = [self findAbnormalTimelineLines:lines];
    if(errorlines.count > 0) {
        NSMutableString *srtFileStr = [[NSMutableString alloc] initWithCapacity:1024*100];
        
        for(SrtxLine *l in errorlines) {
            l.lineNum = [lines indexOfObject:l] + 1;
            [srtFileStr appendFormat:@"%@\n\n",l.formarttedLineString];
        }
        [srtFileStr writeToFile:exceptionPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    else {
        NSString *msg = @"all lines' timeline are in order";
        NSLog(@"%@ %@",msg,srtPath.lastPathComponent);
     //   [msg writeToFile:exceptionPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

+(NSString *)exportTextFileWithSrtxLines:(nonnull NSArray<SrtxLine *>*)lines withLans:(NSArray <NSString *>*)lans toFile:(NSString *)path error:(NSError **)e {
    NSMutableString *mString = [NSMutableString stringWithCapacity:1024*1024*200];
    for(SrtxLine *l in lines) {
        for(NSString *lan in lans) {
            NSString *c = [l.polyglotLines objectForKey:lan];
            if(c)
                [mString appendFormat:@"%@\n",c];
        }
        
        [mString appendString:@"\n"];
    }
    
    if(mString.length > 0)
    {
       NSString *s = [NSString stringWithFormat:@"====App商店搜索下载Tinglee,以获得最佳听力体验====\n\n%@",mString];
        [s writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:e];
        return s;
    }
    
    return nil;
}




/*
 将portionPath的字幕内容时间偏移(减)segStart秒后，替换掉fullPath字幕中，从segStart到segEnd范围内的字幕，
 */
+(NSString *)replaceSrtx:(NSString *)fullPath from:(NSTimeInterval)segStart to:(NSTimeInterval)segEnd withPortionSrtx:(NSString *)portionPath {
    
    NSString *lan;
    NSArray *fullLines = [self parseSrtxFile:fullPath withOriginalLan:&lan];
    NSArray *portionLines = [self parseSrtxFile:portionPath withOriginalLan:&lan];
    NSMutableArray *mLines = [NSMutableArray arrayWithArray:fullLines];
    
    int i = 0, j=0;
    for(SrtxLine *l1 in fullLines) {
        
        if(l1.startSecond >= segStart && l1.startSecond < segEnd) {
            
            if(j >= portionLines.count)
                break;
            
            SrtxLine *l2 = [portionLines objectAtIndex:j];
            l2.startSecond += segStart;
            l2.endSecond += segStart;
    
            [mLines replaceObjectAtIndex:i withObject:l2];
            
            j++;
        }
        
        i++;
    }
    
    NSString *path = [[fullPath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@_new.srtx",[fullPath.lastPathComponent stringByDeletingPathExtension]];
    NSError *e;
    [self saveSrtxLines:mLines withOriginalLan:lan toFile:path error:&e];
    if(e)
        return nil;
    else
        return path;
    
}

#pragma mark- lrc

+(NSTimeInterval )getTimeOffsetFromLrcContent:(NSString *)lrcContent
{
    NSInteger len = [lrcContent length];
    NSRange range = [lrcContent rangeOfString:timeOffsetTagRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, len)];
    if(range.location == NSNotFound || range.length == 0)
    {
        return 0.0;
    }
    NSString *offsetTag = [lrcContent substringWithRange:range];
    
    NSArray* parts = [offsetTag componentsSeparatedByString:@":"];
    NSString *str = [parts objectAtIndex:1];
    NSString *timeStr = [str substringWithRange:NSMakeRange(0,[str length]-1)];
    NSInteger msec = timeStr.integerValue;
    NSTimeInterval offset = (NSTimeInterval)msec/1000;
    return offset;
}

+(NSTimeInterval)timeSecondFromLrcTag:(NSString *)tag
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

+(NSArray<LrcLine *> *)parseLrcString:(NSString *)lrcContent
{
    NSString *str1;
    NSTimeInterval offset;
    
    if (lrcContent == nil)
    {
        NSLog(@"can not parse lrc bcs lrc not found");
        return nil;
    }
    
    NSMutableArray *CtrlInfoArray=[NSMutableArray array];
    
    offset = [self getTimeOffsetFromLrcContent:lrcContent];
   // NSLog(@"offset:%f",offset);
    
    NSRegularExpression* regex = [[NSRegularExpression alloc]initWithPattern:lrcLineRgexp options:0 error:nil];
    NSArray* chunks = [regex matchesInString:lrcContent options:0 range:NSMakeRange(0, [lrcContent length])];
    
    NSInteger i=0;
    for (NSTextCheckingResult* b in chunks)
    {
        str1 = [lrcContent substringWithRange:b.range];
        NSArray *array = [self parseLrcLine:str1 withTimeOffset:offset andIndex:i++];
        if(array)
            [CtrlInfoArray addObjectsFromArray:array];
    }
    
    [CtrlInfoArray sortUsingComparator:^NSComparisonResult(LrcLine * obj1, LrcLine * obj2) {
       return (obj1.second > obj2.second ? NSOrderedDescending:NSOrderedAscending);
    }];
    
    return [NSArray arrayWithArray:CtrlInfoArray];
}

//used to parse lines that actually with time tag only
+(NSArray <LrcLine *>*) parseLrcLine:(NSString *)line withTimeOffset:(NSTimeInterval)offset andIndex:(NSInteger)index
{
    NSInteger /*loc = 0,*/ tidx = 0;
    NSInteger len = [line length];
    NSRange range,subrang;
    NSMutableArray *maray = [NSMutableArray arrayWithCapacity:2000];
    NSMutableString *lrcStr=[[NSMutableString alloc]initWithString:line];
    NSString *str1;
    
    while (1)
    {
        range = [lrcStr rangeOfString:lrcTagRgexp options:NSRegularExpressionSearch range:NSMakeRange(0, len)];

        len = len - range.length;
        
        if(range.location == NSNotFound || range.length == 0)
        {
            for(LrcLine *l in maray)
            {
                l.content = lrcStr;
            }
            break;
        }
        
        str1 = [lrcStr substringWithRange:range];
        subrang = [str1 rangeOfString:lrcTimeRgexp options:NSRegularExpressionSearch];
        if(subrang.location!=NSNotFound && subrang.length!=0) //time
        {
            LrcLine *line = [[LrcLine alloc] init];
            NSTimeInterval sec = [self timeSecondFromLrcTag:str1];
            sec+=offset;
            line.second =sec;
            line.timeTagIndex = tidx++;
            line.lineIndex = index;
           
            [maray addObject:line];
        }
        [lrcStr deleteCharactersInRange:range];
    }
    
    return maray;
}

+(nullable NSArray <NSArray<LrcLine *>*>*)splitLrcFromLrcString:(NSString *)lrcString wihtSplitTimePos:(nonnull NSArray <NSNumber *> *)secPoses
{
    NSArray *allLines = [self parseLrcString:lrcString];
    
    if(secPoses.count == 0)
        return allLines;
    
    NSMutableArray *timeSplits = [NSMutableArray arrayWithArray:secPoses];
    [timeSplits sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2)
     {
         return (obj1.floatValue > obj2.floatValue ? NSOrderedDescending:NSOrderedAscending);
     }];
    
    NSMutableArray *parts = [NSMutableArray arrayWithCapacity:secPoses.count+1];
    
    NSTimeInterval currentSearchTime = secPoses.firstObject.doubleValue;
    NSTimeInterval lastSplitTime = 0.000;
    NSUInteger idx = 0;
    NSUInteger curPartStartIndex = 0;
    NSUInteger currentPosIdx = 0;
    NSTimeInterval orTime;
    BOOL lastSeg = NO;//最后一段
    for(LrcLine *line in allLines)
    {
        orTime = line.second;
        line.second -= lastSplitTime;
        if(orTime >= currentSearchTime && !lastSeg)
        {
            lastSplitTime = currentSearchTime;
            NSArray *segs;
//            if(fabs(orTime - currentSearchTime) < 0.0001)
//            {
//                segs = [allLines subarrayWithRange:NSMakeRange(curPartStartIndex, idx-curPartStartIndex+1)];
//                curPartStartIndex = idx+1;
//            }
//            else
            {
                segs = [allLines subarrayWithRange:NSMakeRange(curPartStartIndex, idx-curPartStartIndex)];
                curPartStartIndex = idx;
                line.second = orTime - lastSplitTime;
            }
            
            [parts addObject:segs];
            
            
            currentPosIdx++;
            if(currentPosIdx >= secPoses.count)//如果是最后一个分割点
            {
                lastSeg = YES;
            }
            else
            {
                currentSearchTime = [secPoses objectAtIndex:currentPosIdx].doubleValue;
            }
            
        }
        
        idx++;
    }
    
    //如果遍历结束，还没有分割到最后一个时间段，说明有分割时间点大于lrc的最大时间
    if(curPartStartIndex < allLines.count)//其实这里永远都是true
    {
        NSArray *segs = [allLines subarrayWithRange:NSMakeRange(curPartStartIndex, allLines.count-curPartStartIndex)];
        [parts addObject:segs];
    }
    
    return parts;
}
+(NSError *)saveLrcLines:(nonnull NSArray <LrcLine *>*)lrcLines toFile:(nonnull NSString *)path
{
    NSError *error = nil;
    NSMutableString *mStr = [NSMutableString string];
    for(LrcLine *line in lrcLines)
    {
        [mStr appendFormat:@"%@%@\r\n",[self lrcTimeTagStringForTime:line.second],line.content];
    }
    
    if(mStr.length > 0)
    {
        NSData *data = [mStr dataUsingEncoding:NSUTF8StringEncoding];
        [data writeToFile:path options:NSDataWritingAtomic error:&error];
    }
    else
        error = [NSError errorWithDomain:@"No LRC file data" code:-999 userInfo:nil];
    
    return error;
}

@end


//计算t0->t1和T0->T1之间的重叠时间
NSTimeInterval timeLapCal(NSTimeInterval t0,NSTimeInterval t1,NSTimeInterval T0,NSTimeInterval T1) {
    
    if(T0 >= t0 && T1 <= t1)
        return T1 - T0;
    
   if(T0 <= t0 && T1 >= t1)
       return t1 - t0;
    
    if(T0<=t0 && T1>=t0) {
        return MIN(T1, t1) - t0;
    }
    
    if(T0<=t1 && T1>=t1) {
        return t1 - MAX(T0, t0);
    }
    
    return 0;
}
