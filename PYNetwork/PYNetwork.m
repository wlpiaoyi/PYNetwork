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


static NSTimeInterval PYNetworkOutTime = 30;
static NSInteger PYNetworkActivityIndicatorIndex = 0;

NSString *  PYNetWorkDatePattern = @"yyyy-MM-dd HH:mm:ss";

//==>传输方法
NSString * _Nonnull PYNET_HTTP_GET = @"GET";
NSString * _Nonnull PYNET_HTTP_POST = @"POST";
NSString * _Nonnull PYNET_HTTP_PUT = @"PUT";
NSString * _Nonnull PYNET_HTTP_DELETE = @"DELETE";
///<==

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
        self.outTime = PYNetworkOutTime;
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
        if([self.url containsString:@"?"]){
            url = kFORMAT(@"%@&%@",self.url, urlParams);
        }else{
            url = kFORMAT(@"%@?%@",self.url, urlParams);
        }
        request = [PYNetwork createRequestWithUrlString:url httpMethod:self.method heads:self.heads params:nil outTime:self.outTime];
        
    }else{
        NSData * pData = [PYNetwork parseDictionaryToHttpBody:self.params contentType:self.heads[@"Content-Type"] keySorts:self.keySorts];
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

/**
 将键值对转换成对应的数据结构
 */
+(nonnull NSData *) parseDictionaryToHttpBody:(NSDictionary<NSString*, id> *) params contentType:(NSString *) contentType keySorts:(nullable NSArray<NSString *> *) keySorts{
    
    if(params == nil) return nil;
    
    if(!contentType || ![contentType isKindOfClass:[NSString class]] || contentType.length == 0) contentType = @"application/x-www-form-urlencoded";
    
    if([contentType containsString:@"application/json"]) return [self parseParamsToData:params];
    
    else if([contentType containsString:@"application/x-www-form-urlencoded"]) return [[self parseParamsToFrom:params keySorts:keySorts isAddPercentEncoding:NO] toData];
    
    else if([contentType containsString:@"application/xml"]) return [self parseParamsToXml:params];

    else if(contentType.length > 29 && [[contentType substringToIndex:29] isEqual:@"multipart/form-data;boundary="]) return [self parseParamsToMultipart:params contentType:contentType];
    
    return nil;
}

+(nullable NSData *) parseParamsToData:(nullable id) params{
    if(!params) return nil;
    
    if([params isKindOfClass:[NSData class]] || [params isMemberOfClass:[NSData class]]){
        return params;
    }
    
    if([params isKindOfClass:[NSString class]] || [params isMemberOfClass:[NSString class]]){
        return [((NSString *) params) toData];
    }
    
    if([params isKindOfClass:[NSDictionary class]] || [params isMemberOfClass:[NSDictionary class]]){
        return [((NSDictionary *) params) toData];
    }
    
    if([params isKindOfClass:[PYXmlElement class]] || [params isMemberOfClass:[PYXmlElement class]]){
        return [[((PYXmlElement *) params) stringValue] toData];
    }
    
    NSAssert(false, @"%@ %s param must be type for NSData, NSString, Dictionary or PYXmlElement", NSStringFromClass(self.class), sel_getName(_cmd));
    
    return nil;
}

/**
 将param转换成Multipart数据结构
 */
+(nullable NSData *) parseParamsToMultipart:(nullable id) params contentType:(NSString *) contentType{
    if(!params) return nil;
    
    if([params isKindOfClass:[NSData class]] || [params isMemberOfClass:[NSData class]]){
        return params;
    }
    
    if([params isKindOfClass:[NSDictionary class]] || [params isMemberOfClass:[NSDictionary class]]){
        NSMutableString * mString = [NSMutableString new];
        NSString * uuid = [contentType substringFromIndex:29];
        [mString appendFormat:@"--%@\r\n",uuid];
        [mString appendFormat:@"Content-Disposition:form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type:%@\r\n\r\n", params[@"fileName"], params[@"contentType"]];
        NSMutableData * mdata = [[mString toData] mutableCopy];
        [mdata appendData:params[uuid]];
        [mdata appendData:[[NSString stringWithFormat:@"\r\n--%@",uuid] toData]];
        mString = [NSMutableString new];
        for(NSString * key in ((NSDictionary *)params).allKeys){
            if([key isEqual:@"fileName"] || [key isEqual:@"contentType"] || [key isEqual:uuid]) continue;
            [mString appendFormat:@"\r\nContent-Disposition:form-data; name=\"%@\"\r\n\r\n", key];
            [mString appendFormat:@"%@\r\n--%@", params[key], uuid];
        }
        [mdata appendData:[mString toData]];
        return mdata;
    }
    
    NSAssert(false, @"%@ %s param must be type for NSData or Dictionary", NSStringFromClass(self.class), sel_getName(_cmd));
    
    return nil;
}



/**
 将param对转换成form表单
 #params 键值对
 #keySorts 排序
 */
+(nullable NSData *) parseParamsToXml:(nullable id) params{
    if(!params) return nil;
    
    if([params isKindOfClass:[NSData class]] || [params isMemberOfClass:[NSData class]]){
        return params;
    }
    
    if([params isKindOfClass:[NSString class]] || [params isMemberOfClass:[NSString class]]){
        return [params toData];
    }
    
    if([params isKindOfClass:[PYXmlElement class]] || [params isMemberOfClass:[PYXmlElement class]]){
        return [[((PYXmlElement *) params) stringValue] toData];
    }
    
    NSAssert(false, @"%@ %s param must be type for NSData, NSString or Dictionary", NSStringFromClass(self.class), sel_getName(_cmd));
    
    return nil;
}

/**
 将param对转换成form表单
 #params 键值对
 #keySorts 排序
 */
+(nullable NSString *) parseParamsToFrom:(nullable id) params keySorts:(nullable NSArray<NSString *> *) keySorts isAddPercentEncoding:(BOOL) isAddPercentEncoding{
    if(!params) return nil;
    
    if([params isKindOfClass:[NSData class]] || [params isMemberOfClass:[NSData class]]){
        if(isAddPercentEncoding){
            return [[params toString] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
        }
        return [params toString];
    }
    
    if([params isKindOfClass:[NSString class]] || [params isMemberOfClass:[NSString class]]){
        if(isAddPercentEncoding){
            return [params stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPasswordAllowedCharacterSet]];
        }
        return params;
    }
    
    if([params isKindOfClass:[NSDictionary class]] || [params isMemberOfClass:[NSDictionary class]]){
        NSAssert([params isKindOfClass:[NSDictionary class]], @"%@ parseDictinaryToFrom param type must be Dictionary type", NSStringFromClass(self));
        if(![params isKindOfClass:[NSDictionary class]]) return nil;
        NSMutableString * formString = [NSMutableString new];
        NSArray<NSString *> * allKeys = ((NSDictionary *)params).allKeys;
        if(keySorts && keySorts.count){
            NSMutableArray * temp = [allKeys mutableCopy];
            [temp removeObjectsInArray:keySorts];
            NSMutableArray * tak = [NSMutableArray arrayWithArray:keySorts];
            [tak addObjectsFromArray:temp];
            allKeys = tak;
        }
        for (NSString * key in allKeys) {
            [self parseForFormString:formString key:key value:params[key] isAddPercentEncoding:isAddPercentEncoding];
        }
        return formString.length > 1 ? [formString substringToIndex:formString.length - 1] : formString;
    }
    
    NSAssert(false, @"%@ %s param must be type for NSData, NSString or Dictionary", NSStringFromClass(self.class), sel_getName(_cmd));
    
    return nil;
}

//form表单传参全类型支持
+(void)parseForFormString:(NSMutableString *) formString key:(NSString *) key value:(id) value isAddPercentEncoding:(BOOL) isAddPercentEncoding{
    if(!value) return;
    
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
