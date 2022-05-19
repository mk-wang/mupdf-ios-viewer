//
//  PDFUtils.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFUtils.h"
#import "PDFAnnotation_Private.h"
#import "PDFCommon.h"
#import "PDFContext.h"
#import "PDFDoc_Private.h"

#define STRIKE_HEIGHT (0.375f)
#define UNDERLINE_HEIGHT (0.075f)
#define LINE_THICKNESS (0.07f)
#define INK_THICKNESS (4.0f)

static CGSize fitPageToScreen(CGSize page, CGSize screen)
{
    CGFloat scale = fz_min(screen.width / page.width, screen.height / page.height);
    CGFloat width = floorf(page.width * scale) / page.width;
    CGFloat height = floorf(page.height * scale) / page.height;
    return CGSizeMake(width, height);
}

int search_page(fz_document *doc, int number, char *needle, fz_cookie *cookie)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;
    fz_rect hit_bbox[500];

    fz_page *page = fz_load_page(ctx, doc, number);
    fz_rect mediabox;
    fz_stext_sheet *sheet = fz_new_stext_sheet(ctx);
    fz_stext_page *text =
        fz_new_stext_page(ctx, fz_bound_page(ctx, page, &mediabox));
    fz_device *dev = fz_new_stext_device(ctx, sheet, text, NULL);
    fz_run_page(ctx, page, dev, &fz_identity, cookie);
    fz_close_device(ctx, dev);
    fz_drop_device(ctx, dev);

    int hit_count = fz_search_stext_page(ctx, text, needle, hit_bbox, nelem(hit_bbox));

    fz_drop_stext_page(ctx, text);
    fz_drop_stext_sheet(ctx, sheet);
    fz_drop_page(ctx, page);

    return hit_count;
}

static void releasePixmap(void *info, const void *data, size_t size)
{
    PDFContext *pCtx = PDFContext.sharedContext;
    fz_context *ctx = pCtx.ctx;
    dispatch_queue_t queue = pCtx.queue;

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
    fz_context *ctx = PDFContext.sharedContext.ctx;

    unsigned char *samples = fz_pixmap_samples(ctx, pix);
    int stride = fz_pixmap_stride(ctx, pix);
    int h = fz_pixmap_height(ctx, pix);

    return CGDataProviderCreateWithData(pix, samples, h * stride, releasePixmap);
}

CGImageRef CreateCGImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

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

static UIImage *newImageWithPixmap(fz_pixmap *pix,
                                   CGFloat scale)
{
    CGDataProviderRef imageData = CreateWrappedPixmap(pix);

    CGImageRef cgimage = CreateCGImageWithPixmap(pix, imageData);
    CGDataProviderRelease(imageData);

    UIImage *image = [[UIImage alloc] initWithCGImage:cgimage
                                                scale:scale
                                          orientation:UIImageOrientationUp];
    CGImageRelease(cgimage);

    return image;
}

static NSArray *enumerateWidgetRects(fz_document *doc, fz_page *page)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    pdf_document *idoc = pdf_specifics(ctx, doc);
    pdf_widget *widget;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10];

    if (!idoc)
        return nil;

    for (widget = pdf_first_widget(ctx, idoc, (pdf_page *)page); widget;
         widget = pdf_next_widget(ctx, widget)) {
        fz_rect rect;

        pdf_bound_widget(ctx, widget, &rect);
        [arr addObject:[NSValue valueWithCGRect:CGRectMake(rect.x0, rect.y0,
                                                           rect.x1 - rect.x0,
                                                           rect.y1 - rect.y0)]];
    }

    return [arr retain];
}

static NSArray *enumerateAnnotations(fz_document *doc, fz_page *page)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    fz_annot *annot;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10];

    for (annot = fz_first_annot(ctx, page); annot; annot = fz_next_annot(ctx, annot)) {
        [arr addObject:[PDFAnnotation annotFromAnnot:annot]];
    }

    return arr;
}

