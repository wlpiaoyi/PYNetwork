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
#import "NSData+Expand.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    PYNetDownload * netd = [PYNetDownload new];
    netd.url = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1511767451861&di=d4fb1a8ba225446d1a23d36a0e154bdb&imgtype=0&src=http%3A%2F%2Fimg2.niutuku.com%2Fdesk%2F1208%2F1542%2Fntk-1542-29992.jpg";
    [netd setBlockReceiveChallenge:^BOOL(id  _Nullable data, PYNetwork * _Nonnull target) {
        return true;
    }];
    [netd setBlockComplete:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetwork * _Nonnull target) {
        NSLog(@"");
    }];
    [netd setBlockCancel:^(id  _Nullable data, NSURLResponse * _Nullable response, PYNetDownload * _Nonnull target) {
        NSLog(@"");
    }];
    [netd resume];
//    [netd cancel];
    PYNetUpload * network = [PYNetUpload new];
    network.method = PYNET_HTTP_POST;
    network.url = @"http://192.168.1.186:8081/upload";//@"http://staging.obt.slyi.cc/tmcs_uac/tmc/uploadImg.json";
    network.params = @{@"aa":@"bb"};
    [network setBlockComplete:^(id _Nullable data,NSURLResponse * _Nullable response, PYNetwork * _Nonnull target){
        NSLog(@"%@", [((NSData *)data) description]);
    }];
    [network resumeWithData:UIImagePNGRepresentation([UIImage imageNamed:@"1.png"]) fileName:@"1.png" contentType:@"image/png"];
//    [network resumeWithPath:[NSString stringWithFormat:@"%@/1.png",bundleDir] fileName:@"1.png" contentType:@"image/png"];
//    [network resumeWithData:[NSData new]];
    return YES;
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
