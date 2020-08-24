//
//  LeancloudUploader.m
//  tingleetool
//
//  Created by 罗亮富 on 2020/6/10.
//  Copyright © 2020 roen. All rights reserved.
//

#import "LeancloudUploader.h"
#import <RRUti/RRUti_Foundation.h>
#import "NSDictionary+Utility.h"
#include <sys/stat.h>
#import "yyttdatacryption.h"
#import <AVOSCloud/AVOSCloud.h>
#import <AVFoundation/AVFoundation.h>
#import "AsyncHelper.h"

@interface UploadSubFileInfo : NSObject<NSCoding>

@property (nonatomic, copy) NSString *audioPath;
@property (nonatomic, copy) NSString *srtPath;
@property (nonatomic) NSTimeInterval duration;//时间长度
@property (nonatomic, copy) NSString *audioCloudUrl;//云端
@property (nonatomic, copy) NSString *audioCloudId;//云端
@property (nonatomic, copy) NSString *srtCloudUrl;//云端
@property (nonatomic, copy) NSString *srtCloudId;//云端
@property (nonatomic) BOOL isUploading;

@end

@implementation UploadSubFileInfo

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    self.audioPath = [coder decodeObjectForKey:@"audioPath"];
    self.srtPath = [coder decodeObjectForKey:@"srtPath"];
    self.audioCloudUrl = [coder decodeObjectForKey:@"audioCloudUrl"];
    self.audioCloudId = [coder decodeObjectForKey:@"audioCloudId"];
    self.srtCloudUrl = [coder decodeObjectForKey:@"srtCloudUrl"];
    self.srtCloudId = [coder decodeObjectForKey:@"srtCloudId"];
    self.duration = [coder decodeDoubleForKey:@"duration"];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.audioPath forKey:@"audioPath"];
    [coder encodeObject:self.srtPath forKey:@"srtPath"];
    [coder encodeObject:self.audioCloudUrl forKey:@"audioCloudUrl"];
    [coder encodeObject:self.audioCloudId forKey:@"audioCloudId"];
    [coder encodeObject:self.srtCloudUrl forKey:@"srtCloudUrl"];
    [coder encodeObject:self.srtCloudId forKey:@"srtCloudId"];
    [coder encodeDouble:self.duration forKey:@"duration"];
}

-(NSUInteger)hash {
    return self.audioPath.hash;
}

-(BOOL)isEqual:(UploadSubFileInfo *)object {
    return [self.audioPath isEqualToString:object.audioPath];
}
@end




@implementation LeancloudUploader
@synthesize uploadedRecords = _uploadedRecords;

-(instancetype)initWithDirectory:(NSURL *)resdirectory {
    self = [super init];
    _resourceDirectory = resdirectory;
    [self readFiles];
    return self;
}

//读取文件信息
-(void)readFiles {
    
    NSFileManager *fm = [NSFileManager defaultManager];
     NSArray *files = [fm contentsOfDirectoryAtPath:self.resourceDirectory.path error:nil];
      
     NSMutableArray *mFiles = [NSMutableArray arrayWithCapacity:12];
      for(NSString *file in files)
      {
          if([file.lowercaseString hasSuffix:@".json"]) //读取json文件
          {
              if(!_resInfo)
              {
                 _resInfo = [self parseJsonFile:[self.resourceDirectory URLByAppendingPathComponent:file]];
             }
          }
          else if([file.lowercaseString hasSuffix:@".m4a"]) //读取音频
          {
              if([file.lowercaseString hasPrefix:@"._"])
                  continue;
                
              [mFiles addObject:file];
          }
          else if(!_coverFileName)
          {
              if([file.lowercaseString hasSuffix:@".jpg"]
                  ||[file.lowercaseString hasSuffix:@".jpeg"]
                  ||[file.lowercaseString hasSuffix:@".png"] )
                     _coverFileName = file;
          }
      }
    
    _allMp3Files = [NSArray arrayWithArray:mFiles];
    
     NSMutableArray *filtFiles = [NSMutableArray arrayWithCapacity:12];
    
    if(_allMp3Files.count == 1) //只有1个mp3文件的话，不限命名格式
        _sorttedMp3Files = _allMp3Files;
    else //多个mp3文件的话，找出已xxx_01.mp3、xxx_02.mp3、xxx_03.mp3命名的文件并排好序
    {
        BOOL found = NO;
        for(int i=1; i<100; i++) {
            found = NO;
            for(NSString *fname in _allMp3Files)
            {
                if([fname.lowercaseString hasSuffix:[NSString stringWithFormat:@"_%02d.m4a",i]]) {
                    found = YES;
                    [filtFiles addObject:fname];
                }
            }
            
            if(!found)
                break;
        }
        _sorttedMp3Files = [NSArray arrayWithArray:filtFiles];
    }
    
    if(_sorttedMp3Files.count == 0 && _allMp3Files.count == 1) {
        _sorttedMp3Files = _allMp3Files;
    }
    
    if(_sorttedMp3Files.count == 0){
        NSLog(@"Error: No audio file found in %@",self.resourceDirectory.path);
        exit(1);
    }
    
    if(!self.cloudTitle) {
        NSLog(@"Error: No title specified in json file");
        exit(1);
    }
        
}

