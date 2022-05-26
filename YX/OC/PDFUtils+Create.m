//
//  PDFUtils+Create.m
//  MuPDF
//
//  Created by MK on 2022/5/20.
//

#import "PDFCommon.h"
#import "PDFContext.h"
#import "PDFDoc_Private.h"
#import "PDFUtils+Create.h"
#import "pdf-tool.h"

@interface PDFCreateProgressWrap : NSObject

@property (nonatomic, strong) PDFCreateProgress cb;

@end

@implementation PDFCreateProgressWrap

@end

static void progress_cb(const void *data, int pos, int max, const char *error)
{
    if (data == NULL) {
        return;
    }

    PDFCreateProgressWrap *wrap = (__bridge PDFCreateProgressWrap *)(data);
    if (wrap.cb == nil) {
        return;
    }
    wrap.cb(pos, max, error == NULL ? nil : @(error));
}

@implementation PDFUtils (Create)

+ (BOOL)setPassword:(NSURL *)source
               dest:(NSURL *)dest
           password:(NSString *)password
              crypt:(BOOL)crypt
           progress:(PDFCreateProgress)progress
{
    NSString *paramStr = [NSString stringWithFormat:@"encrypt=%@,owner-password=%@,user-password=%@",
                                                    crypt ? @"yes" : @"no",
                                                    password,
                                                    password];
    NSString *sourcePath = source.path;
    NSString *destPath = dest.path;

    PDFCreateProgressWrap *wrap = nil;

    if (progress != NULL) {
        wrap = [[PDFCreateProgressWrap alloc] init];
        wrap.cb = progress;
    }

    fz_progress_data cpd;
    cpd.data = (__bridge const void *)(wrap);
    cpd.cb = progress_cb;

    int rt = pdf_create(sourcePath.UTF8String,
                        destPath.UTF8String,
                        paramStr.UTF8String,
                        &cpd);
    return rt > 0;
}

@end
