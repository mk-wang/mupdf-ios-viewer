//
//  PDFDoc.h
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFDoc.h"
#include "Common_Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface PDFDoc()

@property (nonatomic, assign) pdf_document* pdfDoc;
@property (nonatomic, assign) fz_document* doc;

@end

NS_ASSUME_NONNULL_END
