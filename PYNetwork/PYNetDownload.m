//
//  PYNetDownload.m
//  UtileScourceCode
//
//  Created by wlpiaoyi on 15/11/27.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYNetDownload.h"
#import "pyutilea.h"


static NSString *  STATIC_DOWNLOAD_CACHE  = @"org.personal.wlpiaoyi.network.downloadcache";
static NSTimeInterval   STATIC_OUT_TIME = 30;

@interface PYNetDownload()<NSURLSessionDelegate>
@property (nonatomic, assign, nullable) NSURLSession * session;
@property (nonatomic) BOOL flagBeginDownload;
@property (nonatomic, copy, nullable) void (^_blockSuccess_)(id _Nullable data, PYNetDownload * _Nonnull target);
@property (nonatomic, copy, nullable) void (^_blockFaild_)(id _Nullable data, PYNetDownload * _Nonnull target)  ;
@property (nonatomic, copy, nullable) void (^_blockCancel_)(id _Nullable data, PYNetDownload * _Nonnull target) ;
@property (nonatomic, copy, nullable) BOOL (^_blockReceiveChallenge_)(id _Nullable data, PYNetDownload * _Nonnull target) ;
@property (nonatomic, copy, nullable) void (^ _blockProgress_) (PYNetDownload * _Nonnull target, int64_t currentBytes, int64_t totalBytes);
@end

@implementation PYNetDownload

-(instancetype) init{
    if (self = [super init]) {
        self.outTime = STATIC_OUT_TIME;
    }
    return self;
}

/**
 请求反馈
 */
//==>
-(instancetype _Nonnull) setBlockSuccess:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockSuccess{
    self._blockSuccess_ = blockSuccess;
    return self;
}
-(instancetype _Nonnull) setBlockFaild:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockFaild{
    self._blockFaild_ = blockFaild;
    return self;
}

-(instancetype _Nonnull) setBlockProgress:(void (^_Nullable) (PYNetDownload * _Nonnull target,int64_t currentBytes, int64_t totalBytes)) blockProgress;{
    self._blockProgress_ = blockProgress;
    return self;
}
//下载请求恢复数取消
-(instancetype _Nonnull) setBlockCancel:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockCancel;{
    self._blockCancel_ = blockCancel;
    return self;
}

-(instancetype _Nonnull) setBlockReceiveChallenge:(BOOL (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockReceiveChallenge{
    self._blockReceiveChallenge_ = blockReceiveChallenge;
    return self;
}
///<==
-(BOOL) resume{
    @synchronized(self) {
        if (!_task) {
            if (!self.dataResume && !self.stringUrl) {
                return false;
            }
            if (![NSString isEnabled:self.identifier]) {
                self.identifier = PYUUID(64);
            }
            NSURLSession *session = [PYNetDownload createSessionWithIdentifier:self.identifier delegate:self];
            if (!session) {return false;}
            
            NSURLSessionDownloadTask *downloadTask  = [PYNetDownload createDownloadTask:session downLoadString:self.stringUrl resumedata:self.dataResume];
            if (!downloadTask) {return false;}
            
            _task = downloadTask;
        }
    }
    [_task resume];
    self.flagBeginDownload = false;
    return true;
}
-(BOOL) suspend{
    @synchronized(self) {
        if (!self.task) {
            return false;
        }
        [self.task suspend];
    }
    return true;
}
-(BOOL) cancel{
    @synchronized(self) {
        if (!self.task) {
            return false;
        }
       @weakify(self)
        [(NSURLSessionDownloadTask*)self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            @strongify(self)
            self.dataResume = resumeData;
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
    if (self._blockProgress_) {
        self._blockProgress_(self, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

//下载任务完成,这个方法在下载完成时触发，它包含了已经完成下载任务得 Session Task,Download Task和一个指向临时下载文件得文件路径
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSString *relativePath = [location relativePath];
    if (self._blockSuccess_) {
        __blockSuccess_(relativePath,self);
    }
}

//从已经保存的数据中恢复下载任务的委托方法，fileOffset指定了恢复下载时的文件位移字节数：
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        if (self._blockFaild_) {
            __blockFaild_(error,self);
        }
    }
}

#pragma mark - NSURLSessionDelegate ==>
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
}
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session NS_AVAILABLE_IOS(7_0){
}

//NSURLAuthenticationChallenge 中的protectionSpace对象存放了服务器返回的证书信息
//如何处理证书?(使用、忽略、拒绝。。)
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    if(self._blockReceiveChallenge_ && __blockReceiveChallenge_(challenge, self)){
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];//服务器信任证书
        if(completionHandler) completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }else{
        //证书分为好几种：服务器信任的证书、输入密码的证书  。。，所以这里最好判断
        if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){//服务器信任证书
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];//服务器信任证书
            if(completionHandler) completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
        }
    }
    NSLog(@"....completionHandler---:%@",challenge.protectionSpace.authenticationMethod);
    
}
#pragma NSURLSessionDelegate <==

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
                if (!self.task) {
                    return;
                }
                [self cancel];
            }
        });
    });
}

+(NSURLSessionDownloadTask*) createDownloadTask:(NSURLSession*)session
                                 downLoadString:(NSString*) downLoadstr
                                     resumedata:(NSData*) resumedata{
    if (resumedata) {
        return [session downloadTaskWithResumeData:resumedata];
    }else{
        NSURL *URL = [NSURL URLWithString:downLoadstr];
        return [session downloadTaskWithURL:URL];
    }
}

+(NSURLSession*) createSessionWithIdentifier:(nonnull NSString *) identifier delegate:(nullable id <NSURLSessionDelegate>) delegate{
    //这个sessionConfiguration 很重要， com.zyprosoft.xxx  这里，这个com.company.这个一定要和 bundle identifier 里面的一致，否则ApplicationDelegate 不会调用handleEventsForBackgroundURLSession代理方法
    NSURLSessionConfiguration *configuration;
    if (IOS8_OR_LATER) {
        configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    }else{
        configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
    }
    configuration.URLCache =   [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024*1024 diskCapacity:100 * 1024*1024 diskPath:STATIC_DOWNLOAD_CACHE];
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    return [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];
}
@end
