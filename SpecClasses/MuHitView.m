#import "MuHitView.h"
#import "common.h"

@implementation MuHitView {
    CGSize pageSize;
    int hitCount;
    CGRect hitRects[500];
    int linkPage[500];
    char *linkUrl[500];
    UIColor *color;
}

- (instancetype)initWithSearchResults:(int)n
                          forDocument:(fz_document *)doc
{
    self = [super initWithFrame:CGRectMake(0, 0, 100, 100)];
    if (self) {
        [self setOpaque:NO];

        color = [[UIColor colorWithRed:0x25 / 255.0
                                 green:0x72 / 255.0
                                  blue:0xAC / 255.0
                                 alpha:0.5] retain];

        pageSize = CGSizeZero;

        for (int i = 0; i < n && i < nelem(hitRects); i++) {
            fz_rect bbox = search_result_bbox(doc, i); // this is thread-safe enough
            hitRects[i].origin.x = bbox.x0;
            hitRects[i].origin.y = bbox.y0;
            hitRects[i].size.width = bbox.x1 - bbox.x0;
            hitRects[i].size.height = bbox.y1 - bbox.y0;
        }
        hitCount = n;
    }
    return self;
}

- (instancetype)initWithLinks:(fz_link *)link forDocument:(fz_document *)doc
{
    self = [super initWithFrame:CGRectMake(0, 0, 100, 100)];
    if (self) {
        [self setOpaque:NO];

        color = [[UIColor colorWithRed:0xAC / 255.0
                                 green:0x72 / 255.0
                                  blue:0x25 / 255.0
                                 alpha:0.5] retain];

        pageSize = CGSizeMake(100, 100);

        while (link && hitCount < nelem(hitRects)) {
            if (link->uri) {
                fz_rect bbox = link->rect;
                hitRects[hitCount].origin.x = bbox.x0;
                hitRects[hitCount].origin.y = bbox.y0;
                hitRects[hitCount].size.width = bbox.x1 - bbox.x0;
                hitRects[hitCount].size.height = bbox.y1 - bbox.y0;
                if (fz_is_external_link(ctx, link->uri)) {
                    linkPage[hitCount] = -1;
                    linkUrl[hitCount] = strdup(link->uri);
                } else {
                    linkPage[hitCount] = fz_resolve_link(ctx, doc, link->uri, NULL, NULL);
                    linkUrl[hitCount] = nil;
                }
                hitCount++;
            }
            link = link->next;
        }
    }
    return self;
}

- (void)setPageSize:(CGSize)s
{
    pageSize = s;
    // if page takes a long time to load we may have drawn at the initial (wrong)
    // size
    [self setNeedsDisplay];
}

- (MuTapResult *)handleTap:(CGPoint)pt
{
    CGSize scale = fitPageToScreen(pageSize, self.bounds.size);
    pt.x /= scale.width;
    pt.y /= scale.height;

    for (int i = 0; i < hitCount; i++) {
        if (CGRectContainsPoint(hitRects[i], pt)) {
            if (linkPage[i] >= 0) {
                return [[[MuTapResultInternalLink alloc] initWithPageNumber:linkPage[i]]
                    autorelease];
            }
            if (linkUrl[i]) {
                NSString *url = @(linkUrl[i]);
                return [[[MuTapResultExternalLink alloc] initWithUrl:url] autorelease];
            }
        }
    }

    return nil;
}

- (void)drawRect:(CGRect)r
{
    CGSize scale = fitPageToScreen(pageSize, self.bounds.size);

    [color set];

    for (int i = 0; i < hitCount; i++) {
        CGRect rect = hitRects[i];
        rect.origin.x *= scale.width;
        rect.origin.y *= scale.height;
        rect.size.width *= scale.width;
        rect.size.height *= scale.height;
        UIRectFill(rect);
    }
}

- (void)dealloc
{
    int i;
    [color release];
    for (i = 0; i < hitCount; i++)
        free(linkUrl[i]);
    [super dealloc];
}

@end