static NSArray *enumerateWords(fz_document *doc, fz_page *page)
{
    fz_stext_sheet *sheet = NULL;
    fz_stext_page *text = NULL;
    fz_device *dev = NULL;
    NSMutableArray *lns = [NSMutableArray array];
    NSMutableArray *wds;
    PDFWord *word;

    if (!lns)
        return NULL;

    fz_context *ctx = PDFContext.sharedContext.ctx;

    fz_var(sheet);
    fz_var(text);
    fz_var(dev);

    fz_try(ctx)
    {
        fz_rect mediabox;
        int b, l, c;

        sheet = fz_new_stext_sheet(ctx);
        text = fz_new_stext_page(ctx, fz_bound_page(ctx, page, &mediabox));
        dev = fz_new_stext_device(ctx, sheet, text, NULL);
        fz_run_page(ctx, page, dev, &fz_identity, NULL);
        fz_close_device(ctx, dev);
        fz_drop_device(ctx, dev);
        dev = NULL;

        for (b = 0; b < text->len; b++) {
            fz_stext_block *block;

            if (text->blocks[b].type != FZ_PAGE_BLOCK_TEXT)
                continue;

            block = text->blocks[b].u.text;

            for (l = 0; l < block->len; l++) {
                fz_stext_line *line = &block->lines[l];
                fz_stext_span *span;

                wds = [NSMutableArray array];
                if (!wds)
                    fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word array");

                word = [PDFWord word];
                if (!word)
                    fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word");

                for (span = line->first_span; span; span = span->next) {
                    for (c = 0; c < span->len; c++) {
                        fz_stext_char *ch = &span->text[c];
                        fz_rect bbox;
                        CGRect rect;

                        fz_stext_char_bbox(ctx, &bbox, span, c);
                        rect = CGRectMake(bbox.x0, bbox.y0, bbox.x1 - bbox.x0,
                                          bbox.y1 - bbox.y0);

                        if (ch->c != ' ') {
                            [word appendChar:ch->c withRect:rect];
                        } else if (word.text.length > 0) {
                            [wds addObject:word];
                            word = [PDFWord word];
                            if (!word)
                                fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word");
                        }
                    }
                }

                if (word.text.length > 0)
                    [wds addObject:word];

                if (wds.count > 0)
                    [lns addObject:wds];
            }
        }
        fz_close_device(ctx, dev);
    }
    fz_always(ctx)
    {
        fz_drop_stext_page(ctx, text);
        fz_drop_stext_sheet(ctx, sheet);
        fz_drop_device(ctx, dev);
    }
    fz_catch(ctx)
    {
        lns = NULL;
    }

    return [lns retain];
}

static void addMarkupAnnot(fz_document *doc, fz_page *page, int type, NSArray *rects)
{
    pdf_document *idoc;
    float *quadpts = NULL;
    float color[3];
    float alpha;
    float line_height;
    float line_thickness;

    fz_context *ctx = PDFContext.sharedContext.ctx;

    idoc = pdf_specifics(ctx, doc);
    if (!idoc)
        return;

    switch (type) {
    case PDF_ANNOT_HIGHLIGHT:
        color[0] = 1.0;
        color[1] = 1.0;
        color[2] = 0.0;
        alpha = 0.5;
        line_thickness = 1.0;
        line_height = 0.5;
        break;
    case PDF_ANNOT_UNDERLINE:
        color[0] = 0.0;
        color[1] = 0.0;
        color[2] = 1.0;
        alpha = 1.0;
        line_thickness = LINE_THICKNESS;
        line_height = UNDERLINE_HEIGHT;
        break;
    case PDF_ANNOT_STRIKE_OUT:
        color[0] = 1.0;
        color[1] = 0.0;
        color[2] = 0.0;
        alpha = 1.0;
        line_thickness = LINE_THICKNESS;
        line_height = STRIKE_HEIGHT;
        break;

    default:
        return;
    }

    fz_var(quadpts);
    fz_try(ctx)
    {
        int i;
        pdf_annot *annot;

        quadpts = fz_malloc_array(ctx, (int)rects.count * 8, sizeof(float));
        for (i = 0; i < rects.count; i++) {
            CGRect rect = [rects[i] CGRectValue];
            float top = rect.origin.y;
            float bot = top + rect.size.height;
            float left = rect.origin.x;
            float right = left + rect.size.width;
            quadpts[i * 8 + 0] = left;
            quadpts[i * 8 + 1] = bot;
            quadpts[i * 8 + 2] = right;
            quadpts[i * 8 + 3] = bot;
            quadpts[i * 8 + 4] = right;
            quadpts[i * 8 + 5] = top;
            quadpts[i * 8 + 6] = left;
            quadpts[i * 8 + 7] = top;
        }

        annot = pdf_create_annot(ctx, (pdf_page *)page, type);
        pdf_set_annot_quad_points(ctx, annot, (int)rects.count, quadpts);
        pdf_set_markup_appearance(ctx, idoc, annot, color, alpha, line_thickness,
                                  line_height);
    }
    fz_always(ctx)
    {
        fz_free(ctx, quadpts);
    }
    fz_catch(ctx)
    {
        printf("Annotation creation failed\n");
    }
}

