//
//  SubLineManager.h
//  YingYuTingTing
//
//  Created by 罗亮富 on 2019/5/26.
//

#import <Foundation/Foundation.h>
#import "LrcManager.h"
#import "SubTitleProcess.h"
#import "LanguageModel.h"

//解析读取等都主要是调用LrcManager和SubTitleProcess
@interface SubLineManager : NSObject {
@private
    SubLine_type _lineType;
    LrcManager *_lrcMMg;
}


@property (nonatomic, readonly) NSString *filePath;

//copy表示，字幕的数据可以插入，删除，保存
@property (nonatomic, copy) NSArray<SubLineInfo *> *subLines; //如果是srt字幕的话，会自动插入空行

/*
 @"zh": 中文，@"en": 英文，@"fre" 法语，@"ar": 阿拉伯语，@"de": 德语，@"es": 西班牙语，@"ja": 日语，@"ko": 韩语，@"ru": 俄语，@"pt": 葡萄牙语
 */
@property (nonatomic, copy) NSString *orgLan; //原字幕语言, srtx字幕才有, 不设置的话取srtx文件中的默认值 文件开头如origin:zh的格式
@property (nonatomic, copy) NSString *transLanSetting; //翻译字幕的语言, srtx字幕才有，需要手工设置


@property (nonatomic, readonly) NSUInteger lineCount; //字幕数量row
@property (nonatomic, readonly) NSSet *allWords; //单词所有单词
@property (nonatomic, readonly) NSTimeInterval lineDuration; //台词时长，去掉背景音后
//@property (nonatomic, readonly) NSArray<SubLineInfo *> *realSublines; //包含实际内容的字幕

-(NSSet *)allLans;//srtx字幕才有，获取所有的语言种类

-(instancetype)initWithFile:(NSString *)filePath;

-(NSArray<SubLineInfo *> *)parseFile;

-(void)saveLinesToFileCompletion:(void (^)(BOOL sucess))completion;//覆盖保存
-(void)saveLinesToFile:(NSString *)filePath completion:(void (^)(BOOL sucess))completion;//另存为
-(void)exportTextToFile:(NSString *)filepath completion:(void (^)(NSString *, NSError *))compleHandle;//导出纯文本文件

+(BOOL)isSublineBackgroundLine:(SubLineInfo *)line;

@end

#define INSERT_BLANK_LINE_MIN_INTERVAL 0.5
