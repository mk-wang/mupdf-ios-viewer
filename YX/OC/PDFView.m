//
//  PDFView.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFView.h"

@implementation PDFView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

- (instancetype)initWithFrame:(CGRect)frame
                     document:(PDFDoc *)aDoc
                         page:(NSInteger)aNumber
{

    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)displayImage:(UIImage *)image
{
}

- (void)resizeImage
{
}

- (void)loadPage
{
}

- (void)loadTile
{
}

@end
