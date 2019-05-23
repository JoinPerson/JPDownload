//
//  JPDownloadManager.m
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import "JPDownloadManager.h"

NSString *const JPDownloadManagerErrorDomain = @"JPDownloadManagerErrorDomain";
NSString *const JPDownloadManagerErrorMessageKey = @"JPDownloadManagerErrorMessageKey";

@interface JPDownloadManager ()

@property(nonatomic,strong)NSMutableDictionary *sliceDownloadManagerMDic;

@property(nonatomic,strong)NSMutableDictionary *onceDownloadManagerMDic;

@property(nonatomic,strong)NSMutableDictionary *breakPointDownloadManagerMDic;

@end

@implementation JPDownloadManager

+ (instancetype)sharedDownloadManager
{
    static JPDownloadManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.sliceDownloadManagerMDic = [NSMutableDictionary dictionary];
        instance.onceDownloadManagerMDic = [NSMutableDictionary dictionary];
        instance.breakPointDownloadManagerMDic = [NSMutableDictionary dictionary];
    });
    return instance;
}

- (BOOL)errorHandlerErrorType:(JPDownloadManagerErrorType)errorType
                 errorMessage:(NSString *)errorMessage
                        error:(NSError *_Nullable __autoreleasing *)error
{
    if (error) {
        *error = [NSError errorWithDomain:JPDownloadManagerErrorDomain
                                     code:errorType
                                 userInfo:@{JPDownloadManagerErrorMessageKey : errorMessage}];
    }
    return NO;
}

- (BOOL)addSliceDownloadUrls:(NSArray *)urls
                  startIndex:(NSInteger)startIndex
                         key:(NSString *)key
          sliceProgressBlock:(SliceProgressBlock)sliceProgressBlock
           sliceFailureBlock:(SliceFailureBlock)sliceFailureBlock
        sliceCompletionBlock:(SliceCompletionBlock)sliceCompletionBlock
     downloadCompletionBlock:(DownloadCompletionBlock)downloadCompletionBlock
                       error:(NSError *__autoreleasing *)error
{
    if (key.length == 0) {
        return [self errorHandlerErrorType:JPDownloadManagerErrorTypeInvalidateParameter
                              errorMessage:@"参数 key 不能为 nil 或者空字符串"
                                     error:error];
    } else {
        // 存在下载
        if ([self.sliceDownloadManagerMDic objectForKey:key]) {
            return YES;
        } else {
            JPSliceDownloadManager *sliceDownloadManager = [[JPSliceDownloadManager alloc] init];
            [self.sliceDownloadManagerMDic setObject:sliceDownloadManager forKey:key];
            __weak typeof(self) weakSelf = self;
            return [sliceDownloadManager addSliceDownloadUrls:urls
                                                   startIndex:startIndex
                                           sliceProgressBlock:sliceProgressBlock
                                            sliceFailureBlock:^(NSInteger failureIndex, NSInteger totalIndex, NSError *error) {
                                                !sliceFailureBlock ?: sliceFailureBlock(failureIndex,totalIndex,error);
                                                [weakSelf.sliceDownloadManagerMDic removeObjectForKey:key];
                                            }
                                         sliceCompletionBlock:sliceCompletionBlock
                                      downloadCompletionBlock:^(NSInteger endIndex, NSInteger totalIndex) {
                                          !downloadCompletionBlock ?:  downloadCompletionBlock(endIndex,totalIndex);
                                          [weakSelf.sliceDownloadManagerMDic removeObjectForKey:key];
                                      } error:error];
        }
    }
}

- (void)addOnceDownloadUrl:(NSString *)url
                       key:(NSString *)key
         onceProgressBlock:(OnceProgressBlock)onceProgressBlock
          onceFailureBlock:(OnceFailureBlock)onceFailureBlock
       onceCompletionBlock:(OnceCompletionBlock)onceCompletionBlock
                     error:(NSError *__autoreleasing *)error
{
    if (key.length == 0) {
        [self errorHandlerErrorType:JPDownloadManagerErrorTypeInvalidateParameter
                       errorMessage:@"参数 key 不能为 nil 或者空字符串"
                              error:error];
    } else {
        // 存在下载
        if ([self.onceDownloadManagerMDic objectForKey:key]) {
            return;
        } else {
            JPOnceDownloadManager *onceDownloadManager = [[JPOnceDownloadManager alloc] init];
            [self.onceDownloadManagerMDic setObject:onceDownloadManager forKey:key];
            __weak typeof(self) weakSelf = self;
            [onceDownloadManager addOnceDownloadUrl:url onceProgressBlock:onceProgressBlock
                                   onceFailureBlock:^(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, NSError *error) {
                                       !onceFailureBlock ?: onceFailureBlock(totalBytesWritten,totalBytesExpectedToWrite,error);
                                       [weakSelf.onceDownloadManagerMDic removeObjectForKey:key];
                                   } onceCompletionBlock:^(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite, NSString *tempFilePath, NSString *suggestedFilename) {
                                       !onceCompletionBlock ?: onceCompletionBlock(totalBytesWritten,totalBytesExpectedToWrite,tempFilePath,suggestedFilename);
                                       [weakSelf.onceDownloadManagerMDic removeObjectForKey:key];
                                   }];
        }
    }
}

