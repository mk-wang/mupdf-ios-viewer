#import "MuAnnotation.h"
#import "MuWord.h"
#include "common.h"
#include "mupdf/pdf.h"

#import "MuPageViewNormal.h"

#define STRIKE_HEIGHT (0.375f)
#define UNDERLINE_HEIGHT (0.075f)
#define LINE_THICKNESS (0.07f)
#define INK_THICKNESS (4.0f)

static UIImage *newImageWithPixmap(fz_pixmap *pix, CGDataProviderRef cgdata)
{
    CGImageRef cgimage = CreateCGImageWithPixmap(pix, cgdata);
    UIImage *image = [[UIImage alloc] initWithCGImage:cgimage
                                                scale:screenScale
                                          orientation:UIImageOrientationUp];
    CGImageRelease(cgimage);
    return image;
}

static NSArray *enumerateWidgetRects(fz_document *doc, fz_page *page)
{
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
    fz_annot *annot;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:10];

    for (annot = fz_first_annot(ctx, page); annot;
         annot = fz_next_annot(ctx, annot))
        [arr addObject:[MuAnnotation annotFromAnnot:annot]];

    return [arr retain];
}

static NSArray *enumerateWords(fz_document *doc, fz_page *page)
{
    fz_stext_sheet *sheet = NULL;
    fz_stext_page *text = NULL;
    fz_device *dev = NULL;
    NSMutableArray *lns = [NSMutableArray array];
    NSMutableArray *wds;
    MuWord *word;

    if (!lns)
        return NULL;

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

                word = [MuWord word];
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
                        } else if (word.string.length > 0) {
                            [wds addObject:word];
                            word = [MuWord word];
                            if (!word)
                                fz_throw(ctx, FZ_ERROR_GENERIC, "Failed to create word");
                        }
                    }
                }

                if (word.string.length > 0)
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

