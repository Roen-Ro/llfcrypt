//
//  LrcCntrlInfo.h
//  English Listener
//
//  Created by 亮富 罗 on 12-2-28.
//  Copyright (c) 2012年 南昌大学. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "GlobalDefine.h"

#define LINE_BREAK @"<br>"

#define LRC_MARK_DEAULT LRC_MARK_LOW
#define INITIAL_FRAME_HEIGHT 0.0

@interface SubLineInfo : NSObject// <NSCoding, NSCopying>
{
   
}

@property (strong,nonatomic) NSNumber *seconds __attribute__((deprecated("use timeTag")));
@property CTFrameRef paintframe __attribute__((deprecated("no longer available"))); //must be released on exit
@property CGRect    filledFrameRect __attribute__((deprecated("no longer available")));


@property (strong,nonatomic) NSMutableAttributedString *lrcAttrStr; //这个设计思路不好，暂时用来保存attributedstring, 后续优化


@property (copy,nonatomic) NSString *constructedContent;
@property (nonatomic,nonnull,readonly,strong) NSString *mainLine;
@property (nonatomic,nullable,readonly,strong) NSString *subLine;

@property LrcMarkLevel  markLevel;
@property NSInteger originalIndex __attribute__((deprecated("to be deprecated"))); //original index in file bfore been parsed
@property NSInteger timeTagIndex __attribute__((deprecated("to be deprecated")));//有的时候，一句台词包含有多个时间标签，这句用来表明当前是属于第几个时间标签

@property (nonatomic) NSTimeInterval timeTag; //start time in second
@property (nonatomic) NSTimeInterval lastDuration;

 //用于缓存tableViewCell的行高
@property (nonatomic)  CGFloat mainLineHight;
@property (nonatomic)  CGFloat subLineHeight;


-(void)cleanUp;

@end
