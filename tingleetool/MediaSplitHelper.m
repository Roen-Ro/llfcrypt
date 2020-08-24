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
    
    if(beginOffset < 0)
        beginOffset = 0;

    NSTimeInterval s0 = 0.0;
    float r = 0.075;//时间允许浮动范围 15%
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
            
            NSLog(@"%d - split(index:%ld time:%@) curTime:%@ nextRange(%@ - %@) curMaxGap:%.1f",i+1,splitIndex,[SubTitleProcess srtxTimeStringFromValue:s0],[SubTitleProcess srtxTimeStringFromValue:l.startSecond],[SubTitleProcess srtxTimeStringFromValue: nexSegMin],[SubTitleProcess srtxTimeStringFromValue:nexSegMax],curMaxGap);
            
            curMaxGap = 0;
            continue;
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
        NSString *fName =[NSString stringWithFormat:@"%@_%02d",preName,x];
        NSString *dstPath = [path pathByReplaceingWithFileName:fName extention:nil];
        
        NSError *se;
        [SubTitleProcess saveSrtxLines:segs withOriginalLan:orgLan toFile:dstPath error:&se];
        
        if(se)
            NSLog(@"Error save %@ Failed!!!",dstPath);
        else
            NSLog(@"Saved %@",dstPath);
        
        x++;
    }
    
    
    //把分割时候偏移了的时间再补回去，提供给ffmpeg做分割
    NSMutableArray <NSNumber *>*points = [times mutableCopy];
    if(fabs(beginOffset) > 0.01) {
        for(int m=0; m<points.count; m++) {
            NSTimeInterval v = [points objectAtIndex:m].doubleValue + beginOffset;
            [points replaceObjectAtIndex:m withObject:@(v)];
        }
    }
    
    return @{@"trimBegin":@(beginOffset),@"splitPoints":points};
}


+(NSArray<NSString *> *)splitMediaFFmpegCmdWithSplitInfo:(NSDictionary *)splitsInfo
                                                    file:(NSString *)filePath {
    NSNumber *trimBegin = [splitsInfo objectForKey:@"trimBegin"];
    NSArray *splitPoints = [splitsInfo objectForKey:@"splitPoints"];
    return [self splitMediaFFmpegCmdWithSplitPoints:splitPoints file:filePath trimBeginning:trimBegin.doubleValue];
    
}

//分割音/视频的ffmpeg命令，times：分割时间点 trimBeginning：去掉开头部分时间
+(NSArray<NSString *> *)splitMediaFFmpegCmdWithSplitPoints:(NSArray<NSNumber *>*)times
                                                      file:(NSString *)filePath
                                                    trimBeginning:(NSTimeInterval)trimBeginning {
    
    int j = 1;
    NSMutableArray <NSNumber *> *ma = [times mutableCopy];
    if(trimBeginning > 0.1) {
        j = 0;
        [ma insertObject:@(trimBeginning) atIndex:0];
    }
    NSMutableArray *outCmds = [NSMutableArray arrayWithCapacity:ma.count];
    NSTimeInterval preEnd = 0.0;
    NSString *orgName = [filePath.lastPathComponent stringByDeletingPathExtension];
    for(int i=0; i <= ma.count; i++) {
        
        NSTimeInterval t = 0;
        NSTimeInterval d = 0;
        if(i < ma.count) {
            NSNumber *n = ma[i];
            t = n.doubleValue;
            d = t - preEnd;
        }
        else {
            //do nothing
        }

        
        NSString *fName =[NSString stringWithFormat:@"%@_%02d",orgName,j];
        NSString *destPath = [filePath pathByReplaceingWithFileName:fName extention:nil];
        
        NSString *cmd;
        NSString *ss = [NSString timeDisplayStringBySecond:preEnd];
        NSString *tt = [NSString timeDisplayStringBySecond:d];
        if(d>0.1)
            cmd = [NSString stringWithFormat:@"ffmpeg -y -ss %@ -t %@ -i %@ -vcodec copy -acodec copy %@",ss,tt,filePath,destPath];
        else
           cmd = [NSString stringWithFormat:@"ffmpeg -y -ss %@ -i %@ -vcodec copy -acodec copy %@",ss,filePath,destPath];
        [outCmds addObject:cmd];
        
        preEnd = t;
        j++;
    }
    
    return [outCmds copy];

}

@end
