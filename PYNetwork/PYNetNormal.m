//
//  PYNetNormal.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "PYNetNormal.h"
#import "pyutilea.h"

@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
@implementation NSURLRequest (NSURLRequestSSLY)
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host{
    return YES;
}
@end

const NSString * HTTP_HEAD_KEY_ContentType = @"Content-Type";
const NSString * HTTP_HEAD_VALUE_ContentType_JSON = @"application/json";
const NSString * HTTP_HEAD_VALUE_ContentType_Normal = @"application/x-www-form-urlencoded";
const NSString * HTTP_HEAD_VALUE_ContentType_Encode = @"charset=";


//==>传输方法
const NSString * HTTP_GET = @"GET";
const NSString * HTTP_POST = @"POST";
const NSString * HTTP_PUT = @"PUT";
const NSString * HTTP_DELETE = @"DELETE";
///<==
CGFloat PYNetNormalOutTime = 30.0;
@interface PYNetNormal()<NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSDictionary <NSString * , NSString * > * _Nullable _headRequest_;
@property (nonatomic,strong) NSURLConnection	*connection;
@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic) NSInteger statusCode;

@end
@implementation PYNetNormal
-(instancetype) init{
    if (self = [super init]) {
        self.outTime = PYNetNormalOutTime;
        self.encoding = NSUTF8StringEncoding;
        self._headRequest_ = @{HTTP_HEAD_KEY_ContentType:[NSString stringWithFormat:@"%@;%@UTF-8",HTTP_HEAD_VALUE_ContentType_Normal,HTTP_HEAD_VALUE_ContentType_Encode]};
    }
    return self;
}
/**
 添加头信息
 */
-(void) setHeadRequest:(NSDictionary<NSString * , NSString * > * _Nonnull) headRequest{
    self._headRequest_ = headRequest;
}

/**
 开始请求数据
 */
-(nullable NSURLConnection *) requestWithType:(PYRequestType) type params:(nullable NSDictionary<NSString *, NSObject *> *) params blockComplete:(nullable void (^)(NSInteger status, id _Nullable data, PYNetNormal * _Nonnull target)) blockComplete{
    
    self.blockComplete = blockComplete;
    
    NSURLConnection * connection = nil;
    
    switch (type) {
        case PYRequestGet:{
            connection = [self requestGetWithParams:params];
        }
            break;
        case PYRequestPost:{
            connection = [self requestPostWithParams:params];
        }
            break;
        case PYRequestPut:{
            connection = [self requestPutWithParams:params];
        }
            break;
        case PYRequestDelete:{
            connection = [self requestDeleteWithParams:params];
        }
            break;
        default:
            break;
    }
    
    return connection;
}

/**
 开始请求数据
 */
//==>
-(NSURLConnection * _Nullable) requestGetWithParams:(NSDictionary<NSString *, NSObject *> * _Nullable) params{
    if (self.url == nil) {
        return nil;
    }
    
    [self cancel];
    
    NSMutableURLRequest *request = [self createUrlRequest:params outTime:self.outTime urlString:self.url];
    [request setHTTPMethod:(NSString*)HTTP_GET];
    self.connection = [self startAsynRequest:request];
    
    return self.connection;
}
-(NSURLConnection * _Nullable) requestPostWithParams:(NSDictionary<NSString *, NSObject *> * _Nullable) params{
    
    if (self.url == nil) {
        return nil;
    }
    
    [self cancel];
    
    NSMutableURLRequest *request = [self createDataRequest:params outTime:self.outTime urlString:self.url];
    [request setHTTPMethod:(NSString*)HTTP_POST];
    self.connection = [self startAsynRequest:request];
    
    return self.connection;
}
-(NSURLConnection * _Nullable) requestPutWithParams:(NSDictionary<NSString *, NSObject *> * _Nullable) params{
    
    if (self.url == nil) {
        return nil;
    }
    
    [self cancel];
    
    NSMutableURLRequest *request = [self createDataRequest:params outTime:self.outTime urlString:self.url];
    [request setHTTPMethod:(NSString*)HTTP_PUT];
    self.connection = [self startAsynRequest:request];
    
    return self.connection;
}
-(NSURLConnection * _Nullable) requestDeleteWithParams:(NSDictionary<NSString *, NSObject *> * _Nullable) params{
    
    if (self.url == nil) {
        return nil;
    }
    
    [self cancel];
    
    NSMutableURLRequest *request = [self createUrlRequest:params outTime:self.outTime urlString:self.url];
    [request setHTTPMethod:(NSString*)HTTP_DELETE];
    self.connection = [self startAsynRequest:request];
    
    return self.connection;
}
///<==

/**
 取消请求
 */
-(BOOL) cancel{
    if (!self.connection) {
        return false;
    }
    [self.connection cancel];
    self.connection = nil;
    self.blockComplete = nil;
    self.userInfo = nil;
    self.data = nil;
    return true;
}


-(NSURLConnection*) startAsynRequest:(NSURLRequest*) request{
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.data = [NSMutableData new];
    [connection start];
#ifdef DEBUG
    printf("Http:%s\n",[[[request URL] absoluteString] UTF8String]);
#endif
    return connection;
}

