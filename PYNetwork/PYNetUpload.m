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
#import "PYNetworkDelegate.h"

@interface PYNetwork()

kPNSNA PYNetworkDelegate * delegate;

@end

@interface PYNetUpload()<NSURLSessionDelegate>

PYPNSNA NSArray<PYNetUploadAttachment *> * attachments;

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

/**
 分段压缩上传
 */
-(BOOL) resumeWithData:(nonnull NSData *) data fileName:(nonnull NSString *) fileName contentType:(nonnull NSString *)contentType{
    PYNetUploadAttachment * params = [PYNetUploadAttachment new];
    params.data = data;
    params.fileName = fileName;
    params.contentType = contentType;
    return [self resumeWithData:@[params]];
}
-(BOOL) resumeWithData:(nonnull NSArray<PYNetUploadAttachment *> *) files{
    self.attachments = files;
    return [super resume];
}

//-(BOOL) resumeWithPath:(nonnull NSString *) path{
//    self.filePath = path;
//    return [super resume];
//}

-(BOOL) resume{
    return [super resume];
}
-(BOOL) suspend{
    return [super suspend];
}
-(BOOL) cancel{
    return [super cancel];
}


-(nullable NSURLSessionTask *) createDefaultSessionTask{
    if(![NSString isEnabled:self.url]) return nil;
    self.delegate = [PYNetworkDelegate new];
    self.delegate.network = self;
    NSString * uuid = [PYNetUpload uuid];
    NSData * mdata = [self.class parseParamsToMultipart:self.attachments uuid:uuid params:self.params];
    NSMutableDictionary * mHeaders = self.heads ? [self.heads mutableCopy] : [NSMutableDictionary new];
    [mHeaders setDictionary:@{@"Content-Type":[NSString stringWithFormat:@"multipart/form-data;boundary=%@",uuid]}];
    NSURLRequest * request = [PYNetUpload createRequestWithUrlString:self.url httpMethod:self.method heads:mHeaders params:nil outTime:self.outTime];
    void * targetPointer = (__bridge void *)(self);
    kAssign(self);
    return [self.session uploadTaskWithRequest:request fromData:mdata completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSNumber * has = objc_getAssociatedObject([PYNetwork class], targetPointer);
        if(!has || !has.boolValue){
            return;
        }
        kStrong(self);
        if(error){
            if (self.blockCancel) {
                self.blockCancel(data, error, self);
            }
        }else{
            if (self.blockComplete) {
                self.blockComplete(data, response, self);
            }
        }
    }];
    return nil;
}

/**
 将param转换成Multipart数据结构
 */
+(nullable NSData *) parseParamsToMultipart:(NSArray<PYNetUploadAttachment *> *) attachments uuid:(NSString *) uuid params:(NSDictionary *) params{
    
    NSMutableData * mData = [NSMutableData new];
    for(NSString * key in params){
        NSMutableString * mString = [NSMutableString new];
        [mString appendFormat:@"--%@", uuid];
        [mString appendFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
        [mString appendFormat:@"%@\r\n", params[key]];
        [mData appendData:[mString toData]];
    }
    for (PYNetUploadAttachment * attachment in attachments) {
        NSMutableString * mString = [NSMutableString new];
        [mString appendFormat:@"--%@\r\n",uuid];
        [mString appendString:@"Content-Disposition: form-data; "];
        [mString appendFormat:@"name=\"%@\"; ", attachment.file ? : @"file"];
        
//        [mString appendFormat:@"filename=\"%@\"\r\n", attachment.fileName];
//        [mString appendFormat:@"Content-Type:%@\r\n\r\n", attachment.contentType];
        
        if([NSString isEnabled:attachment.fileName]) [mString appendFormat:@"filename=\"%@\"", attachment.fileName];
        [mString appendString:@"\r\n"];
        if([NSString isEnabled:attachment.contentType])[mString appendFormat:@"Content-Type:%@\r\n", attachment.contentType];
        [mString appendString:@"\r\n"];
        
        [mData appendData:[mString toData]];
        [mData appendData:attachment.data];
        [mData appendData:[@"\r\n" toData]];
        
        
//            NSMutableString * mString = [NSMutableString new];
//            [mString appendFormat:@"--%@\r\n",uuid];
//            [mString appendString:@"Content-Disposition: form-data; "];
//            [mString appendFormat:@"name=\"%@\"", attachment.file ? : @"file"];
//            if([NSString isEnabled:attachment.fileName]) [mString appendFormat:@"; filename=\"%@\"\r\n", attachment.fileName];
//            [mString appendString:@"\r\n"];
//            if([NSString isEnabled:attachment.contentType]) [mString appendFormat:@"Content-Type:%@\r\n\r\n", attachment.contentType];
//            [mString appendString:@"\r\n"];
//            [mData appendData:[mString toData]];
//            [mData appendData:attachment.data];
//            [mData appendData:[@"\r\n" toData]];
    }
    [mData appendData:[kFORMAT(@"--%@--\r\n", uuid) toData]];
    return mData;
}


@end

@implementation PYNetUploadAttachment
@end
