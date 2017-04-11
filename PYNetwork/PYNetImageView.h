//
//  PYNetImageView.h
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PYUtile.h"
@interface PYNetImageView : UIImageView
PYPNSNN NSString * imgUrl;
@property (nonatomic, copy, nullable) void (^blockDisplay)(bool isSuccess, bool isCahes, PYNetImageView * _Nonnull imageView);
@property (nonatomic, copy, nullable) void (^blockProgress)(double progress, PYNetImageView * _Nonnull imageView);
+(bool) clearCache:(nonnull NSString *) imgUrl;
+(bool) clearCaches;
@end
