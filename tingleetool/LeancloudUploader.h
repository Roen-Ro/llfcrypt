//
//  LeancloudUploader.h
//  tingleetool
//
//  Created by 罗亮富 on 2020/6/10.
//  Copyright © 2020 roen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UploadSubFileInfo;

@interface LeancloudUploader : NSObject {
    @private
    NSDictionary *_resInfo;
    NSString *_coverFileName; //封面文件路径
    NSArray <NSString *> *_sorttedMp3Files;//排好序的音频文件
    NSArray *_allMp3Files;//所有目录下的音频文件
    NSArray *_allSubFiles;
    
}

-(instancetype)initWithDirectory:(NSURL *)resdirectory;
@property (nonatomic, readonly) NSURL *resourceDirectory;
@property (nonatomic, readonly) NSString *cloudTitle;
@property (nonatomic, readonly) NSMutableArray <UploadSubFileInfo *> *uploadedRecords;//已上传文件信息在本地做的记录，如果失败重试，不会再上传那些资源

@property (nonatomic, readonly) void (^completionBlock)(void);

-(void)startUploadWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
