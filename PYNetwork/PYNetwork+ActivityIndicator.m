//
//  PYNetwork+ActivityIndicator.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/12/23.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import "PYNetwork+ActivityIndicator.h"

@interface PYNetwork()
+(id) __GET__PYNETWORK_SYN;
@end

static NSInteger PYNetworkActivityIndicatorIndex = 0;

@implementation PYNetwork(ActivityIndicator)

+(void) addNetworkActivityIndicatorVisibel{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized([self __GET__PYNETWORK_SYN]){
            PYNetworkActivityIndicatorIndex++;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
            });
        }
    });
}

+(void) removeNetworkActivityIndicatorVisibel{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized([self __GET__PYNETWORK_SYN]){
            PYNetworkActivityIndicatorIndex--;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:PYNetworkActivityIndicatorIndex > 0];
            });
        }
    });
}
@end
