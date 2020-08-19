//
//  SubLineManager.m
//  YingYuTingTing
//
//  Created by 罗亮富 on 2019/5/26.
//

#import "SubLineManager.h"


@implementation SubLineManager
@synthesize filePath = _filePath;
@synthesize transLanSetting = _transLanSetting;
@synthesize orgLan = _orgLan;
@synthesize lineCount = _lineCount, allWords = _allWords, lineDuration = _lineDuration;


-(instancetype)initWithFile:(NSString *)filePath {
    self = [super init];
    _transLanSetting = [LanguageModel preferedTransLan];
    _filePath = filePath;
    NSString *fName = filePath.lastPathComponent;

    if([[fName.pathExtension lowercaseString] isEqualToString:@"lrc"]
       || [[fName lowercaseString] hasSuffix:@"lrc.ytenc"]
       )
        _lineType = SubLineLrcType;
    else// if([[fName.pathExtension lowercaseString] hasPrefix:@"srt"]) 从cloudkit下载的文件是没有文件后缀的
        _lineType = SubLineSrtxType;
    
    return self;
}

-(NSArray<SubLineInfo *> *)parseFile {
    if(_lineType == SubLineLrcType) {
        if(!_lrcMMg)
            _lrcMMg = [[LrcManager alloc] initWithLrcFile:_filePath];
        
        _subLines = [_lrcMMg parseLrc];
    }
    else if(_lineType == SubLineSrtxType) {
        NSString *text = [SubTitleProcess readStringFromFile:_filePath];
        NSString *ol = nil;
        NSArray *srtLines = [SubTitleProcess parseSrtxString:text withOriginalLan:&ol];
        if(!_orgLan)
            _orgLan = ol;
        
        NSString *mainLan = _orgLan ? _orgLan:LAN_UNDEFINED;

        NSMutableArray *mLines = [NSMutableArray arrayWithCapacity:srtLines.count*2];
        SrtxLine *lastLine = nil;
     //   SubLineInfo *preSubLine = nil;
        NSTimeInterval dur = 0;
        for(SrtxLine *curLine in srtLines) {

            dur = curLine.startSecond - lastLine.endSecond;
            SubLineInfo *linfo = [[SubLineInfo alloc] initWithSrtxLine:curLine];
            linfo.mainLine = [curLine.polyglotLines objectForKey:mainLan];
            if(self.transLanSetting && ![self.orgLan isEqualToString:self.transLanSetting])
                linfo.transLine = [curLine.polyglotLines objectForKey:self.transLanSetting];
            
         //   preSubLine.nextLineStartTime = linfo.timeTag;
            
            [mLines addObject:linfo];
            
            lastLine = curLine;
          //  preSubLine = linfo;
        }
//        //最后再加一句空行
//        SubLineInfo *lastblankLine = [[SubLineInfo alloc] initWithSrtxLine:nil];
//        lastblankLine.timeTag = lastLine.endSecond;
//        lastblankLine.lastDuration = INSERT_BLANK_LINE_MIN_INTERVAL;
//        [mLines addObject:lastblankLine];
        
        _subLines = [mLines copy];
    }
    
    [self lineStatistics];
    
    return [_subLines copy];
}

-(void)saveLinesToFileCompletion:(void (^)(BOOL sucess))completion {
    [self saveLinesToFile:self.filePath completion:completion];
}

#warning 这个方法要优化，只是为了兼容之前的代码，后续要直接保存srt line，现在经过SubLineInfo两次转换难免会出错
-(void)saveLinesToFile:(NSString *)filePath completion:(void (^)(BOOL sucess))completion {
    
    if(_lrcMMg)
        [_lrcMMg saveToFile:filePath completion:completion];
    else if(_lineType == SubLineSrtxType)  {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            NSMutableArray *srtxLines = [NSMutableArray arrayWithCapacity:_subLines.count];
            
            int i = 0;
            SrtxLine *toWriteLine = nil;
            NSString *mainKey = _orgLan ? _orgLan:LAN_UNDEFINED;
            for(SubLineInfo *l in _subLines) {
                
                toWriteLine = l.srtx_line;
                //有的字幕没有原语言和对应当前语言的翻译语言，但却有其他语言的翻译，这时候l.srtx_line是有的
                if(l.mainLine.length > 0 || l.transLine.length > 0 || l.srtx_line)
                {
                    i++;
                    
                    if(!toWriteLine)
                        toWriteLine = [SrtxLine new];
                    
                    toWriteLine.lineNum = i;
                    toWriteLine.startSecond = l.timeTag;
                    toWriteLine.endSecond = l.timeTag + l.lastDuration;
                    toWriteLine.markLevel = l.markLevel;
                    
                    
                    if(!toWriteLine.polyglotLines)
                        toWriteLine.polyglotLines = [NSMutableDictionary dictionaryWithCapacity:2];
                        
                
                    if(l.mainLine)
                        [toWriteLine.polyglotLines setObject:l.mainLine forKey:mainKey];

                    if(l.transLine ) {
                        if(self.transLanSetting && ![mainKey isEqualToString:LAN_UNDEFINED]) //单独
                            [toWriteLine.polyglotLines setObject:l.transLine forKey:self.transLanSetting];
                        else //追加到主字幕
                            [toWriteLine.polyglotLines setObject:[NSString stringWithFormat:@"%@\n%@",l.mainLine,l.transLine] forKey:mainKey];
                    }
                   
                }
                else {
//#if DEBUG
//                    NSLog(@"skip blank line:%@ polyglotLines:%@",toWriteLine.formarttedLineString, toWriteLine.polyglotLines);
//#endif
                    //空白行有可能是插入的空白行，也有可能是没有mainLine和transLine，但是具有其他语言的translation
                }
                
                if(toWriteLine.polyglotLines.count > 0)
                    [srtxLines addObject:toWriteLine];
            }
            
            NSError *err;
            [SubTitleProcess saveSrtxLines:srtxLines withOriginalLan:_orgLan toFile:filePath error:&err];

            dispatch_async(dispatch_get_main_queue(), ^{
                if(completion)
                    completion(err==nil);
            });
        });
    }
}

