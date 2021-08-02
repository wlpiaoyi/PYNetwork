//
//  ViewController.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "ViewController.h"
#import "PYNetwork.h"

NSString * qkd_uuid = @"1B00A734-A204-4F5F-A776-22687FC92801";
NSString * qkd_client_id = @"c0a8005808ff0012d3d8";
NSString * qkd_token = @"lDZq1/4ge6cx7pPLXUNBWyMUISwHSb1Xt0MiunttKaAwnx08mK+i4COeB9TTfz42tDY79/VpIqAQOylImOUKjdWK/ElEpM+2ZhYrzvEFkBhOt4C8wPzJbd1VKKDN639MVcL0fQ0sE6GaMqpdOaxV5OmrimhW7Qc4au+2W5WPxSe0CHc6rl4eo/DjfpI3g3m2";
NSString * qkd_cookie = @"think_language=zh-cn; PHPSESSID=ujis7aujm3c107tbcphjhrs8ef";

@interface PYFormMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>

@end



@interface ViewController ()
- (IBAction)oInit:(id)sender;
- (IBAction)o1:(id)sender;
- (IBAction)o2:(id)sender;
- (IBAction)o3:(id)sender;
- (IBAction)o4:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *bInit;
@property (weak, nonatomic) IBOutlet UIButton *b20;
@property (weak, nonatomic) IBOutlet UIButton *b100;
@property (weak, nonatomic) IBOutlet UIButton *b50;
- (IBAction)o5:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *b300;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;
kPNSNA NSMutableArray<NSDictionary *> * result;
kPNSNA NSString * classId;
kPNSNA NSDictionary * headers;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.classId = @"307";
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    NSString * token = [ud valueForKeyPath:@"token"];
    if(token) qkd_token = token;
    self.headers = @{
        @"cookie": qkd_cookie,
        @"Content-Type":@"application/json",
        @"accept":@"*/*",
        @"accept-encoding":@"gzip, deflate, br",
        @"x-version-release":@"1.5.1",
        @"user-agent":@"1.5.1 rv:51 (iPhone; iOS 13.7; zh_CN)",
        @"accept-language":@"zh-cn",
        @"x-version-build":@"0",
    };
}

-(void) getTocken{
    
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://appapi.qukoudai.cn/index.php?mo=V2&a=getToken";
    nw.heads = self.headers;
    nw.params = @{
        @"token":qkd_token,
        @"uuid":qkd_uuid,
    };
    
    self.view.alpha = 0.1;
    self.view.userInteractionEnabled = NO;
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        
        self.view.alpha = 1;
        self.view.userInteractionEnabled = YES;
        self.label1.text = kFORMAT(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
        NSString * token = result[@"result"][@"token"];
        qkd_token = token;
        threadJoinGlobal(^{
            sleep(1);
            threadJoinMain(^{
                self.label1.text = result[@"msg"];
                [self initTocken];
            });
        });
    }];
    [nw resume];
}

-(void) initTocken{
    
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://appapi.qukoudai.cn/index.php?mo=V2&a=getInitData";
    nw.params = @{
        @"token":qkd_token,
        @"uuid":qkd_uuid,
    };
    nw.heads = self.headers;
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        self.label1.text = kFORMAT(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
//        NSString * token = result[@"result"][@"token"];
//        qkd_token = token;
        threadJoinGlobal(^{
            sleep(1);
            threadJoinMain(^{
                self.label1.text = result[@"msg"];
                if(result.count > 1) [self putBind];
            });
        });
    }];
    [nw resume];
}


-(void) putBind{
    
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://appapi.qukoudai.cn/index.php?mo=V2&a=putBind";
    nw.params = @{
        @"token":qkd_token,
        @"uuid":qkd_uuid,
        @"client_id":qkd_client_id,
    };
    nw.heads = self.headers;
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        self.label1.text = kFORMAT(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
//        NSString * token = result[@"result"][@"token"];
//        qkd_token = token;
        threadJoinGlobal(^{
            sleep(1);
            threadJoinMain(^{
                self.label1.text = result[@"msg"];
                if(result.count > 1) [self queryList];
            });
            
        });
    }];
    [nw resume];
}

