//
//  PDFAnnotation.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFAnnotation : NSObject

@property (readonly) int type;
@property (readonly) CGRect rect;

- (instancetype)initFromAnnot:(void *)annot;

@end

NS_ASSUME_NONNULL_END
