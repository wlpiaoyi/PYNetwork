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
    nw.heads = @{@"Content-Type":@"application/x-www-form-urlencoded;charset=UTF-8"};
//    nw.params = xml;
//    nw.params = @{@"name":@"223"};
    NSString * str = @"EZKL+982+8+1116/69/51 55:24:02";
//    NSString *bStr = (__bridge NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    nw.params = @{@"name":str};
//    nw.params = @{@"name":@"黄海平-13726867391"};
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