static void addMarkupAnnot(fz_document *doc, fz_page *page, int type,
                           NSArray *rects)
{
    pdf_document *idoc;
    float *quadpts = NULL;
    float color[3];
    float alpha;
    float line_height;
    float line_thickness;

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

static fz_pixmap *renderPixmap(fz_document *doc, fz_display_list *page_list,
                               fz_display_list *annot_list, CGSize pageSize,
                               CGSize screenSize, CGRect tileRect, float zoom)
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

    fz_var(dev);
    fz_var(pix);
    fz_try(ctx)
    {
        pix = fz_new_pixmap_with_bbox(ctx, fz_device_rgb(ctx), &bbox, 1);
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
    while (list) {
        rect_list *n = list->next;
        fz_free(ctx, list);
        list = n;
    }
}

static rect_list *updatePage(fz_document *doc, fz_page *page)
{
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

static void updatePixmap(fz_document *doc, fz_display_list *page_list,
                         fz_display_list *annot_list, fz_pixmap *pixmap,
                         rect_list *rlist, CGSize pageSize, CGSize screenSize,
                         CGRect tileRect, float zoom)
{
    fz_irect bbox;
    fz_rect rect;
    fz_matrix ctm;
    fz_device *dev = NULL;
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

@implementation MuPageViewNormal {
    MuDocRef *docRef;
    fz_document *doc;
    fz_page *page;
    fz_display_list *page_list;
    fz_display_list *annot_list;
    int number;
    UIActivityIndicatorView *loadingView;
    fz_pixmap *image_pix;
    CGDataProviderRef imageData;
    UIImageView *imageView;
    fz_pixmap *tile_pix;
    CGDataProviderRef tileData;
    UIImageView *tileView;
    MuHitView *hitView;
    MuHitView *linkView;
    MuTextSelectView *textSelectView;
    MuInkView *inkView;
    MuAnnotSelectView *annotSelectView;
    NSArray *widgetRects;
    NSArray *annotations;
    int selectedAnnotationIndex;
    CGSize pageSize;
    CGRect tileFrame;
    float tileScale;
    BOOL cancel;
    id<MuDialogCreator> dialogCreator;
    id<MuUpdater> updater;
}

- (void)ensurePageLoaded
{
    if (page)
        return;

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
        return;
    }
}

- (void)ensureDisplaylists
{
    [self ensurePageLoaded];
    if (!page)
        return;

    if (!page_list)
        page_list = create_page_list(doc, page);

    if (!annot_list)
        annot_list = create_annot_list(doc, page);
}

- (instancetype)initWithFrame:(CGRect)frame
                dialogCreator:(id<MuDialogCreator>)dia
                      updater:(id<MuUpdater>)upd
                     document:(MuDocRef *)aDoc
                         page:(int)aNumber
{
    self = [super initWithFrame:frame];
    if (self) {
        docRef = [aDoc retain];
        doc = docRef->doc;
        number = aNumber;
        cancel = NO;
        dialogCreator = dia;
        updater = upd;
        selectedAnnotationIndex = -1;

        [self setShowsVerticalScrollIndicator:NO];
        [self setShowsHorizontalScrollIndicator:NO];
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;

        // zoomDidFinish/Begin events fire before bounce animation completes,
        // making a mess when we rearrange views during the animation.
        [self setBouncesZoom:NO];

        [self resetZoomAnimated:NO];

        // TODO: use a one shot timer to delay the display of this?
        loadingView = [[UIActivityIndicatorView alloc]
            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [loadingView startAnimating];
        [self addSubview:loadingView];

        [self loadPage];
    }
    return self;
}

- (void)dealloc
{
    // dealloc can trigger in background thread when the queued block is
    // our last owner, and releases us on completion.
    // Send the dealloc back to the main thread so we don't mess up UIKit.
    if (![NSThread isMainThread]) {
        __block id block_self = self; // don't auto-retain self!
        dispatch_async(dispatch_get_main_queue(), ^{
            [block_self dealloc];
        });
    } else {
        __block fz_display_list *block_page_list = page_list;
        __block fz_display_list *block_annot_list = annot_list;
        __block fz_page *block_page = page;
        //		__block fz_document *block_doc = docRef->doc;
        __block CGDataProviderRef block_tileData = tileData;
        __block CGDataProviderRef block_imageData = imageData;
        dispatch_async(queue, ^{
            fz_drop_display_list(ctx, block_page_list);
            fz_drop_display_list(ctx, block_annot_list);
            fz_drop_page(ctx, block_page);
            block_page = nil;
            CGDataProviderRelease(block_tileData);
            CGDataProviderRelease(block_imageData);
        });
        [docRef release];
        [widgetRects release];
        [linkView release];
        [hitView release];
        [textSelectView release];
        [inkView release];
        [annotSelectView release];
        [tileView release];
        [loadingView release];
        [imageView release];
        [super dealloc];
    }
}

- (int)number
{
    return number;
}

- (void)showLinks
{
    if (!linkView) {
        dispatch_async(queue, ^{
            [self ensurePageLoaded];
            fz_link *links = fz_load_links(ctx, page);
            dispatch_async(dispatch_get_main_queue(), ^{
                linkView = [[MuHitView alloc] initWithLinks:links forDocument:doc];
                dispatch_async(queue, ^{
                    fz_drop_link(ctx, links);
                });
                if (imageView) {
                    linkView.frame = imageView.frame;
                    [linkView setPageSize:pageSize];
                }
                [self addSubview:linkView];
            });
        });
    }
}

- (void)hideLinks
{
    [linkView removeFromSuperview];
    [linkView release];
    linkView = nil;
}

- (void)showSearchResults:(int)count
{
    if (hitView) {
        [hitView removeFromSuperview];
        [hitView release];
        hitView = nil;
    }
    hitView = [[MuHitView alloc] initWithSearchResults:count
                                           forDocument:doc];
    if (imageView) {
        hitView.frame = imageView.frame;
        [hitView setPageSize:pageSize];
    }
    [self addSubview:hitView];
}

- (void)clearSearchResults
{
    if (hitView) {
        [hitView removeFromSuperview];
        [hitView release];
        hitView = nil;
    }
}

- (void)textSelectModeOn
{
    dispatch_async(queue, ^{
        [self ensurePageLoaded];
        NSArray *words = enumerateWords(doc, page);
        dispatch_sync(dispatch_get_main_queue(), ^{
            textSelectView = [[MuTextSelectView alloc] initWithWords:words
                                                            pageSize:pageSize];
            [words release];
            if (imageView)
                textSelectView.frame = imageView.frame;
            [self addSubview:textSelectView];
        });
    });
}

- (void)inkModeOn
{
    inkView = [[MuInkView alloc] initWithPageSize:pageSize];
    if (imageView)
        inkView.frame = imageView.frame;
    [self addSubview:inkView];
}

- (void)textSelectModeOff
{
    [textSelectView removeFromSuperview];
    [textSelectView release];
    textSelectView = nil;
}

- (void)inkModeOff
{
    [inkView removeFromSuperview];
    [inkView release];
    inkView = nil;
}

- (void)saveSelectionAsMarkup:(int)type
{
    NSArray *rects = textSelectView.selectionRects;
    if (rects.count == 0)
        return;

    [rects retain];

    dispatch_async(queue, ^{
        addMarkupAnnot(doc, page, type, rects);
        [rects release];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self update];
        });
        [self loadAnnotations];
    });
    [self textSelectModeOff];
}

