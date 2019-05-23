//
//  JPBreakPointDownloadManager.h
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import <Foundation/Foundation.h>

/**
 断点续传下载进度 block
 */
typedef void(^BreakPointProgressBlock)(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive ,int64_t speed);

/**
 断点续传下载失败 block
 */
typedef void(^BreakPointFailureBlock)(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive ,NSError *error);

/**
 断点续传下载完成 block
 */
typedef void(^BreakPointCompletionBlock)(int64_t countOfBytesReceived, int64_t countOfBytesExpectedToReceive ,NSString *tempFilePath, NSString *suggestedFilename);

/**
 断点续传下载错误类型
 */
typedef NS_ENUM(NSInteger, JPBreakPointDownloadManagerErrorType) {
    JPBreakPointDownloadManagerErrorTypeInvalidateParameter
};

extern NSString *const JPBreakPointDownloadManagerErrorDomain;
extern NSString *const JPBreakPointDownloadManagerErrorMessageKey;

/**
 断点续传下载管理器
 */
@interface JPBreakPointDownloadManager : NSObject

/**
 * @abstract 添加断点下载的下载任务
 * @parma url 需要下载的 url
 * @parma breakPointProgressBlock 断点续传下载进度 block
 * @parma breakPointFailureBlock 断点续传下载失败 block
 * @parma breakPointCompletionBlock 断点续传下载完成 block
 */
- (void)addBreakPointDownloadUrl:(NSString *)url
         breakPointProgressBlock:(BreakPointProgressBlock)breakPointProgressBlock
          breakPointFailureBlock:(BreakPointFailureBlock)breakPointFailureBlock
       breakPointCompletionBlock:(BreakPointCompletionBlock)breakPointCompletionBlock;

/**
 * @abstract 取消断点下载的下载任务
 */
- (void)cancelBreakPointDownload;

/**
 * @abstract 暂停断点下载的下载任务
 */
- (void)pauseBreakPointDownload;

/**
 * @abstract 恢复断点下载的下载任务
 */
- (void)resumeBreakPointDownload;

@end
