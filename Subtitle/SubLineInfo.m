//
//  LrcCntrlInfo.m
//  English Listener
//
//  Created by 亮富 罗 on 12-2-28.
//  Copyright (c) 2012年 南昌大学. All rights reserved.
//

#import "SubLineInfo.h"

@implementation SubLineInfo
{
    NSString *_mainLine;
    NSString *_transLine;
    
    NSMutableAttributedString *_attriString;//为了老版本，以后废弃
}

@synthesize mainLine = _mainLine;
@synthesize transLine = _transLine;
@synthesize srtx_line = _srtx_line;
-(id) init
{
    self = [super init];
    if(self)
    {
        self.timeTag = 0;
        self.markLevel = 0;
    
    }
    return  self;
}

-(nonnull instancetype)initWithSrtxLine:(SrtxLine *)srtx {
    
    self = [super init];
    if(self) {
        self.type = SubLineSrtxType;
        _srtx_line = srtx;
        self.timeTag = srtx.startSecond;
        self.lastDuration = srtx.endSecond - srtx.startSecond;
        self.markLevel = srtx.markLevel;
    }
    return self;
}

-(nonnull instancetype)initWithLrcLine:(nullable LrcLine *)lrc {
    self = [super init];
    if(self) {
        self.type = SubLineSrtxType;
        self.timeTag = lrc.second;
        self.lastDuration = 1;
        
        NSArray *lines = [lrc.content componentsSeparatedByString:LINE_BREAK];
        if(lines.count>0)
            self.mainLine = lines.firstObject;
        
        if(lines.count>1)
            self.transLine = lines[1];
    }
    return self;
}

-(NSTimeInterval)timeEnds {
    return self.timeTag + self.lastDuration;
}


////为了老版本兼容
//-(NSMutableAttributedString *)lrcAttrStr
//{
//    if(!_attriString)
//        _attriString = [[NSMutableAttributedString alloc]initWithString:self.content];
//    return _attriString;
//}


@end
