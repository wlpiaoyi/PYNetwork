//
//  PYNetwork+__DataParse.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/8/14.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import "PYNetwork.h"

@interface PYNetwork(__DataParse)

+(nullable NSData *) parseParamsToData:(nullable id) params;

/**
 将param转换成Multipart数据结构
 */
+(nullable NSData *) parseParamsToMultipart:(nullable id) params contentType:(nullable NSString *) contentType;


/**
 将param对转换成form表单
 #params 键值对
 #keySorts 排序
 */
+(nullable NSData *) parseParamsToXml:(nullable id) params;

/**
 将param对转换成form表单
 #params 键值对
 #keySorts 排序
 */
+(nullable NSString *) parseParamsToFrom:(nullable id) params keySorts:(nullable NSArray<NSString *> *) keySorts isAddPercentEncoding:(BOOL) isAddPercentEncoding;

//form表单传参全类型支持
+(void)parseForFormString:(nonnull NSMutableString *) formString key:(nonnull NSString *) key value:(nonnull id) value isAddPercentEncoding:(BOOL) isAddPercentEncoding;

+(nonnull NSString *) __FIELD_TO_BSTR:(nonnull NSString*) str;

+(nonnull NSString *) __PARAM_TO_BSTR:(nonnull NSString*) str;
@end

