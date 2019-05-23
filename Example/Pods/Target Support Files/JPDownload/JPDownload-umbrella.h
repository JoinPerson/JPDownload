#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "JPBreakPointDownloadManager.h"
#import "JPDownloadManager.h"
#import "JPOnceDownloadManager.h"
#import "JPSliceDownloadManager.h"

FOUNDATION_EXPORT double JPDownloadVersionNumber;
FOUNDATION_EXPORT const unsigned char JPDownloadVersionString[];

