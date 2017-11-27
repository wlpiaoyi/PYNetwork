//
//  PYNetwork.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//


#import "PYNetwork.h"

static NSString *  PYNetworkCache  = @"org.personal.wlpiaoyi.network";
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
        _isNetworkActivityIndicatorVisible = true;
        self.outTime = PYNetworkOutTime;
        self.method = (NSString *)PYNET_HTTP_GET;
    }
    return self;
}
-(BOOL) resume{
    @synchronized (self) {
        if(self.url == nil) return false;
        self.session = [self createSession];
        NSData * pData = [PYNetwork parseDictionaryToHttpBody:self.params contentType:self.heads[@"Content-Type"]];
        NSURLRequest * request = [PYNetwork createRequestWithUrlString:self.url httpMethod:self.method heads:self.heads params:pData];
        __unsafe_unretained typeof(self) uself = self;
        self.sessionTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (uself.blockComplete) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        uself.blockComplete(error ? error : data,uself);
                        [uself cancel];
                    });
                });
            }else{
                [uself cancel];
            }
        }];
        if(uself.sessionTask == nil) return false;
        [uself.sessionTask resume];
        
        if(_isNetworkActivityIndicatorVisible){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @synchronized([PYNetwork class]){
                    PYNetworkActivityIndicatorIndex++;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
                    });
                }
            });
            
        }
        
    }
    return true;
}
-(BOOL) suspend{
    @synchronized(self) {
        if (!self.sessionTask) {
            return false;
        }
        [self.sessionTask suspend];
    }
    return true;
}
-(BOOL) cancel{
    @synchronized(self) {
        [self setSession:nil];
        if (!self.sessionTask) {
            return false;
        }
        [self.sessionTask cancel];
        self.sessionTask = nil;
    }
    if(_isNetworkActivityIndicatorVisible){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized([PYNetwork class]){
                PYNetworkActivityIndicatorIndex--;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
                });
            }
        });
    }
    return true;
}



-(nonnull NSURLSession*) createSession{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache =   nil;//[[NSURLCache alloc] initWithMemoryCapacity:20 * 1024*1024 diskCapacity:100 * 1024*1024 diskPath:PYNetworkCache];
    configuration.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    self.delegate = [PYNetworkDelegate new];
    self.delegate.network = self;
    return [NSURLSession sessionWithConfiguration:configuration delegate:self.delegate delegateQueue:[NSOperationQueue mainQueue]];
}

+(nonnull NSURLRequest *) createRequestWithUrlString:(nonnull NSString*) urlString
                                          httpMethod:(nullable NSString*) httpMethod
                                               heads:(nullable NSDictionary<NSString *, NSString *> *) heads
                                              params:(nullable NSData *) params{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = httpMethod;
    if(heads != nil){
        for (NSString * key in heads.allKeys) {
            [request setValue:heads[key] forHTTPHeaderField:key];
        }
    }
    request.HTTPBody = params;
    return  request;
}
+(nonnull NSData *) parseDictionaryToHttpBody:(NSDictionary<NSString*, id> *) params contentType:(NSString *) contentType{
    
    if(params == nil) return nil;
    
    if(!contentType || ![contentType isKindOfClass:[NSString class]] || contentType.length == 0){
        contentType = @"application/x-www-form-urlencoded";
    }
    
    if([@"application/json" isEqual:contentType]){
        return [params toData];
    }else if([@"application/x-www-form-urlencoded" isEqual:contentType]){
        NSMutableString * pString = [NSMutableString new];
        NSUInteger count = params.allKeys.count;
        for (NSString * key in params.allKeys) {
            count--;
            [pString appendString:key];
            [pString appendString:@"="];
            [pString appendString:params[key]];
            if(count > 0){
                [pString appendString:@"&"];
            }
        }
        return [pString toData];
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
