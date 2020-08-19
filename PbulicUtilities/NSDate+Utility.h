//
//  NSDate+BirthDay.h
//  
//
//  Created by 罗亮富 on 12-12-6.
//  Copyright (c) 2012年  All rights reserved.
//

#import <Foundation/Foundation.h>

#define DATE_FORMAT_DEFAULT     @"yyyy-MM-dd"
#define TIME_FORMAT_DEFAULT     @"yyyy-MM-dd HH:mm:ss"
#define TIME_FORMAT_SEC         @"HH:mm:ss"

typedef struct date{
    unsigned char month;
    unsigned char date;
} DateType;


typedef enum {
    time_unit_week,
    time_unit_hour,
    time_unit_day,
    time_unit_month,
    time_unit_year,
    time_unit_era,
    time_unit_None
}time_unit_type;

@interface NSDate (Utility)

-(NSInteger)ageAsBirthDay;
-(NSString *)constellationAsBirthDay;

//比较日历时间日期跨度
-(BOOL)isOtherDayFromDate:(NSDate *)otherDay;
-(NSString*)dateStringFromNow;
+(NSDate *)dateFromFormatedString:(NSString *)formatString;
+(NSDate *)dateFromFormatedString:(NSString *)formatString byFormat:(NSString *)format;
-(NSString *)dateStringWithFormat:(NSString *)formatString;


-(NSString *)appDateDescription;

-(NSString *)defaultDescription;

-(NSString *)referencedDateDescription;
-(NSDateComponents *)datePart;
//年月日时分秒
-(NSDateComponents *)fullPart;

/**
 *  比较两个日期, 日期为nil时,相当于0
 *
 */
+(NSComparisonResult)compareBetweenDate:(NSDate *)date1 andDate:(NSDate *)date2;

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;


//今日凌晨
+(NSDate *)today;

+ (NSDateComponents *)componetsWithTimeInterval:(NSTimeInterval)timeInterval;
+ (NSString *)timeDescriptionOfTimeInterval:(NSTimeInterval)timeInterval;

+ (NSString *)timeDescription1OfTimeInterval:(NSTimeInterval)timeInterval;


//传入 dateString 是一个 YYYY-MM-dd HH:mm:ss 格式的字符串,获取对应的 NSDate
+ (NSDate*)getDateWith:(NSString *)dateString;

@end
