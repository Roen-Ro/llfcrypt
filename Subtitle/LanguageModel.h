//
//  LanguageModel.h
//  Tinglee
//
//  Created by lolaage on 2020/1/30.
//

#import <Foundation/Foundation.h>

#define AppTransLanDidChangeNote @"appTransLanDidChangeNotification"

NS_ASSUME_NONNULL_BEGIN

@interface LanguageModel : NSObject

@property (nonatomic, strong) NSString *selfName; //本地语言名称
@property (nonatomic, strong) NSString *shortName; //简写
@property (nonatomic, strong) NSString *enName; //英文名称
@property (nonatomic, readonly) NSString *fullName; //英文+本地名称

+(NSArray <LanguageModel *> *)availableLans;
+(NSString *)sourceLan; //源语言
+(NSString *)preferedTransLan; //翻译语言
+(LanguageModel *)preferedTransLanModel; 

+(nullable NSString *)manualSetTransLan;//用户手动设置过的翻译语言
+(void)setDefaultTranslan:(nonnull NSString *)transLan; //设置默认的翻译语言, transLan为语言的简写
+(nonnull NSString *)defaultTranslan; //获取默认的翻译语言，如果没有设置，则获取系统语言
+(LanguageModel *)modelForShortName:(NSString *)lan;

+(BOOL)isChineseUser;//是否是中文用户

@end

NS_ASSUME_NONNULL_END