- (void)saveInk
{
    NSArray *curves = inkView.curves;
    if (curves.count == 0)
        return;

    [curves retain];

    dispatch_async(queue, ^{
        addInkAnnot(doc, page, curves);
        [curves release];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self update];
        });
        [self loadAnnotations];
    });
    [self inkModeOff];
}

- (void)selectAnnotation:(int)i
{
    selectedAnnotationIndex = i;
    [annotSelectView removeFromSuperview];
    [annotSelectView release];
    annotSelectView = [[MuAnnotSelectView alloc] initWithAnnot:annotations[i]
                                                      pageSize:pageSize];
    [self addSubview:annotSelectView];
}

- (void)deselectAnnotation
{
    selectedAnnotationIndex = -1;
    [annotSelectView removeFromSuperview];
    [annotSelectView release];
    annotSelectView = nil;
}

- (void)deleteSelectedAnnotation
{
    int index = selectedAnnotationIndex;
    if (index >= 0) {
        dispatch_async(queue, ^{
            deleteAnnotation(doc, page, index);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self update];
            });
            [self loadAnnotations];
        });
    }
    [self deselectAnnotation];
}

- (void)resetZoomAnimated:(BOOL)animated
{
    // discard tile and any pending tile jobs
    tileFrame = CGRectZero;
    tileScale = 1;
    if (tileView) {
        [tileView removeFromSuperview];
        [tileView release];
        tileView = nil;
    }

    self.minimumZoomScale = 1;
    self.maximumZoomScale = 5;
    [self setZoomScale:1 animated:animated];
}

- (void)removeFromSuperview
{
    cancel = YES;
    [super removeFromSuperview];
}

- (void)loadAnnotations
{
    if (number < 0 || number >= fz_count_pages(ctx, doc))
        return;

    NSArray *annots = enumerateAnnotations(doc, page);
    dispatch_async(dispatch_get_main_queue(), ^{
        [annotations release];
        annotations = annots;
    });
}

- (void)loadPage
{
    if (number < 0 || number >= fz_count_pages(ctx, doc))
        return;
    dispatch_async(queue, ^{
        if (!cancel) {
            [self renderPage];
        } else {
            printf("cancel page %d\n", number);
        }
    });
}

