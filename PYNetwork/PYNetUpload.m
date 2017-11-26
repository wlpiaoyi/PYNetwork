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
        self.isNetworkActivityIndicatorVisible = false;
    }
    return self;
}

-(BOOL) resume{
    NSAssert(false, @"PYNetupload is not support resume");
    return false;
}
+(NSString *) uuid{
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);
    CFStringRef uuid_string_ref= CFUUIDCreateString(NULL, uuid_ref);
    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];
    CFRelease(uuid_ref);
    CFRelease(uuid_string_ref);
    return [uuid lowercaseString];
}
-(BOOL) resumeWithData:(nonnull NSData *) data fileName:(nonnull NSString *) fileName contentType:(nonnull NSString *)contentType{
    @synchronized (self) {
        if(self.url == nil) return false;
        
        self.session = [self createSession];
        NSMutableDictionary * mHeaders = self.heads ? [self.heads mutableCopy] : [NSMutableDictionary new];
        NSString *uuid = [PYNetUpload uuid];
        [mHeaders setDictionary:@{@"Content-Type":[NSString stringWithFormat:@"multipart/form-data;boundary=%@",uuid]}];
        NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:mHeaders params:nil];
        NSMutableDictionary * mParams = self.params ? [self.params mutableCopy] : [NSMutableDictionary new];
        [mParams setObject:fileName forKey:@"fileName"];
        [mParams setObject:contentType forKey:@"contentType"];
        [mParams setObject:data forKey:uuid];
        NSData * mdata = [PYNetwork parseDictionaryToHttpBody:mParams contentType:mHeaders[@"Content-Type"]];
        @unsafeify(self);
        self.uploadTask = [self.session uploadTaskWithRequest:request fromData:mdata completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
        
        NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:nil];
        @unsafeify(self);
        self.uploadTask = [self.session uploadTaskWithRequest:request fromFile: [NSURL fileURLWithPath:path] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            @strongify(self);
            if (self.blockComplete) {
                self.blockComplete(error ? error : data,self);
                [self cancel];
            }
        }];
        if(self.uploadTask == nil) return false;
        [self.uploadTask resume];
    }
    return true;
}

@end