static void addInkAnnot(fz_document *doc, fz_page *page, NSArray *curves)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    pdf_document *idoc;
    float *pts = NULL;
    int *counts = NULL;
    int total;
    float color[4] = {1.0, 0.0, 0.0, 0.0};

    idoc = pdf_specifics(ctx, doc);
    if (!idoc)
        return;

    fz_var(pts);
    fz_var(counts);
    fz_try(ctx)
    {
        int i, j, k, n;
        pdf_annot *annot;

        n = (int)curves.count;

        counts = fz_malloc_array(ctx, n, sizeof(int));
        total = 0;

        for (i = 0; i < n; i++) {
            NSArray *curve = curves[i];
            counts[i] = (int)curve.count;
            total += (int)curve.count;
        }

        pts = fz_malloc_array(ctx, total * 2, sizeof(float));

        k = 0;
        for (i = 0; i < n; i++) {
            NSArray *curve = curves[i];
            int count = counts[i];

            for (j = 0; j < count; j++) {
                CGPoint pt = [curve[j] CGPointValue];
                pts[k++] = pt.x;
                pts[k++] = pt.y;
            }
        }

        annot = pdf_create_annot(ctx, (pdf_page *)page, PDF_ANNOT_INK);

        pdf_set_annot_border(ctx, annot, INK_THICKNESS);
        pdf_set_annot_color(ctx, annot, 3, color);
        pdf_set_annot_ink_list(ctx, annot, n, counts, pts);
    }
    fz_always(ctx)
    {
        fz_free(ctx, pts);
        fz_free(ctx, counts);
    }
    fz_catch(ctx)
    {
        printf("Annotation creation failed\n");
    }
}

static void deleteAnnotation(fz_document *doc, fz_page *page, int index)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;
    pdf_document *idoc = pdf_specifics(ctx, doc);

    if (!idoc)
        return;

    fz_try(ctx)
    {
        int i;
        fz_annot *annot = fz_first_annot(ctx, page);
        for (i = 0; i < index && annot; i++)
            annot = fz_next_annot(ctx, annot);

        if (annot)
            pdf_delete_annot(ctx, (pdf_page *)page, (pdf_annot *)annot);
    }
    fz_catch(ctx)
    {
        printf("Annotation deletion failed\n");
    }
}

static int setFocussedWidgetText(fz_document *doc, fz_page *page,
                                 const char *text)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;
    int accepted = 0;
    fz_var(accepted);

    fz_try(ctx)
    {
        pdf_document *idoc = pdf_specifics(ctx, doc);
        if (idoc) {
            pdf_widget *focus = pdf_focused_widget(ctx, idoc);
            if (focus) {
                accepted = pdf_text_widget_set_text(ctx, idoc, focus, (char *)text);
            }
        }
    }
    fz_catch(ctx)
    {
        accepted = 0;
    }

    return accepted;
}

static int setFocussedWidgetChoice(fz_document *doc, fz_page *page,
                                   const char *text)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;
    int accepted = 0;
    fz_var(accepted);

    fz_try(ctx)
    {
        pdf_document *idoc = pdf_specifics(ctx, doc);
        if (idoc) {
            pdf_widget *focus = pdf_focused_widget(ctx, idoc);
            if (focus) {
                pdf_choice_widget_set_value(ctx, idoc, focus, 1, (char **)&text);
                accepted = 1;
            }
        }
    }
    fz_catch(ctx)
    {
        accepted = 0;
    }

    return accepted;
}

