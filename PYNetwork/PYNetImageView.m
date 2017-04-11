//
//  PYNetImageView.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2017/4/10.
//  Copyright © 2017年 wlpiaoyi. All rights reserved.
//

#import "PYNetImageView.h"
#import "PYViewAutolayoutCenter.h"
#import "PYNetDownload.h"

static NSString * PYNetImageViewDataCaches;

@interface PYNetImageView()
PYPNSNN UIActivityIndicatorView * aiv;
PYPNSNN PYNetDownload * dnw;
PYPNSNA NSString * cachesUrl;
@end

@implementation PYNetImageView

+(void) initialize{
    [PYUtile class];
    [PYNetImageView checkCachesPath];
}

PYINITPARAMS;

+(NSString *) parseImageUrlToImagePath:(NSString *) imageUrl{
    
    if(![[imageUrl substringWithRange:NSMakeRange(0, 4)] isEqual:@"http"]){
        return nil;
    }
    NSMutableString * imagePath = [NSMutableString new];
    [imagePath appendString:PYNetImageViewDataCaches];
    NSMutableString * imageName = [NSMutableString new];
    [imageName appendString:@"PY_IMAGE_DATA"];
    NSArray<NSString*> *imgUrlArray = [imageUrl componentsSeparatedByString:@"/"];
    for (NSUInteger i = (imgUrlArray.count - 1); i > 0 ; i--) {
        [imageName appendString:imgUrlArray[i]];
        if(imageName.length > 40){
            break;
        }
    }
    [imagePath appendFormat:@"/%@",imageName];
    return imagePath;
}

-(void) initParams{
    
    self.dnw = [PYNetDownload new];
    [self.dnw setBlockReceiveChallenge:^BOOL(id  _Nullable data, PYNetDownload * _Nonnull target) {
        return true;
    }];
    __unsafe_unretained typeof(self) uself = self;
    [self.dnw setBlockProgress:^(PYNetDownload * _Nonnull target, int64_t currentBytes, int64_t totalBytes) {
        if(uself.blockProgress){
            uself.blockProgress((double)currentBytes/(double)totalBytes, uself);
        }
    }];
    [self.dnw setBlockSuccess:^(id  _Nullable data, PYNetDownload * _Nonnull target) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [uself.aiv stopAnimating];
            });  
        });
        uself.cachesUrl = nil;
        if(data == nil || ![data isKindOfClass:[NSString class]]){
            return;
        }
        BOOL isDirectory = false;
        if(![[NSFileManager defaultManager] fileExistsAtPath:data isDirectory:&isDirectory] || isDirectory){
            return;
        }
        NSString * imagePath = [PYNetImageView parseImageUrlToImagePath:uself.imgUrl];
        imagePath = imagePath ? imagePath : uself.imgUrl;
        NSError * erro;
        if([[NSFileManager defaultManager] fileExistsAtPath:imagePath isDirectory:nil]) [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&erro];
        erro = nil;
        [[NSFileManager defaultManager] moveItemAtPath:data toPath:imagePath error:&erro];
        if(erro == nil){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    uself.cachesUrl = imagePath;
                    if(uself.blockDisplay){
                        uself.blockDisplay(true,false, uself);
                    }
                });
            });
        }else{
            NSLog(@"%@ image errocode:%ld, errodomain:%@",NSStringFromClass([PYNetImageView class]), (long)[erro code], [erro domain]);
        }
    }];
    [self.dnw setBlockFaild:^(id  _Nullable data, PYNetDownload * _Nonnull target) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [uself.aiv stopAnimating];
                if(uself.blockDisplay){
                    uself.blockDisplay(false,false, uself);
                }
            });
        });;
    }];
    [self.dnw setBlockCancel:^(id  _Nullable data, PYNetDownload * _Nonnull target) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [uself.aiv stopAnimating];
                if(uself.blockDisplay){
                    uself.blockDisplay(false,false, uself);
                }
            });
        });
    }];
    self.aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self addSubview:self.aiv];
    [PYViewAutolayoutCenter persistConstraint:self.aiv size:CGSizeMake(50, 50)];
    [PYViewAutolayoutCenter persistConstraint:self.aiv centerPointer:CGPointMake(0, 0)];
}
-(void) setCachesUrl:(NSString *)cachesUrl{
    _cachesUrl = cachesUrl;
    if(_cachesUrl != nil){
        self.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:self.cachesUrl]];
    }else{
        self.image = nil;
    }
}
-(void) setImgUrl:(NSString *)imgUrl{
    _imgUrl = imgUrl;
    if([self.dnw.stringUrl isEqual:self.imgUrl]){
        return;
    }
    [self.dnw cancel];
    
    NSString * imagePath = [PYNetImageView parseImageUrlToImagePath:self.imgUrl];
    if(imagePath == nil){
        self.cachesUrl = imgUrl;
        if(self.blockDisplay){
            _blockDisplay(true,false, self);
        }
        return;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:imagePath isDirectory:nil]){
        self.cachesUrl = imagePath;
        if(self.blockDisplay){
            _blockDisplay(true,true, self);
        }
        return;
    }
    
    self.dnw.stringUrl = imgUrl;
    [self.dnw resume];
    [self.aiv startAnimating];
}

+(bool) clearCache:(nonnull NSString *) imgUrl{
    NSString * imagePath = [PYNetImageView parseImageUrlToImagePath:imgUrl];
    if(imagePath == nil) return false;
    NSError * erro;
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&erro];
    if(erro) return false;
    return true;
}

+(bool) clearCaches{
    NSError * erro;
    [[NSFileManager defaultManager] removeItemAtPath:PYNetImageViewDataCaches error:&erro];
    [PYNetImageView checkCachesPath];
    if(erro) return false;
    return true;
}

+(void) checkCachesPath{
    PYNetImageViewDataCaches = [NSString stringWithFormat:@"%@/imageCaches", cachesDir];
    BOOL isDirectory = false;
    BOOL hasPath = [[NSFileManager defaultManager] fileExistsAtPath:PYNetImageViewDataCaches isDirectory:&isDirectory];
    if(!hasPath || (hasPath && !isDirectory)){
        NSError * error;
        [[NSFileManager defaultManager] createDirectoryAtPath:PYNetImageViewDataCaches withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSAssert(NO, @"%@",error);
        }
    }
}

-(void) dealloc{
    [self.aiv stopAnimating];
}

@end
