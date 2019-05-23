//
//  JPBreakPointDownloadManager.m
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import "JPBreakPointDownloadManager.h"

NSString *const JPBreakPointDownloadManagerErrorDomain = @"JPBreakPointDownloadManagerErrorDomain";
NSString *const JPBreakPointDownloadManagerErrorMessageKey = @"JPBreakPointDownloadManagerErrorMessageKey";

@interface JPBreakPointDownloadManager () <NSURLSessionDataDelegate>

@property(nonatomic,copy)BreakPointProgressBlock breakPointProgressBlock;

@property(nonatomic,copy)BreakPointFailureBlock breakPointFailureBlock;

@property(nonatomic,copy)BreakPointCompletionBlock breakPointCompletionBlock;

@property(nonatomic,strong)NSURLSessionDataTask *sessionDataTask;

@property(nonatomic,strong)NSURLSession *session;

@property(nonatomic,strong)NSTimer *timer;

@property(nonatomic,assign)int64_t speed;

@property(nonatomic,assign)int64_t countOfBytesReceived;

@property(nonatomic,assign)int64_t countOfBytesExpectedToReceive;

@property(nonatomic,copy)NSString *breakPointDownloadCachePath;

@property(nonatomic,strong)NSFileHandle *fileHandle;

@property(nonatomic,strong)NSString *url;

@end

@implementation JPBreakPointDownloadManager

+ (void)initialize
{
    [super initialize];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *breakPointDownloadCachePath = [cachePath stringByAppendingPathComponent:@"breakPointDownloadCache"];
    // 文件夹不存在则创建
    if (![fileManager fileExistsAtPath:breakPointDownloadCachePath]) {
        [fileManager createDirectoryAtPath:breakPointDownloadCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

#pragma mark - download Enviromnet Lazing loading Init Methods

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

- (NSString *)breakPointDownloadCachePath
{
    if (_breakPointDownloadCachePath == nil) {
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _breakPointDownloadCachePath = [cachePath stringByAppendingPathComponent:@"breakPointDownloadCache"];
    }
    return _breakPointDownloadCachePath;
}

- (NSFileHandle *)fileHandle
{
    if (_fileHandle == nil) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *fileCache = [self.breakPointDownloadCachePath
                               stringByAppendingPathComponent:[[[self.url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tmp"]];
        // 文件不存在则创建
        if (![fileManager fileExistsAtPath:fileCache]) {
            [fileManager createFileAtPath:fileCache contents:nil attributes:nil];
        }
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileCache];
    }
    return _fileHandle;
}

#pragma mark - common Method

- (long long)fileSizeForPath:(NSString *)path
{
    long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDic) {
            fileSize = [fileDic fileSize];
        }
        else {
            [fileManager removeItemAtPath:path error:NULL];
        }
    }
    return fileSize;
}

- (void)removeTempFile
{
    if (self.url.length != 0) {
        NSString *fileCache = [self.breakPointDownloadCachePath
                               stringByAppendingPathComponent:[[[self.url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tmp"]];
        [[NSFileManager defaultManager] removeItemAtPath:fileCache error:NULL];
    }
}

#pragma mark - Public Method

- (void)addBreakPointDownloadUrl:(NSString *)url
         breakPointProgressBlock:(BreakPointProgressBlock)breakPointProgressBlock
          breakPointFailureBlock:(BreakPointFailureBlock)breakPointFailureBlock
       breakPointCompletionBlock:(BreakPointCompletionBlock)breakPointCompletionBlock
{
    if (url.length == 0) {
        if (breakPointFailureBlock != nil) {
            NSError *error = [NSError errorWithDomain:JPBreakPointDownloadManagerErrorDomain
                                                 code:JPBreakPointDownloadManagerErrorTypeInvalidateParameter
                                             userInfo:@{JPBreakPointDownloadManagerErrorMessageKey : @"url 不能为 nil 或者空字符串"}];
            
            breakPointFailureBlock(0,0,error);
        }
        return;
    }
    
    [self cancelBreakPointDownload];
    
    self.url = url;
    self.breakPointProgressBlock = breakPointProgressBlock;
    self.breakPointFailureBlock = breakPointFailureBlock;
    self.breakPointCompletionBlock = breakPointCompletionBlock;
    NSString *fileCache = [self.breakPointDownloadCachePath
                           stringByAppendingPathComponent:[[[self.url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tmp"]];
    self.countOfBytesReceived = [self fileSizeForPath:fileCache];
    self.countOfBytesExpectedToReceive = 0;
    NSMutableURLRequest *mURLRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    if (self.countOfBytesReceived > 0) {
        NSString *mURLRequestRange = [NSString stringWithFormat:@"bytes=%llu-", self.countOfBytesReceived];
        [mURLRequest setValue:mURLRequestRange forHTTPHeaderField:@"Range"];
    }
    self.sessionDataTask = [self.session dataTaskWithRequest:mURLRequest];
    if (self.timer == nil) {
        [self createTimer];
    }
    [self.sessionDataTask resume];
}

- (void)cancelBreakPointDownload
{
    [self stopTimer];
    [self.sessionDataTask cancel];
    self.sessionDataTask = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
    self.countOfBytesReceived = 0;
    self.countOfBytesExpectedToReceive = 0;
    self.breakPointProgressBlock = nil;
    self.breakPointFailureBlock = nil;
    self.breakPointCompletionBlock = nil;
    self.breakPointDownloadCachePath = nil;
    self.fileHandle = nil;
    // 移除下载的缓存文件
    [self removeTempFile];
    self.url = nil;
}

- (void)pauseBreakPointDownload
{
    if (self.sessionDataTask.state == NSURLSessionTaskStateRunning) {
        [self stopTimer];
        [self.sessionDataTask suspend];
    }
}

- (void)resumeBreakPointDownload
{
    if (self.sessionDataTask.state == NSURLSessionTaskStateSuspended) {
        [self createTimer];
        [self.sessionDataTask resume];
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
    if (self.breakPointProgressBlock != nil && self.countOfBytesExpectedToReceive != 0) {
        self.breakPointProgressBlock(self.countOfBytesReceived,self.countOfBytesExpectedToReceive,self.speed / 2);
    }
    self.speed = 0;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    // 为了防止下载完成后点击继续下载得到的 self.countOfBytesExpectedToReceive 为 0
    self.countOfBytesExpectedToReceive = MAX(self.countOfBytesExpectedToReceive, self.countOfBytesReceived);
    [self stopTimer];
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    if (error != nil) {
        if (self.breakPointFailureBlock != nil) {
            self.breakPointFailureBlock(self.countOfBytesReceived, self.countOfBytesExpectedToReceive, error);
        }
    } else {
        if (self.breakPointCompletionBlock != nil) {
            NSString *tempFileCache = [self.breakPointDownloadCachePath
                                       stringByAppendingPathComponent:[[[self.url lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"tmp"]];
            self.breakPointCompletionBlock(self.countOfBytesReceived, self.countOfBytesExpectedToReceive, tempFileCache, task.response.suggestedFilename);
        }
    }
}

#pragma mark - NSURLSessionDataDelegate Method

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    self.countOfBytesExpectedToReceive = dataTask.countOfBytesExpectedToReceive;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [self.fileHandle seekToEndOfFile];
    [self.fileHandle writeData:data];
    self.countOfBytesReceived = self.countOfBytesReceived + data.length;
    self.speed = self.speed + data.length;
}

@end
