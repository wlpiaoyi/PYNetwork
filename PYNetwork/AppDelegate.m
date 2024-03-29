//
//  AppDelegate.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "AppDelegate.h"
#import "PYNetUpload.h"
#import "PYNetDownload.h"
#import "NSData+PYExpand.h"
#import "PYNetworkReachabilityManager.h"

//2021-08-04 12:58:07.366835+0800 PYNetwork[31285:7400480] i
//2021-08-04 12:58:07.367032+0800 PYNetwork[31285:7400480] I
//2021-08-04 12:58:07.367132+0800 PYNetwork[31285:7400480] q
//2021-08-04 12:58:07.367227+0800 PYNetwork[31285:7400480] Q
//2021-08-04 12:58:07.367320+0800 PYNetwork[31285:7400480] f
//2021-08-04 12:58:07.367409+0800 PYNetwork[31285:7400480] d
//2021-08-04 12:58:07.367496+0800 PYNetwork[31285:7400480] B
//2021-08-04 12:58:07.367615+0800 PYNetwork[31285:7400480] @"NSDate"
//2021-08-04 12:58:07.367771+0800 PYNetwork[31285:7400480] @"NSString"
@interface TestModle:NSObject<PYObjectParseProtocol>{
//    int vint;
//    unsigned int vuint;
//    long vlong;
//    unsigned long vulong;
//    float vfloat;
//    double vdoubel;
//    bool vbool;
    @public NSDate * vdate;
//    NSString * vstring;
}

@end

@implementation TestModle

+(nullable NSDictionary *) pyObjectGetKeysType{
    return @{
        @"vint":[NSString stringWithFormat:@"%s", @encode(int)],
        @"vuint":[NSString stringWithFormat:@"%s", @encode(unsigned int)],
        @"vlong":[NSString stringWithFormat:@"%s", @encode(long)],
        @"vulong":[NSString stringWithFormat:@"%s", @encode(unsigned long)],
        @"vfloat":[NSString stringWithFormat:@"%s", @encode(float)],
        @"vdoubel":[NSString stringWithFormat:@"%s", @encode(double)],
    };
}

-(nullable id) pyObjectArchiveWithValue:(nonnull NSObject *) value clazz:(nullable Class) clazz returnValue:(nullable id) returnValue{
    if(clazz == [NSDate class]){
        NSDate * d = value;
        return @([d timeIntervalSince1970] * 1000);
    }
    return returnValue;
}
@end

@interface AppDelegate ()
kPNSNA PYNetworkReachabilityManager * nrm;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    TestModle * tm = [TestModle new];
    tm->vdate = [NSDate date];
    id obj = [tm objectToDictionary];
    NSLog(@"");
    self.nrm = [PYNetworkReachabilityManager sharedManager];
    [self.nrm setReachabilityStatusChangeBlock:^(PYNetworkReachabilityStatus status) {
        switch(status) {

        case PYNetworkReachabilityStatusNotReachable:{

        NSLog(@"无网络");

        break;

        }

        case PYNetworkReachabilityStatusReachableViaWiFi:{

        NSLog(@"WiFi网络");

        break;

        }

        case PYNetworkReachabilityStatusReachableViaWWAN:{

        NSLog(@"无线网络");

        break;

        }

        default:

        break;

        }
    }];
    [self.nrm startMonitoring];
    return YES;
}

+(NSString *) randomName:(int) length{
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString * names = [NSMutableString new];
    for (int i = 0; i< length; i++) {
         int i = arc4random() % (62);
        [names appendFormat:@"%c", table[i]];
    }
    return names;
}

+(NSString *) randomUpchars:(int) length{
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString * names = [NSMutableString new];
    for (int i = 0; i< length; i++) {
        int i = arc4random() % (26);
        [names appendFormat:@"%c", table[i]];
    }
    return names;
}

+(NSString *) randomLowerchars:(int) length{
    static char table[] = "abcdefghijklmnopqrstuvwxyz";
    NSMutableString * names = [NSMutableString new];
    for (int i = 0; i< length; i++) {
        int i = arc4random() % (26);
        [names appendFormat:@"%c", table[i]];
    }
    return names;
}

+(NSString *) randomIntchars:(int) length{
    static char table[] = "0123456789";
    NSMutableString * names = [NSMutableString new];
    for (int i = 0; i< length; i++) {
        int i = arc4random() % (10);
        [names appendFormat:@"%c", table[i]];
    }
    return names;
}


+(NSString *) randomDateStr{
    int i = random() % (365 * 14);
    NSDate * date = [@"1980-01-01" dateFormateString:nil];
    date = [date offsetDay:i];
    return [date dateFormateDate:@"yyyy-MM-dd"];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
