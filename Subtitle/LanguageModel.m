//
//  LanguageModel.m
//  Tinglee
//
//  Created by lolaage on 2020/1/30.
//

#import "LanguageModel.h"
static LanguageModel *gTransLanModel;
@implementation LanguageModel

#pragma mark- class methods
+(NSArray <LanguageModel *> *)availableLans {
    static NSArray *allLans;
    if(!allLans) {
        NSMutableArray *ma = [NSMutableArray arrayWithCapacity:20];
        [ma addObject:[self lanWithShort:@"en" en:@"English" name:@"English"]];
        [ma addObject:[self lanWithShort:@"fre" en:@"French" name:@"Français"]];
        [ma addObject:[self lanWithShort:@"es" en:@"Spanish" name:@"Español"]];
        [ma addObject:[self lanWithShort:@"pt" en:@"Portuguese" name:@"Português"]];
        [ma addObject:[self lanWithShort:@"de" en:@"German" name:@"Deutsch"]];
        [ma addObject:[self lanWithShort:@"zh" en:@"Chinese" name:@"中文"]];
        [ma addObject:[self lanWithShort:@"ar" en:@"Arabic" name:@"عربي  ،"]];
        [ma addObject:[self lanWithShort:@"ko" en:@"Korean" name:@"한국어"]];
        [ma addObject:[self lanWithShort:@"ja" en:@"Japanese" name:@"日本語"]];
        [ma addObject:[self lanWithShort:@"ru" en:@"Russian" name:@"русский язык"]];
        [ma addObject:[self lanWithShort:@"vi" en:@"Vietnamese" name:@"Tiếng Việt"]];
        [ma addObject:[self lanWithShort:@"tr" en:@"Turkish" name:@"Türkçe"]];
        [ma addObject:[self lanWithShort:@"it" en:@"Italian" name:@"Italiano"]];
        [ma addObject:[self lanWithShort:@"pl" en:@"Polish" name:@"język polski"]];
        [ma addObject:[self lanWithShort:@"ro" en:@"Romanian" name:@"limba română"]];
        [ma addObject:[self lanWithShort:@"ms" en:@"Malay" name:@"Bahasa Melayu"]];
        [ma addObject:[self lanWithShort:@"hu" en:@"Hungarian" name:@"magyar"]];
        [ma addObject:[self lanWithShort:@"nl" en:@"Dutch" name:@"Nederlands"]];
        [ma addObject:[self lanWithShort:@"sr" en:@"Serbian" name:@"српски"]];
        [ma addObject:[self lanWithShort:@"th" en:@"Thai" name:@"ภาษาไทย"]];
        [ma addObject:[self lanWithShort:@"iw" en:@"Hebrew" name:@"עברית‬"]];
        [ma addObject:[self lanWithShort:@"el" en:@"Greek" name:@"Ελληνικά"]];
        [ma addObject:[self lanWithShort:@"cs" en:@"Czech" name:@"čeština"]];
        [ma addObject:[self lanWithShort:@"sk" en:@"Slovak" name:@"slovenčina"]];
        [ma addObject:[self lanWithShort:@"bn" en:@"Bengali" name:@"বাঙালী"]];
        [ma addObject:[self lanWithShort:@"hr" en:@"Croatian" name:@"Hrvatski"]];
        [ma addObject:[self lanWithShort:@"fa" en:@"Persian" name:@"فارسی‎ "]];
        [ma addObject:[self lanWithShort:@"no" en:@"Norwegian" name:@"norsk"]];
        [ma addObject:[self lanWithShort:@"da" en:@"Danish" name:@"Dansk"]];
        [ma addObject:[self lanWithShort:@"fi" en:@"Finnish" name:@"suomi"]];
        
        allLans = [NSArray arrayWithArray:ma];
        
    }
    return allLans;
}
+(LanguageModel *)lanWithShort:(NSString *)s en:(NSString *)en name:(NSString *)n {
    LanguageModel *m = [[LanguageModel alloc] init];
    m.shortName = s;
    m.enName = en;
    m.selfName = n;
    return m;
}


