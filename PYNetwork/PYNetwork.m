//
//  PYNetwork.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//


#import "PYNetwork.h"
#import "pyutilea.h"
#import <objc/runtime.h>

static NSString *  PYNetworkCache  = @"org.personal.wlpiaoyi.network";
static NSString *  PYNetWorkDatePattern = @"yyyy-MM-dd HH:mm:ss";
static NSTimeInterval   PYNetworkOutTime = 30;
static NSInteger PYNetworkActivityIndicatorIndex = 0;

//==>传输方法
NSString * _Nonnull PYNET_HTTP_GET = @"GET";
NSString * _Nonnull PYNET_HTTP_POST = @"POST";
NSString * _Nonnull PYNET_HTTP_PUT = @"PUT";
NSString * _Nonnull PYNET_HTTP_DELETE = @"DELETE";
///<==

@interface PYIdentityAndTrust:NSObject
kPNA SecIdentityRef  secIdentity;
kPNA SecTrustRef secTrust;
kPNSNN NSArray * cerArray;
@end

@interface PYNetworkDelegate()
@end

@interface PYNetwork()
kPNSNA PYNetworkDelegate * delegate;
@end

@implementation PYNetwork
-(nullable instancetype) init{
    if (self = [super init]) {
        _state = PYNetworkStateUnkwon;
        self.outTime = PYNetworkOutTime;
        self.method = (NSString *)PYNET_HTTP_GET;
        objc_setAssociatedObject([PYNetwork class], (__bridge const void * _Nonnull)(self), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return self;
}
-(BOOL) resume{
    
    @synchronized (self) {
        if(self.session == nil)
            _session = [self createSession];
        self.delegate.network = self;
        if(self.state == PYNetworkStateResume) return false;
        
        if(!self.sessionTask) self.sessionTask = [self createSessionTask];
        if(!self.sessionTask) return false;
        
        [self.sessionTask resume];
        _state = PYNetworkStateResume;
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized([PYNetwork class]){
            PYNetworkActivityIndicatorIndex++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
            });
        }
    });
    
    return true;
    
}
-(BOOL) suspend{
    
    @synchronized(self) {
        
        if(self.state != PYNetworkStateResume) return false;
        if (!self.sessionTask) return false;
        
        [self.sessionTask suspend];
        _state = PYNetworkStateSuspend;
        
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized([PYNetwork class]){
            PYNetworkActivityIndicatorIndex--;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
            });
        }
    });
    
    return true;
}

-(BOOL) cancel{
    if(self.state == PYNetworkStateCancel) return false;
    return [self __cancel];
}
-(BOOL) __cancel{
    
    @synchronized(self) {
        @try{
            if (!self.sessionTask) return false;
            [self.sessionTask cancel];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @synchronized([PYNetwork class]){
                    PYNetworkActivityIndicatorIndex--;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
                    });
                }
            });
        }@finally{
            _state = PYNetworkStateCancel;
            self.sessionTask = nil;
            self.delegate.network = nil;
        }
    }
    
    return true;
    
}


-(void) interrupt{
    _state = PYNetworkStateInterrupt;
    if(self.session){
        [self.session invalidateAndCancel];
        _session = nil;
    }
    [self __cancel];
}



