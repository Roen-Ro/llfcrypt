//
//  MediaSplitHelper.m
//  tingleetool
//
//  Created by 罗亮富 on 2020/8/21.
//  Copyright © 2020 roen. All rights reserved.
//

#import "MediaSplitHelper.h"
#import <RRUti/SubTitleProcess.h>

@implementation MediaSplitHelper


/*
 * 分割srt,并把分割时间点需要的信息返回
 * @para path srt(x)文件路径
 * @para duration 单位秒，每一段分割预期时间的长度
 * @para trims 是否自动去掉第一句字幕开始之前的时间
 */
+(NSArray *)splitTimePointWithSrtFile:(NSString *)path expectedSegmentDuration:(int)duration trimStart:(BOOL)trims
{
    
    NSArray<SrtxLine *> *lines = [SubTitleProcess parseSrtxString:[SubTitleProcess readStringFromFile:path] withOriginalLan:nil];
    if(lines.count == 0)
        return nil;
    
    
    NSTimeInterval s0 = 0.0;
    float r = 0.15;//时间允许浮动范围 15%
    NSTimeInterval nexSegMin = 0; //下一段分割片段的最小时间
    NSTimeInterval nexSegMax = 0; //下一段分割片段的最大时间
    NSTimeInterval curMaxGap = 0.0;
    NSInteger splitIndex = -1;
    
    NSMutableArray *ma = [NSMutableArray arrayWithCapacity:20];
    
    
    SrtxLine *l0 = nil;
    SrtxLine *l = nil;
    int i = 0;
    for(; i<lines.count; i++) {
            l = lines[i];
        if(l.startSecond < nexSegMin)
            continue;
        
        //超出允许分割范围,保存分割字幕，重置下一段分割判断范围
        if(l.startSecond > nexSegMax) {
            if(splitIndex > 0) {
                [ma addObject:[NSNumber numberWithInteger:splitIndex]];
                s0 = [lines objectAtIndex:splitIndex].startSecond;
            }
            
            nexSegMin = s0+(1-r)*duration;
            nexSegMax = s0+(1+r)*duration;
            curMaxGap = 0;
        }
        
        i>0 ? (l0 = lines[i-1]) : (l0 = nil);
        NSTimeInterval gap = l.startSecond - l0.endSecond;
        if(curMaxGap < gap) {
            splitIndex = i;
            curMaxGap = gap;
        }
    }
    
    
    //去掉第一句字幕之前范围的数据
    if(trims) {
        
    }
    
    return nil;
}

@end
