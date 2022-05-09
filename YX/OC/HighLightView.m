//
//  HighLightView.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "HighLightView.h"
#import "PDFUtils.h"

@implementation HighLightView

- (instancetype)initWithFrame:(CGRect)rect
                     rectList:(NSArray *)list
               highlightColor:(UIColor *)color
{
    self = [super initWithFrame:rect];

    if (self != nil) {
        [self setOpaque:NO];
        _rectList = list.copy;
        _highlightColor = [color retain];
        _pageSize = CGSizeZero;
    }
    return self;
}

- (void)setPageSize:(CGSize)pageSize
{
    if (CGSizeEqualToSize(_pageSize, pageSize)) {
        return;
    }

    _pageSize = pageSize;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    if (CGSizeEqualToSize(_pageSize, CGSizeZero)) {
        return;
    }

    CGSize scale = [PDFUtils fit:_pageSize
                              to:self.bounds.size];
    [_highlightColor set];

    for (NSValue *value in _rectList) {
        CGRect rect = value.CGRectValue;
        rect.origin.x *= scale.width;
        rect.origin.y *= scale.height;
        rect.size.width *= scale.width;
        rect.size.height *= scale.height;
        UIRectFill(rect);
    }
}

@end
