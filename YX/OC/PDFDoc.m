//
//  PDFDoc.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFDoc.h"
#import "PDFDoc_Private.h"
#import "PDFContext.h"

@implementation PDFDoc

- (instancetype)initWithPath:(NSString *)path {
    
    self = [super init];
    if (self) {
        _path = path.copy;
    }
    return self;
}

- (void)open {
    PDFContext *context = PDFContext.sharedContext;
    
    dispatch_sync(context.queue, ^{});
    
    fz_var(self);
    
    fz_context *ctx = context.ctx;    
    fz_try(ctx)
    {
        _doc = fz_open_document(ctx, _path.UTF8String);
        
        if (_doc != NULL)
        {
            _pdfDoc = pdf_specifics(ctx, _doc);
            
            if (_pdfDoc != NULL) {
                pdf_enable_js(ctx, _pdfDoc);
                _interactive = (pdf_crypt_version(ctx, _pdfDoc) == 0);
            }
        }
    }
    fz_catch(ctx)
    {
        if (_doc != NULL)
        {
            fz_drop_document(ctx, _doc);
        }
    }
}

- (void)close {
    if (_doc != NULL)
    {
        PDFContext *context = PDFContext.sharedContext;
        dispatch_async(context.queue, ^{
            fz_drop_document(context.ctx, _doc);
        });
    }
}

- (void)dealloc {
    [self close];
}

@end