-(NSDictionary *)parseJsonFile:(NSURL *)jsonUrl {
    return [NSDictionary dictionaryFromJsonFile:jsonUrl];
}

//对文件进行加密处理
-(void)doEncryption {
    
    NSLog(@"开始加密文件....");
    NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:_sorttedMp3Files.count];
    for(NSString *f in _sorttedMp3Files) {
        
        NSString *orgAudioPath = [self.resourceDirectory URLByAppendingPathComponent:f].path;
        NSString *srtPath = [orgAudioPath pathByReplaceingWithFileName:nil extention:@"srt"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:srtPath]) {
            NSLog(@"Error: expected file %@ not found",srtPath);
            exit(1);
        }
        
        NSString *desAudioPath = [orgAudioPath stringByAppendingString:@".ytenc"];
        NSString *desSrtPath = [srtPath stringByAppendingString:@".ytenc"];
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:desAudioPath])
            encrypt_file([orgAudioPath cStringUsingEncoding:NSUTF8StringEncoding], [desAudioPath cStringUsingEncoding:NSUTF8StringEncoding]);
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:desSrtPath])
            encrypt_file([srtPath cStringUsingEncoding:NSUTF8StringEncoding], [desSrtPath cStringUsingEncoding:NSUTF8StringEncoding]);
        
        UploadSubFileInfo *info = [UploadSubFileInfo new];
        info.audioPath = desAudioPath;
        info.srtPath = desSrtPath;
        info.duration = [self getAudioDurationFromFile:orgAudioPath];
        
        //如果本地有已经保存过的上传文件信息，则将文件信息替换掉
        for(UploadSubFileInfo *lInfo in self.uploadedRecords)
        {
            if([info isEqual:lInfo]) {
                info = lInfo;
                break;
            }
        }
        
        [mArray addObject:info];
    }
    
    _allSubFiles = [mArray copy];
}


#define EXIT_IF_ERROR(e) if(e) { \
    NSLog(@"Error:%@",e);\
    self.completionBlock();\
    exit(1);\
    return;\
}

AVFile *sfile;
-(void)startUploadWithCompletion:(void (^)(void))completion {
    
    
    [AVOSCloud setApplicationId:@"TDWwApWrbUyEBsum0HOJ6ETa"
                      clientKey:@"wVcNurfHXqy67S0fx1iiX16d"
                serverURLString:@"https://api.yingyutingting.com"];
    
//    // 关闭调试日志
    [AVOSCloud setAllLogsEnabled:NO];
    [AVOSCloud setLogLevel:AVLogLevelNone];
    [AVOSCloud setVerbosePolicy:kAVVerboseNone];

//#warning test
//    AVFile *f = [AVFile fileWithLocalPath:@"/Users/jiangwenbin/Desktop/英语听听截图/img.png" error:nil];
//    [f uploadWithProgress:^(NSInteger number) {
//        NSLog(@"--->>> %d",number);
//    } completionHandler:^(BOOL succeeded, NSError * _Nullable error) {
//        NSLog(@"completionHandler %@",error);
//        completion();
//    }];
//    
//    
//    return;

    _completionBlock = completion;
    [self doEncryption];
    [self uploadSubFiles];
}

-(void)uploadSubFiles {
    
    UploadSubFileInfo *upFile = nil;
    //从数组中找到第一个没有上传完成的子文件
    for(UploadSubFileInfo *f in _allSubFiles) {
        if(f.srtCloudUrl && f.audioCloudUrl)
            continue;
        else {
            upFile = f;
            break;
        }
    }
    
    if(upFile) {
        [self uploadSubfile:upFile completion:^{
            //一定是成功了才会到这里，否则就在内部直接退出了
            [self uploadSubFiles];
        }];
    }
    else {
        [self uploadResource];
    }
}


-(void)uploadResource {
    
    //首先查询记录是否存在
    AVQuery *query = [AVQuery queryWithClassName:@"EnttResource"];
    [query whereKey:@"title" equalTo:self.cloudTitle];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        EXIT_IF_ERROR(error);
        
        if(objects.count > 0)
            [self saveResourceObjectAsync:objects.firstObject];
        else
            [self saveResourceObjectAsync:nil];
    }];
}