-(nullable NSURLSession*) createSession{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache =  [[NSURLCache alloc] initWithMemoryCapacity:20*1024*1024 diskCapacity:100*1024*1024 diskPath:PYNetworkCache];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    self.delegate = [PYNetworkDelegate new];
    self.delegate.network = self;
    return [NSURLSession sessionWithConfiguration:configuration delegate:self.delegate delegateQueue:[NSOperationQueue mainQueue]];
}
-(nullable NSURLSessionTask *) createSessionTask{
    NSURLRequest * request = nil;
    if([self.method isEqual:PYNET_HTTP_GET] || [self.method isEqual:PYNET_HTTP_DELETE]){
        NSString * url = nil;
        NSString * urlParams = [PYNetwork parseDictinaryToFrom:self.params keySorts:self.keySorts isAddPercentEncoding:YES];
        if([self.url containsString:@"?"]){
            url = kFORMAT(@"%@&%@",self.url, urlParams);
        }else{
            url = kFORMAT(@"%@?%@",self.url, urlParams);
        }
        request = [PYNetwork createRequestWithUrlString:url httpMethod:self.method heads:self.heads params:nil outTime:self.outTime];
        
    }else{
        NSData * pData = [PYNetwork parseDictionaryToHttpBody:self.params keySorts:self.keySorts contentType:self.heads[@"Content-Type"]];
        request = [PYNetwork createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:pData outTime:self.outTime];
    }
    
    if(!self.session) return nil;
    void * targetPointer = (__bridge void *)(self);
    kAssign(self);
    return [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSNumber * has = objc_getAssociatedObject([PYNetwork class], targetPointer);
        if(!has || !has.boolValue){
            return;
        }
        kStrong(self);
        if (self.state != PYNetworkStateCancel && self.state != PYNetworkStateInterrupt &&self.blockComplete) {
            self.blockComplete(error ? error : data, response, self);
            [self cancel];
        }else{
            [self cancel];
        }
    }];
}
-(void) dealloc{
    [self interrupt];
    objc_setAssociatedObject([PYNetwork class], (__bridge const void * _Nonnull)(self), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+(nonnull NSURLRequest *) createRequestWithUrlString:(nonnull NSString*) urlString
                                          httpMethod:(nullable NSString*) httpMethod
                                               heads:(nullable NSDictionary<NSString *, NSString *> *) heads
                                              params:(nullable NSData *) params
                                             outTime:(CGFloat) outTime{
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:outTime];
    request.HTTPMethod = httpMethod;
    if(heads != nil){
        for (NSString * key in heads.allKeys) {
            [request setValue:heads[key] forHTTPHeaderField:key];
        }
    }
    request.HTTPBody = params;
    return  request;
}
+(nonnull NSString *) parseDictinaryToFrom:(NSDictionary<NSString*, id> *) params keySorts:(nullable NSArray<NSString *> *) keySorts isAddPercentEncoding:(BOOL) isAddPercentEncoding{
    NSMutableString * formString = [NSMutableString new];
    if(!keySorts.count) keySorts = params.allKeys;
    for (NSString * key in keySorts) {
        [self parseForFormString:formString key:key value:params[key] isAddPercentEncoding:isAddPercentEncoding];
    }
    return formString.length > 1 ? [formString substringToIndex:formString.length - 1] : formString;
}
//form表单传参全类型支持
+(void)parseForFormString:(NSMutableString *) formString key:(NSString *) key value:(id) value isAddPercentEncoding:(BOOL) isAddPercentEncoding{
    if([value isKindOfClass:[NSString class]]){
        if(isAddPercentEncoding){
            value = [value stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
            key = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
        }
        [formString appendString:key];
        [formString appendString:@"="];
        [formString appendString:value];
        [formString appendString:@"&"];
    }else if([value isKindOfClass:[NSArray class]]){
        for (id v in value) {
            [self parseForFormString:formString key:key value:v isAddPercentEncoding:isAddPercentEncoding];
        }
    }else if([value isKindOfClass:[NSData class]]){
        [self parseForFormString:formString key:key value:[((NSData*)value) toString] isAddPercentEncoding:isAddPercentEncoding];
    }else if([value isKindOfClass:[NSNumber class]]){
        [self parseForFormString:formString key:key value:[((NSNumber*)value) stringValue] isAddPercentEncoding:isAddPercentEncoding];
    }else if([value isKindOfClass:[NSDate class]]){
        [self parseForFormString:formString key:key value:[((NSDate*)value) dateFormateDate:PYNetWorkDatePattern] isAddPercentEncoding:isAddPercentEncoding];
    }else{
        [self parseForFormString:formString key:key value:[(NSDictionary *)[value objectToDictionary] toData] isAddPercentEncoding:isAddPercentEncoding];
    }
    
}
+(nonnull NSData *) parseDictionaryToHttpBody:(NSDictionary<NSString*, id> *) params keySorts:(nullable NSArray<NSString *> *) keySorts contentType:(NSString *) contentType{
    
    if(params == nil) return nil;
    
    if(!contentType || ![contentType isKindOfClass:[NSString class]] || contentType.length == 0){
        contentType = @"application/x-www-form-urlencoded";
    }
    
    if([@"application/json" isEqual:contentType]){
        return [params toData];
    }else if([@"application/x-www-form-urlencoded" isEqual:contentType]){
        return [[self parseDictinaryToFrom:params keySorts:keySorts isAddPercentEncoding:NO] toData];
    }else if(contentType.length > 29 && [[contentType substringToIndex:29] isEqual:@"multipart/form-data;boundary="]){
        NSMutableString * mString = [NSMutableString new];
        NSString * uuid = [contentType substringFromIndex:29];
        [mString appendFormat:@"--%@\r\n",uuid];
        [mString appendFormat:@"Content-Disposition:form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type:%@\r\n\r\n", params[@"fileName"], params[@"contentType"]];
        NSMutableData * mdata = [[mString toData] mutableCopy];
        [mdata appendData:params[uuid]];
        [mdata appendData:[[NSString stringWithFormat:@"\r\n--%@",uuid] toData]];
        mString = [NSMutableString new];
        for(NSString * key in params.allKeys){
            if([key isEqual:@"fileName"] || [key isEqual:@"contentType"] || [key isEqual:uuid]) continue;
            [mString appendFormat:@"\r\nContent-Disposition:form-data; name=\"%@\"\r\n\r\n", key];
            [mString appendFormat:@"%@\r\n--%@", params[key], uuid];
        }
        [mdata appendData:[mString toData]];
        return mdata;
    }
    return nil;
}
@end

@implementation PYIdentityAndTrust @end

@implementation PYNetworkDelegate

#pragma mark - NSURLSessionDelegate ==>
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{}

//NSURLAuthenticationChallenge 中的protectionSpace对象存放了服务器返回的证书信息
//如何处理证书?(使用、忽略、拒绝。。)
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    if(self.network.blockReceiveChallenge && self.network.blockReceiveChallenge(challenge, self.network)){
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];//服务器信任证书
        if(completionHandler) completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
    }else{
        //证书分为好几种：服务器信任的证书、输入密码的证书  。。，所以这里最好判断
        if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]){//服务器信任证书
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if(completionHandler) completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
        }else if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]){//输入密码的证书
            PYIdentityAndTrust * identityAndTrust = [self extractIdentity];
            NSURLCredential * urlCredential =   [[NSURLCredential alloc] initWithIdentity:identityAndTrust.secIdentity certificates:identityAndTrust.cerArray persistence:NSURLCredentialPersistenceForSession];
            completionHandler(NSURLSessionAuthChallengeUseCredential, urlCredential);
        }
    }
    NSLog(@"completionHandler:%@",challenge.protectionSpace.authenticationMethod);
}
#pragma NSURLSessionDelegate <==