- (void)renderPage
{
    printf("render page %d\n", number);
    [self ensureDisplaylists];
    CGSize scale = fitPageToScreen(pageSize, self.bounds.size);
    CGRect rect =
        (CGRect){{0.0, 0.0},
                 {pageSize.width * scale.width, pageSize.height * scale.height}};
    image_pix = renderPixmap(doc, page_list, annot_list, pageSize,
                             self.bounds.size, rect, 1.0);
    CGDataProviderRelease(imageData);
    imageData = CreateWrappedPixmap(image_pix);
    UIImage *image = newImageWithPixmap(image_pix, imageData);
    widgetRects = enumerateWidgetRects(doc, page);
    [self loadAnnotations];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayImage:image];
        [image release];
        [imageView setNeedsDisplay];
    });
}

- (void)displayImage:(UIImage *)image
{
    if (loadingView) {
        [loadingView removeFromSuperview];
        [loadingView release];
        loadingView = nil;
    }

    if (hitView)
        [hitView setPageSize:pageSize];

    if (!imageView) {
        imageView = [[UIImageView alloc] initWithImage:image];
        imageView.opaque = YES;
        [self addSubview:imageView];
        if (hitView)
            [self bringSubviewToFront:hitView];
        if (textSelectView)
            [self bringSubviewToFront:textSelectView];
        if (inkView)
            [self bringSubviewToFront:inkView];
        if (annotSelectView)
            [self bringSubviewToFront:annotSelectView];
    } else {
        imageView.image = image;
    }

    [self resizeImage];
}

- (void)resizeImage
{
    if (imageView) {
        CGSize imageSize = imageView.image.size;
        CGSize scale = fitPageToScreen(imageSize, self.bounds.size);
        if (fabs(scale.width - 1) > 0.1) {
            CGRect frame = imageView.frame;
            frame.size.width = imageSize.width * scale.width;
            frame.size.height = imageSize.height * scale.height;
            imageView.frame = frame;

            printf("resized view; queuing up a reload (%d)\n", number);
            dispatch_async(queue, ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    CGSize scale =
                        fitPageToScreen(imageView.image.size, self.bounds.size);
                    if (fabs(scale.width - 1) > 0.01)
                        [self loadPage];
                });
            });
        } else {
            [imageView sizeToFit];
        }

        self.contentSize = imageView.frame.size;

        [self layoutIfNeeded];
    }
}

