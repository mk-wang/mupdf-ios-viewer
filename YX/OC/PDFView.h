//
//  PDFView.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFDoc.h"
#import "PageView.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PDFView : UIScrollView <UIScrollViewDelegate>
- (instancetype)initWithFrame:(CGRect)frame
                     document:(PDFDoc *)aDoc
                         page:(NSInteger)aNumber;
- (void)displayImage:(UIImage *)image;
- (void)resizeImage;
- (void)loadPage;
- (void)loadTile;
@end

NS_ASSUME_NONNULL_END
