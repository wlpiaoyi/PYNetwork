//
//  PYNetUpload.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "PYNetUpload.h"
#import "PYNetwork+__DataParse.h"
#import <objc/runtime.h>

@interface PYNetUpload()<NSURLSessionDelegate>

PYPNSNA NSData * updateData;
PYPNSNA NSString * fileName;
PYPNSNA NSString * contentType;

PYPNSNA NSString * filePath;

@end
@implementation PYNetUpload
-(instancetype) init{
    if (self = [super init]) {
        self.method = PYNET_HTTP_PUT;
    }
    return self;
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
    self.updateData = data;
    self.fileName = fileName;
    self.contentType = contentType;
    return [super resume];
}

-(BOOL) resumeWithPath:(nonnull NSString *) path{
    self.filePath = path;
    return [super resume];
}

-(BOOL) resume{
    return [super resume];
}
-(BOOL) suspend{
    return [super suspend];
}
-(BOOL) cancel{
    return [super cancel];
}


-(nullable NSURLSessionTask *) createSessionTask{
    if(![NSString isEnabled:self.url]) return nil;
    if([NSString isEnabled:self.filePath]){
        NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:nil outTime:self.outTime];
        void * targetPointer = (__bridge void *)(self);
        kAssign(self);
        return [self.session uploadTaskWithRequest:request fromFile: [NSURL fileURLWithPath:self.filePath] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSNumber * has = objc_getAssociatedObject([PYNetwork class], targetPointer);
            if(!has || !has.boolValue){
                return;
            }
            kStrong(self);
            if (self.blockComplete) {
                self.blockComplete(error ? error : data, nil, self);
                [self cancel];
            }
        }];
    }else if(self.updateData && [NSString isEnabled:self.fileName] && [NSString isEnabled:self.contentType]){
        NSMutableDictionary * mHeaders = self.heads ? [self.heads mutableCopy] : [NSMutableDictionary new];
        NSString *uuid = [PYNetUpload uuid];
        [mHeaders setDictionary:@{@"Content-Type":[NSString stringWithFormat:@"multipart/form-data;boundary=%@",uuid]}];
        NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:mHeaders params:nil outTime:self.outTime];
        NSMutableDictionary * mParams = self.params ? [self.params mutableCopy] : [NSMutableDictionary new];
        [mParams setObject:self.fileName forKey:@"fileName"];
        [mParams setObject:self.contentType forKey:@"contentType"];
        [mParams setObject:self.updateData forKey:uuid];
        NSData * mdata = [PYNetwork parseParamsToHttpBody:mParams contentType:mHeaders[@"Content-Type"]];
        void * targetPointer = (__bridge void *)(self);
        kAssign(self);
        return [self.session uploadTaskWithRequest:request fromData:mdata completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSNumber * has = objc_getAssociatedObject([PYNetwork class], targetPointer);
            if(!has || !has.boolValue){
                return;
            }
            kStrong(self);
            if (self.blockComplete) {
                self.blockComplete(error ? error : data, nil, self);
            }
            [self cancel];
        }];
    }
    return nil;
}


@end
