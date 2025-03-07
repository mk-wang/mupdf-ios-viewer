#import "MuPageViewReflow.h"
#include "common.h"

NSString *textAsHtml(fz_document *doc, int pageNum)
{
    NSString *str = nil;
    fz_page *page = NULL;
    fz_stext_sheet *sheet = NULL;
    fz_stext_page *text = NULL;
    fz_device *dev = NULL;
    fz_matrix ctm;
    fz_buffer *buf = NULL;
    fz_output *out = NULL;
    fz_rect mediabox;
    size_t len;
    unsigned char *data;

    fz_var(page);
    fz_var(sheet);
    fz_var(text);
    fz_var(dev);
    fz_var(buf);
    fz_var(out);

    fz_try(ctx)
    {
        ctm = fz_identity;
        sheet = fz_new_stext_sheet(ctx);
        text = fz_new_stext_page(ctx, fz_bound_page(ctx, page, &mediabox));
        dev = fz_new_stext_device(ctx, sheet, text, NULL);
        page = fz_load_page(ctx, doc, pageNum);
        fz_run_page(ctx, page, dev, &ctm, NULL);
        fz_close_device(ctx, dev);
        fz_drop_device(ctx, dev);
        dev = NULL;

        fz_analyze_text(ctx, sheet, text);

        buf = fz_new_buffer(ctx, 256);
        out = fz_new_output_with_buffer(ctx, buf);
        fz_write_printf(ctx, out, "<html>\n");
        fz_write_printf(ctx, out, "<style>\n");
        fz_write_printf(ctx, out, "body{margin:0;}\n");
        fz_write_printf(ctx, out, "div.page{background-color:white;}\n");
        fz_write_printf(ctx, out, "div.block{margin:0pt;padding:0pt;}\n");
        fz_write_printf(ctx, out, "div.metaline{display:table;width:100%%}\n");
        fz_write_printf(ctx, out, "div.line{display:table-row;}\n");
        fz_write_printf(ctx, out,
                        "div.cell{display:table-cell;padding-left:0.25em;padding-"
                        "right:0.25em}\n");
        // fz_write_printf(ctx, out, "p{margin:0;padding:0;}\n");
        fz_write_printf(ctx, out, "</style>\n");
        fz_write_printf(
            ctx, out,
            "<body style=\"margin:0\"><div style=\"padding:10px\" id=\"content\">");
        fz_print_stext_page_html(ctx, out, text);
        fz_write_printf(ctx, out, "</div></body>\n");
        fz_write_printf(ctx, out, "<style>\n");
        fz_print_stext_sheet(ctx, out, sheet);
        fz_write_printf(ctx, out, "</style>\n</html>\n");

        out = NULL;

        len = fz_buffer_storage(ctx, buf, &data);
        str = [[[NSString alloc] initWithBytes:data
                                        length:len
                                      encoding:NSUTF8StringEncoding] autorelease];
    }
    fz_always(ctx)
    {
        fz_drop_stext_page(ctx, text);
        fz_drop_stext_sheet(ctx, sheet);
        fz_drop_device(ctx, dev);
        fz_drop_output(ctx, out);
        fz_drop_buffer(ctx, buf);
        fz_drop_page(ctx, page);
    }
    fz_catch(ctx)
    {
        str = nil;
    }

    return str;
}

@implementation MuPageViewReflow {
    int number;
    float scale;
}

- (instancetype)initWithFrame:(CGRect)frame
                     document:(MuDocRef *)aDoc
                         page:(int)aNumber
{
    self = [super initWithFrame:frame];
    if (self) {
        number = aNumber;
        scale = 1.0;
        self.scalesPageToFit = NO;
        self.delegate = self;
        dispatch_async(queue, ^{
            __block NSString *cont = [textAsHtml(aDoc->doc, aNumber) retain];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadHTMLString:cont baseURL:nil];
            });
        });
    }
    return self;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self
        stringByEvaluatingJavaScriptFromString:
            [NSString stringWithFormat:
                          @"document.getElementById('content').style.zoom=\"%f\"",
                          scale]];
}

- (void)dealloc
{
    [self setDelegate:nil];
    [super dealloc];
}

- (int)number
{
    return number;
}

- (void)willRotate
{
}
- (void)showLinks
{
}
- (void)hideLinks
{
}
- (void)showSearchResults:(int)count
{
}
- (void)clearSearchResults
{
}
- (void)textSelectModeOn
{
}
- (void)textSelectModeOff
{
}
- (void)inkModeOn
{
}
- (void)inkModeOff
{
}
- (void)saveSelectionAsMarkup:(int)type
{
}
- (void)saveInk
{
}
- (void)deselectAnnotation
{
}
- (void)deleteSelectedAnnotation
{
}
- (void)update
{
}

- (void)resetZoomAnimated:(BOOL)animated
{
    [self.scrollView setContentOffset:CGPointZero animated:NO];
}

- (void)setScale:(float)aFloat
{
    scale = aFloat;
    [self
        stringByEvaluatingJavaScriptFromString:
            [NSString stringWithFormat:
                          @"document.getElementById('content').style.zoom=\"%f\"",
                          scale]];
}

- (MuTapResult *)handleTap:(CGPoint)pt
{
    return nil;
}

@end
