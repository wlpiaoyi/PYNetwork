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
    PYNetwork * nw = [PYNetwork new];
    [nw setUrl:@"https://www.baidu.com"];
    [nw setBlockComplete:^(id  _Nullable data, PYNetwork * _Nonnull target) {
        
    }];
    [nw resume];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
