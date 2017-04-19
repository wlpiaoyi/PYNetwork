//
//  ViewController.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "ViewController.h"
#import "PYAsyImageView.h"
#import "PYDisplayImageView.h"

@interface ViewController ()
//@property (weak, nonatomic) IBOutlet PYAsyImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ((PYDisplayImageView *)self.view).imgUrl = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1491889609544&di=2840c4d8f30c421cc0569246a3625b60&imgtype=0&src=http%3A%2F%2Fwww.pp3.cn%2Fuploads%2F20120322BZ%2F23.jpg";
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
