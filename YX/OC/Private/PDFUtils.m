//
//  PDFUtils.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFUtils.h"

@implementation PDFUtils

+ (CGSize)fit:(CGSize)page to:(CGSize)screen
{
    CGFloat scale = MIN(screen.width / page.width, screen.height / page.height);
    CGFloat width = floorf(page.width * scale) / page.width;
    CGFloat height = floorf(page.height * scale) / page.height;
    return CGSizeMake(width, height);
}

@end