-(NSMutableURLRequest*) createUrlRequest:(NSDictionary<NSString *, NSObject *> *) params outTime:(NSTimeInterval) outTime urlString:(NSString*) urlString{
    NSMutableString *finallyUrlStr = [[NSMutableString alloc] initWithString:urlString];
    if (params && params.allKeys.count) {
        [finallyUrlStr appendString:[urlString rangeOfString:@"?"].length == 1 ? @"&" : @"?"];
        [finallyUrlStr appendString:[PYNetNormal checkParamsConstructionToNormarl:params encoding:self.encoding]];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: finallyUrlStr] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:outTime];
    
    if (self._headRequest_) {
        [PYNetNormal addAllHttpHeaderFields:self._headRequest_ request:request];
    }
    return request;
}

-(NSMutableURLRequest*) createDataRequest:(NSDictionary<NSString *, NSObject *> *) params outTime:(NSTimeInterval) outTime urlString:(NSString*) urlString{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]  cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:outTime];
    if (self._headRequest_) {
        [PYNetNormal addAllHttpHeaderFields:self._headRequest_ request:request];
    }
    if (params) {
        NSData *postData = [self checkParamsConstruction:params];
        [request setHTTPBody:postData];
        NSString *postLength = [NSString stringWithFormat:@"%li", (unsigned long)[postData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    }
    return request;
}

-(NSData*) checkParamsConstruction:(NSDictionary*) dicParam{
    if (!dicParam) {
        return nil;
    }
    NSString *contentType = [self._headRequest_ objectForKey:(NSString*)HTTP_HEAD_KEY_ContentType];
    if ([contentType rangeOfString:((NSString*)HTTP_HEAD_VALUE_ContentType_JSON)].length) {
        return [dicParam toData];
    }else{
        return [[PYNetNormal checkParamsConstructionToNormarl:dicParam encoding:self.encoding] dataUsingEncoding:self.encoding];
    }
}


+(NSString*) checkParamsConstructionToNormarl:(NSDictionary*) dicParam encoding:(NSStringEncoding) encoding{
    NSMutableString *stringParams = [NSMutableString new];
    
    for (NSString *key in [dicParam allKeys]) {
        id value = [dicParam objectForKey:key];
        if (value) {
            if ([value isKindOfClass:[NSString class]]) {
                [stringParams appendFormat:@"&%@=%@",key,value];
            }else if([value isKindOfClass:[NSNumber class]]){
                [stringParams appendFormat:@"&%@=%@",key,[((NSNumber*)value) stringValueWithPrecision:8]];
            }else if([value isKindOfClass:[NSData class]]){
                [stringParams appendFormat:@"&%@=%@",key,[[NSString alloc] initWithData:value encoding:encoding]];
            }else if([value isKindOfClass:[NSArray class]]||[value isKindOfClass:[NSDictionary class]]){
                [stringParams appendFormat:@"&%@=%@",key,[[NSString alloc] initWithData:[value toData] encoding:NSUTF8StringEncoding]];
            }
        }
    }
    if (stringParams.length > 1) {
        return [stringParams substringFromIndex:1];
    }
    return stringParams;
}

+(void) addAllHttpHeaderFields:(NSDictionary<NSString *, NSString *>*) headerFilelds request:(NSMutableURLRequest*) request{
    for (NSString *key in [headerFilelds allKeys]) {
        [request setValue:[headerFilelds objectForKey:key] forHTTPHeaderField:key];
    }
}

#pragma NSURLConnectionDelegate ==>
-(void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error {
    
    if (self.blockComplete) {
        _blockComplete(self.statusCode, error, self);
    }
    [self cancel];
}
#pragma NSURLConnectionDelegate<==

#pragma NSURLConnectionDataDelegate ==>

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
    if(self.blockAuthenticationChallenge != nil && self.blockAuthenticationChallenge(challenge, self)){
        NSURLCredential *   credential;
        
        NSURLProtectionSpace *  protectionSpace;
        
        SecTrustRef            trust;
        
        NSString *              host;
        
        SecCertificateRef      serverCert;
        
        assert(challenge !=nil);
        
        protectionSpace = [challenge protectionSpace];
        assert(protectionSpace != nil);
        
        
        trust = [protectionSpace serverTrust];
        assert(trust != NULL);
        
        
        
        credential = [NSURLCredential credentialForTrust:trust];
        
        assert(credential != nil);
        
        host = [[challenge protectionSpace] host];
        
        if (SecTrustGetCertificateCount(trust) > 0) {
            
            serverCert = SecTrustGetCertificateAtIndex(trust, 0);
            
        } else {
            
            serverCert = NULL;
            
        }
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
}
- (nullable NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(nullable NSURLResponse *)response{
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.statusCode = ((NSHTTPURLResponse*)response).statusCode;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    @synchronized(self.data) {
        [self.data appendData:data];
    }
}

- (nullable NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    if (self.blockComplete) {
        self.blockComplete(self.statusCode,self.data,self);
    }
    [self cancel];
}
#pragma NSURLConnectionDataDelegate <==

+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(nonnull NSString *)inHost{
    [NSURLRequest setAllowsAnyHTTPSCertificate:inAllow forHost:inHost];
}
@end
