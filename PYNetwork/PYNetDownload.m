//
//  PYNetDownload.m
//  UtileScourceCode
//
//  Created by wlpiaoyi on 15/11/27.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYNetDownload.h"
#import "pyutilea.h"


@interface PYNetDownload()<NSURLSessionDelegate>
@property (nonatomic) BOOL flagBeginDownload;
@property (nonatomic, copy, nullable) void (^_blockCancel_)(id _Nullable data, PYNetDownload * _Nonnull target) ;
@property (nonatomic, copy, nullable) void (^ _blockDownloadProgress_) (PYNetDownload * _Nonnull target, int64_t currentBytes, int64_t totalBytes);
@end

@implementation PYNetDownload

-(instancetype) init{
    if (self = [super init]) {
    }
    return self;
}

/**
 请求反馈
 */
//==>

-(instancetype _Nonnull) setBlockDownloadProgress:(void (^_Nullable) (PYNetDownload * _Nonnull target,int64_t currentBytes, int64_t totalBytes)) blockProgress;{
    self._blockDownloadProgress_ = blockProgress;
    return self;
}
//下载请求恢复数取消
-(instancetype _Nonnull) setBlockCancel:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockCancel;{
    self._blockCancel_ = blockCancel;
    return self;
}

///<==
-(BOOL) resume{
    @synchronized(self) {
        if (!self.sessionTask) {
            if (!self.session) {return false;}
            
            NSURLSessionDownloadTask *downloadTask = nil;
            if(self.url){
                NSURLRequest * request = [PYNetwork createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:self.params];
                downloadTask = [self.session downloadTaskWithRequest:request];
            }
            if (!downloadTask) {return false;}
            
            self.sessionTask = downloadTask;
            
        }
    }
    [self.sessionTask resume];
    self.flagBeginDownload = false;
    return true;
}

//if (IOS8_OR_LATER) {
//    configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
//}else{
//    configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
//}
-(nonnull NSURLSession*) createSession{
    //这个sessionConfiguration 很重要， com.zyprosoft.xxx  这里，这个com.company.这个一定要和 bundle identifier 里面的一致，否则ApplicationDelegate 不会调用handleEventsForBackgroundURLSession代理方法
    _identifier = PYUUID(64);
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
    configuration.URLCache =   [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024*1024 diskCapacity:100 * 1024*1024 diskPath:PYNetworkCache];
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    return [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
}


-(BOOL) resumeWithData:(nonnull NSData *) data{
    @synchronized(self) {
        if (!self.sessionTask) {
            if (!self.session) {return false;}
            
            NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithResumeData:data];
            if (!downloadTask) {return false;}
            
            self.sessionTask = downloadTask;
            
        }
    }
    [self.sessionTask resume];
    self.flagBeginDownload = false;
    return true;
}

-(BOOL) cancel{
    @synchronized(self) {
        if (!self.sessionTask) {
            return false;
        }
       @weakify(self)
        [(NSURLSessionDownloadTask*)self.sessionTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            @strongify(self)
            if (self._blockCancel_) {
                self._blockCancel_(resumeData, self);
            }
        }];
    }
    return true;
}

#pragma mark - NSURLSessionDownloadDelegate
//这个方法用来跟踪下载数据并且根据进度刷新ProgressView
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    self.flagBeginDownload = true;
    if (self._blockDownloadProgress_) {
        self._blockDownloadProgress_(self, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

//下载任务完成,这个方法在下载完成时触发，它包含了已经完成下载任务得 Session Task,Download Task和一个指向临时下载文件得文件路径
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSString *relativePath = [location relativePath];
    if (self.blockComplete) {
        self.blockComplete(relativePath, self);
    }
}

//从已经保存的数据中恢复下载任务的委托方法，fileOffset指定了恢复下载时的文件位移字节数：
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        if (self.blockComplete) {
            self.blockComplete(error,self);
        }
    }
}



-(void) setFlagBeginDownload:(BOOL)flagBeginDownload{
    _flagBeginDownload = flagBeginDownload;
    if (_flagBeginDownload) {
        return;
    }
    @unsafeify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self);
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        // 耗时的操作
        while (!self.flagBeginDownload) {
            if ([PYReachabilityNotification instanceSingle].status == kNotReachable) {
                break;
            }
            if ([NSDate timeIntervalSinceReferenceDate] > currentTime + self.outTime) {
                break;
            }
            [NSThread sleepForTimeInterval:.5];
        }
        if (self.flagBeginDownload) {
            return;
        }
        
        @unsafeify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            // 更新界面
            if (!self.flagBeginDownload) {
                if (!self.sessionTask) {
                    return;
                }
                [self cancel];
            }
        });
    });
}

@end
