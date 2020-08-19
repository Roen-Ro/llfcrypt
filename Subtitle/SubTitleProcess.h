//
//  SrtParser.h
//  EnTT
//
//  Created by Roen on 2016/12/25.
//
//

#import <Foundation/Foundation.h>

#define LINE_BREAK @" |br| " //以前用<br>，这样会给处理其他<xx>的标签带领麻烦，现在代码中将所有<xxx>标签都去除掉
#define LAN_UNDEFINED @"-" //未知
#define SRTX_MARK @"MARK" //标记等级

#define ORIGINAL_LAN @"origin:"
//#define SRTX_FIX_MARK @"[fix]"
#define SRTX_LINE_ALIGN @"align>"

#define MERGE_SRTS_FILE_NAME @"merge.srtx"


//#define AVAILABLE_LANS @[@{@"en":@"English"}, \
//                     @{@"fre":@"Français(French)"}, \
//                     @{@"es":@"Español(Spanish)"}, \
//                     @{@"pt":@"Português(Portuguese)"}, \
//                     @{@"de":@"Deutsch(German)"}, \
//                     @{@"zh":@"中文(Chinese)"}, \
//                     @{@"ar":@"عربي  ،(Arabic)"}, \
//                     @{@"ko":@"한국어(Korean)"}, \
//                     @{@"ja":@"日本語(Japanese)"}, \
//                     @{@"ru":@"русский язык(Russian)"}, \
//                     @{@"it":@"In Italiano(Italian)"}, \
//                     @{@"vi":@"Tiếng Việt(Vietnamese)"}, \
//                     @{@"th":@"ภาษาไทย(Thai)"}, \
//                     @{@"ms":@"Bahasa Melayu(Malay)"}, \
//                     @{@"tr":@"Türkçe(Turkish)"}, \
//                     @{@"fa":@"فارسی‎ (Persian)"}, \
//                     @{@"nl":@"Nederlands(Dutch)"}, \
//                     @{@"iw":@"עברית‬(Hebrew)"}, \
//                     @{@"el":@"Ελληνικά(Greek)"}, \
//                     ];



//srtx是我自己定义的一种格式，在srt基础上增加了多语言以及标星操作
//后面新建的类，为了统一处理srtx/lrc字幕，但是因为业务代码都还是使用的LrcManager，所以lrc的业务依然使用LrcManager
@interface SrtxLine : NSObject<NSCopying>

@property (nonatomic, strong) NSMutableDictionary *polyglotLines; //key 就是语言的简写 (zh/en/ru/es/fre/de/ja/kr....)，或者是标星标记MARK，value就是对应语言的字幕
//@property (nonatomic, readonly) NSString *main_line; //主字幕(第一行)字幕内容，标星行不算
//@property (nonatomic, copy) NSString *main_lan; //主字幕的语言(key)
@property (nonatomic, copy, readonly) NSString *formarttedLineString; //格式化后的srtx字符串
@property NSTimeInterval startSecond;//开始时间
@property NSTimeInterval endSecond;//结束时间
@property (readonly) NSTimeInterval duration;
@property NSUInteger lineNum; //序号 暂时没用到
@property int markLevel; //标星等级
@property (nonatomic) BOOL isAlignLine; //是不是对齐字幕，用于字幕合并的时候作为对齐基准，每个字幕文件中只有第一个对齐字幕有效，如果文件中没有标记任何对齐字幕，则默认为第一句


@end

//只是在srt和lrc转换的过程中用到，业务上用的是SubLineInfo
@interface LrcLine : NSObject
@property (nonatomic, copy) NSString *content;
@property (nonatomic) NSTimeInterval second;
@property (nonatomic) NSUInteger timeTagIndex;
@property (nonatomic) NSUInteger lineIndex;
@end


@interface SubTitleProcess : NSObject

+(NSString *)readStringFromFile:(NSString *)path;

+(NSArray<NSTextCheckingResult *> *)chunksWithRegularExpressionPattern:(NSString *)pattern forString:(NSString *)stringContent;

//支持srtx格式（当然也包含srt格式），返回srtx字幕信息数组，以及将字幕原声语言传递给lan
+(NSArray<SrtxLine *>*)parseSrtxString:(NSString *)srtString withOriginalLan:(NSString **)lan;
+(NSArray<SrtxLine *>*)parseSrtxFile:(NSString *)srtPath withOriginalLan:(NSString **)lan;

+(NSTimeInterval)timeFromSrtxTimeString:(NSString *)timeTag;
+(NSString *)srtxTimeStringFromValue:(NSTimeInterval)t;

//返回最终写到文件中的string字符
+(NSString *)saveSrtxLines:(nonnull NSArray<SrtxLine *>*)lines withOriginalLan:(NSString *)orgLan toFile:(NSString *)path error:(NSError **)e;