static fz_display_list *create_page_list(fz_document *doc, fz_page *page)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    fz_display_list *list = NULL;

    fz_device *dev = NULL;

    fz_var(dev);
    fz_try(ctx)
    {
        list = fz_new_display_list(ctx, NULL);
        dev = fz_new_list_device(ctx, list);
        fz_run_page_contents(ctx, page, dev, &fz_identity, NULL);
        fz_close_device(ctx, dev);
    }
    fz_always(ctx)
    {
        fz_drop_device(ctx, dev);
    }
    fz_catch(ctx)
    {
        return NULL;
    }

    return list;
}

static fz_display_list *create_annot_list(fz_document *doc, fz_page *page)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    fz_display_list *list = NULL;
    fz_device *dev = NULL;

    fz_var(dev);
    fz_try(ctx)
    {
        fz_annot *annot;
        pdf_document *idoc = pdf_specifics(ctx, doc);

        if (idoc)
            pdf_update_page(ctx, (pdf_page *)page);
        list = fz_new_display_list(ctx, NULL);
        dev = fz_new_list_device(ctx, list);
        for (annot = fz_first_annot(ctx, page); annot;
             annot = fz_next_annot(ctx, annot))
            fz_run_annot(ctx, annot, dev, &fz_identity, NULL);
        fz_close_device(ctx, dev);
    }
    fz_always(ctx)
    {
        fz_drop_device(ctx, dev);
    }
    fz_catch(ctx)
    {
        return NULL;
    }

    return list;
}

static fz_pixmap *renderPixmap(fz_document *doc,
                               fz_display_list *page_list,
                               fz_display_list *annot_list,
                               CGSize pageSize,
                               CGSize screenSize,
                               CGFloat screenScale,
                               CGRect tileRect,
                               float zoom,
                               BOOL alpha)
{
    fz_irect bbox;
    fz_rect rect;
    fz_matrix ctm;
    fz_device *dev = NULL;
    fz_pixmap *pix = NULL;
    CGSize scale;

    screenSize.width *= screenScale;
    screenSize.height *= screenScale;
    tileRect.origin.x *= screenScale;
    tileRect.origin.y *= screenScale;
    tileRect.size.width *= screenScale;
    tileRect.size.height *= screenScale;

    scale = fitPageToScreen(pageSize, screenSize);
    fz_scale(&ctm, scale.width * zoom, scale.height * zoom);

    bbox.x0 = tileRect.origin.x;
    bbox.y0 = tileRect.origin.y;
    bbox.x1 = tileRect.origin.x + tileRect.size.width;
    bbox.y1 = tileRect.origin.y + tileRect.size.height;
    fz_rect_from_irect(&rect, &bbox);

    fz_context *ctx = PDFContext.sharedContext.ctx;

    fz_var(dev);
    fz_var(pix);
    fz_try(ctx)
    {
        pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), &bbox, alpha ? 1 : 0);
        fz_clear_pixmap_with_value(ctx, pix, 255);

        dev = fz_new_draw_device(ctx, NULL, pix);
        fz_run_display_list(ctx, page_list, dev, &ctm, &rect, NULL);
        fz_run_display_list(ctx, annot_list, dev, &ctm, &rect, NULL);

        fz_close_device(ctx, dev);
    }
    fz_always(ctx)
    {
        fz_drop_device(ctx, dev);
    }
    fz_catch(ctx)
    {
        fz_drop_pixmap(ctx, pix);
        return NULL;
    }

    return pix;
}

typedef struct rect_list_s rect_list;

struct rect_list_s
{
    fz_rect rect;
    rect_list *next;
};

static void drop_list(rect_list *list)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    while (list) {
        rect_list *n = list->next;
        fz_free(ctx, list);
        list = n;
    }
}

static rect_list *updatePage(fz_document *doc, fz_page *page)
{
    fz_context *ctx = PDFContext.sharedContext.ctx;

    rect_list *list = NULL;

    fz_var(list);
    fz_try(ctx)
    {
        pdf_document *idoc = pdf_specifics(ctx, doc);
        if (idoc) {
            pdf_page *ppage = (pdf_page *)page;
            pdf_annot *pannot;

            pdf_update_page(ctx, (pdf_page *)page);
            for (pannot = pdf_first_annot(ctx, ppage); pannot;
                 pannot = pdf_next_annot(ctx, pannot)) {
                if (pannot->changed) {
                    rect_list *node = fz_malloc_struct(ctx, rect_list);
                    fz_bound_annot(ctx, (fz_annot *)pannot, &node->rect);
                    node->next = list;
                    list = node;
                }
            }
        }
    }
    fz_catch(ctx)
    {
        drop_list(list);
        list = NULL;
    }

    return list;
}

