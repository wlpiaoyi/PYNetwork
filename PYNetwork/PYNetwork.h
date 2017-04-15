//
//  PYNetwork.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "pyutilea.h"

static NSString * _Nonnull  PYNetworkCache;
static NSTimeInterval   PYNetworkOutTime;


//==>传输方法
extern const NSString * _Nonnull PYNET_HTTP_GET;
extern const NSString * _Nonnull PYNET_HTTP_POST;
extern const NSString * _Nonnull PYNET_HTTP_PUT ;
extern const NSString * _Nonnull PYNET_HTTP_DELETE;
///<==

@interface PYNetwork : NSObject
@property (nonatomic) NSTimeInterval outTime;
PYPNSNA id userInfo;
PYPNSNN NSURLSession * session;


PYPNSNN NSString * url;
PYPNSNN NSString * method;
PYPNSNA NSDictionary<NSString *, id> * params;
PYPNSNA NSDictionary<NSString *, NSString *> * heads;
PYPNSNN NSURLSessionTask * sessionTask;

PYPNCNA void (^blockSendProgress) (PYNetwork * _Nonnull target, int64_t currentBytes, int64_t totalBytes);
PYPNCNA BOOL (^blockReceiveChallenge)(id _Nullable data, PYNetwork * _Nonnull target) ;
PYPNCNA void (^blockComplete)(id _Nullable data, PYNetwork * _Nonnull target);

PYPNSNA NSString * certificationName;
PYPNSNA NSString * certificationPassword;

-(BOOL) resume;
-(BOOL) suspend;
-(BOOL) cancel;

+(nonnull NSURLRequest *) createRequestWithUrlString:(nonnull NSString*) urlString
                                          httpMethod:(nullable NSString*) httpMethod
                                               heads:(nullable NSDictionary<NSString *, NSString *> *) heads
                                              params:(nullable NSDictionary<NSString *, NSString *> *) params;
@end