#define kTRANS_LAN @"trans_lan"
//是不是中文用户
+(BOOL)isChineseUser {
    
    if([[self preferedTransLan].lowercaseString isEqualToString:@"zh"])
        return YES;
    
    NSArray * allLanguages = [U_DEFAULTS objectForKey:@"AppleLanguages"];
    NSString *lan = [allLanguages objectAtIndex:0];
    NSString *lowLan = lan.lowercaseString;
    if([lowLan hasPrefix:@"zh"])
        return YES;
    if([lowLan hasSuffix:@"cn"])
        return YES;
    if([lowLan hasSuffix:@"hk"])
        return YES;
    if([lowLan hasSuffix:@"tw"])
        return YES;
 
    return NO;
}

+(NSString *)sourceLan {
    //需要根据不同的app返回
    return ORIGIN_LAN;
}

//返回简写
+(NSString *)preferedTransLan {
    NSString *l = [self manualSetTransLan];
    if(!l)
        l = [self defaultTranslan];
    
    if([l isEqualToString:ORIGIN_LAN]) {
        l = [self systemLan];
    }
    
    return l;
}

+(LanguageModel *)preferedTransLanModel; {
    if(!gTransLanModel) {
        NSString *l = [self preferedTransLan];
        gTransLanModel = [self modelForShortName:l];
        if(!gTransLanModel)
            gTransLanModel = [self availableLans].firstObject;
    }
    return gTransLanModel;
}

+(LanguageModel *)modelForShortName:(NSString *)lan {
    
    for(LanguageModel *m in [self availableLans] ) {
        if([lan hasPrefix:m.shortName])
        {
            return m;
        }
    }
    
    return nil;
}

//用户手动设置过的翻译语言，简写
+(NSString *)manualSetTransLan {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSString *lan = [d objectForKey:kTRANS_LAN];
    return lan;
}

+(void)setDefaultTranslan:(NSString *)transLan //设置默认的翻译语言
{
    [[NSUserDefaults standardUserDefaults] setObject:transLan forKey:kTRANS_LAN];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if(![transLan isEqualToString:ORIGIN_LAN])
        gTransLanModel = [self modelForShortName:transLan];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AppTransLanDidChangeNote object:nil];
}

//简写
+(NSString *)defaultTranslan //获取默认的翻译语言，如果没有设置，则获取系统语言
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSString *lan = [d objectForKey:kTRANS_LAN];
    lan = [self lanForLan:lan];
    if(!lan) {
        NSArray * allLanguages = [d objectForKey:@"AppleLanguages"];
        lan = [allLanguages objectAtIndex:0];
        lan = [self lanForLan:lan];
    }
    
    return lan;
}

+(NSString *)systemLan {
    NSArray * allLanguages = [U_DEFAULTS objectForKey:@"AppleLanguages"];
    NSString *lan = [allLanguages objectAtIndex:0];
    lan = [self lanForLan:lan];
    return lan;
}

+(NSString *)lanForLan:(NSString *)lan {
    
    NSArray *lans = [LanguageModel availableLans];
    for(LanguageModel *ldic in lans) {
        NSString *l = ldic.shortName;
        if([lan hasPrefix:l])
            return l;
    }
    return nil;
}


#pragma mark- instance methods

//-(instancetype)initWithCoder:(NSCoder *)aDecoder {
//
//    self = [super init];
//    return self;
//}
//
//-(void)encodeWithCoder:(NSCoder *)aCoder {
//    [super encodeWithCoder:aCoder];
//}


-(NSString *)fullName {
    if(self.selfName.length>0)
        return [NSString stringWithFormat:@"%@(%@)",self.selfName,self.enName];
    else
        return [NSString stringWithFormat:@"%@",self.selfName];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"%@;%@",self.shortName,self.fullName];
}

#pragma mark-

@end
