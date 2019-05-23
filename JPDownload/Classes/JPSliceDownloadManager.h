//
//  JPSliceDownloadManager.h
//  JPDownload
//
//  Created by wangzhen on 2019/5/23.
//

#import <Foundation/Foundation.h>

/**
 分片下载进度 block
 */
typedef void(^SliceProgressBlock)(NSInteger downloadingIndex,NSInteger totalIndex,uint64_t speed);

/**
 分片下载失败 block
 */
typedef void(^SliceFailureBlock)(NSInteger failureIndex,NSInteger totalIndex,NSError *error);

/**
 分片下载某一片段下载完成 block
 */
typedef void(^SliceCompletionBlock)(NSInteger completionIndex,NSInteger totalIndex,NSString *tempFilePath);

/**
 分片下载完成 block
 */
typedef void(^DownloadCompletionBlock)(NSInteger endIndex,NSInteger totalIndex);

/**
 分片下载错误类型
 */
typedef NS_ENUM(NSInteger, JPSliceDownloadManagerErrorType) {
    JPSliceDownloadManagerErrorTypeInvalidateParameter,
    JPSliceDownloadManagerErrorTypeIndexCrossLine
};

extern NSString *const JPSliceDownloadManagerErrorDomain;
extern NSString *const JPSliceDownloadManagerErrorMessageKey;

@interface JPSliceDownloadManager : NSObject

/**
 * @abstract 添加分片下载任务
 * @parma urls 下载地址数组
 * @parma startIndex 开始下载的索引（起始片是 1）
 * @parma sliceProgressBlock 分片下载进度 block
 * @parma sliceFailureBlock 分片下载失败 block
 * @parma sliceCompletionBlock 分片下载某一片段下载完成 block
 * @parma downloadCompletionBlock 分片下载完成 block
 * @parma error 错误信息
 * @return 返回结果
 */
- (BOOL)addSliceDownloadUrls:(NSArray *)urls
                  startIndex:(NSInteger)startIndex
          sliceProgressBlock:(SliceProgressBlock)sliceProgressBlock
           sliceFailureBlock:(SliceFailureBlock)sliceFailureBlock
        sliceCompletionBlock:(SliceCompletionBlock)sliceCompletionBlock
     downloadCompletionBlock:(DownloadCompletionBlock)downloadCompletionBlock
                       error:(NSError **)error;

/**
 * @abstract 取消分片下载任务
 */
- (void)cancelSliceDownload;

/**
 * @abstract 暂停分片下载任务
 */
- (void)pauseSliceDownload;

/**
 * @abstract 恢复分片下载任务
 */
- (void)resumeSliceDownload;

@end
