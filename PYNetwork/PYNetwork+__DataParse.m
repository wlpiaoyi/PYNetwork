//
//  PYNetwork+__DataParse.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/8/14.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import "PYNetwork+__DataParse.h"
#import "PYNetwork+__ContenType.h"

@implementation PYNetwork(__DataParse)

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
    
    if([params isKindOfClass:[NSArray class]] || [params isMemberOfClass:[NSArray class]]){
        return [((NSArray *) params) toData];
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
        [mString appendFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\nContent-Type:%@\r\n\r\n", params[@"fileName"], params[@"contentType"]];
        NSMutableData * mdata = [[mString toData] mutableCopy];
        [mdata appendData:params[uuid]];
//        [mdata appendData:[[NSString stringWithFormat:@"\r\n--%@",uuid] toData]];
        mString = [NSMutableString new];
        NSArray * allKeys = ((NSDictionary *)params).allKeys;
        for(NSString * key in allKeys){
            if([key isEqual:@"fileName"] || [key isEqual:@"contentType"] || [key isEqual:uuid]) continue;
            [mString appendFormat:@"\r\n--%@", uuid];
            [mString appendFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
            [mString appendFormat:@"%@", params[key]];
        }
        [mString appendFormat:@"\r\n--%@--\r\n", uuid];
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
            return [PYNetwork __PARAM_TO_BSTR:[params toString]];
        }
        return [params toString];
    }
    
    if([params isKindOfClass:[NSString class]] || [params isMemberOfClass:[NSString class]]){
        if(isAddPercentEncoding){
            return [PYNetwork __PARAM_TO_BSTR:params];
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
            value = [PYNetwork __FIELD_TO_BSTR:value];
            key = [PYNetwork __FIELD_TO_BSTR:key];
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
        [self parseForFormString:formString key:key value:[((NSDate*)value) dateFormateDate:PYNET_DATE_PATTERN] isAddPercentEncoding:isAddPercentEncoding];
    }else{
        [self parseForFormString:formString key:key value:[(NSDictionary *)[value objectToDictionary] toData] isAddPercentEncoding:isAddPercentEncoding];
    }
    
}

+(nonnull NSString *) __FIELD_TO_BSTR:(nonnull NSString*) str{
    NSString *bStr = (__bridge NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, PYNET_PERCENT_FIELD, kCFStringEncodingUTF8);
    return bStr;
}
+(nonnull NSString *) __PARAM_TO_BSTR:(nonnull NSString*) str{
    NSString *bStr = (__bridge NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, PYNET_PERCENT_PARAM, kCFStringEncodingUTF8);
    return bStr;
}
@end
