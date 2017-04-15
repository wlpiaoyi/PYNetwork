//
//  PYNetUpload.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/14.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "PYNetwork.h"

@interface PYNetUpload : PYNetwork

-(BOOL) resumeWithData:(nonnull NSData *) data;
-(BOOL) resumeWithPath:(nonnull NSString *) path;


@end
