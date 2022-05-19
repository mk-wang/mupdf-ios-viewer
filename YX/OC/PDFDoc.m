//
//  PDFDoc.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFDoc.h"
#import "PDFContext.h"
#import "PDFDoc_Private.h"

@implementation PDFDoc

- (instancetype)initWithPath:(NSString *)path
{
    
    self = [super init];
    if (self) {
        _path = path.copy;
    }
    return self;
}

- (void)open
{
    PDFContext *context = PDFContext.sharedContext;
    
    dispatch_sync(context.queue, ^{
    });
    
    fz_var(self);
    
    fz_context *ctx = context.ctx;
    fz_try(ctx)
    {
        _doc = fz_open_document(ctx, _path.UTF8String);
        
        if (_doc != NULL) {
            pdf_document *pdfDoc = pdf_specifics(ctx, _doc);
            if (pdfDoc != NULL) {
                pdf_enable_js(ctx, pdfDoc);
                _interactive = (pdf_crypt_version(ctx, pdfDoc) == 0);
            }
        }
    }
    fz_catch(ctx)
    {
        if (_doc != NULL) {
            fz_drop_document(ctx, _doc);
        }
    }
}

- (fz_context *)ctx {
    return PDFContext.sharedContext.ctx;
}

- (void)close
{
    // use serial thread to check _doc
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_doc != NULL) {
            PDFContext *context = PDFContext.sharedContext;
            fz_document *doc = _doc;
            dispatch_async(context.queue, ^{
                fz_drop_document(context.ctx, doc);
            });
            _doc = NULL;
        }
    });
}

- (BOOL)needPassword {
    return fz_needs_password(self.ctx, self.doc) != 0;
}

- (void)setPassword:(nullable NSString *)text {
    if (text.length == 0) {
    }
}

- (void)dealloc
{
    [self close];
}

@end
