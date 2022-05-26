//
//  PDFDoc.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFDoc.h"
#import "PDFContext.h"
#import "PDFDoc_Private.h"

@implementation PDFDoc {
    id<NSLocking> _lock;
}

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path.copy;
        _lock = [NSLock new];
    }
    return self;
}

- (void)lock
{
    [_lock lock];
}

- (void)unlock
{
    [_lock unlock];
}

- (void)open
{
    PDFContext *context = PDFContext.sharedContext;

    dispatch_sync(context.queue, ^{
                  });

    [self lock];

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

    [self unlock];
}

- (fz_context *)ctx
{
    return PDFContext.sharedContext.ctx;
}

- (void)close
{
    [self lock];

    if (_doc != NULL) {
        PDFContext *context = PDFContext.sharedContext;
        fz_document *doc = _doc;
        dispatch_async(context.queue, ^{
            fz_drop_document(context.ctx, doc);
        });
        _doc = NULL;
    }

    [self unlock];
}

- (BOOL)isOpen
{
    [self lock];

    BOOL value = _doc != nil;

    [self unlock];

    return value;
}

- (BOOL)needPassword
{
    [self lock];

    BOOL value = fz_needs_password(self.ctx, _doc) != 0;

    [self unlock];

    return value;
}

- (BOOL)authPassword:(NSString *)password
{
    [self lock];

    BOOL value = fz_authenticate_password(self.ctx, _doc, password.UTF8String);

    [self unlock];

    return value;
}

- (void)dealloc
{
    [self close];
}

@end
