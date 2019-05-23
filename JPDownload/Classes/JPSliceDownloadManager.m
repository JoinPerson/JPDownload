//
//  JPSliceDownloadManager.m
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import "JPSliceDownloadManager.h"

NSString *const JPSliceDownloadManagerErrorDomain = @"JPSliceDownloadManagerErrorDomain";
NSString *const JPSliceDownloadManagerErrorMessageKey = @"JPSliceDownloadManagerErrorMessageKey";

@interface JPSliceDownloadManager () <NSURLSessionDownloadDelegate>

@property(nonatomic,copy)NSArray *urls;

@property(nonatomic,assign)NSInteger endIndex;

@property(nonatomic,copy)SliceProgressBlock sliceProgressBlock;

@property(nonatomic,copy)SliceFailureBlock sliceFailureBlock;

@property(nonatomic,copy)SliceCompletionBlock sliceCompletionBlock;

@property(nonatomic,copy)DownloadCompletionBlock downloadCompletionBlock;

@property(nonatomic,strong)NSURLSessionDownloadTask *sessionDownloadTask;

@property(nonatomic,strong)NSURLSession *session;

@property(nonatomic,strong)NSTimer *timer;

@property(nonatomic,assign)int64_t speed;

@end

@implementation JPSliceDownloadManager

#pragma mark - getter

- (NSURLSession *)session
{
    if (_session == nil) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

#pragma mark - Common

- (BOOL)errorHandlerErrorType:(JPSliceDownloadManagerErrorType)errorType
                 errorMessage:(NSString *)errorMessage
                        error:(NSError *_Nullable __autoreleasing *)error
{
    if (error) {
        *error = [NSError errorWithDomain:JPSliceDownloadManagerErrorDomain
                                     code:errorType
                                 userInfo:@{JPSliceDownloadManagerErrorMessageKey : errorMessage}];
    }
    return NO;
}

#pragma mark - Public Method

- (BOOL)addSliceDownloadUrls:(NSArray *)urls
                  startIndex:(NSInteger)startIndex
          sliceProgressBlock:(SliceProgressBlock)sliceProgressBlock
           sliceFailureBlock:(SliceFailureBlock)sliceFailureBlock
        sliceCompletionBlock:(SliceCompletionBlock)sliceCompletionBlock
     downloadCompletionBlock:(DownloadCompletionBlock)downloadCompletionBlock
                       error:(NSError *__autoreleasing *)error
{
    if (urls.count == 0) {
        return [self errorHandlerErrorType:JPSliceDownloadManagerErrorTypeInvalidateParameter
                              errorMessage:@"数组 urls 不能为 nil 且内部元素个数不能是 0"
                                     error:error];
    }
    if (startIndex <= 0) {
        return [self errorHandlerErrorType:JPSliceDownloadManagerErrorTypeInvalidateParameter
                              errorMessage:@"开始索引 startIndex 不能为 0 或者负数"
                                     error:error];
    }
    if (startIndex > urls.count) {
        return [self errorHandlerErrorType:JPSliceDownloadManagerErrorTypeIndexCrossLine
                              errorMessage:@"开始的索引 startIndex 不能大于数组 urls 内部元素个数"
                                     error:error];
    }
    
    [self cancelSliceDownload];
    
    self.urls = urls;
    self.endIndex = startIndex - 1;
    self.sliceProgressBlock = sliceProgressBlock;
    self.sliceFailureBlock = sliceFailureBlock;
    self.sliceCompletionBlock = sliceCompletionBlock;
    self.downloadCompletionBlock = downloadCompletionBlock;
    self.sessionDownloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:self.urls[startIndex - 1]]];
    if (self.timer == nil) {
        [self createTimer];
    }
    [self.sessionDownloadTask resume];
    
    return YES;
}

- (void)cancelSliceDownload
{
    [self stopTimer];
    [self.sessionDownloadTask cancel];
    self.sessionDownloadTask = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
    self.urls = nil;
    self.endIndex = 0;
    self.sliceProgressBlock = nil;
    self.sliceFailureBlock = nil;
    self.sliceCompletionBlock = nil;
    self.downloadCompletionBlock = nil;
}

- (void)pauseSliceDownload {
    if (self.sessionDownloadTask.state == NSURLSessionTaskStateRunning) {
        [self stopTimer];
        [self.sessionDownloadTask suspend];
    }
}

- (void)resumeSliceDownload {
    if (self.sessionDownloadTask.state == NSURLSessionTaskStateSuspended) {
        [self createTimer];
        [self.sessionDownloadTask resume];
    }
}

#pragma mark - NSTimer

- (void)createTimer
{
    self.speed = 0;
    self.timer = [NSTimer timerWithTimeInterval:2.0
                                         target:self
                                       selector:@selector(timerAction)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
    self.speed = 0;
}

- (void)timerAction
{
    if (self.sliceProgressBlock != nil) {
        self.sliceProgressBlock(self.endIndex + 1,self.urls.count,self.speed / 2);
    }
    self.speed = 0;
}

#pragma mark - NSURLSessionTaskDelegate Method

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if (error != nil) {
        [self stopTimer];
        [self.session finishTasksAndInvalidate];
        self.session = nil;
        if (self.sliceFailureBlock != nil) {
            self.sliceFailureBlock(self.endIndex + 1,self.urls.count,error);
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate Method

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    self.endIndex = self.endIndex + 1;
    if (self.sliceCompletionBlock != nil) {
        self.sliceCompletionBlock(self.endIndex,self.urls.count,location.path);
    }
    // 开启下一片下载
    if (self.endIndex + 1 <= self.urls.count) {
        [self addSliceDownloadUrls:self.urls
                        startIndex:self.endIndex + 1
                sliceProgressBlock:self.sliceProgressBlock
                 sliceFailureBlock:self.sliceFailureBlock
              sliceCompletionBlock:self.sliceCompletionBlock
           downloadCompletionBlock:self.downloadCompletionBlock
                             error:NULL];
    }
    else { // 不需要开启下一片下载，下载已完成
        [self stopTimer];
        [self.session finishTasksAndInvalidate];
        self.session = nil;
        if (self.downloadCompletionBlock != nil) {
            self.downloadCompletionBlock(self.endIndex,self.urls.count);
        }
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    self.speed = self.speed + bytesWritten;
}


@end