-(PYIdentityAndTrust *) extractIdentity{
    OSStatus securityError = errSecSuccess;
    NSString * securtyPath = [NSBundle pathForResource:self.network.certificationName ofType:@"p12" inDirectory:(NSString *)bundleDir];
    NSData * pKCS12Data = [NSData dataWithContentsOfFile:securtyPath];
    NSString * key = (NSString *)kSecImportExportPassphrase;
    NSDictionary * options = @{key:self.network.certificationPassword};//客户端证书密码
    CFArrayRef items = nil;
    securityError = SecPKCS12Import((CFDataRef)pKCS12Data, (CFDictionaryRef)options, &items);
    if(securityError == errSecSuccess){
        CFArrayRef certItems = items;
        NSArray * certItemsArray = (__bridge NSArray *)(certItems);
        NSObject * dict = certItemsArray.firstObject;
        NSDictionary * certEntry = nil;
        if((certEntry = (NSDictionary *)dict)){
            NSObject * identityPointer = certEntry[@"identity"];
            SecIdentityRef secIdentityRef = (__bridge SecIdentityRef)(identityPointer);
            
            NSObject * trustPointer = certEntry[@"trust"];
            SecTrustRef trustRef = (__bridge SecTrustRef)(trustPointer);
            
            NSArray * chainPointer = certEntry[@"chain"];
            
            PYIdentityAndTrust * identityAndTrust = [PYIdentityAndTrust new];
            identityAndTrust.secIdentity = secIdentityRef;
            identityAndTrust.secTrust = trustRef;
            identityAndTrust.cerArray = chainPointer;
            
            return identityAndTrust;
        }
    }
    return nil;
}

#pragma NSURLSessionTaskDelegate ==>
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    if(self.network.blockSendProgress){
        self.network.blockSendProgress(self.network, bytesSent, totalBytesSent);
    }
}
#pragma NSURLSessionTaskDelegate <==
@end
