//
//  JPOnceDownloadManager.h
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import <Foundation/Foundation.h>

/**
 一次性下载进度 block
 */
typedef void(^OnceProgressBlock)(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite ,int64_t speed);

/**
 一次性下载失败 block
 */
typedef void(^OnceFailureBlock)(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite ,NSError *error);

/**
 一次性下载完成 block
 */
typedef void(^OnceCompletionBlock)(int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite ,NSString *tempFilePath, NSString *suggestedFilename);

/**
 一次性下载管理器
 */
@interface JPOnceDownloadManager : NSObject

/**
 * @abstract 添加一次性下载任务
 * @parma url 下载地址
 * @parma onceProgressBlock 下载进度 block
 * @parma onceFailureBlock 下载失败 block
 * @parma onceCompletionBlock 下载完成 block
 */
- (void)addOnceDownloadUrl:(NSString *)url
         onceProgressBlock:(OnceProgressBlock)onceProgressBlock
          onceFailureBlock:(OnceFailureBlock)onceFailureBlock
       onceCompletionBlock:(OnceCompletionBlock)onceCompletionBlock;

/**
 * @abstract 取消一次性下载任务
 */
- (void)cancelOnceDownload;

/**
 * @abstract 暂停一次性下载任务
 */
- (void)pauseOnceDownload;

/**
 * @abstract 恢复一次性下载任务
 */
- (void)resumeOnceDownload;

@end
