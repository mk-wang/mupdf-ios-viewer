//
//  PDFContext.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PDFCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDFContext : NSObject

@property (nonatomic, assign, readonly) fz_context *ctx;
@property (nonatomic, strong, readonly) dispatch_queue_t queue;
@property (nonatomic, assign, readonly) CGFloat screenScale;

+ (instancetype)sharedContext;

@end

NS_ASSUME_NONNULL_END
