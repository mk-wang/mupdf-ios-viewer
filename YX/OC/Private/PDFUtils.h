//
//  PDFUtils.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFUtils : NSObject

+ (CGSize)fit:(CGSize)page to:(CGSize)screen;

@end

NS_ASSUME_NONNULL_END
