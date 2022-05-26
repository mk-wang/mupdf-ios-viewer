//
//  PDFDoc.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#include "PDFCommon.h"
#import "PDFDoc.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDFDoc ()

@property (nullable, nonatomic, assign) fz_document *doc;

@property (nonatomic, assign, readonly) fz_context *ctx;

@end

NS_ASSUME_NONNULL_END
