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

+(NSDictionary *)splitTimePointWithSrtFile:(NSString *)path expectedSegmentDuration:(int)duration trimStart:(BOOL)trims;

@end

NS_ASSUME_NONNULL_END
