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
#import "SubTitleProcess.h"




#define LRC_MARK_DEAULT LRC_MARK_LOW
#define INITIAL_FRAME_HEIGHT 0.0

typedef enum {
    SubLineUnknowType = 0,
    SubLineLrcType,
    SubLineSrtxType
}SubLine_type;

//由以前的LrcInfo改过来的，以前是用来保存放lrc信息，现在可以支持lrc，srtx字幕
@interface SubLineInfo : NSObject// <NSCoding, NSCopying>
{
   
}

@property (strong,nonatomic) NSMutableAttributedString *lrcAttrStr; //这个设计思路不好，暂时用来保存attributedstring, 后续优化

//@property (copy,nonatomic) NSString *constructedContent;
@property (nonatomic,nullable,strong) NSString *mainLine; //主字幕
@property (nonatomic,nullable,strong) NSString *transLine; //翻译字幕
@property (nonatomic,readonly,nullable) SrtxLine *srtx_line;

@property int  markLevel; //-1 隐藏 0 正常，其他正值表示标记等级
@property (nonatomic) SubLine_type type;

@property (nonatomic) NSTimeInterval timeTag; //start time in second
@property (nonatomic) NSTimeInterval lastDuration;
@property (nonatomic,readonly) NSTimeInterval timeEnds;//播放结束时间 timeTag+lastDuration


 //用于缓存tableViewCell的行高
@property (nonatomic)  CGFloat mainLineHight;
@property (nonatomic)  CGFloat subLineHeight;

-(nonnull instancetype)initWithSrtxLine:(nullable SrtxLine *)srtx;
-(nonnull instancetype)initWithLrcLine:(nullable LrcLine *)lrc;

@end




