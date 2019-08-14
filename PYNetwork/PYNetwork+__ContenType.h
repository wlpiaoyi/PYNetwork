//
//  PYNetwork+__ContenType.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/8/14.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import "PYNetwork.h"


@interface PYNetwork(__ContenType)

+(BOOL) isContentTypeForWFormData:(nonnull NSString *) contentType;

+(BOOL) isContentTypeForJson:(nonnull NSString *) contentType;

+(BOOL) isContentTypeForXml:(nonnull NSString *) contentType;

+(BOOL) isContentTypeForMFormData:(nonnull NSString *) contentType;
@end

