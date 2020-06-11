//
//  AsyncHelper.h
//  AsyncCoreData
//
//  Created by 罗亮富 on 2019/1/17.
//

#ifndef AsyncHelper_h
#define AsyncHelper_h
#import <Foundation/Foundation.h>

extern void background_async(void(^task)(void));
extern void background_async_high(void(^task)(void));
extern void background_async_low(void(^task)(void));

extern void main_task(void(^task)(void)); //在主线程执行代码

extern void task_delay_on_main(NSTimeInterval second, void (^task)(void));//延迟在主线程执行代码
extern void task_delay_background(NSTimeInterval second, void (^task)(void));//延迟在后台线程执行代码


#endif /* AsyncHelper_h */
