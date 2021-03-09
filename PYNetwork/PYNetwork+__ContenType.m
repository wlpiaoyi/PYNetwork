//
//  PYNetwork+__ContenType.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/8/14.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import "PYNetwork+__ContenType.h"

NSString * PYNetworkDefaultCharset = @"UTF-8";
NSString * PYNetworkXWWWFormContentType = @"application/x-www-form-urlencoded";
NSString * PYNetworkJsonContentType = @"application/json";
NSString * PYNetworkXmlContentType = @"text/xml";
NSString * PYNetworkMutipartFormContentType = @"multipart/form-data";

@implementation PYNetwork(__ContenType)

+(BOOL) isContentTypeForWFormData:(nonnull NSString *) contentType{
    NSRange range = [contentType rangeOfString:PYNetworkXWWWFormContentType];
    return range.location == 0 & range.length == PYNetworkXWWWFormContentType.length;
}

+(BOOL) isContentTypeForJson:(nonnull NSString *) contentType{
    NSRange range = [contentType rangeOfString:PYNetworkJsonContentType];
    return range.location == 0 & range.length == PYNetworkJsonContentType.length;
}

+(BOOL) isContentTypeForXml:(nonnull NSString *) contentType{
    NSRange range = [contentType rangeOfString:PYNetworkXmlContentType];
    return range.location == 0 & range.length == PYNetworkXmlContentType.length;
}

+(BOOL) isContentTypeForMFormData:(nonnull NSString *) contentType{
    NSRange range = [contentType rangeOfString:PYNetworkMutipartFormContentType];
    return range.location == 0 & range.length == PYNetworkMutipartFormContentType.length;
}

@end
