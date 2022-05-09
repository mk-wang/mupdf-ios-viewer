//
//  HitView.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "HitView.h"
#import "Common.h"
#import "PDFDoc.h"
#import "PDFLink.h"
#import "PDFUtils.h"
#import "TapResult.h"

@implementation HitView {
    PDFDoc *_doc;
    NSArray<PDFLink *> *_links;
}

- (instancetype)initWithFrame:(CGRect)frame
                        links:(NSArray<PDFLink *> *)links
                     document:(PDFDoc *)doc
               highlightColor:(UIColor *)color
{
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:links.count];

    for (PDFLink *link in links) {
        [list addObject:[NSValue valueWithCGRect:link.rect]];
    }
    self = [super initWithFrame:frame
                       rectList:list
                 highlightColor:color];
    if (self != nil) {
        _doc = doc;
    }

    return self;
}

- (nullable TapResult *)handleTap:(CGPoint)pt
{
    CGSize scale = [PDFUtils fit:self.pageSize to:self.bounds.size];

    pt.x /= scale.width;
    pt.y /= scale.height;

    for (PDFLink *link in _links) {
        if (CGRectContainsPoint(link.rect, pt)) {
            if (link.number >= 0) {
                return [[TapResultInternalLink alloc] initWithPageNumber:link.number];
            } else if (link.url.length > 0) {
                return [[TapResultExternalLink alloc] initWithUrl:link.url];
            }
        }
    }

    return nil;
}

@end
