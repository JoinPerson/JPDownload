//
//  JPDownloadManager.h
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import <Foundation/Foundation.h>
#import "JPSliceDownloadManager.h"
#import "JPOnceDownloadManager.h"
#import "JPBreakPointDownloadManager.h"

/**
 下载类型
 */
typedef NS_ENUM(NSInteger, JPDownloadType) {
    JPDownloadTypeSlice,
    JPDownloadTypeOnce,
    JPDownloadTypeBreakPoint
};

/**
 下载管理器错误类型
 */
typedef NS_ENUM(NSInteger, JPDownloadManagerErrorType) {
    JPDownloadManagerErrorTypeInvalidateParameter
};

extern NSString *const JPDownloadManagerErrorDomain;
extern NSString *const JPDownloadManagerErrorMessageKey;

/**
 下载管理器，关于下面的参数key主要是用于和某一个下载任务绑定的key的值最好是与下载任务的url一致
 */
@interface JPDownloadManager : NSObject

/**
 * @abstract 获取下载管理器的单例方法
 */
+ (instancetype)sharedDownloadManager;

/**
 * @abstract 添加一个分片下载任务
 * @parma urls 下载地址数组
 * @parma startIndex 开始下载的索引（起始片是 1）
 * @parma key 分片下载任务对应的键值
 * @parma sliceProgressBlock 分片下载进度 block
 * @parma sliceFailureBlock 分片下载失败 block
 * @parma sliceCompletionBlock 分片下载某一片段下载完成 block
 * @parma downloadCompletionBlock 分片下载完成 block
 * @parma error 错误信息
 * @return 返回结果
 */
- (BOOL)addSliceDownloadUrls:(NSArray *)urls
                  startIndex:(NSInteger)startIndex
                         key:(NSString *)key
          sliceProgressBlock:(SliceProgressBlock)sliceProgressBlock
           sliceFailureBlock:(SliceFailureBlock)sliceFailureBlock
        sliceCompletionBlock:(SliceCompletionBlock)sliceCompletionBlock
     downloadCompletionBlock:(DownloadCompletionBlock)downloadCompletionBlock
                       error:(NSError **)error;

/**
 * @abstract 添加一次性下载任务
 * @parma url 下载地址
 * @parma key 一次性下载任务对应的键值
 * @parma onceProgressBlock 下载进度 block
 * @parma onceFailureBlock 下载失败 block
 * @parma onceCompletionBlock 下载完成 block
 * @parma error 错误信息
 */
- (void)addOnceDownloadUrl:(NSString *)url
                       key:(NSString *)key
         onceProgressBlock:(OnceProgressBlock)onceProgressBlock
          onceFailureBlock:(OnceFailureBlock)onceFailureBlock
       onceCompletionBlock:(OnceCompletionBlock)onceCompletionBlock
                     error:(NSError **)error;

/**
 * @abstract 添加断点下载的下载任务
 * @parma url 需要下载的 url
 * @parma key 断点下载任务对应的键值
 * @parma breakPointProgressBlock 断点续传下载进度 block
 * @parma breakPointFailureBlock 断点续传下载失败 block
 * @parma breakPointCompletionBlock 断点续传下载完成 block
 * @parma error 错误信息
 */
- (void)addBreakPointDownloadUrl:(NSString *)url
                             key:(NSString *)key
         breakPointProgressBlock:(BreakPointProgressBlock)breakPointProgressBlock
          breakPointFailureBlock:(BreakPointFailureBlock)breakPointFailureBlock
       breakPointCompletionBlock:(BreakPointCompletionBlock)breakPointCompletionBlock
                           error:(NSError **)error;
/**
 * @abstract 取消下载任务
 * @parma key 任务对应的键值
 * @parma downloadType 下载任务的类型
 */
- (void)cancelDownloadKey:(NSString *)key
             downloadType:(JPDownloadType)downloadType;

/**
 * @abstract 暂停下载任务
 * @parma key 任务对应的键值
 * @parma downloadType 下载任务的类型
 */
- (void)pauseDownloadKey:(NSString *)key
            downloadType:(JPDownloadType)downloadType;

/**
 * @abstract 恢复下载任务
 * @parma key 任务对应的键值
 * @parma downloadType 下载任务的类型
 */
- (void)resumeDownloadKey:(NSString *)key
             downloadType:(JPDownloadType)downloadType;

@end