-(void)uploadSubfile:(UploadSubFileInfo *)file completion:(void (^)(void))completion {
    
    //因为下面的代码用到了dispatch_group,而AVFile回调会自动放到主线程，如果此方法在主线程执行的话就会导致线程一直处于dispatch_group_wait状态中
    background_async(^{
        
        dispatch_group_t group = dispatch_group_create();
        if(!file.audioCloudId)
        {
            NSError *ferror;
            AVFile *f = [AVFile fileWithLocalPath:file.audioPath error:&ferror];
            EXIT_IF_ERROR(ferror);
            dispatch_group_enter(group);
            NSLog(@"Begin Upload %@",file.audioPath.lastPathComponent);
            [f uploadWithProgress:^(NSInteger percent) {
               // NSLog(@"Progress %@ %d",file.audioPath.lastPathComponent,percent);
            } completionHandler:^(BOOL succeeded, NSError * _Nullable error) {
                EXIT_IF_ERROR(error);
                file.audioCloudId = f.objectId;
                file.audioCloudUrl = f.url;
                [self saveStatus];
                NSLog(@"Finished Upload %@",file.audioPath.lastPathComponent);
                dispatch_group_leave(group);
            }];
        }
        
        if(!file.srtCloudId)
        {
            NSError *ferror;
            AVFile *f = [AVFile fileWithLocalPath:file.srtPath error:&ferror];
            EXIT_IF_ERROR(ferror);
            dispatch_group_enter(group);
            NSLog(@"Begin Upload %@",file.srtPath.lastPathComponent);
            [f uploadWithProgress:^(NSInteger percent) {
              //  NSLog(@"Progress %@ %d",file.srtPath.lastPathComponent,percent);
            } completionHandler:^(BOOL succeeded, NSError * _Nullable error) {
                EXIT_IF_ERROR(error);
                file.srtCloudId = f.objectId;
                file.srtCloudUrl = f.url;
                [self saveStatus];
                NSLog(@"Finished Upload %@",file.srtPath.lastPathComponent);
                dispatch_group_leave(group);
            }];
        }
            
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            completion();
        });
        
    });

}

-(void)saveResourceObjectAsync:(AVObject *)resObject {
    
    
    if(!resObject)
        resObject = [AVObject objectWithClassName:@"EnttResource"];
    
     background_async(^{
        [resObject setObject:self.cloudTitle forKey:@"title"];
        [resObject setObject:_resInfo[@"desc"] forKey:@"desc"];
        [resObject setObject:_resInfo[@"region"] forKey:@"region"];
        [resObject setObject:_resInfo[@"type"] forKey:@"type"];
        NSString *yearValue = _resInfo[@"year"];
        [resObject setObject:[NSNumber numberWithInt:yearValue.intValue] forKey:@"year"];
        [resObject setObject:[self subfilesFiled] forKey:@"subfiles"];
        
        
        AVFile *srtxFile = [resObject objectForKey:@"srtxFile"];
        AVFile *coverFile = [resObject objectForKey:@"cover"];
        
        //因为下面的代码用到了dispatch_group,而AVFile回调会自动放到主线程，如果此方法在主线程执行的话就会导致线程一直处于dispatch_group_wait状态中
       
            //上传封面和完整字幕文件
            dispatch_group_t group = dispatch_group_create();
            NSError *readFileError;
            if(!srtxFile) {
                dispatch_group_enter(group);
                NSLog(@"start upload srtx file");
                NSString *path = [self fullSrtxPath];
                srtxFile = [AVFile fileWithData:[NSData dataWithContentsOfFile:path] name:path.lastPathComponent];
                if(!srtxFile) {
                    NSLog(@"Error:%@",readFileError);
                    exit(1);
                }
                
                [srtxFile uploadWithCompletionHandler:^(BOOL succeeded, NSError * _Nullable error) {
                     EXIT_IF_ERROR(error);
                    [resObject setObject:srtxFile forKey:@"srtxFile"];
                    dispatch_group_leave(group);
                    NSLog(@"Finished upload srtx file");
                }];
            }
            
            if(!coverFile) {
                dispatch_group_enter(group);
                NSLog(@"start upload cover file");
                coverFile = [AVFile fileWithLocalPath:[self.resourceDirectory.path stringByAppendingPathComponent:_coverFileName] error:&readFileError];
                if(!coverFile) {
                    NSLog(@"Error:%@",readFileError);
                    exit(1);
                }
                
                [coverFile uploadWithCompletionHandler:^(BOOL succeeded, NSError * _Nullable error) {
                     EXIT_IF_ERROR(error);
                    [resObject setObject:coverFile forKey:@"cover"];
                    dispatch_group_leave(group);
                    NSLog(@"Finished upload cover file");
                }];
            }
            
         dispatch_group_notify(group, dispatch_get_main_queue(), ^{
             
            NSLog(@"Start Upload EnttResource %@",self.cloudTitle);
             [resObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                 EXIT_IF_ERROR(error);
                 NSLog(@"Finished Upload EnttResource %@ !!",self.cloudTitle);
                 self.completionBlock();
             }];
             
         });
            
    });

}

