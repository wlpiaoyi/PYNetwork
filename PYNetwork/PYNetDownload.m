//
//  PYNetDownload.m
//  UtileScourceCode
//
//  Created by wlpiaoyi on 15/11/27.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYNetDownload.h"
#import "PYNetwork+__DataParse.h"
#import <objc/runtime.h>

@interface PYNetDownloadDelegate:PYNetworkDelegate<NSURLSessionDownloadDelegate>
@end

@interface PYNetDownload()
kPNSNA PYNetDownloadDelegate * delegate;
@property (nonatomic, copy, nullable) void (^_blockCancel_)(id _Nullable data, NSURLResponse * _Nullable response, PYNetDownload * _Nonnull target) ;
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
//====================================>

-(instancetype _Nonnull) setBlockDownloadProgress:(void (^_Nullable) (PYNetDownload * _Nonnull target,int64_t currentBytes, int64_t totalBytes)) blockProgress;{
    self._blockDownloadProgress_ = blockProgress;
    return self;
}
//下载请求恢复数取消
-(instancetype _Nonnull) setBlockCancel:(void (^_Nullable)(id _Nullable data, NSURLResponse * _Nullable response, PYNetDownload * _Nonnull target)) blockCancel;{
    self._blockCancel_ = blockCancel;
    return self;
}
///<====================================

-(BOOL) cancel{
    @synchronized(self) {
        if (!self.sessionTask) {
            self.delegate.network= nil;
            self.delegate = nil;
            return false;
        }
        //必须等到cancel block回调时才能回收
        [(NSURLSessionDownloadTask*)self.sessionTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (self.state != PYNetworkStateCancel && self._blockCancel_) {
                self._blockCancel_(resumeData, nil, self);
            }
            [super cancel];
            self.delegate.network= nil;
            self.delegate = nil;
        }];
    }
    return true;
}

-(void) interrupt{
    self._blockCancel_ = nil;
    [super interrupt];
}

-(nullable NSURLSessionTask *) createSessionTask{
    if (!self.session) return nil;
    NSURLSessionDownloadTask *downloadTask = nil;
    if(self.url){
        NSData * pData = [PYNetwork parseParamsToHttpBody:self.params contentType:self.heads[@"Content-Type"]];
        NSURLRequest * request = [PYNetwork createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:pData outTime:self.outTime];
        downloadTask = [self.session downloadTaskWithRequest:request];
    }
    return downloadTask;
}

-(nullable NSURLSession*) createSession{
    //这个sessionConfiguration 很重要， com.zyprosoft.xxx  这里，这个com.company.这个一定要和 bundle identifier 里面的一致，否则ApplicationDelegate 不会调用handleEventsForBackgroundURLSession代理方法
    _identifier = PYUUID(64);
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    self.delegate = [PYNetDownloadDelegate new];
    self.delegate.network = self;
    
    return [NSURLSession sessionWithConfiguration:configuration delegate:self.delegate delegateQueue:[NSOperationQueue mainQueue]];
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
    return true;
}

@end


@implementation PYNetDownloadDelegate

#pragma mark - NSURLSessionDownloadDelegate==>
//这个方法用来跟踪下载数据并且根据进度刷新ProgressView
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    if (((PYNetDownload *)self.network)._blockDownloadProgress_) {
        ((PYNetDownload *)self.network)._blockDownloadProgress_(((PYNetDownload *)self.network), totalBytesWritten, totalBytesExpectedToWrite);
    }
}

//下载任务完成,这个方法在下载完成时触发，它包含了已经完成下载任务得 Session Task,Download Task和一个指向临时下载文件得文件路径
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSString *relativePath = [location relativePath];
    if (((PYNetDownload *)self.network).blockComplete) {
        ((PYNetDownload *)self.network).blockComplete(relativePath, nil, ((PYNetDownload *)self.network));
        [((PYNetDownload *)self.network) cancel];
    }
}

//从已经保存的数据中恢复下载任务的委托方法，fileOffset指定了恢复下载时的文件位移字节数：
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        if (((PYNetDownload *)self.network).blockComplete) {
            ((PYNetDownload *)self.network).blockComplete(error, nil, ((PYNetDownload *)self.network));
            [((PYNetDownload *)self.network) cancel];
        }
    }
}
#pragma mark - NSURLSessionDownloadDelegate <==
@end
