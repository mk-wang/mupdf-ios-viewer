//
//  HitView.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#include "HighLightView.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TapResult;
@class PDFDoc;
@class PDFLink;
@interface HitView : HighLightView

- (instancetype)initWithFrame:(CGRect)frame
                        links:(NSArray<PDFLink *> *)links
                     document:(PDFDoc *)doc
               highlightColor:(UIColor *)color;

- (nullable TapResult *)handleTap:(CGPoint)pt;

@end

NS_ASSUME_NONNULL_END