- (void)willRotate
{
    if (imageView) {
        [self resetZoomAnimated:NO];
        [self resizeImage];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // center the image as it becomes smaller than the size of the screen

    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = loadingView ? loadingView.frame : imageView.frame;

    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x =
            floor((boundsSize.width - frameToCenter.size.width) / 2);
    else
        frameToCenter.origin.x = 0;

    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y =
            floor((boundsSize.height - frameToCenter.size.height) / 2);
    else
        frameToCenter.origin.y = 0;

    if (loadingView)
        loadingView.frame = frameToCenter;
    else
        imageView.frame = frameToCenter;

    if (imageView) {
        CGRect frm = imageView.frame;

        if (hitView)
            hitView.frame = frm;

        if (linkView)
            linkView.frame = frm;

        if (textSelectView)
            textSelectView.frame = frm;

        if (inkView)
            inkView.frame = frm;

        if (annotSelectView)
            annotSelectView.frame = frm;
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}

- (void)loadTile
{
    CGSize screenSize = self.bounds.size;

    tileFrame.origin = self.contentOffset;
    tileFrame.size = self.bounds.size;
    tileFrame = CGRectIntersection(tileFrame, imageView.frame);
    tileScale = self.zoomScale;

    CGRect frame = tileFrame;
    float scale = tileScale;

    CGRect viewFrame = frame;
    // Adjust viewFrame to be relative to imageView's origin
    viewFrame.origin.x -= imageView.frame.origin.x;
    viewFrame.origin.y -= imageView.frame.origin.y;

    if (scale < 1.01)
        return;

    dispatch_async(queue, ^{
        __block BOOL isValid;
        dispatch_sync(dispatch_get_main_queue(), ^{
            isValid = CGRectEqualToRect(frame, tileFrame) && scale == tileScale;
        });
        if (!isValid) {
            printf("cancel tile\n");
            return;
        }

        [self ensureDisplaylists];

        printf("render tile\n");
        tile_pix = renderPixmap(doc, page_list, annot_list, pageSize, screenSize,
                                viewFrame, scale);
        CGDataProviderRelease(tileData);
        tileData = CreateWrappedPixmap(tile_pix);
        UIImage *image = newImageWithPixmap(tile_pix, tileData);

        dispatch_async(dispatch_get_main_queue(), ^{
            isValid = CGRectEqualToRect(frame, tileFrame) && scale == tileScale;
            if (isValid) {
                if (tileView) {
                    [tileView removeFromSuperview];
                    [tileView release];
                    tileView = nil;
                }

                tileView = [[UIImageView alloc] initWithFrame:frame];
                tileView.image = image;
                [self addSubview:tileView];
                if (hitView)
                    [self bringSubviewToFront:hitView];
                if (linkView)
                    [self bringSubviewToFront:linkView];
                if (textSelectView)
                    [self bringSubviewToFront:textSelectView];
                if (inkView)
                    [self bringSubviewToFront:inkView];
                if (annotSelectView)
                    [self bringSubviewToFront:annotSelectView];
            } else {
                printf("discard tile\n");
            }
            [image release];
        });
    });
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self loadTile];
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self loadTile];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadTile];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self loadTile];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView
                          withView:(UIView *)view
{
    // discard tile and any pending tile jobs
    tileFrame = CGRectZero;
    tileScale = 1;
    if (tileView) {
        [tileView removeFromSuperview];
        [tileView release];
        tileView = nil;
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale
{
    [self loadTile];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (imageView) {
        CGRect frm = imageView.frame;

        if (hitView)
            hitView.frame = frm;

        if (textSelectView)
            textSelectView.frame = frm;

        if (inkView)
            inkView.frame = frm;

        if (annotSelectView)
            annotSelectView.frame = frm;
    }
}

- (void)setScale:(float)scale
{
}

- (void)updatePageAndTileWithTileFrame:(CGRect)tframe
                             tileScale:(float)tscale
                             viewFrame:(CGRect)vframe
{
    rect_list *rlist = updatePage(doc, page);
    fz_drop_display_list(ctx, annot_list);
    annot_list = create_annot_list(doc, page);
    if (tile_pix) {
        updatePixmap(doc, page_list, annot_list, tile_pix, rlist, pageSize,
                     self.bounds.size, vframe, tscale);
        UIImage *timage = newImageWithPixmap(tile_pix, tileData);
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isValid =
                CGRectEqualToRect(tframe, tileFrame) && tscale == tileScale;
            if (isValid)
                tileView.image = timage;
            [timage release];
            [tileView setNeedsDisplay];
        });
    }
    drop_list(rlist);

    //  re-render the full-page image
    [self renderPage];
}

- (void)update
{
    CGRect tframe = tileFrame;
    float tscale = tileScale;
    CGRect vframe = tframe;
    vframe.origin.x -= imageView.frame.origin.x;
    vframe.origin.y -= imageView.frame.origin.y;

    dispatch_async(queue, ^{
        [self updatePageAndTileWithTileFrame:tframe
                                   tileScale:tscale
                                   viewFrame:vframe];
    });
}

- (void)invokeTextDialog:(NSString *)text
{
    [dialogCreator invokeTextDialog:text
                         okayAction:^(NSString *newText) {
                             dispatch_async(queue, ^{
                                 BOOL accepted = setFocussedWidgetText(
                                     doc, page, newText.UTF8String);
                                 if (accepted) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [updater update];
                                     });
                                 } else {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [self invokeTextDialog:newText];
                                     });
                                 }
                             });
                         }];
}

