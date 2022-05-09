//
//  PDFAnnotation.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFAnnotation_Private.h"
#import "PDFContext.h"

@implementation PDFAnnotation


-(instancetype) initFromAnnot:(void *)annot;
{
    self = [super init];
    if (self)
    {
        _annot =  (pdf_annot *)annot;
        fz_context *ctx = PDFContext.sharedContext.ctx;
        _type = pdf_annot_type(ctx, _annot);
        
        fz_rect frect;
        fz_bound_annot(ctx, annot, &frect);
        _rect.origin.x = frect.x0;
        _rect.origin.y = frect.y0;
        _rect.size.width = frect.x1 - frect.x0;
        _rect.size.height = frect.y1 - frect.y0;
    }
    return self;
}


@end
