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
//    PYXmlElement * xml = [[PYXmlElement alloc] init];
//    xml.elementName = @"elementName";
//    xml.attributes = @{@"attribute1":@"value"};
//    xml.string = @"string value";
    static PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;
    nw.url = @"http://www.baidu.com";
//    nw.heads = @{@"Content-type": @"application/xml"};
//    nw.params = xml;
    nw.params = @{@"v1":@"我的百分号[%]",@"v2":@(22),@"v3":@[@"vt1",[NSDate date], @{@"a":@"b"}]};
    nw.keySorts = @[@"v3",@"v2"];
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
    }];
    [nw resume];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        while(true){
//            dispatch_async(dispatch_get_main_queue(), ^{
//                PYNetwork * nw = [PYNetwork new];
//                nw.method = PYNET_HTTP_GET;
//                nw.url = @"http://www.51voa.com";
//                nw.params = @{@"v1":@"a",@"v2":@(22)};
//                [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
//                    NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
//                }];
//                [nw resume];
//                if(random() % 3){
//                    [nw cancel];
//                }
//            });
//            [NSThread sleepForTimeInterval:0.5];
//        }
//    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
