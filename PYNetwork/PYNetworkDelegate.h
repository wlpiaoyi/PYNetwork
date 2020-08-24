//
//  PYNetworkDelegate.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/12/23.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PYNetwork.h"

NS_ASSUME_NONNULL_BEGIN

@interface PYNetworkDelegate:NSObject<NSURLSessionDelegate>

kPNSNA PYNetwork * network;

@end
NS_ASSUME_NONNULL_END
