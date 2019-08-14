//
//  PYNetwork.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//


#import "PYNetwork.h"
#import "PYNetwork+__DataParse.h"
#import "PYNetwork+__ContenType.h"

#import "pyutilea.h"
#import <objc/runtime.h>


static NSInteger PYNetworkActivityIndicatorIndex = 0;

NSTimeInterval PYNET_OUTTIME = 30;

NSString *  PYNET_DATE_PATTERN = @"yyyy-MM-dd HH:mm:ss";

CFStringRef PYNET_PERCENT_PARAM = CFSTR(":/?#[]@!$’()*+,;");
CFStringRef PYNET_PERCENT_FIELD = CFSTR(":/?#[]@!$&’()*+,;=");

//==>传输方法
NSString * _Nonnull PYNET_HTTP_GET = @"GET";
NSString * _Nonnull PYNET_HTTP_POST = @"POST";
NSString * _Nonnull PYNET_HTTP_PUT = @"PUT";
NSString * _Nonnull PYNET_HTTP_DELETE = @"DELETE";
///<==

//NSString * PYNetworkDefaultCharset = @"UTF-8";
//NSString * PYNetworkXWWWFormContentType = @"application/x-www-form-urlencoded;";
//NSString * PYNetworkJsonContentType = @"application/json;";
//NSString * PYNetworkXmlContentType = @"application/xml;";
//NSString * PYNetworkMutipartFormContentType = @"multipart/form-data;";

static id PYNETWORK_SYN = @"";

@interface PYIdentityAndTrust:NSObject
kPNA SecIdentityRef  secIdentity;
kPNA SecTrustRef secTrust;
kPNSNN NSArray * cerArray;
kPNSNA NSData * bodyData;
@end

@interface PYNetworkDelegate()
@end

@interface PYNetwork(){
@private
    id synrequest;
}
kPNSNA PYNetworkDelegate * delegate;
@end

@implementation PYNetwork
-(nullable instancetype) init{
    if (self = [super init]) {
        synrequest = @"";
        _state = PYNetworkStateUnkwon;
        self.outTime = PYNET_OUTTIME;
        self.method = (NSString *)PYNET_HTTP_GET;
        objc_setAssociatedObject([PYNetwork class], (__bridge const void * _Nonnull)(self), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return self;
}

-(BOOL) resume{
    @synchronized(synrequest){
        if(self.state == PYNetworkStateResume) return false;
        if(self.session == nil)
            _session = [self createSession];
        self.delegate.network = self;
        
        if(self.state == PYNetworkStateResume) return false;
        
        if(!self.sessionTask) self.sessionTask = [self createSessionTask];
        if(!self.sessionTask) return false;
        
        [self.sessionTask resume];
        _state = PYNetworkStateResume;
        [PYNetwork addNetworkActivityIndicatorVisibel];
    }
    
    return true;
    
}
-(BOOL) suspend{
    @synchronized(synrequest) {
        if(self.state != PYNetworkStateResume) return false;
        if (!self.sessionTask) return false;
        
        [self.sessionTask suspend];
        _state = PYNetworkStateSuspend;
    }
    
    [PYNetwork removeNetworkActivityIndicatorVisibel];
    
    return true;
}

-(BOOL) cancel{
    @synchronized(synrequest){
        if(self.state != PYNetworkStateResume) return false;
        _state = PYNetworkStateCancel;
        if([self __cancel]){
            [PYNetwork removeNetworkActivityIndicatorVisibel];
            return true;
        }else return false;
    }
}

-(void) interrupt{
    @synchronized(synrequest){
        if(_state == PYNetworkStateResume){
            [PYNetwork removeNetworkActivityIndicatorVisibel];
        }
        _state = PYNetworkStateInterrupt;
        if(self.session){
            [self.session invalidateAndCancel];
            [self __cancel];
            _session = nil;
        }
    }
}

-(BOOL) __cancel{
    @try{
        if (!self.sessionTask) return false;
        [self.sessionTask cancel];
    }@finally{
        self.sessionTask = nil;
        self.delegate.network = nil;
    }
    return true;
}

+(void) addNetworkActivityIndicatorVisibel{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(PYNETWORK_SYN){
            PYNetworkActivityIndicatorIndex++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
            });
        }
    });
}

+(void) removeNetworkActivityIndicatorVisibel{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(PYNETWORK_SYN){
            PYNetworkActivityIndicatorIndex--;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
            });
        }
    });
}