- (void)invokeChoiceDialog:(NSArray *)choices
{
    [dialogCreator invokeChoiceDialog:choices
                           okayAction:^(NSArray *selection) {
                               dispatch_async(queue, ^{
                                   BOOL accepted = setFocussedWidgetChoice(
                                       doc, page, [selection[0] UTF8String]);
                                   if (accepted) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [updater update];
                                       });
                                   } else {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self invokeChoiceDialog:choices];
                                       });
                                   }
                               });
                           }];
}

- (int)passTapToPage:(CGPoint)pt
{
    pdf_document *idoc = pdf_specifics(ctx, doc);
    pdf_ui_event event;
    int changed = 0;
    pdf_widget *focus;
    char **opts = NULL;
    char *text = NULL;

    if (!idoc)
        return 0;

    fz_var(opts);
    fz_var(text);
    fz_try(ctx)
    {
        event.etype = PDF_EVENT_TYPE_POINTER;
        event.event.pointer.pt.x = pt.x;
        event.event.pointer.pt.y = pt.y;
        event.event.pointer.ptype = PDF_POINTER_DOWN;
        changed = pdf_pass_event(ctx, idoc, (pdf_page *)page, &event);
        event.event.pointer.ptype = PDF_POINTER_UP;
        changed |= pdf_pass_event(ctx, idoc, (pdf_page *)page, &event);

        focus = pdf_focused_widget(ctx, idoc);
        if (focus) {
            switch (pdf_widget_type(ctx, focus)) {
            case PDF_WIDGET_TYPE_TEXT: {
                text = pdf_text_widget_text(ctx, idoc, focus);
                NSString *stext = [@(text ? text : "") retain];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self invokeTextDialog:stext];
                    [stext release];
                });
                break;
            }

            case PDF_WIDGET_TYPE_LISTBOX:
            case PDF_WIDGET_TYPE_COMBOBOX: {
                int nopts = pdf_choice_widget_options(ctx, idoc, focus, 0, NULL);
                opts = fz_malloc(ctx, nopts * sizeof(*opts));
                (void)pdf_choice_widget_options(ctx, idoc, focus, 0, opts);
                NSMutableArray *arr = [[NSMutableArray arrayWithCapacity:nopts] retain];
                for (int i = 0; i < nopts; i++) {
                    NSString *utf8 = @(opts[i]);
                    // FIXME: temporary patch to handle the library not converting to utf8
                    if (utf8 == nil)
                        utf8 = @(opts[i]);
                    if (utf8 != nil)
                        [arr addObject:utf8];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self invokeChoiceDialog:arr];
                    [arr release];
                });
                break;
            }

            case PDF_WIDGET_TYPE_SIGNATURE:
                break;

            default:
                break;
            }
        }
    }
    fz_always(ctx)
    {
        fz_free(ctx, text);
        fz_free(ctx, opts);
    }
    fz_catch(ctx) {}

    return changed;
}

- (MuTapResult *)handleTap:(CGPoint)pt
{
    CGPoint ipt = [self convertPoint:pt toView:imageView];
    CGSize scale = fitPageToScreen(pageSize, imageView.bounds.size);
    int i;

    ipt.x /= scale.width;
    ipt.y /= scale.height;

    for (i = 0; i < annotations.count; i++) {
        MuAnnotation *annot = annotations[i];
        if (annot.type != PDF_ANNOT_WIDGET &&
            CGRectContainsPoint(annot.rect, ipt)) {
            [self selectAnnotation:i];
            return [[[MuTapResultAnnotation alloc] initWithAnnotation:annot]
                autorelease];
        }
    }

    [self deselectAnnotation];

    for (i = 0; i < widgetRects.count; i++) {
        CGRect r = [widgetRects[i] CGRectValue];
        if (CGRectContainsPoint(r, ipt)) {
            dispatch_async(queue, ^{
                int changed = [self passTapToPage:ipt];
                if (changed)
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self update];
                    });
            });
            return [[[MuTapResultWidget alloc] init] autorelease];
        }
    }

    if (linkView) {
        CGPoint lpt = [self convertPoint:pt toView:linkView];
        return [linkView handleTap:lpt];
    }

    return nil;
}

@end
