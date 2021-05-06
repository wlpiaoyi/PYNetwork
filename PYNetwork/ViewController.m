//
//  ViewController.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "ViewController.h"
#import "PYNetwork.h"

@interface PYFormMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>

@end

@implementation PYFormMutableDictionary

@end


@interface ViewController ()
//@property (weak, nonatomic) IBOutlet PYAsyImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    PYXmlElement * xml = [[PYXmlElement alloc] init];
    xml.elementName = @"elementName";
    xml.attributes = @{@"attribute1":@"value"};
    xml.string = @"string value";
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"http://ugc.wxcitycq.com:8021/ugc_app/upload/savevideo";
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSLog(@"===================================================================");
    }];
    [nw resume];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
