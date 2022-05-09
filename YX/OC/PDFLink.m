//
//  PDFLink.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFLink.h"
#import "Common.h"

@implementation PDFLink

+ (NSArray<PDFLink *> *)linksFromHeader:(void *)header
{
    NSMutableArray *list = [NSMutableArray new];

    fz_link *link = (fz_link *)header;
    while (link != NULL) {
        PDFLink *pLink = [[self alloc] initWithLink:link];
        if (pLink == NULL) {
            break;
        }
        [list addObject:pLink];
        link = link->next;
    }

    return list;
}

- (instancetype)initWithLink:(void *)vlink
{
    fz_link *link = (fz_link *)vlink;

    NSAssert(link != NULL && link->uri != NULL, @"need a valid link: uri is null");
    NSAssert(link != NULL && link->doc != NULL, @"need a valid link: doc is null");

    if (link == NULL || link->uri == NULL || link->doc == NULL) {
        return nil;
    }

    self = [super init];

    if (self) {

        fz_rect bbox = link->rect;
        _rect.origin.x = bbox.x0;
        _rect.origin.y = bbox.y0;
        _rect.size.width = bbox.x1 - bbox.x0;
        _rect.size.height = bbox.y1 - bbox.y0;
        if (link->uri != NULL) {
            if (fz_is_external_link(ctx, link->uri)) {
                _number = -1;
                _url = [[NSString alloc] initWithUTF8String:link->uri];
            } else {
                _number = fz_resolve_link(ctx, link->doc, link->uri, NULL, NULL);
                _url = nil;
            }
        } else {
            _number = -1;
        }
    }

    return self;
}

@end
