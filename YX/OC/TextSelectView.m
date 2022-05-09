//
//  PDFTextSelectView.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "TextSelectView.h"
#import "PDFUtils.h"
#import "PDFWord.h"

@implementation TextSelectView {
    NSArray *_words;
    CGSize _pageSize;
    UIColor *_color;
    CGPoint _start;
    CGPoint _end;
}

- (instancetype)initWithWords:(NSArray *)words
                     pageSize:(CGSize)pageSize;
{
    self = [super init];
    if (self) {
        [self setOpaque:NO];
        _words = [words copy];
        _pageSize = pageSize;
        _color = [UIColor colorWithRed:0x25 / 255.0
                                 green:0x72 / 255.0
                                  blue:0xAC / 255.0
                                 alpha:0.5];
        UIPanGestureRecognizer *rec =
            [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(onDrag:)];
        [self addGestureRecognizer:rec];
    }
    return self;
}

- (NSArray *)selectionRects
{
    NSMutableArray *arr = [NSMutableArray array];
    __block CGRect r;

    [PDFWord selectFrom:_start
        to:_end
        fromWords:_words
        onStartLine:^{
            r = CGRectNull;
        }
        onWord:^(PDFWord *w) {
            r = CGRectUnion(r, w.rect);
        }
        onEndLine:^{
            if (!CGRectIsNull(r))
                [arr addObject:[NSValue valueWithCGRect:r]];
        }];

    return arr;
}

- (NSString *)selectedText
{
    NSMutableString *text = [NSMutableString string];
    NSMutableString *line = [NSMutableString string];

    [PDFWord selectFrom:_start
        to:_end
        fromWords:_words
        onStartLine:^{
            line.string = @"";
        }
        onWord:^(PDFWord *w) {
            if (line.length > 0)
                [line appendString:@" "];
            [line appendString:w.text];
        }
        onEndLine:^{
            if (text.length > 0)
                [text appendString:@"\n"];
            [text appendString:line];
        }];

    return text;
}

- (void)onDrag:(UIPanGestureRecognizer *)rec
{
    CGSize scale = [PDFUtils fit:_pageSize to:self.bounds.size];

    CGPoint p = [rec locationInView:self];
    p.x /= scale.width;
    p.y /= scale.height;

    if (rec.state == UIGestureRecognizerStateBegan)
        _start = p;

    _end = p;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGSize scale = [PDFUtils fit:_pageSize to:self.bounds.size];

    CGContextRef cref = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(cref, scale.width, scale.height);
    __block CGRect r;

    [_color set];

    [PDFWord selectFrom:_start
        to:_end
        fromWords:_words
        onStartLine:^{
            r = CGRectNull;
        }
        onWord:^(PDFWord *w) {
            r = CGRectUnion(r, w.rect);
        }
        onEndLine:^{
            if (!CGRectIsNull(r))
                UIRectFill(r);
        }];
}

@end
