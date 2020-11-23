//
//  PYNetDownload.m
//  UtileScourceCode
//
//  Created by wlpiaoyi on 15/11/27.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import "PYNetDownload.h"
#import "PYNetwork+__DataParse.h"
#import "PYNetDownloadDelegate.h"
#import <objc/runtime.h>

@interface PYNetwork()
kPNSNA PYNetworkDelegate * delegate;
@end


@interface PYNetDownload()
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
    [super cancel];
    @synchronized(self) {
        if(self.state == PYNetworkStateCancel ) return NO;
        if(self.state == PYNetworkStateResume ) return NO;
        //必须等到cancel block回调时才能回收
        [(NSURLSessionDownloadTask*)self.sessionTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (self.state != PYNetworkStateCompleted && self._blockCancel_) {
                self._blockCancel_(resumeData, nil, self);
            }
        }];
    }
    return true;
}

-(void) stop{
    if(self._blockCancel_) self._blockCancel_(nil, nil, self);
    self._blockCancel_ = nil;
    [super stop];
}

-(nullable NSURLSessionTask *) createDefaultSessionTask{
    if (!self.session) return nil;
    NSURLSessionDownloadTask *downloadTask = nil;
    if(self.url){
        NSData * pData = [PYNetwork parseParamsToHttpBody:self.params contentType:self.heads[@"Content-Type"]];
        NSURLRequest * request = [PYNetwork createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:pData outTime:self.outTime];
        downloadTask = [self.session downloadTaskWithRequest:request];
    }
    return downloadTask;
}

-(nullable NSURLSession*) createDefaultSession{
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

