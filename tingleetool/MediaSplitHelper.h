//
//  MediaSplitHelper.h
//  tingleetool
//
//  Created by 罗亮富 on 2020/8/21.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MediaSplitHelper : NSObject


/*
* 分割srt,并把分割时间点需要的信息返回
* @para path srt(x)文件路径
* @para duration 单位秒，每一段分割预期时间的长度
* @para trims 是否自动去掉第一句字幕开始之前的时间，会预留1-2秒的开头时间
*/
+(NSDictionary *)splitTimePointWithSrtFile:(NSString *)path
                   expectedSegmentDuration:(int)duration
                                 trimStart:(BOOL)trims;

//分割音/视频的ffmpeg命令，splitsInfo为分割信息，分割信息来自+splitTimePointWithSrtFile:expectedSegmentDuration:trimStart:产生
+(NSArray<NSString *> *)splitMediaFFmpegCmdWithSplitInfo:(NSDictionary *)splitsInfo
                                                    file:(NSString *)filePath;

//分割音/视频的ffmpeg命令，times：分割时间点 trimBeginning：去掉开头部分时间
+(NSArray<NSString *> *)splitMediaFFmpegCmdWithSplitPoints:(NSArray<NSNumber *>*)times
                                                      file:(NSString *)filePath
                                             trimBeginning:(NSTimeInterval)trimBeginning;

@end

NS_ASSUME_NONNULL_END
