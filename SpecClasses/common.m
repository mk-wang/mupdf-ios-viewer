#include "common.h"

fz_context *ctx;
dispatch_queue_t queue;
float screenScale = 1;

CGSize fitPageToScreen(CGSize page, CGSize screen)
{
    float hscale = screen.width / page.width;
    float vscale = screen.height / page.height;
    float scale = fz_min(hscale, vscale);
    hscale = floorf(page.width * scale) / page.width;
    vscale = floorf(page.height * scale) / page.height;
    return CGSizeMake(hscale, vscale);
}

static int hit_count = 0;
static fz_rect hit_bbox[500];

int search_page(fz_document *doc, int number, char *needle, fz_cookie *cookie)
{
    fz_page *page = fz_load_page(ctx, doc, number);
    fz_rect mediabox;
    fz_stext_sheet *sheet = fz_new_stext_sheet(ctx);
    fz_stext_page *text =
        fz_new_stext_page(ctx, fz_bound_page(ctx, page, &mediabox));
    fz_device *dev = fz_new_stext_device(ctx, sheet, text, NULL);
    fz_run_page(ctx, page, dev, &fz_identity, cookie);
    fz_close_device(ctx, dev);
    fz_drop_device(ctx, dev);

    hit_count =
        fz_search_stext_page(ctx, text, needle, hit_bbox, nelem(hit_bbox));

    fz_drop_stext_page(ctx, text);
    fz_drop_stext_sheet(ctx, sheet);
    fz_drop_page(ctx, page);

    return hit_count;
}

fz_rect search_result_bbox(fz_document *doc, int i)
{
    return hit_bbox[i];
}

static void releasePixmap(void *info, const void *data, size_t size)
{
    if (queue)
        dispatch_async(queue, ^{
            fz_drop_pixmap(ctx, info);
        });
    else {
        fz_drop_pixmap(ctx, info);
    }
}

CGDataProviderRef CreateWrappedPixmap(fz_pixmap *pix)
{
    unsigned char *samples = fz_pixmap_samples(ctx, pix);
    int stride = fz_pixmap_stride(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);

    return CGDataProviderCreateWithData(pix, samples, h * stride, releasePixmap);
}

CGImageRef CreateCGImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata)
{
    int w = fz_pixmap_width(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);
    int components = fz_pixmap_components(ctx, pix);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();

    CGBitmapInfo mapInfo = kCGBitmapByteOrderDefault | (components < 4 ? kCGImageAlphaNone : kCGImageAlphaNoneSkipLast);
    CGImageRef cgimage = CGImageCreate(w,
                                       h,
                                       8,
                                       8 * components,
                                       w * components,
                                       space,
                                       mapInfo,
                                       cgdata,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(space);
    return cgimage;
}

fz_context *CreateContext(size_t maxStore)
{
    return fz_new_context(NULL, NULL, maxStore);
}