- (void)addBreakPointDownloadUrl:(NSString *)url
                             key:(NSString *)key
         breakPointProgressBlock:(BreakPointProgressBlock)breakPointProgressBlock
          breakPointFailureBlock:(BreakPointFailureBlock)breakPointFailureBlock
       breakPointCompletionBlock:(BreakPointCompletionBlock)breakPointCompletionBlock
                           error:(NSError *__autoreleasing *)error
{
    if (key.length == 0) {
        [self errorHandlerErrorType:JPDownloadManagerErrorTypeInvalidateParameter
                       errorMessage:@"参数 key 不能为 nil 或者空字符串"
                              error:error];
    } else {
        // 存在下载
        if ([self.breakPointDownloadManagerMDic objectForKey:key]) {
            return;
        } else {
            JPBreakPointDownloadManager *breakPointDownloadManager = [[JPBreakPointDownloadManager alloc] init];
            [self.breakPointDownloadManagerMDic setObject:breakPointDownloadManager forKey:key];
            __weak typeof(self) weakSelf = self;
            [breakPointDownloadManager addBreakPointDownloadUrl:url
                                        breakPointProgressBlock:breakPointProgressBlock
                                         breakPointFailureBlock:^(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive, NSError *error) {
                                             !breakPointFailureBlock ?: breakPointFailureBlock(countOfBytesReceived,countOfBytesExpectedToReceive,error);
                                             [weakSelf.breakPointDownloadManagerMDic removeObjectForKey:key];
                                         } breakPointCompletionBlock:^(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive, NSString *tempFilePath, NSString *suggestedFilename) {
                                             !breakPointCompletionBlock ?: breakPointCompletionBlock(countOfBytesReceived,countOfBytesExpectedToReceive,tempFilePath,suggestedFilename);
                                             [weakSelf.breakPointDownloadManagerMDic removeObjectForKey:key];
                                         }];
        }
    }
}

- (void)cancelDownloadKey:(NSString *)key
             downloadType:(JPDownloadType)downloadType
{
    if (key.length == 0) {
        return;
    }
    if (downloadType == JPDownloadTypeSlice) {
        JPSliceDownloadManager *sliceDownloadManager = [self.sliceDownloadManagerMDic objectForKey:key];
        if (sliceDownloadManager != nil) {
            [sliceDownloadManager cancelSliceDownload];
            [self.sliceDownloadManagerMDic removeObjectForKey:key];
        }
    } else if (downloadType == JPDownloadTypeOnce) {
        JPOnceDownloadManager *onceDownloadManager = [self.onceDownloadManagerMDic objectForKey:key];
        if (onceDownloadManager != nil) {
            [onceDownloadManager cancelOnceDownload];
            [self.onceDownloadManagerMDic removeObjectForKey:key];
        }
    } else if (downloadType == JPDownloadTypeBreakPoint) {
        JPBreakPointDownloadManager *breakPointDownloadManager = [self.breakPointDownloadManagerMDic objectForKey:key];
        if (breakPointDownloadManager != nil) {
            [breakPointDownloadManager cancelBreakPointDownload];
            [self.breakPointDownloadManagerMDic removeObjectForKey:key];
        }
    }
}

- (void)pauseDownloadKey:(NSString *)key
            downloadType:(JPDownloadType)downloadType
{
    if (key.length == 0) {
        return;
    }
    if (downloadType == JPDownloadTypeSlice) {
        JPSliceDownloadManager *sliceDownloadManager = [self.sliceDownloadManagerMDic objectForKey:key];
        if (sliceDownloadManager != nil) {
            [sliceDownloadManager pauseSliceDownload];
        }
    } else if (downloadType == JPDownloadTypeOnce) {
        JPOnceDownloadManager *onceDownloadManager = [self.onceDownloadManagerMDic objectForKey:key];
        if (onceDownloadManager != nil) {
            [onceDownloadManager pauseOnceDownload];
        }
    } else if (downloadType == JPDownloadTypeBreakPoint) {
        JPBreakPointDownloadManager *breakPointDownloadManager = [self.breakPointDownloadManagerMDic objectForKey:key];
        if (breakPointDownloadManager != nil) {
            [breakPointDownloadManager pauseBreakPointDownload];
        }
    }
}

- (void)resumeDownloadKey:(NSString *)key
             downloadType:(JPDownloadType)downloadType
{
    if (key.length == 0) {
        return;
    }
    if (downloadType == JPDownloadTypeSlice) {
        JPSliceDownloadManager *sliceDownloadManager = [self.sliceDownloadManagerMDic objectForKey:key];
        if (sliceDownloadManager != nil) {
            [sliceDownloadManager resumeSliceDownload];
        }
    } else if (downloadType == JPDownloadTypeOnce) {
        JPOnceDownloadManager *onceDownloadManager = [self.onceDownloadManagerMDic objectForKey:key];
        if (onceDownloadManager != nil) {
            [onceDownloadManager resumeOnceDownload];
        }
    } else if (downloadType == JPDownloadTypeBreakPoint) {
        JPBreakPointDownloadManager *breakPointDownloadManager = [self.breakPointDownloadManagerMDic objectForKey:key];
        if (breakPointDownloadManager != nil) {
            [breakPointDownloadManager resumeBreakPointDownload];
        }
    }
}

@end
