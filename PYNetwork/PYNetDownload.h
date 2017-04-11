//
//  PYNetDownload.h
//  UtileScourceCode
//
//  Created by wlpiaoyi on 15/11/27.
//  Copyright © 2015年 wlpiaoyi. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * _Nonnull  STATIC_DOWNLOAD_CACHE;
static NSTimeInterval   STATIC_OUT_TIME;

@interface PYNetDownload : NSObject
//http请求反馈
@property (nonatomic) NSTimeInterval outTime;
@property (nonatomic, strong, nullable) NSString * identifier;
@property (nonatomic, strong, nullable) id userInfo;
//下载地址
@property (nonatomic, strong, nullable) NSString * stringUrl;
@property (nonatomic, strong, nullable) NSData * dataResume;
@property (nonatomic, readonly, nonnull) NSURLSessionTask * task;

/**
 请求反馈
 */
//==>
-(instancetype _Nonnull) setBlockSuccess:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockSuccess;
-(instancetype _Nonnull) setBlockFaild:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockFaild;
-(instancetype _Nonnull) setBlockProgress:(void (^_Nullable) (PYNetDownload * _Nonnull target,int64_t currentBytes, int64_t totalBytes)) blockProgress;
//下载请求恢复数取消
-(instancetype _Nonnull) setBlockCancel:(void (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockCancel;
-(instancetype _Nonnull) setBlockReceiveChallenge:(BOOL (^_Nullable)(id _Nullable data, PYNetDownload * _Nonnull target)) blockReceiveChallenge;
///<==
-(BOOL) resume;
-(BOOL) suspend;
-(BOOL) cancel;

@end
