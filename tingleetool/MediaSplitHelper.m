//
//  MediaSplitHelper.m
//  tingleetool
//
//  Created by 罗亮富 on 2020/8/21.
//  Copyright © 2020 roen. All rights reserved.
//

#import "MediaSplitHelper.h"
#import <RRUti/SubTitleProcess.h>
#import <RRUti/NSString+Utility.h>

@implementation MediaSplitHelper


/*
 * 分割srt,并把分割时间点需要的信息返回
 * @para path srt(x)文件路径
 * @para duration 单位秒，每一段分割预期时间的长度
 * @para trims 是否自动去掉第一句字幕开始之前的时间，会预留1-2秒的开头时间
 */
+(NSDictionary *)splitTimePointWithSrtFile:(NSString *)path expectedSegmentDuration:(int)duration trimStart:(BOOL)trims
{
    NSString *orgLan;
    NSArray<SrtxLine *> *lines = [SubTitleProcess parseSrtxString:[SubTitleProcess readStringFromFile:path] withOriginalLan:&orgLan];
    if(lines.count == 0)
        return nil;

    //计算自动去掉开头时间
    NSTimeInterval beginOffset = 0.0;
    if(trims)
        beginOffset = floor(lines.firstObject.startSecond) - 1;

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
        l.startSecond -= beginOffset;
        l.endSecond -= beginOffset;
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
            
     //       NSLog(@"%d - splitIndex:%ld l.startSecond:%.1f R(%.1f - %.1f) curMaxGap:%.1f",i,splitIndex,l.startSecond,nexSegMin,nexSegMax,curMaxGap);
            
            curMaxGap = 0;
        }
        
        if(i>0) {
            l0 = lines[i-1];
            NSTimeInterval gap = l.startSecond - l0.endSecond;
            if(curMaxGap < gap) {
                splitIndex = i;
                curMaxGap = gap;
            }
        }
    }
    
    NSMutableArray *times = [NSMutableArray arrayWithCapacity:20];
    for(NSNumber *n in ma) {
        SrtxLine *tl = lines[n.intValue];
        NSInteger t = floor(tl.startSecond) - 1;
        [times addObject:[NSNumber numberWithInteger:t]];
    }
        
    NSArray <NSArray<SrtxLine *> *>* groups = [SubTitleProcess splitSrtLines:lines byTime:times];

    int x = 1;
    for(NSArray<SrtxLine *> *segs in groups) {
        NSString *preName = [path.lastPathComponent stringByDeletingPathExtension];
        NSString *fName =[NSString stringWithFormat:@"%@_%02d.srt",preName,x];
        NSString *dstPath = [path pathByReplaceingWithFileName:fName extention:nil];
        
        NSError *se;
        [SubTitleProcess saveSrtxLines:segs withOriginalLan:orgLan toFile:dstPath error:&se];
        
        if(se)
            NSLog(@"Error save %@ Failed!!!",dstPath);
        else
            NSLog(@"Saved %@",dstPath);
        
        x++;
    }
    
    
    return nil;
}

@end