-(void) queryList{
    sleep(1);
    self.view.alpha = 0.1;
    self.view.userInteractionEnabled = NO;
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:qkd_token forKeyPath:@"token"];
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_GET;//67765498860
    nw.url = kFORMAT(@"https://appapi.qukoudai.cn/index.php?mo=V2&a=getPurchaseList&uuid=%@&class_id=%@&token=%@&pagesize=20&page=1",
                     qkd_uuid, self.classId, [qkd_token pyEncodeToPercentEscapeString:nil]);
    nw.heads = self.headers;

    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        self.view.alpha = 1;
        self.view.userInteractionEnabled = YES;
        NSLog(@"===================================================================");
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
        NSLog(@"===================================================================");
        self.result = [NSMutableArray new];
        for (NSDictionary * dict in result[@"result"][@"list"]) {
            NSNumber * is_join_m = dict[@"is_join_m"];
            NSNumber * is_join = dict[@"is_join"];
            if(![is_join_m isEqual:@0]) continue;
            if(![is_join isEqual:@1]) continue;
            [self.result addObject:dict];
        }
        self.label1.text = kFORMAT(@"classId(%@):%ld/%ld",self.classId, [self.result count], ((NSArray *)result[@"result"][@"list"]).count);
        if(self.result.count){
            [self putPurchaseAddCart:self.result.firstObject];
            [self.result removeObject:self.result.firstObject];
        }
    }];
    [nw resume];
    
}

-(void) putPurchaseAddCart:(NSDictionary *) goods{
    sleep(1);
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://appapi.qukoudai.cn/index.php?mo=V2&a=putPurchaseAddCart";
    nw.heads = self.headers;
    nw.params = @{
        @"goods_id": goods[@"goods_id"],
        @"purchase_id": goods[@"purchase_id"],
        @"token":qkd_token,
        @"uuid":qkd_uuid,
    };
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
        NSLog(@"===================================================================");
        self.label1.text = result[@"msg"];
        [self getOrderConfirmPage:result[@"result"][@"cart_id"]];
    }];
    [nw resume];
    
}


-(void) getOrderConfirmPage:(NSString *) cart_ids{
    sleep(1);
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://appapi.qukoudai.cn/index.php?mo=V2&a=getOrderConfirmPage";
    nw.heads = self.headers;
    nw.params = @{
        @"cart_ids": cart_ids,
        @"is_user_amount": @1,
        @"address_id": @0,
        @"token":qkd_token,
        @"uuid":qkd_uuid,
    };
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
        NSLog(@"===================================================================");
        self.label1.text = result[@"msg"];
        [self putOrder:result[@"result"]];
    }];
    [nw resume];
    
}



-(void) putOrder:(NSDictionary *) cparmas{
    sleep(1);
    PYNetwork * nw;
    nw = [PYNetwork new];
    nw.method = PYNET_HTTP_POST;//67765498860
    nw.url = @"https://appapi.qukoudai.cn/index.php?mo=V2&a=putOrder";
    nw.heads = self.headers;
    NSMutableDictionary * params = [cparmas mutableCopy];
    [params setObject:qkd_token forKey:@"token"];
    [params setObject:qkd_uuid forKey:@"uuid"];
    nw.params = params;
    [nw setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"===================================================================");
        NSLog(@"%@",[data isKindOfClass:[NSData class]] ? [data toString] : [data description]);
        NSDictionary * result = [data toDictionary];
        NSLog(@"===================================================================");
        self.label1.text = result[@"msg"];
        threadJoinGlobal(^{
//            sleep(1);
//            if(self.result.count){
//                [self putPurchaseAddCart:self.result.firstObject];
//                [self.result removeObject:self.result.firstObject];
//            }
        });
    }];
    [nw resume];
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)o4:(id)sender {
    self.classId = @"322";
    [self queryList];
    
}

- (IBAction)o3:(id)sender {
    self.classId = @"321";
    [self queryList];
}

- (IBAction)o2:(id)sender {
    self.classId = @"320";
    [self queryList];
}

- (IBAction)o1:(id)sender {
    self.classId = @"307";
    [self queryList];
}

- (IBAction)oInit:(id)sender {
    
//    self.classId = @"323";
//    self.classId = @"322";
//    self.classId = @"321";
//    self.classId = @"320";
    [self getTocken];
}
- (IBAction)o5:(id)sender {
    self.classId = @"323";
    [self queryList];
}
@end
