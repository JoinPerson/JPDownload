//
//  JPOnceDownloadManager.m
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import "JPOnceDownloadManager.h"

@interface JPOnceDownloadManager () <NSURLSessionDownloadDelegate>

@property(nonatomic,copy)OnceProgressBlock onceProgressBlock;

@property(nonatomic,copy)OnceFailureBlock onceFailureBlock;

@property(nonatomic,copy)OnceCompletionBlock onceCompletionBlock;

@property(nonatomic,strong)NSURLSessionDownloadTask *sessionDownloadTask;

@property(nonatomic,strong)NSURLSession *session;

@property(nonatomic,strong)NSTimer *timer;

@property(nonatomic,assign)int64_t speed;

@property(nonatomic,assign)int64_t totalBytesWritten;

@property(nonatomic,assign)int64_t totalBytesExpectedToWrite;

@end

@implementation JPOnceDownloadManager

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

#pragma mark - Public Method

- (void)addOnceDownloadUrl:(NSString *)url
         onceProgressBlock:(OnceProgressBlock)onceProgressBlock
          onceFailureBlock:(OnceFailureBlock)onceFailureBlock
       onceCompletionBlock:(OnceCompletionBlock)onceCompletionBlock;
{
    [self cancelOnceDownload];
    
    self.onceProgressBlock = onceProgressBlock;
    self.onceFailureBlock = onceFailureBlock;
    self.onceCompletionBlock = onceCompletionBlock;
    self.sessionDownloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:url]];
    [self createTimer];
    [self.sessionDownloadTask resume];
}

- (void)cancelOnceDownload
{
    [self stopTimer];
    [self.sessionDownloadTask cancel];
    self.sessionDownloadTask = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
    self.totalBytesWritten = 0;
    self.totalBytesExpectedToWrite = 0;
    self.onceProgressBlock = nil;
    self.onceFailureBlock = nil;
    self.onceCompletionBlock = nil;
}

- (void)pauseOnceDownload
{
    if (self.sessionDownloadTask.state == NSURLSessionTaskStateRunning) {
        [self stopTimer];
        [self.sessionDownloadTask suspend];
    }
}

- (void)resumeOnceDownload
{
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
    if (self.onceProgressBlock != nil && self.totalBytesExpectedToWrite != 0) {
        self.onceProgressBlock(self.totalBytesWritten,self.totalBytesExpectedToWrite,self.speed / 2);
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
        if (self.onceFailureBlock != nil) {
            self.onceFailureBlock(self.totalBytesWritten,self.totalBytesExpectedToWrite,error);
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate Method

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    [self stopTimer];
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    if (self.onceCompletionBlock != nil) {
        self.onceCompletionBlock(self.totalBytesWritten,self.totalBytesExpectedToWrite,location.path,downloadTask.response.suggestedFilename);
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    self.speed = self.speed + bytesWritten;
    self.totalBytesWritten = totalBytesWritten;
    self.totalBytesExpectedToWrite = totalBytesExpectedToWrite;
}

@end