static void updatePixmap(
    fz_document *doc,
    fz_display_list *page_list,
    fz_display_list *annot_list,
    fz_pixmap *pixmap,
    rect_list *rlist,
    CGSize pageSize,
    CGSize screenSize,
    CGFloat screenScale,
    CGRect tileRect,
    float zoom)
{
    fz_irect bbox;
    fz_rect rect;
    fz_matrix ctm;
    fz_device *dev = NULL;
    CGSize scale;

    fz_context *ctx = PDFContext.sharedContext.ctx;

    screenSize.width *= screenScale;
    screenSize.height *= screenScale;
    tileRect.origin.x *= screenScale;
    tileRect.origin.y *= screenScale;
    tileRect.size.width *= screenScale;
    tileRect.size.height *= screenScale;

    scale = fitPageToScreen(pageSize, screenSize);
    fz_scale(&ctm, scale.width * zoom, scale.height * zoom);

    bbox.x0 = tileRect.origin.x;
    bbox.y0 = tileRect.origin.y;
    bbox.x1 = tileRect.origin.x + tileRect.size.width;
    bbox.y1 = tileRect.origin.y + tileRect.size.height;
    fz_rect_from_irect(&rect, &bbox);

    fz_var(dev);
    fz_try(ctx)
    {
        while (rlist) {
            fz_irect abox;
            fz_rect arect = rlist->rect;
            fz_transform_rect(&arect, &ctm);
            fz_intersect_rect(&arect, &rect);
            fz_round_rect(&abox, &arect);
            if (!fz_is_empty_irect(&abox)) {
                fz_clear_pixmap_rect_with_value(ctx, pixmap, 255, &abox);
                dev = fz_new_draw_device_with_bbox(ctx, NULL, pixmap, &abox);
                fz_run_display_list(ctx, page_list, dev, &ctm, &arect, NULL);
                fz_run_display_list(ctx, annot_list, dev, &ctm, &arect, NULL);

                fz_close_device(ctx, dev);
                fz_drop_device(ctx, dev);
                dev = NULL;
            }
            rlist = rlist->next;
        }
    }
    fz_always(ctx)
    {
        fz_drop_device(ctx, dev);
    }
    fz_catch(ctx) {}
}

@implementation PDFUtils

+ (CGSize)fit:(CGSize)page to:(CGSize)screen
{
    return fitPageToScreen(page, screen);
}

+ (nullable UIImage *)renderPage:(PDFDoc *)pDoc
                      boundsSize:(CGSize)boundsSize
                     screenScale:(CGFloat)screenScale
                          number:(NSInteger)number
{
    fz_page *page = NULL;
    fz_context *ctx = PDFContext.sharedContext.ctx;
    fz_document *doc = pDoc.doc;

    CGSize pageSize = CGSizeZero;
    fz_try(ctx)
    {
        fz_rect bounds;
        page = fz_load_page(ctx, doc, number);
        fz_bound_page(ctx, page, &bounds);
        pageSize.width = bounds.x1 - bounds.x0;
        pageSize.height = bounds.y1 - bounds.y0;
    }
    fz_catch(ctx)
    {
        return nil;
    }

    CGSize scale = fitPageToScreen(pageSize, boundsSize);
    CGRect rect = CGRectZero;
    rect.size = CGSizeMake(pageSize.width * scale.width, pageSize.height * scale.height);

    fz_display_list *page_list = create_page_list(doc, page);
    fz_display_list *annot_list = create_annot_list(doc, page);

    fz_pixmap *image_pix = renderPixmap(doc,
                                        page_list,
                                        annot_list,
                                        pageSize,
                                        boundsSize,
                                        screenScale,
                                        rect,
                                        1.0,
                                        NO);
    if (image_pix == NULL) {
        return nil;
    }

    UIImage *image = newImageWithPixmap(image_pix, screenScale);

    if (page_list != NULL) {
        fz_drop_display_list(ctx, page_list);
    }

    if (annot_list != NULL) {
        fz_drop_display_list(ctx, annot_list);
    }

    return image;
}

@end
