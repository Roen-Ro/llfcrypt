//
//  NSObject+FDUti.h
//  llfcrypt
//
//  Created by 罗亮富 on 2020/8/19.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NotificationHandleBlockType)(id object, NSDictionary *userInfo);

@interface NSObject (FDUti)

-(void)observeForNotification:(NSString *)notificationName object:(id)object handleBlock:(NotificationHandleBlockType)block;

-(void)unobserveForNotification:(NSString *)notificationName object:(id)object;

-(void)unobserveForAllNotifications;

@end

NS_ASSUME_NONNULL_END
