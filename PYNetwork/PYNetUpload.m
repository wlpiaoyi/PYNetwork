//
//  PYNetUpload.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "PYNetUpload.h"
@interface PYNetUpload()<NSURLSessionDelegate>
@property (nonatomic, strong, nonnull) NSURLSessionUploadTask * uploadTask;
@end
@implementation PYNetUpload
-(instancetype) init{
    if (self = [super init]) {
    }
    return self;
}

-(BOOL) resume{
    NSAssert(false, @"PYNetupload is not support resume");
    return false;
}
-(BOOL) resumeWithData:(nonnull NSData *) data{
    @synchronized (self) {
        if(self.url == nil) return false;
        NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:self.params];
        @weakify(self);
        self.uploadTask = [self.session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            @strongify(self);
            if (self.blockComplete) {
                self.blockComplete(error ? error : data,self);
            }
        }];
        if(self.uploadTask == nil) return false;
        [self.uploadTask resume];
    }
    return true;
}
-(BOOL) resumeWithPath:(nonnull NSString *) path{
    @synchronized (self) {
        if(self.url == nil) return false;
        NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:self.params];
        @weakify(self);
        self.uploadTask = [self.session uploadTaskWithRequest:request fromFile: [NSURL URLWithString:path] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            @strongify(self);
            if (self.blockComplete) {
                self.blockComplete(error ? error : data,self);
            }
        }];
        if(self.uploadTask == nil) return false;
        [self.uploadTask resume];
    }
    return true;
}
@end