/**
 解析srtx的字幕内容
 举个栗子：
 会将以下srtx字幕
 [zh:]我叫萧穗子
 [en:]My name is Xiao Suizi.[fix]
 [es:]Mi nombre es Xiao Suizi.
 解析成：
 @{
     @"zh":NSLocalizedString(@"我叫萧穗子",nil),
     @"en":@"My name is Xiao Suizi.",
     @"es":@"Mi nombre es Xiao Suizi.",
 }
 */
+(NSDictionary *)polyglotLinesFromSrtxLineString:(NSString *)lineString firstLineLan:(NSString **)lan;
+(NSString *)parseSrtxLine:(NSString *)line lan:(NSString **)lan;//解析单行
+(NSString *)formarttedSrtxWithLine:(NSString *)line lan:(NSString *)lan;//组装行

#pragma mark- 转换
+(NSString *)convertSrtString2LrcString:(NSString *)srtString revertLineOrder:(BOOL)revert;
+(NSString *)convertSrtString2LrcStringFromFile:(NSString *)srtFilePath revertLineOrder:(BOOL)revert;

+(NSArray <SrtxLine*>*)convertLrcToSrtxLines:(NSString *)lrcPath;

//返回srtx文件路径
+(NSString *)convertLrcToSrtFile:(NSString *)lrcPath;

//将srtx文件生成为中英双语的srt文件，返回新生成的文件路劲
+(NSString *)srtxToBilingualChs_EngSrt:(NSString *)srtxPath;
#pragma mark- 合并/分割
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
                             ofTransLan:(nonnull NSString *)transLan;


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
+(NSString *)mergeLinesAtDirectory:(NSString *)directory withOriginLan:(nonnull NSString *)orgLan;


//对字幕进行分割
+(NSArray <NSArray<SrtxLine *> *>*)splitSrtLines:(NSArray<SrtxLine *>*)lines byTime:(NSArray<NSNumber *> *)splitTimes;

//字幕文件分割 splitTimes中的时间是srtx格式时间
+(nullable NSArray <NSString *>*)splitSrtxFileAtPath:(nonnull NSString *)path
                                             byTimes:(nonnull NSArray<NSString *> *)splitTimes
                                            errorMsg:(NSString **)errorMsg;

//返回适合分割的srt字幕时间
+(NSString *)logSuitableSplitTimePoints:(NSString *)srtFilePath;

//将所有lines的字幕，合并成一句
+(SrtxLine *)mergeSrtxLinesToOne:(nonnull NSArray <SrtxLine *> *)lines;

//找出字幕中时间顺序有问题的字幕
+(void)findAbnormalTimelineLinesAtPath:(NSString *)srtPath toFile:(NSString *)exceptionPath;
+(NSArray <SrtxLine *> *)findAbnormalTimelineLines:(NSArray <SrtxLine *> *)lines;

//对字幕重新排序，对时间有重叠的字幕进行合并或调整处理
+(NSArray <SrtxLine *> *)fixLineOrderAndLappedTime:(NSArray <SrtxLine *> *)lines;

//注意是拆分srt字幕，不是srtx字幕，就是单纯的把两行字幕，分别拆分成两组字幕,返回其存放地址
+(NSArray <NSString *> *)breakLinesWithSrtFile:(NSString *)srtPath;

/*
 将portionPath的字幕内容时间偏移(减)segStart秒后，替换掉fullPath字幕中，从segStart到segEnd范围内的字幕，
 */
+(NSString *)replaceSrtx:(NSString *)fullPath from:(NSTimeInterval)segStart to:(NSTimeInterval)segEnd withPortionSrtx:(NSString *)portionPath;

#pragma mark- 导出
//导出去除时间标签的文本
+(NSString *)exportTextFileWithSrtxLines:(nonnull NSArray<SrtxLine *>*)lines withLans:(NSArray <NSString *>*)lans toFile:(NSString *)path error:(NSError **)e;

#pragma mark- lrc
#warning 下面这些方法还没用到，现在业务上lrc都是用的LrcManager中的方法
+(NSString *)lrcTimeTagStringForTime:(NSTimeInterval)time;

+(NSArray<LrcLine *> *)parseLrcString:(NSString *)lrcContent;

+(NSArray <NSArray<LrcLine *>*>*)splitLrcFromLrcString:(NSString *)lrcString wihtSplitTimePos:(NSArray <NSNumber *> *)secPoses;

+(NSError *)saveLrcLines:(nonnull NSArray <LrcLine *>*)lrcLines toFile:(nonnull NSString *)path;

@end


//计算t0->t1和T0->T1之间的重叠时间
extern NSTimeInterval timeLapCal(NSTimeInterval t0,NSTimeInterval t1,NSTimeInterval T0,NSTimeInterval T1);