-(void)exportTextToFile:(NSString *)filepath completion:(void (^)(NSString *, NSError *))compleHandle {
    
     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
         NSMutableString *mStr = [NSMutableString stringWithCapacity:1024*1024*400];
         for(SubLineInfo *l in self.subLines) {
             if(l.mainLine)
                 [mStr appendFormat:@"%@\n",l.mainLine];
             if(l.transLine)
                 [mStr appendFormat:@"%@\n",l.transLine];
             
             [mStr appendString:@"\n"];
         }
         
         [mStr insertString:@"=====学英语下载英语听听app，关注公众老罗说英语=====\n\n" atIndex:0];
         NSError *e;
         [mStr writeToFile:filepath atomically:YES encoding:NSUTF8StringEncoding error:&e];
         if(compleHandle) {
            dispatch_async(dispatch_get_main_queue(), ^{
                compleHandle(mStr,e);
             });
         }
     });
}

-(NSSet *)allLans {
    
    NSMutableSet *lans = [NSMutableSet setWithCapacity:15];
    
    NSArray *sbls = [_subLines copy];
    NSUInteger c = sbls.count;
    for(NSUInteger i=0; i<15; i++)
    {
        SubLineInfo *sl = [sbls objectAtIndex:rand()%c];
        NSArray *subLans = [sl.srtx_line.polyglotLines allKeys];
        [lans addObjectsFromArray:subLans];
    }
    
    return [lans copy];
}

-(void)setTransLanSetting:(NSString *)transLan {
    if(![_transLanSetting isEqualToString:transLan]) {
        
        if(_lineType == SubLineSrtxType) {
            _transLanSetting  = [transLan copy];
            
            NSArray *sbls = [_subLines copy];
            for(SubLineInfo *sl in sbls)
            {
                sl.transLine = [sl.srtx_line.polyglotLines objectForKey:_transLanSetting];
            }
        }
    }
}

-(void)setOrgLan:(NSString *)orgLan {
    
    if(![_orgLan isEqualToString:orgLan]) {
        
        if(_lineType == SubLineSrtxType) {
            _orgLan  = [orgLan copy];
            
            NSArray *sbls = [_subLines copy];
            for(SubLineInfo *sl in sbls)
            {
                sl.mainLine = [sl.srtx_line.polyglotLines objectForKey:_orgLan];
            }
        }
    }
}

+(BOOL)isSublineBackgroundLine:(SubLineInfo *)line {
    if(line.markLevel > 0)
        return NO;
    if(line.mainLine.length == 0)
        return YES;
    if([line.mainLine hasPrefix:@"#"] && [line.mainLine hasSuffix:@"#"] )
        return YES;
    if([line.mainLine hasPrefix:@"["] && [line.mainLine hasSuffix:@"]"] )
        return YES;
    if([line.mainLine hasPrefix:@"("] && [line.mainLine hasSuffix:@")"] )
        return YES;
    
    return NO;
}
//统计
-(void)lineStatistics {
    
    NSMutableArray *realLines = [NSMutableArray arrayWithCapacity:self.subLines.count*0.7];
    NSMutableSet *mset = [NSMutableSet setWithCapacity:3000];
    _lineDuration = 0;
    _lineCount = 0;
    
    for(SubLineInfo *l in self.subLines) {
        if(![[self class] isSublineBackgroundLine:l]) {
            _lineDuration += l.lastDuration;
            [realLines addObject:l];
        }
        
        if(l.mainLine.length > 0) {
            _lineCount++;
            [l.mainLine enumerateSubstringsInRange:NSMakeRange(0, l.mainLine.length) options:NSStringEnumerationByWords|NSStringEnumerationLocalized usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                if(substring)
                    [mset addObject:substring];
            }];
        }
        
        _allWords = [NSSet setWithSet:mset];
    }
    
}

@end
