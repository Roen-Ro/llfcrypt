//
//  NSObject+FDUti.m
//  llfcrypt
//
//  Created by 罗亮富 on 2020/8/19.
//  Copyright © 2020 roen. All rights reserved.
//

#import "NSObject+FDUti.h"


@implementation NSObject (FDUti)



-(void)observeForNotification:(NSString *)notificationName object:(id)object handleBlock:(NotificationHandleBlockType)block
{
    //避免重复监听
    [[NSNotificationCenter defaultCenter]removeObserver:self name:notificationName object:object];
    
    if(block)
    {
        @synchronized(self)
        {
            [[self blockMap]setObject:block forKey:[self mapKeyForNotification:notificationName ofObject:object]];
        }
    }
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleNotification:) name:notificationName object:object];
}

-(void)unobserveForNotification:(NSString *)notificationName object:(id)object
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:notificationName object:object];
    [[self blockMap]removeObjectForKey:[self mapKeyForNotification:notificationName ofObject:object]];
    //如果object是nil 的话是要取消对所有object的监听的，所以这里还要增加处理...
    if(!object)
    {
        NSMutableDictionary *map = [self blockMap];
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:2];
        [map enumerateKeysAndObjectsUsingBlock:^(id   key, id   obj, BOOL *  stop) {
            NSString *theKey = key;
            if([theKey hasSuffix:[NSString stringWithFormat:@"%@-",notificationName]])
                [arr addObject:key];
        }];
        
        if(arr.count>0)
        {
            for(NSString *key in arr)
            {
                [[self blockMap] removeObjectForKey:key];
            }
        }
    }
}

static char mapKey;

-(void)unobserveForAllNotifications
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    @synchronized(self)
    {
        NSMutableDictionary *map = objc_getAssociatedObject(self, &mapKey);
        if (map)
            [map removeAllObjects];
    }
}


-(NSMutableDictionary *)blockMap
{
    @synchronized(self)
    {
        NSMutableDictionary *map = objc_getAssociatedObject(self, &mapKey);
        if(!map)
        {
            map = [NSMutableDictionary dictionaryWithCapacity:2];
            objc_setAssociatedObject(self, &mapKey, map, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        return map;
    }
}

-(void)handleNotification:(NSNotification *)notification
{
    NotificationHandleBlockType block1 = [[self blockMap] objectForKey:[self mapKeyForNotification:notification.name ofObject:notification.object]];
    if(block1)
        block1(notification.object, notification.userInfo);
    
    //因为通知中心监听的object参数传的是nil的话，则表示监听所有object发送的这个通知，所以这里再做这一步的作用是为了保证监听object传入是nil时候也能正常回调
    if(notification.object)
    {
        NotificationHandleBlockType block2 = [[self blockMap] objectForKey:[self mapKeyForNotification:notification.name ofObject:nil]];
        if(block2)
            block2(notification.object, notification.userInfo);
    }
}

-(NSString *)mapKeyForNotification:(NSString *)notificationName ofObject:(id)object
{
    NSString *key = [NSString stringWithFormat:@"%@-%p",notificationName,object];
    return key;
}


@end
