//
//  PDFWord.m
//  MuPDF
//
//  Created by MK on 2022/5/9.
//

#import "PDFWord.h"

@implementation PDFWord {
    NSMutableString *_mString;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mString = [NSMutableString new];
    }
    return self;
}

- (NSString *)text {
    return [_mString description];
}

@end