-(nullable NSURLSession*) createSession{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:20 * 1024 * 1024 diskCapacity:0 diskPath:nil];
    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    self.delegate = [PYNetworkDelegate new];
    self.delegate.network = self;
    return [NSURLSession sessionWithConfiguration:configuration delegate:self.delegate delegateQueue:[NSOperationQueue mainQueue]];
}
-(nullable NSURLSessionTask *) createSessionTask{
    NSURLRequest * request = nil;
    if([self.method isEqual:PYNET_HTTP_GET] || [self.method isEqual:PYNET_HTTP_DELETE]){
        NSString * url = nil;
        NSString * urlParams = [PYNetwork parseParamsToFrom:self.params keySorts:self.keySorts isAddPercentEncoding:YES];
        if(urlParams == nil || urlParams.length == 0){
            url = self.url;
        }else if([self.url containsString:@"?"]){
            url = kFORMAT(@"%@&%@",self.url, urlParams);
        }else{
            url = kFORMAT(@"%@?%@",self.url, urlParams);
        }
        request = [PYNetwork createRequestWithUrlString:url httpMethod:self.method heads:self.heads params:nil outTime:self.outTime];
        
    }else{
        NSData * pData = [PYNetwork parseParamsToHttpBody:self.params contentType:self.heads[@"Content-Type"] keySorts:self.keySorts];
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
        }
        [self cancel];
    }];
}
-(void) dealloc{
    [self interrupt];
    objc_setAssociatedObject([PYNetwork class], (__bridge const void * _Nonnull)(self), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/**
 创建网络请求
 @param urlString 请求地址
 @param httpMethod 请求类型
 @param heads 请求头信息
 @param outTime 超时时间
 */
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


@implementation PYNetwork(DataParse)
/**
 将键值对转换成对应的数据结构
 @param params 支持 NSString , NSDictionary, NSData
 @param contentType 支持
 application/x-www-form-urlencoded
 application/json
 application/xml
 @param keySorts 参数排序,仅当c参数类型是form表单时有用
 */
+(nonnull NSData *) parseParamsToHttpBody:(nullable id) params
                              contentType:(nullable NSString *) contentType
                                 keySorts:(nullable NSArray<NSString *> *) keySorts{
    if(keySorts && keySorts.count > 0 && [contentType isEqual:@"application/x-www-form-urlencoded;charset=UTF-8"]){
        return [self parseParamsToFormBody:params keySorts:keySorts];
    }else{
        return [self parseParamsToHttpBody:params contentType:contentType];
    }
}
/**
 将键值对转换成对应的数据结构
 @param params 支持 NSString , NSDictionary, NSData
 @param contentType 支持
 application/x-www-form-urlencoded
 application/json
 application/xml
 */
+(nonnull NSData *) parseParamsToHttpBody:(nullable id) params
                              contentType:(nullable NSString *) contentType{
    
    if(params == nil) return nil;
    
    if([params isKindOfClass:[NSData class]])
        return params;
    
    if(!contentType || ![contentType isKindOfClass:[NSString class]] || contentType.length == 0)
        contentType = @"application/x-www-form-urlencoded;charset=UTF-8";
    
    if([PYNetwork isContentTypeForWFormData:contentType]){
        if([params isKindOfClass:[NSDictionary class]])
            return [[self parseParamsToFrom:params keySorts:nil isAddPercentEncoding:YES] toData];
        else if([params isKindOfClass:[NSString class]])
            return [((NSString *) params) toData];
    }
    
    else if([PYNetwork isContentTypeForJson:contentType])
        return [self parseParamsToData:params];
    
    else if([PYNetwork isContentTypeForXml:contentType])
        return [self parseParamsToXml:params];
    
    else if([PYNetwork isContentTypeForMFormData:contentType])
        return [self parseParamsToMultipart:params contentType:contentType];
    
    else
        NSAssert(false, @"PYNetwork.parseParamsToHttpBody params can't parset to httpbody that dataType is [%@] and contentType is [%@]", NSStringFromClass([params class]), contentType);
    
    return nil;
}

/**
 将键值对转换成对应的数据结构
 @param params 参数
 @param keySorts 参数排序
 */
+(nonnull NSData *) parseParamsToFormBody:(nullable NSDictionary *) params
                                 keySorts:(nullable NSArray<NSString *> *) keySorts{
    return  [[self parseParamsToFrom:params keySorts:keySorts isAddPercentEncoding:YES] toData];
}

@end
