//
//  ViewController.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "ViewController.h"
#import "PYNetwork.h"

@interface ViewController ()
//@property (weak, nonatomic) IBOutlet PYAsyImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(true){
            dispatch_async(dispatch_get_main_queue(), ^{
                PYNetwork * nw = [PYNetwork new];
                nw.url = @"https://www.baidu.com";
                [nw setBlockComplete:^(id  _Nullable data, PYNetwork * _Nonnull target) {
                    NSLog(@"%@",[data description]);
                }];
                [nw resume];

            });
            [NSThread sleepForTimeInterval:0.5];
        }
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
