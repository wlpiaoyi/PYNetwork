//
//  PYNetUpload.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "PYNetwork.h"

@interface PYNetUploadAttachment : NSObject

PYPNSNA NSString * file;
PYPNSNA NSData * data;
PYPNSNA NSString * fileName;
PYPNSNA NSString * contentType;

@end

@interface PYNetUpload : PYNetwork

kPNCNA void (^blockCancel)(id _Nullable data, NSError * _Nullable error, PYNetwork * _Nonnull target);

/**
 分段压缩上传
 */
-(BOOL) resumeWithData:(nonnull NSData *) data fileName:(nonnull NSString *) fileName contentType:(nonnull NSString *)contentType;

/**
 分段压缩上传
 */
-(BOOL) resumeWithData:(nonnull NSArray<PYNetUploadAttachment *> *) files;

///**
// 直接上传
// */
//-(BOOL) resumeWithPath:(nonnull NSString *) path;

@end