-(NSString *)fullSrtxPath {
    NSString *name = _resInfo[@"title"];
    NSString *path = [self.resourceDirectory.path stringByAppendingFormat:@"/%@.srtx",name];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path])
        path = [self.resourceDirectory.path stringByAppendingFormat:@"/%@.srt",name];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path])
        path = [self.resourceDirectory.path stringByAppendingPathComponent:@"merge.srtx"];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:path])
        return nil;
    else {
        NSString *destPath = [path stringByAppendingString:@".ytenc"];
        encrypt_file([path cStringUsingEncoding:NSUTF8StringEncoding],[destPath cStringUsingEncoding:NSUTF8StringEncoding]);
        return destPath;
    }
}

-(NSArray<NSString *> *)subfilesFiled {
    NSMutableArray *sFiles = [NSMutableArray arrayWithCapacity:_allMp3Files.count];
    for(UploadSubFileInfo *f in _allSubFiles) {
        NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithCapacity:5];
        [mdic setObject:f.audioCloudUrl forKey:@"audio_url"];
        [mdic setObject:f.audioCloudId forKey:@"audio_fileId"];
        [mdic setObject:[NSDate timeDescriptionOfTimeInterval:f.duration] forKey:@"duration"];
        [mdic setObject:f.srtCloudUrl forKey:@"srt_url"];
        [mdic setObject:f.srtCloudId forKey:@"srtx_fileId"];
        [sFiles addObject:mdic];
    }
    return sFiles;
}

-(NSString *)cloudTitle {
    NSString *title = _resInfo[@"title"];
    NSString *zh_title = _resInfo[@"titles"][@"zh"];
    if(zh_title)
        return zh_title;
    
    return title;
}

-(NSString *)archivePath {
    return [self.resourceDirectory URLByAppendingPathComponent:@"uploaded.arc"].path;
}
-(NSMutableArray *)uploadedRecords {
    if(!_uploadedRecords)
        _uploadedRecords = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archivePath]];
    if(!_uploadedRecords)
        _uploadedRecords = [NSMutableArray array];
    
    return _uploadedRecords;
}

-(void)saveStatus {
    @synchronized (_uploadedRecords) {
        _uploadedRecords = [_allSubFiles mutableCopy];
        for(UploadSubFileInfo *f in _allSubFiles) {
            if(!f.audioCloudId && !f.srtCloudId)
                [_uploadedRecords removeObject:f];
        }
    }
    [NSKeyedArchiver archiveRootObject:_uploadedRecords toFile:[self archivePath]];
}

#pragma mark- helper
+(NSUInteger)fileSizeAtPath:(NSString *)filePath//获取一个文件的大小
{
    struct stat st;
    if(lstat([filePath cStringUsingEncoding:NSUTF8StringEncoding], &st) == 0)
    {
        return st.st_size;
    }
    return 0;
}

-(NSTimeInterval)getAudioDurationFromFile:(NSString *)audioPath {
    
    AVURLAsset *audioAsset =[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:audioPath] options:nil];
    CMTime audioDuration = audioAsset.duration;
    NSTimeInterval sec = CMTimeGetSeconds(audioDuration);
    return sec;
}

@end


NSString *jsonTemplate = @"{\
  \"split\" :\"\",\
  \"trimmedBeginning\" : \"00:00:01,010\",\
  \"titles\" : {\
    \"en\":\"\",\
    \"zh\":\"\",\
    \"fre\":\"\",\
    \"es\":\"\",\
    \"pt\":\"\",\
    \"ar\":\"\",\
    \"ms\":\"\",\
    \"vi\":\"\",\
    \"ja\":\"\",\
    \"ko\":\"\",\
    \"ru\":\"\",\
    \"de\":\"\",\
    \"pl\":\"\",\
    \"it\":\"\",\
    \"tr\":\"\",\
    \"fa\":\"\"\
  },\
  \"title\" : \"I'm the Title\",\
  \"year\" : \"2020\",\
  \"type\" : \"Film\",\
  \"region\" : \"U.S.A\",\
  \"copyright\" : 1,\
  \"recomendation\" : 8,\
  \"difficulty\" : 6,\
  \"videolink\" : \"\",\
  \"desc\" : \"This part is for description\"\
}";
