//
//  PDFUtils.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFAnnotation.h"
#import "PDFWord.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class PDFDoc;
@interface PDFUtils : NSObject

+ (CGSize)fit:(CGSize)page
           to:(CGSize)screen;


+ (void)renderPage:(PDFDoc *)pDoc
        boundsSize:(CGSize)boundsSize
       screenScale:(CGFloat)screenScale
            number:(NSInteger)number
        completion:(void(^)(UIImage * _Nullable ))completion;

// should run in PDFContext.sharedContext.queue
+ (nullable UIImage *)renderPage:(PDFDoc *)pDoc
                      boundsSize:(CGSize)boundsSize
                     screenScale:(CGFloat)screenScale
                          number:(NSInteger)number;


@end

NS_ASSUME_NONNULL_END
