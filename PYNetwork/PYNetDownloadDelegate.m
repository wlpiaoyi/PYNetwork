//
//  PYNetDownloadDelegate.m
//  PYNetwork
//
//  Created by wlpiaoyi on 2019/12/23.
//  Copyright © 2019 wlpiaoyi. All rights reserved.
//

#import "PYNetDownloadDelegate.h"
#import "PYNetDownload.h"



@interface PYNetDownload()
kPNSNA PYNetDownloadDelegate * delegate;
@property (nonatomic, copy, nullable) void (^_blockCancel_)(id _Nullable data, NSURLResponse * _Nullable response, PYNetDownload * _Nonnull target) ;
@property (nonatomic, copy, nullable) void (^ _blockDownloadProgress_) (PYNetDownload * _Nonnull target, int64_t currentBytes, int64_t totalBytes);
@end

@implementation PYNetDownloadDelegate


#pragma mark - NSURLSessionDownloadDelegate==>

//这个方法用来跟踪下载数据并且根据进度刷新ProgressView
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    if(self.network == nil) return;
    self.network.outTime = self.network.outTime;
    if (((PYNetDownload *)self.network)._blockDownloadProgress_) {
        ((PYNetDownload *)self.network)._blockDownloadProgress_(((PYNetDownload *)self.network), totalBytesWritten, totalBytesExpectedToWrite);
    }
}

//下载任务完成,这个方法在下载完成时触发，它包含了已经完成下载任务得 Session Task,Download Task和一个指向临时下载文件得文件路径
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    NSString *relativePath = [location relativePath];
    if(self.network == nil) return;
    [self.network setValue:@(PYNetworkStateCompleting) forKey:@"state"];
    if (((PYNetDownload *)self.network).blockComplete) {
        ((PYNetDownload *)self.network).blockComplete(relativePath, nil, ((PYNetDownload *)self.network));
        [((PYNetDownload *)self.network) cancel];
    }
}

//从已经保存的数据中恢复下载任务的委托方法，fileOffset指定了恢复下载时的文件位移字节数：
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(self.network == nil) return;
    if (error) {
        if (((PYNetDownload *)self.network).blockComplete) {
            ((PYNetDownload *)self.network).blockComplete(error, nil, ((PYNetDownload *)self.network));
            [((PYNetDownload *)self.network) cancel];
        }
    }
}
#pragma mark - NSURLSessionDownloadDelegate <==
@end
