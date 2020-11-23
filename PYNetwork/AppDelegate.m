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

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//    [[PYNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(PYNetworkReachabilityStatus status) {
//        NSLog(@"%ld", status);
//    }];
//    [[PYNetworkReachabilityManager sharedManager] startMonitoring];
//    
//    static PYNetDownload * download;
//    download = [PYNetDownload new];
//    download.url = @"http://185.38.13.130//mp43/354441.mp4?st=4TAONEpXMkpDTUf3wnU8KQ&e=1580878232";
//    [download setBlockDownloadProgress:^(PYNetDownload * _Nonnull target, int64_t currentBytes, int64_t totalBytes) {
//        NSLog(@"%.2f%%", (double)currentBytes/(double)totalBytes * 100.);
//    }];
//    download.blockComplete = ^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
//        NSLog(@"");
//        
//    };
//    [download setBlockCancel:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetDownload * _Nonnull target) {
//        NSLog(@"");
//    }];
//    [download resume];
    
    PYNetwork * network = [PYNetwork new];
    network.method = PYNET_HTTP_POST;
    network.url = @"https://www.google.com";
    [network setBlockComplete:^(id _Nullable data,NSURLResponse * _Nullable response, PYNetwork * _Nonnull target){
        NSLog(@"%@", [((NSData *)data) toString]);
    }];
    [network resume];
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
