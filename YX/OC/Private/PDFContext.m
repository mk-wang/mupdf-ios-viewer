//
//  PDFContext.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFContext.h"

@implementation PDFContext

+ (instancetype)sharedContext
{
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedInstance];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.yx.pdf.context.queue", DISPATCH_QUEUE_SERIAL);
        _ctx = fz_new_context(NULL, NULL, 128 << 20);
        fz_register_document_handlers(_ctx);
        _screenScale = [UIScreen mainScreen].scale;
    }
    return self;
}

@end
